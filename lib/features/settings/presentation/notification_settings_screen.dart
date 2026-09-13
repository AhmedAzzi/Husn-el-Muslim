import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/l10n/l10n.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';
import 'package:small_husn_muslim/features/nakhtem/presentation/controllers/nakhtem_controller.dart';
import 'package:small_husn_muslim/features/nakhtem/presentation/controllers/nakhtem_settings_controller.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_reminder_service.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';
import 'package:small_husn_muslim/core/widgets/app_feedback.dart';
import 'package:small_husn_muslim/core/widgets/app_sheets.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/features/settings/presentation/fajr_wakeup_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/extra_alarms_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/adhkar_reminders_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/quran_settings_screen.dart';
import 'package:small_husn_muslim/core/services/battery_optimization_helper.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
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
  final DhikrReminderHelper _reminderHelper = DhikrReminderHelper();
  bool _isBatteryOptimizationEnabled = false;
  bool _isCheckingBattery = true;
  bool _isDndGranted = false;
  bool _floatingEnabled = false;
  int _floatingInterval = 15;
  bool _trackingReminders = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBatteryOptimization();
    _checkDndPermission();
  }

  Future<void> _loadSettings() async {
    await _logic.loadNotificationPreference();
    bool tracking = false;
    try {
      tracking = await PrayerTrackingRepository.instance.remindersEnabled();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _floatingEnabled = _reminderHelper.isEnabled;
      _floatingInterval = _reminderHelper.intervalMinutes;
      _trackingReminders = tracking;
    });
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
      {bool? globalValue,
      Map<String, bool>? prayerValuesMap,
      bool? soundValue,
      bool? persistentValue,
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
      globalValue ?? _logic.notificationsEnabled,
      prayerValuesMap ?? _logic.prayerNotificationsEnabled,
      soundValue ?? _logic.notificationSoundEnabled,
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

  String _othersStatus(AppLocalizations loc) {
    final on = <String>[
      if (_floatingEnabled) loc.stFloatingDhikr,
      if (_trackingReminders) loc.ptRemindToggle,
    ];
    if (Get.isRegistered<NakhtemSettingsController>()) {
      try {
        final k = Get.find<NakhtemSettingsController>().settings.value;
        if (k.overlayEnabled) on.add(loc.diagOverlayTitle);
        if (k.showDailySummary) on.add(loc.stQuran);
      } catch (_) {}
    }
    if (on.isEmpty) return loc.sheetEnabledOff;
    if (on.length <= 2) return on.join(' • ');
    return '${on.take(2).join(' • ')} • +${on.length - 2}';
  }

  Future<void> _toggleFloating(bool value) async {
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
    await _reminderHelper.updateSettings(value, _floatingInterval);
    if (mounted) setState(() => _floatingEnabled = value);
  }

  Future<void> _setFloatingInterval(int value) async {
    await _reminderHelper.updateSettings(_floatingEnabled, value);
    if (mounted) setState(() => _floatingInterval = value);
  }

  void _showIntervalPicker() {
    final loc = AppLocalizations.of(context)!;
    const intervals = [1, 2, 3, 5, 10, 15, 30, 60];
    AppSheets.show(
      context,
      title: loc.stIntervalTitle,
      subtitle: loc.stIntervalSub,
      child: AppSheets.chipGroup<int>(
        context: context,
        values: intervals,
        selected: _floatingInterval,
        labelOf: (mins) =>
            mins >= 60 ? loc.stEveryHour : loc.stEveryMinutes(mins),
        onSelected: (mins) {
          Get.back();
          _setFloatingInterval(mins);
        },
      ),
    );
  }

  Future<void> _toggleTrackingReminders(bool value) async {
    await PrayerTrackingRepository.instance.setReminders(value);
    try {
      if (value) {
        await PrayerReminderService.instance.refreshFromCache();
      } else {
        await PrayerReminderService.instance.cancelAll();
      }
    } catch (_) {}
    if (mounted) setState(() => _trackingReminders = value);
  }

  Future<void> _setQuranOverlay(bool value) async {
    if (!Get.isRegistered<NakhtemSettingsController>()) return;
    final ctl = Get.find<NakhtemSettingsController>();
    await ctl.setOverlayEnabled(value);
    try {
      await Get.find<NakhtemController>().syncOverlayCache();
    } catch (_) {}
    if (value && mounted) {
      bool granted = true;
      try {
        granted = await PrayerNotificationHelper.checkOverlayPermission();
      } catch (_) {}
      if (!granted) {
        await PrayerNotificationHelper.requestOverlayPermission();
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _setDailySummary(bool value) async {
    if (!Get.isRegistered<NakhtemSettingsController>()) return;
    await Get.find<NakhtemSettingsController>().setShowDailySummary(value);
    if (mounted) setState(() {});
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: HusnAppBar.back(title: loc.nsTitle),
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

                // Section 2: Wake-up challenge — quick toggle + details.
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.sheetTitle,
                  icon: Icons.alarm_rounded,
                  color: const Color(0xFFD64463),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsFajrEnable,
                      subtitle: loc.nsFajrEnableSub,
                      icon: Icons.alarm_on_rounded,
                      iconColor: const Color(0xFFD64463),
                      value: _logic.fajrChallengeEnabled,
                      onChanged: (value) {
                        setState(() => _logic.fajrChallengeEnabled = value);
                        _saveSettings(fajrChallengeValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.sheetTitle,
                      subtitle: _fajrStatus(loc),
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFFD64463),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () =>
                          _openSub(const FajrWakeupSettingsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 3: Extra prayer alarms — individual toggles.
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.nsExtraAlarms,
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFF0EA5E9),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsSuhoor,
                      subtitle: loc.nsSuhoorSub,
                      icon: Icons.restaurant_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      value: _logic.suhoorAlarmEnabled,
                      onChanged: (value) {
                        setState(() => _logic.suhoorAlarmEnabled = value);
                        _saveSettings(suhoorValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsPreFajr,
                      subtitle: loc.nsPreFajrSub,
                      icon: Icons.alarm_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      value: _logic.preFajrAlarmEnabled,
                      onChanged: (value) {
                        setState(() => _logic.preFajrAlarmEnabled = value);
                        _saveSettings(preFajrValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsTahajjud,
                      subtitle: loc.nsTahajjudSub,
                      icon: Icons.nightlight_round,
                      iconColor: const Color(0xFF14B8A6),
                      value: _logic.tahajjudEnabled,
                      onChanged: (value) {
                        setState(() => _logic.tahajjudEnabled = value);
                        _saveSettings(tahajjudValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsFajrExtra,
                      subtitle: loc.nsFajrExtraSub,
                      icon: Icons.snooze_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      value: _logic.fajrExtra1Enabled ||
                          _logic.fajrExtra2Enabled,
                      onChanged: (value) {
                        setState(() {
                          _logic.fajrExtra1Enabled = value;
                          if (!value) _logic.fajrExtra2Enabled = false;
                        });
                        _saveSettings(
                          fajrExtra1Value: value,
                          fajrExtra2Value:
                              value ? _logic.fajrExtra2Enabled : false,
                        );
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsBedtime,
                      subtitle: loc.nsBedtimeSub,
                      icon: Icons.bedtime_rounded,
                      iconColor: const Color(0xFF6366F1),
                      value: _logic.bedtimeAlarmEnabled,
                      onChanged: (value) {
                        setState(() => _logic.bedtimeAlarmEnabled = value);
                        _saveSettings(bedtimeValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsPrePrayer,
                      subtitle: loc.nsPrePrayerSub,
                      icon: Icons.notification_important_outlined,
                      iconColor: const Color(0xFF10B981),
                      value: _logic.prePrayerEnabled,
                      onChanged: (value) {
                        setState(() => _logic.prePrayerEnabled = value);
                        _saveSettings(prePrayerValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsPostPrayer,
                      subtitle: loc.nsPostPrayerSub,
                      icon: Icons.done_all_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      value: _logic.postPrayerEnabled,
                      onChanged: (value) {
                        setState(() => _logic.postPrayerEnabled = value);
                        _saveSettings(postPrayerValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.nsExtraAlarms,
                      subtitle: _extraStatus(loc),
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () =>
                          _openSub(const ExtraAlarmsSettingsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 4: Adhkar reminders — individual toggles.
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.nsAdhkarSection,
                  icon: Icons.wb_twilight_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsMorning,
                      subtitle: loc.nsMorningSub,
                      icon: Icons.wb_sunny_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      value: _logic.morningAdhkarEnabled,
                      onChanged: (value) {
                        setState(() => _logic.morningAdhkarEnabled = value);
                        _saveSettings(morningAdhkarValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsEvening,
                      subtitle: loc.nsEveningSub,
                      icon: Icons.nights_stay_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      value: _logic.eveningAdhkarEnabled,
                      onChanged: (value) {
                        setState(() => _logic.eveningAdhkarEnabled = value);
                        _saveSettings(eveningAdhkarValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsWakeupAdhkar,
                      subtitle: loc.nsWakeupAdhkarSub,
                      icon: Icons.alarm_on_rounded,
                      iconColor: const Color(0xFF10B981),
                      value: _logic.wakeupAdhkarEnabled,
                      onChanged: (value) {
                        setState(() => _logic.wakeupAdhkarEnabled = value);
                        _saveSettings(wakeupAdhkarValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsSleepAdhkar,
                      subtitle: loc.nsSleepAdhkarSub,
                      icon: Icons.bedtime_outlined,
                      iconColor: const Color(0xFF6366F1),
                      value: _logic.sleepAdhkarEnabled,
                      onChanged: (value) {
                        setState(() => _logic.sleepAdhkarEnabled = value);
                        _saveSettings(sleepAdhkarValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.nsFridayKahf,
                      subtitle: loc.nsFridayKahfSub,
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      value: _logic.fridayKahfEnabled,
                      onChanged: (value) {
                        setState(() => _logic.fridayKahfEnabled = value);
                        _saveSettings(fridayKahfValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.stFloatingDhikr,
                      subtitle: loc.stFloatingDhikrSub,
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF10B981),
                      value: _floatingEnabled,
                      onChanged: _toggleFloating,
                    ),
                    if (_floatingEnabled) ...[
                      SettingsWidgets.buildDivider(context),
                      SettingsWidgets.buildValueTile(
                        context: context,
                        title: loc.stReminderRate,
                        subtitle: loc.stReminderRateSub,
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF10B981),
                        valueBadge: _floatingInterval >= 60
                            ? loc.stEveryHour
                            : loc.stEveryMinutes(_floatingInterval),
                        onTap: _showIntervalPicker,
                      ),
                    ],
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.nsAdhkarSection,
                      subtitle: _adhkarStatus(loc),
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () =>
                          _openSub(const AdhkarRemindersSettingsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 5: Tracking + Quran notifications.
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.navFajrLog,
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFD64463),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.ptRemindToggle,
                      subtitle: loc.ptRemindHint,
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFFD64463),
                      value: _trackingReminders,
                      onChanged: _toggleTrackingReminders,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.stQuran,
                  icon: Icons.auto_stories_outlined,
                  color: const Color(0xFFC9A227),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    if (Get.isRegistered<NakhtemSettingsController>())
                      Obx(() {
                        final k = Get.find<NakhtemSettingsController>()
                            .settings
                            .value;
                        final l = L10n.of(khatmaLang());
                        return Column(
                          children: [
                            SettingsWidgets.buildSwitchTile(
                              context: context,
                              title: l.t('phone_experience'),
                              subtitle: l.t('overlay_lock_hint'),
                              icon: Icons.layers_outlined,
                              iconColor: const Color(0xFFC9A227),
                              value: k.overlayEnabled,
                              onChanged: _setQuranOverlay,
                            ),
                            SettingsWidgets.buildDivider(context),
                            SettingsWidgets.buildSwitchTile(
                              context: context,
                              title: khatmaLang() == 'ar'
                                  ? 'ملخص يومي'
                                  : (khatmaLang() == 'fr'
                                      ? 'Résumé quotidien'
                                      : 'Daily summary'),
                              subtitle: khatmaLang() == 'ar'
                                  ? 'عرض ملخص القراءة مرة واحدة في اليوم'
                                  : (khatmaLang() == 'fr'
                                      ? 'Afficher le résumé de lecture une fois par jour'
                                      : 'Show the reading summary once a day'),
                              icon: Icons.summarize_outlined,
                              iconColor: const Color(0xFFC9A227),
                              value: k.showDailySummary,
                              onChanged: _setDailySummary,
                            ),
                            SettingsWidgets.buildDivider(context),
                          ],
                        );
                      }),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.stQuran,
                      subtitle: _othersStatus(loc),
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFFC9A227),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () => _openSub(const QuranSettingsScreen()),
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
