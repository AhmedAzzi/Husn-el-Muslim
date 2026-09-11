import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/utils/url_utils.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';
import 'package:small_husn_muslim/features/settings/presentation/general_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/quran_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/prayer_data_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/tracking_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/advanced_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/notification_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/fajr_wakeup_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/extra_alarms_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/adhkar_reminders_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/diagnostics_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/prayer_tracking_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PrayerTimesLogic _prayerLogic = PrayerTimesLogic();
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _appLanguage = 'ar';
  bool _showAdvanced = false;
  int _trackingGoal = 5;
  int _trackingStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = SharedPrefsCache.instance;
    await _prayerLogic.loadNotificationPreference();
    int goal = 5;
    int streak = 0;
    try {
      goal = await PrayerTrackingRepository.instance.dailyGoal();
      streak = await PrayerTrackingRepository.instance.currentStreak();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _appLanguage = prefs.getString('app_language') ?? 'ar';
      _showAdvanced = prefs.getBool('show_advanced') ?? false;
      _trackingGoal = goal;
      _trackingStreak = streak;
    });
  }

  void _openSub(Widget page) {
    Get.to(() => page)?.then((_) => _loadSettings());
  }

  String _wakeStatus(AppLocalizations loc) {
    if (!_prayerLogic.fajrChallengeEnabled) return loc.sheetEnabledOff;
    final t = switch (_prayerLogic.fajrChallengeType) {
      'math' => loc.nsTypeMath,
      'memory' => loc.nsTypeMemory,
      'shake' => loc.nsTypeShake,
      'random' => loc.nsTypeRandom,
      _ => loc.nsTypeQuestions,
    };
    return '${loc.sheetEnabledOn} • $t • ${loc.sheetQuestions(_prayerLogic.fajrChallengeQuestionsCount)}';
  }

  String? _fajrTime() {
    try {
      return _prayerLogic.prayerTimes
          ?.firstWhere((p) => p.name == 'Fajr')
          .time24h;
    } catch (_) {
      return null;
    }
  }

  String _prayerStatus(AppLocalizations loc) {
    final src = _prayerLogic.prayerTimeSource == PrayerTimeSource.mosque
        ? loc.stMosqueBadge
        : loc.stCalcBadge;
    return '$src • ${loc.stCoords(_prayerLogic.lat.toStringAsFixed(3), _prayerLogic.lon.toStringAsFixed(3))}';
  }

  List<({String title, String sub, IconData icon, Color color, VoidCallback open})>
      _searchEntries(AppLocalizations loc) => [
            (
              title: loc.sheetTitle,
              sub: loc.nsFajrEnableSub,
              icon: Icons.alarm_rounded,
              color: const Color(0xFFD64463),
              open: () => _openSub(const FajrWakeupSettingsScreen()),
            ),
            (
              title: loc.nsChallengeType,
              sub: loc.nsTypeMath,
              icon: Icons.calculate_rounded,
              color: const Color(0xFFD64463),
              open: () => _openSub(const FajrWakeupSettingsScreen()),
            ),
            (
              title: loc.nsExtraAlarms,
              sub: loc.nsSuhoorSub,
              icon: Icons.notifications_active_outlined,
              color: const Color(0xFF0EA5E9),
              open: () => _openSub(const ExtraAlarmsSettingsScreen()),
            ),
            (
              title: loc.nsSuhoor,
              sub: loc.nsSuhoorSub,
              icon: Icons.restaurant_rounded,
              color: const Color(0xFF0EA5E9),
              open: () => _openSub(const ExtraAlarmsSettingsScreen()),
            ),
            (
              title: loc.nsPreFajr,
              sub: loc.nsPreFajrSub,
              icon: Icons.alarm_rounded,
              color: const Color(0xFF8B5CF6),
              open: () => _openSub(const ExtraAlarmsSettingsScreen()),
            ),
            (
              title: loc.nsTahajjud,
              sub: loc.nsTahajjudSub,
              icon: Icons.nightlight_round,
              color: const Color(0xFF14B8A6),
              open: () => _openSub(const ExtraAlarmsSettingsScreen()),
            ),
            (
              title: loc.nsBedtime,
              sub: loc.nsBedtimeSub,
              icon: Icons.bedtime_rounded,
              color: const Color(0xFF6366F1),
              open: () => _openSub(const ExtraAlarmsSettingsScreen()),
            ),
            (
              title: loc.nsPrePrayer,
              sub: loc.nsPrePrayerSub,
              icon: Icons.notifications_outlined,
              color: const Color(0xFF0EA5E9),
              open: () => _openSub(const ExtraAlarmsSettingsScreen()),
            ),
            (
              title: loc.nsAdhkarSection,
              sub: loc.nsMorningSub,
              icon: Icons.wb_twilight_rounded,
              color: const Color(0xFFF59E0B),
              open: () => _openSub(const AdhkarRemindersSettingsScreen()),
            ),
            (
              title: loc.nsMorning,
              sub: loc.nsMorningSub,
              icon: Icons.wb_sunny_rounded,
              color: const Color(0xFFF59E0B),
              open: () => _openSub(const AdhkarRemindersSettingsScreen()),
            ),
            (
              title: loc.nsEvening,
              sub: loc.nsEveningSub,
              icon: Icons.nights_stay_rounded,
              color: const Color(0xFF8B5CF6),
              open: () => _openSub(const AdhkarRemindersSettingsScreen()),
            ),
            (
              title: loc.nsFridayKahf,
              sub: loc.nsFridayKahfSub,
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF0EA5E9),
              open: () => _openSub(const AdhkarRemindersSettingsScreen()),
            ),
            (
              title: loc.stPrayerData,
              sub: loc.stCalcMethodSub,
              icon: Icons.mosque_outlined,
              color: const Color(0xFFD64463),
              open: () => _openSub(const PrayerDataSettingsScreen()),
            ),
            (
              title: loc.stCalcMethod,
              sub: loc.stCalcMethodSub,
              icon: Icons.calculate_outlined,
              color: const Color(0xFFD64463),
              open: () => _openSub(const PrayerDataSettingsScreen()),
            ),
            (
              title: loc.stAsrMethod,
              sub: loc.stAsrMethodSub,
              icon: Icons.wb_twilight_rounded,
              color: const Color(0xFFD64463),
              open: () => _openSub(const PrayerDataSettingsScreen()),
            ),
            (
              title: loc.stManualTitle,
              sub: loc.stManualTileSub,
              icon: Icons.tune_rounded,
              color: const Color(0xFFD64463),
              open: () => _openSub(const PrayerDataSettingsScreen()),
            ),
            (
              title: loc.stHijriTitle,
              sub: loc.stHijriExact,
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFD64463),
              open: () => _openSub(const PrayerDataSettingsScreen()),
            ),
            (
              title: loc.navFajrLog,
              sub: loc.trackDays(_trackingStreak),
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFD64463),
              open: () => _openSub(const PrayerTrackingScreen()),
            ),
            (
              title: loc.stLanguageTitle,
              sub: loc.settingsLanguageSubtitle,
              icon: Icons.translate_rounded,
              color: const Color(0xFF10B981),
              open: () => _openSub(const GeneralSettingsScreen()),
            ),
            (
              title: loc.stDarkMode,
              sub: loc.stDarkOn,
              icon: Icons.dark_mode_rounded,
              color: const Color(0xFF8B5CF6),
              open: () => _openSub(const GeneralSettingsScreen()),
            ),
            (
              title: loc.stFloatingDhikr,
              sub: loc.stFloatingDhikrSub,
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF10B981),
              open: () => _openSub(const GeneralSettingsScreen()),
            ),
            (
              title: loc.stQuran,
              sub: loc.stQuranSub,
              icon: Icons.auto_stories_outlined,
              color: const Color(0xFFC9A227),
              open: () => _openSub(const QuranSettingsScreen()),
            ),
            (
              title: loc.navMushaf,
              sub: loc.stQuranSub,
              icon: Icons.menu_book_outlined,
              color: const Color(0xFFC9A227),
              open: () => _openSub(const QuranSettingsScreen()),
            ),
            (
              title: loc.navKhatma,
              sub: loc.stQuranSub,
              icon: Icons.menu_book_rounded,
              color: const Color(0xFFC9A227),
              open: () => _openSub(const QuranSettingsScreen()),
            ),
            (
              title: loc.stDiagTile,
              sub: loc.stDiagTileSub,
              icon: Icons.bug_report_outlined,
              color: const Color(0xFF64748B),
              open: () => _openSub(const DiagnosticsScreen()),
            ),
            (
              title: loc.stAdvancedMode,
              sub: loc.stAdvancedModeSub,
              icon: Icons.tune_rounded,
              color: const Color(0xFF8B5CF6),
              open: () => _openSub(const AdvancedSettingsScreen()),
            ),
            (
              title: loc.nsDndTitle,
              sub: loc.nsDndSub,
              icon: Icons.do_not_disturb_on_rounded,
              color: const Color(0xFFEF4444),
              open: () => _openSub(const NotificationSettingsScreen()),
            ),
            (
              title: loc.nsPersistent,
              sub: loc.nsPersistentSub,
              icon: Icons.push_pin_outlined,
              color: const Color(0xFF3B82F6),
              open: () => _openSub(const NotificationSettingsScreen()),
            ),
          ];

  void _showAboutSheet() {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E28) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(icLauncher, width: 64, height: 64),
            const SizedBox(height: 8),
            Text(
              loc.appTitle,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              loc.stAboutSheetLine('v1.4.0'),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD64463).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD64463).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  do3aa,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildAboutTile(
                icon: SimpleIcons.google,
                title: offielWebSite,
                subtitle: offielWebSiteIbnWahf,
                onTap: () => openURL(oficialWebSiteLink),
              ),
              const SizedBox(height: 8),
              _buildAboutTile(
                icon: SimpleIcons.github,
                title: sourceCode,
                subtitle: loc.stGithubSheetSub,
                onTap: () => openURL(githubLink),
              ),
            ],
          ),
        ),
      isScrollControlled: true,
    );
  }

  Widget _buildAboutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282836) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFFD64463)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 18, color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations loc, bool isDark) {
    final on = _prayerLogic.fajrChallengeEnabled;
    final time = _fajrTime();
    final sub = on && time != null
        ? '$time • ${_wakeStatus(loc)}'
        : _wakeStatus(loc);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openSub(const FajrWakeupSettingsScreen()),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: on
                  ? [const Color(0xFFD64463), const Color(0xFF8B5CF6)]
                  : [const Color(0xFF3A3A48), const Color(0xFF2A2A36)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.alarm_on_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.sheetTitle,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuRow({
    required AppLocalizations loc,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return SettingsWidgets.buildActionTile(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: color,
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.grey),
      onTap: () => _openSub(page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageTitle = switch (_appLanguage) {
      'en' => loc.langEnglish,
      'fr' => loc.langFrench,
      _ => loc.langArabic,
    };
    final q = _query.trim().toLowerCase();
    final allEntries = _searchEntries(loc);
    final matches = q.isEmpty
        ? null
        : allEntries
            .where((e) =>
                e.title.toLowerCase().contains(q) ||
                e.sub.toLowerCase().contains(q))
            .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF14141C) : const Color(0xFFF7F7FA),
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.appBarTheme.foregroundColor,
              ),
              onPressed: () => Get.back(),
            ),
            title: Text(
              loc.stSettingsTitle,
              style: TextStyle(
                fontFamily: 'Amiri',
                color: theme.appBarTheme.foregroundColor,
                fontSize: 24,
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
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
                  decoration: InputDecoration(
                    hintText: loc.stSearchHint,
                    hintStyle: const TextStyle(fontFamily: 'Amiri'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => _searchCtrl.clear(),
                          ),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF1E1E28) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: matches != null
                    ? ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: matches.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = matches[i];
                          return Material(
                            color: isDark
                                ? const Color(0xFF1E1E28)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: e.open,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: e.color
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Icon(e.icon,
                                            color: e.color, size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.title,
                                            style: TextStyle(
                                              fontFamily: 'Amiri',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            e.sub,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Amiri',
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildHero(loc, isDark),
                            const SizedBox(height: 20),
                            SettingsWidgets.buildCardContainer(
                              context: context,
                              children: [
                                _menuRow(
                                  loc: loc,
                                  title: loc.stPrayerData,
                                  subtitle: _prayerStatus(loc),
                                  icon: Icons.mosque_outlined,
                                  color: const Color(0xFFD64463),
                                  page:
                                      const PrayerDataSettingsScreen(),
                                ),
                                SettingsWidgets.buildDivider(context),
                                _menuRow(
                                  loc: loc,
                                  title: loc.stNotifHub,
                                  subtitle: _wakeStatus(loc),
                                  icon: Icons.alarm_on_outlined,
                                  color: const Color(0xFF06B6D4),
                                  page:
                                      const NotificationSettingsScreen(),
                                ),
                                SettingsWidgets.buildDivider(context),
                                _menuRow(
                                  loc: loc,
                                  title: loc.navFajrLog,
                                  subtitle:
                                      '🔥 ${loc.trackDays(_trackingStreak)} • $_trackingGoal/5',
                                  icon: Icons
                                      .local_fire_department_rounded,
                                  color: const Color(0xFFD64463),
                                  page:
                                      const TrackingSettingsScreen(),
                                ),
                                SettingsWidgets.buildDivider(context),
                                _menuRow(
                                  loc: loc,
                                  title: loc.stAppearance,
                                  subtitle: languageTitle,
                                  icon: Icons.palette_outlined,
                                  color: const Color(0xFF8B5CF6),
                                  page:
                                      const GeneralSettingsScreen(),
                                ),
                                SettingsWidgets.buildDivider(context),
                                _menuRow(
                                  loc: loc,
                                  title: loc.stQuran,
                                  subtitle: loc.stQuranSub,
                                  icon: Icons.auto_stories_outlined,
                                  color: const Color(0xFFC9A227),
                                  page:
                                      const QuranSettingsScreen(),
                                ),
                                SettingsWidgets.buildDivider(context),
                                _menuRow(
                                  loc: loc,
                                  title: loc.stAdvanced,
                                  subtitle: _showAdvanced
                                      ? loc.stAdvancedModeSub
                                      : loc.stHiddenAdvanced,
                                  icon: Icons.build_outlined,
                                  color: const Color(0xFF64748B),
                                  page:
                                      const AdvancedSettingsScreen(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                // Section 6: About & Community
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.stAbout,
                  icon: Icons.info_outline_rounded,
                  color: const Color(0xFF64748B),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.stAboutApp,
                      subtitle: loc.stAboutAppSub('v1.4.0'),
                      icon: Icons.info_rounded,
                      iconColor: const Color(0xFF64748B),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: _showAboutSheet,
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.stOfficialSite,
                      subtitle: loc.stOfficialSiteSub,
                      icon: SimpleIcons.google,
                      iconColor: const Color(0xFF4285F4),
                      trailing: const Icon(Icons.open_in_new_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () => openURL(oficialWebSiteLink),
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.stGithub,
                      subtitle: loc.stGithubSub,
                      icon: SimpleIcons.github,
                      iconColor: isDark ? Colors.white : Colors.black87,
                      trailing: const Icon(Icons.open_in_new_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () => openURL(githubLink),
                    ),
                  ],
                ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
