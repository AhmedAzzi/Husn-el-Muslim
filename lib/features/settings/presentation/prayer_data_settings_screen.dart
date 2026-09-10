import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/mosque_map_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/advanced_settings_screen.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class PrayerDataSettingsScreen extends StatefulWidget {
  const PrayerDataSettingsScreen({super.key});

  @override
  State<PrayerDataSettingsScreen> createState() => _PrayerDataSettingsScreenState();
}

class _PrayerDataSettingsScreenState extends State<PrayerDataSettingsScreen> {
  final PrayerTimesLogic _prayerLogic = PrayerTimesLogic();
  bool _isRefreshingLocation = false;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _prayerLogic.loadNotificationPreference();
    final prefs = SharedPrefsCache.instance;
    if (!mounted) return;
    setState(() {
      _showAdvanced = prefs.getBool('show_advanced') ?? false;
    });
  }

  static Map<String, ({String title, String subtitle})> calculationMethods(
          AppLocalizations loc) =>
      {
    'makkah': (
      title: loc.stMethodMakkah,
      subtitle: loc.stMethodMakkahSub,
    ),
    'egypt': (
      title: loc.stMethodEgypt,
      subtitle: loc.stMethodEgyptSub,
    ),
    'mwl': (
      title: loc.stMethodMwl,
      subtitle: loc.stMethodMwlSub,
    ),
    'karachi': (
      title: loc.stMethodKarachi,
      subtitle: loc.stMethodKarachiSub,
    ),
    'isna': (
      title: loc.stMethodIsna,
      subtitle: loc.stMethodIsnaSub,
    ),
    'kuwait': (
      title: loc.stMethodKuwait,
      subtitle: loc.stMethodKuwaitSub,
    ),
    'qatar': (
      title: loc.stMethodQatar,
      subtitle: loc.stMethodQatarSub,
    ),
    'singapore': (
      title: loc.stMethodSingapore,
      subtitle: loc.stMethodSingaporeSub,
    ),
    'turkey': (
      title: loc.stMethodTurkey,
      subtitle: loc.stMethodTurkeySub,
    ),
    'dubai': (
      title: loc.stMethodDubai,
      subtitle: loc.stMethodDubaiSub,
    ),
    'moonsighting': (
      title: loc.stMethodMoon,
      subtitle: loc.stMethodMoonSub,
    ),
  };

  // Asr methods (localized at call time)
  static Map<String, ({String title, String subtitle})> asrMethods(
          AppLocalizations loc) =>
      {
    'shafi': (
      title: loc.stAsrShafi,
      subtitle: loc.stAsrShafiSub,
    ),
    'hanafi': (
      title: loc.stAsrHanafi,
      subtitle: loc.stAsrHanafiSub,
    ),
  };

  Future<void> _refreshGpsLocation() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isRefreshingLocation = true);
    try {
      await _prayerLogic.ensureDataLoaded(force: true);
      _showSnackBar(loc.stGpsRefreshed);
    } catch (e) {
      _showSnackBar(loc.stGpsFailed);
    } finally {
      if (mounted) setState(() => _isRefreshingLocation = false);
    }
  }
  void _showPrayerSourcePicker() {
    final loc = AppLocalizations.of(context)!;
    _showCustomBottomSheet(
      title: loc.stSourcePicker,
      subtitle: loc.stSourcePickerSub,
      child: Column(
        children: [
          SettingsWidgets.buildPickerOption(
            context: context,
            title: loc.stSourceMosque,
            subtitle: loc.stSourceMosqueSub,
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
                _showSnackBar(AppLocalizations.of(context)!.stSourceMosqueSet);
              }
            },
          ),
          SettingsWidgets.buildPickerOption(
            context: context,
            title: loc.stSourceCalc,
            subtitle: loc.stSourceCalcSub,
            icon: Icons.calculate_outlined,
            isSelected:
                _prayerLogic.prayerTimeSource == PrayerTimeSource.calculated,
            onTap: () {
              Get.back();
              setState(() => _prayerLogic
                  .setPrayerTimeSource(PrayerTimeSource.calculated));
              _showSnackBar(AppLocalizations.of(context)!.stSourceCalcSet);
            },
          ),
        ],
      ),
    );
  }
  void _showCalculationMethodPicker() {
    final loc = AppLocalizations.of(context)!;
    _showCustomBottomSheet(
      title: loc.stCalcPicker,
      subtitle: loc.stCalcPickerSub,
      child: Column(
        children: calculationMethods(AppLocalizations.of(context)!).entries.map((entry) {
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
              _showSnackBar(AppLocalizations.of(context)!.stCalcSaved);
            },
          );
        }).toList(),
      ),
    );
  }
  void _showAsrMethodPicker() {
    final loc = AppLocalizations.of(context)!;
    _showCustomBottomSheet(
      title: loc.stAsrPicker,
      subtitle: loc.stAsrPickerSub,
      child: Column(
        children: asrMethods(AppLocalizations.of(context)!).entries.map((entry) {
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
              _showSnackBar(AppLocalizations.of(context)!.stAsrSaved);
            },
          );
        }).toList(),
      ),
    );
  }
  void _showManualAdjustmentSheet() {
    final loc = AppLocalizations.of(context)!;
    final Map<String, String> prayerNames = {
      'Fajr': loc.nsPrayerFajr,
      'Sunrise': loc.nsPrayerSunrise,
      'Dhuhr': loc.nsPrayerDhuhr,
      'Asr': loc.nsPrayerAsr,
      'Maghrib': loc.nsPrayerMaghrib,
      'Isha': loc.nsPrayerIsha,
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      StatefulBuilder(
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
                      Text(
                        loc.stManualTitle,
                        style: const TextStyle(
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
                        label: Text(
                          loc.stReset,
                          style: const TextStyle(fontFamily: 'Amiri'),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD64463),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.stManualSub,
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
                                      ? loc.stZeroMin
                                      : loc.stMinDelta(
                                          '${mins > 0 ? '+' : ''}$mins'),
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
                        _showSnackBar(AppLocalizations.of(context)!.stManualSaved);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64463),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        loc.stSaveEdits,
                        style: const TextStyle(
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
      isScrollControlled: true,
    );
  }
  void _showIqamaOffsetsSheet() {
    final loc = AppLocalizations.of(context)!;
    final Map<String, String> prayerNames = {
      'Fajr': loc.nsPrayerFajr,
      'Dhuhr': loc.nsPrayerDhuhr,
      'Asr': loc.nsPrayerAsr,
      'Maghrib': loc.nsPrayerMaghrib,
      'Isha': loc.nsPrayerIsha,
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      StatefulBuilder(
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
                      Text(
                        loc.stIqamaTitle,
                        style: const TextStyle(
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
                        label: Text(
                          loc.stReset,
                          style: const TextStyle(fontFamily: 'Amiri'),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD64463),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.stIqamaSub,
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
                                      ? loc.stNoIqama
                                      : loc.stIqamaMinutes(offsetMin),
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
                        _showSnackBar(AppLocalizations.of(context)!.stIqamaSaved);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64463),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        loc.stSave,
                        style: const TextStyle(
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
      isScrollControlled: true,
    );
  }
  void _showHijriAdjustmentSheet() {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      StatefulBuilder(
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
                  Text(
                    loc.stHijriTitle,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.stHijriSub,
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
                                    ? loc.stHijriExact
                                    : loc.stHijriDays(
                                        _prayerLogic.hijriOffset.abs()),
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
                        _showSnackBar(AppLocalizations.of(context)!.stHijriSaved);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64463),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        loc.stSave,
                        style: const TextStyle(
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
    );
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
              // Options scroll when taller than the sheet allows (e.g. the
              // 11-item calculation-method list on small screens).
              Flexible(
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
);
    }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final calcMethodTitle =
        calculationMethods(loc)[_prayerLogic.angles]?.title ??
            loc.stMethodMakkah;
    final asrMethodTitle =
        asrMethods(loc)[_prayerLogic.asrMethod]?.title ?? loc.stAsrShafi;

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
              loc.stPrayerData,
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
                // Section 4: Prayer Times & Data Source
                SettingsWidgets.buildSectionHeader(
                  context: context,
                  title: loc.stPrayerData,
                  icon: Icons.mosque_outlined,
                  color: const Color(0xFFD64463),
                ),
                SettingsWidgets.buildCardContainer(
                  context: context,
                  children: [
                    // Source Selector Tile
                    SettingsWidgets.buildValueTile(
                      context: context,
                      title: loc.stSourcePicker,
                      subtitle: _prayerLogic.prayerTimeSource ==
                              PrayerTimeSource.mosque
                          ? loc.stSourceMosque
                          : loc.stSourceCalcMode,
                      icon: _prayerLogic.prayerTimeSource ==
                              PrayerTimeSource.mosque
                          ? Icons.mosque_rounded
                          : Icons.calculate_outlined,
                      iconColor: const Color(0xFFD64463),
                      valueBadge: _prayerLogic.prayerTimeSource ==
                              PrayerTimeSource.mosque
                          ? loc.stMosqueBadge
                          : loc.stCalcBadge,
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
                            : loc.stNoMosque,
                        subtitle: _prayerLogic.selectedMosque != null
                            ? loc.stCityChange(
                                _prayerLogic.selectedMosque!.city)
                            : loc.stOpenMapChoose,
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
                                ? loc.stChangeMosque
                                : loc.stChooseMosque,
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
                      title: loc.stGpsTile,
                      subtitle: loc.stCoords(
                          _prayerLogic.lat.toStringAsFixed(3),
                          _prayerLogic.lon.toStringAsFixed(3)),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh_rounded,
                                      size: 16, color: Color(0xFFD64463)),
                                  const SizedBox(width: 4),
                                  Text(
                                    loc.stRefresh,
                                    style: const TextStyle(
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
                      title: loc.stCalcMethod,
                      subtitle: loc.stCalcMethodSub,
                      icon: Icons.calculate_outlined,
                      iconColor: const Color(0xFFD64463),
                      valueBadge: calcMethodTitle,
                      onTap: _showCalculationMethodPicker,
                    ),
                    SettingsWidgets.buildDivider(context),

                    // Asr Method
                    SettingsWidgets.buildValueTile(
                      context: context,
                      title: loc.stAsrMethod,
                      subtitle: loc.stAsrMethodSub,
                      icon: Icons.wb_twilight_rounded,
                      iconColor: const Color(0xFFD64463),
                      valueBadge: asrMethodTitle,
                      onTap: _showAsrMethodPicker,
                    ),
                    SettingsWidgets.buildDivider(context),

                    // Daylight Saving Time (DST) — advanced
                    if (_showAdvanced) ...[
                      SettingsWidgets.buildSwitchTile(
                        context: context,
                        title: loc.stDst,
                        subtitle: loc.stDstSub,
                        icon: Icons.wb_sunny_outlined,
                        iconColor: const Color(0xFFD64463),
                        value: _prayerLogic.dstEnabled,
                        onChanged: (val) {
                          setState(() => _prayerLogic.dstEnabled = val);
                          _prayerLogic.saveCalculationSettings();
                        },
                      ),
                      SettingsWidgets.buildDivider(context),
                    ],

                    // Manual Prayer Offsets — advanced
                    if (_showAdvanced) ...[
                      SettingsWidgets.buildActionTile(
                        context: context,
                        title: loc.stManualTitle,
                        subtitle: loc.stManualTileSub,
                        icon: Icons.tune_rounded,
                        iconColor: const Color(0xFFD64463),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: Colors.grey),
                        onTap: _showManualAdjustmentSheet,
                      ),
                      SettingsWidgets.buildDivider(context),
                    ],

                    // Iqama Offsets (calculated mode only) — advanced
                    if (_showAdvanced &&
                        _prayerLogic.prayerTimeSource ==
                            PrayerTimeSource.calculated)
                      SettingsWidgets.buildActionTile(
                        context: context,
                        title: loc.stIqamaTile,
                        subtitle: loc.stIqamaTileSub,
                        icon: Icons.groups_rounded,
                        iconColor: const Color(0xFFD64463),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: Colors.grey),
                        onTap: _showIqamaOffsetsSheet,
                      ),
                    if (_showAdvanced &&
                        _prayerLogic.prayerTimeSource ==
                            PrayerTimeSource.calculated)
                      SettingsWidgets.buildDivider(context),

                    // Hijri Date Adjustment
                    SettingsWidgets.buildActionTile(
                      context: context,
                      title: loc.stHijriTitle,
                      subtitle: _prayerLogic.hijriOffset == 0
                          ? loc.stHijriExact
                          : loc.stHijriAdjusted(
                              '${_prayerLogic.hijriOffset > 0 ? '+' : ''}${loc.stHijriDays(_prayerLogic.hijriOffset.abs())}'),
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
                              ? loc.stAdjust
                              : '${_prayerLogic.hijriOffset > 0 ? '+' : ''}${loc.stHijriDays(_prayerLogic.hijriOffset.abs())}',
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
                if (!_showAdvanced) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Get.to(
                          () => const AdvancedSettingsScreen()),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        loc.stHiddenAdvanced,
                        style:
                            const TextStyle(fontFamily: 'Amiri'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
