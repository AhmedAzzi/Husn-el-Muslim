import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Helper class to communicate with native Android notification
class PrayerNotificationHelper {
  static const MethodChannel _channel =
      MethodChannel('com.example.hisn_el_muslim/prayer_notification');

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
}
