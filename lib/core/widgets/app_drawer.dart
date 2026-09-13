import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/navigation/main_destinations.dart';
import 'package:small_husn_muslim/core/navigation/main_nav_controller.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// The app's only navigation menu: every section is a main entry.
///
/// Visual design is the original drawer look (plain [DrawerHeader] with the
/// app icon, flat [ListTile] rows separated by thin dividers). Behavior:
/// tapping an entry switches the [MainShell] IndexedStack in place via
/// [MainNavController] — no route is ever pushed, so Back never walks between
/// sections and each visited section keeps its state. The active entry is
/// highlighted with the accent color.
///
/// When no shell controller is registered (standalone screen in tests or a
/// deep route), tapping an entry is a no-op after closing the drawer.
class AppDrawer extends StatelessWidget {
  /// All drawer destinations, in display order. The mosque map is intentionally
  /// excluded: it opens from the Mawaqit section (map button) and the prayer
  /// data settings, and stays a shell page so those jumps push no routes.
  static const List<MainDestination> mainEntries = [
    MainDestination.adhkar,
    MainDestination.quran,
    MainDestination.khatma,
    MainDestination.mawaqit,
    MainDestination.tasbih,
    MainDestination.dua,
    MainDestination.names,
    MainDestination.ruqyah,
    MainDestination.tracking,
    MainDestination.qibla,
    MainDestination.settings,
  ];

  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final Size screenSize = MediaQuery.of(context).size;
    const accent = Color(0xFFD64463);

    return Drawer(
      width: screenSize.width - 150,
      child: Obx(() {
        final nav = Get.isRegistered<MainNavController>()
            ? Get.find<MainNavController>()
            : null;
        final active = nav?.destination.value;

        return ListView(
          shrinkWrap: true,
          children: [
            DrawerHeader(
              child: Center(
                child: Image(
                  image: AssetImage(icLauncher),
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mosque_rounded,
                    size: 56,
                  ),
                ),
              ),
            ),
            for (final dest in mainEntries) ...[
              Builder(builder: (_) {
                final selected = active == dest;
                final color = selected ? accent : null;
                return ListTile(
                  key: ValueKey(dest.keyName),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(dest.icon, color: color, size: 22),
                  title: Text(
                    dest.label(loc),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: fontFamily,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: color,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_rounded, color: accent, size: 18)
                      : null,
                  onTap: () {
                    // Close the drawer first for a smooth transition.
                    Navigator.of(context).pop();
                    nav?.goTo(dest);
                  },
                );
              }),
              const Divider(thickness: 0.3),
            ],
          ],
        );
      }),
    );
  }
}
