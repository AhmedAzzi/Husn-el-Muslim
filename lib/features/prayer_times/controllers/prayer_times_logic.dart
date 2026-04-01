import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:small_husn_muslim/core/services/cache_manager.dart';
import 'package:small_husn_muslim/core/services/notification_service.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_calculation_engine.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';

class DayPrayerSummary {
  final List<PrayerTime> prayerTimes;
  final String hijriDate;
  final String gregorianDate;

  DayPrayerSummary({
    required this.prayerTimes,
    required this.hijriDate,
    required this.gregorianDate,
  });
}

// Helper to run computeDayTimes in compute()
Future<Map<String, int>> _calculateTimesAsync(
    Map<String, dynamic> params) async {
  return await compute(PrayerCalculationEngine.computeDayTimes, params);
}

class PrayerTimesLogic extends GetxController {
  // Singleton pattern for backward compatibility
  static final PrayerTimesLogic _instance = PrayerTimesLogic._internal();
  factory PrayerTimesLogic() => _instance;

  late final CacheManager _cacheManager;
  late AudioPlayer audioPlayer;

  PrayerTimesLogic._internal() {
    audioPlayer = AudioPlayer();
    _cacheManager = CacheManager();
  }

  // Rx State variables
  final prayerTimesRx = Rxn<List<PrayerTime>>();
  List<PrayerTime>? get prayerTimes => prayerTimesRx.value;
  set prayerTimes(List<PrayerTime>? value) => prayerTimesRx.value = value;

  final isLoadingPrayerTimesRx = true.obs;
  bool get isLoadingPrayerTimes => isLoadingPrayerTimesRx.value;
  set isLoadingPrayerTimes(bool value) => isLoadingPrayerTimesRx.value = value;

  final isLoadingLocationRx = true.obs;
  bool get isLoadingLocation => isLoadingLocationRx.value;
  set isLoadingLocation(bool value) => isLoadingLocationRx.value = value;

  final currentPositionRx = Rxn<Position>();
  Position? get currentPosition => currentPositionRx.value;
  set currentPosition(Position? value) => currentPositionRx.value = value;

  bool hasPlayedAudio = false;

  // Notification settings
  bool notificationsEnabled = true;
  final prayerNotificationsEnabled = <String, bool>{}.obs;
  final prayerAyatHadithEnabled = <String, bool>{}.obs;
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

  // Hidden internal base offsets (in seconds)
  final Map<String, int> _internalBaseOffsets = {
    'Fajr': 3 * 60,
    'Sunrise': 2 * 60,
    'Dhuhr': 0,
    'Asr': 3 * 60,
    'Maghrib': 6 * 60,
    'Isha': 3 * 60,
  };

  // User-facing prayer time offsets (visible in settings)
  Map<String, int> prayerOffsets = {
    'Fajr': 0,
    'Sunrise': 0,
    'Dhuhr': 0,
    'Asr': 0,
    'Maghrib': 0,
    'Isha': 0,
  };

  // Helper to get combined offsets for internal calculations
  Map<String, int> _getEffectiveOffsets() {
    final Map<String, int> effective = Map.from(prayerOffsets);
    _internalBaseOffsets.forEach((key, value) {
      if (effective.containsKey(key)) {
        effective[key] = effective[key]! + value;
      } else {
        effective[key] = value;
      }
    });
    return effective;
  }

  // Fajr Challenge Wake Up Settings
  // 'auto': Wake up at Last Third
  // 'custom': Wake up X minutes before Fajr
  String fajrChallengeWakeUpMode = 'auto';
  int fajrChallengeCustomOffsetMinutes = 30; // Default 30 mins before Fajr

  // Display strings (Reactive)
  final gregorianDateRx = ''.obs;
  String get gregorianDate => gregorianDateRx.value;
  set gregorianDate(String value) => gregorianDateRx.value = value;

  final hijriDateRx = ''.obs;
  String get hijriDate => hijriDateRx.value;
  set hijriDate(String value) => hijriDateRx.value = value;

  final currentTimeRx = ''.obs;
  String get currentTime => currentTimeRx.value;
  set currentTime(String value) => currentTimeRx.value = value;

