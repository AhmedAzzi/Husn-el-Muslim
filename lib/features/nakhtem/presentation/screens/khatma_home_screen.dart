import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/logic/quran_index.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/husn_app_bar.dart';
import '../../../../core/widgets/settings_widgets.dart';
import '../../../prayer_times/services/prayer_notification_helper.dart';
import '../../domain/services/reading_service.dart';
import '../controllers/nakhtem_controller.dart';
import '../controllers/nakhtem_settings_controller.dart';
import '../controllers/statistics_controller.dart';

/// Asks for confirmation, then wipes all khatma progress (khatmas, reading
/// events, saved position, overlay) and refreshes statistics.
/// Khatma *settings* (reciter, edition, display flags) are kept.
/// Returns true when a reset was performed.
Future<bool> confirmAndResetKhatma(BuildContext context) async {
  final confirmed = await AppFeedback.confirmDestructive(
    context,
    title: 'إعادة تعيين الختمة؟',
    content:
        'سيتم مسح كل تقدم الختمة نهائياً (الختمات وسجل القراءة والموضع المحفوظ). لا يمكن التراجع.',
    confirmLabel: 'مسح التقدم',
    cancelLabel: 'إلغاء',
  );
  if (!confirmed) return false;
  await Get.find<NakhtemController>().resetAllProgress();
  try {
    await Get.find<StatisticsController>().refresh();
  } catch (_) {}
  if (context.mounted) {
    AppFeedback.snack(context, 'تم مسح تقدم الختمة');
  }
  return true;
}

class KhatmaHomeScreen extends StatefulWidget {
  const KhatmaHomeScreen({super.key});

  @override
  State<KhatmaHomeScreen> createState() => _KhatmaHomeScreenState();
}

