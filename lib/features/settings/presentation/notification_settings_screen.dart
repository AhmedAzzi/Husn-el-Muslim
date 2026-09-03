import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBatteryOptimization();
  }

  Future<void> _loadSettings() async {
    await _logic.loadNotificationPreference();
    if (mounted) setState(() {});
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
      bool? morningAdhkarValue,
      bool? eveningAdhkarValue,
      bool? persistentBgValue,
      bool? nightPrayerTimesValue,
      int? notificationModeValue}) async {
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
      morningAdhkarValue: morningAdhkarValue ?? _logic.morningAdhkarEnabled,
      eveningAdhkarValue: eveningAdhkarValue ?? _logic.eveningAdhkarEnabled,
      nightPrayerTimesValue:
          nightPrayerTimesValue ?? _logic.nightPrayerTimesEnabled,
      notificationModeValue: notificationModeValue ?? _logic.notificationMode,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
              'إعدادات التنبيهات والأذان',
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
                  _buildBatteryBanner(isDark),

                // Section 1: Persistent Status Bar Notification
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'إشعارات النظام الدائمة',
                  icon: Icons.push_pin_outlined,
                  color: const Color(0xFF3B82F6),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: 'إشعار شريط الحالة الدائم',
                      subtitle: 'عرض التاريخ الهجري وموعد الصلاة القادمة دائماً',
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

                // Section 2: Fajr Challenge Smart Alarm
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'تحدي الاستيقاظ لصلاة الفجر',
                  icon: Icons.alarm_rounded,
                  color: const Color(0xFFD64463),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: 'تفعيل منبه تحدي الفجر',
                      subtitle: 'منبه تفاعلي ذكي لا يتوقف إلا بعد حل أسئلة',
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
                                const Text(
                                  'عدد أسئلة التحدي',
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
                                    '${_logic.fajrChallengeQuestionsCount} أسئلة',
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
                                  '${_logic.fajrChallengeQuestionsCount} أسئلة',
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

                            // Text Input switch
                            SwitchListTile(
                              activeThumbColor: const Color(0xFFD64463),
                              activeTrackColor: const Color(0xFFD64463)
                                  .withValues(alpha: 0.3),
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'كتابة الإجابة نصياً',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'زيادة مستوى التحدي بالكتابة بدلاً من الاختيار من متعدد',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 13,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
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

                            // Wake Up Mode Segmented Selection
                            const Text(
                              'موعد رنين المنبه',
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
                                    title: 'الثلث الأخير',
                                    subtitle: 'تلقائياً لقيام الليل',
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
                                    title: 'وقت مخصص',
                                    subtitle: 'دقائق محددة قبل الفجر',
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
                                  const Text(
                                    'الرنين قبل أذان الفجر بـ:',
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${_logic.fajrChallengeCustomOffsetMinutes} دقيقة',
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
                                    '${_logic.fajrChallengeCustomOffsetMinutes} دقيقة',
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
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Get.to(() => const FajrChallengeScreen());
                                },
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 22),
                                label: const Text(
                                  'تجربة التحدي الآن',
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
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Section 3: Morning & Evening Adhkar Scheduled Alerts
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'تنبيهات أذكار الصباح والمساء',
                  icon: Icons.wb_twilight_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: 'تنبيه أذكار الصباح',
                      subtitle: 'تذكير مبارك بعد صلاة الفجر بساعة واحدة',
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
                      title: 'تنبيه أذكار المساء',
                      subtitle: 'تذكير مبارك بعد صلاة العصر بساعة واحدة',
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryBanner(bool isDark) {
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
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تحسين البطارية مفعل في النظام',
                  style: TextStyle(
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
            'قد يُوقف النظام إشعارات الأذان والعد التنازلي التلقائي لتوفير الطاقة. يوصى باستثناء التطبيق من تحسين البطارية لضمان دقة التنبيهات.',
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
              label: const Text(
                'استثناء التطبيق من تحسين البطارية',
                style: TextStyle(
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
