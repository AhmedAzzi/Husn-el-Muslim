import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';

/// Local Fajr wake-up tracking (streak only). Extracted from the removed
/// tracking feature so the Fajr challenge keeps its streak without the
/// 5-prayer / sunnah / fasting / wird trackers.
///
/// Schema (timezone-safe, Gregorian date keys `yyyy-MM-dd` in *local* time):
/// - `fajr_log_<date>` → JSON `{fajr, challenge, wakeup, ts}`
/// - `fajr_streak_longest` → int
///
/// Current streak is always *calculated* (never stored) by walking back from
/// today: consecutive wake-up-confirmed days count; a missed day (past date
/// with no success) breaks the chain. Future dates are ignored. Duplicate
/// records for the same date are merged idempotently.
class FajrDayLog {
  final String date;
  final bool fajrCompleted;
  final bool challengeCompleted;
  final bool wakeUpConfirmed;

  const FajrDayLog({
    required this.date,
    this.fajrCompleted = false,
    this.challengeCompleted = false,
    this.wakeUpConfirmed = false,
  });

  bool get success => wakeUpConfirmed;

  Map<String, dynamic> toJson() => {
        'date': date,
        'fajr': fajrCompleted,
        'challenge': challengeCompleted,
        'wakeup': wakeUpConfirmed,
      };

  factory FajrDayLog.fromJson(Map<String, dynamic> json) => FajrDayLog(
        date: json['date'] as String? ?? '',
        fajrCompleted: json['fajr'] as bool? ?? false,
        challengeCompleted: json['challenge'] as bool? ?? false,
        wakeUpConfirmed: json['wakeup'] as bool? ?? false,
      );
}

Future<SharedPreferences> _fajrPrefs() async {
  try {
    return SharedPrefsCache.instance;
  } catch (_) {
    return SharedPreferences.getInstance();
  }
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class FajrTrackingRepository {
  FajrTrackingRepository._();
  static final FajrTrackingRepository instance = FajrTrackingRepository._();

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

  /// Records the final successful wake-up for [date] (defaults: today).
  /// Only the confirmation step marks success — opening the alarm screen or
  /// starting the challenge is NOT enough.
  Future<FajrDayLog> recordWakeUpSuccess({DateTime? date}) async {
    final prefs = await _fajrPrefs();
    final key = dateKey(date ?? DateTime.now());
    final log = FajrDayLog(
      date: key,
      fajrCompleted: true,
      challengeCompleted: true,
      wakeUpConfirmed: true,
    );
    await prefs.setString('fajr_log_$key', jsonEncode(log.toJson()));
    final longest = prefs.getInt('fajr_streak_longest') ?? 0;
    final current = await currentStreak();
    if (current > longest) {
      await prefs.setInt('fajr_streak_longest', current);
    }
    return log;
  }

  /// Partial progress (challenge done, confirmation pending) — does NOT count
  /// toward streaks until [recordWakeUpSuccess] merges the confirmation.
  Future<FajrDayLog> recordChallengeCompleted({DateTime? date}) async {
    final prefs = await _fajrPrefs();
    final key = dateKey(date ?? DateTime.now());
    final prev = await getLog(key);
    final log = FajrDayLog(
      date: key,
      fajrCompleted: true,
      challengeCompleted: true,
      wakeUpConfirmed: prev?.wakeUpConfirmed ?? false,
    );
    await prefs.setString('fajr_log_$key', jsonEncode(log.toJson()));
    return log;
  }

  Future<FajrDayLog?> getLog(String key) async {
    final prefs = await _fajrPrefs();
    final raw = prefs.getString('fajr_log_$key');
    if (raw == null) return null;
    try {
      return FajrDayLog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Bad fajr log $key: $e');
      return null;
    }
  }

  Future<FajrDayLog?> today() => getLog(dateKey(DateTime.now()));

  /// Consecutive wake-up-confirmed days ending today (or yesterday if today
  /// hasn't succeeded yet — so the streak doesn't read 0 mid-day).
  Future<int> currentStreak({DateTime? now}) async {
    final prefs = await _fajrPrefs();
    final today = now ?? DateTime.now();
    var cursor = _dayOnly(today);
    // If today has no success yet, start counting from yesterday.
    final todayLog = await getLog(dateKey(cursor));
    if (todayLog?.success != true) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    for (var i = 0; i < 3650; i++) {
      final log = await _logSync(prefs, dateKey(cursor));
      if (log?.success == true) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<FajrDayLog?> _logSync(SharedPreferences prefs, String key) async {
    final raw = prefs.getString('fajr_log_$key');
    if (raw == null) return null;
    try {
      return FajrDayLog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<int> longestStreak() async {
    final prefs = await _fajrPrefs();
    return prefs.getInt('fajr_streak_longest') ?? 0;
  }

  /// Last [days] logs (newest first) for the history/calendar UI.
  Future<List<FajrDayLog?>> history({int days = 30, DateTime? now}) async {
    final today = now ?? DateTime.now();
    final out = <FajrDayLog?>[];
    for (var i = 0; i < days; i++) {
      final d = _dayOnly(today).subtract(Duration(days: i));
      out.add(await getLog(dateKey(d)));
    }
    return out;
  }
}
