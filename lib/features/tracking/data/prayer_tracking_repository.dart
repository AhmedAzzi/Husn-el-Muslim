import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/features/tracking/data/points_engine.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_log_entry.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_reminder_service.dart';

/// 5-prayer tracking repository. Reuses SharedPreferences (the project's
/// existing persistence) — no new database.
///
/// Schema (timezone-safe, local Gregorian date keys `yyyy-MM-dd`):
/// - `ptrack_log_<date>_<prayerIndex>` → JSON `{date, prayer, status, ts}`
/// - `ptrack_context` → 'man' | 'woman' (affects scoring options in UI)
/// - `ptrack_disabled` → bool (tracking paused)
/// - `ptrack_onboarded` → bool (tracker onboarding shown)
/// - `ptrack_daily_goal` → int 1..5 (default 5, the "الهدف اليومي")
/// - `ptrack_streak_longest` → int (high-water mark)
///
/// Streak rule: a past day counts when at least [dailyGoal] prayers were
/// logged as performed (anything except missed). A past day below the goal
/// breaks the chain. Like the Fajr tracker, the current streak walks back
/// from yesterday while today is still pending.
///
/// Fajr alarm integration: [FajrTrackingRepository.recordWakeUpSuccess]
/// writes a Fajr=onTimeAlone entry here (never overwrites a manual entry).
/// Legacy `fajr_log_*` successes can be imported once via [migrateFajrLogs].
class PrayerTrackingRepository {
  PrayerTrackingRepository._();
  static final PrayerTrackingRepository instance =
      PrayerTrackingRepository._();

  static const int fajrIndex = 0;
  static const int prayerCount = 5;
  static const int defaultDailyGoal = 5;

  static const String _logPrefix = 'ptrack_log_';
  static const String _kContext = 'ptrack_context';
  static const String _kDisabled = 'ptrack_disabled';
  static const String _kOnboarded = 'ptrack_onboarded';
  static const String _kDailyGoal = 'ptrack_daily_goal';
  static const String _kLongest = 'ptrack_streak_longest';
  static const String _kMigrated = 'ptrack_fajr_migrated';
  static const String _kReminders = 'ptrack_reminders';

