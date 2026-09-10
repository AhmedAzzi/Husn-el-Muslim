import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/constants/notification_ids.dart';
import 'package:small_husn_muslim/features/azkar/data/azkar_info.dart';
import 'package:small_husn_muslim/features/azkar/presentation/azkar_details_screen.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/prayer_tracking_screen.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? pendingPayload;

  Future<void> handleAdhkarNotification(String payload) async {
    final String category = switch (payload) {
      NotificationIds.morningAdhkarPayload => 'أذكار الصباح',
      NotificationIds.eveningAdhkarPayload => 'أذكار المساء',
      NotificationIds.wakeupAdhkarPayload => 'أذكار الاستيقاظ من النوم',
      NotificationIds.sleepAdhkarPayload => 'أذكار النوم',
      _ => '',
    };

    if (category.isEmpty) return;

    if (Get.context != null) {
      // Load azkar data to find the matching category
      final String jsonData =
          await rootBundle.loadString('assets/hisnmuslim.json');
      final List<dynamic> jsonList = json.decode(jsonData);
      final azkarList =
          jsonList.map((json) => AzkarInfo.fromJson(json)).toList();

      try {
        final targetAzkar =
            azkarList.firstWhere((element) => element.category.contains(category) || category.contains(element.category));
        Get.to(() => AzkarDetailsScreen(azkarInfo: targetAzkar));
      } catch (e) {
        if (kDebugMode) print('Error finding azkar category: $e');
      }
    } else {
      pendingPayload = payload;
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Check if app was launched by notification
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        pendingPayload = payload;
      }
    }

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) print('Notification tapped: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          if (response.payload == 'Fajr_Challenge') {
            if (Get.context != null) {
              Get.to(() => const FajrChallengeScreen());
            } else {
              pendingPayload = response.payload;
            }
          } else if (response.payload == NotificationIds.morningAdhkarPayload ||
              response.payload == NotificationIds.eveningAdhkarPayload ||
              response.payload == NotificationIds.wakeupAdhkarPayload ||
              response.payload == NotificationIds.sleepAdhkarPayload) {
            handleAdhkarNotification(response.payload!);
          } else if (response.payload == NotificationIds.trackerLogPayload) {
            if (Get.context != null) {
              Get.to(() => const PrayerTrackingScreen());
            } else {
              pendingPayload = response.payload;
            }
          }
        }
      },
    );
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  Future<void> showNotification(int id, String title, String body,
      DateTime scheduledDate, bool soundEnabled,
      {String? payload, bool isAlarm = true, String? channel}) async {
    final resolved = channel ?? (isAlarm ? 'prayer_times_channel' : 'adhkar_channel');
    final resolvedName = switch (resolved) {
      'fajr_wakeup_channel' => 'منبه الفجر',
      'suhoor_channel' => 'منبه السحور',
      'bedtime_channel' => 'تذكير النوم',
      'tracking_channel' => 'التتبع',
      'adhkar_channel' => 'تنبيهات الأذكار',
      _ => 'مواقيت الصلاة',
    };
    final androidDetails = AndroidNotificationDetails(
      resolved,
      resolvedName,
      channelDescription:
          isAlarm ? 'تنبيهات أوقات الصلاة' : 'تنبيهات أذكار الصباح والمساء',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
      category: isAlarm
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      fullScreenIntent: isAlarm,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> showWeeklyNotification(int id, String title, String body,
      DateTime scheduledDate, bool soundEnabled,
      {String? payload, String? channel}) async {
    final resolved = channel ?? 'adhkar_channel';
    final androidDetails = AndroidNotificationDetails(
      resolved,
      'تنبيهات الأذكار',
      channelDescription: 'تذكير سورة الكهف والأذكار الأسبوعية',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  /// One-shot exact schedule (fires once, never repeats). Used by the
  /// prayer-tracker logging reminders, which are recomputed daily and must
  /// NOT use the daily-repeating [showNotification].
  Future<void> scheduleOneShotNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    bool soundEnabled, {
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'التتبع',
      channelDescription: 'تذكيرات تسجيل الصلوات',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
