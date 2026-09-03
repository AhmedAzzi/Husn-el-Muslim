import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/widgets/app_drawer.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/data/mosque_api.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_names.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/mosque_map_screen.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_bottom_sheet.dart';

class PrayerTimesScreen extends StatefulWidget {
  final bool isHomeScreen;

  const PrayerTimesScreen({super.key, this.isHomeScreen = false});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerTimesLogic _logic = Get.find<PrayerTimesLogic>();
  late final PageController _listPageController;
  final Map<int, Future<DayPrayerSummary>> _pageFutures = {};
  final RxInt _currentSwipeDiff = 0.obs;

  @override
  void initState() {
    super.initState();
    _listPageController = PageController(initialPage: 10000);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _logic.loadNotificationPreference();
    await _logic.ensureDataLoaded();
    _logic.displayDate();
  }

  @override
  void dispose() {
    _listPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                icon: Icon(
                  Icons.wb_twilight_rounded,
                  color: _logic.fajrChallengeEnabled
                      ? const Color(0xFFD64463)
                      : theme.appBarTheme.foregroundColor,
                ),
                tooltip: 'تحدي استيقاظ الفجر',
                onPressed: () => showFajrChallengeBottomSheet(context),
              ),
              IconButton(
                icon: Icon(Icons.map_rounded,
                    color: theme.appBarTheme.foregroundColor),
                tooltip: 'خريطة المساجد',
                onPressed: () => Get.to(() => const MosqueMapScreen()),
              ),
              IconButton(
                icon: Icon(Icons.my_location,
                    color: theme.appBarTheme.foregroundColor),
                onPressed: () async {
                  _logic.isLoadingLocation = true;
                  _logic.isLoadingPrayerTimes = true;

                  await _logic.ensureDataLoaded(force: true);

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
          drawer: widget.isHomeScreen ? const AppDrawer() : null,
          body: _buildRootBody(),
        ),
      ),
    );
  }

  Widget _buildRootBody() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Obx(() {
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
      if (_logic.prayerTimes == null || _logic.prayerTimes!.isEmpty) {
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
                    _logic.isLoadingLocation = true;
                    _logic.isLoadingPrayerTimes = true;
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

      // Success State - Fixed Header + Swipable PageView
      return Column(
        children: [
          SizedBox(height: screenHeight * 0.02),
          // Fixed Instant-Updating Date Block
          Obx(() {
            final diffDays = _currentSwipeDiff.value;
            if (diffDays == 0) {
              return _buildDateHeaderWidget(
                DayPrayerSummary(
                  prayerTimes: _logic.prayerTimes!,
                  hijriDate: _logic.hijriDate,
                  gregorianDate: _logic.gregorianDate,
                ),
                isToday: true,
              );
            }
            return FutureBuilder<DayPrayerSummary>(
              future: _getDaySummary(diffDays),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildDateHeaderWidget(
                    DayPrayerSummary(
                      prayerTimes: [],
                      hijriDate: 'يتم التحميل...',
                      gregorianDate: '...',
                    ),
                    isToday: false,
                  );
                }
                return _buildDateHeaderWidget(snapshot.data!, isToday: false);
              },
            );
          }),
          // SizedBox(height: screenHeight * 0.0001), // Reduced from 0.01
          // Fixed Countdown Timer
          _buildNewHeader(screenWidth, screenHeight),
          // Source Tag + Fajr Challenge chip, in one row of equal small size
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Row(
              children: [
                // Prayer time source tag
                Expanded(
                  child: Center(
                    child: Obx(() {
                      final isMosque =
                          _logic.prayerTimeSource == PrayerTimeSource.mosque;
                      final mosque = _logic.selectedMosque;
                      final tagText = isMosque
                          ? (mosque != null ? mosque.name : 'مواقيت المسجد')
                          : 'مواقيت محسوبة';
                      final icon = isMosque
                          ? Icons.mosque_rounded
                          : Icons.calculate_outlined;

                      return Material(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _showSourceSheet,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    size: 13, color: const Color(0xFFD64463)),
                                const SizedBox(width: 4),
                                Text(
                                  tagText,
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 12.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.swap_vert_rounded,
                                    size: 13, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                // Fajr challenge chip, same small size
                Expanded(
                  child: Center(
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => showFajrChallengeBottomSheet(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wb_twilight_rounded,
                                  size: 13, color: Color(0xFFD64463)),
                              const SizedBox(width: 4),
                              const Text(
                                'تحدي الفجر',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 12.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _logic.fajrChallengeEnabled
                                    ? Icons.circle
                                    : Icons.circle_outlined,
                                size: 10,
                                color: _logic.fajrChallengeEnabled
                                    ? const Color(0xFFFFD700)
                                    : Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          // Swipable List
          Expanded(
            child: PageView.builder(
              controller: _listPageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                _currentSwipeDiff.value = index - 10000;
              },
              itemBuilder: _buildListPage,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildListPage(BuildContext context, int index) {
    final diffDays = index - 10000;

    if (diffDays == 0) {
      return _buildPrayerListWrapper(
        DayPrayerSummary(
          prayerTimes: _logic.prayerTimes!,
          hijriDate: _logic.hijriDate,
          gregorianDate: _logic.gregorianDate,
        ),
        isToday: true,
      );
    }

    return FutureBuilder<DayPrayerSummary>(
      future: _getDaySummary(diffDays),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingListWrapper();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'عذرًا، فشل تحميل المواقيت',
              style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white.withValues(alpha: 0.8)),
            ),
          );
        }
        return _buildPrayerListWrapper(snapshot.data!, isToday: false);
      },
    );
  }

  Widget _buildLoadingListWrapper() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.001;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Container(
          height: screenHeight *
              0.55, // Approximate height of 9 items to prevent jumping
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
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFD64463)),
          ),
        ),
      ),
    );
  }

  Future<DayPrayerSummary> _getDaySummary(int diffDays) {
    if (_pageFutures.containsKey(diffDays)) {
      return _pageFutures[diffDays]!;
    }
    final targetDate = DateTime.now().add(Duration(days: diffDays));
    final future = _logic.getPrayerSummaryForDate(targetDate);
    _pageFutures[diffDays] = future;
    return future;
  }

  /// Opens the source picker bottom sheet: switch between calculated
  /// and mosque timings, and choose a nearby mosque.
  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildSourceSheet(sheetContext),
    );
    _logic.searchNearbyMosques();
  }

  Widget _buildSourceSheet(BuildContext sheetContext) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: screenHeight * 0.66,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'مصدر المواقيت',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF3A2B2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر المواقيت المحسوبة أو ابحث عن مسجد قريبك',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Primary source buttons
            Obx(() => Column(
                  children: [
                    _buildSourceOption(
                      icon: Icons.calculate_outlined,
                      title: 'مواقيت محسوبة',
                      subtitle: 'حسب حساب فقهي يعتمد على موقعك',
                      active: _logic.prayerTimeSource ==
                          PrayerTimeSource.calculated,
                      onTap: () {
                        _logic.setPrayerTimeSource(PrayerTimeSource.calculated);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSourceOption(
                      icon: Icons.mosque_rounded,
                      title: 'مواقيت المسجد',
                      subtitle: _logic.selectedMosque != null
                          ? _logic.selectedMosque!.name
                          : 'لم يتم اختيار مسجد بعد',
                      active:
                          _logic.prayerTimeSource == PrayerTimeSource.mosque,
                      onTap: () {
                        if (_logic.selectedMosque != null) {
                          _logic.setPrayerTimeSource(PrayerTimeSource.mosque);
                          Navigator.of(sheetContext).pop();
                        } else {
                          // no selected mosque, user should pick from list below
                        }
                      },
                    ),
                  ],
                )),
            const SizedBox(height: 16),
            // Nearby mosques header
            Obx(() => Text(
                  _logic.nearbyMosqueCountry.isEmpty
                      ? 'المساجد القريبة منك'
                      : 'جميع المساجد — ${_logic.nearbyMosqueCountry} (${_logic.nearbyMosques.length})',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF3A2B2E),
                  ),
                )),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (_logic.isSearchingMosques) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD64463)),
                  );
                }
                if (_logic.nearbyMosques.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد نتائج حالياً',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: _logic.nearbyMosques.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final m = _logic.nearbyMosques[i];
                    final isActive = _logic.selectedMosque?.slug == m.slug &&
                        _logic.prayerTimeSource == PrayerTimeSource.mosque;
                    final distText = _formatDistance(m.proximityMeters);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isActive ? const Color(0xFFD64463) : null,
                        child: Icon(
                          Icons.mosque_rounded,
                          color:
                              isActive ? Colors.white : const Color(0xFFD64463),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        m.name,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF3A2B2E),
                        ),
                      ),
                      subtitle: Text(
                        m.city.isNotEmpty // city used to display country: mosque has city when present
                            ? (m.address?.isNotEmpty ?? false)
                                ? '${m.city} • ${m.address}'
                                : m.city
                            : m.address ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            distText,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isActive
                                ? Icons.check_circle_rounded
                                : Icons.chevron_left_rounded,
                            color: isActive
                                ? const Color(0xFFD64463)
                                : Colors.grey,
                          ),
                        ],
                      ),
                      onTap: () => _selectMosqueFromSheet(m, sheetContext),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: active
          ? const Color(0xFFD64463)
          : (isDark ? const Color(0xFF2C2C35) : const Color(0xFFF5ECE9)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 26,
                color: active ? Colors.white : const Color(0xFFD64463),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: active
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF3A2B2E)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        color: active
                            ? Colors.white70
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.chevron_left_rounded,
                color: active ? Colors.white : Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selects a mosque from the nearby list: loads its schedule and activates it.
  Future<void> _selectMosqueFromSheet(
      MosquePoint m, BuildContext sheetContext) async {
    try {
      final api = MawaqitApi();
      final feed = await api.scheduleBySlug(m.slug, forceRefresh: true);
      await _logic.setSelectedMosque(m, schedule: feed);
      if (mounted && sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم اعتماد (${m.name}) كمسجدك الرئيسي للمواقيت',
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
            backgroundColor: const Color(0xFF693B42),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted && sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تحميل مواقيت هذا المسجد، حاول مجدداً',
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
            backgroundColor: const Color(0xFF693B42),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters <= 0) return '';
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} م';
    }
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  Widget _buildDateHeaderWidget(DayPrayerSummary summary,
      {required bool isToday}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textDecoration =
        isToday ? TextDecoration.none : TextDecoration.underline;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.008,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C35).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: summary.hijriDate,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.95)
                            : const Color(0xFF2D3142),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        height: 1.3,
                        decoration: textDecoration,
                      ),
                    ),
                    TextSpan(
                      text: ' الموافق ل ${summary.gregorianDate} م',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.95)
                            : const Color(0xFF2D3142).withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        letterSpacing: 1.2,
                        decoration: textDecoration,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerListWrapper(DayPrayerSummary summary,
      {required bool isToday}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final horizontalPadding = screenWidth * 0.06;
    final verticalPadding = screenHeight * 0.0005;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Container(
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
            vertical: screenHeight * 0.005,
            horizontal: screenWidth * 0.01,
          ),
          child: Column(
            children: _buildPrayerList(screenWidth, screenHeight, summary,
                isToday: isToday),
          ),
        ),
      ),
    );
  }

  Widget _buildNewHeader(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
      child: SizedBox(
        height: screenHeight * 0.2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Obx(() {
              final hasIqama = _logic.hasIqamaData;
              final iqamaCountdown = _logic.iqamaCountdown;
              final adhanCountdown = _logic.timeRemaining;
              // Use iqama countdown if available, otherwise fall back to adhan
              final displayCountdown = hasIqama && iqamaCountdown.isNotEmpty
                  ? iqamaCountdown
                  : adhanCountdown;
              final countdownLabel = hasIqama && iqamaCountdown.isNotEmpty
                  ? 'الإقامة بعد'
                  : '${_logic.nextPrayerName} بعد';

              return Row(
                children: [
                  // RIGHT SIDE: Text Info (In RTL this is the "Start")
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Prayer Name with enhanced styling
                        if (_logic.nextPrayerName.isNotEmpty)
                          Container(
                            padding:
                                EdgeInsets.only(bottom: screenHeight * 0.001),
                            child: Text(
                              countdownLabel,
                              style: TextStyle(
                                fontSize: screenWidth * 0.08,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                    color: Colors.black.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(height: screenHeight * 0.01),
                        if (displayCountdown.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
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
                                  displayCountdown,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.065,
                                    color: const Color(0xFF1A1A2E),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Icon(
                                  Icons.schedule,
                                  color: const Color(0xFFD64463),
                                  size: screenWidth * 0.05,
                                ),
                              ],
                            ),
                          ),
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
                          color: _getNextPrayerColor(),
                          size: screenWidth * 0.11,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
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

  List<Widget> _buildPrayerList(
      double screenWidth, double screenHeight, DayPrayerSummary summary,
      {required bool isToday}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final arabicNames = kArabicPrayerNames;
    final nightPrayerNames = kNightPrayerNames;

    // Separate main and night prayers
    final mainPrayers = summary.prayerTimes
        .where((p) => !nightPrayerNames.contains(p.name))
        .toList();
    final nightPrayers = summary.prayerTimes
        .where((p) => nightPrayerNames.contains(p.name))
        .toList();

    Widget buildPrayerItem(dynamic prayer) {
      final arabicName = arabicNames[prayer.name] ?? prayer.name;
      // If it's today, we wrap in Obx to show dynamic highlight
      if (isToday) {
        return Obx(() {
          final dynNextPrayerName = _logic.nextPrayerName;
          final isNextNow = arabicName == dynNextPrayerName;
          return _buildSinglePrayerItem(
              prayer, arabicName, isNextNow, isDark, screenHeight, screenWidth);
        });
      } else {
        return _buildSinglePrayerItem(
            prayer, arabicName, false, isDark, screenHeight, screenWidth);
      }
    }

    final List<Widget> widgets = mainPrayers.map(buildPrayerItem).toList();

    // Night Prayers Section
    widgets.addAll(nightPrayers.map(buildPrayerItem));

    return widgets;
  }

  Widget _buildSinglePrayerItem(dynamic prayer, String arabicName, bool isNext,
      bool isDark, double screenHeight, double screenWidth) {
    final textColor = isDark ? Colors.white : Colors.black;
    final activeColor = const Color(0xFFD64463);
    final nextTextColor =
        isDark ? Colors.white : Colors.white; // High contrast for highlight
    final hasIqama = prayer.iqamaTime != null;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.002,
        horizontal: screenWidth * 0.015,
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
          // Prayer Icon with elegant background tint
          Container(
            width: screenWidth * 0.088,
            height: screenWidth * 0.088,
            decoration: BoxDecoration(
              color:
                  (isNext ? activeColor : _getPrayerColorFromName(prayer.name))
                      .withValues(alpha: isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                _getPrayerIconFromName(prayer.name),
                color:
                    isNext ? activeColor : _getPrayerColorFromName(prayer.name),
                size: screenWidth * 0.052,
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.03),
          // Name
          Text(
            arabicName,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: isNext ? nextTextColor : textColor,
            ),
          ),

          const Spacer(),

          // Adhan time + Iqama time
          if (hasIqama) ...[
            Text(
              _formatTime24H(prayer.iqamaTime!),
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w800,
                color: isNext ? nextTextColor : const Color(0xFFD64463),
              ),
            ),
            SizedBox(width: screenWidth * 0.015),
            Container(
              width: 1,
              height: screenHeight * 0.025,
              color:
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
            ),
            SizedBox(width: screenWidth * 0.015),
          ],
          Text(
            _formatTime24H(prayer.time),
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: isNext ? nextTextColor : textColor,
            ),
          ),

          // Reserved space for the toggle icon to ensure alignment
          SizedBox(
            width: screenWidth * 0.12,
            child: Obx(() {
              final isSpecialTime = [
                'Sunrise',
                'First Third',
                'Midnight',
                'Last Third'
              ].contains(prayer.name);
              final isAyatEnabled =
                  _logic.prayerAyatHadithEnabled[prayer.name] ?? !isSpecialTime;

              return Center(
                child: IconButton(
                  icon: Icon(
                    isAyatEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: isAyatEnabled
                        ? (isNext
                            ? nextTextColor
                            : Colors.orangeAccent.withValues(alpha: 0.8))
                        : (isDark ? Colors.white24 : Colors.black12),
                    size: screenWidth * 0.05,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip:
                      isAyatEnabled ? 'إيقاف نافذة الآية' : 'تفعيل نافذة الآية',
                  onPressed: () => _logic.toggleAyatHadith(prayer.name),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIconFromName(String name) {
    switch (name) {
      case 'Fajr':
        return Icons.wb_twilight_rounded;
      case 'Sunrise':
        return Icons.wb_sunny_rounded;
      case 'Dhuhr':
        return Icons.sunny;
      case 'Asr':
        return Icons.sunny_snowing;
      case 'Maghrib':
        return Icons.wb_twilight_rounded;
      case 'Isha':
        return Icons.bedtime_rounded;
      case 'First Third':
        return Icons.bedtime_outlined;
      case 'Midnight':
        return Icons.dark_mode_rounded;
      case 'Last Third':
        return Icons.nights_stay_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getPrayerColorFromName(String name) {
    switch (name) {
      case 'Fajr':
        return const Color(0xFF64B5F6); // Twilight dawn sky blue
      case 'Sunrise':
        return const Color(0xFFFFB74D); // Warm sunrise amber
      case 'Dhuhr':
        return const Color(0xFFFFC107); // Radiant midday gold
      case 'Asr':
        return const Color(0xFFFF9800); // Warm afternoon amber-orange
      case 'Maghrib':
        return const Color(0xFFFF7043); // Sunset coral red
      case 'Isha':
        return const Color(0xFF9575CD); // Calm night purple
      case 'First Third':
        return const Color(0xFF7986CB); // Early night indigo
      case 'Midnight':
        return const Color(0xFF5C6BC0); // Deep midnight blue
      case 'Last Third':
        return const Color(0xFFFFD54F); // Tahajjud & Qiyam celestial gold
      default:
        return Colors.orangeAccent;
    }
  }

  IconData _getNextPrayerIcon() {
    final prayerName = _logic.nextPrayerName;
    switch (prayerName) {
      case 'الفجر':
        return Icons.wb_twilight_rounded;
      case 'الشروق':
        return Icons.wb_sunny_rounded;
      case 'الظهر':
        return Icons.sunny;
      case 'العصر':
        return Icons.sunny_snowing;
      case 'المغرب':
        return Icons.wb_twilight_rounded;
      case 'العشاء':
        return Icons.bedtime_rounded;
      case 'الثلث الأول':
        return Icons.bedtime_outlined;
      case 'منتصف الليل':
      case 'الليل':
        return Icons.dark_mode_rounded;
      case 'الثلث الأخير':
        return Icons.nights_stay_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getNextPrayerColor() {
    final prayerName = _logic.nextPrayerName;
    switch (prayerName) {
      case 'الفجر':
        return const Color(0xFF64B5F6);
      case 'الشروق':
        return const Color(0xFFFFB74D);
      case 'الظهر':
        return const Color(0xFFFFC107);
      case 'العصر':
        return const Color(0xFFFF9800);
      case 'المغرب':
        return const Color(0xFFFF7043);
      case 'العشاء':
        return const Color(0xFF9575CD);
      case 'الثلث الأول':
        return const Color(0xFF7986CB);
      case 'منتصف الليل':
      case 'الليل':
        return const Color(0xFF5C6BC0);
      case 'الثلث الأخير':
        return const Color(0xFFFFD54F);
      default:
        return Colors.orangeAccent;
    }
  }

  String _formatTime24H(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
