import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_names.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';

/// Persists today's prayer snapshot for the native home-screen widgets and
/// asks Android to re-render them.
///
/// The widgets compute the live countdown natively from [targetTs], so Dart
/// only needs to sync when the underlying data changes (fresh calculation,
/// mosque switch, manual offsets) — not on every tick.
class PrayerWidgetSync {
  static const _order = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha'
  ];

  static Future<void> syncFromTimes({
    required List<PrayerTime> times,
    required String hijriDate,
  }) async {
    try {
      final now = DateTime.now();
      final day = <Map<String, dynamic>>[];
      for (final name in _order) {
        PrayerTime? match;
        for (final p in times) {
          if (p.name == name) {
            match = p;
            break;
          }
        }
        if (match != null) {
          day.add({
            'n': name,
            't': match.time24h,
            'ts': match.time.millisecondsSinceEpoch,
          });
        }
      }
      if (day.isEmpty) return;

      // Next prayer: first future entry, else tomorrow's Fajr (+24h —
      // corrected on the next Dart sync; the native side does the same).
      Map<String, dynamic>? next;
      for (final e in day) {
        final ts = e['ts'] as int;
        if (ts > now.millisecondsSinceEpoch &&
            (next == null || ts < (next['ts'] as int))) {
          next = e;
        }
      }
      next ??= {
        'n': 'Fajr',
        't': day.firstWhere((e) => e['n'] == 'Fajr',
            orElse: () => day.first)['t'],
        'ts': (day.firstWhere((e) => e['n'] == 'Fajr',
                    orElse: () => day.first)['ts'] as int) +
            86400000,
      };

      final nextEn = next['n'] as String;
      final prefs = SharedPrefsCache.instance;
      await prefs.setString('widget_hijri', hijriDate);
      await prefs.setString('widget_next_en', nextEn);
      await prefs.setString(
          'widget_next_ar', kArabicPrayerNames[nextEn] ?? nextEn);
      await prefs.setString('widget_next_time', next['t'] as String);
      await prefs.setInt('widget_target_ts', next['ts'] as int);
      await prefs.setString('widget_day_json', jsonEncode(day));

      await PrayerNotificationHelper.updatePrayerWidgets();
    } catch (e) {
      if (kDebugMode) print('PrayerWidgetSync failed: $e');
    }
  }
}
