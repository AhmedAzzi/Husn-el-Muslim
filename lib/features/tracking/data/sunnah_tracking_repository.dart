import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/tracking/data/sunnah_type.dart';

/// Sunnah tracker repository (Rawatib + Duha + Witr + Qiyam).
/// Reuses SharedPreferences — no new database.
///
/// Schema (timezone-safe, local Gregorian date keys `yyyy-MM-dd`):
/// - `strak_log_<date>_<sunnahIndex>` → JSON `{date, sunnah, done, ts}`
///   (presence = done; absence = not done — single toggle, no statuses)
/// - `strak_daily_goal` → int 1..8 (default 4)
/// - `strak_streak_longest` → int (high-water mark)
/// - `strak_disabled` → bool (tracking paused, default false)
///
/// Streak rule mirrors the 5-prayer tracker: a past day counts when at
/// least [dailyGoal] Sunnahs were done. The current streak walks back
/// from yesterday while today is still pending.
class SunnahTrackingRepository {
  SunnahTrackingRepository._();
  static final SunnahTrackingRepository instance =
      SunnahTrackingRepository._();

  static int get sunnahCount => SunnahType.values.length;
  static const int defaultDailyGoal = 4;

  static const String _logPrefix = 'strak_log_';
  static const String _kGoal = 'strak_daily_goal';
  static const String _kLongest = 'strak_streak_longest';
  static const String _kDisabled = 'strak_disabled';

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<SharedPreferences> _prefs() async {
    try {
      return SharedPrefsCache.instance;
    } catch (_) {
      return SharedPreferences.getInstance();
    }
  }

  String _entryKey(String date, int sunnahIndex) =>
      '$_logPrefix${date}_$sunnahIndex';

  // ---------- logging ----------

  /// Toggles one Sunnah for [date]. Returns the new state (true = done),
  /// or null when tracking is disabled.
  Future<bool?> toggleSunnah({
    required DateTime date,
    required SunnahType type,
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
          'sunnah': type.index,
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

  /// Explicitly sets one Sunnah (used by tests / future widgets).
  /// Returns null when tracking is disabled.
  Future<bool?> setSunnah({
    required DateTime date,
    required SunnahType type,
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
          'sunnah': type.index,
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

  /// One day's states in [SunnahType] order; true = done.
  Future<List<bool>> dayEntries(DateTime date) async {
    final prefs = await _prefs();
    final key = dateKey(date);
    return List<bool>.generate(
      sunnahCount,
      (i) => prefs.getString(_entryKey(key, i)) != null,
    );
  }

  /// Done-count for one day.
  Future<int> dayCount(DateTime date) async {
    final day = await dayEntries(date);
    return day.where((d) => d).length;
  }

  /// Whether all five Rawatib were done on [date].
  Future<bool> rawatibComplete(DateTime date) async {
    final day = await dayEntries(date);
    return rawatibTypes.every((t) => day[t.index]);
  }

  /// Points for one day (per-Sunnah points + Rawatib bonus when complete).
  Future<int> dayPoints(DateTime date) async {
    final day = await dayEntries(date);
    var points = 0;
    for (var i = 0; i < sunnahCount; i++) {
      if (day[i]) points += sunnahPoints[SunnahType.values[i]] ?? 0;
    }
    if (rawatibTypes.every((t) => day[t.index])) points += rawatibBonus;
    return points;
  }

  /// Rolling 30-day points total ending at [now] (default today).
  Future<int> rolling30DayPoints({DateTime? now}) async {
    final anchor = now ?? DateTime.now();
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    var total = 0;
    for (var d = 0; d < 30; d++) {
      total += await dayPoints(base.subtract(Duration(days: d)));
    }
    return total;
  }

  /// Done-counts for the last [days] days ending at [end] (default today),
  /// newest day first. Feeds the week overview.
  Future<List<int>> countsForRange(int days, {DateTime? end}) async {
    final anchor = end ?? DateTime.now();
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final out = <int>[];
    for (var i = 0; i < days; i++) {
      out.add(await dayCount(base.subtract(Duration(days: i))));
    }
    return out;
  }

  // ---------- streaks ----------

  Future<int> _dailyGoal(SharedPreferences prefs) async =>
      (prefs.getInt(_kGoal) ?? defaultDailyGoal).clamp(1, sunnahCount);

  Future<int> dailyGoal() async => _dailyGoal(await _prefs());

  Future<void> setDailyGoal(int goal) async {
    final prefs = await _prefs();
    await prefs.setInt(_kGoal, goal.clamp(1, sunnahCount));
  }

  /// Consecutive goal-meeting days ending today (or yesterday if today is
  /// still pending — so the streak doesn't read 0 mid-day).
  Future<int> currentStreak({DateTime? now}) async {
    final prefs = await _prefs();
    final goal = await _dailyGoal(prefs);
    final today = now ?? DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
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
    for (var i = 0; i < sunnahCount; i++) {
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

  /// Destructive reset: removes all Sunnah logs and the longest-streak
  /// mark. Keeps the daily goal (a setting, not data).
  Future<void> clearAll() async {
    final prefs = await _prefs();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_logPrefix)) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_kLongest);
  }

  /// Developer snapshot for the diagnostics screen. Single read, no strings.
  Future<Map<String, Object>> diagnosticsSnapshot({DateTime? now}) async {
    final prefs = await _prefs();
    final anchor = now ?? DateTime.now();
    final todayKey = dateKey(anchor);
    var todayDone = 0;
    for (var i = 0; i < sunnahCount; i++) {
      if (prefs.getString(_entryKey(todayKey, i)) != null) todayDone++;
    }
    return {
      'sunnahToday': todayDone,
      'sunnahCurrent': await currentStreak(now: anchor),
      'sunnahLongest': prefs.getInt(_kLongest) ?? 0,
      'sunnahGoal': await _dailyGoal(prefs),
      'sunnahDisabled': prefs.getBool(_kDisabled) ?? false,
    };
  }
}
