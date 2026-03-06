import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart';
import 'screens/custom_dikr_screen.dart';
import 'screens/prayer_times_screen.dart';
import 'models/prayer_times_logic.dart';
import 'helpers/dhikr_reminder_helper.dart';

// Home screen options
const String homeScreenAzkar = 'azkar';
const String homeScreenMisbaha = 'misbaha';
const String homeScreenPrayerTimes = 'prayer_times';

// App themes
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF693B42),
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF693B42),
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF693B42),
    brightness: Brightness.light,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF693B42),
  scaffoldBackgroundColor: const Color(0xFF1A1A24),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1A24),
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF693B42),
    brightness: Brightness.dark,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow Google Fonts to fallback to system fonts when network unavailable
  GoogleFonts.config.allowRuntimeFetching = false;

  await NotificationService().init();

  // Initialize Dhikr Reminder System
  await DhikrReminderHelper().init();

  // Initialize PrayerTimesLogic early to handle notification intents
  await PrayerTimesLogic().ensureDataLoaded();

  // Load preferences
  final prefs = await SharedPreferences.getInstance();
  final homeScreen = prefs.getString('home_screen') ?? homeScreenAzkar;
  final isDarkMode = prefs.getBool('dark_mode') ?? true; // Default to dark

  runApp(MyApp(
    initialHomeScreen: homeScreen,
    isDarkMode: isDarkMode,
  ));
}

class MyApp extends StatelessWidget {
  final String initialHomeScreen;
  final bool isDarkMode;

  const MyApp({
    super.key,
    required this.initialHomeScreen,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which screen to show based on preference
    Widget homeWidget;
    switch (initialHomeScreen) {
      case homeScreenMisbaha:
        homeWidget = const CustomDikrScreen(isHomeScreen: true);
        break;
      case homeScreenPrayerTimes:
        homeWidget = const PrayerTimesScreen(isHomeScreen: true);
        break;
      case homeScreenAzkar:
      default:
        // The MyHomePageScreen already has GetMaterialApp inside it
        return MyHomePageScreen(isDarkMode: isDarkMode);
    }

    // For non-default home screens, wrap with GetMaterialApp
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: homeWidget,
    );
  }
}