  final nextPrayerNameRx = ''.obs;
  String get nextPrayerName => nextPrayerNameRx.value;

  final timeRemainingRx = ''.obs;
  String get timeRemaining => timeRemainingRx.value;

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final info = getNextPrayerInfo();
    nextPrayerNameRx.value = info['name'] ?? '';
    timeRemainingRx.value = info['timeRemaining'] ?? '';
    currentTime = _formatCurrentTime();
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  // Calculation settings
  double lat = 30.0444;
  double lon = 31.2357;
  String asrMethod = 'shafi';
  String angles = 'ms';
  double customFajrAngle = 19.5;
  double customIshaAngle = 17.5;
  bool dstEnabled = false;
  int hijriOffset = 0; // Default 0 offset

  DateTime? _tomorrowFajrTime;

  Timer? _notificationTimer;
  final Set<int> _firedPrayerIndexes = <int>{};
  DateTime _firedDate = DateTime.now();
  // _lastNotificationContent removed as unused
  dynamic _lastSentTargetTimestamp;

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
    await _cacheManager.init();
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

    // 4. Check onboarding status for UI silence
    final prefs = SharedPrefsCache.instance;
    final isOnboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    // Check availability and fetch fresh location
    // Always request location on first load or when forced
    if (force || currentPosition == null || !_hasCachedLocation) {
      if (force) {
        await _getCurrentLocation(background: false);
        _calculateTimes();
      } else {
        // If onboarding is not complete, we MUST be silent (background: true)
        // This prevents the "Location services disabled" popup on the very first launch
        final shouldBeSilent = !isOnboardingComplete;

        // Request location with user interaction ONLY if onboarding is complete and no cached location
        if (!_hasCachedLocation) {
          await _getCurrentLocation(background: shouldBeSilent);
          _calculateTimes();
          if (persistentNotificationEnabled) {
            updatePersistentNotification();
          }
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

    // Attempt to use high-level cache first (30-minute TTL)
    final cachedLocation = _cacheManager.getCachedLocation();
    if (cachedLocation != null) {
      lat = cachedLocation.latitude;
      lon = cachedLocation.longitude;
      _hasCachedLocation = true;
      if (kDebugMode) print("Using 30-min cached location: ($lat, $lon)");
      if (!background) isLoadingLocation = false;
      return;
    }

    // Fallback to SharedPreferences (persistence)
    final prefs = SharedPrefsCache.instance;
    final persistentLat = prefs.getDouble('lat');
    final persistentLon = prefs.getDouble('lon');

    if (persistentLat != null && persistentLon != null) {
      _hasCachedLocation = true;
      if (currentPosition == null) {
        lat = persistentLat;
        lon = persistentLon;
        if (kDebugMode) print("Using persistent location: ($lat, $lon)");
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
        if (background) {
          if (kDebugMode) print("Location permission denied in background.");
          isLoadingLocation = false;
          return;
        }

        // Only request if user specifically asked for refresh (e.g. force == true)
        // or during the 'force' path in ensureDataLoaded.
        // Actually, let's look at the flow.
        // If we're here and it's denied, we should stop unless it's a direct user action.
        
        // For the fix, we won't auto-request here.
        // The Onboarding screen or Settings will handle the request.
        if (kDebugMode) print("Location permission denied, skipping auto-request.");
        isLoadingLocation = false;
        return;
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
        // We no longer auto-request background upgrade here.
        // It's handled by Onboarding or explicit user Settings navigation.
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

  /// Re-check and potentially request background location permission.
  /// Used for "Allow all the time" (Android 10+) to ensure persistent notification reliability.
  Future<bool> requestBackgroundLocation() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.whileInUse) {
      if (kDebugMode) print("Upgrading to background location permission...");
      try {
        const platform = MethodChannel('com.example.hisn_el_muslim/location');
        final bool granted =
            await platform.invokeMethod('requestBackgroundLocationPermission');
        return granted;
      } catch (e) {
        if (kDebugMode) print("Error upgrading background permission: $e");
        return false;
      }
    }
    return status == LocationPermission.always;
  }

  // --- Calculation Logic (from user provided code) ---

  Future<void> _calculateTimes({DateTime? targetDate, bool force = false}) async {
    final date = targetDate ?? DateTime.now();
    final dateKey = "${date.year}-${date.month}-${date.day}";

    // Check cache first (skip if forced)
    if (!force) {
      final cachedWeek = _cacheManager.getCachedWeekPrayerTimes();
      if (cachedWeek != null && cachedWeek.containsKey(dateKey)) {
        final List<dynamic> jsonList = jsonDecode(cachedWeek[dateKey] as String);
        final List<PrayerTime> cachedTimes = jsonList
            .map((j) => PrayerTime.fromJson(j as Map<String, dynamic>))
            .toList();

        // If this is today, update the reactive state
        if (targetDate == null) {
          prayerTimes = cachedTimes;
          isLoadingPrayerTimes = false;
          displayDate();

          if (persistentNotificationEnabled) {
            updatePersistentNotification();
          }
        }
        return;
      }
    }

    final params = {
      'lat': lat,
      'lon': lon,
      'dstEnabled': dstEnabled,
      'prayerOffsets': _getEffectiveOffsets(),
      'asrMethod': asrMethod,
      'angles': angles,
      'customFajrAngle': customFajrAngle,
      'customIshaAngle': customIshaAngle,
    };

    final yesterday = date.subtract(const Duration(days: 1));
    final tomorrow = date.add(const Duration(days: 1));

    final multiParams = {
      ...params,
      'days': [
        {
          'key': 'today',
          'year': date.year,
          'month': date.month,
          'day': date.day,
        },
        {
          'key': 'yesterday',
          'year': yesterday.year,
          'month': yesterday.month,
          'day': yesterday.day,
        },
        {
          'key': 'tomorrow',
          'year': tomorrow.year,
          'month': tomorrow.month,
          'day': tomorrow.day,
        }
      ],
    };

    // Move heavy calculations to an isolate, batching 3 days at once
    final results =
        await compute(PrayerCalculationEngine.computeMultipleDays, multiParams);

    final timesMap = results['today']!;
    final yesterdayTimes = results['yesterday']!;
    final tomorrowTimes = results['tomorrow']!;

    final List<PrayerTime> mainPrayersList = [
      _createPrayerTime('Fajr', timesMap['fajr'] as int, date),
      _createPrayerTime('Sunrise', timesMap['sunrise'] as int, date),
      _createPrayerTime('Dhuhr', timesMap['dhuhr'] as int, date),
      _createPrayerTime('Asr', timesMap['asr'] as int, date),
      _createPrayerTime('Maghrib', timesMap['maghrib'] as int, date),
      _createPrayerTime('Isha', timesMap['isha'] as int, date),
    ];

    mainPrayersList.sort((a, b) => a.time.compareTo(b.time));

    final fajrP = mainPrayersList.firstWhere((p) => p.name == 'Fajr');
    final isBeforeFajr = DateTime.now().isBefore(fajrP.time);

    final currentNightMarkers = <PrayerTime>[];

    if (isBeforeFajr) {
      final maghribYesterdayTime = _createPrayerTime(
              'Maghrib', yesterdayTimes['maghrib'] as int, yesterday)
          .time;

      _addNightTimes(maghribYesterdayTime, fajrP.time, currentNightMarkers);
    } else {
      final maghribTodayTime =
          _createPrayerTime('Maghrib', timesMap['maghrib'] as int, date).time;

      final int fajrMin = tomorrowTimes['fajr']!;
      final fajrTomorrowTime =
          _createPrayerTime('Fajr', fajrMin, tomorrow).time;

      _addNightTimes(maghribTodayTime, fajrTomorrowTime, currentNightMarkers);
    }

    _tomorrowFajrTime =
        _createPrayerTime('Fajr', tomorrowTimes['fajr'] as int, tomorrow).time;

    final calculatedTimes = [...mainPrayersList, ...currentNightMarkers];

    // Cache the result
    final currentCache = _cacheManager.getCachedWeekPrayerTimes() ?? {};
    currentCache[dateKey] =
        jsonEncode(calculatedTimes.map((p) => p.toJson()).toList());
    await _cacheManager.cacheWeekPrayerTimes(currentCache);

    if (targetDate == null) {
      prayerTimes = calculatedTimes;
      isLoadingPrayerTimes = false;
      displayDate();

      if (persistentNotificationEnabled) {
        updatePersistentNotification();
      }
    }
  }

  Future<DayPrayerSummary> getPrayerSummaryForDate(DateTime targetDate) async {
    final dateKey = "${targetDate.year}-${targetDate.month}-${targetDate.day}";
    final cachedWeek = _cacheManager.getCachedWeekPrayerTimes();

    List<PrayerTime> times;
    if (cachedWeek != null && cachedWeek.containsKey(dateKey)) {
      final List<dynamic> jsonList = jsonDecode(cachedWeek[dateKey] as String);
      times = jsonList
          .map((j) => PrayerTime.fromJson(j as Map<String, dynamic>))
          .toList();
    } else {
      await _calculateTimes(targetDate: targetDate);
      final newCachedWeek = _cacheManager.getCachedWeekPrayerTimes();
      if (newCachedWeek != null && newCachedWeek.containsKey(dateKey)) {
        final List<dynamic> jsonList =
            jsonDecode(newCachedWeek[dateKey] as String);
        times = jsonList
            .map((j) => PrayerTime.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        times = [];
      }
    }

    final gregorian =
        '${targetDate.day} ${getArabicMonth(targetDate.month)} ${targetDate.year}';

    final hijriNow = targetDate.add(Duration(days: hijriOffset));
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar.fromDate(hijriNow);
    final dayName = getArabicDayName(targetDate.weekday);
    final hijriStr =
        '$dayName، ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';

    return DayPrayerSummary(
      prayerTimes: times,
      hijriDate: hijriStr,
      gregorianDate: gregorian,
    );
  }

  Future<void> preCalculateWeek() async {
    final start = DateTime.now();
    for (int i = 0; i < 7; i++) {
      await _calculateTimes(targetDate: start.add(Duration(days: i)));
    }
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
    final hijriNow = now.add(Duration(days: hijriOffset));
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar.fromDate(hijriNow);
    final dayName = getArabicDayName(now.weekday);
    hijriDate =
        '$dayName، ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';

    // Time: HH:mm:ss
    currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  // --- Preferences & Notifications ---

  Future<void> loadNotificationPreference() async {
    final prefs = SharedPrefsCache.instance;
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
    hijriOffset = prefs.getInt('hijriOffset') ?? 0;

    // Check for region-specific defaults if angles not set
    if (!prefs.containsKey('angles')) {
      // Default to MWL normally
      angles = 'mwl';

      // If in Egypt (approximate bounds), use the Egypt calculation method
      if (lat >= 22.0 && lat <= 32.0 && lon >= 25.0 && lon <= 36.0) {
        angles = 'egypt';
        if (kDebugMode) {
          print("Auto-detected region: Egypt. Using 'egypt' method.");
        }
      }
    } else {
      angles = prefs.getString('angles') ?? 'mwl';
    }

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
      // Use default values (Mostaganem, Algeria)
      lat = 35.9311;
      lon = 0.0892;
      _hasCachedLocation = false;
      // Also default to MWL for Mostaganem
      if (!prefs.containsKey('angles')) angles = 'mwl';

      if (kDebugMode) {
        print("No cached location found, using defaults: ($lat, $lon)");
      }
    }

    asrMethod = prefs.getString('asrMethod') ?? 'shafi';
    // Removed old redundant load of 'angles' to keep it cleaner

    // Load offsets
    for (var name in prayerOffsets.keys) {
      // Default to 0 for most, except maybe a slight buffer if desired.
      prayerOffsets[name] = prefs.getInt('offset_$name') ?? 0;
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

    // Load Ayat/Hadith preference using English keys (for background sync)
    final englishNames = [
      'Fajr',
      'Sunrise',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
      'First Third',
      'Midnight',
      'Last Third'
    ];

    for (var enName in englishNames) {
      // Defaults: Main prayers ON, special times OFF
      bool isSpecialTime =
          ['Sunrise', 'First Third', 'Midnight', 'Last Third'].contains(enName);

      prayerAyatHadithEnabled[enName] =
          prefs.getBool('ayat_hadith_$enName') ?? !isSpecialTime;
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

    // Force recalculation for new internal offsets if not already done
    if (!(prefs.getBool('internal_offsets_v2') ?? false)) {
      await _cacheManager.clearCache();
      await _calculateTimes(force: true);
      await prefs.setBool('internal_offsets_v2', true);
    }
  }

  Future<void> saveCalculationSettings() async {
    final prefs = SharedPrefsCache.instance;
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

    // Force recalculation to reflect manual adjustments
    await _cacheManager.clearCache();
    await _calculateTimes(force: true);
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
    final prefs = SharedPrefsCache.instance;

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

    prayerNotificationsEnabled.assignAll(prayerValues);

    // Schedule adhkar notifications
    scheduleAdhkarNotifications();

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

  Future<void> toggleAyatHadith(String prayerName) async {
    final prefs = SharedPrefsCache.instance;
    final currentValue = prayerAyatHadithEnabled[prayerName] ?? true;
    prayerAyatHadithEnabled[prayerName] = !currentValue;
    await prefs.setBool('ayat_hadith_$prayerName', !currentValue);
    
    // Sync with background service immediately
    updatePersistentNotification();
  }

  void startNotificationUpdates() {
    _notificationTimer?.cancel();
    // Update every minute, used for day change and fajr challenge checks
    _notificationTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
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
          // Reschedule adhkar notifications for the new day
          scheduleAdhkarNotifications();
          // Clear fired indexes for the new day
          _firedPrayerIndexes.clear();
          _firedDate = now;
        }
      }

      // Check fajr challenge
      if (fajrChallengeEnabled) {
        _checkFajrChallenge();
      }

      if (!persistentNotificationEnabled) {
        stopNotificationUpdates();
      }
    });
  }

  void stopNotificationUpdates() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  Future<void> updatePersistentNotification() async {
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
    final tomorrowTimesMap = await _calculateTimesAsync({
      'year': tomorrow.year,
      'month': tomorrow.month,
      'day': tomorrow.day,
      'lat': lat,
      'lon': lon,
      'dstEnabled': dstEnabled,
      'prayerOffsets': _getEffectiveOffsets(),
      'asrMethod': asrMethod,
      'angles': angles,
      'customFajrAngle': customFajrAngle,
      'customIshaAngle': customIshaAngle,
    });
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
        DateTime? cTime = await _getFajrChallengeTime(fajrPrayer);

        // If today's challenge passed, check tomorrow's
        if (cTime != null && cTime.isBefore(now)) {
          final tomorrowFajr = sequence.firstWhere(
              (p) => p.name == 'Fajr' && p.time.day != now.day,
              orElse: () => fajrPrayer.copyWith(
                  time: fajrPrayer.time.add(const Duration(days: 1))));

          cTime = await _getFajrChallengeTime(tomorrowFajr);
        }

        if (cTime != null) {
          challengeTimestamp = cTime.millisecondsSinceEpoch;
        }
      } catch (e) {
        if (kDebugMode) print('Error calc challenge timestamp: $e');
      }
    }

    // Sync Dhikr Reminder info as well
    final dhikrHelper = DhikrReminderHelper();
    final dhikrEnabled = dhikrHelper.isEnabled;
    final dhikrInterval = dhikrHelper.intervalMinutes;
    final dhikrList = dhikrHelper.adhkar;

    // Optimization check (Include Dhikr in check to prevent blocking Dhikr settings updates)
    final checkKey =
        "${targetPrayer.time.millisecondsSinceEpoch}_${dhikrEnabled}_$dhikrInterval";
    if (_lastSentTargetTimestamp == checkKey) {
      if (kDebugMode) print("Skipping redundant notification update");
      return;
    }

    _lastSentTargetTimestamp = checkKey;

    // Call native helper with both current and fallback targets
    await PrayerNotificationHelper.startPrayerCountdown(
      hijriDate: hijriDate,
      prayerInfo: info,
      nextPrayerName: targetPrayer.name, // Use English for key checking
      targetTimestamp: targetPrayer.time.millisecondsSinceEpoch,
      nextTargetTimestamp: fallbackTimestamp,
      nextTargetPrayerName: fallbackPrayer?.name, // Use English for fallback name
      nextPrayerInfo: fallbackInfo,
      challengeTimestamp: challengeTimestamp,
      isBlackBackground: persistentNotificationBlackBg,
      notificationMode: notificationMode,
      dhikrEnabled: dhikrEnabled,
      dhikrIntervalMinutes: dhikrInterval,
      dhikrList: dhikrList,
    );
  }

  Future<DateTime?> _getFajrChallengeTime(PrayerTime fajrPrayer) async {
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
      final yesterdayTimes = await _calculateTimesAsync({
        'year': yesterday.year,
        'month': yesterday.month,
        'day': yesterday.day,
        'lat': lat,
        'lon': lon,
        'dstEnabled': dstEnabled,
        'prayerOffsets': _getEffectiveOffsets(),
        'asrMethod': asrMethod,
        'angles': angles,
        'customFajrAngle': customFajrAngle,
        'customIshaAngle': customIshaAngle,
      });
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

    if (nextPrayer == null && _tomorrowFajrTime != null) {
      final time24h =
          '${_tomorrowFajrTime!.hour.toString().padLeft(2, '0')}:${_tomorrowFajrTime!.minute.toString().padLeft(2, '0')}';
      nextPrayer =
          PrayerTime(name: 'Fajr', time: _tomorrowFajrTime!, time24h: time24h);
      nextTime = nextPrayer.time;
    } else if (nextPrayer == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = PrayerCalculationEngine.computeDayTimes({
        'year': tomorrow.year,
        'month': tomorrow.month,
        'day': tomorrow.day,
        'lat': lat,
        'lon': lon,
        'dstEnabled': dstEnabled,
        'prayerOffsets': _getEffectiveOffsets(),
        'asrMethod': asrMethod,
        'angles': angles,
        'customFajrAngle': customFajrAngle,
        'customIshaAngle': customIshaAngle,
      });
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

  void scheduleAdhkarNotifications() {
    if (prayerTimes == null || prayerTimes!.isEmpty) {
      return;
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
        isAlarm: false,
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
        isAlarm: false,
      );
    }
  }

  Future<void> _checkFajrChallenge() async {
    if (!fajrChallengeEnabled || prayerTimes == null) return;
    final now = DateTime.now();

    if (_firedDate.year != now.year ||
        _firedDate.month != now.month ||
        _firedDate.day != now.day) {
      _firedPrayerIndexes.clear();
      _firedDate = now;
    }

    for (int i = 0; i < prayerTimes!.length; i++) {
      final prayer = prayerTimes![i];

      if (prayer.name == 'Fajr') {
        int challengeIndex = 9999;

        if (!_firedPrayerIndexes.contains(challengeIndex)) {
          DateTime? challengeTime = await _getFajrChallengeTime(prayer);
          if (challengeTime != null) {
            final challengeDiff = now.difference(challengeTime);
            if (!challengeTime.isAfter(now) &&
                challengeDiff.inSeconds.abs() <= 60) {
              if (notificationSoundEnabled) playAudio();

              try {
                const platform = MethodChannel(
                    'com.example.hisn_el_muslim/prayer_notification');
                platform.invokeMethod('bringAppToForeground');
              } catch (e) {
                if (kDebugMode) print("Error bringing - $e");
              }

              Get.to(() => const FajrChallengeScreen());
              _firedPrayerIndexes.add(challengeIndex);
            }
          }
        }
      }
    }
  }

  Future<void> playAudio() async {
    if (!hasPlayedAudio) {
      try {
        await audioPlayer.play(AssetSource('adan.mp3'));
        hasPlayedAudio = true;
      } catch (e) {
        if (kDebugMode) print('playAudio error: $e');
      }
    }
  }

  Future<void> stopAudio() async {
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

    // Only handle Fajr Challenge triggers
    if (prayerName == 'Fajr_Challenge' || prayerName == 'تحي الفجر') {
      if (_firedPrayerIndexes.contains(9999)) return;
      _firedPrayerIndexes.add(9999);

      if (notificationSoundEnabled) playAudio();

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

    // Standard prayer alarms are disabled - ignore
    if (kDebugMode) print("Ignoring standard prayer alarm for: $prayerName");
  }

  @override
  void onClose() {
    _notificationTimer?.cancel();
    audioPlayer.dispose();
    super.onClose();
  }
}
