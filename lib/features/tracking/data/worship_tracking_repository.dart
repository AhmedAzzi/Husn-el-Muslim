import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/tracking/data/worship_type.dart';

/// Worship tracker repository: voluntary fasting + daily wird + good deeds.
/// Reuses SharedPreferences — no new database.
///
/// Schema (timezone-safe, local Gregorian date keys `yyyy-MM-dd`):
/// - `wtrk_log_<date>_<deedIndex>` → JSON `{date, deed, done, ts}`
///   (presence = done — single toggle, like the Sunnah tracker)
/// - `wtrk_fast_<date>` → JSON `{date, kind, ts}` (at most one fast a day)
/// - `wtrk_daily_goal` → int 1..8 (daily-deeds goal, default 3)
/// - `wtrk_streak_longest` → int (daily-deeds high-water mark)
/// - `wtrk_fast_streak_longest` → int (Mon+Thu weeks high-water mark)
/// - `wtrk_disabled` → bool (tracking paused, default false)
///
/// Streaks:
/// - daily deeds: a past day counts when at least [dailyGoal] deeds were
///   done; walks back from yesterday while today is pending (same rule as
///   the prayer/Sunnah trackers).
/// - fasting: consecutive weeks with both Monday and Thursday fasted;
///   walks back from last week while the current week is still pending
///   (its Thursday is in the future, or today is an unlogged fast-day).
class WorshipTrackingRepository {
  WorshipTrackingRepository._();
  static final WorshipTrackingRepository instance =
      WorshipTrackingRepository._();

  static int get deedCount => DeedType.values.length;
  static const int defaultDailyGoal = 3;

  static const String _logPrefix = 'wtrk_log_';
  static const String _fastPrefix = 'wtrk_fast_';
  static const String _kGoal = 'wtrk_daily_goal';
  static const String _kLongest = 'wtrk_streak_longest';
  static const String _kFastLongest = 'wtrk_fast_streak_longest';
  static const String _kDisabled = 'wtrk_disabled';

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<SharedPreferences> _prefs() async {
    try {
      return SharedPrefsCache.instance;
    } catch (_) {
      return SharedPreferences.getInstance();
    }
  }

  String _entryKey(String date, int deedIndex) =>
      '$_logPrefix${date}_$deedIndex';

  String _fastKey(String date) => '$_fastPrefix$date';

  // ---------- daily deeds ----------

