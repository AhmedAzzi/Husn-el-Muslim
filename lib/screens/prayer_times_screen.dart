import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            leading: widget.isHomeScreen
                ? null
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
                  if (!mounted) return;
                  setState(() {
                    _logic.displayDate();
                    _updateNextPrayer();
                  });
                  if (context.mounted) {
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.001;

    // Loading State
    if (_logic.isLoadingLocation || _logic.isLoadingPrayerTimes) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: const Color(0xFFD64463).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Color(0xFFD64463),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'جاري تحميل مواقيت الصلاة...',
              style: TextStyle(
                fontFamily: 'Amiri',
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: screenWidth * 0.045,
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
          padding: EdgeInsets.all(screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.08),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_outlined,
                  color: Colors.white54,
                  size: screenWidth * 0.18,
                ),
              ),
              SizedBox(height: screenHeight * 0.035),
              Text(
                'تعذر جلب مواقيت الصلاة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                'تأكد من تفعيل خدمات الموقع والاتصال بالإنترنت',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: screenWidth * 0.04,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.04),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: Icon(Icons.refresh_rounded, size: screenWidth * 0.055),
                label: Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: screenWidth * 0.045,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: screenHeight * 0.02),

            // Date Display moved to top
            Center(
              child: Container(
                // margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                padding: EdgeInsets.symmetric(
                  horizontal:
                      screenWidth * 0.02, // Reduced padding to maximize space
                  vertical: screenHeight * 0.012,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C35).withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black12,
                    width: 1,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _logic.hijriDate,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: screenWidth * 0.038,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.95)
                                : const Color(0xFF2D3142),
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: ' | ${_logic.gregorianDate} م',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: screenWidth * 0.038,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.95)
                                : const Color(0xFF2D3142)
                                    .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // NEW HEADER STRUCTURE
            _buildNewHeader(screenWidth, screenHeight),

            // SizedBox(height: screenHeight * 0.001),

            // PRAYER LIST CARD
            if (_logic.prayerTimes != null)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C35) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.02,
                ),
                child: Column(
                  children: _buildPrayerList(screenWidth, screenHeight),
                ),
              ),

            // SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildNewHeader(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: SizedBox(
        height: screenHeight * 0.20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Row(
                children: [
                  // RIGHT SIDE: Text Info (In RTL this is the "Start")
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Prayer Name with enhanced styling
                        if (_nextPrayerInfo['name'].isNotEmpty)
                          Container(
                            padding:
                                EdgeInsets.only(bottom: screenHeight * 0.005),
                            child: Text(
                              '${_nextPrayerInfo['name']} بعد',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: screenWidth * 0.08,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                    color: Colors.black.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(height: screenHeight * 0.01),
                        if (_nextPrayerInfo['timeRemaining'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: const Color(0xFFD64463),
                                  size: screenWidth * 0.05,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  '${_nextPrayerInfo['timeRemaining']}',
                                  style: TextStyle(
                                    fontFamily: 'tajawal',
                                    fontSize: screenWidth * 0.065,
                                    color: const Color(0xFF1A1A2E),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // // Countdown Timer with enhanced visibility
                        // if (_nextPrayerInfo['timeRemaining'] != null)
                        //   Container(
                        //     padding: EdgeInsets.symmetric(
                        //       vertical: screenHeight * 0.004,
                        //     ),
                        //     child: Text(
                        //       _nextPrayerInfo['timeRemaining'],
                        //       style: TextStyle(
                        //         fontFamily: 'Tajawal',
                        //         fontSize: screenWidth * 0.10,
                        //         color: Colors.white,
                        //         fontWeight: FontWeight.w600,
                        //         height: 1.1,
                        //         letterSpacing: -1.5,
                        //         shadows: [
                        //           Shadow(
                        //             offset: Offset(0, 3),
                        //             blurRadius: 12,
                        //             color: Colors.black.withOpacity(0.4),
                        //           ),
                        //         ],
                        //       ),
                        //       textDirection: TextDirection.ltr,
                        //     ),
                        //   ),

                        // SizedBox(height: screenHeight * 0.008),
                      ],
                    ),
                  ),

                  // LEFT SIDE: Progress/Icon (In RTL this is the "End")
                  Expanded(
                    flex: 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow effect (static)
                        Container(
                          width: screenWidth * 0.25,
                          height: screenWidth * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),

                        // Progress ring with enhanced styling
                        SizedBox(
                          width: screenWidth * 0.24,
                          height: screenWidth * 0.24,
                          child: CircularProgressIndicator(
                            value: _calculateProgress(),
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orangeAccent.withValues(alpha: 0.9),
                            ),
                          ),
                        ),

                        // Inner circle background
                        Container(
                          width: screenWidth * 0.18,
                          height: screenWidth * 0.18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                        ),

                        // Icon with shadow
                        Icon(
                          _getNextPrayerIcon(),
                          color: Colors.orangeAccent,
                          size: screenWidth * 0.11,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 6,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgress() {
    if (_logic.prayerTimes == null || _logic.prayerTimes!.isEmpty) return 0;

    final now = DateTime.now();
    final prayers = _logic.prayerTimes!;

    // Find next prayer index
    int nextIndex = -1;
    for (int i = 0; i < prayers.length; i++) {
      if (prayers[i].time.isAfter(now)) {
        nextIndex = i;
        break;
      }
    }

    DateTime startTime;
    DateTime endTime;

    if (nextIndex == -1) {
      // Waiting for Fajr tomorrow
      startTime = prayers.last.time;
      final fajrToday = prayers.firstWhere((p) => p.name == 'Fajr',
          orElse: () => prayers.first);
      endTime = fajrToday.time.add(const Duration(days: 1));
    } else if (nextIndex == 0) {
      // Waiting for Fajr today
      endTime = prayers.first.time;
      final ishaToday = prayers.lastWhere((p) => p.name == 'Isha',
          orElse: () => prayers.last);
      startTime = ishaToday.time.subtract(const Duration(days: 1));
    } else {
      endTime = prayers[nextIndex].time;
      startTime = prayers[nextIndex - 1].time;
    }

    final totalDuration = endTime.difference(startTime).inSeconds;
    final elapsed = now.difference(startTime).inSeconds;

    if (totalDuration == 0) return 0.0;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  List<Widget> _buildPrayerList(double screenWidth, double screenHeight) {
    if (_logic.prayerTimes == null) return [];

    final nextPrayerName = _nextPrayerInfo['name'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final arabicNames = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
      'First Third': 'الثلث الأول',
      'Midnight': 'منتصف الليل',
      'Last Third': 'الثلث الأخير',
    };

    final nightPrayerNames = ['First Third', 'Midnight', 'Last Third'];

    // Separate main and night prayers
    final mainPrayers = _logic.prayerTimes!
        .where((p) => !nightPrayerNames.contains(p.name))
        .toList();
    final nightPrayers = _logic.prayerTimes!
        .where((p) => nightPrayerNames.contains(p.name))
        .toList();

    Widget buildPrayerItem(dynamic prayer) {
      final arabicName = arabicNames[prayer.name] ?? prayer.name;
      final isNext = arabicName == nextPrayerName;

      return Builder(builder: (context) {
        final textColor = isDark ? Colors.white : Colors.black;
        final activeColor = const Color(0xFFD64463);

        return Container(
          // margin:
          //     EdgeInsets.symmetric(vertical: 2, horizontal: screenWidth * 0.02),
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.015,
            horizontal: screenWidth * 0.03,
          ),
          decoration: BoxDecoration(
            color: isNext
                ? (isDark
                    ? activeColor.withValues(alpha: 0.2)
                    : activeColor.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Icon (Left)
              Icon(
                _getPrayerIconFromName(prayer.name),
                color: isNext ? activeColor : Colors.orangeAccent,
                size: screenWidth * 0.06,
              ),

              SizedBox(width: screenWidth * 0.03),
              // Name
              Text(
                arabicName,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: isNext ? activeColor : textColor,
                ),
              ),

              const Spacer(),

              // Time
              Text(
                _formatTime24H(prayer.time),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: isNext ? activeColor : textColor,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),

              // Sound (Right)
              GestureDetector(
                onTap: () async {
                  // if (prayer.name == 'Sunrise') return;
                  setState(() {
                    final currentStatus =
                        _logic.prayerNotificationsEnabled[arabicName] ?? true;
                    _logic.prayerNotificationsEnabled[arabicName] =
                        !currentStatus;

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
                child: Icon(
                  (_logic.prayerNotificationsEnabled[arabicName] ?? true)
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: isNext
                      ? activeColor
                      : (isDark ? Colors.white70 : Colors.grey),
                  size: screenWidth * 0.06,
                ),
              )
            ],
          ),
        );
      });
    }

    final List<Widget> widgets = mainPrayers.map(buildPrayerItem).toList();

    // Night Prayers Section
    widgets.addAll(nightPrayers.map(buildPrayerItem));

    return widgets;
  }

  IconData _getPrayerIconFromName(String name) {
    switch (name) {
      case 'Fajr':
        return Icons.brightness_low_rounded;
      case 'Sunrise':
        return Icons.wb_sunny_rounded;
      case 'Dhuhr':
        return Icons.wb_sunny_outlined;
      case 'Asr':
        return Icons.wb_twilight_rounded;
      case 'Maghrib':
        return Icons.brightness_medium_rounded;
      case 'Isha':
        return Icons.brightness_2_rounded;
      case 'First Third':
        return Icons.brightness_3_rounded;
      case 'Midnight':
        return Icons.nightlight_round;
      case 'Last Third':
        return Icons.star_border_rounded;
      default:
        return Icons.access_time_filled_rounded;
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
      case 'الثلث الأول':
        return Icons.brightness_3_rounded;
      case 'الليل':
        return Icons.nightlight_round;
      case 'الثلث الأخير':
        return Icons.star_border_rounded;
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
