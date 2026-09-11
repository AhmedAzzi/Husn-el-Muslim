import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/logic/ahkam.dart';
import '../../../../core/theme/husn_style.dart';
import '../../../../core/theme/tajweed_colors.dart';
import '../../data/models/tafsir_source.dart';
import '../../data/models/word_meaning.dart';
import '../../../settings/settings_provider.dart';
import '../../../nakhtem/presentation/controllers/nakhtem_settings_controller.dart';
import '../providers/irab_providers.dart';
import '../providers/asbab_providers.dart';
import '../providers/tafsir_providers.dart';
import '../providers/translation_providers.dart';

/// Centered tabbed dialog for a single mushaf word.
///
/// Tabs: المعنى (DB gloss, Arabic only) + التجويد (rule cards) +
/// التفسير (six sources) + الإعراب + سبب النزول + الترجمة (English).
/// Opening tab is controlled by [initialTab] — plain-word taps open المعنى,
/// colored-segment taps open التجويد, but both live in the same dialog so
/// there is no tap ambiguity. Extra tabs can be appended via [extraTabs].
class WordDetailDialog extends StatefulWidget {
  const WordDetailDialog({
    super.key,
    required this.selected,
    required this.isLoading,
    required this.error,
    this.tajweedClasses = const [],
    this.initialTab = 0,
    this.surah,
    this.ayah,
    this.word,
    this.extraTabs = const [],
  });

  final Rxn<WordMeaning> selected;
  final RxBool isLoading;
  final Rxn<String> error;
  final List<String> tajweedClasses;
  final int initialTab;

  /// Ayah context for the التفسير/الترجمة tabs. When null, they are hidden.
  final int? surah;
  final int? ayah;
  final String? word;

  /// Future tabs. Each entry provides a tab label and its view.
  /// Appended after the built-in tabs.
  final List<({String label, Widget view})> extraTabs;

  @override
  State<WordDetailDialog> createState() => _WordDetailDialogState();
}

