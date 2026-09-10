import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
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

  // Home screen options (localized at call time — const maps can't use loc)
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
    _showSnackBar(loc.stHomeSet);
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
      final hasPermission =
          await PrayerNotificationHelper.checkOverlayPermission();
      if (!hasPermission) {
        if (!mounted) return;
        final bool? proceed = await _showOverlayPermissionDialog();
        if (proceed != true) return;
      }
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
  Future<bool?> _showOverlayPermissionDialog() {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Get.dialog<bool>(
      AlertDialog(
          backgroundColor: isDark ? const Color(0xFF23232E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.layers_rounded,
                  color: Color(0xFFD64463), size: 28),
              const SizedBox(width: 10),
              Text(
                loc.stOverlayTitle,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            loc.stOverlayBody,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(
                loc.sheetLater,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64463),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                PrayerNotificationHelper.requestOverlayPermission();
                Get.back(result: true);
              },
              child: Text(
                loc.stActivateNow,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
    );
  }
  void _showHomeScreenPicker() {
    final loc = AppLocalizations.of(context)!;
    _showCustomBottomSheet(
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
    _showCustomBottomSheet(
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
    _showCustomBottomSheet(
      title: loc.stIntervalTitle,
      subtitle: loc.stIntervalSub,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: intervals.map((mins) {
          final isSelected = _reminderInterval == mins;
          return ChoiceChip(
            label: Text(
              mins >= 60 ? loc.stEveryHour : loc.stEveryMinutes(mins),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : null,
                fontSize: 15,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFFD64463),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2C2C38)
                : Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFD64463)
                    : Colors.transparent,
              ),
            ),
            onSelected: (selected) {
              if (selected) {
                Get.back();
                _setReminderInterval(mins);
              }
            },
          );
        }).toList(),
      ),
    );
  }
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 15),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- Dialogs & Bottom Sheets ---
  void _showCustomBottomSheet({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E28) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              // Options scroll when taller than the sheet allows (e.g. the
              // 11-item calculation-method list on small screens).
              Flexible(
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
);
    }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
          backgroundColor:
              isDark ? const Color(0xFF14141C) : const Color(0xFFF7F7FA),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Get.back(),
            ),
            title: Text(
              loc.stAppearance,
              style: TextStyle(
                fontFamily: 'Amiri',
                color: isDark ? Colors.white : Colors.black87,
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
                  opacity: isDark ? 0.35 : 0.15,
                ),
              ),
            ),
          ),
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
