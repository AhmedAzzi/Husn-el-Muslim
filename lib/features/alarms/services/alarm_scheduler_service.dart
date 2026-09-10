import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Single Dart entry point to the native [AlarmScheduler] (AlarmManager).
///
/// The native side owns exact timing (setAlarmClock / setExactAndAllowWhileIdle,
/// cancel-before-schedule, boot/timezone rescheduling). Dart only computes the
/// next trigger timestamp from prayer times + user offsets and forwards it.
/// Returns `true` only when an alarm was actually armed — never phantom success.
class AlarmSchedulerService {
  AlarmSchedulerService._();
  static final AlarmSchedulerService instance = AlarmSchedulerService._();

  static const MethodChannel _channel =
      MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');

  Future<bool> scheduleSuhoor(int triggerAtMillis) async {
    try {
      final r = await _channel.invokeMethod('scheduleSuhoorAlarm', {
        'trigger_at': triggerAtMillis,
      });
      return r ?? false;
    } catch (e) {
      debugPrint('scheduleSuhoor failed: $e');
      return false;
    }
  }

  Future<bool> schedulePreFajr(int triggerAtMillis) async {
    try {
      final r = await _channel.invokeMethod('schedulePreFajrAlarm', {
        'trigger_at': triggerAtMillis,
      });
      return r ?? false;
    } catch (e) {
      debugPrint('schedulePreFajr failed: $e');
      return false;
    }
  }

  Future<bool> scheduleTahajjud(int triggerAtMillis) async {
    try {
      final r = await _channel.invokeMethod('scheduleTahajjudAlarm', {
        'trigger_at': triggerAtMillis,
      });
      return r ?? false;
    } catch (e) {
      debugPrint('scheduleTahajjud failed: $e');
      return false;
    }
  }

  Future<bool> scheduleFajrExtra1(int triggerAtMillis) async {
    try {
      final r = await _channel.invokeMethod('scheduleFajrExtra1Alarm', {
        'trigger_at': triggerAtMillis,
      });
      return r ?? false;
    } catch (e) {
      debugPrint('scheduleFajrExtra1 failed: $e');
      return false;
    }
  }

  Future<bool> scheduleFajrExtra2(int triggerAtMillis) async {
    try {
      final r = await _channel.invokeMethod('scheduleFajrExtra2Alarm', {
        'trigger_at': triggerAtMillis,
      });
      return r ?? false;
    } catch (e) {
      debugPrint('scheduleFajrExtra2 failed: $e');
      return false;
    }
  }

  Future<bool> scheduleBedtime(int triggerAtMillis) async {
    try {
      final r = await _channel.invokeMethod('scheduleBedtimeAlarm', {
        'trigger_at': triggerAtMillis,
      });
      return r ?? false;
    } catch (e) {
      debugPrint('scheduleBedtime failed: $e');
      return false;
    }
  }

  Future<bool> schedulePrePrayer(int triggerAtMillis, String prayerName) async {
    try {
      final r = await _channel.invokeMethod('schedulePrePrayerAlarm', {
        'trigger_at': triggerAtMillis,
        'prayer_name': prayerName,
      });
      return r ?? false;
    } catch (e) {
      debugPrint('schedulePrePrayer failed: $e');
      return false;
    }
  }

  Future<bool> schedulePostPrayer(
      int triggerAtMillis, String prayerName) async {
    try {
      final r = await _channel.invokeMethod('schedulePostPrayerAlarm', {
        'trigger_at': triggerAtMillis,
        'prayer_name': prayerName,
      });
      return r ?? false;
    } catch (e) {
      debugPrint('schedulePostPrayer failed: $e');
      return false;
    }
  }

  /// Passing 0 cancels (mirrors `scheduleFajrChallengeAlarm(0)` convention).
  Future<bool> cancelSuhoor() => scheduleSuhoor(0);
  Future<bool> cancelPreFajr() => schedulePreFajr(0);
  Future<bool> cancelBedtime() => scheduleBedtime(0);
  Future<bool> cancelTahajjud() => scheduleTahajjud(0);
  Future<bool> cancelFajrExtra1() => scheduleFajrExtra1(0);
  Future<bool> cancelFajrExtra2() => scheduleFajrExtra2(0);

  Future<bool> rescheduleAll() async {
    try {
      final r = await _channel.invokeMethod('rescheduleAllAlarms');
      return r ?? false;
    } catch (e) {
      debugPrint('rescheduleAll failed: $e');
      return false;
    }
  }

  Future<String> diagnostics() async {
    try {
      final r = await _channel.invokeMethod<String>('getAlarmDiagnostics');
      return r ?? 'unavailable';
    } catch (e) {
      return 'diagnostics unavailable: $e';
    }
  }
}