  /// Toggles one deed for [date]. Returns the new state (true = done),
  /// or null when tracking is disabled.
  Future<bool?> toggleDeed({
    required DateTime date,
    required DeedType type,
  }) async {
    final prefs = await _prefs();
    if (prefs.getBool(_kDisabled) ?? false) return null;
    final key = dateKey(date);
    final entryKey = _entryKey(key, type.index);
    final done = prefs.getString(entryKey) == null;
    if (done) {
      await prefs.setString(
        entryKey,
        jsonEncode({
          'date': key,
          'deed': type.index,
          'done': true,
          'ts': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } else {
      await prefs.remove(entryKey);
    }
    await _refreshLongest();
    return done;
  }

  /// Explicitly sets one deed (used by tests / future widgets).
  Future<bool?> setDeed({
    required DateTime date,
    required DeedType type,
    required bool done,
  }) async {
    final prefs = await _prefs();
    if (prefs.getBool(_kDisabled) ?? false) return null;
    final key = dateKey(date);
    final entryKey = _entryKey(key, type.index);
    if (done) {
      await prefs.setString(
        entryKey,
        jsonEncode({
          'date': key,
          'deed': type.index,
          'done': true,
          'ts': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } else {
      await prefs.remove(entryKey);
    }
    await _refreshLongest();
    return done;
  }

  /// One day's deed states in [DeedType] order; true = done.
  Future<List<bool>> dayEntries(DateTime date) async {
    final prefs = await _prefs();
    final key = dateKey(date);
    return List<bool>.generate(
      deedCount,
      (i) => prefs.getString(_entryKey(key, i)) != null,
    );
  }

  Future<int> dayCount(DateTime date) async {
    final day = await dayEntries(date);
    return day.where((d) => d).length;
  }

  /// Points for one day's deeds (fasting excluded — see [fastPointsOn]).
  Future<int> dayPoints(DateTime date) async {
    final day = await dayEntries(date);
    var points = 0;
    for (var i = 0; i < deedCount; i++) {
      if (day[i]) points += deedPoints[DeedType.values[i]] ?? 0;
    }
    return points;
  }

  // ---------- fasting ----------

  /// Logs a fast on [date] with [kind], replacing any existing fast entry
  /// for that day. Returns null when tracking is disabled.
  Future<FastKind?> logFast({
    required DateTime date,
    required FastKind kind,
  }) async {
    final prefs = await _prefs();
    if (prefs.getBool(_kDisabled) ?? false) return null;
    final key = dateKey(date);
    await prefs.setString(
      _fastKey(key),
      jsonEncode({
        'date': key,
        'kind': kind.index,
        'ts': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    await _refreshFastLongest();
    return kind;
  }

  /// Removes the fast entry for [date] (back to not-fasted). Never fails.
  Future<void> clearFast(DateTime date) async {
    final prefs = await _prefs();
    await prefs.remove(_fastKey(dateKey(date)));
  }

  /// The fast kind logged on [date], or null when not fasted.
  Future<FastKind?> fastOn(DateTime date) async {
    final prefs = await _prefs();
    return _readFastSync(prefs, _fastKey(dateKey(date)));
  }

  /// Fast kinds for [days] consecutive days ending at [end] (default
  /// today), newest day first; null = not fasted.
  Future<List<FastKind?>> fastsForRange(int days, {DateTime? end}) async {
    final prefs = await _prefs();
    final anchor = _dayOnly(end ?? DateTime.now());
    final out = <FastKind?>[];
    for (var i = 0; i < days; i++) {
      out.add(_readFastSync(
          prefs, _fastKey(dateKey(anchor.subtract(Duration(days: i))))));
    }
    return out;
  }

  /// Points for the fast logged on [date] (0 when not fasted).
  Future<int> fastPointsOn(DateTime date) async {
    final kind = await fastOn(date);
    return kind == null ? 0 : (fastPoints[kind] ?? 0);
  }

  /// Number of fasted days in the last 30 days (including today).
  Future<int> fastCount30({DateTime? now}) async {
    final fasts = await fastsForRange(30, end: now);
    return fasts.where((f) => f != null).length;
  }

  /// Rolling 30-day points total: daily deeds + fasting, ending at [now].
  Future<int> rolling30DayPoints({DateTime? now}) async {
    final anchor = _dayOnly(now ?? DateTime.now());
    var total = 0;
    for (var d = 0; d < 30; d++) {
      final date = anchor.subtract(Duration(days: d));
      total += await dayPoints(date);
      total += await fastPointsOn(date);
    }
    return total;
  }

  /// Monday of the week containing [date] (weeks start on Monday).
  static DateTime mondayOfWeek(DateTime date) {
    final base = _dayOnly(date);
    return base.subtract(Duration(days: (base.weekday - 1) % 7));
  }

  /// Consecutive Mon+Thu-complete weeks. Walks back from last week while
  /// the current week is still pending (its Thursday is in the future, or
  /// today itself is an unlogged Monday/Thursday).
  Future<int> fastingWeekStreak({DateTime? now}) async {
    final prefs = await _prefs();
    final today = _dayOnly(now ?? DateTime.now());
    var cursor = mondayOfWeek(today);
    if (await _weekPending(prefs, cursor, today)) {
      cursor = cursor.subtract(const Duration(days: 7));
    }
    var streak = 0;
    for (var i = 0; i < 520; i++) {
      if (await _weekComplete(prefs, cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> fastingLongest() async {
    final prefs = await _prefs();
    return prefs.getInt(_kFastLongest) ?? 0;
  }

  Future<void> _refreshFastLongest() async {
    final prefs = await _prefs();
    final current = await fastingWeekStreak();
    final longest = prefs.getInt(_kFastLongest) ?? 0;
    if (current > longest) {
      await prefs.setInt(_kFastLongest, current);
    }
  }

  Future<bool> _hasFastSync(SharedPreferences prefs, DateTime date) async =>
      _readFastSync(prefs, _fastKey(dateKey(date))) != null;

  Future<bool> _weekComplete(SharedPreferences prefs, DateTime monday) async {
    final thu = monday.add(const Duration(days: 3));
    return await _hasFastSync(prefs, monday) &&
        await _hasFastSync(prefs, thu);
  }

  /// A week is pending while its outcome can still change: Thursday in the
  /// future, or today is Monday/Thursday and not logged yet.
  Future<bool> _weekPending(
      SharedPreferences prefs, DateTime monday, DateTime today) async {
    final thu = monday.add(const Duration(days: 3));
    if (thu.isAfter(today)) return true;
    if (thu == today && !await _hasFastSync(prefs, today)) return true;
    if (monday == today && !await _hasFastSync(prefs, today)) return true;
    return false;
  }

  FastKind? _readFastSync(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final index = json['kind'] as int? ?? -1;
      if (index < 0 || index >= FastKind.values.length) return null;
      return FastKind.values[index];
    } catch (_) {
      return null;
    }
  }

  // ---------- daily-deed streaks ----------

  Future<int> _dailyGoal(SharedPreferences prefs) async =>
      (prefs.getInt(_kGoal) ?? defaultDailyGoal).clamp(1, deedCount);

  Future<int> dailyGoal() async => _dailyGoal(await _prefs());

  Future<void> setDailyGoal(int goal) async {
    final prefs = await _prefs();
    await prefs.setInt(_kGoal, goal.clamp(1, deedCount));
  }

  /// Consecutive goal-meeting days ending today (or yesterday if today is
  /// still pending).
  Future<int> currentStreak({DateTime? now}) async {
    final prefs = await _prefs();
    final goal = await _dailyGoal(prefs);
    final today = _dayOnly(now ?? DateTime.now());
    var cursor = today;
    if (await _countSync(prefs, cursor) < goal) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    for (var i = 0; i < 3650; i++) {
      if (await _countSync(prefs, cursor) >= goal) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> longestStreak() async {
    final prefs = await _prefs();
    return prefs.getInt(_kLongest) ?? 0;
  }

  Future<void> _refreshLongest() async {
    final prefs = await _prefs();
    final current = await currentStreak();
    final longest = prefs.getInt(_kLongest) ?? 0;
    if (current > longest) {
      await prefs.setInt(_kLongest, current);
    }
  }

  Future<int> _countSync(SharedPreferences prefs, DateTime date) async {
    final key = dateKey(date);
    var count = 0;
    for (var i = 0; i < deedCount; i++) {
      if (prefs.getString(_entryKey(key, i)) != null) count++;
    }
    return count;
  }

  // ---------- settings ----------

  Future<bool> isDisabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_kDisabled) ?? false;
  }

  Future<void> setDisabled(bool disabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_kDisabled, disabled);
  }

  /// Destructive reset: removes all deed logs, fast logs and both
  /// longest-streak marks. Keeps the daily goal (a setting, not data).
  Future<void> clearAll() async {
    final prefs = await _prefs();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_logPrefix) || key.startsWith(_fastPrefix)) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_kLongest);
    await prefs.remove(_kFastLongest);
  }

  /// Developer snapshot for the diagnostics screen. Single read, no strings.
  Future<Map<String, Object>> diagnosticsSnapshot({DateTime? now}) async {
    final prefs = await _prefs();
    final anchor = _dayOnly(now ?? DateTime.now());
    return {
      'worshipToday': await _countSync(prefs, anchor),
      'worshipCurrent': await currentStreak(now: anchor),
      'worshipLongest': prefs.getInt(_kLongest) ?? 0,
      'worshipGoal': await _dailyGoal(prefs),
      'worshipFastWeeks': await fastingWeekStreak(now: anchor),
      'worshipFastLongest': prefs.getInt(_kFastLongest) ?? 0,
      'worshipDisabled': prefs.getBool(_kDisabled) ?? false,
    };
  }
}
