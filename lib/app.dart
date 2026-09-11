import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/config/app_config.dart';
import 'package:small_husn_muslim/core/theme/app_theme.dart';
import 'package:small_husn_muslim/features/azkar/presentation/home_page.dart';
import 'package:small_husn_muslim/features/masbaha/presentation/custom_dikr_screen.dart';
import 'package:small_husn_muslim/features/onboarding/presentation/onboarding_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Forces right-to-left layout app-wide, regardless of the selected
/// interface language (Arabic default; English/French stay RTL too).
/// Used as [GetMaterialApp.builder] so screens, dialogs, snackbars and
/// bottom sheets all inherit RTL from a single place.
Widget forceRtl(BuildContext context, Widget? child) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: child ?? const SizedBox.shrink(),
  );
}

class MyApp extends StatelessWidget {
  final String initialHomeScreen;
  final bool isDarkMode;
  final bool showOnboarding;
  final Locale initialLocale;

  const MyApp({
    super.key,
    required this.initialHomeScreen,
    required this.isDarkMode,
    this.showOnboarding = false,
    this.initialLocale = const Locale('ar'),
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
      locale: initialLocale,
      fallbackLocale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: forceRtl,
      home: homeWidget,
    );
  }
}
