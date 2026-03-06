import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/azkar_info.dart';
import '../screens/fajr_challenge_screen.dart';
import '../screens/prayer_times_screen.dart';
import '../screens/azkar_details_screen.dart';
import '../helpers/prayer_notification_helper.dart'; // Keep this import
import '../dialogs/ayat_hadith_dialog.dart';

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
  bool persistentNotificationBlackBg = false;
  bool fajrChallengeEnabled = false;
  int fajrChallengeQuestionsCount = 3;
  bool fajrChallengeIsTextInput = false;
  bool morningAdhkarEnabled = true;
  bool eveningAdhkarEnabled = true;
  bool nightPrayerTimesEnabled = true;

  // Notification behavior:
  // 0: Both notification and prayer screen (default)
  // 1: Notification only
  // 2: Prayer screen only
  // 3: No alert
  int notificationMode = 0;

  // Prayer time offsets (in seconds)
  Map<String, int> prayerOffsets = {
    'Fajr': 60,
    'Sunrise': 60,
    'Dhuhr': 120,
    'Asr': 120,
    'Maghrib':
        300, // Default 300 seconds (5 mins) offset to match official times
    'Isha': 120,
  };

  // Fajr Challenge Wake Up Settings
  // 'auto': Wake up at Last Third
  // 'custom': Wake up X minutes before Fajr
  String fajrChallengeWakeUpMode = 'auto';
  int fajrChallengeCustomOffsetMinutes = 30; // Default 30 mins before Fajr

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
  int hijriOffset = -3; // Default -3 offset to match 16 Ramadan 1447

  Timer? _notificationTimer;
  final Set<int> _firedPrayerIndexes = <int>{};
  DateTime _firedDate = DateTime.now();
  // _lastNotificationContent removed as unused
  int? _lastSentTargetTimestamp;

  final List<String> arabicPrayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
    'الشروق',
    'الثلث الأول',
    'منتصف الليل',
    'الثلث الأخير'
  ];

  // --- Initialization ---

  Future<void> ensureDataLoaded({bool force = false}) async {
    await loadNotificationPreference();

    // Calculate times immediately using cached location (prefs)
    _calculateTimes();

    // If not forced (just entering screen), show cached data immediately
    if (!force) {
      isLoadingPrayerTimes = false;
      isLoadingLocation = false;
    }

    // Set up callback for native triggers (GPS refresh and Prayer Alarms)
    PrayerNotificationHelper.setMethodCallHandler(
      onRefreshGps: () async {
        await _getCurrentLocation(background: false); // Interactive refresh
        _calculateTimes();
        displayDate();
        updatePersistentNotification();
      },
      onTriggerAlarm: (prayerName) {
        _handleTriggeredAlarm(prayerName);
      },
      onOpenScreen: (screenName) {
        if (screenName == 'prayer_times') {
          if (Get.context != null) {
            Get.to(() => const PrayerTimesScreen());
          }
        }
      },
      onStopAdhan: () {
        stopAudio();
      },
    );

    // Handle any pending screen from native side (e.g. cold start launch)
    final pendingScreen = await PrayerNotificationHelper.getPendingScreen();
    if (pendingScreen != null) {
      if (pendingScreen == 'prayer_times') {
        if (Get.context != null) {
          Get.to(() => const PrayerTimesScreen());
        }
      }
    }

    // Check availability and fetch fresh location
    // Always request location on first load or when forced
    if (force || currentPosition == null || !_hasCachedLocation) {
      if (force) {
        await _getCurrentLocation(background: false);
        _calculateTimes();
      } else {
        // Request location with user interaction if no cached location
        if (!_hasCachedLocation) {
          await _getCurrentLocation(background: false);
          _calculateTimes();
          updatePersistentNotification();
        } else {
          // Background fetch if we have cached location
          _getCurrentLocation(background: true).then((_) {
            _calculateTimes();
            updatePersistentNotification();
          });
        }
      }
    }
  }

  // Track if we have a valid cached location
  bool _hasCachedLocation = false;

  // Getter to check if cached location is available
  bool get hasCachedLocation => _hasCachedLocation;

  Future<void> _getCurrentLocation({bool background = false}) async {
    if (!background) {
      isLoadingLocation = true;
    }

    // First, ensure we have cached location loaded from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedLat = prefs.getDouble('lat');
    final cachedLon = prefs.getDouble('lon');

    // If we have cached values, use them immediately
    if (cachedLat != null && cachedLon != null) {
      _hasCachedLocation = true;
      // Only update lat/lon if they are still at default values
      // This prevents overwriting fresh GPS data with stale cache
      if (currentPosition == null) {
        lat = cachedLat;
        lon = cachedLon;
        if (kDebugMode) print("Using cached location: ($lat, $lon)");
      }
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print("Location service disabled");
        }

        // Only show dialog if this is a foreground/user-initiated request
        if (!background) {
          // Prompt user to enable location services
          final shouldOpenSettings = await _showEnableLocationDialog();
          if (shouldOpenSettings == true) {
            // Open location settings
            await Geolocator.openLocationSettings();

            // Wait for user to enable GPS and return to app
            await Future.delayed(const Duration(seconds: 2));
            serviceEnabled = await Geolocator.isLocationServiceEnabled();

            if (!serviceEnabled) {
              if (kDebugMode) print("Location services still disabled");
              isLoadingLocation = false;
              return;
            }
            // GPS is now enabled, continue with location fetch
            if (kDebugMode) print("Location services enabled successfully");

            // Now that GPS is enabled, immediately request location permission
            // This will show the system permission dialog
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              if (kDebugMode) print("Requesting location permission...");
              permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.denied) {
                if (kDebugMode) {
                  print("Location permission denied by user");
                }
                isLoadingLocation = false;
                return;
              }
            }

            if (permission == LocationPermission.deniedForever) {
              if (kDebugMode) {
                print("Location permission denied forever");
              }
              _showPermissionDeniedDialog();
              isLoadingLocation = false;
              return;
            }

            // Permission granted, continue to fetch location
            if (kDebugMode) print("Location permission granted: $permission");
          } else {
            // User declined to enable location services
            if (kDebugMode) print("User declined to enable location services");
            isLoadingLocation = false;
            return;
          }
        } else {
          // Background request, just use cached location
          isLoadingLocation = false;
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print("Location permission denied, using cached location");
          }
          isLoadingLocation = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print("Location permission denied forever, using cached location");
        }

        // Only show dialog if this is a foreground request
        if (!background) {
          _showPermissionDeniedDialog();
        }

        isLoadingLocation = false;
        return;
      }

      // On Android 10+ (API 29+), background location requires a separate permission
      // First ensure we have foreground permission (whileInUse or always)
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (kDebugMode) {
          print("Have foreground location permission: $permission");
        }

        // Try to request background permission for "Allow all the time"
        // This is needed for the persistent notification to work properly
        if (permission == LocationPermission.whileInUse) {
          if (kDebugMode) {
            print(
                "Requesting background location permission for 'Allow all the time'...");
          }
          // Use native method channel to request background permission on Android 10+
          try {
            const platform =
                MethodChannel('com.example.hisn_el_muslim/location');
            final bool granted = await platform
                .invokeMethod('requestBackgroundLocationPermission');
            if (kDebugMode) {
              print("Background permission granted: $granted");
            }
          } catch (e) {
            if (kDebugMode) {
              print("Error requesting background permission: $e");
            }
          }
        }
      }
      // Try to get last known position first (faster and works even when GPS is temporarily blocked)
      Position? position = await Geolocator.getLastKnownPosition();

      // If no last known position, get current position
      if (position == null) {
        if (kDebugMode) {
          print("No last known position, fetching current position...");
        }
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } else {
        if (kDebugMode) print("Using last known position");
      }

      currentPosition = position;
      lat = position.latitude;
      lon = position.longitude;
      _hasCachedLocation = true;

      // Save location to cache
      await prefs.setDouble('lat', lat);
      await prefs.setDouble('lon', lon);
      if (kDebugMode) print("GPS location saved to cache: ($lat, $lon)");
    } catch (e) {
      if (kDebugMode) {
        print(
            "Error getting location: $e - will use cached location if available");
      }
    } finally {
      isLoadingLocation = false;
    }
  }

  // Show dialog to prompt user to enable location services
  Future<bool?> _showEnableLocationDialog() async {
    if (Get.context == null) return false;

    return await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Color(0xFFD64463)),
              SizedBox(width: 8),
              Text(
                'خدمات الموقع معطلة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'لحساب مواقيت الصلاة بدقة، يرجى تفعيل خدمات الموقع (GPS) من إعدادات الجهاز.',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64463),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'فتح الإعدادات',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Show dialog when permission is permanently denied
  void _showPermissionDeniedDialog() {
    if (Get.context == null) return;

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_disabled, color: Color(0xFFD64463)),
              SizedBox(width: 8),
              Text(
                'إذن الموقع مرفوض',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'تم رفض إذن الوصول إلى الموقع بشكل دائم. لتفعيل مواقيت الصلاة، يرجى منح التطبيق إذن الموقع من إعدادات التطبيق في النظام.',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64463),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'فتح الإعدادات',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Calculation Logic (from user provided code) ---

  void _calculateTimes() {
    final today = DateTime.now();
    final timesMap = _computeDayTimes(today.year, today.month, today.day);

    prayerTimes = [
      _createPrayerTime('Fajr', timesMap['fajr']!, today),
      // _createPrayerTime('Fajr', 8 * 60 + 50, today),
      _createPrayerTime('Sunrise', timesMap['sunrise']!, today),
      _createPrayerTime('Dhuhr', timesMap['dhuhr']!, today),
      // _createPrayerTime('Asr', 15 * 60 + 15, today),
      _createPrayerTime('Asr', timesMap['asr']!, today),
      _createPrayerTime('Maghrib', timesMap['maghrib']!, today),
      _createPrayerTime('Isha', timesMap['isha']!, today),
    ];

    // 3. Construct the Final Ordered List
    // Filter main prayers
    final mainPrayers = prayerTimes!
        .where(
            (p) => !['First Third', 'Midnight', 'Last Third'].contains(p.name))
        .toList();
    mainPrayers.sort((a, b) => a.time.compareTo(b.time));

    // Determine which "Night Cycle" to show
    // Logic: The "Night" technically ends at Fajr.
    // If we are BEFORE Fajr (e.g. 00:40 AM), we are still in the "Previous Night".
    // We should show markers for (Yesterday Maghrib -> Today Fajr).
    // If we are AFTER Fajr (e.g. 07:00 AM), we are starting a new day.
    // We should show markers for (Today Maghrib -> Tomorrow Fajr).

    final now = DateTime.now();

    // We need to know specific Fajr time for comparison
    // We can find it in mainPrayers or from existing calculation
    final fajrP = mainPrayers.firstWhere((p) => p.name == 'Fajr');
    final isBeforeFajr = now.isBefore(fajrP.time);

    final currentNightMarkers = <PrayerTime>[];

    if (isBeforeFajr) {
      // Show "Previous Night" markers (valid for early morning hours)
      // 1. Calculate Night Times for "Yesterday Maghrib -> Today Fajr"
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayTimes =
          _computeDayTimes(yesterday.year, yesterday.month, yesterday.day);
      final maghribYesterdayMinutes = yesterdayTimes['maghrib']!;
      final maghribYesterdayTime =
          _createPrayerTime('Maghrib', maghribYesterdayMinutes, yesterday).time;

      // fajrToday is fajrP.time
      _addNightTimes(maghribYesterdayTime, fajrP.time, currentNightMarkers);
    } else {
      // Show "Upcoming Night" markers
      // 2. Calculate Night Times for "Today Maghrib -> Tomorrow Fajr"
      final maghribTodayMinutes = timesMap['maghrib']!;
      final maghribTodayTime =
          _createPrayerTime('Maghrib', maghribTodayMinutes, today).time;

      final tomorrow = today.add(const Duration(days: 1));
      final tomorrowTimes =
          _computeDayTimes(tomorrow.year, tomorrow.month, tomorrow.day);
      final fajrTomorrowMinutes = tomorrowTimes['fajr']!;

      final fajrTomorrowTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          (fajrTomorrowMinutes / 60).floor(),
          fajrTomorrowMinutes % 60);

      _addNightTimes(maghribTodayTime, fajrTomorrowTime, currentNightMarkers);
    }

    // Combine: Main Prayers + Night Markers
    prayerTimes = [...mainPrayers, ...currentNightMarkers];

    isLoadingPrayerTimes = false;
    displayDate();
  }

  Map<String, DateTime> _calculateNightBoundaries(
      DateTime maghrib, DateTime fajr) {
    final nightDuration = fajr.difference(maghrib);
    final thirdDuration =
        Duration(seconds: (nightDuration.inSeconds / 3).round());
    final halfDuration =
        Duration(seconds: (nightDuration.inSeconds / 2).round());

    return {
      'First Third': maghrib.add(thirdDuration),
      'Midnight': maghrib.add(halfDuration),
      'Last Third': maghrib.add(thirdDuration * 2),
      // 'Last Third': DateTime(DateTime.now().year, DateTime.now().month,
      //    DateTime.now().day, 22, 25),
    };
  }

  void _addNightTimes(DateTime maghrib, DateTime fajr, List<PrayerTime> list) {
    final nightTimes = _calculateNightBoundaries(maghrib, fajr);

    list.add(_createPrayerTimeFromDateTime(
        'First Third', nightTimes['First Third']!));
    list.add(
        _createPrayerTimeFromDateTime('Midnight', nightTimes['Midnight']!));
    list.add(
        _createPrayerTimeFromDateTime('Last Third', nightTimes['Last Third']!));
  }

  PrayerTime _createPrayerTimeFromDateTime(String name, DateTime time) {
    final hours = time.hour;
    final mins = time.minute;
    final time24h =
        '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    return PrayerTime(name: name, time: time, time24h: time24h);
  }

  PrayerTime _createPrayerTime(String name, int totalSeconds, DateTime date) {
    final hours = (totalSeconds / 3600).floor() % 24;
    final mins = (totalSeconds / 60).floor() % 60;
    final secs = totalSeconds % 60;
    final time = DateTime(date.year, date.month, date.day, hours, mins, secs);
    final time24h =
        '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    return PrayerTime(name: name, time: time, time24h: time24h);
  }

  Map<String, int> _computeDayTimes(int y, int m, int d) {
    final jd = _toJulianDay(y, m, d);
    final sunCoords = _sunCoords(jd);
    final latRad = _deg2rad(lat);
    final noonUTC = _solarNoonUTCMinutes(lon, sunCoords['eoT']!);

    // Get local timezone offset in minutes
    final offset = DateTime(y, m, d).timeZoneOffset.inMinutes;

    final opts = _getOptions();
    final fajrAlt = _deg2rad(-opts['fajrAngle']!);
    final ishaAlt = _deg2rad(-opts['ishaAngle']!);
    final sunriseAlt = _deg2rad(-0.833);

    final hf = _hourAngleForAltitude(latRad, sunCoords['decl']!, fajrAlt);
    final hs = _hourAngleForAltitude(latRad, sunCoords['decl']!, sunriseAlt);
    final hi = _hourAngleForAltitude(latRad, sunCoords['decl']!, ishaAlt);
    final ha = _hourAngleForAltitude(latRad, sunCoords['decl']!,
        _asrAltitude(latRad, sunCoords['decl']!, opts['asrFactor']!));

    double toMin(double r) => _rad2deg(r) * 4;

    return {
      'fajr': ((noonUTC + offset - toMin(hf) + (dstEnabled ? 60 : 0)) * 60 +
              (prayerOffsets['Fajr'] ?? 0))
          .round(),
      'sunrise': ((noonUTC + offset - toMin(hs) + (dstEnabled ? 60 : 0)) * 60 +
              (prayerOffsets['Sunrise'] ?? 0))
          .round(),
      'dhuhr': ((noonUTC + offset + (dstEnabled ? 60 : 0)) * 60 +
              (prayerOffsets['Dhuhr'] ?? 0))
          .round(),
      'asr': ((noonUTC + offset + toMin(ha) + (dstEnabled ? 60 : 0)) * 60 +
              (prayerOffsets['Asr'] ?? 0))
          .round(),
      'maghrib': ((noonUTC + offset + toMin(hs) + (dstEnabled ? 60 : 0)) * 60 +
              (prayerOffsets['Maghrib'] ?? 0))
          .round(),
      'isha': ((noonUTC + offset + toMin(hi) + (dstEnabled ? 60 : 0)) * 60 +
              (prayerOffsets['Isha'] ?? 0))
          .round(),
    };
  }

  Map<String, double> _getOptions() {
    double fajr = 18.0;
    double isha = 17.0;

    switch (angles) {
      case 'mwl': // Muslim World League (Recommended for Algeria)
        fajr = 18.0;
        isha = 17.0;
        break;
      case 'egypt': // Egyptian General Authority of Survey
        fajr = 19.5;
        isha = 17.5;
        break;
      case 'makkah': // Umm Al-Qura University, Makkah
        fajr = 18.5;
        isha = 18.5; // Actually 90 min after Maghrib, handled elsewhere usually
        break;
      case 'isna': // Islamic Society of North America
        fajr = 15.0;
        isha = 15.0;
        break;
      case 'karachi': // University of Islamic Sciences, Karachi
        fajr = 18.0;
        isha = 18.0;
        break;
      case 'custom':
        fajr = customFajrAngle;
        isha = customIshaAngle;
        break;
      case 'ms':
      default:
        fajr = 18.0;
        isha = 17.0;
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
    final t = (jd - 2451545.0) / 36525;
    final l0 = (280.46646 + 36000.76983 * t + 0.0003032 * t * t) % 360;
    final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
    final e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
    final mRad = _deg2rad(m);
    final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(mRad) +
        (0.019993 - 0.000101 * t) * sin(2 * mRad) +
        0.000289 * sin(3 * mRad);
    final trueLong = l0 + c;
    final omega = 125.04 - 1934.136 * t;
    final lambda = trueLong - 0.00569 - 0.00478 * sin(_deg2rad(omega));
    final epsilon0 = 23.439291 -
        0.0130042 * t -
        0.0000001639 * t * t +
        0.0000005036 * t * t * t;
    final epsilon = epsilon0 + 0.00256 * cos(_deg2rad(omega));
    final lambdaRad = _deg2rad(lambda);
    final epsRad = _deg2rad(epsilon);
    final decl = asin(sin(epsRad) * sin(lambdaRad));

    final valY = tan(epsRad / 2);
    final y2 = valY * valY;
    final sin2L0 = sin(2 * _deg2rad(l0));
    final sinM = sin(mRad);
    final cos2L0 = cos(2 * _deg2rad(l0));
    final sin4L0 = sin(4 * _deg2rad(l0));
    final sin2M = sin(2 * mRad);
    final eoT = 4 *
        _rad2deg(y2 * sin2L0 -
            2 * e * sinM +
            4 * e * y2 * sinM * cos2L0 -
            0.5 * y2 * y2 * sin4L0 -
            1.25 * e * e * sin2M);

    return {'decl': decl, 'eoT': eoT};
  }

  double _solarNoonUTCMinutes(double lon, double eoT) {
    return 720 - 4 * lon - eoT;
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
        '$dayName، ${hijri['day']} ${hijri['monthName']} ${hijri['year']} هـ';

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
    persistentNotificationBlackBg =
        prefs.getBool('persistentNotificationBlackBg') ?? false;
    fajrChallengeEnabled = prefs.getBool('fajrChallengeEnabled') ?? false;
    fajrChallengeQuestionsCount =
        prefs.getInt('fajrChallengeQuestionsCount') ?? 3;
    fajrChallengeIsTextInput =
        prefs.getBool('fajrChallengeIsTextInput') ?? false;

    // Load Wake Up Settings
    fajrChallengeWakeUpMode =
        prefs.getString('fajrChallengeWakeUpMode') ?? 'auto';
    fajrChallengeCustomOffsetMinutes =
        prefs.getInt('fajrChallengeCustomOffsetMinutes') ?? 30;

    morningAdhkarEnabled = prefs.getBool('morningAdhkarEnabled') ?? true;
    eveningAdhkarEnabled = prefs.getBool('eveningAdhkarEnabled') ?? true;
    nightPrayerTimesEnabled = prefs.getBool('nightPrayerTimesEnabled') ?? false;

    notificationMode = prefs.getInt('notificationMode') ?? 0;

    // Load calculation settings
    dstEnabled = prefs.getBool('dstEnabled') ?? false;
    hijriOffset = prefs.getInt('hijriOffset') ?? -3;

    // Default to MWL if not set for better compatibility in North Africa
    angles = prefs.getString('angles') ?? 'mwl';
    final cachedLat = prefs.getDouble('lat');
    final cachedLon = prefs.getDouble('lon');
    if (cachedLat != null && cachedLon != null) {
      lat = cachedLat;
      lon = cachedLon;
      _hasCachedLocation = true;
      if (kDebugMode) {
        print("Loaded cached location from preferences: ($lat, $lon)");
      }
    } else {
      // Use default values (Cairo, Egypt)
      lat = 30.0444;
      lon = 31.2357;
      _hasCachedLocation = false;
      if (kDebugMode) {
        print("No cached location found, using defaults: ($lat, $lon)");
      }
    }

    asrMethod = prefs.getString('asrMethod') ?? 'shafi';
    // Removed old redundant load of 'angles' to keep it cleaner

    // Load offsets
    for (var name in prayerOffsets.keys) {
      prayerOffsets[name] = prefs.getInt('offset_$name') ??
          (name == 'Fajr'
              ? 60
              : name == 'Sunrise'
                  ? 60
                  : name == 'Dhuhr'
                      ? 120
                      : name == 'Asr'
                          ? 120
                          : name == 'Maghrib'
                              ? 300
                              : name == 'Isha'
                                  ? 120
                                  : 0);
    }

    for (var name in arabicPrayerNames) {
      // Default to true for actual prayers, false for non-prayer times (Sunrise/Night thirds)
      bool isActualPrayer = ![
        'الشروق',
        'الثلث الأول',
        'منتصف الليل',
        'الثلث الأخير'
      ].contains(name);
      prayerNotificationsEnabled[name] =
          prefs.getBool('notification_$name') ?? isActualPrayer;
    }
    // Load night prayer preferences (defaulting to false if not set, or true?)
    // Let's default to false to avoid unexpected alarms unless enabled
    // final nightNames = ['الثلث الأول', 'منتصف الليل', 'الثلث الأخير', 'الشروق'];
    // for (var name in nightNames) {
    //   prayerNotificationsEnabled[name] =
    //       prefs.getBool('notification_$name') ?? false;
    // }

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

    // Save offsets
    for (var entry in prayerOffsets.entries) {
      await prefs.setInt('offset_${entry.key}', entry.value);
    }

    _calculateTimes();
  }

  Future<void> saveNotificationPreference(
      bool globalValue, Map<String, bool> prayerValues, bool soundValue,
      {bool? persistentValue,
      bool? persistentBgValue,
      bool? fajrChallengeValue,
      int? challengeQuestionsCount,
      bool? challengeIsTextInput,
      String? challengeWakeUpMode, // New param
      int? challengeCustomOffset, // New param
      bool? morningAdhkarValue,
      bool? eveningAdhkarValue,
      bool? nightPrayerTimesValue,
      int? notificationModeValue}) async {
    final prefs = await SharedPreferences.getInstance();

    if (notificationModeValue != null) {
      await prefs.setInt('notificationMode', notificationModeValue);
      notificationMode = notificationModeValue;
    }

    await prefs.setBool('notificationsEnabled', globalValue);
    notificationsEnabled = globalValue;
    await prefs.setBool('notificationSoundEnabled', soundValue);
    notificationSoundEnabled = soundValue;

    if (persistentValue != null) {
      await prefs.setBool('persistentNotificationEnabled', persistentValue);
      persistentNotificationEnabled = persistentValue;
    }
    if (persistentBgValue != null) {
      await prefs.setBool('persistentNotificationBlackBg', persistentBgValue);
      persistentNotificationBlackBg = persistentBgValue;
    }
    if (fajrChallengeValue != null) {
      await prefs.setBool('fajrChallengeEnabled', fajrChallengeValue);
      fajrChallengeEnabled = fajrChallengeValue;
    }
    if (challengeQuestionsCount != null) {
      await prefs.setInt(
          'fajrChallengeQuestionsCount', challengeQuestionsCount);
      fajrChallengeQuestionsCount = challengeQuestionsCount;
    }
    if (challengeIsTextInput != null) {
      await prefs.setBool('fajrChallengeIsTextInput', challengeIsTextInput);
      fajrChallengeIsTextInput = challengeIsTextInput;
    }
    if (challengeWakeUpMode != null) {
      await prefs.setString('fajrChallengeWakeUpMode', challengeWakeUpMode);
      fajrChallengeWakeUpMode = challengeWakeUpMode;
    }
    if (challengeCustomOffset != null) {
      await prefs.setInt(
          'fajrChallengeCustomOffsetMinutes', challengeCustomOffset);
      fajrChallengeCustomOffsetMinutes = challengeCustomOffset;
    }
    if (morningAdhkarValue != null) {
      await prefs.setBool('morningAdhkarEnabled', morningAdhkarValue);
      morningAdhkarEnabled = morningAdhkarValue;
    }
    if (eveningAdhkarValue != null) {
      await prefs.setBool('eveningAdhkarEnabled', eveningAdhkarValue);
      eveningAdhkarEnabled = eveningAdhkarValue;
    }
    if (nightPrayerTimesValue != null) {
      await prefs.setBool('nightPrayerTimesEnabled', nightPrayerTimesValue);
      nightPrayerTimesEnabled = nightPrayerTimesValue;
      // Recalculate to show/hide times
      _calculateTimes();
    }
    for (var entry in prayerValues.entries) {
      await prefs.setBool('notification_${entry.key}', entry.value);
    }

    prayerNotificationsEnabled = prayerValues;

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
      // Check for day change to refresh prayer times
      final now = DateTime.now();
      if (prayerTimes != null && prayerTimes!.isNotEmpty) {
        final firstPrayerDate = prayerTimes!.first.time;
        if (firstPrayerDate.day != now.day ||
            firstPrayerDate.month != now.month ||
            firstPrayerDate.year != now.year) {
          if (kDebugMode) {
            print("Day changed, recalculating prayer times");
          }
          _calculateTimes();
          // Fix: Reschedule all background notifications for the new day
          schedulePrayerTimeNotifications();
          // We also need to clear fired indexes for the new day
          _firedPrayerIndexes.clear();
          _firedDate = now;
        }
      }

      if (persistentNotificationEnabled) {
        // No longer update every second from Flutter.
        // The native side (PrayerTimeService.kt) handles its own countdown timer.
        // We only update if the day changed or target changed (handled below).
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

    if (prayerTimes == null || prayerTimes!.isEmpty) {
      return;
    }

    // CRITICAL FIX: Check location permission before starting service.
    // Starting a foreground service of type 'location' without permission crashes Android 14+.
    LocationPermission permission = await Geolocator.checkPermission();
    bool isGranted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    if (!isGranted) {
      if (kDebugMode) {
        print(
            "UpdatePersistentNotification: Location permission not granted ($permission). Skipping service start.");
      }
      // We cannot start the service yet.
      return;
    }

    final now = DateTime.now();
    final today = now;

    // Create a sequence of prayers: Today + Tomorrow
    // This simplifies finding the "Next" and "Next+1" prayer across day boundaries
    List<PrayerTime> sequence = [];
    sequence.addAll(prayerTimes!);

    // Add tomorrow's prayers (properly calculated) to handle late night / day switch cases
    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowTimesMap =
        _computeDayTimes(tomorrow.year, tomorrow.month, tomorrow.day);
    final tomorrowPrayers = [
      _createPrayerTime('Fajr', tomorrowTimesMap['fajr']!, tomorrow),
      _createPrayerTime('Sunrise', tomorrowTimesMap['sunrise']!, tomorrow),
      _createPrayerTime('Dhuhr', tomorrowTimesMap['dhuhr']!, tomorrow),
      _createPrayerTime('Asr', tomorrowTimesMap['asr']!, tomorrow),
      _createPrayerTime('Maghrib', tomorrowTimesMap['maghrib']!, tomorrow),
      _createPrayerTime('Isha', tomorrowTimesMap['isha']!, tomorrow),
    ];
    sequence.addAll(tomorrowPrayers);

    // Sort by time
    sequence.sort((a, b) => a.time.compareTo(b.time));

    // Find the immediate next prayer
    int nextIndex = sequence.indexWhere((p) => p.time.isAfter(now));

    if (nextIndex == -1) {
      // Should not happen as we added tomorrow's prayers
      return;
    }

    PrayerTime targetPrayer = sequence[nextIndex];
    PrayerTime? fallbackPrayer;

    // Find the subsequent prayer (fallback for native service)
    if (nextIndex + 1 < sequence.length) {
      fallbackPrayer = sequence[nextIndex + 1];
    }

    final arabicNameMap = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
      'First Third': 'الثلث الأول',
      'Midnight': 'منتصف الليل',
      'Last Third': 'الثلث الأخير',
    };

    String targetName = arabicNameMap[targetPrayer.name] ?? targetPrayer.name;
    String info = '$targetName ,${targetPrayer.time24h}';

    String? fallbackInfo;
    int? fallbackTimestamp;

    if (fallbackPrayer != null) {
      String fbName = arabicNameMap[fallbackPrayer.name] ?? fallbackPrayer.name;
      fallbackInfo = '$fbName في ${fallbackPrayer.time24h}';
      fallbackTimestamp = fallbackPrayer.time.millisecondsSinceEpoch;
    }

    int? challengeTimestamp;
    if (fajrChallengeEnabled) {
      try {
        final fajrPrayer = prayerTimes!.firstWhere((p) => p.name == 'Fajr');
        DateTime? cTime = _getFajrChallengeTime(fajrPrayer);

        // If today's challenge passed, check tomorrow's
        if (cTime != null && cTime.isBefore(now)) {
          // Re-computing tomorrow's times properly would require calling _computeDayTimes for tomorrow
          // But since _getFajrChallengeTime relies on "Yesterday Maghrib" relative to "Fajr",
          // We can simulate tomorrow's Fajr

          // Simplified approach: Add 24h to today's challenge time as approximation
          // Or better: Use the tomorrow's Fajr time we calculated for 'sequence' list?
          // The 'sequence' list has tomorrow's prayers.

          // Let's find tomorrow's Fajr from sequence (it should be there)
          final tomorrowFajr = sequence.firstWhere(
              (p) => p.name == 'Fajr' && p.time.day != now.day,
              orElse: () => fajrPrayer.copyWith(
                  time: fajrPrayer.time.add(const Duration(days: 1))));

          cTime = _getFajrChallengeTime(tomorrowFajr);
        }

        if (cTime != null) {
          challengeTimestamp = cTime.millisecondsSinceEpoch;
        }
      } catch (e) {
        if (kDebugMode) print('Error calc challenge timestamp: $e');
      }
    }

    // Optimization: Skip update if same target was already sent
    if (_lastSentTargetTimestamp == targetPrayer.time.millisecondsSinceEpoch) {
      if (kDebugMode) print("Skipping redundant notification update");
      return;
    }

    _lastSentTargetTimestamp = targetPrayer.time.millisecondsSinceEpoch;

    // Call native helper with both current and fallback targets
    await PrayerNotificationHelper.startPrayerCountdown(
      hijriDate: hijriDate,
      prayerInfo: info,
      nextPrayerName: targetName,
      targetTimestamp: targetPrayer.time.millisecondsSinceEpoch,
      nextTargetTimestamp: fallbackTimestamp,
      nextPrayerInfo: fallbackInfo,
      challengeTimestamp: challengeTimestamp,
      isBlackBackground: persistentNotificationBlackBg,
      notificationMode: notificationMode,
    );
  }

  DateTime? _getFajrChallengeTime(PrayerTime fajrPrayer) {
    if (!fajrChallengeEnabled) return null;

    if (fajrChallengeWakeUpMode == 'custom') {
      return fajrPrayer.time
          .subtract(Duration(minutes: fajrChallengeCustomOffsetMinutes));
    } else if (fajrChallengeWakeUpMode == 'auto') {
      // Calculate start of Last Third of Night
      // Night = Maghrib (Yesterday) -> Fajr (Today)

      // 1. Get Yesterday's Maghrib
      // We assume fajrPrayer.time is the correct Fajr time we want to aim for.
      DateTime fajrTime = fajrPrayer.time;
      DateTime yesterday = fajrTime.subtract(const Duration(days: 1));

      // Compute times for yesterday to get accurate Maghrib
      final yesterdayTimes =
          _computeDayTimes(yesterday.year, yesterday.month, yesterday.day);
      final maghribSeconds = yesterdayTimes['maghrib']!;

      DateTime maghribTime =
          _createPrayerTime('Maghrib', maghribSeconds, yesterday).time;

      // Calculate duration
      final nightTimes = _calculateNightBoundaries(maghribTime, fajrTime);
      return nightTimes['Last Third'];
    }
    return null;
  }

  Map<String, dynamic> getNextPrayerInfo() {
    if (prayerTimes == null || prayerTimes!.isEmpty) {
      return {'name': '', 'timeRemaining': ''};
    }

    final now = DateTime.now();
    final arabicNames = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
      'First Third': 'الثلث الأول',
      'Midnight': 'منتصف الليل',
      'Last Third': 'الثلث الأخير',
    };

    PrayerTime? nextPrayer;
    DateTime? nextTime;

    for (var prayer in prayerTimes!) {
      // Skip Sunrise if you don't want it to be a "Next Prayer" target
      // if (prayer.name == 'Sunrise') continue;

      final prayerDateTime = prayer.time;

      // Check if this prayer is in the future
      if (prayerDateTime.isAfter(now)) {
        // If we haven't found a next prayer yet, OR this one is sooner than the one we found
        if (nextTime == null || prayerDateTime.isBefore(nextTime)) {
          nextTime = prayerDateTime;
          nextPrayer = prayer;
        }
      }
    }

    if (nextPrayer == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes =
          _computeDayTimes(tomorrow.year, tomorrow.month, tomorrow.day);
      final fajrSeconds = tomorrowTimes['fajr']!;
      nextPrayer = _createPrayerTime('Fajr', fajrSeconds, tomorrow);
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
      // Map English name to Arabic for notification
      final arabicNameMap = {
        'Fajr': 'الفجر',
        'Sunrise': 'الشروق',
        'Dhuhr': 'الظهر',
        'Asr': 'العصر',
        'Maghrib': 'المغرب',
        'Isha': 'العشاء',
        'First Third': 'الثلث الأول',
        'Midnight': 'منتصف الليل',
        'Last Third': 'الثلث الأخير',
      };

      final prayerName = arabicNameMap[prayer.name] ?? prayer.name;

      // Skip non-prayer times (Mute)
      if (['الشروق', 'الثلث الأول', 'منتصف الليل', 'الثلث الأخير']
          .contains(prayerName)) {
        continue;
      }

      // Only schedule if explicitly enabled in settings
      // CRITICAL FIX: To avoid double notifications, we only schedule standard local notifications
      // if the persistent foreground service is DISABLED. If the service is enabled,
      // the native side (PrayerTimeService.kt) handles the alerts more accurately.
      if (prayerNotificationsEnabled[prayerName] == true &&
          !persistentNotificationEnabled) {
        DateTime scheduledDate = prayer.time;
        if (scheduledDate.isBefore(DateTime.now())) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        NotificationService().showNotification(
          i,
          'وقت الصلاة',
          'حان الآن وقت صلاة $prayerName',
          scheduledDate,
          notificationSoundEnabled,
          payload: prayerName,
        );
      }
    }

    // Schedule Adhkar Notifications
    if (morningAdhkarEnabled) {
      final fajr = prayerTimes!.firstWhere((p) => p.name == 'Fajr');
      DateTime adhkarTime = fajr.time.add(const Duration(hours: 1));
      if (adhkarTime.isBefore(DateTime.now())) {
        adhkarTime = adhkarTime.add(const Duration(days: 1));
      }
      NotificationService().showNotification(
        100, // Unique ID for Morning Adhkar
        'أذكار الصباح',
        'حان الآن وقت أذكار الصباح',
        adhkarTime,
        notificationSoundEnabled,
        payload: 'Morning_Adhkar',
        isAlarm: false, // Don't show prayer screen or play adhan
      );
    }

    if (eveningAdhkarEnabled) {
      final asr = prayerTimes!.firstWhere((p) => p.name == 'Asr');
      DateTime adhkarTime = asr.time.add(const Duration(hours: 1));
      if (adhkarTime.isBefore(DateTime.now())) {
        adhkarTime = adhkarTime.add(const Duration(days: 1));
      }
      NotificationService().showNotification(
        101, // Unique ID for Evening Adhkar
        'أذكار المساء',
        'حان الآن وقت أذكار المساء',
        adhkarTime,
        notificationSoundEnabled,
        payload: 'Evening_Adhkar',
        isAlarm: false, // Don't show prayer screen or play adhan
      );
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
        // Fix: Use map instead of index for name
        final arabicNameMap = {
          'Fajr': 'الفجر',
          'Sunrise': 'الشروق',
          'Dhuhr': 'الظهر',
          'Asr': 'العصر',
          'Maghrib': 'المغرب',
          'Isha': 'العشاء',
          'First Third': 'الثلث الأول',
          'Midnight': 'منتصف الليل',
          'Last Third': 'الثلث الأخير',
        };

        final prayerName = arabicNameMap[prayer.name] ?? prayer.name;

        // Skip non-prayer times (Mute)
        if (['الشروق', 'الثلث الأول', 'منتصف الليل', 'الثلث الأخير']
            .contains(prayerName)) {
          _firedPrayerIndexes.add(i);
          continue;
        }

        if (prayerNotificationsEnabled[prayerName] == true) {
          // Check if app is in foreground
          final isForeground = WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed;

          if (isForeground) {
            // Standard Prayer Notification Logic (Foreground only)
            if (notificationSoundEnabled) playAudio();
            // For standard prayer time, show the Ayat/Hadith dialog
            Get.dialog(AyatHadithDialog(prayerName: prayerName));
          } else {
            // Background behavior:
            // 1. If persistent service is enabled, it handles the alarm and notification.
            // 2. If disabled, the scheduled notification (from flutter_local_notifications) fires.
            // In either case, we don't need to do anything here to avoid double triggers.
          }
          _firedPrayerIndexes.add(i);
        }
      }

      // --- Fajr Challenge Check ---
      if (prayer.name == 'Fajr' && fajrChallengeEnabled) {
        // Use a unique index for the challenge event (e.g. 9999)
        int challengeIndex = 9999;

        if (!_firedPrayerIndexes.contains(challengeIndex)) {
          DateTime? challengeTime = _getFajrChallengeTime(prayer);
          if (challengeTime != null) {
            final challengeDiff = now.difference(challengeTime);
            // Allow 60s window
            if (!challengeTime.isAfter(now) &&
                challengeDiff.inSeconds.abs() <= 60) {
              // Trigger Fajr Challenge Logic
              if (notificationSoundEnabled) playAudio();

              // 1. Force App to Foreground
              try {
                const platform = MethodChannel(
                    'com.example.hisn_el_muslim/prayer_notification');
                platform.invokeMethod('bringAppToForeground');
              } catch (e) {
                if (kDebugMode) print("Error bringing - $e");
              }

              // 2. Navigate
              Get.to(() => const FajrChallengeScreen());

              // 3. Notification (Backup) - Removed to avoid duplicate with Native Service
              // NotificationService().showImmediateNotification(
              //   challengeIndex,
              //   'تحدي الفجر',
              //   'حان وقت الاستيقاظ لتحدي الفجر!',
              //   true,
              //   payload: 'Fajr_Challenge',
              // );

              _firedPrayerIndexes.add(challengeIndex);
            }
          }
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

  void stopAudio() async {
    try {
      await audioPlayer.stop();
      hasPlayedAudio =
          false; // Reset so it can play again for next prayer if needed (though logic usually re-instances or relies on _firedPrayerIndexes)
    } catch (e) {
      if (kDebugMode) print('stopAudio error: $e');
    }
  }

  // Removed foreground task methods

  void _handleTriggeredAlarm(String prayerName) {
    if (kDebugMode) print("Triggered Alarm: $prayerName");

    if (prayerName == 'Fajr_Challenge' || prayerName == 'تحدي الفجر') {
      if (_firedPrayerIndexes.contains(9999)) return;
      _firedPrayerIndexes.add(9999);

      if (notificationSoundEnabled) playAudio();

      // 1. Force app to foreground (redundant if MainActivity already launched, but safe)
      try {
        const platform =
            MethodChannel('com.example.hisn_el_muslim/prayer_notification');
        platform.invokeMethod('bringAppToForeground');
      } catch (e) {
        if (kDebugMode) print("Error bringing - $e");
      }

      Get.to(() => const FajrChallengeScreen());
      return;
    }

    // Standard prayer trigger from native side
    final arabicNames = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
      'First Third': 'الثلث الأول',
      'Midnight': 'منتصف الليل',
      'Last Third': 'الثلث الأخير',
    };

    // Find the prayer index to check if already fired by Dart timer
    int idx = prayerTimes?.indexWhere(
            (p) => (arabicNames[p.name] ?? p.name) == prayerName) ??
        -1;
    if (idx != -1 && _firedPrayerIndexes.contains(idx)) {
      if (kDebugMode) {
        print("Alarm for $prayerName already handle by Dart timer.");
      }
      return;
    }
    if (idx != -1) _firedPrayerIndexes.add(idx);

    if (notificationSoundEnabled) playAudio();
    Get.dialog(AyatHadithDialog(prayerName: prayerName));
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
  String? pendingPayload;

  void handleAdhkarNotification(String payload) async {
    final String category =
        payload == 'Morning_Adhkar' ? 'أذكار الصباح' : 'أذكار المساء';

    if (Get.context != null) {
      // Load azkar data to find the matching category
      final String jsonData =
          await rootBundle.loadString('assets/hisnmuslim.json');
      final List<dynamic> jsonList = json.decode(jsonData);
      final azkarList =
          jsonList.map((json) => AzkarInfo.fromJson(json)).toList();

      try {
        final targetAzkar =
            azkarList.firstWhere((element) => element.category == category);
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
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) print('Notification tapped: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          if (response.payload == 'Fajr_Challenge') {
            if (Get.context != null) {
              Get.to(() => const FajrChallengeScreen());
            } else {
              pendingPayload = response.payload;
            }
          } else if (response.payload == 'Morning_Adhkar' ||
              response.payload == 'Evening_Adhkar') {
            handleAdhkarNotification(response.payload!);
          } else {
            if (Get.context != null) {
              Get.dialog(AyatHadithDialog(prayerName: response.payload!));
            } else {
              pendingPayload = response.payload;
            }
          }
        }
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
      DateTime scheduledDate, bool soundEnabled,
      {String? payload, bool isAlarm = true}) async {
    final androidDetails = AndroidNotificationDetails(
      isAlarm ? 'prayer_times_channel' : 'adhkar_channel',
      isAlarm ? 'مواقيت الصلاة' : 'تنبيهات الأذكار',
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
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> showImmediateNotification(
      int id, String title, String body, bool soundEnabled,
      {String? payload}) async {
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
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
