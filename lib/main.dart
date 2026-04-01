import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workmanager/workmanager.dart';

import 'package:small_husn_muslim/app.dart';
import 'package:small_husn_muslim/core/config/app_config.dart';
import 'package:small_husn_muslim/core/services/notification_service.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/masbaha/presentation/custom_dikr_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';
import 'package:small_husn_muslim/features/azkar/presentation/home_page.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize notification service first
      await NotificationService().init();

      // Initialize logic and trigger data load
      // This will use the cached location and recalculate prayer times
      final logic = PrayerTimesLogic();
      await logic.ensureDataLoaded();

      // Schedule adhkar notifications
      logic.scheduleAdhkarNotifications();

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() {
  final stopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // Allow Google Fonts to fallback to system fonts when network unavailable
  GoogleFonts.config.allowRuntimeFetching = false;

  // 2. Initialize PrayerTimesLogic immediately so that the first screen (Onboarding)
  // can find it without waiting for the post-frame callback.
  Get.put(PrayerTimesLogic(), permanent: true);

  // Run the app IMMEDIATELY with onboarding as the default first screen.
  // After SharedPrefs load, we'll either stay on onboarding or switch to home.
  runApp(const MyApp(
    initialHomeScreen: homeScreenAzkar,
    isDarkMode: true,
    showOnboarding: true,
  ));

  // Defers all heavy initialization until after the first frame has rendered
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (kDebugMode) {
      print('⏱ First frame rendered in ${stopwatch.elapsedMilliseconds}ms');
    }
    _initializeAppAsync(stopwatch);
  });
}

Future<void> _initializeAppAsync(Stopwatch stopwatch) async {
  // 1. Load SharedPreferences once and cache it globally
  final prefs = await SharedPreferences.getInstance();
  SharedPrefsCache.init(prefs);
  if (kDebugMode) {
    print('⏱ SharedPrefs loaded in ${stopwatch.elapsedMilliseconds}ms');
  }

  // 2. We already put the Logic in main() so the UI can build safely.
  // We just find it here to continue initialization.
  final logic = Get.find<PrayerTimesLogic>();

  // 2. Check onboarding status and apply theme/home preferences
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  final savedHomeScreen = prefs.getString('home_screen') ?? homeScreenAzkar;
  final savedIsDarkMode = prefs.getBool('dark_mode') ?? true;

  if (!savedIsDarkMode) {
    Get.changeThemeMode(ThemeMode.light);
  }

  if (onboardingComplete) {
    // Onboarding already done — navigate to the user's preferred home screen
    // (the initial frame showed onboarding as placeholder, now we replace it)
    if (savedHomeScreen == homeScreenMisbaha) {
      Get.offAll(() => const CustomDikrScreen(isHomeScreen: true));
    } else if (savedHomeScreen == homeScreenPrayerTimes) {
      Get.offAll(() => const PrayerTimesScreen(isHomeScreen: true));
    } else {
      Get.offAll(() => MyHomePageScreen(isDarkMode: savedIsDarkMode));
    }
  }
  // If onboarding is NOT complete, the OnboardingScreen is already showing
  // from the initial runApp call — no navigation needed.

  // 3. Initialize background services in parallel
  await Future.wait([
    NotificationService().init().then((_) {
      if (kDebugMode) {
        print(
            '⏱ NotificationService initialized in ${stopwatch.elapsedMilliseconds}ms');
      }
    }),
    DhikrReminderHelper().init().then((_) {
      if (kDebugMode) {
        print(
            '⏱ DhikrReminderHelper initialized in ${stopwatch.elapsedMilliseconds}ms');
      }
    }),
    _initWorkmanager().then((_) {
      if (kDebugMode) {
        print(
            '⏱ Workmanager initialized in ${stopwatch.elapsedMilliseconds}ms');
      }
    }),
  ]);

  // 4. Ensure prayer data is loaded
  await logic.ensureDataLoaded();

  if (kDebugMode) {
    print(
        '⏱ Total initialization completed in ${stopwatch.elapsedMilliseconds}ms');
  }
}

Future<void> _initWorkmanager() async {
  Workmanager().initialize(
    callbackDispatcher,
  );

  Workmanager().registerPeriodicTask(
    "daily_prayer_calculation",
    "calculate_prayer_times_task",
    frequency: const Duration(hours: 12), // Run every 12 hours to be safe
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(
      networkType: NetworkType
          .connected, // Need internet for potentially fetching location if cache is old
    ),
  );
}
