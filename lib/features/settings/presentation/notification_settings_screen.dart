import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/widgets/app_feedback.dart';
import 'package:small_husn_muslim/core/widgets/app_sheets.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
import 'package:small_husn_muslim/core/widgets/husn_number_dropdown.dart';
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
  bool _isDndGranted = false;
  bool _floatingEnabled = false;
  int _floatingInterval = 15;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkDndPermission();
  }

  Future<void> _loadSettings() async {
    await _logic.loadNotificationPreference();
    // Removed alarms (pre-Fajr, Suhoor, Tahajjud): make sure a
    // previously-enabled one can never keep ringing with no UI left
    // to switch it off. The Fajr challenge covers the wake-up.
    if (_logic.preFajrAlarmEnabled ||
        _logic.suhoorAlarmEnabled ||
        _logic.tahajjudEnabled) {
      await _saveSettings(
        preFajrValue: false,
        suhoorValue: false,
        tahajjudValue: false,
      );
    }
    if (!mounted) return;
    setState(() {
      _floatingEnabled = _reminderHelper.isEnabled;
      _floatingInterval = _reminderHelper.intervalMinutes;
    });
  }

  String _arabicPrayer(BuildContext context, String en) {
    final loc = AppLocalizations.of(context)!;
    return switch (en) {
      'Fajr' => loc.nsPrayerFajr,
      'Dhuhr' => loc.nsPrayerDhuhr,
      'Asr' => loc.nsPrayerAsr,
      'Maghrib' => loc.nsPrayerMaghrib,
      'Isha' => loc.nsPrayerIsha,
      _ => en,
    };
  }

  /// Periodic floating dhikr: lives only here, next to the other adhkar
  /// reminders.
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

  Future<void> _checkDndPermission() async {
    final granted = await PrayerNotificationHelper.isDndAccessGranted();
    if (mounted) {
      setState(() => _isDndGranted = granted);
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
      shakeSensitivity: shakeSensitivity ?? _logic.fajrShakeSensitivity,
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
                // Pinned system notifications: the persistent status-bar
                // notification plus the periodic floating dhikr.
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
                        setState(
                            () => _logic.persistentNotificationEnabled = value);
                        _saveSettings(persistentValue: value);
                      },
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: loc.stFloatingDhikr,
                      subtitle: loc.stFloatingDhikrSub,
                      icon: Icons.book,
                      iconColor: const Color(0xFF3B82F6),
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
                        iconColor: const Color(0xFF3B82F6),
                        valueBadge: _floatingInterval >= 60
                            ? loc.stEveryHour
                            : loc.stEveryMinutes(_floatingInterval),
                        onTap: _showIntervalPicker,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Extra prayer alarms — everything inline, no nested page.
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
                    // Bedtime mode cards: "relative to Fajr" or a fixed
                    // clock time. One tap picks the mode; the single
                    // control below edits it. No second switch.
                    if (_logic.bedtimeAlarmEnabled) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SettingsWidgets.buildChoiceCard(
                                context: context,
                                title: loc.nsBedtimeRelative,
                                subtitle: loc.nsBedtimeRelativeSub(
                                    _logic.bedtimeRelativeHours),
                                isSelected: _logic.bedtimeRelativeToFajr,
                                onTap: () {
                                  setState(() =>
                                      _logic.bedtimeRelativeToFajr = true);
                                  _saveSettings(bedtimeRelative: true);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SettingsWidgets.buildChoiceCard(
                                context: context,
                                title: loc.nsBedtimeFixed,
                                subtitle: TimeOfDay(
                                  hour: _logic.bedtimeHour,
                                  minute: _logic.bedtimeMinute,
                                ).format(context),
                                isSelected: !_logic.bedtimeRelativeToFajr,
                                onTap: () {
                                  setState(() =>
                                      _logic.bedtimeRelativeToFajr = false);
                                  _saveSettings(bedtimeRelative: false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Center(
                          child: _logic.bedtimeRelativeToFajr
                              // Hours-before-Fajr picker (4-12h).
                              ? HusnNumberDropdown(
                                  value: _logic.bedtimeRelativeHours
                                      .clamp(4, 12),
                                  options: const [
                                    4, 5, 6, 7, 8, 9, 10, 11, 12,
                                  ],
                                  accentColor: const Color(0xFF6366F1),
                                  icon: Icons.bedtime_outlined,
                                  labelOf: (v) =>
                                      loc.nsBedtimeRelativeSub(v),
                                  onChanged: (v) {
                                    setState(() =>
                                        _logic.bedtimeRelativeHours = v);
                                    _saveSettings(bedtimeRelHours: v);
                                  },
                                )
                              // Fixed clock time: standard time picker.
                              : OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: _logic.bedtimeHour,
                                        minute: _logic.bedtimeMinute,
                                      ),
                                    );
                                    if (picked == null) return;
                                    setState(() {
                                      _logic.bedtimeHour = picked.hour;
                                      _logic.bedtimeMinute = picked.minute;
                                    });
                                    await _saveSettings(
                                      bedtimeH: picked.hour,
                                      bedtimeM: picked.minute,
                                    );
                                  },
                                  icon: const Icon(
                                      Icons.schedule_rounded,
                                      size: 18),
                                  label: Text(
                                    TimeOfDay(
                                      hour: _logic.bedtimeHour,
                                      minute: _logic.bedtimeMinute,
                                    ).format(context),
                                    style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF6366F1),
                                    side: const BorderSide(
                                        color: Color(0xFF6366F1),
                                        width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                  ),
                                ),
                        ),
                      ),
                      // Quiet skip link instead of a full-width button.
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await _logic.skipBedtimeOnce();
                            if (!context.mounted) return;
                            setState(() {});
                            AppFeedback.snack(
                              context,
                              loc.nsSkippedTonight,
                              type: AppFeedbackType.warn,
                            );
                          },
                          icon: const Icon(Icons.skip_next_rounded, size: 16),
                          label: Text(loc.nsSkipTonight,
                              style:
                                  const TextStyle(fontFamily: 'Amiri')),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                        ),
                      ),
                    ],
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
                    if (_logic.prePrayerEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            HusnNumberPickerRow(
                              title: loc.nsBeforePrayerBy,
                              value: _logic.prePrayerOffsetMinutes,
                              options: const [
                                5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
                              ],
                              accentColor: const Color(0xFF10B981),
                              labelOf: (v) => loc.sheetMinutes(v),
                              onChanged: (v) {
                                setState(() =>
                                    _logic.prePrayerOffsetMinutes = v);
                                _saveSettings(prePrayerOffset: v);
                              },
                            ),
                            const SizedBox(height: 8),
                            HusnPrayerToggleRow(
                              prayers: PrayerTimesLogic.prePostPrayers,
                              accentColor: const Color(0xFF10B981),
                              labelOf: (p) => _arabicPrayer(context, p),
                              isSelected: (p) =>
                                  _logic.prePrayerPerPrayer[p] ?? true,
                              onToggle: (p, selected) {
                                final map = Map<String, bool>.of(
                                    _logic.prePrayerPerPrayer);
                                map[p] = selected;
                                setState(() =>
                                    _logic.prePrayerPerPrayer[p] = selected);
                                _saveSettings(prePrayerMap: map);
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
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
                    if (_logic.postPrayerEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            HusnNumberPickerRow(
                              title: loc.nsAfterPrayerBy,
                              value: _logic.postPrayerOffsetMinutes,
                              options: const [
                                5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
                              ],
                              accentColor: const Color(0xFFF59E0B),
                              labelOf: (v) => loc.sheetMinutes(v),
                              onChanged: (v) {
                                setState(() =>
                                    _logic.postPrayerOffsetMinutes = v);
                                _saveSettings(postPrayerOffset: v);
                              },
                            ),
                            const SizedBox(height: 8),
                            HusnPrayerToggleRow(
                              prayers: PrayerTimesLogic.prePostPrayers,
                              accentColor: const Color(0xFFF59E0B),
                              labelOf: (p) => _arabicPrayer(context, p),
                              isSelected: (p) =>
                                  _logic.postPrayerPerPrayer[p] ?? true,
                              onToggle: (p, selected) {
                                final map = Map<String, bool>.of(
                                    _logic.postPrayerPerPrayer);
                                map[p] = selected;
                                setState(() => _logic.postPrayerPerPrayer[p] =
                                    selected);
                                _saveSettings(postPrayerMap: map);
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Adhkar reminders — everything inline, no nested page.
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
                  ],
                ),
                const SizedBox(height: 20),
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.nsExtraAdhkarSection,
                  icon: Icons.auto_stories_rounded,
                  color: const Color(0xFF10B981),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
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
                  ],
                ),
                const SizedBox(height: 20),

                // Do Not Disturb (DND) Automation
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
                                        borderRadius: BorderRadius.circular(10),
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
                        child: HusnNumberPickerRow(
                          title: loc.nsDndDuration,
                          value: _logic.dndDurationMinutes,
                          options: const [
                            10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
                          ],
                          accentColor: const Color(0xFFEF4444),
                          labelOf: (v) => loc.nsDndMinutes(v),
                          onChanged: (v) {
                            setState(
                                () => _logic.dndDurationMinutes = v);
                            _saveSettings(dndDurationMinutesValue: v);
                          },
                        ),
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
