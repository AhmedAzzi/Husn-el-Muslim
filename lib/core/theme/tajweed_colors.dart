import 'package:flutter/material.dart';

/// Tajweed palette sampled from the web `app.css` variables.
class TajweedColors {
  static Color of(String cls, {required bool dark}) {
    switch (cls) {
      case 'silent':
      case 'hamzah-wasl':
      case 'idgham-bilaghunnah':
      case 'idgham-mutamatsilain':
      case 'idgham-mutajanisain':
        return dark ? const Color(0xFF9AA0A6) : const Color(0xFF8B8E90);
      case 'madd-wajib':
      case 'madd-jaiz':
      case 'madd-4-5':
        return dark ? const Color(0xFFE8604C) : const Color(0xFFD63821);
      case 'madd-arid-lissukun':
      case 'madd-2-4-6':
        return dark ? const Color(0xFFEDA06B) : const Color(0xFFE37138);
      case 'madd-lazim-mutsaqal-harfi':
      case 'madd-lazim-mukhofaf-harfi':
      case 'madd-6':
        return dark ? const Color(0xFFD96A5B) : const Color(0xFF8C1D12);
      case 'ghunnah':
      case 'idgham-mimi':
      case 'idgham-bighunnah':
      case 'iqlab':
        return dark ? const Color(0xFF7BA78B) : const Color(0xFF3C6838);
      case 'ikhfa':
      case 'ikhfa-syafawi':
        return dark ? const Color(0xFFA4BD85) : const Color(0xFF87A162);
      case 'qalqalah':
        return dark ? const Color(0xFF4A90D9) : const Color(0xFF2368BC);
      default:
        return dark ? const Color(0xFFE5E7EB) : Colors.black;
    }
  }

  static const List<({String cls, String sample})> legendItems = [
    (cls: 'madd-wajib', sample: 'مَدّ وَاجِب'),
    (cls: 'madd-jaiz', sample: 'مَدّ جَائِز'),
    (cls: 'madd-arid-lissukun', sample: 'مَدّ عَارِض'),
    (cls: 'madd-lazim-mutsaqal-harfi', sample: 'مَدّ لَازِم'),
    (cls: 'ghunnah', sample: 'غُنَّة'),
    (cls: 'idgham-bighunnah', sample: 'إِدْغَام بِغُنَّة'),
    (cls: 'idgham-bilaghunnah', sample: 'بِغَيْرِ غُنَّة'),
    (cls: 'ikhfa', sample: 'إِخْفَاء'),
    (cls: 'ikhfa-syafawi', sample: 'إِخْفَاء شَفَوِيّ'),
    (cls: 'idgham-mimi', sample: 'إِدْغَام شَفَوِيّ'),
    (cls: 'iqlab', sample: 'إِقْلَاب'),
    (cls: 'qalqalah', sample: 'قَلْقَلَة'),
    (cls: 'silent', sample: 'لَا يُلْفَظ'),
  ];
}

/// App chrome palette. Burgundy + gold follow the Husn-el-Muslim identity
/// so this module merges visually into that app. Tajweed *text* colors in
/// [TajweedColors] are untouched — they encode recitation rules.
class AppPalette {
  static const primary = Color(0xFF693B42);
  static const primaryDark = Color(0xFF4E2A30);
  static const gold = Color(0xFFC9A227);
  static const goldDark = Color(0xFF8A6D2B);
  static const paper = Color(0xFFFFFDF5);
  static const paperBand1 = Color(0xFFF7ECD0);
  static const paperBand2 = Color(0xFFEFDFB5);
  static const ayaMark = Color(0xFF27416C);
  static const darkSurface = Color(0xFF1A1A24);
  static const darkCard = Color(0xFF27222B);
}
