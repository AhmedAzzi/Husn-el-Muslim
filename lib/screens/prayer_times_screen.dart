import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:small_husn_muslim/constants/strings.dart';
import 'package:small_husn_muslim/constants/colors.dart';
import '../models/prayer_times_logic.dart';
import '../utils.dart';
import 'home_page.dart';
import 'custom_dikr_screen.dart';
import 'settings_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  final bool isHomeScreen;

  const PrayerTimesScreen({super.key, this.isHomeScreen = false});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerTimesLogic _logic = PrayerTimesLogic();
  Timer? _timer;
  Map<String, dynamic> _nextPrayerInfo = {'name': '', 'timeRemaining': ''};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await NotificationService().init();
    await _logic.loadNotificationPreference();
    await _logic.ensureDataLoaded();
    _logic.displayDate();
    _updateNextPrayer();

    // Update persistent notification on start if enabled
    if (_logic.persistentNotificationEnabled) {
      _logic.updatePersistentNotification();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _logic.displayDate();
          _updateNextPrayer();
        });
      }
    });

    if (mounted) setState(() {});
  }

  void _updateNextPrayer() {
    _nextPrayerInfo = _logic.getNextPrayerInfo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            leading: widget.isHomeScreen
                ? null // Let drawer icon show automatically
                : IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: theme.appBarTheme.foregroundColor),
                    onPressed: () => Get.back(),
                  ),
            title: Text(
              'مواقيت الصلاة',
              style: TextStyle(
                fontFamily: 'Amiri',
                color: theme.appBarTheme.foregroundColor,
                fontSize: 24,
                // fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.my_location,
                    color: theme.appBarTheme.foregroundColor),
                onPressed: () async {
                  setState(() {
                    _logic.isLoadingLocation = true;
                    _logic.isLoadingPrayerTimes = true;
                  });
                  await _logic.ensureDataLoaded(force: true);
                  if (mounted) {
                    setState(() {
                      _logic.displayDate();
                      _updateNextPrayer();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث الموقع بنجاح')),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(appBarBG),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          drawer: widget.isHomeScreen
              ? Drawer(
                  width: screenSize.width - 100,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      DrawerHeader(
                        child:
                            Center(child: Image(image: AssetImage(icLauncher))),
                      ),
                      ListTile(
                        leading: const Icon(Icons.list_rounded),
                        title: Text(
                          adkar,
                          style: TextStyle(
                            fontSize: double.parse(fontSize18),
                            fontFamily: fontFamily,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        onTap: () {
                          Get.back();
                          Get.to(() => const MyHomePageScreen(
                              isRoot: false, isHomeScreen: false));
                        },
                      ),
                      const Divider(thickness: 0.3),
                      ListTile(
                        leading: const Icon(Icons.bubble_chart),
                        title:
                            const Text('مسبحة', style: TextStyle(fontSize: 18)),
                        onTap: () {
                          Get.back();
                          Get.to(() => const CustomDikrScreen());
                        },
                      ),
                      const Divider(thickness: 0.3),
                      ListTile(
                        leading: const Icon(Icons.access_time_filled_rounded),
                        title: const Text('مواقيت الصلاة',
                            style: TextStyle(fontSize: 18)),
                        onTap: () => Get.back(),
                      ),
                      const Divider(thickness: 0.3),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('الإعدادات',
                            style: TextStyle(fontSize: 18)),
                        onTap: () {
                          Get.back();
                          Get.to(() => const SettingsScreen());
                        },
                      ),
                      const Divider(thickness: 0.3),
                      ListTile(
                        onTap: () {
                          Get.dialog(
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Theme(
                                data: Get.isDarkMode
                                    ? ThemeData.dark()
                                    : ThemeData.light(),
                                child: AlertDialog(
                                  backgroundColor:
                                      Get.isDarkMode ? bgDark : bgLight,
                                  title: Text(
                                    about,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      color: Get.isDarkMode ? bgLight : bgDark,
                                    ),
                                  ),
                                  content: SizedBox(
                                    height: 450,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: Image.asset(
                                            icLauncher,
                                            scale: 3,
                                          ),
                                          title: Text(aboutVersion),
                                          subtitle: Text(aboutOpenSource),
                                        ),
                                        const Divider(),
                                        ListTile(
                                          title: Text(
                                            do3aa,
                                            style: TextStyle(
                                                fontFamily: fontFamily,
                                                fontSize:
                                                    double.parse(fontSize24)),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const Divider(),
                                        ListTile(
                                          leading:
                                              const Icon(SimpleIcons.google),
                                          title: Text(offielWebSite),
                                          subtitle: Text(
                                            offielWebSiteIbnWahf,
                                            style: TextStyle(
                                              fontFamily: fontFamily,
                                            ),
                                          ),
                                          onTap: () {
                                            openURL(oficialWebSiteLink);
                                          },
                                        ),
                                        const Divider(),
                                        ListTile(
                                          leading:
                                              const Icon(SimpleIcons.github),
                                          title: Text(sourceCode),
                                          onTap: () async {
                                            await openURL(
                                              githubLink,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                      },
                                      child: Text(
                                        leave,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          color:
                                              Get.isDarkMode ? bgLight : bgDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        leading: const Icon(Icons.info_rounded),
                        title: Text(
                          about,
                          style: TextStyle(
                            fontFamily: fontFamily,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      const Divider(thickness: 0.3),
                    ],
                  ),
                )
              : null,
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Loading State
    if (_logic.isLoadingLocation || _logic.isLoadingPrayerTimes) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD64463).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Color(0xFFD64463),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جاري تحميل مواقيت الصلاة...',
              style: TextStyle(
                fontFamily: 'Amiri',
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Error State
    if (_logic.prayerTimes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  color: Colors.white54,
                  size: 72,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'تعذر جلب مواقيت الصلاة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'تأكد من تفعيل خدمات الموقع والاتصال بالإنترنت',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _logic.isLoadingLocation = true;
                    _logic.isLoadingPrayerTimes = true;
                  });
                  _initializeData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD64463),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Success State - Prayer Times Display
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MAIN HEADER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFD64463).withOpacity(0.2),
                    const Color(0xFFD64463).withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD64463).withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Date Info (moved to bottom of card)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_logic.hijriDate}، ${_logic.gregorianDate}',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      // LEFT SIDE - Prayer Info
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Prayer Name
                            if (_nextPrayerInfo['name'].isNotEmpty)
                              Text(
                                '${_nextPrayerInfo['name']} خلال',
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 24, // smaller
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            const SizedBox(height: 6), // smaller spacing

                            // Time Remaining
                            if (_nextPrayerInfo['timeRemaining'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, // smaller padding
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_nextPrayerInfo['timeRemaining']}',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 32, // smaller
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // RIGHT SIDE - Icon
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(20), // smaller
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getNextPrayerIcon(),
                            color: Colors.white,
                            size: 42, // smaller icon
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // PRAYER LIST
            if (_logic.prayerTimes != null) ..._buildPrayerList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrayerList() {
    final prayerData = [
      {'name': 'Fajr', 'arabic': 'الفجر'},
      {'name': 'Sunrise', 'arabic': 'الشروق'},
      {'name': 'Dhuhr', 'arabic': 'الظهر'},
      {'name': 'Asr', 'arabic': 'العصر'},
      {'name': 'Maghrib', 'arabic': 'المغرب'},
      {'name': 'Isha', 'arabic': 'العشاء'},
    ];

    final nextPrayerName = _nextPrayerInfo['name'] ?? '';

    return prayerData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final arabicName = data['arabic']!;
      final prayer = _logic.prayerTimes![index];
      final isNext = arabicName == nextPrayerName;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isNext ? const Color(0xFF2C2C35) : const Color(0xFF22222A),
          borderRadius: BorderRadius.circular(16),
          border: isNext
              ? Border.all(color: const Color(0xFFD64463), width: 1.5)
              : null,
          boxShadow: [
            if (isNext)
              BoxShadow(
                color: const Color(0xFFD64463).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Icon(
            _getPrayerIcon(index),
            color: isNext ? const Color(0xFFD64463) : Colors.white54,
            size: 28,
          ),
          title: Text(
            arabicName,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext ? Colors.white : Colors.white70,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime24H(prayer.time),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  color: isNext ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () async {
                  setState(() {
                    final currentStatus =
                        _logic.prayerNotificationsEnabled[arabicName] ?? true;
                    _logic.prayerNotificationsEnabled[arabicName] =
                        !currentStatus;

                    // Update global notifications based on individual states
                    // If all are disabled, disable global; if any is enabled, enable global
                    final anyEnabled = _logic.prayerNotificationsEnabled.values
                        .any((enabled) => enabled);
                    _logic.notificationsEnabled = anyEnabled;
                  });
                  await _logic.saveNotificationPreference(
                    _logic.notificationsEnabled,
                    _logic.prayerNotificationsEnabled,
                    _logic.notificationSoundEnabled,
                  );
                },
                icon: Icon(
                  (_logic.prayerNotificationsEnabled[arabicName] ?? true)
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  color: isNext
                      ? Colors.white
                      : (_logic.prayerNotificationsEnabled[arabicName] ?? true)
                          ? const Color(0xFFD64463)
                          : Colors.grey,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  IconData _getPrayerIcon(int index) {
    switch (index) {
      case 0:
        return Icons.nights_stay; // Fajr
      case 1:
        return Icons.wb_sunny; // Sunrise
      case 2:
        return Icons.wb_sunny_outlined; // Dhuhr
      case 3:
        return Icons.sunny_snowing; // Asr
      case 4:
        return Icons.wb_twilight; // Maghrib
      case 5:
        return Icons.nightlight_round; // Isha
      default:
        return Icons.access_time;
    }
  }

  IconData _getNextPrayerIcon() {
    final prayerName = _nextPrayerInfo['name'] ?? '';
    switch (prayerName) {
      case 'الفجر':
        return Icons.nights_stay_rounded;
      case 'الشروق':
        return Icons.wb_sunny_rounded;
      case 'الظهر':
        return Icons.wb_sunny_outlined;
      case 'العصر':
        return Icons.sunny_snowing;
      case 'المغرب':
        return Icons.wb_twilight_rounded;
      case 'العشاء':
        return Icons.nightlight_round;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _formatTime24H(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
