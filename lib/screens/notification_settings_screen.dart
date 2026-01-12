import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/prayer_times_logic.dart';
import 'fajr_challenge_screen.dart';
import '../helpers/battery_optimization_helper.dart';

import 'package:small_husn_muslim/constants/strings.dart';

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
      bool? nightPrayerTimesValue}) async {
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
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A24),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A24),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: const Text(
              'إعدادات التنبيهات',
              style: TextStyle(
                fontFamily: 'Amiri',
                color: Colors.white,
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
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Battery Optimization Warning Banner
                if (!_isCheckingBattery && _isBatteryOptimizationEnabled)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.amber, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'تحذير: تحسين البطارية مفعّل',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  color: Colors.amber,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'تحسين البطارية قد يوقف الإشعار الدائم ويظهر "الآن" بدلاً من الوقت المتبقي. لضمان عمل التطبيق بشكل صحيح، يُنصح بتعطيل تحسين البطارية.',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await BatteryOptimizationHelper
                                  .requestIgnoreBatteryOptimization();
                              // Re-check after a delay to see if user disabled it
                              Future.delayed(const Duration(seconds: 2), () {
                                _checkBatteryOptimization();
                              });
                            },
                            icon: const Icon(Icons.battery_saver, size: 20),
                            label: const Text(
                              'تعطيل تحسين البطارية',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Global notifications switch
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: const Color(0xFFD64463),
                    activeTrackColor:
                        const Color(0xFFD64463).withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    title: const Text(
                      'تفعيل التنبيهات',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'تفعيل أو إيقاف جميع التنبيهات',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    value: _logic.notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _logic.notificationsEnabled = value;
                        // Update all individual prayer notifications to match
                        for (var name in _logic.arabicPrayerNames) {
                          _logic.prayerNotificationsEnabled[name] = value;
                        }
                      });
                      _saveSettings();
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Sound switch
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: const Color(0xFFD64463),
                    activeTrackColor:
                        const Color(0xFFD64463).withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    title: const Text(
                      'صوت الأذان',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'تشغيل صوت الأذان مع التنبيه',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    value: _logic.notificationSoundEnabled,
                    onChanged: (value) {
                      setState(() => _logic.notificationSoundEnabled = value);
                      _saveSettings();
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Persistent notification switch
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: const Color(0xFFD64463),
                    activeTrackColor:
                        const Color(0xFFD64463).withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    title: const Text(
                      'إشعار دائم',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'عرض التاريخ الهجري والصلاة القادمة',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    value: _logic.persistentNotificationEnabled,
                    onChanged: (value) {
                      setState(
                          () => _logic.persistentNotificationEnabled = value);
                      _saveSettings(persistentValue: value);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Wake Up Challenge Section
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD64463).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFD64463).withValues(alpha: 0.3)),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: const Color(0xFFD64463),
                    activeTrackColor:
                        const Color(0xFFD64463).withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64463).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.alarm_on,
                          color: Color(0xFFD64463), size: 28),
                    ),
                    title: const Text(
                      'تحدي صلاة الفجر',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'منبه لا يتوقف إلا بحل الأسئلة',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    value: _logic.fajrChallengeEnabled,
                    onChanged: (value) {
                      setState(() => _logic.fajrChallengeEnabled = value);
                      _saveSettings(fajrChallengeValue: value);
                    },
                  ),
                ),

                if (_logic.fajrChallengeEnabled)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عدد الأسئلة: ${_logic.fajrChallengeQuestionsCount}',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Slider(
                          value: _logic.fajrChallengeQuestionsCount.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: const Color(0xFFD64463),
                          inactiveColor: Colors.grey.withValues(alpha: 0.3),
                          label: '${_logic.fajrChallengeQuestionsCount}',
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
                        const Divider(color: Colors.white24),
                        SwitchListTile(
                          activeThumbColor: const Color(0xFFD64463),
                          activeTrackColor:
                              const Color(0xFFD64463).withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor:
                              Colors.grey.withValues(alpha: 0.3),
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'كتابة الإجابة',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'أكثر صعوبة: اكتب الإجابة بدلاً من الاختيار',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
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
                        const Divider(color: Colors.white24),

                        // Wake Up Mode Section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'وقت الاستيقاظ',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        RadioGroup<String>(
                          groupValue: _logic.fajrChallengeWakeUpMode,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _logic.fajrChallengeWakeUpMode = val;
                              });
                              _saveSettings(challengeWakeUpMode: val);
                            }
                          },
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                value: 'auto',
                                activeColor: const Color(0xFFD64463),
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'تلقائي (عند الثلث الأخير)',
                                  style: TextStyle(
                                      fontFamily: 'Amiri', color: Colors.white),
                                ),
                              ),
                              RadioListTile<String>(
                                value: 'custom',
                                activeColor: const Color(0xFFD64463),
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'مخصص (قبل الفجر)',
                                  style: TextStyle(
                                      fontFamily: 'Amiri', color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Custom Offset Slider (Visible only if Custom)
                        if (_logic.fajrChallengeWakeUpMode == 'custom')
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_logic.fajrChallengeCustomOffsetMinutes} دقيقة',
                                    style: const TextStyle(color: Colors.amber),
                                  ),
                                  const Text(
                                    'قبل الفجر بـ:',
                                    style: TextStyle(
                                        fontFamily: 'Amiri',
                                        color: Colors.white70),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _logic.fajrChallengeCustomOffsetMinutes
                                    .toDouble(),
                                min: 10,
                                max: 120, // Max 2 hours before
                                divisions: 11, // 10, 20, ... 120
                                activeColor: const Color(0xFFD64463),
                                inactiveColor:
                                    Colors.grey.withValues(alpha: 0.3),
                                label:
                                    '${_logic.fajrChallengeCustomOffsetMinutes} دقيقة',
                                onChanged: (val) {
                                  setState(() {
                                    _logic.fajrChallengeCustomOffsetMinutes =
                                        val.toInt();
                                  });
                                  _saveSettings(
                                      challengeCustomOffset: val.toInt());
                                },
                              ),
                            ],
                          ),

                        const Divider(color: Colors.white24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'تجربة التحدي',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'جرب التحدي الآن للتأكد من عمله',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Get.to(() => const FajrChallengeScreen());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD64463),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('بدء التجربة'),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Adhkar Auto-Reminders Section
                Text(
                  'تنبيهات الأذكار التلقائية',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeThumbColor: const Color(0xFFD64463),
                        activeTrackColor:
                            const Color(0xFFD64463).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                        title: const Text(
                          'أذكار الصباح',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'بعد صلاة الفجر بـ ساعة واحدة',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        value: _logic.morningAdhkarEnabled,
                        onChanged: (value) {
                          setState(() => _logic.morningAdhkarEnabled = value);
                          _saveSettings(morningAdhkarValue: value);
                        },
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      SwitchListTile(
                        activeThumbColor: const Color(0xFFD64463),
                        activeTrackColor:
                            const Color(0xFFD64463).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                        title: const Text(
                          'أذكار المساء',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'بعد صلاة العصر بـساعة واحدة',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        value: _logic.eveningAdhkarEnabled,
                        onChanged: (value) {
                          setState(() => _logic.eveningAdhkarEnabled = value);
                          _saveSettings(eveningAdhkarValue: value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