class _KhatmaHomeScreenState extends State<KhatmaHomeScreen> {
  int _selectedSurah = 1;
  int _selectedAyah = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSelectorsFromProgress();
      _maybeShowDailySummary();
    });
  }

  /// Aligns the surah/ayah selectors with the actual reading position, so
  /// the home screen always guides from where the user really is.
  void _syncSelectorsFromProgress() {
    try {
      final ctl = Get.find<NakhtemController>();
      final idx = ctl.progress.value?.currentGlobalAyah ??
          ctl.khatma.value?.currentGlobalAyah ??
          0;
      if (!mounted) return;
      if (idx <= 0) {
        setState(() {
          _selectedSurah = 1;
          _selectedAyah = 1;
        });
        return;
      }
      final loc = QuranIndex.instance.locationOf(idx);
      if (loc == null) return;
      setState(() {
        _selectedSurah = loc.surah;
        _selectedAyah = loc.ayah;
      });
    } catch (_) {}
  }

  /// Applies a manual selector change to the live khatma position (no-op
  /// when no khatma is active — the selectors are then only the start point).
  Future<void> _applySelectorPosition() async {
    final ctl = Get.find<NakhtemController>();
    if (ctl.khatma.value == null) return;
    final globalIndex =
        QuranIndex.instance.globalIndex(_selectedSurah, _selectedAyah);
    if (globalIndex == null || !mounted) return;
    final ok = await ctl.moveTo(globalIndex);
    if (!mounted) return;
    final surahName =
        QuranIndex.instance.surahMeta(_selectedSurah)?.nameAr ?? '';
    AppFeedback.getSnack(
      ok ? 'تم الانتقال' : 'تعذّر الانتقال',
      ok ? 'سورة $surahName • آية $_selectedAyah' : 'حاول مرة أخرى',
      type: ok ? AppFeedbackType.success : AppFeedbackType.error,
      duration: const Duration(seconds: 2),
    );
  }

  /// End-of-day reading summary: once per day, only when the setting is on
  /// and something was actually read today. Stamps the date first so a
  /// rebuild can never double-show it.
  Future<void> _maybeShowDailySummary() async {
    try {
      final ctl = Get.find<NakhtemController>();
      final statsCtl = Get.find<StatisticsController>();
      final settingsCtl = Get.find<NakhtemSettingsController>();
      if (!settingsCtl.settings.value.showDailySummary) return;
      await statsCtl.refresh();
      if (!mounted) return;
      final today = statsCtl.todayCount.value;
      if (today <= 0) return;
      final progress = ctl.progress.value;
      if (progress == null) return;
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final last = progress.lastSummaryDate;
      if (last != null &&
          DateTime(last.year, last.month, last.day) == todayDate) {
        return;
      }
      final stamped = progress.copyWith(lastSummaryDate: todayDate);
      try {
        await Get.find<ReadingService>().saveProgress(stamped);
      } catch (_) {}
      ctl.progress.value = stamped;
      if (!mounted) return;
      _showDailySummarySheet(today, progress.versesRead);
    } catch (_) {
      // best effort only — never break the home screen
    }
  }

  void _showDailySummarySheet(int today, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E28) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              const Icon(
                Icons.menu_book_outlined,
                size: 42,
                color: HusnTheme.gold,
              ),
              const SizedBox(height: 4),
              const Text(
                'ملخص اليوم',
                style: TextStyle(
                  fontFamily: HusnTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _summaryRow('آيات قرأتها اليوم', '$today'),
              const SizedBox(height: 8),
              _summaryRow('مجموع الآيات منذ البدء', '$total'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: HusnTheme.gold,
                    foregroundColor: HusnTheme.primaryDark,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    'تقبل الله',
                    style: TextStyle(
                      fontFamily: HusnTheme.fontFamily,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: HusnTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HusnTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: HusnTheme.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: HusnTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<NakhtemController>();
    final statsCtl = Get.find<StatisticsController>();
    final settingsCtl = Get.find<NakhtemSettingsController>();
    final l = L10n.of(khatmaLang());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          // Main section inside MainShell: drawer is the primary navigation.
          drawer: const AppDrawer(),
          appBar: HusnAppBar(title: l.t('app_name')),
          // Single screen, no scroll: overlay controls on top, then the
          // position pickers and the reading stats. Everything is compact
          // so it fits without scrolling.
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                _overlayCard(context, ctl, settingsCtl),
                const SizedBox(height: 12),
                _currentAyahCard(context, ctl, settingsCtl, l),
                const SizedBox(height: 12),
                _statsGrid(context, statsCtl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- sections ----------

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: SettingsWidgets.cardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: HusnTheme.gold),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: HusnTheme.fontFamily,
                      color: HusnTheme.gold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: HusnTheme.fontFamily,
                color: dark ? Colors.white : HusnTheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid(BuildContext context, StatisticsController statsCtl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsWidgets.buildSectionHeader(
          context: context,
          title: 'إحصائيات القراءة',
          icon: Icons.bar_chart_outlined,
          color: HusnTheme.gold,
        ),
        Obx(() {
          final cum = statsCtl.cumulative.value;
          final tiles = [
            ('اليوم', '${statsCtl.todayCount.value}', Icons.today_outlined),
            (
              'هذا الأسبوع',
              '${statsCtl.weekCount.value}',
              Icons.date_range_outlined,
            ),
            (
              'هذا الشهر',
              '${statsCtl.monthCount.value}',
              Icons.calendar_month_outlined,
            ),
            (
              'منذ استخدام البرنامج',
              '${cum?.totalVerses ?? 0}',
              Icons.menu_book_outlined,
            ),
          ];
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: tiles.length,
            itemBuilder: (context, i) {
              final t = tiles[i];
              return _statCard(context, t.$1, t.$2, t.$3);
            },
          );
        }),
      ],
    );
  }

  /// The current ayah card: surah, ayah text, reciter + listen, progress.
  Widget _currentAyahCard(
    BuildContext context,
    NakhtemController ctl,
    NakhtemSettingsController settingsCtl,
    L10n l,
  ) {
    return SettingsWidgets.buildCardContainer(
      context: context,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final k = ctl.khatma.value;
            if (k == null) {
              return _khatmaSetupCard(context, ctl, settingsCtl, l,
                  hasKhatma: false);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _khatmaSetupCard(context, ctl, settingsCtl, l, hasKhatma: true)
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Floating-ayah overlay controls: enable (show the current ayah over
  /// other apps now) or stop/disable (dismiss the visible overlay and
  /// switch the master flag off so it never draws). The enable/disable
  /// state is the same flag the Quran settings page edits.
  Widget _overlayCard(
    BuildContext context,
    NakhtemController ctl,
    NakhtemSettingsController settingsCtl,
  ) {
    return Obx(() {
      final hasKhatma = ctl.khatma.value != null;
      final enabled = settingsCtl.settings.value.overlayEnabled;
      final status = !hasKhatma
          ? 'اضغط تشغيل لبدء الختمة وعرض الآية'
          : enabled
              ? 'مفعّلة • تظهر الآية فوق التطبيقات'
              : 'متوقفة';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsWidgets.buildSectionHeader(
            context: context,
            title: 'الآية العائمة',
            icon: Icons.layers_outlined,
            color: HusnTheme.gold,
          ),
          SettingsWidgets.buildCardContainer(
            context: context,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !hasKhatma
                            ? Colors.grey
                            : enabled
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontFamily: HusnTheme.fontFamily,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: HusnTheme.gold,
                          foregroundColor: HusnTheme.primaryDark,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'تشغيل',
                          style: TextStyle(
                            fontFamily: HusnTheme.fontFamily,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () => _enableOverlay(ctl, settingsCtl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.stop),
                        label: const Text(
                          'إيقاف',
                          style: TextStyle(
                            fontFamily: HusnTheme.fontFamily,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () => _disableOverlay(ctl, settingsCtl),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// Starts the overlay: when no khatma exists yet, one is created at
  /// the selected position first — so this single button covers both
  /// cases. Then the master flag is switched on and the current ayah is
  /// shown over other apps right away (permission flow included).
  Future<void> _enableOverlay(
    NakhtemController ctl,
    NakhtemSettingsController settingsCtl,
  ) async {
    if (ctl.khatma.value == null) {
      final globalIndex = QuranIndex.instance.globalIndex(
        _selectedSurah,
        _selectedAyah,
      );
      if (globalIndex == null) return;
      final ok = await ctl.startKhatma(
        startingGlobalAyah: globalIndex,
        edition: settingsCtl.settings.value.edition,
      );
      if (!ok) {
        AppFeedback.getSnack(
          'الختمة',
          'تعذّر بدء الختمة',
          type: AppFeedbackType.error,
        );
        return;
      }
      _syncSelectorsFromProgress();
    }
    await settingsCtl.setOverlayEnabled(true);
    try {
      await ctl.syncOverlayCache();
    } catch (_) {}
    await _startPhoneExperience(ctl);
  }

  /// Stops the overlay: dismisses any visible surface and switches the
  /// master flag off so it never draws until enabled again.
  Future<void> _disableOverlay(
    NakhtemController ctl,
    NakhtemSettingsController settingsCtl,
  ) async {
    await settingsCtl.setOverlayEnabled(false);
    try {
      await ctl.syncOverlayCache();
    } catch (_) {}
    if (!mounted) return;
    AppFeedback.snack(context, 'تم إيقاف الآية العائمة');
  }

  Widget _khatmaSetupCard(
    BuildContext context,
    NakhtemController ctl,
    NakhtemSettingsController settingsCtl,
    L10n l, {
    required bool hasKhatma,
  }) {
    final index = QuranIndex.instance;
    final surah = index.surahMeta(_selectedSurah)!;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.menu_book_outlined,
          size: 30,
          color: dark ? HusnTheme.gold : HusnTheme.primary,
        ),
        const SizedBox(height: 2),
        Text(
          hasKhatma ? 'موضعك الحالي' : 'ابدأ ختمة جديدة',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: HusnTheme.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _selectionDropdown<int>(
          context,
          label: 'السورة',
          value: _selectedSurah,
          items: [
            for (var number = 1; number <= index.surahCount; number++)
              DropdownMenuItem(
                value: number,
                child: Text(
                  '${index.surahMeta(number)!.number}. ${index.surahMeta(number)!.nameAr}',
                  style: const TextStyle(fontFamily: HusnTheme.fontFamily),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedSurah = value;
              _selectedAyah = 1;
            });
            _applySelectorPosition();
          },
        ),
        const SizedBox(height: 8),
        _selectionDropdown<int>(
          context,
          label: 'الآية',
          value: _selectedAyah,
          items: [
            for (var ayah = 1; ayah <= surah.ayahCount; ayah++)
              DropdownMenuItem(
                value: ayah,
                child: Text(
                  '$ayah',
                  style: const TextStyle(fontFamily: HusnTheme.fontFamily),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedAyah = value);
            _applySelectorPosition();
          },
        ),
        const SizedBox(height: 8),
        Obx(() {
          final selectedId = settingsCtl.settings.value.khatmaReciterId;
          final reciterIds = settingsCtl.reciters.map((r) => r.id);
          final selectedValue =
              reciterIds.contains(selectedId) ? selectedId : null;
          return _selectionDropdown<String>(
            context,
            label: 'القارئ',
            value: selectedValue,
            items: [
              for (final reciter in settingsCtl.reciters)
                DropdownMenuItem(
                  value: reciter.id,
                  child: Text(
                    reciter.titleFor(khatmaLang()),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: HusnTheme.fontFamily),
                  ),
                ),
            ],
            onChanged: (value) async {
              if (value == null) return;
              await settingsCtl.setKhatmaReciter(value);
              // Take effect immediately: next overlay/ayah uses it.
              try {
                await ctl.syncOverlayCache();
              } catch (_) {}
            },
          );
        }),
      ],
    );
  }

  Widget _selectionDropdown<T>(
    BuildContext context, {
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      style: TextStyle(
        fontFamily: HusnTheme.fontFamily,
        color: dark ? Colors.white : Theme.of(context).colorScheme.onSurface,
      ),
      dropdownColor: Theme.of(context).cardColor,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: dark ? Colors.white10 : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: TextStyle(
          fontFamily: HusnTheme.fontFamily,
          color: dark ? Colors.white : HusnTheme.primary,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: HusnTheme.fontFamily,
          color: dark ? Colors.white : HusnTheme.primary,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: HusnTheme.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: HusnTheme.gold, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Future<void> _startPhoneExperience(NakhtemController ctl) async {
    // The "display over other apps" permission is already requested during
    // first-start onboarding through Husn's own channel, so never ask for it
    // here. Just verify: if granted, start the overlay directly; if the user
    // skipped it at onboarding, open the system settings so they can allow it.
    final granted = await PrayerNotificationHelper.checkOverlayPermission();
    if (!granted) {
      await PrayerNotificationHelper.requestOverlayPermission();
      AppFeedback.getSnack(
        'السماح مطلوب',
        'فعّل السماح بالعرض فوق التطبيقات ثم اضغط ابدأ الآن مرة أخرى',
        type: AppFeedbackType.warn,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    final shown = await ctl.publishAyahToOverlay();
    if (!shown) {
      AppFeedback.getSnack(
        'الآية العائمة',
        'تعذّر بدء عرض الآية',
        type: AppFeedbackType.error,
      );
    }
  }
}
