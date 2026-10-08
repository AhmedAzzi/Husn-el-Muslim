import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/core/widgets/app_feedback.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
import 'package:small_husn_muslim/core/widgets/husn_number_dropdown.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';

class FajrWakeupSettingsScreen extends StatefulWidget {
  const FajrWakeupSettingsScreen({super.key});

  @override
  State<FajrWakeupSettingsScreen> createState() =>
      _FajrWakeupSettingsScreenState();
}

class _FajrWakeupSettingsScreenState extends State<FajrWakeupSettingsScreen> {
  final PrayerTimesLogic _logic = PrayerTimesLogic();

  static const _accent = Color(0xFFD64463);
  static const _delayOptions = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _logic.loadNotificationPreference();
    if (!mounted) return;
    setState(() {});
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
          appBar: HusnAppBar.back(title: loc.sheetTitle),
          body: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Master switch stays pinned on top of every tab.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: SettingsWidgets.buildCardContainer(
                    context: context,
                    children: [
                      SettingsWidgets.buildSwitchTile(
                        context: context,
                        title: loc.nsFajrEnable,
                        subtitle: loc.nsFajrEnableSub,
                        icon: Icons.alarm_on_rounded,
                        iconColor: _accent,
                        value: _logic.fajrChallengeEnabled,
                        onChanged: (value) {
                          setState(() => _logic.fajrChallengeEnabled = value);
                          _saveSettings(fajrChallengeValue: value);
                        },
                      ),
                    ],
                  ),
                ),
                if (_logic.fajrChallengeEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Container(
                      decoration: SettingsWidgets.cardDecoration(context),
                      child: TabBar(
                        labelColor: _accent,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: _accent,
                        indicatorWeight: 2.5,
                        // Tight padding so long labels (e.g. "إعادة التنبيه")
                        // stay inside their tab instead of painting over
                        // the neighbour tab on narrow screens.
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        labelStyle: const TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                        ),
                        tabs: [
                          for (final t in [
                            loc.fajrTabChallenge,
                            loc.fajrTabSound,
                            loc.fajrTabRering,
                          ])
                            Tab(
                              child: Text(
                                t,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildChallengeTab(context, loc),
                        _buildSoundTab(context, loc),
                        _buildReringTab(context, loc),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One tab page: compact card, fits on screen without scrolling.
  Widget _tabPage(BuildContext context, List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      physics: const BouncingScrollPhysics(),
      child: SettingsWidgets.buildCardContainer(
        context: context,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontFamily: 'Amiri',
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );

  /// Grey one-line caption under pill rows (selected option's hint).
  static Widget _caption(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ------------------------------- Tab 1: Challenge -------------------------------

  Widget _buildChallengeTab(BuildContext context, AppLocalizations loc) {
    return _tabPage(context, [
      Text(loc.sheetRingTime, style: _labelStyle),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: SettingsWidgets.buildChoiceCard(
              context: context,
              title: loc.sheetLastThird,
              subtitle: loc.sheetLastThirdSub,
              isSelected: _logic.fajrChallengeWakeUpMode == 'auto',
              onTap: () {
                setState(() => _logic.fajrChallengeWakeUpMode = 'auto');
                _saveSettings(challengeWakeUpMode: 'auto');
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SettingsWidgets.buildChoiceCard(
              context: context,
              title: loc.sheetCustom,
              subtitle: loc.sheetCustomSub,
              isSelected: _logic.fajrChallengeWakeUpMode == 'custom',
              onTap: () {
                setState(() => _logic.fajrChallengeWakeUpMode = 'custom');
                _saveSettings(challengeWakeUpMode: 'custom');
              },
            ),
          ),
        ],
      ),
      if (_logic.fajrChallengeWakeUpMode == 'custom') ...[
        const SizedBox(height: 10),
        HusnNumberPickerRow(
          title: loc.sheetBeforeFajrBy,
          value: _logic.fajrChallengeCustomOffsetMinutes,
          options: const [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120],
          accentColor: _accent,
          labelOf: (v) => loc.sheetMinutes(v),
          onChanged: (v) {
            setState(() => _logic.fajrChallengeCustomOffsetMinutes = v);
            _saveSettings(challengeCustomOffset: v);
          },
        ),
      ],
      const SizedBox(height: 10),
      SettingsWidgets.buildDivider(context),
      const SizedBox(height: 10),
      HusnNumberPickerRow(
        title: loc.sheetQuestionCount,
        value: _logic.fajrChallengeQuestionsCount,
        options: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        accentColor: _accent,
        labelOf: (v) => loc.sheetQuestions(v),
        onChanged: (v) {
          setState(() => _logic.fajrChallengeQuestionsCount = v);
          _saveSettings(challengeQuestionsCount: v);
        },
      ),
      SettingsWidgets.buildSwitchTile(
        context: context,
        title: loc.sheetTextMode,
        subtitle: loc.sheetTextModeSub,
        icon: Icons.keyboard_outlined,
        iconColor: _accent,
        value: _logic.fajrChallengeIsTextInput,
        onChanged: (value) {
          setState(() => _logic.fajrChallengeIsTextInput = value);
          _saveSettings(challengeIsTextInput: value);
        },
      ),
      SettingsWidgets.buildDivider(context),
      const SizedBox(height: 10),
      Text(loc.nsChallengeType, style: _labelStyle),
      const SizedBox(height: 8),
      HusnChoicePills(
        values: const ['questions', 'math', 'memory', 'shake', 'random'],
        accentColor: _accent,
        labelOf: (t) => switch (t) {
          'math' => loc.nsTypeMath,
          'memory' => loc.nsTypeMemory,
          'shake' => loc.nsTypeShake,
          'random' => loc.nsTypeRandom,
          _ => loc.nsTypeQuestions,
        },
        isSelected: (t) => _logic.fajrChallengeType == t,
        onToggle: (t, _) {
          setState(() => _logic.fajrChallengeType = t);
          _saveSettings(challengeType: t);
        },
      ),
      const SizedBox(height: 10),
      _caption(switch (_logic.fajrChallengeType) {
        'math' => loc.nsTypeMathSub,
        'memory' => loc.nsTypeMemorySub,
        'shake' => loc.nsTypeShakeSub,
        'random' => loc.nsTypeRandomSub,
        _ => loc.nsTypeQuestionsSub,
      }),
      if (_logic.fajrChallengeType == 'random') ...[
        const SizedBox(height: 10),
        Text(loc.nsRandomPool, style: _labelStyle),
        const SizedBox(height: 8),
        HusnChoicePills(
          values: const ['questions', 'math', 'memory', 'shake'],
          accentColor: _accent,
          labelOf: (t) => switch (t) {
            'math' => loc.nsTypeMath,
            'memory' => loc.nsTypeMemory,
            'shake' => loc.nsTypeShake,
            _ => loc.nsTypeQuestions,
          },
          isSelected: (t) => _logic.fajrRandomPool.contains(t),
          onToggle: (t, selected) {
            final pool = List<String>.of(_logic.fajrRandomPool);
            if (selected) {
              if (!pool.contains(t)) pool.add(t);
            } else {
              pool.remove(t);
            }
            if (pool.isEmpty) return;
            setState(() => _logic.fajrRandomPool = pool);
            _saveSettings(challengePool: pool);
          },
        ),
      ],
      if (_logic.fajrChallengeType == 'shake' ||
          _logic.fajrChallengeType == 'random') ...[
        const SizedBox(height: 10),
        Text(loc.nsShakeSensitivity, style: _labelStyle),
        const SizedBox(height: 8),
        HusnChoicePills(
          values: const ['low', 'medium', 'high'],
          accentColor: _accent,
          labelOf: (s) => switch (s) {
            'low' => loc.nsLow,
            'high' => loc.nsHigh,
            _ => loc.nsShakeMedium,
          },
          isSelected: (s) => _logic.fajrShakeSensitivity == s,
          onToggle: (s, _) {
            setState(() => _logic.fajrShakeSensitivity = s);
            _saveSettings(shakeSensitivity: s);
          },
        ),
      ],
      const SizedBox(height: 10),
      SettingsWidgets.buildDivider(context),
      const SizedBox(height: 10),
      Text(loc.nsDifficulty, style: _labelStyle),
      const SizedBox(height: 8),
      HusnChoicePills(
        values: const ['easy', 'medium', 'hard'],
        accentColor: _accent,
        labelOf: (d) => switch (d) {
          'easy' => loc.nsEasy,
          'hard' => loc.nsHard,
          _ => loc.nsDiffMedium,
        },
        isSelected: (d) => _logic.fajrChallengeDifficulty == d,
        onToggle: (d, _) {
          setState(() => _logic.fajrChallengeDifficulty = d);
          _saveSettings(challengeDifficulty: d);
        },
      ),
      if (_logic.fajrChallengeDifficulty == 'hard') _caption(loc.nsHardSub),
      SettingsWidgets.buildSwitchTile(
        context: context,
        title: loc.nsWakeConfirm,
        subtitle: loc.nsWakeConfirmSub,
        icon: Icons.check_circle_outlined,
        iconColor: _accent,
        value: _logic.wakeUpConfirmationEnabled,
        onChanged: (value) {
          setState(() => _logic.wakeUpConfirmationEnabled = value);
          _saveSettings(wakeUpConfirmationValue: value);
        },
      ),
    ]);
  }

  // ------------------------------- Tab 2: Sound -------------------------------

  Widget _buildSoundTab(BuildContext context, AppLocalizations loc) {
    return _tabPage(context, [
      Text(loc.nsAlarmSound, style: _labelStyle),
      const SizedBox(height: 8),
      HusnChoicePills(
        values: const ['adhan', 'system', 'custom'],
        accentColor: _accent,
        labelOf: (s) => switch (s) {
          'system' => loc.nsSoundSystem,
          'custom' => loc.nsSoundCustom,
          _ => loc.nsSoundAdhan,
        },
        isSelected: (s) => _logic.alarmSound == s,
        onToggle: (s, _) {
          setState(() => _logic.alarmSound = s);
          _saveSettings(alarmSoundValue: s);
        },
      ),
      _caption(switch (_logic.alarmSound) {
        'system' => loc.nsSoundSystemSub,
        'custom' => loc.nsSoundCustomSub,
        _ => loc.nsSoundAdhanSub,
      }),
      if (_logic.alarmSound == 'custom') ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final res =
                  await FilePicker.platform.pickFiles(type: FileType.audio);
              final path = res?.files.single.path;
              if (path != null && path.isNotEmpty) {
                setState(() => _logic.alarmCustomPath = path);
                await _saveSettings(alarmCustomPathValue: path);
              }
            },
            icon: const Icon(Icons.audio_file_outlined, size: 18),
            label: Text(
              _logic.alarmCustomPath.isEmpty
                  ? loc.nsPickAudio
                  : loc.nsChangeAudio,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ),
        ),
      ],
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await PrayerNotificationHelper.previewAlarmSound();
            if (!context.mounted) return;
            AppFeedback.snack(
              context,
              loc.nsPreviewPlaying,
              action: SnackBarAction(
                label: loc.nsStop,
                textColor: Colors.white,
                onPressed: () => PrayerNotificationHelper.stopAlarmPreview(),
              ),
            );
          },
          icon: const Icon(Icons.hearing_rounded, size: 18),
          label: Text(loc.nsPreviewSound,
              style: const TextStyle(fontFamily: 'Amiri')),
        ),
      ),
      const SizedBox(height: 10),
      SettingsWidgets.buildDivider(context),
      const SizedBox(height: 10),
      HusnNumberPickerRow(
        title: loc.nsAlarmVolume,
        value: _logic.alarmVolumePercent,
        options: const [20, 30, 40, 50, 60, 70, 80, 90, 100],
        accentColor: _accent,
        labelOf: (v) => '$v٪',
        onChanged: (v) {
          setState(() => _logic.alarmVolumePercent = v);
          _saveSettings(alarmVolumeValue: v);
        },
      ),
      SettingsWidgets.buildSwitchTile(
        context: context,
        title: loc.nsAlarmVibrate,
        icon: Icons.vibration_rounded,
        iconColor: _accent,
        value: _logic.alarmVibrate,
        onChanged: (v) {
          setState(() => _logic.alarmVibrate = v);
          _saveSettings(alarmVibrateValue: v);
        },
      ),
      const SizedBox(height: 10),
      SettingsWidgets.buildDivider(context),
      const SizedBox(height: 10),
      SettingsWidgets.buildSwitchTile(
        context: context,
        title: loc.nsAlarmLoop,
        icon: Icons.loop_rounded,
        iconColor: _accent,
        value: _logic.alarmLoop,
        onChanged: (v) {
          setState(() => _logic.alarmLoop = v);
          _saveSettings(alarmLoopValue: v);
        },
      ),
      const SizedBox(height: 10),
      SettingsWidgets.buildDivider(context),
      const SizedBox(height: 10),
      Text(loc.nsGentleWake, style: _labelStyle),
      const SizedBox(height: 8),
      HusnChoicePills(
        values: const ['0', '30', '60', '120'],
        accentColor: _accent,
        labelOf: (g) =>
            g == '0' ? loc.nsInstant : loc.sheetSeconds(int.parse(g)),
        isSelected: (g) => _logic.gentleWakeSeconds == int.parse(g),
        onToggle: (g, _) {
          final v = int.parse(g);
          setState(() => _logic.gentleWakeSeconds = v);
          _saveSettings(gentleWakeValue: v);
        },
      ),
    ]);
  }

  // ------------------------------- Tab 3: Re-ring -------------------------------

  Widget _buildReringTab(BuildContext context, AppLocalizations loc) {
    return _tabPage(context, [
      // Heavy-sleeper re-ring: re-fires the Fajr challenge after Fajr.
      Text(loc.nsFajrExtra, style: _labelStyle),
      _caption(loc.nsFajrExtraSub),
      const SizedBox(height: 12),
      _extraRow(
        loc: loc,
        enabled: _logic.fajrExtra1Enabled,
        minutes: _logic.fajrExtra1Minutes,
        onToggle: (v) {
          setState(() => _logic.fajrExtra1Enabled = v);
          _saveSettings(fajrExtra1Value: v);
        },
        onDelay: (v) {
          setState(() => _logic.fajrExtra1Minutes = v);
          _saveSettings(fajrExtra1Delay: v);
        },
      ),
      const SizedBox(height: 10),
      _extraRow(
        loc: loc,
        enabled: _logic.fajrExtra2Enabled,
        minutes: _logic.fajrExtra2Minutes,
        onToggle: (v) {
          setState(() => _logic.fajrExtra2Enabled = v);
          _saveSettings(fajrExtra2Value: v);
        },
        onDelay: (v) {
          setState(() => _logic.fajrExtra2Minutes = v);
          _saveSettings(fajrExtra2Delay: v);
        },
      ),
      const SizedBox(height: 20),

      SettingsWidgets.buildDivider(context),
      const SizedBox(height: 10),

      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () {
            Get.to(() => const FajrChallengeScreen());
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: Text(
            loc.nsTryNow,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ]);
  }

  /// One re-ring row: switch + live label on the first line, delay
  /// dropdown on its own centered line when enabled. Two lines guarantee
  /// the switch, label and (wide) dropdown never collide on narrow screens.
  Widget _extraRow({
    required AppLocalizations loc,
    required bool enabled,
    required int minutes,
    required ValueChanged<bool> onToggle,
    required ValueChanged<int> onDelay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeThumbColor: _accent,
              activeTrackColor: _accent.withValues(alpha: 0.3),
            ),
            Expanded(
              child: Text(
                '+${loc.sheetMinutes(minutes)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: enabled ? null : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        if (enabled)
          Center(
            child: HusnNumberDropdown(
              value: minutes,
              options: _delayOptions,
              accentColor: _accent,
              labelOf: (v) => '+${loc.sheetMinutes(v)}',
              onChanged: onDelay,
            ),
          ),
      ],
    );
  }
}
