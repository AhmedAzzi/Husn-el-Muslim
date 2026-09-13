import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/settings/presentation/diagnostics_screen.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = SharedPrefsCache.instance;
    if (!mounted) return;
    setState(() {
      _showAdvanced = prefs.getBool('show_advanced') ?? false;
    });
  }

  Future<void> _setAdvanced(bool value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setBool('show_advanced', value);
    if (!mounted) return;
    setState(() => _showAdvanced = value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: HusnAppBar.back(title: loc.stAdvanced),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.stAdvancedMode,
                  icon: Icons.tune_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.stAdvancedMode,
                      subtitle: loc.stAdvancedModeSub,
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      value: _showAdvanced,
                      onChanged: _setAdvanced,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.stDiagTile,
                      subtitle: loc.stDiagTileSub,
                      icon: Icons.bug_report_outlined,
                      iconColor: const Color(0xFF64748B),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () =>
                          Get.to(() => const DiagnosticsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
