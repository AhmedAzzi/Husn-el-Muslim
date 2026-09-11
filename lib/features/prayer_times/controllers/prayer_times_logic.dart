import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/core/constants/notification_ids.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:small_husn_muslim/core/services/cache_manager.dart';
import 'package:small_husn_muslim/core/services/notification_service.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_calculation_engine.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_names.dart';
import 'package:small_husn_muslim/features/prayer_times/data/mosque_api.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/tracking_home_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_widget_sync.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_reminder_service.dart';

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

  // Prayer time source mode: calculated (offline) vs mosque (online/cache)
  final prayerTimeSourceRx = PrayerTimeSource.calculated.obs;
  PrayerTimeSource get prayerTimeSource => prayerTimeSourceRx.value;
  set prayerTimeSource(PrayerTimeSource value) =>
      prayerTimeSourceRx.value = value;

  final selectedMosqueRx = Rxn<MosquePoint>();
  MosquePoint? get selectedMosque => selectedMosqueRx.value;
  set selectedMosque(MosquePoint? value) => selectedMosqueRx.value = value;

  final isMosqueScheduleOfflineRx = false.obs;
  bool get isMosqueScheduleOffline => isMosqueScheduleOfflineRx.value;
  set isMosqueScheduleOffline(bool value) =>
      isMosqueScheduleOfflineRx.value = value;

  // Nearby mosque search state
  final nearbyMosquesRx = <MosquePoint>[].obs;
  List<MosquePoint> get nearbyMosques => nearbyMosquesRx.toList();
  final isSearchingMosquesRx = false.obs;
  bool get isSearchingMosques => isSearchingMosquesRx.value;
  final nearbyMosqueCountryRx = ''.obs;
  String get nearbyMosqueCountry => nearbyMosqueCountryRx.value;

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
  bool wakeupAdhkarEnabled = false;
  bool sleepAdhkarEnabled = false;
  bool fridayKahfEnabled = false;
  bool dndDuringPrayerEnabled = false;
  int dndDurationMinutes = 20;
  bool nightPrayerTimesEnabled = true;

  // Notification behavior:
  // 0: Both notification and prayer screen (default)
  // 1: Notification only
  // 2: Prayer screen only
  // 3: No alert
  int notificationMode = 0;

  // Hidden internal base offsets were introducing a systematic skew away from
  // the raw adhan calculation. Keep the mechanism for compatibility, but default
  // it to zero so calculated times reflect the actual method output for the
  // selected location and timezone.
  final Map<String, int> _internalBaseOffsets = {
    'Fajr': 0,
    'Sunrise': 0,
    'Dhuhr': 0,
    'Asr': 0,
    'Maghrib': 0,
    'Isha': 0,
  };

  // User-facing prayer time offsets (visible in settings)
  final Map<String, int> prayerOffsets = {
    'Fajr': 0,
    'Sunrise': 0,
    'Dhuhr': 0,
    'Asr': 0,
    'Maghrib': 0,
    'Isha': 0,
  }.obs;

  // Iqama offsets in minutes (per-prayer, used in calculated mode)
  // e.g. {'Fajr': 10, 'Dhuhr': 15, ...}
  final Map<String, int> iqamaOffsets = {
    'Fajr': 0,
    'Sunrise': 0,
    'Dhuhr': 0,
    'Asr': 0,
    'Maghrib': 0,
    'Isha': 0,
  }.obs;

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

  // Generic challenge engine (Phase 3): type + difficulty. Existing installs
  // default to the legacy Questions behavior — migration-safe.
  // type: questions | math | memory | shake | random
  String fajrChallengeType = 'questions';
  // difficulty: easy | medium | hard
  String fajrChallengeDifficulty = 'medium';
  // Random-challenge pool: which types Random may pick (persisted enabled list).
  List<String> fajrRandomPool = ['questions', 'math', 'memory', 'shake'];
  // Shake sensitivity: low | medium | high.
  String fajrShakeSensitivity = 'medium';
  // Wake-up confirmation separates "challenge done" from "user awake".
  bool wakeUpConfirmationEnabled = true;

  // Additional alarms (Phase 6). All anchored to Fajr unless noted.
  bool suhoorAlarmEnabled = false;
  int suhoorOffsetMinutes = 40; // Fajr − 40min. Distinct UI from Fajr.
  bool preFajrAlarmEnabled = false;
  int preFajrOffsetMinutes =
      10; // presets 5/10/15 + custom 10–120 (shared range)
  bool bedtimeAlarmEnabled = false;
  int bedtimeHour = 23;
  int bedtimeMinute = 0;
  bool bedtimeRelativeToFajr = false;
  int bedtimeRelativeHours = 7; // Fajr − 7h when relative mode is on
  // Skip-once applies to tonight only (local date key); never disables schedule.
  String bedtimeSkipDate = '';

  // Tahajjud night-prayer alarm (Sprint 1). Mode: 'lastThird' (auto, follows
  // the computed Last Third) or 'fixed' (exact clock time, rolled daily).
  bool tahajjudEnabled = false;
  String tahajjudMode = 'lastThird';
  int tahajjudHour = 3;
  int tahajjudMinute = 30;

  // Heavy-sleeper chain: re-fire the Fajr challenge +N minutes after Fajr.
  // Two independent slots so users can enable +5 only, +10 only, or both.
  bool fajrExtra1Enabled = false;
  int fajrExtra1Minutes = 5;
  bool fajrExtra2Enabled = false;
  int fajrExtra2Minutes = 10;

  // Pre/post prayer reminders (informational; global + per-prayer, no spam).
  static const List<String> prePostPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha'
  ];
  bool prePrayerEnabled = false;
  int prePrayerOffsetMinutes = 10;
  final Map<String, bool> prePrayerPerPrayer = {
    for (final p in prePostPrayers) p: true,
  };
  bool postPrayerEnabled = false;
  int postPrayerOffsetMinutes = 15;
  final Map<String, bool> postPrayerPerPrayer = {
    for (final p in prePostPrayers) p: true,
  };

  // Alarm sound system (Phase 7). Bundled/system/local-file only — no downloads.
  // sound: adhan | system | custom
  String alarmSound = 'adhan';
  String alarmCustomPath = '';
  // 20..100 (%). Never silent: the Fajr alarm must remain audible.
  int alarmVolumePercent = 100;
  bool alarmVibrate = true;
  bool alarmLoop = true;
  // Gentle wake-up ramp: 0/30/60/120 seconds from low to target volume.
  int gentleWakeSeconds = 0;

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

  final iqamaCountdownRx = ''.obs;
  String get iqamaCountdown => iqamaCountdownRx.value;

  final nextPrayerIqamaTimeRx = ''.obs;
  String get nextPrayerIqamaTime => nextPrayerIqamaTimeRx.value;

  final hasIqamaDataRx = false.obs;
  bool get hasIqamaData => hasIqamaDataRx.value;

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
    iqamaCountdownRx.value = info['iqamaCountdown'] ?? '';
    nextPrayerIqamaTimeRx.value = info['iqamaTime'] ?? '';
    hasIqamaDataRx.value = info['hasIqama'] == true;
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

  /// Allow the Fajr challenge to be triggered again (e.g. repeated tests).
  void resetFajrChallengeFired() {
    _firedPrayerIndexes.remove(NotificationIds.fajrChallengeIndex);
    _fajrChallengeOpen = false;
  }

  /// Re-entrancy guard: the native alarm and the Dart timer can fire within
  /// milliseconds of each other — without this the screen pushes twice and
  /// the second instance keeps looping audio behind the first.
  bool _fajrChallengeOpen = false;

  /// Single guarded entry point for opening the Fajr challenge UI.
  ///
  /// Enforces the "No alert" notification mode, prevents double-push from
  /// the concurrent trigger paths, and owns the bring-to-foreground hop.
  /// Native [AlarmSound] owns the alarm audio (it works even when the Dart
  /// engine was dead); the challenge screen stops it on open.
  Future<void> _openFajrChallenge() async {
    if (notificationMode == 3) return;
    if (_fajrChallengeOpen) return;
    _fajrChallengeOpen = true;
    try {
      try {
        const platform =
            MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');
        await platform.invokeMethod('bringAppToForeground');
      } catch (e) {
        if (kDebugMode) print("Error bringing - $e");
      }
      await Get.to(() => const FajrChallengeScreen());
    } catch (e) {
      if (kDebugMode) print('Error opening Fajr challenge: $e');
    } finally {
      _fajrChallengeOpen = false;
    }
  }

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
        } else if (screenName == 'tracking') {
          if (Get.context != null) {
            Get.to(() => const TrackingHomeScreen());
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
      } else if (pendingScreen == 'tracking') {
        if (Get.context != null) {
          Get.to(() => const TrackingHomeScreen());
        }
      }
    }

    // Handle a pending alarm trigger that fired during cold start
    // (AlarmManager exact alarm -> full-screen intent -> this activity)
    final pendingAlarm = await PrayerNotificationHelper.getPendingAlarm();
    if (pendingAlarm != null) {
      _handleTriggeredAlarm(pendingAlarm);
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
        if (kDebugMode) {
          print("Location permission denied, skipping auto-request.");
        }
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
        const platform = MethodChannel('com.ahmed.hisnelmuslim/location');
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

  Future<void> _calculateTimes(
      {DateTime? targetDate, bool force = false}) async {
    final date = targetDate ?? DateTime.now();
    final dateKey = "${date.year}-${date.month}-${date.day}";

    // Check cache first (skip if forced)
    if (!force) {
      final cachedWeek = _cacheManager.getCachedWeekPrayerTimes();
      if (cachedWeek != null && cachedWeek.containsKey(dateKey)) {
        final List<dynamic> jsonList =
            jsonDecode(cachedWeek[dateKey] as String);
        final List<PrayerTime> cachedTimes = jsonList
            .map((j) => PrayerTime.fromJson(j as Map<String, dynamic>))
            .toList();

        // If this is today, update the reactive state
        if (targetDate == null) {
          prayerTimes = cachedTimes;
          isLoadingPrayerTimes = false;
          displayDate();
          // Push today's snapshot to the home-screen widgets.
          PrayerWidgetSync.syncFromTimes(
              times: cachedTimes, hijriDate: hijriDate);

          if (persistentNotificationEnabled) {
            updatePersistentNotification();
          }
          _syncFajrChallengeAlarm();
        }
        return;
      }
    }

    // If Mosque mode is active and we have an active mosque, resolve mosque schedule
    if (prayerTimeSource == PrayerTimeSource.mosque && selectedMosque != null) {
      try {
        MosqueSchedule? schedule;
        if (!force) {
          schedule = await OfflineCache.getSchedule(selectedMosque!.slug);
          if (schedule != null) {
            isMosqueScheduleOffline = true;
          }
        }
        if (schedule == null) {
          try {
            final api = MawaqitApi();
            schedule = await api.scheduleBySlug(selectedMosque!.slug,
                forceRefresh: force);
            isMosqueScheduleOffline = false;
          } catch (_) {
            schedule = await OfflineCache.getSchedule(selectedMosque!.slug);
            isMosqueScheduleOffline = true;
          }
        }

        if (schedule != null) {
          final mosqueTimes = schedule.toPrayerTimes(date);
          final currentCache = _cacheManager.getCachedWeekPrayerTimes() ?? {};
          currentCache[dateKey] =
              jsonEncode(mosqueTimes.map((p) => p.toJson()).toList());
          await _cacheManager.cacheWeekPrayerTimes(currentCache);

          if (targetDate == null) {
            prayerTimes = mosqueTimes;
            isLoadingPrayerTimes = false;
            displayDate();
            // Push today's snapshot to the home-screen widgets.
            PrayerWidgetSync.syncFromTimes(
                times: mosqueTimes, hijriDate: hijriDate);

            if (persistentNotificationEnabled) {
              updatePersistentNotification();
            }
            _syncFajrChallengeAlarm();
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print("Mosque schedule error, falling back to calculation: $e");
        }
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

    // Attach iqama times from manual offsets (calculated mode only)
    if (prayerTimeSource == PrayerTimeSource.calculated) {
      for (int i = 0; i < mainPrayersList.length; i++) {
        final p = mainPrayersList[i];
        final offsetMin = iqamaOffsets[p.name] ?? 0;
        if (offsetMin > 0) {
          final iqamaDt = p.time.add(Duration(minutes: offsetMin));
          mainPrayersList[i] = p.copyWith(iqamaTime: iqamaDt);
        }
      }
    }

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
      // Push today's snapshot to the home-screen widgets.
      PrayerWidgetSync.syncFromTimes(
          times: calculatedTimes, hijriDate: hijriDate);

      if (persistentNotificationEnabled) {
        updatePersistentNotification();
      }
      _syncFajrChallengeAlarm();
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
        '$dayName ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ،';

    // Time: HH:mm:ss
    currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  // --- Preferences & Notifications ---

  /// Publishes batched RxMap writes. When called mid-build (e.g. awaited
  /// from a screen's initState while its first build is still in flight),
  /// a synchronous notify would dirty an Obx that is already building and
  /// crash the app — so the publish is deferred past the current frame.
  /// Idle-phase callers are unaffected (same-frame publish).
  void _publishRxMap(RxMap<String, bool> target, Map<String, bool> values) {
    try {
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        target.addAll(values);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          target.addAll(values);
        });
      }
    } catch (_) {
      // No scheduler (unit tests): direct write is safe, nothing is building.
      target.addAll(values);
    }
  }

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

    // Generic challenge engine (migration-safe defaults = legacy behavior).
    fajrChallengeType = prefs.getString('fajrChallengeType') ?? 'questions';
    fajrChallengeDifficulty =
        prefs.getString('fajrChallengeDifficulty') ?? 'medium';
    final pool = prefs.getStringList('fajrRandomPool');
    if (pool != null && pool.isNotEmpty) {
      fajrRandomPool = pool
          .where((e) => ['questions', 'math', 'memory', 'shake'].contains(e))
          .toList();
      if (fajrRandomPool.isEmpty) {
        fajrRandomPool = ['questions', 'math', 'memory', 'shake'];
      }
    }
    fajrShakeSensitivity = prefs.getString('fajrShakeSensitivity') ?? 'medium';
    wakeUpConfirmationEnabled =
        prefs.getBool('wakeUpConfirmationEnabled') ?? true;

    // Additional alarms (all default OFF so existing users see no change).
    suhoorAlarmEnabled = prefs.getBool('suhoorAlarmEnabled') ?? false;
    suhoorOffsetMinutes = prefs.getInt('suhoorOffsetMinutes') ?? 40;
    preFajrAlarmEnabled = prefs.getBool('preFajrAlarmEnabled') ?? false;
    preFajrOffsetMinutes = prefs.getInt('preFajrOffsetMinutes') ?? 10;
    bedtimeAlarmEnabled = prefs.getBool('bedtimeAlarmEnabled') ?? false;
    bedtimeHour = prefs.getInt('bedtimeHour') ?? 23;
    bedtimeMinute = prefs.getInt('bedtimeMinute') ?? 0;
    bedtimeRelativeToFajr = prefs.getBool('bedtimeRelativeToFajr') ?? false;
    bedtimeRelativeHours = prefs.getInt('bedtimeRelativeHours') ?? 7;
    bedtimeSkipDate = prefs.getString('bedtimeSkipDate') ?? '';

    tahajjudEnabled = prefs.getBool('tahajjudEnabled') ?? false;
    tahajjudMode = prefs.getString('tahajjudMode') ?? 'lastThird';
    tahajjudHour = prefs.getInt('tahajjudHour') ?? 3;
    tahajjudMinute = prefs.getInt('tahajjudMinute') ?? 30;
    fajrExtra1Enabled = prefs.getBool('fajrExtra1Enabled') ?? false;
    fajrExtra1Minutes = prefs.getInt('fajrExtra1Minutes') ?? 5;
    fajrExtra2Enabled = prefs.getBool('fajrExtra2Enabled') ?? false;
    fajrExtra2Minutes = prefs.getInt('fajrExtra2Minutes') ?? 10;

    prePrayerEnabled = prefs.getBool('prePrayerEnabled') ?? false;
    prePrayerOffsetMinutes = prefs.getInt('prePrayerOffsetMinutes') ?? 10;
    for (final p in prePostPrayers) {
      prePrayerPerPrayer[p] = prefs.getBool('prePrayer_$p') ?? true;
    }
    postPrayerEnabled = prefs.getBool('postPrayerEnabled') ?? false;
    postPrayerOffsetMinutes = prefs.getInt('postPrayerOffsetMinutes') ?? 15;
    for (final p in prePostPrayers) {
      postPrayerPerPrayer[p] = prefs.getBool('postPrayer_$p') ?? true;
    }

    alarmSound = prefs.getString('alarmSound') ?? 'adhan';
    alarmCustomPath = prefs.getString('alarmCustomPath') ?? '';
    alarmVolumePercent = prefs.getInt('alarmVolumePercent') ?? 100;
    alarmVibrate = prefs.getBool('alarmVibrate') ?? true;
    alarmLoop = prefs.getBool('alarmLoop') ?? true;
    gentleWakeSeconds = prefs.getInt('gentleWakeSeconds') ?? 0;

    morningAdhkarEnabled = prefs.getBool('morningAdhkarEnabled') ?? true;
    eveningAdhkarEnabled = prefs.getBool('eveningAdhkarEnabled') ?? true;
    wakeupAdhkarEnabled = prefs.getBool('wakeupAdhkarEnabled') ?? false;
    sleepAdhkarEnabled = prefs.getBool('sleepAdhkarEnabled') ?? false;
    fridayKahfEnabled = prefs.getBool('fridayKahfEnabled') ?? false;
    dndDuringPrayerEnabled = prefs.getBool('dndDuringPrayerEnabled') ?? false;
    dndDurationMinutes = prefs.getInt('dndDurationMinutes') ?? 20;
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
      // Use neutral default (Mecca) instead of hardcoded location
      lat = 21.4225;
      lon = 39.8262;
      _hasCachedLocation = false;
      // Default to MWL for Mecca
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

    // Load iqama offsets
    for (var name in iqamaOffsets.keys) {
      iqamaOffsets[name] = prefs.getInt('iqama_offset_$name') ?? 0;
    }

    // Collect RxMap writes first and publish them past the current frame
    // (see _publishRxMap): this method is awaited from initState paths, and
    // a synchronous notify mid-build crashes observing Obx widgets.
    final notifValues = <String, bool>{};
    for (var name in arabicPrayerNames) {
      // Default to true for actual prayers, false for non-prayer times (Sunrise/Night thirds)
      bool isActualPrayer = ![
        'الشروق',
        'الثلث الأول',
        'منتصف الليل',
        'الثلث الأخير'
      ].contains(name);
      notifValues[name] = prefs.getBool('notification_$name') ?? isActualPrayer;
    }
    _publishRxMap(prayerNotificationsEnabled, notifValues);

    // Load Ayat/Hadith preference using English keys (for background sync)
    final ayatValues = <String, bool>{};
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

      ayatValues[enName] =
          prefs.getBool('ayat_hadith_$enName') ?? !isSpecialTime;
    }
    _publishRxMap(prayerAyatHadithEnabled, ayatValues);
    // Load night prayer preferences (defaulting to false if not set, or true?)
    // Let's default to false to avoid unexpected alarms unless enabled
    // final nightNames = ['الثلث الأول', 'منتصف الليل', 'الثلث الأخير', 'الشروق'];
    // for (var name in nightNames) {
    //   prayerNotificationsEnabled[name] =
    //       prefs.getBool('notification_$name') ?? false;
    // }

    // Load prayer times source (calculated vs mosque)
    final savedSource = prefs.getString('prayer_time_source');
    if (savedSource == 'mosque') {
      prayerTimeSource = PrayerTimeSource.mosque;
    } else {
      prayerTimeSource = PrayerTimeSource.calculated;
    }

    final activeMosque = await OfflineCache.getActiveMosque();
    if (activeMosque != null) {
      selectedMosque = activeMosque;
    }

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

  /// Changes the prayer times source (calculated vs mosque).
  Future<void> setPrayerTimeSource(PrayerTimeSource source) async {
    if (prayerTimeSource == source) return;
    prayerTimeSource = source;
    final prefs = SharedPrefsCache.instance;
    await prefs.setString('prayer_time_source',
        source == PrayerTimeSource.mosque ? 'mosque' : 'calculated');
    await _cacheManager.clearCache();
    await _calculateTimes(force: true);
    displayDate();
    if (persistentNotificationEnabled) {
      updatePersistentNotification();
    }
  }

  /// Sets the active mosque and immediately switches the source to [PrayerTimeSource.mosque].
  Future<void> setSelectedMosque(MosquePoint mosque,
      {MosqueSchedule? schedule}) async {
    selectedMosque = mosque;
    await OfflineCache.saveActiveMosque(mosque);
    if (schedule != null) {
      await OfflineCache.saveSchedule(mosque.slug, schedule);
    }
    prayerTimeSource = PrayerTimeSource.mosque;
    final prefs = SharedPrefsCache.instance;
    await prefs.setString('prayer_time_source', 'mosque');

    await _cacheManager.clearCache();
    await _calculateTimes(force: true);
    displayDate();
    if (persistentNotificationEnabled) {
      updatePersistentNotification();
    }
  }

  /// Slugs the user already answered (accepted or dismissed) for the
  /// nearest-mosque suggestion — never suggest them again.
  static const String _kMosqueSuggestDismissed = 'mosque_suggest_dismissed';

  Future<List<String>> dismissedMosqueSuggestions() async {
    final prefs = SharedPrefsCache.instance;
    return prefs.getStringList(_kMosqueSuggestDismissed) ?? [];
  }

  Future<void> markMosqueSuggestionDismissed(String slug) async {
    if (slug.isEmpty) return;
    final prefs = SharedPrefsCache.instance;
    final current = prefs.getStringList(_kMosqueSuggestDismissed) ?? [];
    if (!current.contains(slug)) {
      await prefs.setStringList(_kMosqueSuggestDismissed, [...current, slug]);
    }
  }

  /// Pure decision helper: suggest [nearest] only when it exists, is not
  /// already the default mosque, and was never answered before.
  static bool shouldSuggestMosque({
    required MosquePoint? nearest,
    required MosquePoint? selected,
    required List<String> dismissedSlugs,
  }) {
    if (nearest == null || nearest.slug.isEmpty) return false;
    if (selected != null && selected.slug == nearest.slug) return false;
    if (dismissedSlugs.contains(nearest.slug)) return false;
    return true;
  }

  /// Nearest mosque eligible for the suggestion dialog, or null when there
  /// is nothing to suggest (empty list, already default, already answered).
  /// Call after [searchNearbyMosques] so [nearbyMosques] is fresh.
  Future<MosquePoint?> nearestSuggestedMosque() async {
    if (nearbyMosquesRx.isEmpty) return null;
    final nearest = nearbyMosquesRx.first;
    final dismissed = await dismissedMosqueSuggestions();
    if (!shouldSuggestMosque(
      nearest: nearest,
      selected: selectedMosque,
      dismissedSlugs: dismissed,
    )) {
      return null;
    }
    return nearest;
  }

  /// Loads ALL mosques for the user's country (not just nearby ones),
  /// computing each one's distance to the user and sorting nearest-first.
  ///
  /// The user's country is inferred from their coordinates using the nearest
  /// supported-country center point. Falls back to the coordinate-based
  /// proximity search if the country list cannot be determined or loaded.
  Future<void> searchNearbyMosques() async {
    isSearchingMosquesRx.value = true;
    try {
      final api = MawaqitApi();
      final countryCode = _countryCodeFor(lat, lon);
      nearbyMosqueCountryRx.value = '';
      List<MosquePoint> results;
      try {
        final all = await api.mosquesByCountry(countryCode);
        nearbyMosqueCountryRx.value = _countryNameFor(countryCode);
        // Keep only mosques that have coordinates, annotate distance, sort.
        results = all
            .where((m) => m.latitude != 0 || m.longitude != 0)
            .map((m) => m.copyWithProximity(
                _distanceMeters(lat, lon, m.latitude, m.longitude)))
            .toList()
          ..sort((a, b) => a.proximityMeters.compareTo(b.proximityMeters));
      } catch (e) {
        if (kDebugMode) print('Country mosque list error: $e');
        // Fallback: coordinate-based search which still returns nearby entries.
        results = await api.searchNearby(lat, lon);
      }
      nearbyMosquesRx.value = results;
    } catch (e) {
      if (kDebugMode) print('Nearby mosque search error: $e');
      nearbyMosquesRx.value = [];
    } finally {
      isSearchingMosquesRx.value = false;
    }
  }

  /// Approximate the user's country from coordinates by picking the supported
  /// country whose center point is closest to (lat, lon).
  String _countryCodeFor(double lat, double lon) {
    String best = 'DZ';
    double bestDist = double.infinity;
    for (final c in _countryCenters.entries) {
      final d = _distanceMeters(lat, lon, c.value.$1, c.value.$2);
      if (d < bestDist) {
        bestDist = d;
        best = c.key;
      }
    }
    return best;
  }

  String _countryNameFor(String code) {
    for (final c in _countryNames.entries) {
      if (c.key == code) return c.value;
    }
    return code;
  }

  /// Haversine distance in meters between two coordinates.
  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  static const Map<String, (double, double)> _countryCenters = {
    'DZ': (36.75, 3.05),
    'SA': (24.71, 46.67),
    'EG': (30.04, 31.23),
    'MA': (33.57, -7.58),
    'TN': (36.80, 10.18),
    'AE': (25.20, 55.27),
    'FR': (48.85, 2.35),
    'GB': (51.50, -0.12),
    'TR': (39.93, 32.85),
    'DE': (52.52, 13.40),
    'CA': (45.42, -75.69),
    'US': (38.90, -77.03),
    'ES': (40.41, -3.70),
    'BE': (50.85, 4.35),
    'IT': (41.90, 12.49),
  };

  static const Map<String, String> _countryNames = {
    'DZ': 'الجزائر',
    'SA': 'السعودية',
    'EG': 'مصر',
    'MA': 'المغرب',
    'TN': 'تونس',
    'AE': 'الإمارات',
    'FR': 'فرنسا',
    'GB': 'بريطانيا',
    'TR': 'تركيا',
    'DE': 'ألمانيا',
    'CA': 'كندا',
    'US': 'الولايات المتحدة',
    'ES': 'إسبانيا',
    'BE': 'بلجيكا',
    'IT': 'إيطاليا',
  };

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

    // Save iqama offsets
    for (var entry in iqamaOffsets.entries) {
      await prefs.setInt('iqama_offset_${entry.key}', entry.value);
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
      String? challengeType,
      String? challengeDifficulty,
      List<String>? challengePool,
      String? shakeSensitivity,
      bool? wakeUpConfirmationValue,
      bool? morningAdhkarValue,
      bool? eveningAdhkarValue,
      bool? wakeupAdhkarValue,
      bool? sleepAdhkarValue,
      bool? fridayKahfValue,
      bool? dndDuringPrayerValue,
      int? dndDurationMinutesValue,
      bool? nightPrayerTimesValue,
      int? notificationModeValue,
      bool? suhoorValue,
      int? suhoorOffset,
      bool? preFajrValue,
      int? preFajrOffset,
      bool? bedtimeValue,
      int? bedtimeH,
      int? bedtimeM,
      bool? bedtimeRelative,
      int? bedtimeRelHours,
      bool? tahajjudValue,
      String? tahajjudModeValue,
      int? tahajjudH,
      int? tahajjudM,
      bool? fajrExtra1Value,
      int? fajrExtra1Delay,
      bool? fajrExtra2Value,
      int? fajrExtra2Delay,
      bool? prePrayerValue,
      int? prePrayerOffset,
      Map<String, bool>? prePrayerMap,
      bool? postPrayerValue,
      int? postPrayerOffset,
      Map<String, bool>? postPrayerMap,
      String? alarmSoundValue,
      String? alarmCustomPathValue,
      int? alarmVolumeValue,
      bool? alarmVibrateValue,
      bool? alarmLoopValue,
      int? gentleWakeValue}) async {
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
    if (challengeType != null) {
      await prefs.setString('fajrChallengeType', challengeType);
      fajrChallengeType = challengeType;
    }
    if (challengeDifficulty != null) {
      await prefs.setString('fajrChallengeDifficulty', challengeDifficulty);
      fajrChallengeDifficulty = challengeDifficulty;
    }
    if (challengePool != null && challengePool.isNotEmpty) {
      await prefs.setStringList('fajrRandomPool', challengePool);
      fajrRandomPool = List.of(challengePool);
    }
    if (shakeSensitivity != null) {
      await prefs.setString('fajrShakeSensitivity', shakeSensitivity);
      fajrShakeSensitivity = shakeSensitivity;
    }
    if (wakeUpConfirmationValue != null) {
      await prefs.setBool('wakeUpConfirmationEnabled', wakeUpConfirmationValue);
      wakeUpConfirmationEnabled = wakeUpConfirmationValue;
    }
    if (suhoorValue != null) {
      await prefs.setBool('suhoorAlarmEnabled', suhoorValue);
      suhoorAlarmEnabled = suhoorValue;
    }
    if (suhoorOffset != null) {
      await prefs.setInt('suhoorOffsetMinutes', suhoorOffset);
      suhoorOffsetMinutes = suhoorOffset;
    }
    if (preFajrValue != null) {
      await prefs.setBool('preFajrAlarmEnabled', preFajrValue);
      preFajrAlarmEnabled = preFajrValue;
    }
    if (preFajrOffset != null) {
      await prefs.setInt('preFajrOffsetMinutes', preFajrOffset);
      preFajrOffsetMinutes = preFajrOffset;
    }
    if (bedtimeValue != null) {
      await prefs.setBool('bedtimeAlarmEnabled', bedtimeValue);
      bedtimeAlarmEnabled = bedtimeValue;
    }
    if (bedtimeH != null) {
      await prefs.setInt('bedtimeHour', bedtimeH);
      bedtimeHour = bedtimeH;
    }
    if (bedtimeM != null) {
      await prefs.setInt('bedtimeMinute', bedtimeM);
      bedtimeMinute = bedtimeM;
    }
    if (bedtimeRelative != null) {
      await prefs.setBool('bedtimeRelativeToFajr', bedtimeRelative);
      bedtimeRelativeToFajr = bedtimeRelative;
    }
    if (bedtimeRelHours != null) {
      await prefs.setInt('bedtimeRelativeHours', bedtimeRelHours);
      bedtimeRelativeHours = bedtimeRelHours;
    }
    if (tahajjudValue != null) {
      await prefs.setBool('tahajjudEnabled', tahajjudValue);
      tahajjudEnabled = tahajjudValue;
    }
    if (tahajjudModeValue != null) {
      await prefs.setString('tahajjudMode', tahajjudModeValue);
      tahajjudMode = tahajjudModeValue;
    }
    if (tahajjudH != null) {
      await prefs.setInt('tahajjudHour', tahajjudH);
      tahajjudHour = tahajjudH;
    }
    if (tahajjudM != null) {
      await prefs.setInt('tahajjudMinute', tahajjudM);
      tahajjudMinute = tahajjudM;
    }
    if (fajrExtra1Value != null) {
      await prefs.setBool('fajrExtra1Enabled', fajrExtra1Value);
      fajrExtra1Enabled = fajrExtra1Value;
    }
    if (fajrExtra1Delay != null) {
      await prefs.setInt(
          'fajrExtra1Minutes', fajrExtra1Delay.clamp(1, 60));
      fajrExtra1Minutes = fajrExtra1Delay.clamp(1, 60);
    }
    if (fajrExtra2Value != null) {
      await prefs.setBool('fajrExtra2Enabled', fajrExtra2Value);
      fajrExtra2Enabled = fajrExtra2Value;
    }
    if (fajrExtra2Delay != null) {
      await prefs.setInt(
          'fajrExtra2Minutes', fajrExtra2Delay.clamp(1, 60));
      fajrExtra2Minutes = fajrExtra2Delay.clamp(1, 60);
    }
    if (prePrayerValue != null) {
      await prefs.setBool('prePrayerEnabled', prePrayerValue);
      prePrayerEnabled = prePrayerValue;
    }
    if (prePrayerOffset != null) {
      await prefs.setInt('prePrayerOffsetMinutes', prePrayerOffset);
      prePrayerOffsetMinutes = prePrayerOffset;
    }
    if (prePrayerMap != null) {
      for (final e in prePrayerMap.entries) {
        await prefs.setBool('prePrayer_${e.key}', e.value);
        prePrayerPerPrayer[e.key] = e.value;
      }
    }
    if (postPrayerValue != null) {
      await prefs.setBool('postPrayerEnabled', postPrayerValue);
      postPrayerEnabled = postPrayerValue;
    }
    if (postPrayerOffset != null) {
      await prefs.setInt('postPrayerOffsetMinutes', postPrayerOffset);
      postPrayerOffsetMinutes = postPrayerOffset;
    }
    if (postPrayerMap != null) {
      for (final e in postPrayerMap.entries) {
        await prefs.setBool('postPrayer_${e.key}', e.value);
        postPrayerPerPrayer[e.key] = e.value;
      }
    }
    if (alarmSoundValue != null) {
      await prefs.setString('alarmSound', alarmSoundValue);
      alarmSound = alarmSoundValue;
    }
    if (alarmCustomPathValue != null) {
      await prefs.setString('alarmCustomPath', alarmCustomPathValue);
      alarmCustomPath = alarmCustomPathValue;
    }
    if (alarmVolumeValue != null) {
      final v = alarmVolumeValue.clamp(20, 100);
      await prefs.setInt('alarmVolumePercent', v);
      alarmVolumePercent = v;
    }
    if (alarmVibrateValue != null) {
      await prefs.setBool('alarmVibrate', alarmVibrateValue);
      alarmVibrate = alarmVibrateValue;
    }
    if (alarmLoopValue != null) {
      await prefs.setBool('alarmLoop', alarmLoopValue);
      alarmLoop = alarmLoopValue;
    }
    if (gentleWakeValue != null) {
      await prefs.setInt('gentleWakeSeconds', gentleWakeValue);
      gentleWakeSeconds = gentleWakeValue;
    }
    if (morningAdhkarValue != null) {
      await prefs.setBool('morningAdhkarEnabled', morningAdhkarValue);
      morningAdhkarEnabled = morningAdhkarValue;
    }
    if (eveningAdhkarValue != null) {
      await prefs.setBool('eveningAdhkarEnabled', eveningAdhkarValue);
      eveningAdhkarEnabled = eveningAdhkarValue;
    }
    if (wakeupAdhkarValue != null) {
      await prefs.setBool('wakeupAdhkarEnabled', wakeupAdhkarValue);
      wakeupAdhkarEnabled = wakeupAdhkarValue;
    }
    if (sleepAdhkarValue != null) {
      await prefs.setBool('sleepAdhkarEnabled', sleepAdhkarValue);
      sleepAdhkarEnabled = sleepAdhkarValue;
    }
    if (fridayKahfValue != null) {
      await prefs.setBool('fridayKahfEnabled', fridayKahfValue);
      fridayKahfEnabled = fridayKahfValue;
    }
    if (dndDuringPrayerValue != null) {
      await prefs.setBool('dndDuringPrayerEnabled', dndDuringPrayerValue);
      dndDuringPrayerEnabled = dndDuringPrayerValue;
    }
    if (dndDurationMinutesValue != null) {
      await prefs.setInt('dndDurationMinutes', dndDurationMinutesValue);
      dndDurationMinutes = dndDurationMinutesValue;
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

    // Always keep the Fajr challenge exact alarm in sync, regardless of the
    // persistent notification state, so toggling/offset changes take effect.
    // (_syncFajrChallengeAlarm also syncs Suhoor/Pre-Fajr/Bedtime.)
    await _syncFajrChallengeAlarm();

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
    final isSpecialTime = ['Sunrise', 'First Third', 'Midnight', 'Last Third']
        .contains(prayerName);
    final currentValue = prayerAyatHadithEnabled[prayerName] ?? !isSpecialTime;
    final newValue = !currentValue;
    prayerAyatHadithEnabled[prayerName] = newValue;
    await prefs.setBool('ayat_hadith_$prayerName', newValue);

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
        _syncFajrChallengeAlarm();
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

    String targetName =
        kArabicPrayerNames[targetPrayer.name] ?? targetPrayer.name;
    String info = '$targetName ,${targetPrayer.time24h}';

    // Append iqama time to notification info if available
    if (targetPrayer.iqamaTime != null) {
      final iqamaH = targetPrayer.iqamaTime!.hour.toString().padLeft(2, '0');
      final iqamaM = targetPrayer.iqamaTime!.minute.toString().padLeft(2, '0');
      info += ' | الإقامة $iqamaH:$iqamaM';
    }

    String? fallbackInfo;
    int? fallbackTimestamp;

    if (fallbackPrayer != null) {
      String fbName =
          kArabicPrayerNames[fallbackPrayer.name] ?? fallbackPrayer.name;
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

    // Optimization check (Include Dhikr and Fajr Challenge in check to prevent blocking settings updates)
    final checkKey = '${targetPrayer.time.millisecondsSinceEpoch}'
        '_$dhikrEnabled'
        '_$dhikrInterval'
        '_$fajrChallengeEnabled'
        '_$fajrChallengeWakeUpMode'
        '_$fajrChallengeCustomOffsetMinutes';
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
      nextTargetPrayerName:
          fallbackPrayer?.name, // Use English for fallback name
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

  /// Schedule (or cancel) the Fajr challenge exact alarm on the native side,
  /// independent of the persistent notification service, so it works even when
  /// the persistent notification / location permission is unavailable.
  Future<void> _syncFajrChallengeAlarm() async {
    if (!fajrChallengeEnabled || prayerTimes == null || prayerTimes!.isEmpty) {
      await PrayerNotificationHelper.scheduleFajrChallengeAlarm(0);
      await PrayerNotificationHelper.scheduleFajrExtra1Alarm(0);
      await PrayerNotificationHelper.scheduleFajrExtra2Alarm(0);
      await syncAdditionalAlarms();
      return;
    }
    try {
      final fajrPrayer = prayerTimes!.firstWhere((p) => p.name == 'Fajr');
      DateTime? cTime = await _getFajrChallengeTime(fajrPrayer);
      final now = DateTime.now();

      // If today's challenge time passed, schedule for tomorrow's Fajr
      if (cTime != null && cTime.isBefore(now)) {
        cTime = await _getFajrChallengeTime(fajrPrayer.copyWith(
            time: fajrPrayer.time.add(const Duration(days: 1))));
      }

      await PrayerNotificationHelper.scheduleFajrChallengeAlarm(
          cTime?.millisecondsSinceEpoch ?? 0);
      await _syncFajrExtraAlarms(fajrPrayer, DateTime.now());
    } catch (e) {
      if (kDebugMode) print('Error syncing fajr challenge alarm: $e');
    }
    await syncAdditionalAlarms();
  }

  /// Heavy-sleeper chain: re-fire the Fajr challenge at Fajr +N minutes.
  /// Anchored to the Fajr prayer itself (not the challenge time, which may be
  /// Last-Third). Each slot cancels first; disabled slots cancel stale alarms.
  Future<void> _syncFajrExtraAlarms(
      PrayerTime fajrPrayer, DateTime now) async {
    if (!fajrChallengeEnabled) {
      await PrayerNotificationHelper.scheduleFajrExtra1Alarm(0);
      await PrayerNotificationHelper.scheduleFajrExtra2Alarm(0);
      return;
    }
    Future<void> syncOne(
        bool enabled, int delayMin, Future<bool> Function(int) schedule) async {
      if (!enabled) {
        await schedule(0);
        return;
      }
      var t = fajrPrayer.time.add(Duration(minutes: delayMin.clamp(1, 60)));
      if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
      await schedule(t.isAfter(now) ? t.millisecondsSinceEpoch : 0);
    }

    await syncOne(
        fajrExtra1Enabled, fajrExtra1Minutes, PrayerNotificationHelper.scheduleFajrExtra1Alarm);
    await syncOne(
        fajrExtra2Enabled, fajrExtra2Minutes, PrayerNotificationHelper.scheduleFajrExtra2Alarm);
  }

  /// Syncs Suhoor / Pre-Fajr / Bedtime native exact alarms from the current
  /// prayer times + user offsets. Every path cancels first (0 = cancel), so
  /// toggling OFF or a passed time can never leave a stale PendingIntent.
  /// All three are real AlarmManager alarms — no faked UI.
  Future<void> syncAdditionalAlarms() async {
    try {
      final now = DateTime.now();
      PrayerTime? fajr;
      try {
        fajr = prayerTimes?.firstWhere((p) => p.name == 'Fajr');
      } catch (_) {
        fajr = null;
      }

      // Suhoor: Fajr − offset (default 40min). Rolled to tomorrow if passed.
      if (!suhoorAlarmEnabled || fajr == null) {
        await PrayerNotificationHelper.scheduleSuhoorAlarm(0);
      } else {
        var t = fajr.time.subtract(Duration(minutes: suhoorOffsetMinutes));
        if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
        await PrayerNotificationHelper.scheduleSuhoorAlarm(
            t.isAfter(now) ? t.millisecondsSinceEpoch : 0);
      }

      // Pre-Fajr: Fajr − offset (presets 5/10/15, custom 10–120 preserved).
      if (!preFajrAlarmEnabled || fajr == null) {
        await PrayerNotificationHelper.schedulePreFajrAlarm(0);
      } else {
        var t = fajr.time.subtract(Duration(minutes: preFajrOffsetMinutes));
        if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
        await PrayerNotificationHelper.schedulePreFajrAlarm(
            t.isAfter(now) ? t.millisecondsSinceEpoch : 0);
      }

      // Tahajjud: Last-Third auto (follows computed night boundary) or fixed
      // clock time. Rolled to tomorrow if passed. Cancel-first like the rest.
      if (!tahajjudEnabled) {
        await PrayerNotificationHelper.scheduleTahajjudAlarm(0);
      } else if (tahajjudMode == 'fixed') {
        var t = DateTime(
            now.year, now.month, now.day, tahajjudHour, tahajjudMinute);
        if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
        await PrayerNotificationHelper.scheduleTahajjudAlarm(
            t.millisecondsSinceEpoch);
      } else {
        PrayerTime? lastThird;
        try {
          lastThird = prayerTimes?.firstWhere((p) => p.name == 'Last Third');
        } catch (_) {
          lastThird = null;
        }
        if (lastThird == null) {
          await PrayerNotificationHelper.scheduleTahajjudAlarm(0);
        } else {
          var t = lastThird.time;
          if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
          await PrayerNotificationHelper.scheduleTahajjudAlarm(
              t.isAfter(now) ? t.millisecondsSinceEpoch : 0);
        }
      }

      // Bedtime: exact clock time, or Fajr-relative (Fajr − N hours).
      // Skip-once only suppresses tonight; the recurring schedule stays on.
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (!bedtimeAlarmEnabled || bedtimeSkipDate == todayKey) {
        await PrayerNotificationHelper.scheduleBedtimeAlarm(0);
      } else if (bedtimeRelativeToFajr && fajr != null) {
        var t = fajr.time.subtract(Duration(hours: bedtimeRelativeHours));
        if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
        await PrayerNotificationHelper.scheduleBedtimeAlarm(
            t.millisecondsSinceEpoch);
      } else {
        var t =
            DateTime(now.year, now.month, now.day, bedtimeHour, bedtimeMinute);
        if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
        await PrayerNotificationHelper.scheduleBedtimeAlarm(
            t.millisecondsSinceEpoch);
      }

      await _syncPrePostPrayers(now);
    } catch (e) {
      if (kDebugMode) print('Error syncing additional alarms: $e');
    }
  }

  /// Skips tonight's bedtime reminder once without disabling the schedule.
  Future<void> skipBedtimeOnce() async {
    final now = DateTime.now();
    bedtimeSkipDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final prefs = SharedPrefsCache.instance;
    await prefs.setString('bedtimeSkipDate', bedtimeSkipDate);
    await PrayerNotificationHelper.scheduleBedtimeAlarm(0);
  }

  /// Pre-prayer = next upcoming enabled prayer − offset; post-prayer = most
  /// recent past enabled prayer + offset (if still in the future). One native
  /// alarm each, re-armed on every prayer-time refresh.
  Future<void> _syncPrePostPrayers(DateTime now) async {
    final times = prayerTimes;
    if (times == null || times.isEmpty) {
      await PrayerNotificationHelper.schedulePrePrayerAlarm(0, '');
      await PrayerNotificationHelper.schedulePostPrayerAlarm(0, '');
      return;
    }
    DateTime? nextTime;
    String nextName = '';
    DateTime? lastTime;
    String lastName = '';
    for (final p in times) {
      if (!prePostPrayers.contains(p.name)) continue;
      if (p.time.isAfter(now)) {
        if (nextTime == null || p.time.isBefore(nextTime)) {
          nextTime = p.time;
          nextName = p.name;
        }
      } else {
        if (lastTime == null || p.time.isAfter(lastTime)) {
          lastTime = p.time;
          lastName = p.name;
        }
      }
    }
    if (prePrayerEnabled &&
        nextTime != null &&
        (prePrayerPerPrayer[nextName] ?? true)) {
      final t = nextTime.subtract(Duration(minutes: prePrayerOffsetMinutes));
      if (t.isAfter(now)) {
        await PrayerNotificationHelper.schedulePrePrayerAlarm(
            t.millisecondsSinceEpoch, nextName);
      } else {
        await PrayerNotificationHelper.schedulePrePrayerAlarm(0, '');
      }
    } else {
      await PrayerNotificationHelper.schedulePrePrayerAlarm(0, '');
    }
    if (postPrayerEnabled &&
        lastTime != null &&
        (postPrayerPerPrayer[lastName] ?? true)) {
      final t = lastTime.add(Duration(minutes: postPrayerOffsetMinutes));
      if (t.isAfter(now)) {
        await PrayerNotificationHelper.schedulePostPrayerAlarm(
            t.millisecondsSinceEpoch, lastName);
      } else {
        await PrayerNotificationHelper.schedulePostPrayerAlarm(0, '');
      }
    } else {
      await PrayerNotificationHelper.schedulePostPrayerAlarm(0, '');
    }
  }

  Map<String, dynamic> getNextPrayerInfo() {
    if (prayerTimes == null || prayerTimes!.isEmpty) {
      return {
        'name': '',
        'timeRemaining': '',
        'iqamaCountdown': '',
        'iqamaTime': '',
        'hasIqama': false
      };
    }

    final now = DateTime.now();
    final arabicNames = kArabicPrayerNames;

    // 1) Look for the currently-active prayer: its adhan has already
    //    sounded but its iqama time is still ahead (we are inside the
    //    adhan -> iqama window). Only then do we show the iqama countdown.
    PrayerTime? activeIqamaPrayer;
    for (var prayer in prayerTimes!) {
      final iqama = prayer.iqamaTime;
      if (iqama == null) continue;
      // Prayer list may include Sunrise/night thirds; iqama only applies to
      // the five main prayers which always have iqamaTime when available.
      if (prayer.time.isBefore(now) && iqama.isAfter(now)) {
        if (activeIqamaPrayer == null ||
            prayer.time.isAfter(activeIqamaPrayer.time)) {
          activeIqamaPrayer = prayer;
        }
      }
    }

    // If we are inside an active iqama window (adhan already fired),
    // display the countdown to iqama.
    if (activeIqamaPrayer != null) {
      final iqama = activeIqamaPrayer.iqamaTime!;
      final iqamaRemaining = iqama.difference(now);
      final iqamaCountdown = _formatCountdown(iqamaRemaining);
      final iqamaTimeStr =
          '${iqama.hour.toString().padLeft(2, '0')}:${iqama.minute.toString().padLeft(2, '0')}';
      return {
        'name': arabicNames[activeIqamaPrayer.name] ?? activeIqamaPrayer.name,
        'timeRemaining': iqamaCountdown,
        'iqamaCountdown': iqamaCountdown,
        'iqamaTime': iqamaTimeStr,
        'hasIqama': true,
        'prayerTime': activeIqamaPrayer.time24h,
      };
    }

    // 2) Otherwise, determine the next upcoming adhan and count down to it.
    PrayerTime? nextPrayer;
    DateTime? nextTime;

    for (var prayer in prayerTimes!) {
      final prayerDateTime = prayer.time;

      if (prayerDateTime.isAfter(now)) {
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

    // Adhan countdown (iqama not active, so no iqama display)
    final remaining = nextTime!.difference(now);
    final adhanCountdown = _formatCountdown(remaining);

    return {
      'name': arabicNames[nextPrayer.name] ?? nextPrayer.name,
      'timeRemaining': adhanCountdown,
      'iqamaCountdown': '',
      'iqamaTime': '',
      'hasIqama': false,
      'prayerTime': nextPrayer.time24h,
    };
  }

  /// Formats a duration as a countdown string, showing "الآن" when within 10s.
  String _formatCountdown(Duration remaining) {
    if (remaining.inSeconds <= 0 && remaining.inSeconds >= -9) {
      return 'الآن';
    }
    String result = '';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    if (hours > 0) {
      result += '${hours.toString().padLeft(2, '0')}:';
    }
    result +=
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return result;
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
        NotificationIds.morningAdhkar,
        'أذكار الصباح',
        'حان الآن وقت أذكار الصباح',
        adhkarTime,
        notificationSoundEnabled,
        payload: NotificationIds.morningAdhkarPayload,
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
        NotificationIds.eveningAdhkar,
        'أذكار المساء',
        'حان الآن وقت أذكار المساء',
        adhkarTime,
        notificationSoundEnabled,
        payload: NotificationIds.eveningAdhkarPayload,
        isAlarm: false,
      );
    } else {
      NotificationService().cancelNotification(NotificationIds.eveningAdhkar);
    }

    if (wakeupAdhkarEnabled) {
      final fajr = prayerTimes!.firstWhere((p) => p.name == 'Fajr');
      DateTime adhkarTime = fajr.time;
      if (adhkarTime.isBefore(DateTime.now())) {
        adhkarTime = adhkarTime.add(const Duration(days: 1));
      }
      NotificationService().showNotification(
        NotificationIds.wakeupAdhkar,
        'أذكار الاستيقاظ',
        'الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور',
        adhkarTime,
        notificationSoundEnabled,
        payload: NotificationIds.wakeupAdhkarPayload,
        isAlarm: false,
      );
    } else {
      NotificationService().cancelNotification(NotificationIds.wakeupAdhkar);
    }

    if (sleepAdhkarEnabled) {
      final isha = prayerTimes!.firstWhere((p) => p.name == 'Isha');
      DateTime adhkarTime = isha.time.add(const Duration(hours: 1));
      if (adhkarTime.isBefore(DateTime.now())) {
        adhkarTime = adhkarTime.add(const Duration(days: 1));
      }
      NotificationService().showNotification(
        NotificationIds.sleepAdhkar,
        'أذكار النوم',
        'باسمك ربي وضعت جنبي وبك أرفعه',
        adhkarTime,
        notificationSoundEnabled,
        payload: NotificationIds.sleepAdhkarPayload,
        isAlarm: false,
      );
    } else {
      NotificationService().cancelNotification(NotificationIds.sleepAdhkar);
    }

    if (fridayKahfEnabled) {
      final now = DateTime.now();
      int daysUntilFriday = (DateTime.friday - now.weekday) % 7;
      DateTime fridayTime =
          DateTime(now.year, now.month, now.day + daysUntilFriday, 9, 0);
      if (fridayTime.isBefore(now)) {
        fridayTime = fridayTime.add(const Duration(days: 7));
      }
      // The Kahf reminder is a UI string (not Quran/dua source text), so it
      // follows the app language via ARB. The controller has no BuildContext,
      // so resolve via the stored language code; any failure keeps the
      // Arabic defaults and never breaks scheduling (offline-safe).
      String kahfTitle = 'سورة الكهف';
      String kahfBody = 'لا تنس قراءة سورة الكهف اليوم — نور ما بين الجمعتين';
      try {
        final lang =
            SharedPrefsCache.instance.getString('app_language') ?? 'ar';
        final kahfLoc = lookupAppLocalizations(Locale(lang));
        kahfTitle = kahfLoc.nsFridayKahfTitle;
        kahfBody = kahfLoc.nsFridayKahfBody;
      } catch (_) {
        // Keep Arabic defaults.
      }
      NotificationService().showWeeklyNotification(
        NotificationIds.fridayKahf,
        kahfTitle,
        kahfBody,
        fridayTime,
        notificationSoundEnabled,
        payload: NotificationIds.fridayKahfPayload,
      );
    } else {
      NotificationService().cancelNotification(NotificationIds.fridayKahf);
    }

    // Tracker logging reminders: recompute exact one-shot nudges from
    // today's times. Runs on app start + settings changes; safe no-op when
    // reminders are off, tracking is paused, or times are missing.
    try {
      final order = PrayerReminderService.engineOrder;
      final moments = <PrayerMoment>[];
      for (var i = 0; i < order.length; i++) {
        final match = prayerTimes!.where((p) => p.name == order[i]);
        if (match.isNotEmpty) {
          moments.add(PrayerMoment(order[i], match.first.time));
        }
      }
      if (moments.length == 5) {
        PrayerReminderService.instance.refreshWithMoments(moments);
      }
    } catch (_) {
      // Never break adhkar scheduling over tracker reminders.
    }
  }

  Future<void> _checkFajrChallenge() async {
    if (!fajrChallengeEnabled || prayerTimes == null) return;
    if (notificationMode == 3) return; // "No alert" silences everything
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
        int challengeIndex = NotificationIds.fajrChallengeIndex;

        if (!_firedPrayerIndexes.contains(challengeIndex)) {
          DateTime? challengeTime = await _getFajrChallengeTime(prayer);
          if (challengeTime != null) {
            final challengeDiff = now.difference(challengeTime);
            if (!challengeTime.isAfter(now) &&
                challengeDiff.inSeconds.abs() <= 60) {
              // No Dart-side audio here: native AlarmSound already rings
              // (audible even from background); the screen starts its loop.
              _openFajrChallenge();
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
      if (notificationMode == 3) return; // "No alert" silences everything
      if (_firedPrayerIndexes.contains(NotificationIds.fajrChallengeIndex)) {
        return;
      }
      _firedPrayerIndexes.add(NotificationIds.fajrChallengeIndex);

      // No Dart-side audio here: native AlarmSound already rings.
      _openFajrChallenge();
      return;
    }

    // Standard prayer alarms are disabled - ignore
    if (kDebugMode) print("Ignoring standard prayer alarm for: $prayerName");
  }

  @override
  void onClose() {
    _notificationTimer?.cancel();
    _countdownTimer?.cancel();
    audioPlayer.dispose();
    super.onClose();
  }
}
