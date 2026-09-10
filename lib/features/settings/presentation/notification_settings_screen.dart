import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/features/settings/presentation/fajr_wakeup_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/extra_alarms_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/adhkar_reminders_settings_screen.dart';
import 'package:small_husn_muslim/core/services/battery_optimization_helper.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final PrayerTimesLogic _logic = PrayerTimesLogic();
  bool _isBatteryOptimizationEnabled = false;
  bool _isCheckingBattery = true;
  bool _isDndGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBatteryOptimization();
    _checkDndPermission();
  }

  Future<void> _loadSettings() async {
    await _logic.loadNotificationPreference();
    if (mounted) setState(() {});
  }

  Future<void> _checkDndPermission() async {
    final granted = await PrayerNotificationHelper.isDndAccessGranted();
    if (mounted) {
      setState(() => _isDndGranted = granted);
    }
  }

  Future<void> _checkBatteryOptimization() async {
    final isEnabled =
        await BatteryOptimizationHelper.isBatteryOptimizationEnabled();
    if (mounted) {
      setState(() {
        _isBatteryOptimizationEnabled = isEnabled;
        _isCheckingBattery = false;
      });
    }
  }

  Future<void> _saveSettings(
      {bool? persistentValue,
      bool? fajrChallengeValue,
      int? challengeQuestionsCount,
      bool? challengeIsTextInput,
      String? challengeWakeUpMode,
      int? challengeCustomOffset,
      String? challengeType,
      String? challengeDifficulty,
      List<String>? challengePool,
      String? shakeSensitivity,
      bool? wakeUpConfirmationValue,
      bool? morningAdhkarValue,
      bool? eveningAdhkarValue,
      bool? wakeupAdhkarValue,
      bool? sleepAdhkarValue,
      bool? fridayKahfValue,
      bool? dndDuringPrayerValue,
      int? dndDurationMinutesValue,
      bool? persistentBgValue,
      bool? nightPrayerTimesValue,
      int? notificationModeValue,
      bool? suhoorValue,
      int? suhoorOffset,
      bool? preFajrValue,
      int? preFajrOffset,
      bool? bedtimeValue,
      int? bedtimeH,
      int? bedtimeM,
      bool? bedtimeRelative,
      int? bedtimeRelHours,
      bool? tahajjudValue,
      String? tahajjudModeValue,
      int? tahajjudH,
      int? tahajjudM,
      bool? fajrExtra1Value,
      int? fajrExtra1Delay,
      bool? fajrExtra2Value,
      int? fajrExtra2Delay,
      bool? prePrayerValue,
      int? prePrayerOffset,
      Map<String, bool>? prePrayerMap,
      bool? postPrayerValue,
      int? postPrayerOffset,
      Map<String, bool>? postPrayerMap,
      String? alarmSoundValue,
      String? alarmCustomPathValue,
      int? alarmVolumeValue,
      bool? alarmVibrateValue,
      bool? alarmLoopValue,
      int? gentleWakeValue}) async {
    await _logic.saveNotificationPreference(
      _logic.notificationsEnabled,
      _logic.prayerNotificationsEnabled,
      _logic.notificationSoundEnabled,
      persistentValue: persistentValue ?? _logic.persistentNotificationEnabled,
      persistentBgValue:
          persistentBgValue ?? _logic.persistentNotificationBlackBg,
      fajrChallengeValue: fajrChallengeValue ?? _logic.fajrChallengeEnabled,
      challengeQuestionsCount:
          challengeQuestionsCount ?? _logic.fajrChallengeQuestionsCount,
      challengeIsTextInput:
          challengeIsTextInput ?? _logic.fajrChallengeIsTextInput,
      challengeWakeUpMode:
          challengeWakeUpMode ?? _logic.fajrChallengeWakeUpMode,
      challengeCustomOffset:
          challengeCustomOffset ?? _logic.fajrChallengeCustomOffsetMinutes,
      challengeType: challengeType ?? _logic.fajrChallengeType,
      challengeDifficulty:
          challengeDifficulty ?? _logic.fajrChallengeDifficulty,
      challengePool: challengePool ?? _logic.fajrRandomPool,
      shakeSensitivity:
          shakeSensitivity ?? _logic.fajrShakeSensitivity,
      wakeUpConfirmationValue:
          wakeUpConfirmationValue ?? _logic.wakeUpConfirmationEnabled,
      morningAdhkarValue: morningAdhkarValue ?? _logic.morningAdhkarEnabled,
      eveningAdhkarValue: eveningAdhkarValue ?? _logic.eveningAdhkarEnabled,
      wakeupAdhkarValue: wakeupAdhkarValue ?? _logic.wakeupAdhkarEnabled,
      sleepAdhkarValue: sleepAdhkarValue ?? _logic.sleepAdhkarEnabled,
      fridayKahfValue: fridayKahfValue ?? _logic.fridayKahfEnabled,
      dndDuringPrayerValue:
          dndDuringPrayerValue ?? _logic.dndDuringPrayerEnabled,
      dndDurationMinutesValue:
          dndDurationMinutesValue ?? _logic.dndDurationMinutes,
      nightPrayerTimesValue:
          nightPrayerTimesValue ?? _logic.nightPrayerTimesEnabled,
      notificationModeValue: notificationModeValue ?? _logic.notificationMode,
      suhoorValue: suhoorValue ?? _logic.suhoorAlarmEnabled,
      suhoorOffset: suhoorOffset ?? _logic.suhoorOffsetMinutes,
      preFajrValue: preFajrValue ?? _logic.preFajrAlarmEnabled,
      preFajrOffset: preFajrOffset ?? _logic.preFajrOffsetMinutes,
      bedtimeValue: bedtimeValue ?? _logic.bedtimeAlarmEnabled,
      bedtimeH: bedtimeH ?? _logic.bedtimeHour,
      bedtimeM: bedtimeM ?? _logic.bedtimeMinute,
      bedtimeRelative: bedtimeRelative ?? _logic.bedtimeRelativeToFajr,
      bedtimeRelHours: bedtimeRelHours ?? _logic.bedtimeRelativeHours,
      tahajjudValue: tahajjudValue ?? _logic.tahajjudEnabled,
      tahajjudModeValue: tahajjudModeValue ?? _logic.tahajjudMode,
      tahajjudH: tahajjudH ?? _logic.tahajjudHour,
      tahajjudM: tahajjudM ?? _logic.tahajjudMinute,
      fajrExtra1Value: fajrExtra1Value ?? _logic.fajrExtra1Enabled,
      fajrExtra1Delay: fajrExtra1Delay ?? _logic.fajrExtra1Minutes,
      fajrExtra2Value: fajrExtra2Value ?? _logic.fajrExtra2Enabled,
      fajrExtra2Delay: fajrExtra2Delay ?? _logic.fajrExtra2Minutes,
      prePrayerValue: prePrayerValue ?? _logic.prePrayerEnabled,
      prePrayerOffset: prePrayerOffset ?? _logic.prePrayerOffsetMinutes,
      prePrayerMap: prePrayerMap ?? _logic.prePrayerPerPrayer,
      postPrayerValue: postPrayerValue ?? _logic.postPrayerEnabled,
      postPrayerOffset: postPrayerOffset ?? _logic.postPrayerOffsetMinutes,
      postPrayerMap: postPrayerMap ?? _logic.postPrayerPerPrayer,
      alarmSoundValue: alarmSoundValue ?? _logic.alarmSound,
      alarmCustomPathValue: alarmCustomPathValue ?? _logic.alarmCustomPath,
      alarmVolumeValue: alarmVolumeValue ?? _logic.alarmVolumePercent,
      alarmVibrateValue: alarmVibrateValue ?? _logic.alarmVibrate,
      alarmLoopValue: alarmLoopValue ?? _logic.alarmLoop,
      gentleWakeValue: gentleWakeValue ?? _logic.gentleWakeSeconds,
    );
    if (mounted) setState(() {});
  }

  String _fajrStatus(AppLocalizations loc) {
    if (!_logic.fajrChallengeEnabled) return loc.sheetEnabledOff;
    final t = switch (_logic.fajrChallengeType) {
      'math' => loc.nsTypeMath,
      'memory' => loc.nsTypeMemory,
      'shake' => loc.nsTypeShake,
      'random' => loc.nsTypeRandom,
      _ => loc.nsTypeQuestions,
    };
    return '${loc.sheetEnabledOn} • $t • ${loc.sheetQuestions(_logic.fajrChallengeQuestionsCount)}';
  }

  String _extraStatus(AppLocalizations loc) {
    final on = <String>[
      if (_logic.suhoorAlarmEnabled) loc.nsSuhoor,
      if (_logic.preFajrAlarmEnabled) loc.nsPreFajr,
      if (_logic.tahajjudEnabled) loc.nsTahajjud,
      if (_logic.fajrExtra1Enabled || _logic.fajrExtra2Enabled) loc.nsFajrExtra,
      if (_logic.bedtimeAlarmEnabled) loc.nsBedtime,
      if (_logic.prePrayerEnabled) loc.nsPrePrayer,
      if (_logic.postPrayerEnabled) loc.nsPostPrayer,
    ];
    if (on.isEmpty) return loc.sheetEnabledOff;
    if (on.length <= 2) return on.join(' • ');
    return '${on.take(2).join(' • ')} • +${on.length - 2}';
  }

  String _adhkarStatus(AppLocalizations loc) {
    final on = <String>[
      if (_logic.morningAdhkarEnabled) loc.nsMorning,
      if (_logic.eveningAdhkarEnabled) loc.nsEvening,
      if (_logic.wakeupAdhkarEnabled) loc.nsWakeupAdhkar,
      if (_logic.sleepAdhkarEnabled) loc.nsSleepAdhkar,
      if (_logic.fridayKahfEnabled) loc.nsFridayKahf,
    ];
    if (on.isEmpty) return loc.sheetEnabledOff;
    if (on.length <= 2) return on.join(' • ');
    return '${on.take(2).join(' • ')} • +${on.length - 2}';
  }

  void _openSub(Widget page) {
    Get.to(() => page)?.then((_) => _loadSettings());
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
              loc.nsTitle,
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
                // Battery Optimization Warning Banner
                if (!_isCheckingBattery && _isBatteryOptimizationEnabled)
                  _buildBatteryBanner(isDark, loc),

                // Section 1: Persistent Status Bar Notification
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.nsPersistentSection,
                  icon: Icons.push_pin_outlined,
                  color: const Color(0xFF3B82F6),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsPersistent,
                      subtitle: loc.nsPersistentSub,
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      value: _logic.persistentNotificationEnabled,
                      onChanged: (value) {
                        setState(() =>
                            _logic.persistentNotificationEnabled = value);
                        _saveSettings(persistentValue: value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.sheetTitle,
                      subtitle: _fajrStatus(loc),
                      icon: Icons.alarm_rounded,
                      iconColor: const Color(0xFFD64463),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () =>
                          _openSub(const FajrWakeupSettingsScreen()),
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.nsExtraAlarms,
                      subtitle: _extraStatus(loc),
                      icon: Icons.notifications_active_outlined,
                      iconColor: const Color(0xFF0EA5E9),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () =>
                          _openSub(const ExtraAlarmsSettingsScreen()),
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.nsAdhkarSection,
                      subtitle: _adhkarStatus(loc),
                      icon: Icons.wb_twilight_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () =>
                          _openSub(const AdhkarRemindersSettingsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 5: Do Not Disturb (DND) Automation
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.nsDndSection,
                  icon: Icons.do_not_disturb_on_rounded,
                  color: const Color(0xFFEF4444),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsDndTitle,
                      subtitle: loc.nsDndSub,
                      icon: Icons.do_not_disturb_on_rounded,
                      iconColor: const Color(0xFFEF4444),
                      value: _logic.dndDuringPrayerEnabled,
                      onChanged: (value) async {
                        setState(() => _logic.dndDuringPrayerEnabled = value);
                        _saveSettings(dndDuringPrayerValue: value);
                        if (value && !_isDndGranted) {
                          await _checkDndPermission();
                        }
                      },
                    ),
                    if (_logic.dndDuringPrayerEnabled) ...[
                      if (!_isDndGranted) ...[
                        SettingsWidgets.buildDivider(context),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Colors.amber, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        loc.nsDndPermNeeded,
                                        style: const TextStyle(
                                          fontFamily: 'Amiri',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await PrayerNotificationHelper
                                          .openDndSettings();
                                      await Future.delayed(
                                          const Duration(seconds: 2));
                                      await _checkDndPermission();
                                    },
                                    icon: const Icon(
                                        Icons.settings_suggest_rounded,
                                        size: 18),
                                    label: Text(
                                      loc.nsDndPermGrant,
                                      style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SettingsWidgets.buildDivider(context),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.nsDndDuration,
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                loc.nsDndMinutes(_logic.dndDurationMinutes),
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Slider(
                        value: _logic.dndDurationMinutes.toDouble(),
                        min: 10,
                        max: 60,
                        divisions: 10,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (v) => setState(
                            () => _logic.dndDurationMinutes = v.toInt()),
                        onChangeEnd: (v) => _saveSettings(
                            dndDurationMinutesValue: v.toInt()),
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

  Widget _buildBatteryBanner(bool isDark, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.amber, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.nsBatteryTitle,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    color: Colors.amber,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.nsBatteryBody,
            style: TextStyle(
              fontFamily: 'Amiri',
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await BatteryOptimizationHelper
                    .requestIgnoreBatteryOptimization();
                Future.delayed(const Duration(seconds: 2), () {
                  _checkBatteryOptimization();
                });
              },
              icon: const Icon(Icons.battery_saver_rounded, size: 18),
              label: Text(
                loc.nsBatteryButton,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
