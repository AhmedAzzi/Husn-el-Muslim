import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/features/asmaa_allah/presentation/asmaa_allah_screen.dart';
import 'package:small_husn_muslim/features/dua/presentation/dua_screen.dart';
import 'package:small_husn_muslim/features/ruqyah/presentation/ruqyah_screen.dart';
import 'package:small_husn_muslim/features/masbaha/presentation/custom_dikr_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/mosque_map_screen.dart';
import 'package:small_husn_muslim/features/qibla/presentation/qibla_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/tracking_home_screen.dart';
import 'package:small_husn_muslim/features/quran/presentation/screens/home_screen.dart'
    as quran_home;
import 'package:small_husn_muslim/features/nakhtem/presentation/screens/khatma_home_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/features/settings/presentation/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Size screenSize = MediaQuery.of(context).size;
    return Drawer(
      width: screenSize.width - 100,
      child: ListView(
        shrinkWrap: true,
        children: [
          DrawerHeader(
            child: Center(child: Image(image: AssetImage(icLauncher))),
          ),
          ListTile(
            leading: const Icon(Icons.list_rounded),
            title: Text(
              loc.navAdhkar,
              style: TextStyle(
                fontSize: double.parse(fontSize18),
                fontFamily: fontFamily,
              ),
              textAlign: TextAlign.justify,
            ),
            onTap: () => Get.back(),
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.auto_stories_rounded),
            title: Text(loc.navDua, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const DuaScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.all_inclusive_rounded),
            title: Text(loc.navNames, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const AsmaaAllahScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.health_and_safety_rounded),
            title: Text(loc.navRuqyah, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const RuqyahScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.bubble_chart),
            title: Text(loc.navMasbaha, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const CustomDikrScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.access_time_filled_rounded),
            title:
                Text(loc.navPrayerTimes, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const PrayerTimesScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.map_rounded),
            title:
                Text(loc.navMosqueMap, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const MosqueMapScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.explore_rounded),
            title: Text(loc.navQibla, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const QiblaScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.local_fire_department_rounded),
            title: Text(loc.navTracking, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const TrackingHomeScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.auto_stories_rounded),
            title: Text(loc.navMushaf, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const quran_home.HomeScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(loc.navKhatma, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const KhatmaHomeScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(loc.navSettings, style: const TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const SettingsScreen());
            },
          ),
          const Divider(thickness: 0.3),
        ],
      ),
    );
  }
}
