import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../helpers/prayer_notification_helper.dart';

class PrayerTimesLogic {
  // Singleton pattern
  static final PrayerTimesLogic _instance = PrayerTimesLogic._internal();
  factory PrayerTimesLogic() => _instance;
  PrayerTimesLogic._internal() {
    audioPlayer = AudioPlayer();
  }

  // State variables
  List<PrayerTime>? prayerTimes;
  bool isLoadingPrayerTimes = true;
  bool isLoadingLocation = true;
  Position? currentPosition;
  late AudioPlayer audioPlayer;
  bool hasPlayedAudio = false;

  // Notification settings
  bool notificationsEnabled = true;
  Map<String, bool> prayerNotificationsEnabled = {};
  bool notificationSoundEnabled = true;
  bool persistentNotificationEnabled = true;

  // Display strings
  String gregorianDate = '';
  String hijriDate = '';
  String currentTime = '';

  // Calculation settings
  double lat = 30.0444;
  double lon = 31.2357;
  String asrMethod = 'shafi';
  String angles = 'ms';
  double customFajrAngle = 19.5;
  double customIshaAngle = 17.5;
  bool dstEnabled = false;
  int hijriOffset = 0;

  Timer? _notificationTimer;
  final Set<int> _firedPrayerIndexes = <int>{};
  DateTime _firedDate = DateTime.now();
  String _lastNotificationContent = ''; // Cache to avoid unnecessary updates

