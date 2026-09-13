import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';
import 'package:small_husn_muslim/core/widgets/app_feedback.dart';
import 'package:small_husn_muslim/core/widgets/app_sheets.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final DhikrReminderHelper _reminderHelper = DhikrReminderHelper();

  bool _clickSoundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = true;
  String _selectedHomeScreen = 'azkar';
  String _appLanguage = 'ar';

  bool _reminderEnabled = false;
  int _reminderInterval = 15;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = SharedPrefsCache.instance;
    if (!mounted) return;
    setState(() {
      _clickSoundEnabled = prefs.getBool('click_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode') ?? true;
      _selectedHomeScreen = prefs.getString('home_screen') ?? 'azkar';
      _appLanguage = prefs.getString('app_language') ?? 'ar';
      _reminderEnabled = _reminderHelper.isEnabled;
      _reminderInterval = _reminderHelper.intervalMinutes;
    });
  }

  // Home screen options: every main page (settings excluded — opening
  // the app straight into settings is never useful). Localized at call
  // time — const maps can't use loc. Keys match `fromHomeScreenKey`.
  static Map<String, ({String title, String subtitle, IconData icon})>
      homeScreenMeta(AppLocalizations loc) => {
    'azkar': (
      title: loc.navAdhkar,
      subtitle: loc.stHomeAzkarSub,
      icon: Icons.menu_book_rounded,
    ),
    'misbaha': (
      title: loc.navMasbaha,
      subtitle: loc.stHomeMisbahaSub,
      icon: Icons.touch_app_rounded,
    ),
    'prayer_times': (
      title: loc.navPrayerTimes,
      subtitle: loc.stHomePrayerSub,
      icon: Icons.access_time_filled_rounded,
    ),
    'quran': (
      title: loc.navMushaf,
      subtitle: loc.stHomeQuranSub,
      icon: Icons.auto_stories_rounded,
    ),
    'khatma': (
      title: loc.navKhatma,
      subtitle: loc.stHomeKhatmaSub,
      icon: Icons.menu_book_outlined,
    ),
    'qibla': (
      title: loc.navQibla,
      subtitle: loc.stHomeQiblaSub,
      icon: Icons.explore_rounded,
    ),
    'dua': (
      title: loc.navDua,
      subtitle: loc.stHomeDuaSub,
      icon: Icons.favorite_rounded,
    ),
    'names': (
      title: loc.navNames,
      subtitle: loc.stHomeNamesSub,
      icon: Icons.all_inclusive_rounded,
    ),
    'ruqyah': (
      title: loc.navRuqyah,
      subtitle: loc.stHomeRuqyahSub,
      icon: Icons.health_and_safety_rounded,
    ),
    'mosque_map': (
      title: loc.navMosqueMap,
      subtitle: loc.stHomeMosqueMapSub,
      icon: Icons.map_rounded,
    ),
    'tracking': (
      title: loc.navTracking,
      subtitle: loc.stHomeTrackingSub,
      icon: Icons.local_fire_department_rounded,
    ),
  };

  // Calculation method details (localized at call time)
  Future<void> _toggleClickSound(bool value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setBool('click_sound_enabled', value);
    setState(() {
      _clickSoundEnabled = value;
    });
  }

  Future<void> _toggleVibration(bool value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setBool('vibration_enabled', value);
    setState(() {
      _vibrationEnabled = value;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setBool('dark_mode', value);
    setState(() {
      _darkModeEnabled = value;
    });
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }
  Future<void> _setHomeScreen(String value) async {
    final loc = AppLocalizations.of(context)!;
    final prefs = SharedPrefsCache.instance;
    await prefs.setString('home_screen', value);
    setState(() {
      _selectedHomeScreen = value;
    });
    snack(loc.stHomeSet);
  }

  Future<void> _setLanguage(String value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setString('app_language', value);
    setState(() {
      _appLanguage = value;
    });
    Get.updateLocale(Locale(value));
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final loc = AppLocalizations.of(context)!;
      if (!mounted) return;
      final proceed = await OverlayGate.ensure(
        context,
        title: loc.stOverlayTitle,
        body: loc.stOverlayBody,
        laterLabel: loc.sheetLater,
        activateLabel: loc.stActivateNow,
      );
      if (!proceed) return;
    }

    await _reminderHelper.updateSettings(value, _reminderInterval);
    setState(() {
      _reminderEnabled = value;
    });
  }

  Future<void> _setReminderInterval(int value) async {
    await _reminderHelper.updateSettings(_reminderEnabled, value);
    setState(() {
      _reminderInterval = value;
    });
  }
  void _showHomeScreenPicker() {
    final loc = AppLocalizations.of(context)!;
    AppSheets.show(
      context,
      title: loc.stHomePicker,
      subtitle: loc.stHomePickerSub,
      child: Column(
        children: homeScreenMeta(AppLocalizations.of(context)!).entries.map((entry) {
          final isSelected = _selectedHomeScreen == entry.key;
          return SettingsWidgets.buildPickerOption(
            context: context,
            title: entry.value.title,
            subtitle: entry.value.subtitle,
            icon: entry.value.icon,
            isSelected: isSelected,
            onTap: () {
              Get.back();
              _setHomeScreen(entry.key);
            },
          );
        }).toList(),
      ),
    );
  }
  void _showLanguagePicker() {
    final loc = AppLocalizations.of(context)!;
    final langs = [
      ('ar', loc.langArabic, loc.stLangArSub, Icons.language_rounded),
      ('en', loc.langEnglish, loc.stLangEnSub, Icons.language_outlined),
      ('fr', loc.langFrench, loc.stLangFrSub, Icons.translate_rounded),
    ];
    AppSheets.show(
      context,
      title: loc.stLanguagePicker,
      subtitle: loc.stLanguagePickerSub,
      child: Column(
        children: langs.map((l) {
          final isSelected = _appLanguage == l.$1;
          return SettingsWidgets.buildPickerOption(
            context: context,
            title: l.$2,
            subtitle: l.$3,
            icon: l.$4,
            isSelected: isSelected,
            onTap: () {
              Get.back();
              _setLanguage(l.$1);
            },
          );
        }).toList(),
      ),
    );
  }
  void _showIntervalPicker() {
    final loc = AppLocalizations.of(context)!;
    final intervals = [1, 2, 3, 5, 10, 15, 30, 60];
    AppSheets.show(
      context,
      title: loc.stIntervalTitle,
      subtitle: loc.stIntervalSub,
      child: AppSheets.chipGroup<int>(
        context: context,
        values: intervals,
        selected: _reminderInterval,
        labelOf: (mins) =>
            mins >= 60 ? loc.stEveryHour : loc.stEveryMinutes(mins),
        onSelected: (mins) {
          Get.back();
          _setReminderInterval(mins);
        },
      ),
    );
  }
  // --- Dialogs & Bottom Sheets ---
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final homeScreenTitle =
        homeScreenMeta(loc)[_selectedHomeScreen]?.title ?? loc.navAdhkar;
    final languageTitle = switch (_appLanguage) {
      'en' => loc.langEnglish,
      'fr' => loc.langFrench,
      _ => loc.langArabic,
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: HusnAppBar.back(title: loc.stAppearance),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Appearance & General
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.stAppearance,
                  icon: Icons.palette_outlined,
                  color: const Color(0xFF8B5CF6),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.stDarkMode,
                      subtitle: _darkModeEnabled
                          ? loc.stDarkOn
                          : loc.stDarkOff,
                      icon: _darkModeEnabled
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      value: _darkModeEnabled,
                      onChanged: _toggleDarkMode,
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildValueTile(
                      context: context,
                      title: loc.stDefaultHome,
                      subtitle: loc.stDefaultHomeSub,
                      icon: Icons.home_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      valueBadge: homeScreenTitle,
                      onTap: _showHomeScreenPicker,
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildValueTile(
                      context: context,
                      title: loc.stLanguageTitle,
                      subtitle: loc.settingsLanguageSubtitle,
                      icon: Icons.translate_rounded,
                      iconColor: const Color(0xFF10B981),
                      valueBadge: languageTitle,
                      onTap: _showLanguagePicker,
                    ),
                  ],
                ), // Section 2: Interaction & Misbaha
                const SizedBox(height: 20),
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.stInteraction,
                  icon: Icons.touch_app_outlined,
                  color: const Color(0xFFEC4899),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.stClickSound,
                      subtitle: loc.stClickSoundSub,
                      icon: Icons.volume_up_rounded,
                      iconColor: const Color(0xFFEC4899),
                      value: _clickSoundEnabled,
                      onChanged: _toggleClickSound,
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.stHaptic,
                      subtitle: loc.stHapticSub,
                      icon: Icons.vibration_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      value: _vibrationEnabled,
                      onChanged: _toggleVibration,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Section 3: Periodic Dhikr Reminders (Overlay)
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.stReminder,
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFF10B981),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.stFloatingDhikr,
                      subtitle: loc.stFloatingDhikrSub,
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF10B981),
                      value: _reminderEnabled,
                      onChanged: _toggleReminder,
                    ),
                    if (_reminderEnabled) ...[
                      SettingsWidgets.buildDivider(context),
                      SettingsWidgets.buildValueTile(
                        context: context,
                        title: loc.stReminderRate,
                        subtitle: loc.stReminderRateSub,
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF10B981),
                        valueBadge: _reminderInterval >= 60
                            ? loc.stEveryHour
                            : loc.stEveryMinutes(_reminderInterval),
                        onTap: _showIntervalPicker,
                      ),
                    ],
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
