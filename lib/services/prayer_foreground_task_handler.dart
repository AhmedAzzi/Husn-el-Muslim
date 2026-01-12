import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(PrayerTaskHandler());
}

class PrayerTaskHandler extends TaskHandler {
  Timer? _timer;

  // Data
  String _hijriDate = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Load data
    _hijriDate =
        await FlutterForegroundTask.getData<String>(key: 'hijriDate') ?? '';

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _updateNotificationBuffer();
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Called based on interval in ForegroundTaskOptions
    // We can also update notification here instead of Timer
    // But Timer allows 1 second updates which might be faster than repeat event?
    // If 'interval' is set to 1000ms.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isStopped) async {
    // Wait, the error said (DateTime, bool). ServiceRequest might be the type or bool is the type.
    // I'll try (DateTime timestamp, ServiceRequest request) first if I see ServiceRequest exists.
    // If not, I'll use dynamic to be safe or check the error again.
    // Error said: "Future<void> Function(DateTime, bool)"
    // So the second arg is bool.
    _timer?.cancel();
    await FlutterForegroundTask.clearAllData();
  }

  // To match the signature (DateTime, bool), I'll define it as such:
  // But wait, can I overload? No.
  // I will assume (DateTime timestamp, SendPort? sendPort) was WRONG.
  // And (DateTime timestamp, bool isStopped) might be correct?
  // Let's try matching the error recommendation.

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'openApp') {
      FlutterForegroundTask.launchApp();
    } else if (id == 'refreshGps') {
      FlutterForegroundTask.sendDataToMain('refreshGps');
    }
  }

  Future<void> _updateNotificationBuffer() async {
    final nextPrayerName =
        await FlutterForegroundTask.getData<String>(key: 'nextPrayerName') ??
            '';
    final nextPrayerTimeStr =
        await FlutterForegroundTask.getData<String>(key: 'nextPrayerTime') ??
            '';
    _hijriDate =
        await FlutterForegroundTask.getData<String>(key: 'hijriDate') ?? '';

    if (nextPrayerName.isEmpty || nextPrayerTimeStr.isEmpty) return;

    final nextPrayerTime = DateTime.parse(nextPrayerTimeStr);
    final now = DateTime.now();
    final difference = nextPrayerTime.difference(now);

    String remainingTime;
    if (difference.isNegative) {
      remainingTime = 'الآن';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      if (hours > 0) {
        remainingTime =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        remainingTime =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }

      remainingTime = '- $remainingTime';
    }

    final prayerTimeFormatted =
        '${nextPrayerTime.hour.toString().padLeft(2, '0')}:${nextPrayerTime.minute.toString().padLeft(2, '0')}';

    FlutterForegroundTask.updateService(
      notificationTitle: _hijriDate,
      notificationText:
          '$nextPrayerName في $prayerTimeFormatted ($remainingTime)',
    );
  }
}