  final List<String> arabicPrayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء'
  ];

  // --- Initialization ---

  Future<void> ensureDataLoaded({bool force = false}) async {
    await loadNotificationPreference();

    // Set up callback for refresh GPS button in notification
    PrayerNotificationHelper.setRefreshGpsCallback(() async {
      await _getCurrentLocation();
      _calculateTimes();
      displayDate();
      updatePersistentNotification();
    });

    // If we already have data, don't reload unless forced
    if (!force && prayerTimes != null && !isLoadingLocation) {
      return;
    }

    await _getCurrentLocation();
    _calculateTimes();
  }

  Future<void> _getCurrentLocation() async {
    isLoadingLocation = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLoadingLocation = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLoadingLocation = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        isLoadingLocation = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition = position;
      lat = position.latitude;
      lon = position.longitude;

      // Save location
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', lat);
      await prefs.setDouble('lon', lon);
    } catch (e) {
      if (kDebugMode) print("Error getting location: $e");
    } finally {
      isLoadingLocation = false;
    }
  }

  // --- Calculation Logic (from user provided code) ---

  void _calculateTimes() {
    final today = DateTime.now();
    final timesMap = _computeDayTimes(today.year, today.month, today.day);

    prayerTimes = [
      _createPrayerTime('Fajr', timesMap['fajr']!, today),
      _createPrayerTime('Sunrise', timesMap['sunrise']!, today),
      _createPrayerTime('Dhuhr', timesMap['dhuhr']!, today),
      _createPrayerTime('Asr', timesMap['asr']!, today),
      _createPrayerTime('Maghrib', timesMap['maghrib']!, today),
      _createPrayerTime('Isha', timesMap['isha']!, today),
    ];

    isLoadingPrayerTimes = false;
    displayDate();
  }

  PrayerTime _createPrayerTime(String name, int minutes, DateTime date) {
    final hours = (minutes / 60).floor() % 24;
    final mins = minutes % 60;
    final time = DateTime(date.year, date.month, date.day, hours, mins);
    final time24h =
        '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    return PrayerTime(name: name, time: time, time24h: time24h);
  }

  Map<String, int> _computeDayTimes(int y, int m, int d) {
    final jd = _toJulianDay(y, m, d);
    final sunCoords = _sunCoords(jd);
    final latRad = _deg2rad(lat);
    final noonUTC = _solarNoonUTCMinutes(lon, sunCoords['EoT']!);

    // Get local timezone offset in minutes
    final offset = DateTime(y, m, d).timeZoneOffset.inMinutes;

    final opts = _getOptions();
    final fajrAlt = _deg2rad(-opts['fajrAngle']!);
    final ishaAlt = _deg2rad(-opts['ishaAngle']!);
    final sunriseAlt = _deg2rad(-0.833);

    final Hf = _hourAngleForAltitude(latRad, sunCoords['decl']!, fajrAlt);
    final Hs = _hourAngleForAltitude(latRad, sunCoords['decl']!, sunriseAlt);
    final Hi = _hourAngleForAltitude(latRad, sunCoords['decl']!, ishaAlt);
    final Ha = _hourAngleForAltitude(latRad, sunCoords['decl']!,
        _asrAltitude(latRad, sunCoords['decl']!, opts['asrFactor']!));

    double toMin(double r) => _rad2deg(r) * 4;

    return {
      'fajr': (noonUTC + offset - toMin(Hf) + (dstEnabled ? 60 : 0)).round(),
      'sunrise': (noonUTC + offset - toMin(Hs) + (dstEnabled ? 60 : 0)).round(),
      'dhuhr': (noonUTC + offset + (dstEnabled ? 60 : 0)).round(),
      'asr': (noonUTC + offset + toMin(Ha) + (dstEnabled ? 60 : 0)).round(),
      'maghrib': (noonUTC + offset + toMin(Hs) + (dstEnabled ? 60 : 0)).round(),
      'isha': (noonUTC + offset + toMin(Hi) + (dstEnabled ? 60 : 0)).round(),
    };
  }

  Map<String, double> _getOptions() {
    double fajr = 19.5;
    double isha = 17.5;

    if (angles == 'ms') {
      fajr = 18.0;
      isha = 17.0;
    } else if (angles == 'custom') {
      fajr = customFajrAngle;
      isha = customIshaAngle;
    } else if (angles == 'egypt') {
      fajr = 19.5;
      isha = 17.5;
    }

    return {
      'fajrAngle': fajr,
      'ishaAngle': isha,
      'asrFactor': asrMethod == 'hanafi' ? 2.0 : 1.0,
    };
  }

  double _toJulianDay(int y, int m, int d) {
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final A = (y / 100).floor();
    final B = 2 - A + (A / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        B -
        1524.5;
  }

  Map<String, double> _sunCoords(double jd) {
    final T = (jd - 2451545.0) / 36525;
    final L0 = (280.46646 + 36000.76983 * T + 0.0003032 * T * T) % 360;
    final M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T;
    final e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T * T;
    final Mrad = _deg2rad(M);
    final C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(Mrad) +
        (0.019993 - 0.000101 * T) * sin(2 * Mrad) +
        0.000289 * sin(3 * Mrad);
    final trueLong = L0 + C;
    final Omega = 125.04 - 1934.136 * T;
    final lambda = trueLong - 0.00569 - 0.00478 * sin(_deg2rad(Omega));
    final epsilon0 = 23.439291 -
        0.0130042 * T -
        0.0000001639 * T * T +
        0.0000005036 * T * T * T;
    final epsilon = epsilon0 + 0.00256 * cos(_deg2rad(Omega));
    final lambdaRad = _deg2rad(lambda);
    final epsRad = _deg2rad(epsilon);
    final decl = asin(sin(epsRad) * sin(lambdaRad));

    final y = tan(epsRad / 2);
    final y2 = y * y;
    final sin2L0 = sin(2 * _deg2rad(L0));
    final sinM = sin(Mrad);
    final cos2L0 = cos(2 * _deg2rad(L0));
    final sin4L0 = sin(4 * _deg2rad(L0));
    final sin2M = sin(2 * Mrad);
    final EoT = 4 *
        _rad2deg(y2 * sin2L0 -
            2 * e * sinM +
            4 * e * y2 * sinM * cos2L0 -
            0.5 * y2 * y2 * sin4L0 -
            1.25 * e * e * sin2M);

    return {'decl': decl, 'EoT': EoT};
  }

  double _solarNoonUTCMinutes(double lon, double EoT) {
    return 720 - 4 * lon - EoT;
  }

  double _hourAngleForAltitude(double latRad, double decl, double altitudeRad) {
    final cosH = (sin(altitudeRad) - sin(latRad) * sin(decl)) /
        (cos(latRad) * cos(decl));
    return acos(max(-1, min(1, cosH)));
  }

  double _asrAltitude(double latRad, double decl, double f) {
    return atan(1 / (f + tan((latRad - decl).abs())));
  }

  double _deg2rad(double d) => d * pi / 180;
  double _rad2deg(double r) => r * 180 / pi;

  // --- Date Helpers ---

  String getArabicMonth(int month) {
    const arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return arabicMonths[month - 1];
  }

  String getArabicDayName(int weekday) {
    const arabicDays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return arabicDays[weekday - 1];
  }

  void displayDate() {
    final now = DateTime.now();

    // Gregorian: d MMMM yyyy
    gregorianDate = '${now.day} ${getArabicMonth(now.month)} ${now.year}';

    // Hijri with day name
    final hijri = _gregorianToHijri(now.year, now.month, now.day);
    final dayName = getArabicDayName(now.weekday);
    hijriDate =
        '$dayName ${hijri['day']} ${hijri['monthName']} ${hijri['year']} هـ';

    // Time: HH:mm:ss
    currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _gregorianToHijri(int gy, int gm, int gd) {
    int jd = ((1461 * (gy + 4800 + ((gm - 14) / 12).floor())) / 4).floor() +
        ((367 * (gm - 2 - 12 * ((gm - 14) / 12).floor())) / 12).floor() -
        ((3 * ((gy + 4900 + ((gm - 14) / 12).floor()) / 100).floor()) / 4)
            .floor() +
        gd -
        32075;

    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    int j = (((10985 - l) / 5316).floor()) * ((50 * l / 17719).floor()) +
        ((l / 5670).floor()) * ((43 * l / 15238).floor());
    l = l -
        ((30 - j) / 15).floor() * ((17719 * j / 50).floor()) -
        ((j / 16).floor()) * ((15238 * j / 43).floor()) +
        29;
    int m = ((24 * l) / 709).floor();
    int d = l - ((709 * m) / 24).floor();
    int y = 30 * n + j - 30;

    final months = [
      "محرم",
      "صفر",
      "ربيع الأول",
      "ربيع الآخر",
      "جمادى الأولى",
      "جمادى الآخرة",
      "رجب",
      "شعبان",
      "رمضان",
      "شوال",
      "ذو القعدة",
      "ذو الحجة"
    ];

    return {
      'day': d + hijriOffset,
      'month': m,
      'year': y,
      'monthName': months[m - 1],
    };
  }

  // --- Preferences & Notifications ---

  Future<void> loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    notificationSoundEnabled =
        prefs.getBool('notificationSoundEnabled') ?? true;
    persistentNotificationEnabled =
        prefs.getBool('persistentNotificationEnabled') ?? true;

    // Load calculation settings
    dstEnabled = prefs.getBool('dstEnabled') ?? false;
    hijriOffset = prefs.getInt('hijriOffset') ?? 0;
    lat = prefs.getDouble('lat') ?? 30.0444;
    lon = prefs.getDouble('lon') ?? 31.2357;
    asrMethod = prefs.getString('asrMethod') ?? 'shafi';
    angles = prefs.getString('angles') ?? 'ms';

    for (var name in arabicPrayerNames) {
      prayerNotificationsEnabled[name] =
          prefs.getBool('notification_$name') ?? true;
    }

    if (persistentNotificationEnabled || notificationsEnabled) {
      startNotificationUpdates();
    }
  }

  Future<void> saveCalculationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lat', lat);
    await prefs.setDouble('lon', lon);
    await prefs.setString('asrMethod', asrMethod);
    await prefs.setString('angles', angles);
    await prefs.setBool('dstEnabled', dstEnabled);
    await prefs.setInt('hijriOffset', hijriOffset);

    _calculateTimes();
  }

  Future<void> saveNotificationPreference(
      bool globalValue, Map<String, bool> prayerValues, bool soundValue,
      {bool? persistentValue}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', globalValue);
    await prefs.setBool('notificationSoundEnabled', soundValue);
    if (persistentValue != null) {
      await prefs.setBool('persistentNotificationEnabled', persistentValue);
      persistentNotificationEnabled = persistentValue;
    }
    for (var entry in prayerValues.entries) {
      await prefs.setBool('notification_${entry.key}', entry.value);
    }

    notificationsEnabled = globalValue;
    prayerNotificationsEnabled = prayerValues;
    notificationSoundEnabled = soundValue;

    if (globalValue) {
      schedulePrayerTimeNotifications();
    } else {
      NotificationService().cancelAllNotifications();
    }

    if (persistentNotificationEnabled) {
      startNotificationUpdates();
      updatePersistentNotification();
    } else {
      PrayerNotificationHelper.hideNotification();
      if (!notificationsEnabled) {
        stopNotificationUpdates();
      }
    }

    if (notificationsEnabled) {
      startNotificationUpdates();
    }
  }

  void startNotificationUpdates() {
    _notificationTimer?.cancel();
    // Update every second for smooth countdown display
    _notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (persistentNotificationEnabled) {
        updatePersistentNotification();
      }
      if (notificationsEnabled) {
        checkPrayerNotifications();
      }
      if (!persistentNotificationEnabled && !notificationsEnabled) {
        stopNotificationUpdates();
      }
    });

    // Immediately update once when starting
    if (persistentNotificationEnabled) {
      updatePersistentNotification();
    }
  }

  void stopNotificationUpdates() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  void updatePersistentNotification() async {
    if (!persistentNotificationEnabled) {
      await PrayerNotificationHelper.hideNotification();
      return;
    }

    final nextPrayer = getNextPrayerInfo();
    if (nextPrayer['name'].isEmpty || prayerTimes == null) {
      return;
    }

    // Format: الفجر في 06:25
    final prayerInfo = '${nextPrayer['name']} في ${nextPrayer['prayerTime']}';
    final remainingTime = nextPrayer['timeRemaining'] == 'الآن'
        ? 'الآن'
        : '- ${nextPrayer['timeRemaining']}';

    // Create content key to check if update is needed
    final contentKey = '$hijriDate|$prayerInfo|$remainingTime';

    // Only update notification if content changed (saves battery)
    if (contentKey != _lastNotificationContent) {
      _lastNotificationContent = contentKey;
      await PrayerNotificationHelper.showPrayerNotification(
        hijriDate: hijriDate,
        prayerInfo: prayerInfo,
        remainingTime: remainingTime,
      );
    }
  }

  Map<String, dynamic> getNextPrayerInfo() {
    if (prayerTimes == null || prayerTimes!.isEmpty) {
      return {'name': '', 'timeRemaining': ''};
    }

    final now = DateTime.now();
    final arabicNames = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء'
    };

    PrayerTime? nextPrayer;
    DateTime? nextTime;

    for (var prayer in prayerTimes!) {
      if (prayer.name == 'Sunrise') continue;
      final prayerDateTime = prayer.time;
      if (prayerDateTime.isAfter(now)) {
        if (nextTime == null || prayerDateTime.isBefore(nextTime)) {
          nextTime = prayerDateTime;
          nextPrayer = prayer;
        }
      }
    }

    if (nextPrayer == null) {
      final fajrToday = prayerTimes!.firstWhere((p) => p.name == 'Fajr');
      nextPrayer =
          fajrToday.copyWith(time: fajrToday.time.add(const Duration(days: 1)));
      nextTime = nextPrayer.time;
    }

    final remaining = nextTime!.difference(now);

    if (remaining.inSeconds <= 0 && remaining.inSeconds >= -9) {
      return {
        'name': arabicNames[nextPrayer.name] ?? nextPrayer.name,
        'timeRemaining': 'الآن',
        'prayerTime': nextPrayer.time24h,
      };
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    String remainingTime = '';
    if (hours > 0) {
      remainingTime += '${hours.toString().padLeft(2, '0')}:';
    }
    remainingTime +=
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return {
      'name': arabicNames[nextPrayer.name] ?? nextPrayer.name,
      'timeRemaining': remainingTime,
      'prayerTime': nextPrayer.time24h,
    };
  }

  void schedulePrayerTimeNotifications() {
    if (prayerTimes == null || prayerTimes!.isEmpty || !notificationsEnabled) {
      return;
    }
    NotificationService().cancelAllNotifications();

    for (int i = 0; i < prayerTimes!.length; i++) {
      final prayer = prayerTimes![i];
      final prayerName = arabicPrayerNames[i];

      if (prayerNotificationsEnabled[prayerName] == true) {
        final now = DateTime.now();
        DateTime scheduledDate = prayer.time;
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        NotificationService().showNotification(
          i,
          'وقت الصلاة',
          'حان الآن وقت صلاة $prayerName',
          scheduledDate,
          notificationSoundEnabled,
        );
      }
    }
  }

  void checkPrayerNotifications() {
    if (!notificationsEnabled || prayerTimes == null) return;
    final now = DateTime.now();

    if (_firedDate.year != now.year ||
        _firedDate.month != now.month ||
        _firedDate.day != now.day) {
      _firedPrayerIndexes.clear();
      _firedDate = now;
    }

    for (int i = 0; i < prayerTimes!.length; i++) {
      if (_firedPrayerIndexes.contains(i)) continue;

      final prayer = prayerTimes![i];
      final scheduledDate = prayer.time;
      final difference = now.difference(scheduledDate);

      if (!scheduledDate.isAfter(now) && difference.inSeconds.abs() <= 60) {
        final prayerName =
            arabicPrayerNames.length > i ? arabicPrayerNames[i] : 'صلاة';
        if (prayerNotificationsEnabled[prayerName] == true) {
          NotificationService().showImmediateNotification(
            i + 1000,
            'وقت الصلاة',
            'حان الآن وقت صلاة $prayerName',
            notificationSoundEnabled,
          );
          if (notificationSoundEnabled) playAudio();
          _firedPrayerIndexes.add(i);
        }
      }
    }
  }

  void playAudio() async {
    if (!hasPlayedAudio) {
      try {
        await audioPlayer.play(AssetSource('adan.mp3'));
        hasPlayedAudio = true;
      } catch (e) {
        if (kDebugMode) print('playAudio error: $e');
      }
    }
  }

  void dispose() {
    _notificationTimer?.cancel();
    audioPlayer.dispose();
  }
}

class PrayerTime {
  final String name;
  final DateTime time;
  final String time24h;

  PrayerTime({
    required this.name,
    required this.time,
    required this.time24h,
  });

  PrayerTime copyWith({String? name, DateTime? time, String? time24h}) {
    return PrayerTime(
      name: name ?? this.name,
      time: time ?? this.time,
      time24h: time24h ?? this.time24h,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) print('Notification tapped: ${response.payload}');
      },
    );
    await _requestPermissions();
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  Future<void> showNotification(int id, String title, String body,
      DateTime scheduledDate, bool soundEnabled) async {
    final androidDetails = AndroidNotificationDetails(
      'prayer_times_channel',
      'مواقيت الصلاة',
      channelDescription: 'تنبيهات أوقات الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showImmediateNotification(
      int id, String title, String body, bool soundEnabled) async {
    final androidDetails = AndroidNotificationDetails(
      'prayer_times_immediate',
      'تنبيه الصلاة الفوري',
      channelDescription: 'تنبيهات فورية لأوقات الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
