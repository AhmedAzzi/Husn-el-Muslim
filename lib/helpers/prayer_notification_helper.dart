import 'package:flutter/services.dart';

/// Helper class to communicate with native Android notification
class PrayerNotificationHelper {
  static const MethodChannel _channel =
      MethodChannel('com.example.hisn_el_muslim/prayer_notification');

  static Function? _onRefreshGpsCallback;

  /// Set callback for when refresh GPS button is pressed in notification
  static void setRefreshGpsCallback(Function callback) {
    _onRefreshGpsCallback = callback;

    // Set up method call handler to receive calls from native
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'refreshGps') {
        _onRefreshGpsCallback?.call();
      }
    });
  }

  /// Show persistent notification with prayer information
  ///
  /// Example:
  /// ```dart
  /// await PrayerNotificationHelper.showPrayerNotification(
  ///   hijriDate: '٢٣ جمادى الأولى ١٤٤٦',
  ///   prayerInfo: 'العشاء - ٢٠:٣٠',
  ///   remainingTime: 'الوقت المتبقي: ١ساعة ١٥ دقيقة',
  /// );
  /// ```
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
      print('Error showing prayer notification: $e');
      return false;
    }
  }

  /// Hide the persistent notification
  static Future<bool> hideNotification() async {
    try {
      final result = await _channel.invokeMethod('hideNotification');
      return result ?? false;
    } catch (e) {
      print('Error hiding notification: $e');
      return false;
    }
  }
}
