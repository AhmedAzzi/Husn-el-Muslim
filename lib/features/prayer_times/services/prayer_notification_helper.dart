import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Helper class to communicate with native Android notification
class PrayerNotificationHelper {
  static const MethodChannel _channel =
      MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');

  /// Set callback for when refresh GPS button is pressed in notification
  static void setMethodCallHandler({
    required Function onRefreshGps,
    required Function(String) onTriggerAlarm,
    required Function(String) onOpenScreen,
    required Function onStopAdhan, // New param
  }) {
    // Set up method call handler to receive calls from native
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'refreshGps') {
        onRefreshGps.call();
      } else if (call.method == 'triggerPrayerAlarm') {
        final prayerName = call.arguments['prayer_name'] as String?;
        if (prayerName != null) {
          onTriggerAlarm(prayerName);
        }
      } else if (call.method == 'openScreen') {
        final screenName = call.arguments['screen_name'] as String?;
        if (screenName != null) {
          onOpenScreen(screenName);
        }
      } else if (call.method == 'stopAdhan') {
        onStopAdhan.call();
      }
    });
  }

  static Future<bool> showPrayerNotification({
    required String hijriDate,
    required String prayerInfo,
    required String remainingTime,
  }) async {
    try {
      final result = await _channel.invokeMethod('showPrayerNotification', {
        'hijri_date': hijriDate,
        'prayer_info': prayerInfo,
        'remaining_time': remainingTime,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error showing prayer notification: $e');
      return false;
    }
  }

  /// Start persistent notification with countdown
  static Future<bool> startPrayerCountdown({
    required String hijriDate,
    required String prayerInfo,
    required String nextPrayerName,
    required int targetTimestamp,
    int? nextTargetTimestamp,
    String? nextTargetPrayerName,
    String? nextPrayerInfo,
    int? challengeTimestamp,
    bool isBlackBackground = false,
    int notificationMode = 0,
    bool? dhikrEnabled,
    int? dhikrIntervalMinutes,
    List<String>? dhikrList,
  }) async {
    try {
      final result = await _channel.invokeMethod('startPrayerCountdown', {
        'hijri_date': hijriDate,
        'prayer_info': prayerInfo,
        'next_prayer_name': nextPrayerName,
        'target_timestamp': targetTimestamp,
        'next_target_timestamp': nextTargetTimestamp,
        'next_target_prayer_name': nextTargetPrayerName,
        'next_prayer_info': nextPrayerInfo,
        'challenge_timestamp': challengeTimestamp,
        'is_black_background': isBlackBackground,
        'notification_mode': notificationMode,
        'dhikr_enabled': dhikrEnabled,
        'dhikr_interval': dhikrIntervalMinutes,
        'dhikr_list': dhikrList,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error starting prayer countdown: $e');
      return false;
    }
  }

  /// Re-render any pinned home-screen prayer widgets from cached data.
  /// Fire-and-forget: safe to call even when no widget is pinned.
  static Future<void> updatePrayerWidgets() async {
    try {
      await _channel.invokeMethod('updatePrayerWidgets');
    } catch (e) {
      debugPrint('Error updating prayer widgets: $e');
    }
  }

  /// Hide the persistent notification
  static Future<bool> hideNotification() async {
    try {
      final result = await _channel.invokeMethod('hideNotification');
      return result ?? false;
    } catch (e) {
      debugPrint('Error hiding notification: $e');
      return false;
    }
  }

  /// Check for a pending screen to open (e.g. from notification click during cold start)
  static Future<String?> getPendingScreen() async {
    try {
      final String? screenName =
          await _channel.invokeMethod('getPendingScreen');
      return screenName;
    } catch (e) {
      debugPrint('Error getting pending screen: $e');
      return null;
    }
  }

  /// Check for a pending alarm trigger (e.g. AlarmManager fired during cold start)
  static Future<String?> getPendingAlarm() async {
    try {
      final String? prayerName = await _channel.invokeMethod('getPendingAlarm');
      return prayerName;
    } catch (e) {
      debugPrint('Error getting pending alarm: $e');
      return null;
    }
  }

  /// Cancel the Fajr challenge full-screen notification and its exact alarm
  static Future<bool> cancelAlarmNotification() async {    try {
      final result = await _channel.invokeMethod('cancelAlarmNotification');
      return result ?? false;
    } catch (e) {
      debugPrint('Error cancelling alarm notification: $e');
      return false;
    }
  }

  /// Play a short preview of the selected alarm sound (native side).
  static Future<bool> previewAlarmSound() async {
    try {
      final result = await _channel.invokeMethod('previewAlarmSound');
      return result ?? false;
    } catch (e) {
      debugPrint('Error previewing alarm sound: $e');
      return false;
    }
  }

  /// Stop a running sound preview.
  static Future<bool> stopAlarmPreview() async {
    try {
      final result = await _channel.invokeMethod('stopAlarmPreview');
      return result ?? false;
    } catch (e) {
      debugPrint('Error stopping alarm preview: $e');
      return false;
    }
  }

  /// Check if the app has the "Appear on top" (overlay) permission
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool? result = await _channel.invokeMethod('checkOverlayPermission');
      return result ?? true;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return true;
    }
  }

  /// Request the "Appear on top" permission
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
    }
  }

  /// Test Ayat Overlay
  static Future<bool> testAyatOverlay() async {
    try {
      final result = await _channel.invokeMethod('testAyatOverlay');
      return result ?? false;
    } catch (e) {
      debugPrint('Error testing Ayat overlay: $e');
      return false;
    }
  }

  /// True when the app is currently allowed to schedule exact alarms.
  /// Always true pre-Android 12; on 12+ reflects the "Alarms & reminders"
  /// system toggle, which the user can revoke at any time.
  static Future<bool> canScheduleExactAlarms() async {
    try {
      final bool? result =
          await _channel.invokeMethod('canScheduleExactAlarms');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Opens the per-app "Alarms & reminders" system screen (Android 12+)
  /// so the user can grant exact-alarm permission. No-op on older versions.
  static Future<void> openExactAlarmSettings() async {
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      debugPrint('Error opening exact alarm settings: $e');
    }
  }

  /// Schedule the real Fajr challenge native alarm a few seconds from now for testing.
  static Future<bool> testFajrChallengeAlarm({int delaySeconds = 5}) async {
    try {
      final result = await _channel.invokeMethod('testFajrChallengeAlarm', {
        'delay_seconds': delaySeconds,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error testing Fajr challenge alarm: $e');
      return false;
    }
  }

  /// Schedule (or cancel with 0) the Fajr challenge exact alarm natively,
  /// independent of the persistent notification service.
  static Future<bool> scheduleFajrChallengeAlarm(int challengeTimestamp) async {
    try {
      final result = await _channel.invokeMethod('scheduleFajrChallengeAlarm', {
        'challenge_timestamp': challengeTimestamp,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling Fajr challenge alarm: $e');
      return false;
    }
  }

  /// Allow/disallow the app from rendering above the lock screen.
  /// Only used while an alarm / Fajr challenge is active.
  static Future<bool> setLockScreenMode(bool enable) async {
    try {
      final result = await _channel.invokeMethod(
          enable ? 'enableLockScreenMode' : 'disableLockScreenMode');
      return result ?? false;
    } catch (e) {
      debugPrint('Error setting lock screen mode: $e');
      return false;
    }
  }

  /// Suhoor alarm anchored to Fajr. Passing 0 cancels.
  static Future<bool> scheduleSuhoorAlarm(int triggerAtMillis) async {
    try {
      final result = await _channel.invokeMethod('scheduleSuhoorAlarm', {
        'trigger_at': triggerAtMillis,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling Suhoor alarm: $e');
      return false;
    }
  }

  /// Pre-Fajr gentle warning anchored to Fajr. Passing 0 cancels.
  static Future<bool> schedulePreFajrAlarm(int triggerAtMillis) async {
    try {
      final result = await _channel.invokeMethod('schedulePreFajrAlarm', {
        'trigger_at': triggerAtMillis,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling Pre-Fajr alarm: $e');
      return false;
    }
  }

  /// Tahajjud night-prayer wake-up (Last-Third auto or fixed time). Passing 0 cancels.
  static Future<bool> scheduleTahajjudAlarm(int triggerAtMillis) async {
    try {
      final result = await _channel.invokeMethod('scheduleTahajjudAlarm', {
        'trigger_at': triggerAtMillis,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling Tahajjud alarm: $e');
      return false;
    }
  }

  /// Heavy-sleeper chain: re-fires the Fajr challenge +N min. Passing 0 cancels.
  static Future<bool> scheduleFajrExtra1Alarm(int triggerAtMillis) async {
    try {
      final result = await _channel.invokeMethod('scheduleFajrExtra1Alarm', {
        'trigger_at': triggerAtMillis,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling Fajr extra 1 alarm: $e');
      return false;
    }
  }

  static Future<bool> scheduleFajrExtra2Alarm(int triggerAtMillis) async {
    try {
      final result = await _channel.invokeMethod('scheduleFajrExtra2Alarm', {
        'trigger_at': triggerAtMillis,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling Fajr extra 2 alarm: $e');
      return false;
    }
  }

  /// Bedtime reminder (exact clock time or Fajr-relative). Passing 0 cancels.
  static Future<bool> scheduleBedtimeAlarm(int triggerAtMillis) async {
    try {
      final result = await _channel.invokeMethod('scheduleBedtimeAlarm', {
        'trigger_at': triggerAtMillis,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling bedtime alarm: $e');
      return false;
    }
  }

  /// Pre-prayer reminder for [prayerName]. Passing 0 cancels.
  static Future<bool> schedulePrePrayerAlarm(
      int triggerAtMillis, String prayerName) async {
    try {
      final result = await _channel.invokeMethod('schedulePrePrayerAlarm', {
        'trigger_at': triggerAtMillis,
        'prayer_name': prayerName,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling pre-prayer alarm: $e');
      return false;
    }
  }

  /// Post-prayer reminder for [prayerName]. Passing 0 cancels.
  static Future<bool> schedulePostPrayerAlarm(
      int triggerAtMillis, String prayerName) async {
    try {
      final result = await _channel.invokeMethod('schedulePostPrayerAlarm', {
        'trigger_at': triggerAtMillis,
        'prayer_name': prayerName,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error scheduling post-prayer alarm: $e');
      return false;
    }
  }

  /// Re-arm everything from persisted prefs (boot/tz/date/permission flows).
  static Future<bool> rescheduleAllAlarms() async {
    try {
      final result = await _channel.invokeMethod('rescheduleAllAlarms');
      return result ?? false;
    } catch (e) {
      debugPrint('Error rescheduling alarms: $e');
      return false;
    }
  }

  /// Native diagnostics string for Advanced → Diagnostics.
  static Future<String> getAlarmDiagnostics() async {
    try {
      final String? r = await _channel.invokeMethod('getAlarmDiagnostics');
      return r ?? 'unavailable';
    } catch (e) {
      return 'diagnostics unavailable: $e';
    }
  }

  /// Check whether Do Not Disturb policy access is granted on Android.
  static Future<bool> isDndAccessGranted() async {
    try {
      final bool? r = await _channel.invokeMethod('isDndAccessGranted');
      return r ?? false;
    } catch (e) {
      debugPrint('Error checking DND policy access: $e');
      return false;
    }
  }

  /// Deep-link to Android's "Do Not Disturb access" settings page.
  static Future<bool> openDndSettings() async {
    try {
      final bool? r = await _channel.invokeMethod('openDndSettings');
      return r ?? false;
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
      return false;
    }
  }

  /// Manually enable or disable Do Not Disturb mode via native policy.
  static Future<bool> setDndMode(bool enable) async {
    try {
      final bool? r = await _channel.invokeMethod('setDndMode', {'enable': enable});
      return r ?? false;
    } catch (e) {
      debugPrint('Error setting DND mode: $e');
      return false;
    }
  }
}
