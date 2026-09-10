import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/constants/notification_ids.dart';
import 'package:small_husn_muslim/core/services/notification_service.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// A single prayer moment (engine name + local time) used for planning.
/// Decoupled from `PrayerTime` so this service never imports the prayer
/// controller (which itself imports this service — one-way dependency).
class PrayerMoment {
  /// Engine name: Fajr, Dhuhr, Asr, Maghrib, Isha.
  final String name;
  final DateTime time;

  const PrayerMoment(this.name, this.time);
}

/// One due logging nudge: prayer index 0..4 + exact fire time.
class DueReminder {
  final int prayerIndex;
  final DateTime fireAt;

  const DueReminder(this.prayerIndex, this.fireAt);
}

/// Logging reminders ("إشعارات ذكية" from the tracker onboarding): quiet
/// one-shot nudges for prayers the user forgot to log.
///
/// Design notes:
/// - NEVER daily-repeating: each reminder is an exact one-shot computed
///   from real prayer times, recomputed on app start / prayer sync /
///   settings changes. Covers today only (times shift daily).
/// - Logging a prayer cancels its reminder immediately (no times needed).
/// - Clearing re-arms a single reminder from the cached times.
/// - All public methods are infallible (never throw) so repository hooks
///   and unit tests can call them freely.
class PrayerReminderService {
  PrayerReminderService._();
  static final PrayerReminderService instance = PrayerReminderService._();

  /// Minutes after a prayer time before nudging.
  static const int reminderOffsetMinutes = 30;

  /// Raw pref keys (mirrors PrayerTrackingRepository — kept local to avoid
  /// a repository↔service import cycle).
  static const String _kReminders = 'ptrack_reminders';
  static const String _kDisabled = 'ptrack_disabled';
  static const String _kTimesPrefix = 'ptrack_times_';

  /// Cache key holding the prayer times snapshot for [dateKey]
  /// (`yyyy-MM-dd`). Shared with diagnostics (no import cycle: the
  /// repository imports this service, never the reverse).
  static String timesCacheKey(String date) => '$_kTimesPrefix$date';

  static const _engineOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static int _idFor(int prayerIndex) =>
      NotificationIds.trackerLogBase + prayerIndex;

  Future<SharedPreferences> _prefs() async {
    try {
      return SharedPrefsCache.instance;
    } catch (_) {
      return SharedPreferences.getInstance();
    }
  }

  // ---------- pure planner (unit-testable, no I/O) ----------

  /// Returns reminders for unlogged prayers whose nudge time
  /// (prayer time + [offsetMinutes]) is still in the future.
  static List<DueReminder> plan({
    required DateTime now,
    required List<PrayerMoment> moments,
    required Set<int> logged,
    int offsetMinutes = reminderOffsetMinutes,
  }) {
    final out = <DueReminder>[];
    for (var i = 0; i < moments.length && i < 5; i++) {
      if (logged.contains(i)) continue;
      final fireAt =
          moments[i].time.add(Duration(minutes: offsetMinutes));
      if (fireAt.isAfter(now)) out.add(DueReminder(i, fireAt));
    }
    return out;
  }

  // ---------- orchestration ----------

  /// Full refresh from fresh prayer times (called after prayer sync).
  /// Caches the times, then schedules every due reminder.
  Future<void> refreshWithMoments(List<PrayerMoment> moments) async {
    try {
      final prefs = await _prefs();
      final today = _dateKey(DateTime.now());
      await prefs.setStringList(
        timesCacheKey(today),
        [for (final m in moments) '${m.name}|${m.time.millisecondsSinceEpoch}'],
      );
      await _reschedule(prefs, moments);
    } catch (e) {
      debugPrint('Reminder refresh failed: $e');
    }
  }

  /// Refresh from the cached times (onboarding accept, settings toggle).
  /// No-op when nothing was ever cached (covered on next prayer sync).
  Future<void> refreshFromCache() async {
    try {
      final prefs = await _prefs();
      final moments = _cachedMoments(prefs);
      if (moments == null) return;
      await _reschedule(prefs, moments);
    } catch (e) {
      debugPrint('Reminder cache refresh failed: $e');
    }
  }