  /// 'man' (default) or 'woman'. Prayer rulings differ, which affects the
  /// logging options offered in the UI ("السياق" in the design).
  static const String contextMan = 'man';
  static const String contextWoman = 'woman';

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseKey(String key) {
    try {
      final p = key.split('-');
      if (p.length != 3) return null;
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences> _prefs() async {
    try {
      return SharedPrefsCache.instance;
    } catch (_) {
      return SharedPreferences.getInstance();
    }
  }

  String _entryKey(String date, int prayerIndex) =>
      '$_logPrefix${date}_$prayerIndex';

  // ---------- logging ----------

  /// Logs (or re-logs) one prayer. Re-logging the same day/prayer replaces
  /// the previous status — tapping a different "how" just updates it.
  /// Returns null when tracking is disabled.
  Future<PrayerLogEntry?> logPrayer({
    required DateTime date,
    required int prayerIndex,
    required PrayerStatus status,
  }) async {
    assert(prayerIndex >= 0 && prayerIndex < prayerCount);
    final prefs = await _prefs();
    if (prefs.getBool(_kDisabled) ?? false) return null;
    final key = dateKey(date);
    final entry = PrayerLogEntry(
      date: key,
      prayerIndex: prayerIndex,
      status: status,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setString(_entryKey(key, prayerIndex), jsonEncode(entry.toJson()));
    await _refreshLongest(prefs);
    await _syncWidget(prefs);
    // The prayer is logged: its logging reminder (if any) is now stale.
    await PrayerReminderService.instance.onLogged(prayerIndex, key);
    return entry;
  }

  /// Removes the log for one prayer (back to unlogged). Never fails.
  Future<void> clearPrayer({
    required DateTime date,
    required int prayerIndex,
  }) async {
    final prefs = await _prefs();
    final key = dateKey(date);
    await prefs.remove(_entryKey(key, prayerIndex));
    await _syncWidget(prefs);
    // Unlogged again: re-arm its reminder from the cached prayer times.
    await PrayerReminderService.instance.onCleared(prayerIndex, key);
  }

  /// One day's entries in prayer order (Fajr..Isha); null = unlogged.
  Future<List<PrayerLogEntry?>> dayEntries(DateTime date) async {
    final prefs = await _prefs();
    final key = dateKey(date);
    final out = <PrayerLogEntry?>[];
    for (var i = 0; i < prayerCount; i++) {
      out.add(_readSync(prefs, _entryKey(key, i)));
    }
    return out;
  }

  /// Entries for [days] consecutive days ending at [date] (default today),
  /// newest day first. Used by the calendar / 30-day overview.
  Future<List<List<PrayerLogEntry?>>> entriesForRange(
    int days, {
    DateTime? end,
  }) async {
    final anchor = end ?? DateTime.now();
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final out = <List<PrayerLogEntry?>>[];
    for (var i = 0; i < days; i++) {
      out.add(await dayEntries(base.subtract(Duration(days: i))));
    }
    return out;
  }

  /// Rolling 30-day points total (the "بناءً على آخر ٣٠ يومًا" figure that
  /// drives the level). Includes today.
  Future<int> rolling30DayPoints({DateTime? now}) async {
    final range = await entriesForRange(30, end: now);
    return PointsEngine.totalPoints(range.expand((day) => day.whereType<PrayerLogEntry>()));
  }

  // ---------- streaks ----------

  Future<int> _dailyGoal(SharedPreferences prefs) async =>
      (prefs.getInt(_kDailyGoal) ?? defaultDailyGoal).clamp(1, prayerCount);

  Future<int> dailyGoal() async => _dailyGoal(await _prefs());

  Future<void> setDailyGoal(int goal) async {
    final prefs = await _prefs();
    await prefs.setInt(_kDailyGoal, goal.clamp(1, prayerCount));
    await syncDayProgress(prefs);
  }

  /// Consecutive goal-meeting days ending today (or yesterday if today is
  /// still pending — so the streak doesn't read 0 mid-day).
  Future<int> currentStreak({DateTime? now}) async {
    final prefs = await _prefs();
    final goal = await _dailyGoal(prefs);
    final today = now ?? DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    final todayKey = dateKey(cursor);
    var performed = 0;
    for (var i = 0; i < prayerCount; i++) {
      final e = _readSync(prefs, _entryKey(todayKey, i));
      if (e != null && e.countsTowardGoal) performed++;
    }
    if (performed < goal) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    for (var i = 0; i < 3650; i++) {
      final key = dateKey(cursor);
      var count = 0;
      for (var p = 0; p < prayerCount; p++) {
        final e = _readSync(prefs, _entryKey(key, p));
        if (e != null && e.countsTowardGoal) count++;
      }
      if (count >= goal) {
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

  Future<void> _refreshLongest(SharedPreferences prefs) async {
    // currentStreak re-reads prefs; pass through the same instance where
    // possible by computing inline is complex — use the public method.
    final current = await currentStreak();
    final longest = prefs.getInt(_kLongest) ?? 0;
    if (current > longest) {
      await prefs.setInt(_kLongest, current);
    }
  }

  // ---------- settings ----------

  Future<String> context() async {
    final prefs = await _prefs();
    final v = prefs.getString(_kContext);
    return v == contextWoman ? contextWoman : contextMan;
  }

  Future<void> setContext(String value) async {
    final prefs = await _prefs();
    await prefs.setString(
        _kContext, value == contextWoman ? contextWoman : contextMan);
  }

  Future<bool> isDisabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_kDisabled) ?? false;
  }

  Future<void> setDisabled(bool disabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_kDisabled, disabled);
  }

  Future<bool> isOnboarded() async {
    final prefs = await _prefs();
    return prefs.getBool(_kOnboarded) ?? false;
  }

  Future<void> setOnboarded(bool onboarded) async {
    final prefs = await _prefs();
    await prefs.setBool(_kOnboarded, onboarded);
  }

  /// Logging reminders ("إشعارات ذكية"). Default OFF: enabled by accepting
  /// the tracker onboarding, toggleable in tracking settings afterwards.
  Future<bool> remindersEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_kReminders) ?? false;
  }

  Future<void> setReminders(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_kReminders, enabled);
  }

