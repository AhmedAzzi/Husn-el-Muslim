import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/settings/presentation/notification_settings_screen.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PrayerTimesLogic _prayerLogic = PrayerTimesLogic();
  final DhikrReminderHelper _reminderHelper = DhikrReminderHelper();
  bool _clickSoundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = true;
  String _selectedHomeScreen = 'azkar';

  // Reminder settings
  bool _reminderEnabled = false;
  int _reminderInterval = 15;

  // Home screen options
  static const Map<String, String> _homeScreenOptions = {
    'azkar': 'الأذكار',
    'misbaha': 'المسبحة',
    'prayer_times': 'مواقيت الصلاة',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = SharedPrefsCache.instance;
    await _prayerLogic.loadNotificationPreference();
    setState(() {
      _clickSoundEnabled = prefs.getBool('click_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode') ?? true;
      _selectedHomeScreen = prefs.getString('home_screen') ?? 'azkar';
      _reminderEnabled = _reminderHelper.isEnabled;
      _reminderInterval = _reminderHelper.intervalMinutes;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final hasPermission =
          await PrayerNotificationHelper.checkOverlayPermission();
      if (!hasPermission) {
        if (!mounted) return;
        final bool? proceed = await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: const Color(0xFF1A1A24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'إذن الظهور فوق التطبيقات',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white, fontFamily: 'Amiri'),
            ),
            content: const Text(
              'ليتمكن التطبيق من إظهار أذكار التذكير التلقائية أثناء استخدامك لتطبيقات أخرى، يحتاج إلى إذن "الظهور فوق التطبيقات". هل تود تفعيله الآن؟',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white70, fontFamily: 'Amiri'),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('لاحقاً',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD64463),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  PrayerNotificationHelper.requestOverlayPermission();
                  Get.back(result: true);
                },
                child: const Text('تفعيل الآن',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (proceed != true) {
          // User cancelled
        }
      }
    }

    await _reminderHelper.updateSettings(value, _reminderInterval);
    setState(() {
      _reminderEnabled = value;
    });
  }

  Future<void> _setReminderInterval(int value) async {
    await _reminderHelper.updateSettings(_reminderEnabled, value);
    setState(() {
      _reminderInterval = value;
    });
  }

  Future<void> _toggleClickSound(bool value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setBool('click_sound_enabled', value);
    setState(() {
      _clickSoundEnabled = value;
    });
  }

  Future<void> _toggleVibration(bool value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setBool('vibration_enabled', value);
    setState(() {
      _vibrationEnabled = value;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setBool('dark_mode', value);
    setState(() {
      _darkModeEnabled = value;
    });
    // Apply theme change immediately using GetX
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _setHomeScreen(String? value) async {
    if (value == null) return;
    final prefs = SharedPrefsCache.instance;
    await prefs.setString('home_screen', value);
    setState(() {
      _selectedHomeScreen = value;
    });
    // Show a snackbar to inform the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سيتم تطبيق التغيير عند إعادة فتح التطبيق',
              textDirection: TextDirection.rtl),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showManualAdjustmentDialog() {
    final Map<String, String> prayerNames = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C35),
              title: const Text(
                'تعديل مواقيت الصلاة',
                style: TextStyle(fontFamily: 'Amiri', color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: prayerNames.entries.map((entry) {
                    final int totalSeconds =
                        _prayerLogic.prayerOffsets[entry.key] ?? 0;
                    final int mins = (totalSeconds / 60).floor();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          _buildNumberInput(
                            label: 'دقائق',
                            value: mins,
                            onChanged: (v) {
                              setDialogState(() {
                                _prayerLogic.prayerOffsets[entry.key] = v * 60;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('إلغاء',
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _prayerLogic.saveCalculationSettings();
                    setState(() {});
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64463)),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumberInput(
      {required String label,
      required int value,
      required Function(int) onChanged}) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
          onPressed: () => onChanged(value - 1),
        ),
        Expanded(
          child: Text(
            '$value $label',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }

  void _showHijriAdjustmentDialog() {
    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C35),
              title: const Text(
                'تعديل التاريخ الهجري',
                style: TextStyle(fontFamily: 'Amiri', color: Colors.white),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.white, size: 30),
                    onPressed: () {
                      setDialogState(() {
                        _prayerLogic.hijriOffset--;
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '${_prayerLogic.hijriOffset} يوم',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.white, size: 30),
                    onPressed: () {
                      setDialogState(() {
                        _prayerLogic.hijriOffset++;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('إلغاء',
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _prayerLogic.saveCalculationSettings();
                    setState(() {});
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64463)),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        ),
      ),
    );
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
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'الإعدادات',
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
                // General Settings Section
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
                          'صوت النقرة',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'تشغيل صوت عند النقر على المسبحة',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volume_up_rounded,
                              color: Color(0xFFD64463), size: 20),
                        ),
                        value: _clickSoundEnabled,
                        onChanged: _toggleClickSound,
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      SwitchListTile(
                        activeThumbColor: const Color(0xFFD64463),
                        activeTrackColor:
                            const Color(0xFFD64463).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                        title: const Text(
                          'الاهتزاز',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'اهتزاز الهاتف عند التسبيح',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.vibration_rounded,
                              color: Color(0xFFD64463), size: 20),
                        ),
                        value: _vibrationEnabled,
                        onChanged: _toggleVibration,
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      // Dark Mode Toggle
                      SwitchListTile(
                        activeThumbColor: const Color(0xFFD64463),
                        activeTrackColor:
                            const Color(0xFFD64463).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                        title: const Text(
                          'الوضع الداكن',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'تفعيل المظهر الداكن للتطبيق',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _darkModeEnabled
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: const Color(0xFFD64463),
                            size: 20,
                          ),
                        ),
                        value: _darkModeEnabled,
                        onChanged: _toggleDarkMode,
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      // Home Screen Selection
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.home_rounded,
                              color: Color(0xFFD64463), size: 20),
                        ),
                        title: const Text(
                          'الصفحة الرئيسية',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'اختر الصفحة التي يفتح عليها التطبيق',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedHomeScreen,
                            dropdownColor: const Color(0xFF2C2C35),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            items: _homeScreenOptions.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: _setHomeScreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dhikr Reminder Section
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
                          'تذكير تلقائي',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'عرض أذكار قصيرة بشكل دوري',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mode_night_sharp,
                              color: Color(0xFFD64463), size: 20),
                        ),
                        value: _reminderEnabled,
                        onChanged: _toggleReminder,
                      ),
                      if (_reminderEnabled) ...[
                        Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD64463)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.timer_outlined,
                                color: Color(0xFFD64463), size: 20),
                          ),
                          title: const Text(
                            'وتيرة التذكير',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'كل $_reminderInterval دقيقة',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD64463)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<int>(
                              value: _reminderInterval,
                              dropdownColor: const Color(0xFF2C2C35),
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              items:
                                  [1, 2, 3, 5, 10, 15, 30, 60].map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value دقيقة'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _setReminderInterval(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),


                const SizedBox(height: 20),

                // Prayer Times Settings
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // GPS Update
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.my_location,
                              color: Color(0xFFD64463), size: 20),
                        ),
                        title: const Text(
                          'تحديث الموقع',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${_prayerLogic.lat.toStringAsFixed(4)}, ${_prayerLogic.lon.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        onTap: () async {
                          await _prayerLogic.ensureDataLoaded(force: true);
                          setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم تحديث الموقع بنجاح')),
                            );
                          }
                        },
                      ),
                      Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16),

                      // Asr Method
                      ListTile(
                        title: const Text('مذهب العصر',
                            style: TextStyle(
                                fontFamily: 'Amiri',
                                color: Colors.white,
                                fontSize: 16)),
                        trailing: DropdownButton<String>(
                          value: _prayerLogic.asrMethod,
                          dropdownColor: const Color(0xFF2C2C35),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                          style: const TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white,
                              fontSize: 14),
                          items: const [
                            DropdownMenuItem(
                                value: 'shafi', child: Text('شافعي')),
                            DropdownMenuItem(
                                value: 'hanafi', child: Text('حنفي')),
                          ],
                          onChanged: (value) {
                            setState(() => _prayerLogic.asrMethod = value!);
                            _prayerLogic.saveCalculationSettings();
                          },
                        ),
                      ),
                      Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16),

                      // Calculation Method
                      ListTile(
                        title: const Text('طريقة الحساب',
                            style: TextStyle(
                                fontFamily: 'Amiri',
                                color: Colors.white,
                                fontSize: 16)),
                        trailing: DropdownButton<String>(
                          value: _prayerLogic.angles,
                          dropdownColor: const Color(0xFF2C2C35),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                          style: const TextStyle(
                              fontFamily: 'Amiri',
                              color: Colors.white,
                              fontSize: 14),
                          items: const [
                            DropdownMenuItem(
                                value: 'mwl',
                                child: Text('رابطة العالم الإسلامي')),
                            DropdownMenuItem(
                                value: 'egypt',
                                child: Text('الهيئة العامة المصرية')),
                            DropdownMenuItem(
                                value: 'makkah', child: Text('أم القرى')),
                            DropdownMenuItem(
                                value: 'karachi', child: Text('كراتشي')),
                            DropdownMenuItem(
                                value: 'isna', child: Text('أمريكا الشمالية')),
                          ],
                          onChanged: (value) {
                            setState(() => _prayerLogic.angles = value!);
                            _prayerLogic.saveCalculationSettings();
                          },
                        ),
                      ),
                      Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16),

                      // DST
                      SwitchListTile(
                        activeThumbColor: const Color(0xFFD64463),
                        activeTrackColor:
                            const Color(0xFFD64463).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                        title: const Text('التوقيت الصيفي',
                            style: TextStyle(
                                fontFamily: 'Amiri',
                                color: Colors.white,
                                fontSize: 16)),
                        value: _prayerLogic.dstEnabled,
                        onChanged: (value) {
                          setState(() => _prayerLogic.dstEnabled = value);
                          _prayerLogic.saveCalculationSettings();
                        },
                      ),
                      Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16),

                      // Manual Adjustment
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune,
                              color: Color(0xFFD64463), size: 20),
                        ),
                        title: const Text(
                          'تعديل يدوي (بالدقائق والثواني)',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => _showManualAdjustmentDialog(),
                      ),
                      Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16),

                      // Hijri Adjustment
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD64463).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_month,
                              color: Color(0xFFD64463), size: 20),
                        ),
                        title: const Text(
                          'تعديل التاريخ الهجري',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _prayerLogic.hijriOffset == 0
                              ? 'بدون تعديل'
                              : '${_prayerLogic.hijriOffset > 0 ? '+' : ''}${_prayerLogic.hijriOffset} يوم',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        onTap: () => _showHijriAdjustmentDialog(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Notification Settings Link
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64463).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded,
                          color: Color(0xFFD64463), size: 20),
                    ),
                    title: const Text(
                      'إعدادات التنبيهات',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'تخصيص تنبيهات الصلوات والأذكار',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white54, size: 18),
                    onTap: () {
                      Get.to(() => const NotificationSettingsScreen());
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
