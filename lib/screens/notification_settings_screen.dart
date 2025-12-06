import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/prayer_times_logic.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _logic.loadNotificationPreference();
    if (mounted) setState(() {});
  }

  Future<void> _saveSettings({bool? persistentValue}) async {
    await _logic.saveNotificationPreference(
      _logic.notificationsEnabled,
      _logic.prayerNotificationsEnabled,
      _logic.notificationSoundEnabled,
      persistentValue: persistentValue ?? _logic.persistentNotificationEnabled,
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
                // Global notifications switch
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: const Color(0xFFD64463),
                    activeTrackColor: const Color(0xFFD64463).withOpacity(0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.6),
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
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: const Color(0xFFD64463),
                    activeTrackColor: const Color(0xFFD64463).withOpacity(0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.6),
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
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: const Color(0xFFD64463),
                    activeTrackColor: const Color(0xFFD64463).withOpacity(0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.6),
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

                // Wake Up Challenge Section (New)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD64463).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFD64463).withOpacity(0.3)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64463).withOpacity(0.2),
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
                      'تحديات لإيقاظك لصلاة الفجر',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white54, size: 18),
                    onTap: () {
                      // TODO: Navigate to Wake Up Challenge Configuration
                      Get.snackbar(
                        'قريباً',
                        'سيتم إضافة تحديات الاستيقاظ قريباً',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.white,
                        colorText: Colors.black,
                      );
                    },
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