  /// A prayer was just logged → its reminder is stale. Needs no times.
  Future<void> onLogged(int prayerIndex, String date) async {
    try {
      if (date != _dateKey(DateTime.now())) return;
      await NotificationService().cancelNotification(_idFor(prayerIndex));
    } catch (e) {
      debugPrint('Reminder cancel failed: $e');
    }
  }

  /// A prayer log was cleared → re-arm its reminder from cached times.
  Future<void> onCleared(int prayerIndex, String date) async {
    try {
      final prefs = await _prefs();
      if (date != _dateKey(DateTime.now())) return;
      if (!(prefs.getBool(_kReminders) ?? false)) return;
      if (prefs.getBool(_kDisabled) ?? false) return;
      final moments = _cachedMoments(prefs);
      if (moments == null ||
          prayerIndex < 0 ||
          prayerIndex >= moments.length) {
        return;
      }
      final fireAt = moments[prayerIndex]
          .time
          .add(const Duration(minutes: reminderOffsetMinutes));
      if (!fireAt.isAfter(DateTime.now())) return;
      await _scheduleOne(prefs, prayerIndex, moments[prayerIndex].name, fireAt);
    } catch (e) {
      debugPrint('Reminder re-arm failed: $e');
    }
  }

  Future<void> cancelAll() async {
    for (var i = 0; i < 5; i++) {
      try {
        await NotificationService().cancelNotification(_idFor(i));
      } catch (e) {
        debugPrint('Reminder cancelAll failed: $e');
      }
    }
  }

  // ---------- internals ----------

  List<PrayerMoment>? _cachedMoments(SharedPreferences prefs) {
    try {
      final today = _dateKey(DateTime.now());
      final raw = prefs.getStringList(timesCacheKey(today));
      if (raw == null || raw.isEmpty) return null;
      final out = <PrayerMoment>[];
      for (final s in raw) {
        final parts = s.split('|');
        if (parts.length != 2) continue;
        final ms = int.tryParse(parts[1]);
        if (ms == null) continue;
        out.add(PrayerMoment(
            parts[0], DateTime.fromMillisecondsSinceEpoch(ms)));
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _reschedule(
    SharedPreferences prefs,
    List<PrayerMoment> moments,
  ) async {
    for (var i = 0; i < 5; i++) {
      try {
        await NotificationService().cancelNotification(_idFor(i));
      } catch (_) {}
    }
    if (!(prefs.getBool(_kReminders) ?? false)) return;
    if (prefs.getBool(_kDisabled) ?? false) return;
    final now = DateTime.now();
    final today = _dateKey(now);
    final logged = <int>{};
    for (var i = 0; i < 5; i++) {
      if (prefs.getString('ptrack_log_${today}_$i') != null) logged.add(i);
    }
    final due = PrayerReminderService.plan(
        now: now, moments: moments, logged: logged);
    for (final d in due) {
      final name =
          d.prayerIndex < moments.length ? moments[d.prayerIndex].name : '';
      await _scheduleOne(prefs, d.prayerIndex, name, d.fireAt);
    }
  }

  Future<void> _scheduleOne(
    SharedPreferences prefs,
    int prayerIndex,
    String engineName,
    DateTime fireAt,
  ) async {
    try {
      final lang = prefs.getString('app_language') ?? 'ar';
      final loc = lookupAppLocalizations(Locale(lang));
      final display = _displayName(loc, engineName);
      // Quiet nudge: obey the global sound toggle like adhkar reminders.
      final logic = prefs.getBool('notificationSoundEnabled') ?? true;
      await NotificationService().scheduleOneShotNotification(
        _idFor(prayerIndex),
        loc.ptRemindTitle,
        loc.ptRemindBody(display),
        fireAt,
        logic,
        payload: NotificationIds.trackerLogPayload,
      );
    } catch (e) {
      debugPrint('Reminder schedule failed: $e');
    }
  }

  static String _displayName(AppLocalizations loc, String engine) {
    switch (engine) {
      case 'Fajr':
        return loc.nsPrayerFajr;
      case 'Dhuhr':
        return loc.nsPrayerDhuhr;
      case 'Asr':
        return loc.nsPrayerAsr;
      case 'Maghrib':
        return loc.nsPrayerMaghrib;
      case 'Isha':
        return loc.nsPrayerIsha;
      default:
        return engine;
    }
  }

  /// Engine names in tracker index order (for mapping prayerTimes → moments).
  static List<String> get engineOrder => _engineOrder;
}
