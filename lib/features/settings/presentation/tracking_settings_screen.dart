import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/navigation/main_nav_helper.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
import 'package:small_husn_muslim/features/tracking/presentation/tracking_settings_section.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class TrackingSettingsScreen extends StatelessWidget {
  const TrackingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: HusnAppBar.back(
            title: loc.navFajrLog,
            actions: [
              IconButton(
                tooltip: loc.nsOpenLog,
                icon: const Icon(Icons.visibility_outlined),
                onPressed: () {
                  // Tracking log is a main section: switch the shell instead
                  // of pushing a duplicate route.
                  if (MainNavHelper.isShellReady) {
                    MainNavHelper.goToTracking();
                  } else {
                    Get.back();
                  }
                },
              ),
            ],
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrackingSettingsSection(),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
