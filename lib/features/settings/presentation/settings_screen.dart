import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/settings/presentation/notification_settings_screen.dart';
import 'package:small_husn_muslim/features/overlays/presentation/dhikr_reminder_helper.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/utils/url_utils.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/mosque_map_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';

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
  bool _isRefreshingLocation = false;

  // Home screen options
  static const Map<String, ({String title, String subtitle, IconData icon})>
      _homeScreenMeta = {
    'azkar': (
      title: 'الأذكار',
      subtitle: 'أذكار اليوم والليلة وحصن المسلم',
      icon: Icons.menu_book_rounded,
    ),
    'misbaha': (
      title: 'المسبحة الإلكترونية',
      subtitle: 'عداد التسبيح والأذكار المخصصة',
      icon: Icons.touch_app_rounded,
    ),
    'prayer_times': (
      title: 'مواقيت الصلاة',
      subtitle: 'مواعيد الأذان والتنبيهات والقبلة',
      icon: Icons.access_time_filled_rounded,
    ),
  };

  // Calculation method details
  static const Map<String, ({String title, String subtitle})>
      _calculationMethods = {
    'makkah': (
      title: 'أم القرى (مكة المكرمة)',
      subtitle: 'المملكة العربية السعودية والخليج العربي',
    ),
    'egypt': (
      title: 'الهيئة العامة المصرية للمساحة',
      subtitle: 'مصر، السودان، وبعض دول إفريقيا',
    ),
    'mwl': (
      title: 'رابطة العالم الإسلامي',
      subtitle: 'أوروبا والشرق الأقصى وأمريكا',
    ),
    'karachi': (
      title: 'جامعة العلوم الإسلامية بكراتشي',
      subtitle: 'باكستان، الهند، بنغلاديش، وأفغانستان',
    ),
    'isna': (
      title: 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)',
      subtitle: 'الولايات المتحدة وكندا',
    ),
  };

  // Asr methods
  static const Map<String, ({String title, String subtitle})> _asrMethods = {
    'shafi': (
      title: 'الجمهور (شافعي، مالكي، حنبلي)',
      subtitle: 'عندما يصير ظل كل شيء مثله',
    ),
    'hanafi': (
      title: 'المذهب الحنفي',
      subtitle: 'عندما يصير ظل كل شيء مثليه',
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = SharedPrefsCache.instance;
    await _prayerLogic.loadNotificationPreference();
    if (!mounted) return;
    setState(() {
      _clickSoundEnabled = prefs.getBool('click_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode') ?? true;
      _selectedHomeScreen = prefs.getString('home_screen') ?? 'azkar';
      _reminderEnabled = _reminderHelper.isEnabled;
      _reminderInterval = _reminderHelper.intervalMinutes;
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
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _setHomeScreen(String value) async {
    final prefs = SharedPrefsCache.instance;
    await prefs.setString('home_screen', value);
    setState(() {
      _selectedHomeScreen = value;
    });
    _showSnackBar('تم تعيين الصفحة الرئيسية (تُطبق عند إعادة الفتح)');
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final hasPermission =
          await PrayerNotificationHelper.checkOverlayPermission();
      if (!hasPermission) {
        if (!mounted) return;
        final bool? proceed = await _showOverlayPermissionDialog();
        if (proceed != true) return;
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

  Future<void> _refreshGpsLocation() async {
    setState(() => _isRefreshingLocation = true);
    try {
      await _prayerLogic.ensureDataLoaded(force: true);
      _showSnackBar('تم تحديث الموقع ومواقيت الصلاة بنجاح');
    } catch (e) {
      _showSnackBar('تعذر تحديث الموقع، يرجى التحقق من تفعيل الـ GPS');
    } finally {
      if (mounted) setState(() => _isRefreshingLocation = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 15),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- Dialogs & Bottom Sheets ---

  Future<bool?> _showOverlayPermissionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF23232E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.layers_rounded, color: Color(0xFFD64463), size: 28),
              SizedBox(width: 10),
              Text(
                'إذن الظهور فوق التطبيقات',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'ليتمكن التطبيق من عرض الأذكار القصيرة أثناء تصفحك للتطبيقات الأخرى، يحتاج إلى منح إذن "الظهور فوق التطبيقات". هل تود تفعيله الآن؟',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(
                'لاحقاً',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64463),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                PrayerNotificationHelper.requestOverlayPermission();
                Get.back(result: true);
              },
              child: const Text(
                'تفعيل الآن',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeScreenPicker() {
    _showCustomBottomSheet(
      title: 'الصفحة الرئيسية الافتراضية',
      subtitle: 'اختر الواجهة التي تبدأ مع فتح التطبيق',
      child: Column(
        children: _homeScreenMeta.entries.map((entry) {
          final isSelected = _selectedHomeScreen == entry.key;
          return SettingsWidgets.buildPickerOption(
            context: context,
            title: entry.value.title,
            subtitle: entry.value.subtitle,
            icon: entry.value.icon,
            isSelected: isSelected,
            onTap: () {
              Get.back();
              _setHomeScreen(entry.key);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showIntervalPicker() {
    final intervals = [1, 2, 3, 5, 10, 15, 30, 60];
    _showCustomBottomSheet(
      title: 'وتيرة التذكير التلقائي',
      subtitle: 'المدة الزمنية بين كل ذكر عائم وآخر',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: intervals.map((mins) {
          final isSelected = _reminderInterval == mins;
          return ChoiceChip(
            label: Text(
              mins >= 60 ? 'كل ساعة' : 'كل $mins دقيقة',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : null,
                fontSize: 15,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFFD64463),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2C2C38)
                : Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFD64463)
                    : Colors.transparent,
              ),
            ),
            onSelected: (selected) {
              if (selected) {
                Get.back();
                _setReminderInterval(mins);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showPrayerSourcePicker() {
    _showCustomBottomSheet(
      title: 'مصدر مواقيت الصلاة',
      subtitle: 'اختر بين مواقيت المسجد المعتمدة أو الحساب الفلكي الدقيق',
      child: Column(
        children: [
          SettingsWidgets.buildPickerOption(
            context: context,
            title: 'مواقيت المسجد (أونلاين مع كاش)',
            subtitle:
                'جلب المواقيت المعتمدة لمسجدك المحدد عبر Mawaqit وحفظها للعمل بدون إنترنت',
            icon: Icons.mosque_rounded,
            isSelected:
                _prayerLogic.prayerTimeSource == PrayerTimeSource.mosque,
            onTap: () {
              Get.back();
              if (_prayerLogic.selectedMosque == null) {
                Get.to(() => const MosqueMapScreen());
              } else {
                setState(() =>
                    _prayerLogic.setPrayerTimeSource(PrayerTimeSource.mosque));
                _showSnackBar('تم تعيين المصدر: مواقيت المسجد');
              }
            },
          ),
          SettingsWidgets.buildPickerOption(
            context: context,
            title: 'مواقيت محسوبة (أوفلاين بالكامل)',
            subtitle:
                'حساب مواقيت الصلاة فلكياً بناءً على إحداثيات الموقع والمذهب الفقهي دون الحاجة للإنترنت',
            icon: Icons.calculate_outlined,
            isSelected:
                _prayerLogic.prayerTimeSource == PrayerTimeSource.calculated,
            onTap: () {
              Get.back();
              setState(() => _prayerLogic
                  .setPrayerTimeSource(PrayerTimeSource.calculated));
              _showSnackBar('تم تعيين المصدر: مواقيت محسوبة');
            },
          ),
        ],
      ),
    );
  }

  void _showCalculationMethodPicker() {
    _showCustomBottomSheet(
      title: 'طريقة حساب مواقيت الصلاة',
      subtitle: 'اختر الهيئة أو المجمع الفلكي المعتمد في منطقتك',
      child: Column(
        children: _calculationMethods.entries.map((entry) {
          final isSelected = _prayerLogic.angles == entry.key;
          return SettingsWidgets.buildPickerOption(
            context: context,
            title: entry.value.title,
            subtitle: entry.value.subtitle,
            icon: Icons.mosque_rounded,
            isSelected: isSelected,
            onTap: () {
              Get.back();
              setState(() => _prayerLogic.angles = entry.key);
              _prayerLogic.saveCalculationSettings();
              _showSnackBar('تم حفظ طريقة الحساب وإعادة ضبط المواقيت');
            },
          );
        }).toList(),
      ),
    );
  }

  void _showAsrMethodPicker() {
    _showCustomBottomSheet(
      title: 'مذهب صلاة العصر',
      subtitle: 'تحديد وقت دخول صلاة العصر حسب المذاهب الفقهية',
      child: Column(
        children: _asrMethods.entries.map((entry) {
          final isSelected = _prayerLogic.asrMethod == entry.key;
          return SettingsWidgets.buildPickerOption(
            context: context,
            title: entry.value.title,
            subtitle: entry.value.subtitle,
            icon: Icons.wb_sunny_rounded,
            isSelected: isSelected,
            onTap: () {
              Get.back();
              setState(() => _prayerLogic.asrMethod = entry.key);
              _prayerLogic.saveCalculationSettings();
              _showSnackBar('تم حفظ مذهب العصر');
            },
          );
        }).toList(),
      ),
    );
  }

  void _showManualAdjustmentSheet() {
    final Map<String, String> prayerNames = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E28) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تعديل مواقيت الصلاة يدوياً',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            for (var key in prayerNames.keys) {
                              _prayerLogic.prayerOffsets[key] = 0;
                            }
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'إعادة ضبط',
                          style: TextStyle(fontFamily: 'Amiri'),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD64463),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يمكنك زيادة أو إنقاص دقائق محددة لكل صلاة لتطابق أذان مسجدك',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      children: prayerNames.entries.map((entry) {
                        final int totalSeconds =
                            _prayerLogic.prayerOffsets[entry.key] ?? 0;
                        final int mins = (totalSeconds / 60).floor();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF282836)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 24),
                                color: const Color(0xFFD64463),
                                onPressed: () {
                                  setSheetState(() {
                                    _prayerLogic.prayerOffsets[entry.key] =
                                        (mins - 1) * 60;
                                  });
                                },
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 70),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: mins == 0
                                      ? (isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200)
                                      : const Color(0xFFD64463)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  mins == 0
                                      ? '0 دقيقة'
                                      : '${mins > 0 ? '+' : ''}$mins د',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: mins == 0
                                        ? (isDark
                                            ? Colors.white70
                                            : Colors.black87)
                                        : const Color(0xFFD64463),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 24),
                                color: const Color(0xFFD64463),
                                onPressed: () {
                                  setSheetState(() {
                                    _prayerLogic.prayerOffsets[entry.key] =
                                        (mins + 1) * 60;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        _prayerLogic.saveCalculationSettings();
                        setState(() {});
                        Get.back();
                        _showSnackBar('تم حفظ تعديلات المواقيت بنجاح');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64463),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showIqamaOffsetsSheet() {
    final Map<String, String> prayerNames = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E28) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'هذه الإقامة (دقائق بعد الأذان)',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            for (var key in prayerNames.keys) {
                              _prayerLogic.iqamaOffsets[key] = 0;
                            }
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'إعادة ضبط',
                          style: TextStyle(fontFamily: 'Amiri'),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD64463),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'حدد عدد دقائق الإقامة بعد الأذان لكل صلاة لعرض عد تنازلي دقيق',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      children: prayerNames.entries.map((entry) {
                        final int offsetMin =
                            _prayerLogic.iqamaOffsets[entry.key] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF282836)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 24),
                                color: const Color(0xFFD64463),
                                onPressed: () {
                                  setSheetState(() {
                                    final current =
                                        _prayerLogic.iqamaOffsets[entry.key] ??
                                            0;
                                    _prayerLogic.iqamaOffsets[entry.key] =
                                        current > 0 ? current - 1 : 0;
                                  });
                                },
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 80),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: offsetMin == 0
                                      ? (isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200)
                                      : const Color(0xFFD64463)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  offsetMin == 0
                                      ? 'بدون إقامة'
                                      : '+$offsetMin دقيقة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: offsetMin == 0
                                        ? (isDark
                                            ? Colors.white70
                                            : Colors.black87)
                                        : const Color(0xFFD64463),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 24),
                                color: const Color(0xFFD64463),
                                onPressed: () {
                                  setSheetState(() {
                                    final current =
                                        _prayerLogic.iqamaOffsets[entry.key] ??
                                            0;
                                    _prayerLogic.iqamaOffsets[entry.key] =
                                        current + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        _prayerLogic.saveCalculationSettings();
                        setState(() {});
                        Get.back();
                        _showSnackBar('تم حفظ إعدادات الإقامة بنجاح');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64463),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showHijriAdjustmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E28) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تعديل التاريخ الهجري',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'قم بتقديم أو تأخير التاريخ الهجري يوماً أو أكثر لمطابقة الرؤية الشرعية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF282836)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.remove_rounded, size: 24),
                          color: const Color(0xFFD64463),
                          onPressed: () {
                            setSheetState(() => _prayerLogic.hijriOffset--);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              Text(
                                _prayerLogic.hijriOffset == 0
                                    ? '0'
                                    : '${_prayerLogic.hijriOffset > 0 ? '+' : ''}${_prayerLogic.hijriOffset}',
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD64463),
                                ),
                              ),
                              Text(
                                _prayerLogic.hijriOffset == 0
                                    ? 'بدون تعديل'
                                    : '${_prayerLogic.hijriOffset.abs()} يوم',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded, size: 24),
                          color: const Color(0xFFD64463),
                          onPressed: () {
                            setSheetState(() => _prayerLogic.hijriOffset++);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        _prayerLogic.saveCalculationSettings();
                        setState(() {});
                        Get.back();
                        _showSnackBar('تم حفظ تعديل التاريخ الهجري');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64463),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAboutSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E28) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Image.asset(icLauncher, width: 64, height: 64),
              const SizedBox(height: 8),
              const Text(
                'حصن المسلم',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'الإصدار $aboutVersion • تطبيق إسلامي مفتوح المصدر',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD64463).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD64463).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  do3aa,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildAboutTile(
                icon: SimpleIcons.google,
                title: offielWebSite,
                subtitle: offielWebSiteIbnWahf,
                onTap: () => openURL(oficialWebSiteLink),
              ),
              const SizedBox(height: 8),
              _buildAboutTile(
                icon: SimpleIcons.github,
                title: sourceCode,
                subtitle: 'المستودع البرمجي للتطبيق على GitHub',
                onTap: () => openURL(githubLink),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAboutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282836) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFFD64463)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 18, color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }

  void _showCustomBottomSheet({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E28) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
      isScrollControlled: true,
);
    }

  // --- UI Layout Builder ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final homeScreenTitle =
        _homeScreenMeta[_selectedHomeScreen]?.title ?? 'الأذكار';
    final calcMethodTitle =
        _calculationMethods[_prayerLogic.angles]?.title ?? 'أم القرى';
    final asrMethodTitle =
        _asrMethods[_prayerLogic.asrMethod]?.title ?? 'الجمهور (شافعي)';

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
              'الإعدادات والتفضيلات',
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
                // Section 1: Appearance & General
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'المظهر والتفضيلات العامة',
                  icon: Icons.palette_outlined,
                  color: const Color(0xFF8B5CF6),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: 'الوضع الداكن',
                      subtitle: _darkModeEnabled
                          ? 'المظهر الليلي مفعّل لراحة العين'
                          : 'المظهر النهاري الفاتح مفعّل',
                      icon: _darkModeEnabled
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      value: _darkModeEnabled,
                      onChanged: _toggleDarkMode,
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildValueTile(
                      context: context,
                      title: 'الواجهة الافتراضية',
                      subtitle: 'الصفحة التي تظهر عند تشغيل التطبيق',
                      icon: Icons.home_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      valueBadge: homeScreenTitle,
                      onTap: _showHomeScreenPicker,
                    ),
                  ],
                ), // Section 2: Interaction & Misbaha
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'المسبحة والتفاعل',
                  icon: Icons.touch_app_outlined,
                  color: const Color(0xFFEC4899),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: 'صوت النقرة',
                      subtitle: 'تشغيل صوت خفيف عند الضغط على المسبحة',
                      icon: Icons.volume_up_rounded,
                      iconColor: const Color(0xFFEC4899),
                      value: _clickSoundEnabled,
                      onChanged: _toggleClickSound,
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: 'الاهتزاز اللمسي',
                      subtitle: 'اهتزاز الهاتف عند كل تسبيحة للتأكيد',
                      icon: Icons.vibration_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      value: _vibrationEnabled,
                      onChanged: _toggleVibration,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 3: Periodic Dhikr Reminders (Overlay)
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'التذكير التلقائي بالأذكار',
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFF10B981),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: 'أذكار عائمة دورية',
                      subtitle: 'ظهور نافذة ذكر قصيرة تلقائياً فوق التطبيقات',
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF10B981),
                      value: _reminderEnabled,
                      onChanged: _toggleReminder,
                    ),
                    if (_reminderEnabled) ...[
                      SettingsWidgets.buildDivider(context),
                      SettingsWidgets.buildValueTile(
                        context: context,
                        title: 'وتيرة التذكير',
                        subtitle: 'الفترة الفاصلة بين كل ذكر وآخر',
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF10B981),
                        valueBadge: _reminderInterval >= 60
                            ? 'كل ساعة'
                            : 'كل $_reminderInterval دقيقة',
                        onTap: _showIntervalPicker,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Section 4: Prayer Times & Data Source
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'مواقيت الصلاة ومصدر البيانات',
                  icon: Icons.mosque_outlined,
                  color: const Color(0xFFD64463),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    // Source Selector Tile
                    SettingsWidgets.buildValueTile(
                      context: context,
                      title: 'مصدر مواقيت الصلاة',
                      subtitle: _prayerLogic.prayerTimeSource ==
                              PrayerTimeSource.mosque
                          ? 'مواقيت المسجد (أونلاين مع كاش)'
                          : 'مواقيت محسوبة فلكياً (أوفلاين)',
                      icon: _prayerLogic.prayerTimeSource ==
                              PrayerTimeSource.mosque
                          ? Icons.mosque_rounded
                          : Icons.calculate_outlined,
                      iconColor: const Color(0xFFD64463),
                      valueBadge: _prayerLogic.prayerTimeSource ==
                              PrayerTimeSource.mosque
                          ? 'مواقيت المسجد'
                          : 'محسوبة',
                      onTap: _showPrayerSourcePicker,
                    ),
                    SettingsWidgets.buildDivider(context),

                    // If Mosque Mode is active: Show selected mosque info
                    if (_prayerLogic.prayerTimeSource ==
                        PrayerTimeSource.mosque) ...[
                      SettingsWidgets.buildActionTile(
                        context: context,
                        title: _prayerLogic.selectedMosque != null
                            ? _prayerLogic.selectedMosque!.name
                            : 'لم يتم تحديد مسجد بعد',
                        subtitle: _prayerLogic.selectedMosque != null
                            ? 'المدينة: ${_prayerLogic.selectedMosque!.city} • انقر للتغيير'
                            : 'انقر لفتح الخريطة واختيار مسجدك',
                        icon: Icons.map_rounded,
                        iconColor: const Color(0xFFD64463),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD64463)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _prayerLogic.selectedMosque != null
                                ? 'تغيير المسجد'
                                : 'اختيار مسجد',
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD64463),
                            ),
                          ),
                        ),
                        onTap: () => Get.to(() => const MosqueMapScreen()),
                      ),
                      SettingsWidgets.buildDivider(context),
                    ],

                    // Location Tile
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: 'الموقع الجغرافي (GPS)',
                      subtitle:
                          'الإحداثيات: ${_prayerLogic.lat.toStringAsFixed(3)}, ${_prayerLogic.lon.toStringAsFixed(3)}',
                      icon: Icons.my_location_rounded,
                      iconColor: const Color(0xFFD64463),
                      trailing: _isRefreshingLocation
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFD64463)),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD64463)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      size: 16, color: Color(0xFFD64463)),
                                  SizedBox(width: 4),
                                  Text(
                                    'تحديث',
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD64463),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      onTap: _isRefreshingLocation ? null : _refreshGpsLocation,
                    ),
                    SettingsWidgets.buildDivider(context),

                    // Calculation Method
                    SettingsWidgets.buildValueTile(
                      context: context,
                      title: 'طريقة الحساب',
                      subtitle: 'الهيئة الفلكية المعتمدة لزوايا الفجر والعشاء',
                      icon: Icons.calculate_outlined,
                      iconColor: const Color(0xFFD64463),
                      valueBadge: calcMethodTitle,
                      onTap: _showCalculationMethodPicker,
                    ),
                    SettingsWidgets.buildDivider(context),

                    // Asr Method
                    SettingsWidgets.buildValueTile(
                      context: context,
                      title: 'مذهب صلاة العصر',
                      subtitle: 'معيار تحديد ظل الزوال لدخول وقت العصر',
                      icon: Icons.wb_twilight_rounded,
                      iconColor: const Color(0xFFD64463),
                      valueBadge: asrMethodTitle,
                      onTap: _showAsrMethodPicker,
                    ),
                    SettingsWidgets.buildDivider(context),

                    // Daylight Saving Time (DST)
                    SettingsWidgets.buildSwitchTile(
                      context: context,
                      title: 'التوقيت الصيفي',
                      subtitle: 'إضافة ساعة واحدة لمواقيت الصلاة تلقائياً',
                      icon: Icons.wb_sunny_outlined,
                      iconColor: const Color(0xFFD64463),
                      value: _prayerLogic.dstEnabled,
                      onChanged: (val) {
                        setState(() => _prayerLogic.dstEnabled = val);
                        _prayerLogic.saveCalculationSettings();
                      },
                    ),
                    SettingsWidgets.buildDivider(context),

                    // Manual Prayer Offsets
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: 'تعديل المواقيت يدوياً',
                      subtitle: 'زيادة أو إنقاص دقائق لتطابق أذان منطقتك',
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFFD64463),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: _showManualAdjustmentSheet,
                    ),
                    SettingsWidgets.buildDivider(context),

                    // Iqama Offsets (calculated mode only)
                    if (_prayerLogic.prayerTimeSource ==
                        PrayerTimeSource.calculated)
                      SettingsWidgets.buildActionTile(
                        context: context,
                        title: 'هذه الإقامة',
                        subtitle: 'تحديد دقائق الإقامة بعد الأذان لكل صلاة',
                        icon: Icons.groups_rounded,
                        iconColor: const Color(0xFFD64463),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: Colors.grey),
                        onTap: _showIqamaOffsetsSheet,
                      ),
                    if (_prayerLogic.prayerTimeSource ==
                        PrayerTimeSource.calculated)
                      SettingsWidgets.buildDivider(context),

                    // Hijri Date Adjustment
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: 'تعديل التاريخ الهجري',
                      subtitle: _prayerLogic.hijriOffset == 0
                          ? 'التاريخ مطابق للحساب الفلكي'
                          : 'معدّل بـ (${_prayerLogic.hijriOffset > 0 ? '+' : ''}${_prayerLogic.hijriOffset} يوم)',
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFFD64463),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _prayerLogic.hijriOffset == 0
                              ? (isDark ? Colors.white10 : Colors.grey.shade200)
                              : const Color(0xFFD64463).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _prayerLogic.hijriOffset == 0
                              ? 'تعديل'
                              : '${_prayerLogic.hijriOffset > 0 ? '+' : ''}${_prayerLogic.hijriOffset} يوم',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _prayerLogic.hijriOffset == 0
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : const Color(0xFFD64463),
                          ),
                        ),
                      ),
                      onTap: _showHijriAdjustmentSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 5: Notifications & Alarms Hub
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'التنبيهات والأذان',
                  icon: Icons.alarm_on_outlined,
                  color: const Color(0xFF06B6D4),
                ),
                _buildNotificationHubCard(),
                const SizedBox(height: 20),

                // Section 6: About & Community
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: 'حول التطبيق والمشاركة',
                  icon: Icons.info_outline_rounded,
                  color: const Color(0xFF64748B),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: 'عن حصن المسلم والإصدار',
                      subtitle: 'الإصدار $aboutVersion • مفتوح المصدر',
                      icon: Icons.info_rounded,
                      iconColor: const Color(0xFF64748B),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      onTap: _showAboutSheet,
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: 'الموقع الرسمي للشيخ سعيد بن وهف',
                      subtitle: 'مؤلف كتاب حصن المسلم رحمه الله',
                      icon: SimpleIcons.google,
                      iconColor: const Color(0xFF4285F4),
                      trailing: const Icon(Icons.open_in_new_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () => openURL(oficialWebSiteLink),
                    ),
                    SettingsWidgets.buildDivider(context),
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: 'المشروع على GitHub',
                      subtitle: 'مساهمة في التطوير وكود المصدر',
                      icon: SimpleIcons.github,
                      iconColor: isDark ? Colors.white : Colors.black87,
                      trailing: const Icon(Icons.open_in_new_rounded,
                          size: 16, color: Colors.grey),
                      onTap: () => openURL(githubLink),
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

  Widget _buildNotificationHubCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E1E28) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => Get.to(() => const NotificationSettingsScreen()),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.notifications_active_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تخصيص التنبيهات والأذان',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الإشعار الدائم، تحدي الفجر، وتنبيهات أذكار الصباح والمساء',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
