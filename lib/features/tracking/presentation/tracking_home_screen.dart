import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/features/tracking/presentation/prayer_tracking_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/sunnah_tracking_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/worship_tracking_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Unified tracking page: the 5-prayer tracker, the Sunnah tracker and the
/// fasting/wird tracker as three tabs under one themed AppBar.
///
/// The AppBar keeps the app background image to itself; the tabs live below
/// it as an icon-less segmented switcher with its own design. Each tab
/// embeds its screen's content (`embedded` — no nested Scaffold/AppBar).
/// Explicit RTL like every other screen; the tab content sits inside a
/// [SafeArea].
class TrackingHomeScreen extends StatefulWidget {
  /// Initially selected tab: 0 prayers, 1 sunan, 2 fasting & wird.
  final int initialTab;

  const TrackingHomeScreen({super.key, this.initialTab = 0});

  @override
  State<TrackingHomeScreen> createState() => _TrackingHomeScreenState();
}

class _TrackingHomeScreenState extends State<TrackingHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFFD64463);

  late final TabController _tabs;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _selected = _tabs.index;
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted || _selected == _tabs.index) return;
    setState(() => _selected = _tabs.index);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            foregroundColor: theme.appBarTheme.foregroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Get.back(),
            ),
            title: Text(
              loc.navTracking,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(appBarBG),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _tabsSwitcher(loc, isDark),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: const [
                      PrayerTrackingScreen(embedded: true),
                      SunnahTrackingScreen(embedded: true),
                      WorshipTrackingScreen(embedded: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Icon-less segmented tab switcher with its own pill design, separate
  /// from the AppBar background image above it.
  Widget _tabsSwitcher(AppLocalizations loc, bool isDark) {
    final labels = [loc.ptTrackerTitle, loc.navSunnah, loc.navWorship];
    const keys = ['tr_tab_prayers', 'tr_tab_sunnah', 'tr_tab_worship'];
    return Container(
      key: const ValueKey('tr_tabs'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final selected = _selected == i;
          return Expanded(
            child: GestureDetector(
              key: ValueKey(keys[i]),
              onTap: () => _tabs.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