class _WordDetailDialogState extends State<WordDetailDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  bool get _hasTafsir =>
      widget.surah != null && widget.ayah != null && _tafsirOn;
  bool get _hasIrab => widget.surah != null && widget.ayah != null;
  bool get _hasAsbab => widget.surah != null && widget.ayah != null;
  bool get _hasTranslation =>
      widget.surah != null && widget.ayah != null && _translationOn;

  /// Khatma display settings; always on when the controller isn't
  /// registered (e.g. standalone tests).
  bool get _tafsirOn =>
      !Get.isRegistered<NakhtemSettingsController>() ||
      Get.find<NakhtemSettingsController>().settings.value.tafsirEnabled;
  bool get _translationOn =>
      !Get.isRegistered<NakhtemSettingsController>() ||
      Get.find<NakhtemSettingsController>().settings.value.translationEnabled;

  int get _tabCount =>
      2 +
      (_hasTafsir ? 1 : 0) +
      (_hasIrab ? 1 : 0) +
      (_hasAsbab ? 1 : 0) +
      (_hasTranslation ? 1 : 0) +
      widget.extraTabs.length;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabCount - 1),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 640),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  selected: widget.selected,
                  isLoading: widget.isLoading,
                  surah: widget.surah,
                  ayah: widget.ayah,
                ),
                SizedBox(
                  height: 44,
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    indicatorPadding: const EdgeInsets.symmetric(vertical: 5),
                    overlayColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    splashFactory: NoSplash.splashFactory,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [HusnTheme.primary, HusnTheme.primaryDark],
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        dark ? Colors.grey[400] : HusnTheme.primary,
                    labelStyle: const TextStyle(
                      fontFamily: HusnTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: HusnTheme.fontFamily,
                      fontSize: 14,
                    ),
                    tabs: [
                      const Tab(text: 'المعنى'),
                      const Tab(text: 'التجويد'),
                      if (_hasTafsir) const Tab(text: 'التفسير'),
                      if (_hasIrab) const Tab(text: 'الإعراب'),
                      if (_hasAsbab) const Tab(text: 'سبب النزول'),
                      if (_hasTranslation) const Tab(text: 'الترجمة'),
                      for (final t in widget.extraTabs) Tab(text: t.label),
                    ],
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _MeaningView(
                          selected: widget.selected,
                          isLoading: widget.isLoading,
                          error: widget.error,
                          dark: dark,
                        ),
                        _TajweedView(
                          classes: widget.tajweedClasses,
                          dark: dark,
                        ),
                        if (_hasTafsir)
                          _TafsirView(
                            surah: widget.surah!,
                            ayah: widget.ayah!,
                            dark: dark,
                          ),
                        if (_hasIrab)
                          _IrabView(
                            surah: widget.surah!,
                            ayah: widget.ayah!,
                            word: widget.word,
                          ),
                        if (_hasAsbab)
                          _AsbabView(surah: widget.surah!, ayah: widget.ayah!),
                        if (_hasTranslation)
                          _TranslationView(
                            surah: widget.surah!,
                            ayah: widget.ayah!,
                            dark: dark,
                          ),
                        for (final t in widget.extraTabs) t.view,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: HusnTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(
                          fontFamily: HusnTheme.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
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

/// Gradient header with the tapped word in large Quran type,
/// a gold root pill, and an ayah reference line.
class _Header extends StatelessWidget {
  const _Header({
    required this.selected,
    required this.isLoading,
    this.surah,
    this.ayah,
  });

  final Rxn<WordMeaning> selected;
  final RxBool isLoading;
  final int? surah;
  final int? ayah;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [HusnTheme.primary, HusnTheme.primaryDark],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ayah bookmark toggle (super bookmark).
              if (surah != null && ayah != null)
                Obx(() {
                  if (!Get.isRegistered<SettingsController>()) {
                    return const SizedBox(width: 18);
                  }
                  final settings = Get.find<SettingsController>();
                  final saved = settings.isAyahBookmarked(surah!, ayah!);
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => settings.toggleAyahBookmark(surah!, ayah!),
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                      color: saved ? HusnTheme.gold : Colors.white70,
                      size: 20,
                    ),
                    tooltip: saved ? 'محفوظة' : 'حفظ الآية',
                  );
                })
              else
                const SizedBox(width: 18),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                tooltip: 'إغلاق',
              ),
            ],
          ),
          Obx(() {
            final w = selected.value;
            final title = w?.wordWithHaraqah ?? w?.imlaee ?? '…';
            return Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'KemenagLPMQ',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            );
          }),
          Obx(() {
            final w = selected.value;
            final root = w?.root ?? '';
            final parts = <String>[];
            if (root.isNotEmpty) parts.add('الجذر: $root');
            if (surah != null && ayah != null) {
              parts.add('سورة $surah · آية $ayah');
            }
            if (parts.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                parts.join(' · '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFE9A8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MeaningView extends StatelessWidget {
  const _MeaningView({
    required this.selected,
    required this.isLoading,
    required this.error,
    required this.dark,
  });

  final Rxn<WordMeaning> selected;
  final RxBool isLoading;
  final Rxn<String> error;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isLoading.value && selected.value == null) {
        return const Center(
          child: CircularProgressIndicator(color: HusnTheme.primary),
        );
      }
      final w = selected.value;
      if (w == null) {
        return Center(child: Text(error.value ?? 'لا توجد معاني لهذه الكلمة'));
      }
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              w.wordWithHaraqah ?? w.imlaee ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'KemenagLPMQ',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((w.root ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'الجذر: ${w.root}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            if ((w.meaning ?? '').isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : HusnTheme.primary.withValues(alpha: 0.06),
                  border: Border.all(
                    color: HusnTheme.gold.withValues(alpha: 0.55),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  w.meaning!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 2.0),
                ),
              )
            else
              const Text(
                'لا توجد معاني لهذه الكلمة',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    });
  }
}

class _TafsirView extends StatefulWidget {
  const _TafsirView({
    required this.surah,
    required this.ayah,
    required this.dark,
  });

  final int surah;
  final int ayah;
  final bool dark;

  @override
  State<_TafsirView> createState() => _TafsirViewState();
}

class _TafsirViewState extends State<_TafsirView> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<TafsirController>()) {
      TafsirController.to.loadAyah(widget.surah, widget.ayah);
    }
  }

  @override
  void didUpdateWidget(covariant _TafsirView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah != widget.surah || oldWidget.ayah != widget.ayah) {
      if (Get.isRegistered<TafsirController>()) {
        TafsirController.to.loadAyah(widget.surah, widget.ayah);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TafsirController>()) {
      return const Center(child: Text('التفسير غير متاح'));
    }
    final ctl = TafsirController.to;
    return Column(
      children: [
        const SizedBox(height: 4),
        Obx(() {
          final current = ctl.source.value;
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final s in TafsirSource.values)
                ChoiceChip(
                  label: Text(
                    s.arabicName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                  selected: s == current,
                  selectedColor: HusnTheme.primary,
                  labelStyle: TextStyle(
                    color: s == current ? Colors.white : HusnTheme.primary,
                    fontWeight:
                        s == current ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: HusnTheme.gold),
                  ),
                  onSelected: (_) => ctl.setSource(s),
                ),
            ],
          );
        }),
        const SizedBox(height: 6),
        Expanded(
          child: Obx(() {
            if (ctl.isLoading.value && ctl.text.value == null) {
              return const Center(
                child: CircularProgressIndicator(color: HusnTheme.primary),
              );
            }
            final t = ctl.text.value;
            if (t == null) {
              return Center(
                child: Text(ctl.error.value ?? 'لا يوجد تفسير لهذه الآية'),
              );
            }
            return SingleChildScrollView(
              child: Text(
                t,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.9),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// I'rab tab (I'rab al-Quran li al-Darwish, bundled JSON). Single source,
/// lazily loaded per surah — shows a spinner on first open only.
class _IrabView extends StatefulWidget {
  const _IrabView({required this.surah, required this.ayah, this.word});

  final int surah;
  final int ayah;
  final String? word;

  @override
  State<_IrabView> createState() => _IrabViewState();
}

class _IrabViewState extends State<_IrabView> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<IrabController>()) {
      _load();
    }
  }

  void _load() {
    final ctl = IrabController.to;
    final word = widget.word?.trim();
    if (word == null || word.isEmpty) {
      ctl.loadAyah(widget.surah, widget.ayah);
    } else {
      ctl.loadWord(widget.surah, widget.ayah, word);
    }
  }

  @override
  void didUpdateWidget(covariant _IrabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah != widget.surah ||
        oldWidget.ayah != widget.ayah ||
        oldWidget.word != widget.word) {
      if (Get.isRegistered<IrabController>()) {
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<IrabController>()) {
      return const Center(child: Text('الإعراب غير متاح'));
    }
    final ctl = IrabController.to;
    return Obx(() {
      if (ctl.isLoading.value && ctl.text.value == null) {
        return const Center(
          child: CircularProgressIndicator(color: HusnTheme.primary),
        );
      }
      final t = ctl.text.value;
      if (t == null) {
        return Center(
          child: Text(ctl.error.value ?? 'لا يوجد إعراب لهذه الآية'),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text.rich(
          TextSpan(
            children: [
              if (widget.word?.trim().isNotEmpty ?? false) ...[
                TextSpan(
                  text: '${widget.word!.trim()}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HusnTheme.primary,
                  ),
                ),
              ],
              TextSpan(text: t),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: HusnTheme.fontFamily,
            fontSize: 15,
            height: 1.9,
          ),
        ),
      );
    });
  }
}

/// Asbab al-nuzul tab, loaded lazily from the bundled al-Wahidy data.
class _AsbabView extends StatefulWidget {
  const _AsbabView({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  State<_AsbabView> createState() => _AsbabViewState();
}

class _AsbabViewState extends State<_AsbabView> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AsbabController>()) {
      AsbabController.to.loadAyah(widget.surah, widget.ayah);
    }
  }

  @override
  void didUpdateWidget(covariant _AsbabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah != widget.surah || oldWidget.ayah != widget.ayah) {
      if (Get.isRegistered<AsbabController>()) {
        AsbabController.to.loadAyah(widget.surah, widget.ayah);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AsbabController>()) {
      return const Center(child: Text('سبب النزول غير متاح'));
    }
    final ctl = AsbabController.to;
    return Obx(() {
      if (ctl.isLoading.value && ctl.text.value == null) {
        return const Center(
          child: CircularProgressIndicator(color: HusnTheme.primary),
        );
      }
      final text = ctl.text.value;
      if (text == null || text.trim().isEmpty) {
        return Center(
          child: Text(ctl.error.value ?? 'لا يوجد سبب نزول لهذه الآية'),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'سبب النزول',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HusnTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 15,
                height: 1.9,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _TajweedView extends StatelessWidget {
  const _TajweedView({required this.classes, required this.dark});

  final List<String> classes;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(child: Text('لا يوجد حكم تجويد في هذه الكلمة'));
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: classes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final cls = classes[i];
        final ruleColor = TajweedColors.of(cls, dark: dark);
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ruleColor.withValues(alpha: dark ? 0.25 : 0.16),
                ruleColor.withValues(alpha: dark ? 0.08 : 0.05),
              ],
            ),
            border: Border.all(color: ruleColor.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                ahkamAr(cls),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: HusnTheme.fontFamily,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'طريقة قراءة ${ahkamAr(cls)} :',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: HusnTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tajweedDescription(cls) ?? ahkamAr(cls),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: HusnTheme.fontFamily,
                  fontSize: 15,
                  height: 1.9,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TranslationView extends StatefulWidget {
  const _TranslationView({
    required this.surah,
    required this.ayah,
    required this.dark,
  });

  final int surah;
  final int ayah;
  final bool dark;

  @override
  State<_TranslationView> createState() => _TranslationViewState();
}

class _TranslationViewState extends State<_TranslationView> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<TranslationController>()) {
      TranslationController.to.loadAyah(widget.surah, widget.ayah);
    }
  }

  @override
  void didUpdateWidget(covariant _TranslationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah != widget.surah || oldWidget.ayah != widget.ayah) {
      if (Get.isRegistered<TranslationController>()) {
        TranslationController.to.loadAyah(widget.surah, widget.ayah);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TranslationController>()) {
      return const Center(child: Text('الترجمة غير متاحة'));
    }
    final ctl = TranslationController.to;
    return Obx(() {
      if (ctl.isLoading.value && ctl.text.value == null) {
        return const Center(
          child: CircularProgressIndicator(color: HusnTheme.primary),
        );
      }
      final t = ctl.text.value;
      if (t == null) {
        return Center(
          child: Text(ctl.error.value ?? 'لا توجد ترجمة لهذه الآية'),
        );
      }
      return SingleChildScrollView(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.dark
                ? Colors.white.withValues(alpha: 0.06)
                : HusnTheme.primary.withValues(alpha: 0.06),
            border: Border.all(color: HusnTheme.gold.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            t,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.8),
          ),
        ),
      );
    });
  }
}