  /// Destructive reset ("مسح بيانات التتبع"): removes all prayer logs and
  /// the longest-streak mark. Keeps settings (context, goal, onboarding).
  Future<void> clearAll() async {
    final prefs = await _prefs();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_logPrefix)) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_kLongest);
    await _syncWidget(prefs);
  }

  /// Developer snapshot for the diagnostics screen: streaks, goal, level
  /// inputs, flags, and reminder-cache presence. Single read, no UI strings.
  Future<Map<String, Object>> diagnosticsSnapshot({DateTime? now}) async {
    final prefs = await _prefs();
    final anchor = now ?? DateTime.now();
    final todayKey = dateKey(anchor);
    var todayLogged = 0;
    for (var p = 0; p < prayerCount; p++) {
      if (_readSync(prefs, _entryKey(todayKey, p)) != null) todayLogged++;
    }
    final entries = <PrayerLogEntry>[];
    final base =
        DateTime(anchor.year, anchor.month, anchor.day);
    for (var d = 0; d < 30; d++) {
      final key = dateKey(base.subtract(Duration(days: d)));
      for (var p = 0; p < prayerCount; p++) {
        final e = _readSync(prefs, _entryKey(key, p));
        if (e != null) entries.add(e);
      }
    }
    final points = PointsEngine.totalPoints(entries);
    return {
      'current': await currentStreak(now: anchor),
      'longest': prefs.getInt(_kLongest) ?? 0,
      'goal': await _dailyGoal(prefs),
      'points30': points,
      'level': PointsEngine.levelForPoints(points),
      'todayLogged': todayLogged,
      'reminders': prefs.getBool(_kReminders) ?? false,
      'disabled': prefs.getBool(_kDisabled) ?? false,
      'context': prefs.getString(_kContext) ?? contextMan,
      'onboarded': prefs.getBool(_kOnboarded) ?? false,
      'cacheToday': prefs.getStringList(
              PrayerReminderService.timesCacheKey(todayKey)) !=
          null,
    };
  }

  // ---------- Fajr legacy ----------

  /// Called by the Fajr alarm confirmation path: records Fajr as performed
  /// on time unless the user already logged Fajr manually (manual entry
  /// always wins) or tracking is disabled.
  Future<void> recordAlarmFajr(String date) async {
    final prefs = await _prefs();
    if (prefs.getBool(_kDisabled) ?? false) return;
    if (_readSync(prefs, _entryKey(date, fajrIndex)) != null) return;
    final entry = PrayerLogEntry(
      date: date,
      prayerIndex: fajrIndex,
      status: PrayerStatus.onTimeAlone,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setString(
        _entryKey(date, fajrIndex), jsonEncode(entry.toJson()));
    await _refreshLongest(prefs);
    await _syncWidget(prefs);
    await PrayerReminderService.instance.onLogged(fajrIndex, date);
  }

  /// One-time import of legacy `fajr_log_*` wake-up successes as
  /// Fajr=onTimeAlone entries. Never overwrites an existing manual entry.
  /// Safe to call repeatedly (guarded by a flag + per-day checks).
  Future<int> migrateFajrLogs() async {
    final prefs = await _prefs();
    if (prefs.getBool(_kMigrated) ?? false) return 0;
    var imported = 0;
    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith('fajr_log_')) continue;
      final date = key.substring('fajr_log_'.length);
      if (parseKey(date) == null) continue;
      if (_readSync(prefs, _entryKey(date, fajrIndex)) != null) continue;
      Map<String, dynamic>? json;
      try {
        json = jsonDecode(prefs.getString(key) ?? '') as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      if (json['wakeup'] == true) {
        final entry = PrayerLogEntry(
          date: date,
          prayerIndex: fajrIndex,
          status: PrayerStatus.onTimeAlone,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await prefs.setString(
            _entryKey(date, fajrIndex), jsonEncode(entry.toJson()));
        imported++;
      }
    }
    await prefs.setBool(_kMigrated, true);
    await _refreshLongest(prefs);
    return imported;
  }

  /// User Hijri day-adjustment shared with the prayer-times screen
  /// (raw `hijriOffset` pref; default 0). Display-only helper.
  Future<int> hijriOffsetDays() async {
    final prefs = await _prefs();
    return prefs.getInt('hijriOffset') ?? 0;
  }

  /// Writes today's performed count + goal for the home-screen tracking
  /// widget (`widget_day_done` / `widget_day_goal`). Never throws; the
  /// caller triggers the native re-render (see [_syncWidget]).
  Future<void> syncDayProgress([SharedPreferences? prefs]) async {
    try {
      final p = prefs ?? await _prefs();
      final key = dateKey(DateTime.now());
      var done = 0;
      for (var i = 0; i < prayerCount; i++) {
        final e = _readSync(p, _entryKey(key, i));
        if (e != null && e.countsTowardGoal) done++;
      }
      await p.setInt('widget_day_done', done);
      await p.setInt('widget_day_goal', await _dailyGoal(p));
    } catch (e) {
      debugPrint('Day progress sync failed: $e');
    }
  }

  // ---------- internals ----------

  PrayerLogEntry? _readSync(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return PrayerLogEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Bad prayer track log $key: $e');
      return null;
    }
  }

  /// Mirrors streak + today's Fajr state into the native tracking widget
  /// keys (same single-source pattern as the Fajr repository).
  Future<void> _syncWidget(SharedPreferences prefs) async {
    try {
      final now = DateTime.now();
      final current = await currentStreak(now: now);
      final todayKey = dateKey(now);
      final fajr = _readSync(prefs, _entryKey(todayKey, fajrIndex));
      await prefs.setInt('widget_streak_current', current);
      await prefs.setBool(
          'widget_fajr_done', fajr != null && fajr.countsTowardGoal);
      await syncDayProgress(prefs);
      await PrayerNotificationHelper.updatePrayerWidgets();
    } catch (e) {
      debugPrint('Prayer tracking widget sync failed: $e');
    }
  }
}
