import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/features/azkar/presentation/home_page.dart';
import 'package:small_husn_muslim/features/masbaha/presentation/custom_dikr_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/core/config/app_config.dart';
import 'package:small_husn_muslim/core/services/notification_service.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';

/// ─────────────────────────────────────────────────────────────
/// Data model for a single permission item
/// ─────────────────────────────────────────────────────────────
class _PermissionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  bool isGranted = false;

  _PermissionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// ─────────────────────────────────────────────────────────────
/// Onboarding Screen
/// ─────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final List<_PermissionItem> _permissions;
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _checkController;
  final _logic = Get.find<PrayerTimesLogic>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _permissions = [
      _PermissionItem(
        title: 'الإشعارات',
        subtitle: 'لتنبيهك بأوقات الصلاة والأذكار',
        icon: Icons.notifications_active_rounded,
      ),
      _PermissionItem(
        title: 'الموقع الجغرافي',
        subtitle: 'لتحديد مواقيت الصلاة بدقة حسب موقعك',
        icon: Icons.location_on_rounded,
      ),
      _PermissionItem(
        title: 'العرض فوق التطبيقات',
        subtitle: 'لعرض الأذكار والآيات تلقائياً على الشاشة',
        icon: Icons.layers_rounded,
      ),
    ];

    // Entrance stagger (0→1 over 900ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Infinite soft pulse for the next un-granted card
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Quick pop for the checkmark
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Start entrance
    _entranceController.forward();

    // Check initial states
    _recheckAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entranceController.dispose();
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  /// Re-check when coming back from Android settings (overlay permission).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckAll();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Permission Checks
  // ─────────────────────────────────────────────────────────────

  Future<void> _recheckAll() async {
    // 1. Notifications
    final notifPlugin = FlutterLocalNotificationsPlugin();
    final androidPlugin = notifPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.areNotificationsEnabled() ?? false;
      _permissions[0].isGranted = granted;
    }

    // 2. Location
    final locPerm = await Geolocator.checkPermission();
    _permissions[1].isGranted = locPerm == LocationPermission.always ||
        locPerm == LocationPermission.whileInUse;

    // 3. Overlay
    final overlayGranted =
        await PrayerNotificationHelper.checkOverlayPermission();
    _permissions[2].isGranted = overlayGranted;

    if (mounted) setState(() {});
  }

  Future<void> _requestPermission(int index) async {
    switch (index) {
      case 0:
        await _requestNotifications();
        break;
      case 1:
        await _requestLocation();
        break;
      case 2:
        await _requestOverlay();
        break;
    }
    if (mounted) setState(() {});
  }

  Future<void> _requestNotifications() async {
    await NotificationService().requestPermissions();
    await _recheckAll();
  }

  Future<void> _requestLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    _permissions[1].isGranted = perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;

    // Upgrade to background location if on Android 10+ and only foreground was granted
    if (_permissions[1].isGranted && perm == LocationPermission.whileInUse) {
      await _logic.requestBackgroundLocation();
      // Re-fetch to see if they granted "Always"
      final finalPerm = await Geolocator.checkPermission();
      _permissions[1].isGranted = finalPerm == LocationPermission.always ||
          finalPerm == LocationPermission.whileInUse;
    }
  }

  Future<void> _requestOverlay() async {
    await PrayerNotificationHelper.requestOverlayPermission();
    // Will re-check on lifecycle resume
  }

  // ─────────────────────────────────────────────────────────────
  //  Navigation
  // ─────────────────────────────────────────────────────────────

  bool get _allGranted => _permissions.every((p) => p.isGranted);

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    _navigateToHome(prefs);
  }

  void _navigateToHome(SharedPreferences prefs) {
    final savedHome = prefs.getString('home_screen') ?? homeScreenAzkar;
    Widget home;
    switch (savedHome) {
      case homeScreenMisbaha:
        home = const CustomDikrScreen(isHomeScreen: true);
        break;
      case homeScreenPrayerTimes:
        home = const PrayerTimesScreen(isHomeScreen: true);
        break;
      default:
        final isDark = prefs.getBool('dark_mode') ?? true;
        home = MyHomePageScreen(isDarkMode: isDark);
    }
    Get.offAll(() => home);
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Find the first un-granted index (to pulse it)
    int nextIndex = _permissions.indexWhere((p) => !p.isGranted);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF111118),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1028),
                  Color(0xFF111118),
                  Color(0xFF0D0D14),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // ── App Icon ──
                    _buildAppIcon(),
                    const SizedBox(height: 28),
                    // ── Welcome Text ──
                    _buildWelcomeHeader(),
                    const SizedBox(height: 12),
                    _buildSubtitle(),
                    const SizedBox(height: 36),
                    // ── Permission Cards ──
                    ...List.generate(_permissions.length, (i) {
                      return _buildPermissionCard(
                        index: i,
                        item: _permissions[i],
                        isNext: i == nextIndex,
                      );
                    }),
                    const SizedBox(height: 32),
                    // ── Continue Button ──
                    _buildContinueButton(),
                    const SizedBox(height: 14),
                    // ── Skip ──
                    _buildSkipButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  UI Components
  // ─────────────────────────────────────────────────────────

  Widget _buildAppIcon() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, child) {
        final t = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ).value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1F3D), Color(0xFF1A1528)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/ic_launcher.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, child) {
        final t = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.1, 0.55, curve: Curves.easeOut),
        ).value;
        return Opacity(opacity: t, child: child);
      },
      child: Column(
        children: [
          Text(
            'بسم الله الرحمن الرحيم',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 22,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'مرحباً بك في حصن المسلم',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, child) {
        final t = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
        ).value;
        return Opacity(opacity: t, child: child);
      },
      child: Text(
        'نحتاج إلى بعض الأذونات لتعمل جميع المميزات بشكل صحيح',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 16,
          color: Colors.white.withValues(alpha: 0.55),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required int index,
    required _PermissionItem item,
    required bool isNext,
  }) {
    // Stagger entrance per card
    final staggerStart = 0.25 + (index * 0.12);
    final staggerEnd = (staggerStart + 0.35).clamp(0.0, 1.0);

    final cardEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(staggerStart, staggerEnd, curve: Curves.easeOut),
    );

    // Colors based on state
    final Color borderColor;
    final Color bgColor;
    final Color iconBgColor;
    final Color iconColor;
    final Color titleColor;

    if (item.isGranted) {
      borderColor = const Color(0xFF2E7D32).withValues(alpha: 0.6);
      bgColor = const Color(0xFF1B2E1B).withValues(alpha: 0.6);
      iconBgColor = const Color(0xFF2E7D32).withValues(alpha: 0.2);
      iconColor = const Color(0xFF66BB6A);
      titleColor = const Color(0xFF81C784);
    } else if (isNext) {
      borderColor = const Color(0xFFD4AF37).withValues(alpha: 0.5);
      bgColor = const Color(0xFF2A2030).withValues(alpha: 0.7);
      iconBgColor = const Color(0xFFD4AF37).withValues(alpha: 0.15);
      iconColor = const Color(0xFFD4AF37);
      titleColor = Colors.white;
    } else {
      borderColor = Colors.white.withValues(alpha: 0.08);
      bgColor = Colors.white.withValues(alpha: 0.04);
      iconBgColor = Colors.white.withValues(alpha: 0.06);
      iconColor = Colors.white.withValues(alpha: 0.35);
      titleColor = Colors.white.withValues(alpha: 0.45);
    }

    Widget card = AnimatedBuilder(
      animation: cardEntrance,
      builder: (_, child) {
        return Opacity(
          opacity: cardEntrance.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - cardEntrance.value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: item.isGranted ? null : () => _requestPermission(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: item.isGranted
                ? [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ]
                : isNext
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFD4AF37).withValues(alpha: 0.08),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
          ),
          child: Row(
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.4),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status indicator
              _buildStatusIndicator(item.isGranted, isNext),
            ],
          ),
        ),
      ),
    );

    // Wrap the "next" card with a subtle pulse
    if (isNext && !item.isGranted) {
      card = AnimatedBuilder(
        animation: _pulseController,
        builder: (_, child) {
          final t = _pulseController.value;
          return Transform.scale(
            scale: 1.0 + (t * 0.012),
            child: child,
          );
        },
        child: card,
      );
    }

    return card;
  }

  Widget _buildStatusIndicator(bool granted, bool isNext) {
    if (granted) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
          border: Border.all(
            color: const Color(0xFF66BB6A).withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF66BB6A),
          size: 20,
        ),
      );
    }

    if (isNext) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
          size: 18,
        ),
      );
    }

    // Pending (future item)
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final enabled = _allGranted;
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, child) {
        final t = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
        ).value;
        return Opacity(opacity: t, child: child);
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFC29B2A)],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: enabled ? _completeOnboarding : null,
              child: Center(
                child: Text(
                  'متابعة',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? const Color(0xFF1A1528)
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, child) {
        final t = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
        ).value;
        return Opacity(opacity: t, child: child);
      },
      child: TextButton(
        onPressed: _completeOnboarding,
        child: Text(
          'تخطي',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.3),
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }
}
