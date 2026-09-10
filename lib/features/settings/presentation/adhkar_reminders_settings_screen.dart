import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
class AdhkarRemindersSettingsScreen extends StatefulWidget {
  const AdhkarRemindersSettingsScreen({super.key});

  @override
  State<AdhkarRemindersSettingsScreen> createState() => _AdhkarRemindersSettingsScreenState();
}

class _AdhkarRemindersSettingsScreenState extends State<AdhkarRemindersSettingsScreen> {
  final PrayerTimesLogic _logic = PrayerTimesLogic();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _logic.loadNotificationPreference();
    if (mounted) setState(() {});
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
              loc.nsAdhkarSection,
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
                // Section 4: Extra Adhkar Reminders (Wake-up, Sleep, Friday Kahf)
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
