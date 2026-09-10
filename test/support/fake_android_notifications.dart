import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Records zoned schedules + cancels instead of touching the OS.
/// Register via `FlutterLocalNotificationsPlatform.instance = fake;`
/// (needs `flutter_local_notifications_platform_interface` import at the
/// call site) — the plugin's platform late-init never runs under tests.
class FakeAndroidNotifications extends AndroidFlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> scheduled = [];
  final List<int> cancelled = [];

  void clear() {
    scheduled.clear();
    cancelled.clear();
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    AndroidNotificationDetails? notificationDetails,
    required AndroidScheduleMode scheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'match': matchDateTimeComponents,
      'channel': notificationDetails?.channelId,
      'at': scheduledDate,
    });
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
  }
}
