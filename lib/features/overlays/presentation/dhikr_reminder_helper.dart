import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/masbaha/data/custom_dikr.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';

class DhikrReminderHelper {
  static final DhikrReminderHelper _instance = DhikrReminderHelper._internal();
  factory DhikrReminderHelper() => _instance;
  DhikrReminderHelper._internal();

  bool isEnabled = false;
  int intervalMinutes = 15; // Default 15 minutes
  List<String> _adhkar = [];
  List<String> get adhkar => _adhkar;

  Future<void> init() async {
    final prefs = SharedPrefsCache.instance;
    isEnabled = prefs.getBool('dhikr_reminder_enabled') ?? false;
    intervalMinutes = prefs.getInt('dhikr_reminder_interval') ?? 15;

    await _loadAdhkarFromJson();

    final hasOverlay = await PrayerNotificationHelper.checkOverlayPermission();
    if (!hasOverlay) {
      if (kDebugMode) {
        print('DhikrReminderHelper: overlay permission not granted');
      }
    }
  }

  Future<void> _loadAdhkarFromJson() async {
    try {
      final prefs = SharedPrefsCache.instance;
      final saved = prefs.getString('custom_dikr_list');

      List<dynamic> jsonList;
      if (saved != null) {
        jsonList = json.decode(saved);
      } else {
        final String jsonString =
            await rootBundle.loadString('assets/custom_dikr.json');
        jsonList = json.decode(jsonString);
      }

      _adhkar = jsonList
          .map((e) => CustomDikr.fromJson(e).arabic)
          .where((text) => text.length < 100) // Keep it short for overlay
          .toList();

      // Fallback if list is empty or fails
      if (_adhkar.isEmpty) {
        _adhkar = ["سبحان الله", "الحمد لله", "لا إله إلا الله", "الله أكبر"];
      }
    } catch (e) {
      _adhkar = ["سبحان الله", "الحمد لله", "لا إله إلا الله", "الله أكبر"];
    }
  }

  Future<void> updateSettings(bool enabled, int interval) async {
    isEnabled = enabled;
    intervalMinutes = interval;
    final prefs = SharedPrefsCache.instance;
    await prefs.setBool('dhikr_reminder_enabled', enabled);
    await prefs.setInt('dhikr_reminder_interval', interval);

    // NEW: Sync with native service for background reliability
    // Access singleton and trigger sync
    PrayerTimesLogic().updatePersistentNotification();
  }
}
