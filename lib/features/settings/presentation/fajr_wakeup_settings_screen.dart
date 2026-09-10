import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/prayer_tracking_screen.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
import 'package:small_husn_muslim/features/settings/presentation/advanced_settings_screen.dart';
class FajrWakeupSettingsScreen extends StatefulWidget {
  const FajrWakeupSettingsScreen({super.key});

  @override
  State<FajrWakeupSettingsScreen> createState() => _FajrWakeupSettingsScreenState();
}

class _FajrWakeupSettingsScreenState extends State<FajrWakeupSettingsScreen> {
  final PrayerTimesLogic _logic = PrayerTimesLogic();
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _logic.loadNotificationPreference();
    final prefs = SharedPrefsCache.instance;
    if (!mounted) return;
    setState(() {
      _showAdvanced = prefs.getBool('show_advanced') ?? false;
    });
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
              loc.sheetTitle,
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
                    if (_logic.fajrChallengeEnabled) ...[
                      SettingsWidgets.buildDivider(context),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Questions count slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  loc.sheetQuestionCount,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD64463)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    loc.sheetQuestions(_logic.fajrChallengeQuestionsCount),
                                    style: const TextStyle(
                                      fontFamily: 'Amiri',
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD64463),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value:
                                  _logic.fajrChallengeQuestionsCount.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              activeColor: const Color(0xFFD64463),
                              inactiveColor: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                              label:
                                  loc.sheetQuestions(_logic.fajrChallengeQuestionsCount),
                              onChanged: (double value) {
                                setState(() {
                                  _logic.fajrChallengeQuestionsCount =
                                      value.toInt();
                                });
                              },
                              onChangeEnd: (double value) {
                                _saveSettings(
                                    challengeQuestionsCount: value.toInt());
                              },
                            ),
                            const SizedBox(height: 8),

                            // Text Input switch (advanced: harder typing mode)
                            if (_showAdvanced) ...[
                              SwitchListTile(
                                activeThumbColor: const Color(0xFFD64463),
                                activeTrackColor: const Color(0xFFD64463)
                                    .withValues(alpha: 0.3),
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  loc.sheetTextMode,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  loc.sheetTextModeSub,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                                value: _logic.fajrChallengeIsTextInput,
                                onChanged: (value) {
                                  setState(() {
                                    _logic.fajrChallengeIsTextInput = value;
                                  });
                                  _saveSettings(challengeIsTextInput: value);
                                },
                              ),
                              const Divider(height: 24),
                            ],

                            // Wake Up Mode Segmented Selection
                            Text(
                              loc.sheetRingTime,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SettingsWidgets.buildChoiceCard(
                                    context: context,
                                    title: loc.sheetLastThird,
                                    subtitle: loc.sheetLastThirdSub,
                                    isSelected:
                                        _logic.fajrChallengeWakeUpMode == 'auto',
                                    onTap: () {
                                      setState(() => _logic
                                          .fajrChallengeWakeUpMode = 'auto');
                                      _saveSettings(
                                          challengeWakeUpMode: 'auto');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SettingsWidgets.buildChoiceCard(
                                    context: context,
                                    title: loc.sheetCustom,
                                    subtitle: loc.sheetCustomSub,
                                    isSelected: _logic
                                            .fajrChallengeWakeUpMode ==
                                        'custom',
                                    onTap: () {
                                      setState(() => _logic
                                          .fajrChallengeWakeUpMode = 'custom');
                                      _saveSettings(
                                          challengeWakeUpMode: 'custom');
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Custom Offset Slider
                            if (_logic.fajrChallengeWakeUpMode == 'custom') ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    loc.sheetBeforeFajrBy,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    loc.sheetMinutes(_logic.fajrChallengeCustomOffsetMinutes),
                                    style: const TextStyle(
                                      fontFamily: 'Amiri',
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD64463),
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _logic.fajrChallengeCustomOffsetMinutes
                                    .toDouble(),
                                min: 10,
                                max: 120,
                                divisions: 11,
                                activeColor: const Color(0xFFD64463),
                                inactiveColor: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                                label:
                                    loc.sheetMinutes(_logic.fajrChallengeCustomOffsetMinutes),
                                onChanged: (val) {
                                  setState(() {
                                    _logic.fajrChallengeCustomOffsetMinutes =
                                        val.toInt();
                                  });
                                },
                                onChangeEnd: (val) {
                                  _saveSettings(
                                      challengeCustomOffset: val.toInt());
                                },
                              ),
                            ],

                            const SizedBox(height: 16),
                            Text(
                              loc.nsChallengeType,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final t in [
                                  ('questions', loc.nsTypeQuestions, loc.nsTypeQuestionsSub),
                                  ('math', loc.nsTypeMath, loc.nsTypeMathSub),
                                  ('memory', loc.nsTypeMemory, loc.nsTypeMemorySub),
                                  ('shake', loc.nsTypeShake, loc.nsTypeShakeSub),
                                  ('random', loc.nsTypeRandom, loc.nsTypeRandomSub),
                                ])
                                  SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            72) /
                                        2,
                                    child: SettingsWidgets.buildChoiceCard(
                                      context: context,
                                      title: t.$2,
                                      subtitle: t.$3,
                                      isSelected:
                                          _logic.fajrChallengeType == t.$1,
                                      onTap: () {
                                        setState(() =>
                                            _logic.fajrChallengeType = t.$1);
                                        _saveSettings(challengeType: t.$1);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            if (_showAdvanced &&
                                _logic.fajrChallengeType == 'random') ...[
                              const SizedBox(height: 12),
                              Text(
                                loc.nsRandomPool,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              for (final t in [
                                ('questions', loc.nsTypeQuestions),
                                ('math', loc.nsTypeMath),
                                ('memory', loc.nsTypeMemory),
                                ('shake', loc.nsTypeShake),
                              ])
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(t.$2,
                                      style: const TextStyle(
                                          fontFamily: 'Amiri')),
                                  value: _logic.fajrRandomPool.contains(t.$1),
                                  activeColor: const Color(0xFFD64463),
                                  onChanged: (v) {
                                    final pool = List<String>.of(
                                        _logic.fajrRandomPool);
                                    if (v == true) {
                                      if (!pool.contains(t.$1)) {
                                        pool.add(t.$1);
                                      }
                                    } else {
                                      pool.remove(t.$1);
                                    }
                                    if (pool.isEmpty) return;
                                    setState(
                                        () => _logic.fajrRandomPool = pool);
                                    _saveSettings(challengePool: pool);
                                  },
                                ),
                            ],
                            if (_showAdvanced &&
                                (_logic.fajrChallengeType == 'shake' ||
                                    _logic.fajrChallengeType ==
                                        'random')) ...[
                              const SizedBox(height: 12),
                              Text(
                                loc.nsShakeSensitivity,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final s in [
                                    ('low', loc.nsLow),
                                    ('medium', loc.nsShakeMedium),
                                    ('high', loc.nsHigh),
                                  ])
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child:
                                            SettingsWidgets.buildChoiceCard(
                                          context: context,
                                          title: s.$2,
                                          subtitle: '',
                                          isSelected:
                                              _logic.fajrShakeSensitivity ==
                                                  s.$1,
                                          onTap: () {
                                            setState(() => _logic
                                                    .fajrShakeSensitivity =
                                                s.$1);
                                            _saveSettings(
                                                shakeSensitivity: s.$1);
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              loc.nsDifficulty,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                for (final d in [
                                  ('easy', loc.nsEasy),
                                  ('medium', loc.nsDiffMedium),
                                  ('hard', loc.nsHard),
                                ])
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: SettingsWidgets.buildChoiceCard(
                                        context: context,
                                        title: d.$2,
                                        subtitle: d.$1 == 'hard'
                                            ? loc.nsHardSub
                                            : '',
                                        isSelected:
                                            _logic.fajrChallengeDifficulty ==
                                                d.$1,
                                        onTap: () {
                                          setState(() =>
                                              _logic.fajrChallengeDifficulty =
                                                  d.$1);
                                          _saveSettings(
                                              challengeDifficulty: d.$1);
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_showAdvanced) ...[
                              SwitchListTile(
                                activeThumbColor: const Color(0xFFD64463),
                                activeTrackColor: const Color(0xFFD64463)
                                    .withValues(alpha: 0.3),
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  loc.nsWakeConfirm,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  loc.nsWakeConfirmSub,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                                value: _logic.wakeUpConfirmationEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _logic.wakeUpConfirmationEnabled = value;
                                  });
                                  _saveSettings(
                                      wakeUpConfirmationValue: value);
                                },
                              ),
                            ],
                            const Divider(height: 24),
                            Text(
                              loc.nsAlarmSound,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final s in [
                                  ('adhan', loc.nsSoundAdhan, loc.nsSoundAdhanSub),
                                  ('system', loc.nsSoundSystem, loc.nsSoundSystemSub),
                                  ('custom', loc.nsSoundCustom, loc.nsSoundCustomSub),
                                ])
                                  SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            72) /
                                        2,
                                    child: SettingsWidgets.buildChoiceCard(
                                      context: context,
                                      title: s.$2,
                                      subtitle: s.$3,
                                      isSelected:
                                          _logic.alarmSound == s.$1,
                                      onTap: () {
                                        setState(() =>
                                            _logic.alarmSound = s.$1);
                                        _saveSettings(alarmSoundValue: s.$1);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            if (_logic.alarmSound == 'custom') ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final res = await FilePicker.platform
                                        .pickFiles(type: FileType.audio);
                                    final path =
                                        res?.files.single.path;
                                    if (path != null && path.isNotEmpty) {
                                      setState(() => _logic.alarmCustomPath =
                                          path);
                                      await _saveSettings(
                                          alarmCustomPathValue: path);
                                    }
                                  },
                                  icon: const Icon(
                                      Icons.audio_file_outlined),
                                  label: Text(
                                    _logic.alarmCustomPath.isEmpty
                                        ? loc.nsPickAudio
                                        : loc.nsChangeAudio,
                                    style: const TextStyle(
                                        fontFamily: 'Amiri'),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await PrayerNotificationHelper
                                      .previewAlarmSound();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          loc.nsPreviewPlaying,
                                          style: const TextStyle(
                                              fontFamily: 'Amiri')),
                                      action: SnackBarAction(
                                        label: loc.nsStop,
                                        onPressed: () =>
                                            PrayerNotificationHelper
                                                .stopAlarmPreview(),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.hearing_rounded),
                                label: Text(loc.nsPreviewSound,
                                    style:
                                        TextStyle(fontFamily: 'Amiri')),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(loc.nsAlarmVolume,
                                    style: TextStyle(
                                        fontFamily: 'Amiri', fontSize: 15)),
                                Text('${_logic.alarmVolumePercent}٪',
                                    style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD64463))),
                              ],
                            ),
                            Slider(
                              value: _logic.alarmVolumePercent.toDouble(),
                              min: 20,
                              max: 100,
                              divisions: 8,
                              activeColor: const Color(0xFFD64463),
                              label: '${_logic.alarmVolumePercent}٪',
                              onChanged: (v) => setState(() =>
                                  _logic.alarmVolumePercent = v.toInt()),
                              onChangeEnd: (v) => _saveSettings(
                                  alarmVolumeValue: v.toInt()),
                            ),
                            if (_showAdvanced) ...[
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(loc.nsAlarmVibrate,
                                    style:
                                        TextStyle(fontFamily: 'Amiri')),
                                value: _logic.alarmVibrate,
                                activeThumbColor: const Color(0xFFD64463),
                                onChanged: (v) {
                                  setState(
                                      () => _logic.alarmVibrate = v);
                                  _saveSettings(alarmVibrateValue: v);
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(loc.nsAlarmLoop,
                                    style:
                                        TextStyle(fontFamily: 'Amiri')),
                                value: _logic.alarmLoop,
                                activeThumbColor: const Color(0xFFD64463),
                                onChanged: (v) {
                                  setState(
                                      () => _logic.alarmLoop = v);
                                  _saveSettings(alarmLoopValue: v);
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                loc.nsGentleWake,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final g in [
                                    (0, loc.nsInstant),
                                    (30, loc.sheetSeconds(30)),
                                    (60, loc.sheetSeconds(60)),
                                    (120, loc.sheetSeconds(120)),
                                  ])
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 3),
                                        child: SettingsWidgets
                                            .buildChoiceCard(
                                          context: context,
                                          title: g.$2,
                                          subtitle: '',
                                          isSelected:
                                              _logic.gentleWakeSeconds ==
                                                  g.$1,
                                          onTap: () {
                                            setState(() => _logic
                                                .gentleWakeSeconds = g.$1);
                                            _saveSettings(
                                                gentleWakeValue: g.$1);
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Get.to(() => const FajrChallengeScreen());
                                },
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 22),
                                label: Text(
                                  loc.nsTryNow,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD64463),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Get.to(() => const PrayerTrackingScreen());
                                },
                                icon: const Icon(Icons.local_fire_department,
                                    size: 22),
                                label: Text(
                                  loc.nsOpenLog,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (!_showAdvanced) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Get.to(
                          () => const AdvancedSettingsScreen()),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        loc.stHiddenAdvanced,
                        style:
                            const TextStyle(fontFamily: 'Amiri'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
