import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:small_husn_muslim/core/services/notification_service.dart';
import 'package:small_husn_muslim/features/todo/models/todo_item.dart';

class TodoNotificationService {
  final NotificationService _notificationService = NotificationService();

  static int notificationIdFor(String taskId) {
    return 80000 + (taskId.hashCode.abs() % 10000);
  }

  /// Prefs key holding the scheduled notification id for [taskId].
  /// Read natively by the home-screen widget to cancel the exact
  /// AlarmManager alarm on widget-side completion (Dart `hashCode`
  /// is not reproducible in Kotlin).
  /// `shared_preferences` adds the `flutter.` prefix automatically.
  static String notifIdKey(String taskId) => 'todo_notif_id_$taskId';

  static Future<void> persistNotifId(String taskId, int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(notifIdKey(taskId), id);
    } catch (e) {
      debugPrint('Error persisting todo notif id: $e');
    }
  }

  static Future<void> clearNotifId(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(notifIdKey(taskId));
    } catch (e) {
      debugPrint('Error clearing todo notif id: $e');
    }
  }

  Future<void> scheduleReminder(TodoItem task) async {
    final reminderTime = task.reminderDateTime;
    if (reminderTime == null) {
      await cancelReminder(task.id);
      return;
    }

    if (reminderTime.isBefore(DateTime.now())) {
      // Past reminder time, do not schedule
      await clearNotifId(task.id);
      return;
    }

    final id = notificationIdFor(task.id);
    // Persisted outside try: must survive even when the plugin call
    // below throws (e.g. exact-alarm permission revoked).
    await persistNotifId(task.id, id);

    try {
      const androidDetails = AndroidNotificationDetails(
        'todo_channel',
        'تذكيرات المهام',
        channelDescription: 'تنبيهات وتذكيرات بمواعيد المهام',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.reminder,
        autoCancel: true,
      );

      final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);

      await _notificationService.flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: task.title,
        body: task.notes?.isNotEmpty == true
            ? task.notes!
            : 'حان موعد إنجاز هذه المهمة',
        scheduledDate: scheduledTz,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'todo_${task.id}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling todo reminder: $e');
      }
    }
  }

  Future<void> cancelReminder(String taskId) async {
    await clearNotifId(taskId);
    try {
      final id = notificationIdFor(taskId);
      await _notificationService.flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling todo reminder: $e');
      }
    }
  }
}
