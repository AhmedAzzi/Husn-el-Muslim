import 'package:flutter/material.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Top-level destinations of the app — every entry in the navigation drawer.
///
/// The drawer is the primary way to move between these sections. [adhkar] is
/// the default home section (page index 0).
enum MainDestination {
  adhkar,
  quran,
  khatma,
  mawaqit,
  qibla,
  tasbih,
  settings,
  dua,
  names,
  ruqyah,
  mosqueMap,
  tracking,
}

extension MainDestinationX on MainDestination {
  /// Index into the [MainShell] IndexedStack.
  int get pageIndex => switch (this) {
        MainDestination.adhkar => 0,
        MainDestination.quran => 1,
        MainDestination.khatma => 2,
        MainDestination.mawaqit => 3,
        MainDestination.qibla => 4,
        MainDestination.tasbih => 5,
        MainDestination.settings => 6,
        MainDestination.dua => 7,
        MainDestination.names => 8,
        MainDestination.ruqyah => 9,
        MainDestination.mosqueMap => 10,
        MainDestination.tracking => 11,
      };

  /// Default destination for a page index (used when only the page is known).
  static MainDestination fromPageIndex(int page) => switch (page) {
        1 => MainDestination.quran,
        2 => MainDestination.khatma,
        3 => MainDestination.mawaqit,
        4 => MainDestination.qibla,
        5 => MainDestination.tasbih,
        6 => MainDestination.settings,
        7 => MainDestination.dua,
        8 => MainDestination.names,
        9 => MainDestination.ruqyah,
        10 => MainDestination.mosqueMap,
        11 => MainDestination.tracking,
        _ => MainDestination.adhkar,
      };

  /// Maps the persisted `home_screen` preference (see `app_config.dart`)
  /// to a drawer destination. Unknown keys fall back to adhkar.
  static MainDestination fromHomeScreenKey(String key) => switch (key) {
        'misbaha' => MainDestination.tasbih,
        'prayer_times' => MainDestination.mawaqit,
        'quran' => MainDestination.quran,
        'khatma' => MainDestination.khatma,
        'qibla' => MainDestination.qibla,
        'dua' => MainDestination.dua,
        'names' => MainDestination.names,
        'ruqyah' => MainDestination.ruqyah,
        'mosque_map' => MainDestination.mosqueMap,
        'tracking' => MainDestination.tracking,
        _ => MainDestination.adhkar,
      };

  IconData get icon => switch (this) {
        MainDestination.adhkar => Icons.list_rounded,
        MainDestination.quran => Icons.auto_stories_rounded,
        MainDestination.khatma => Icons.menu_book_rounded,
        MainDestination.mawaqit => Icons.access_time_filled_rounded,
        MainDestination.qibla => Icons.explore_rounded,
        MainDestination.tasbih => Icons.bubble_chart_rounded,
        MainDestination.settings => Icons.settings,
        MainDestination.dua => Icons.auto_stories_rounded,
        MainDestination.names => Icons.all_inclusive_rounded,
        MainDestination.ruqyah => Icons.health_and_safety_rounded,
        MainDestination.mosqueMap => Icons.map_rounded,
        MainDestination.tracking => Icons.local_fire_department_rounded,
      };

  /// Arabic-first label via the existing localizations.
  String label(AppLocalizations loc) => switch (this) {
        MainDestination.quran => loc.navMushaf,
        MainDestination.khatma => loc.navKhatma,
        MainDestination.adhkar => loc.navAdhkar,
        MainDestination.mawaqit => loc.navPrayerTimes,
        MainDestination.qibla => loc.navQibla,
        MainDestination.tasbih => loc.navMasbaha,
        MainDestination.settings => loc.navSettings,
        MainDestination.dua => loc.navDua,
        MainDestination.names => loc.navNames,
        MainDestination.ruqyah => loc.navRuqyah,
        MainDestination.mosqueMap => loc.navMosqueMap,
        MainDestination.tracking => loc.navTracking,
      };

  /// Stable key for tests and semantics.
  String get keyName => 'nav_$name';
}
