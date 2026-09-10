import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
import 'package:small_husn_muslim/features/settings/presentation/advanced_settings_screen.dart';
class ExtraAlarmsSettingsScreen extends StatefulWidget {
  const ExtraAlarmsSettingsScreen({super.key});

  @override
  State<ExtraAlarmsSettingsScreen> createState() => _ExtraAlarmsSettingsScreenState();
}

class _ExtraAlarmsSettingsScreenState extends State<ExtraAlarmsSettingsScreen> {
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
              loc.nsExtraAlarms,
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
                    if (_logic.suhoorAlarmEnabled) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loc.nsBeforeFajrBy,
                                style: TextStyle(
                                    fontFamily: 'Amiri', fontSize: 14)),
                            Text(loc.sheetMinutes(_logic.suhoorOffsetMinutes),
                                style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0EA5E9))),
                          ],
                        ),
                      ),
                      Slider(
                        value: _logic.suhoorOffsetMinutes.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        activeColor: const Color(0xFF0EA5E9),
                        onChanged: (v) => setState(
                            () => _logic.suhoorOffsetMinutes = v.toInt()),
                        onChangeEnd: (v) =>
                            _saveSettings(suhoorOffset: v.toInt()),
                      ),
                    ],
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
                    if (_logic.preFajrAlarmEnabled) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loc.nsBeforeFajrBy,
                                style: TextStyle(
                                    fontFamily: 'Amiri', fontSize: 14)),
                            Text(loc.sheetMinutes(_logic.preFajrOffsetMinutes),
                                style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B5CF6))),
                          ],
                        ),
                      ),
                      Slider(
                        value: _logic.preFajrOffsetMinutes.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        activeColor: const Color(0xFF8B5CF6),
                        onChanged: (v) => setState(
                            () => _logic.preFajrOffsetMinutes = v.toInt()),
                        onChangeEnd: (v) =>
                            _saveSettings(preFajrOffset: v.toInt()),
                      ),
                    ],
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
                    if (_logic.tahajjudEnabled) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SettingsWidgets.buildChoiceCard(
                                context: context,
                                title: loc.nsTahajjudLastThird,
                                subtitle: '',
                                isSelected:
                                    _logic.tahajjudMode == 'lastThird',
                                onTap: () {
                                  setState(() =>
                                      _logic.tahajjudMode = 'lastThird');
                                  _saveSettings(
                                      tahajjudModeValue: 'lastThird');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SettingsWidgets.buildChoiceCard(
                                context: context,
                                title: loc.nsTahajjudFixed,
                                subtitle:
                                    '${_logic.tahajjudHour.toString().padLeft(2, '0')}:${_logic.tahajjudMinute.toString().padLeft(2, '0')}',
                                isSelected:
                                    _logic.tahajjudMode == 'fixed',
                                onTap: () async {
                                  final picked =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                        hour: _logic.tahajjudHour,
                                        minute: _logic.tahajjudMinute),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _logic.tahajjudMode = 'fixed';
                                      _logic.tahajjudHour = picked.hour;
                                      _logic.tahajjudMinute = picked.minute;
                                    });
                                    _saveSettings(
                                      tahajjudModeValue: 'fixed',
                                      tahajjudH: picked.hour,
                                      tahajjudM: picked.minute,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
                    if (_logic.fajrExtra1Enabled ||
                        _logic.fajrExtra2Enabled) ...[
                      CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        dense: true,
                        title: Text(
                            '+${loc.sheetMinutes(_logic.fajrExtra1Minutes)}',
                            style: const TextStyle(
                                fontFamily: 'Amiri')),
                        value: _logic.fajrExtra1Enabled,
                        activeColor: const Color(0xFFF59E0B),
                        onChanged: (v) {
                          setState(() =>
                              _logic.fajrExtra1Enabled = v ?? false);
                          _saveSettings(fajrExtra1Value: v ?? false);
                        },
                      ),
                      if (_logic.fajrExtra1Enabled)
                        Slider(
                          value: _logic.fajrExtra1Minutes.toDouble(),
                          min: 1,
                          max: 60,
                          divisions: 59,
                          activeColor: const Color(0xFFF59E0B),
                          onChanged: (v) => setState(() =>
                              _logic.fajrExtra1Minutes = v.toInt()),
                          onChangeEnd: (v) => _saveSettings(
                              fajrExtra1Delay: v.toInt()),
                        ),
                      CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        dense: true,
                        title: Text(
                            '+${loc.sheetMinutes(_logic.fajrExtra2Minutes)}',
                            style: const TextStyle(
                                fontFamily: 'Amiri')),
                        value: _logic.fajrExtra2Enabled,
                        activeColor: const Color(0xFFF59E0B),
                        onChanged: (v) {
                          setState(() =>
                              _logic.fajrExtra2Enabled = v ?? false);
                          _saveSettings(fajrExtra2Value: v ?? false);
                        },
                      ),
                      if (_logic.fajrExtra2Enabled)
                        Slider(
                          value: _logic.fajrExtra2Minutes.toDouble(),
                          min: 1,
                          max: 60,
                          divisions: 59,
                          activeColor: const Color(0xFFF59E0B),
                          onChanged: (v) => setState(() =>
                              _logic.fajrExtra2Minutes = v.toInt()),
                          onChangeEnd: (v) => _saveSettings(
                              fajrExtra2Delay: v.toInt()),
                        ),
                    ],
                    SettingsWidgets.buildDivider(context),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                              Icons.visibility_rounded),
                          label: Text(loc.nsPreviewTry,
                              style: const TextStyle(
                                  fontFamily: 'Amiri')),
                          onPressed: () => Get.to(
                              () => const FajrChallengeScreen(
                                  preview: true)),
                        ),
                      ),
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
                    if (_logic.bedtimeAlarmEnabled)
                      SwitchListTile(
                        title: Text(loc.nsBedtimeRelative,
                            style: const TextStyle(fontFamily: 'Amiri')),
                        subtitle: Text(
                            loc.nsBedtimeRelativeSub(
                                _logic.bedtimeRelativeHours),
                            style: const TextStyle(fontFamily: 'Amiri')),
                        value: _logic.bedtimeRelativeToFajr,
                        onChanged: (v) {
                          setState(
                              () => _logic.bedtimeRelativeToFajr = v);
                          _saveSettings(bedtimeRelative: v);
                        },
                      ),
                    if (_logic.bedtimeAlarmEnabled)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _logic.skipBedtimeOnce();
                              if (!context.mounted) return;
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(loc.nsSkippedTonight,
                                        style: const TextStyle(
                                            fontFamily: 'Amiri'))),
                              );
                            },
                            icon: const Icon(Icons.skip_next_rounded),
                            label: Text(loc.nsSkipTonight,
                                style: const TextStyle(
                                    fontFamily: 'Amiri')),
                          ),
                        ),
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
                    if (_logic.prePrayerEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(loc.nsBeforePrayerBy,
                                    style: const TextStyle(
                                        fontFamily: 'Amiri', fontSize: 14)),
                                Text(
                                    loc.sheetMinutes(
                                        _logic.prePrayerOffsetMinutes),
                                    style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981))),
                              ],
                            ),
                            Slider(
                              value: _logic.prePrayerOffsetMinutes.toDouble(),
                              min: 5,
                              max: 60,
                              divisions: 11,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (v) => setState(() =>
                                  _logic.prePrayerOffsetMinutes = v.toInt()),
                            onChangeEnd: (v) => _saveSettings(
                                prePrayerOffset: v.toInt()),
                          ),
                            if (_showAdvanced)
                              for (final p
                                  in PrayerTimesLogic.prePostPrayers)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                      _arabicPrayer(context, p),
                                      style: const TextStyle(
                                          fontFamily: 'Amiri')),
                                  value:
                                      _logic.prePrayerPerPrayer[p] ?? true,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (v) {
                                    final map = Map<String, bool>.of(
                                        _logic.prePrayerPerPrayer);
                                    map[p] = v ?? true;
                                    setState(() =>
                                        _logic.prePrayerPerPrayer[p] =
                                            v ?? true);
                                    _saveSettings(prePrayerMap: map);
                                  },
                                ),
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
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(loc.nsAfterPrayerBy,
                                    style: const TextStyle(
                                        fontFamily: 'Amiri', fontSize: 14)),
                                Text(
                                    loc.sheetMinutes(
                                        _logic.postPrayerOffsetMinutes),
                                    style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF59E0B))),
                              ],
                            ),
                            Slider(
                              value: _logic.postPrayerOffsetMinutes.toDouble(),
                              min: 5,
                              max: 60,
                              divisions: 11,
                              activeColor: const Color(0xFFF59E0B),
                              onChanged: (v) => setState(() =>
                                  _logic.postPrayerOffsetMinutes = v.toInt()),
                            onChangeEnd: (v) => _saveSettings(
                                postPrayerOffset: v.toInt()),
                          ),
                            if (_showAdvanced)
                              for (final p
                                  in PrayerTimesLogic.prePostPrayers)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                      _arabicPrayer(context, p),
                                      style: const TextStyle(
                                          fontFamily: 'Amiri')),
                                  value:
                                      _logic.postPrayerPerPrayer[p] ?? true,
                                  activeColor: const Color(0xFFF59E0B),
                                  onChanged: (v) {
                                    final map = Map<String, bool>.of(
                                        _logic.postPrayerPerPrayer);
                                    map[p] = v ?? true;
                                    setState(() =>
                                        _logic.postPrayerPerPrayer[p] =
                                            v ?? true);
                                    _saveSettings(postPrayerMap: map);
                                  },
                                ),
                          ],
                        ),
                      ),
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
