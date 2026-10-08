import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/constants/notification_ids.dart';
import 'package:small_husn_muslim/features/azkar/data/azkar_info.dart';
import 'package:small_husn_muslim/features/azkar/controllers/azkar_controller.dart';
import 'package:small_husn_muslim/features/azkar/presentation/azkar_details_screen.dart';
import 'package:small_husn_muslim/core/utils/asset_loader.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? pendingPayload;

  /// Same hisnmuslim.json content parsed off the UI isolate. Null on error
  /// (caller keeps prior fallback behavior of doing nothing).
  static Future<List<AzkarInfo>?> _loadAzkarOffMain() async {
    try {
      final jsonData = await loadAzkarJson();
      return await compute(_parseAzkarList, jsonData);
    } catch (_) {
      return null;
    }
  }

  static List<AzkarInfo> _parseAzkarList(String jsonData) {
    final List<dynamic> jsonList = json.decode(jsonData);
    return jsonList.map((j) => AzkarInfo.fromJson(j)).toList();
  }

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
      // Perf-only: reuse the already-loaded AzkarController list when
      // available; otherwise parse the same JSON off the UI isolate with
      // the same parser/matcher. Same category, destination, fallback.
      List<AzkarInfo>? azkarList;
      try {
        if (Get.isRegistered<AzkarController>()) {
          final ctl = Get.find<AzkarController>();
          if (!ctl.isLoading.value && ctl.azkarList.isNotEmpty) {
            azkarList = ctl.azkarList.toList();
          }
        }
      } catch (_) {
        azkarList = null;
      }
      azkarList ??= await _loadAzkarOffMain();
      if (azkarList == null) return;

      try {
        final list = azkarList;
        final targetAzkar =
            list.firstWhere((element) => element.category.contains(category) || category.contains(element.category));
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

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
