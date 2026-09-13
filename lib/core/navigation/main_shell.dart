import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/navigation/main_destinations.dart';
import 'package:small_husn_muslim/core/navigation/main_nav_controller.dart';
import 'package:small_husn_muslim/features/asmaa_allah/presentation/asmaa_allah_screen.dart';
import 'package:small_husn_muslim/features/azkar/presentation/home_page.dart';
import 'package:small_husn_muslim/features/dua/presentation/dua_screen.dart';
import 'package:small_husn_muslim/features/masbaha/presentation/custom_dikr_screen.dart';
import 'package:small_husn_muslim/features/nakhtem/presentation/screens/khatma_home_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/mosque_map_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/features/qibla/presentation/qibla_screen.dart';
import 'package:small_husn_muslim/features/quran/presentation/screens/home_screen.dart'
    as quran_home;
import 'package:small_husn_muslim/features/ruqyah/presentation/ruqyah_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/settings_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/tracking_home_screen.dart';

/// Root of the app's main UI: a single route hosting every top-level section
/// in an [IndexedStack].
///
/// - Switching sections changes the stack index only: no route history is
///   created (Back never walks between main sections) and each visited
///   section keeps its state while mounted.
/// - Sections are built lazily on first visit ([MainNavController.visited]),
///   so heavy pages (map, compass sensors, book data) don't all initialize
///   at startup. Unvisited slots render an empty placeholder.
/// - Detail screens (Adhkar details, Mushaf reader, settings sub-pages, …)
///   are pushed with `Get.to` on top of the shell, so Back still works
///   *within* a section.
class MainShell extends StatefulWidget {
  final MainDestination initialDestination;

  const MainShell({
    super.key,
    this.initialDestination = MainDestination.adhkar,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final MainNavController _nav;

  static const _pages = [
    MyHomePageScreen(),
    quran_home.HomeScreen(),
    KhatmaHomeScreen(),
    PrayerTimesScreen(),
    QiblaScreen(),
    CustomDikrScreen(),
    SettingsScreen(),
    DuaScreen(),
    AsmaaAllahScreen(),
    RuqyahScreen(),
    MosqueMapScreen(),
    TrackingHomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<MainNavController>()) {
      _nav = Get.find<MainNavController>();
      _nav.goTo(widget.initialDestination);
    } else {
      _nav = Get.put(
        MainNavController(initial: widget.initialDestination),
        permanent: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Each child is a full Scaffold with its own AppBar (shared AppDrawer,
    // except drawer-less Settings and mosque map which offer a Prev button).
    // Visited pages stay alive, preserving scroll/counter/tab state.
    return Obx(
      () => IndexedStack(
        index: _nav.pageIndex,
        children: [
          for (var i = 0; i < _pages.length; i++)
            // Keyed by position so state stays attached to its section even
            // if a placeholder swaps for the real page on first visit.
            KeyedSubtree(
              key: ValueKey(i),
              child: _nav.visited.contains(i)
                  ? _pages[i]
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
