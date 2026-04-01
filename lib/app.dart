import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/config/app_config.dart';
import 'package:small_husn_muslim/core/theme/app_theme.dart';
import 'package:small_husn_muslim/features/azkar/presentation/home_page.dart';
import 'package:small_husn_muslim/features/masbaha/presentation/custom_dikr_screen.dart';
import 'package:small_husn_muslim/features/onboarding/presentation/onboarding_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';

class MyApp extends StatelessWidget {
  final String initialHomeScreen;
  final bool isDarkMode;
  final bool showOnboarding;

  const MyApp({
    super.key,
    required this.initialHomeScreen,
    required this.isDarkMode,
    this.showOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show onboarding on first launch
    Widget homeWidget;
    if (showOnboarding) {
      homeWidget = const OnboardingScreen();
    } else {
      switch (initialHomeScreen) {
        case homeScreenMisbaha:
          homeWidget = const CustomDikrScreen(isHomeScreen: true);
          break;
        case homeScreenPrayerTimes:
          homeWidget = const PrayerTimesScreen(isHomeScreen: true);
          break;
        case homeScreenAzkar:
        default:
          homeWidget = MyHomePageScreen(isDarkMode: isDarkMode);
          break;
      }
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: homeWidget,
    );
  }
}
