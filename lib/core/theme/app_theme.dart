import 'package:flutter/material.dart';

const _snackBarTheme = SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  backgroundColor: Color(0xFF693B42),
  actionTextColor: Colors.white,
  contentTextStyle: TextStyle(
    fontFamily: 'Amiri',
    fontSize: 15,
    color: Colors.white,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
);

const _dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
);

// Matches AppSheets.show top radius so standard showModalBottomSheet
// and the custom AppSheets card share one silhouette.
const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

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
  // Defaults for SnackBar / dialog / bottom sheet. AppFeedback and
  // AppSheets read these values (shape, text, action color, surface);
  // AppFeedback only overrides the SnackBar background per severity.
  snackBarTheme: _snackBarTheme,
  dialogTheme: const DialogThemeData(
    shape: _dialogShape,
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontFamily: 'Amiri',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'Amiri',
      fontSize: 16,
      color: Colors.black87,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    showDragHandle: true,
    backgroundColor: Colors.white,
    modalBackgroundColor: Colors.white,
    shape: _sheetShape,
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
  snackBarTheme: _snackBarTheme,
  dialogTheme: const DialogThemeData(
    shape: _dialogShape,
    backgroundColor: Color(0xFF1E1E28),
    titleTextStyle: TextStyle(
      fontFamily: 'Amiri',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'Amiri',
      fontSize: 16,
      color: Colors.white,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    showDragHandle: true,
    backgroundColor: Color(0xFF1E1E28),
    modalBackgroundColor: Color(0xFF1E1E28),
    shape: _sheetShape,
  ),
);
