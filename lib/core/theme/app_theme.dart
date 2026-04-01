import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Amiri',
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
  fontFamily: 'Amiri',
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
