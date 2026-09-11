import 'package:flutter/material.dart';

/// Shared Husn-el-Muslim visual identity, mirrored from that app's
/// `core/theme/app_colors.dart`, `core/theme/app_theme.dart` and
/// `core/constants/strings.dart` so this Quran module looks native when it
/// is merged into the Husn-el-Muslim app.
///
/// Tajweed text colors intentionally stay untouched (see `tajweed_colors.dart`
/// and `AppPalette.ayaMark`): they encode Quranic recitation rules, not app
/// chrome.
Color bgLight = const Color.fromARGB(255, 255, 252, 254);
Color bgDark = const Color.fromARGB(255, 39, 34, 43);

/// Husn primary (burgundy) + dark surface, matching `app_theme.dart`.
class HusnTheme {
  static const primary = Color(0xFF693B42);
  static const primaryDark = Color(0xFF4E2A30);
  static const gold = Color(0xFFC9A227);
  static const scaffoldLight = Color(0xFFF5F5F5);
  static const scaffoldDark = Color(0xFF1A1A24);

  static const fontFamily = 'Amiri';

  static const double fontSize18 = 18;
  static const double fontSize22 = 22;
  static const double fontSize24 = 24;

  static const appBarBG = 'assets/appBarBG.jpg';
}
