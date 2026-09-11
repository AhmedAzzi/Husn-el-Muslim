import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logic/quran_index.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../../nakhtem/presentation/controllers/nakhtem_settings_controller.dart';
import '../../../settings/settings_provider.dart';
import '../providers/mushaf_audio_controller.dart';
import 'ayah_search_screen.dart';
import '../providers/quran_providers.dart';
import '../widgets/mushaf_page_view.dart';
import '../widgets/tajweed_legend.dart';

/// Full-screen mushaf reader: swipe-only page switching (RTL paging like an
/// Arabic mushaf). Each 604-edition page is fitted to the viewport.
/// The AppBar hosts the Tajweed color palette guide and settings.
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key, required this.initialPage, this.highlightAya});

  final int initialPage;
  final String? highlightAya;

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  /// Mushaf-only brightness override key: when true the reader stays on
  /// the light paper even if the rest of the app is dark. Defaults to
  /// false = the mushaf follows the app theme (historical behavior).
  static const _mushafLightKey = 'mushaf_force_light';

  late final PageController _pages;
  final _currentPage = 1.obs;
  Worker? _audioFollowWorker;
  bool _mushafLight = false;

  @override
  void initState() {
    super.initState();
    _currentPage.value = widget.initialPage.clamp(1, 604);
    _pages = PageController(initialPage: _currentPage.value - 1);
    _loadMushafBrightness();
    ensureMushafAudioController();
    // Follows the recitation: when the playing ayah lives on another page,
    // the reader jumps straight to it.
    final audio = Get.find<MushafAudioController>();
    _audioFollowWorker = everAll(
      [audio.playingSurah, audio.playingAyah, audio.trackedAyah],
      (_) => _followAudio(audio),
    );
  }

  void _followAudio(MushafAudioController audio) {
    if (!audio.active || !_pages.hasClients) return;
    final meta = Get.find<QuranController>().meta.value;
    if (meta == null) return;
    final surah = audio.playingSurah.value;
    // Single-file surah mode follows the tracked live ayah when known,
    // otherwise the surah's first page.
    final ayah = audio.playingAyah.value != 0
        ? audio.playingAyah.value
        : audio.trackedAyah.value;
    final target = ayah == 0 ? meta.start['$surah'] : meta.aya['$surah:$ayah'];
    if (target == null) return;
    final current =
        ((_pages.page ?? _pages.initialPage.toDouble()).round()) + 1;
    if (target != current) {
      _pages.jumpToPage((target - 1).clamp(0, 603));
    }
  }

  /// AppBar audio button: opens the same recitation dialogue as tapping a
  /// surah header, resolved for the currently visible page (first surah
  /// on the page + that page's ayahs).
  Future<void> _openPageAudio(
    QuranController quranCtl,
    String Function(int id) surahName,
  ) async {
    try {
      final b = await quranCtl.pageBundle(_currentPage.value);
      if (!mounted) return;
      // First surah header on the page, else the surah of its first ayah.
      var surahId = 0;
      for (final ln in b.page.lines) {
        if (ln.t == 'h' && ln.s != null) {
          surahId = int.tryParse(ln.s!) ?? 0;
          if (surahId > 0) break;
        }
      }
      if (surahId <= 0) {
        for (final ln in b.page.lines) {
          if (ln.t == 't' && ln.v != null) {
            surahId = int.tryParse(ln.v!.split(':').first) ?? 0;
            if (surahId > 0) break;
          }
        }
      }
      if (surahId <= 0) {
        debugPrint('openPageAudio: no surah on page ${_currentPage.value}');
        return;
      }
      showSurahAudioSheet(
        context,
        surahId: surahId,
        surahName: surahName(surahId),
        pageNum: _currentPage.value,
        pageAyahs: pageQueueAyahs(b.page.lines),
      );
    } catch (e) {
      debugPrint('openPageAudio failed on page ${_currentPage.value}: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح التلاوة')),
      );
    }
  }

  /// Super bookmark hub: toggle the visible page + jump to saved pages
  /// and ayahs (ayah pages resolve through the mushaf meta index).
  void _showBookmarksSheet(
    QuranController quranCtl,
    String Function(int id) surahName,
  ) {
    final settings = Get.find<SettingsController>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'العلامات',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: HusnTheme.fontFamily,
                        fontSize: HusnTheme.fontSize18,
                        fontWeight: FontWeight.bold,
                        color: HusnTheme.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      final saved = settings.isPageBookmarked(
                        _currentPage.value,
                      );
                      return saved
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.bookmark_remove_outlined),
                              label: Text(
                                'إزالة علامة الصفحة (${_currentPage.value})',
                                style: const TextStyle(
                                  fontFamily: HusnTheme.fontFamily,
                                ),
                              ),
                              onPressed: () => settings.togglePageBookmark(
                                _currentPage.value,
                              ),
                            )
                          : FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: HusnTheme.gold,
                                foregroundColor: HusnTheme.primaryDark,
                              ),
                              icon: const Icon(Icons.bookmark_add_outlined),
                              label: Text(
                                'حفظ الصفحة (${_currentPage.value})',
                                style: const TextStyle(
                                  fontFamily: HusnTheme.fontFamily,
                                ),
                              ),
                              onPressed: () => settings.togglePageBookmark(
                                _currentPage.value,
                              ),
                            );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Obx(() {
                      final list = settings.bookmarks;
                      if (list.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد علامات بعد',
                            style: TextStyle(
                              fontFamily: HusnTheme.fontFamily,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      final meta = quranCtl.meta.value;
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final b = list[i];
                          final page = b.isPage
                              ? b.page
                              : meta?.aya['${b.surah}:${b.ayah}'] ?? 0;
                          final title = b.isPage
                              ? 'صفحة ${b.page}'
                              : 'سورة ${surahName(b.surah)} · آية ${b.ayah}';
                          final subtitle = b.isPage
                              ? 'اضغط للانتقال'
                              : page > 0
                                  ? 'صفحة $page · اضغط للانتقال'
                                  : '…';
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  b.isPage
                                      ? Icons.auto_stories_outlined
                                      : Icons.bookmark_border,
                                  color: HusnTheme.primary,
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: HusnTheme.fontFamily,
                                  ),
                                ),
                                subtitle: Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontFamily: HusnTheme.fontFamily,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey,
                                  ),
                                  tooltip: 'حذف',
                                  onPressed: () =>
                                      settings.removeBookmark(b.id),
                                ),
                                onTap: page <= 0
                                    ? null
                                    : () {
                                        Navigator.of(sheetCtx).pop();
                                        _pages.jumpToPage(
                                          (page - 1).clamp(0, 603),
                                        );
                                      },
                              ),
                              const Divider(
                                height: 1,
                                thickness: 0.3,
                                indent: 56,
                              ),
                            ],
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Loads the mushaf-only brightness override (defaults to false =
  /// follow the app theme, i.e. the historical behavior).
  Future<void> _loadMushafBrightness() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _mushafLight = prefs.getBool(_mushafLightKey) ?? false;
      });
    } catch (_) {
      // Keep following the app theme when storage is unavailable.
    }
  }

  /// Simple mushaf-only light/dark toggle: forces the light paper
  /// (for readers who keep the app dark but want a bright mushaf),
  /// or back to following the app theme. Persisted across sessions.
  Future<void> _toggleMushafBrightness() async {
    setState(() => _mushafLight = !_mushafLight);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mushafLightKey, _mushafLight);
    } catch (_) {
      // Toggle still applies in-memory for this session.
    }
  }

  @override
  void dispose() {
    _audioFollowWorker?.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quranCtl = Get.find<QuranController>();
    ensureMushafAudioController();
    final canPop = Navigator.of(context).canPop();

    String surahName(int id) =>
        QuranIndex.instance.surahMeta(id)?.nameAr ??
        quranCtl.surahs.value
            ?.where((s) => s.id == id)
            .map((s) => s.suratText)
            .firstOrNull ??
        '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          // The opening-pages cover art has a transparent middle: it shows
          // whatever is behind it. With the mushaf-only light override the
          // scaffold must be light too, otherwise the dark app background
          // shines through pages 1-2.
          backgroundColor:
              _mushafLight ? const Color(0xFFFFFDF5) : null,
          appBar: AppBar(
            leading: canPop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'رجوع',
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            title: Text(
              'القرآن الملوّن',
              style: TextStyle(
                fontSize: HusnTheme.fontSize18,
                fontFamily: HusnTheme.fontFamily,
                color: bgLight,
              ),
            ),
            iconTheme: IconThemeData(color: bgLight),
            actions: [
              // Mushaf-only light toggle: keeps the light paper even when
              // the rest of the app is dark. Tap again to follow the app.
              IconButton(
                key: const ValueKey('mushaf_brightness_toggle'),
                icon: Icon(
                  _mushafLight
                      ? Icons.light_mode
                      : Icons.light_mode_outlined,
                ),
                tooltip: _mushafLight
                    ? 'المصحف: فاتح دائمًا'
                    : 'المصحف: حسب التطبيق',
                onPressed: _toggleMushafBrightness,
              ),
              // Same dialogue as tapping a surah header: reciter + whole
              // surah / page / ayah choices for the visible page.
              IconButton(
                icon: const Icon(Icons.volume_up_outlined),
                tooltip: 'التلاوة',
                onPressed: () => _openPageAudio(quranCtl, surahName),
              ),
              IconButton(
                icon: const Icon(Icons.manage_search_outlined),
                tooltip: 'البحث في الآيات',
                onPressed: () => Get.to(
                  () => AyahSearchScreen(
                    onPick: (page) =>
                        _pages.jumpToPage((page - 1).clamp(0, 603)),
                  ),
                ),
              ),
              // Super bookmark hub (pages + ayahs).
              Obx(() {
                final saved = Get.isRegistered<SettingsController>() &&
                    Get.find<SettingsController>()
                        .isPageBookmarked(_currentPage.value);
                return IconButton(
                  icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                  ),
                  tooltip: 'العلامات',
                  onPressed: () => _showBookmarksSheet(quranCtl, surahName),
                );
              }),
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'دليل ألوان التجويد',
                onPressed: () => showTajweedLegendSheet(context),
              ),
            ],
            backgroundColor: HusnTheme.primary,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pages,
                  // App is RTL; PageView inherits that direction, so swiping left
                  // advances forward through the mushaf (1 -> 604), like a real mushaf.
                  itemCount: 604,
                  onPageChanged: (i) => _currentPage.value = i + 1,
                  itemBuilder: (ctx, i) => _MushafPageLoader(
                    key: ValueKey(i + 1),
                    pageNum: i + 1,
                    surahName: surahName,
                    initialHighlight: widget.highlightAya,
                    forceLight: _mushafLight,
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _MushafMiniPlayer(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Per-page loader: subscribes to its own bundle inside its own build
/// (never `Obx` from the PageView sliver builder, which runs in the
/// layout phase and can leave pages permanently blank).
class _MushafPageLoader extends StatelessWidget {
  const _MushafPageLoader({
    super.key,
    required this.pageNum,
    required this.surahName,
    this.initialHighlight,
    this.forceLight = false,
  });

  final int pageNum;
  final String Function(int id) surahName;
  final String? initialHighlight;
  final bool forceLight;

  @override
  Widget build(BuildContext context) {
    final quranCtl = Get.find<QuranController>();
    return FutureBuilder<PageBundle>(
      future: quranCtl.pageBundle(pageNum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جارٍ تحميل الصفحة...'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'تعذّر تحميل الصفحة $pageNum:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          );
        }
        final b = snapshot.data!;
        return Obx(() {
          final meta = quranCtl.meta.value;
          return MushafPageView(
            pageNum: pageNum,
            pageData: b.page,
            tajMap: b.tajMap,
            surahName: surahName,
            surahBadge: (id) {
              final s =
                  quranCtl.surahs.value?.where((e) => e.id == id).firstOrNull;
              if (s == null) return (order: id, ayatCount: 0);
              return (order: s.id, ayatCount: s.countAyat);
            },
            juz: meta?.pageJuz['$pageNum'] ?? 1,
            highlightAya: initialHighlight,
            forceLight: forceLight,
          );
        });
      },
    );
  }
}

/// Bottom mini-player shown only while mushaf audio is loading/playing.
/// Uses the shared reciter ([MushafAudioController]) so it always matches
/// the Khatma selection.
class _MushafMiniPlayer extends StatelessWidget {
  const _MushafMiniPlayer();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MushafAudioController>()) {
      return const SizedBox.shrink();
    }
    final audio = Get.find<MushafAudioController>();
    return Obx(() {
      final active = audio.active;
      if (!active && !audio.isLoading.value) return const SizedBox.shrink();
      final hasNakhtem = Get.isRegistered<NakhtemSettingsController>();
      final lang = hasNakhtem ? khatmaLang() : 'ar';
      final reciterName = hasNakhtem ? audio.reciterLabel(lang) : '';
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Spinner only while preparing — never once playback runs.
              if (audio.isLoading.value && !audio.isPlaying.value)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: Icon(
                    audio.isPlaying.value
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: HusnTheme.primary,
                    size: 32,
                  ),
                  tooltip: audio.isPlaying.value ? 'إيقاف مؤقت' : 'تشغيل',
                  onPressed: () {
                    if (audio.isPlaying.value) {
                      audio.pause();
                    } else {
                      audio.resume();
                    }
                  },
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.playingAyah.value == 0
                          ? audio.trackedAyah.value > 0
                              ? 'سورة ${audio.queueLabel.value} • الآية ${audio.playingSurah.value}:${audio.trackedAyah.value}'
                              : 'سورة ${audio.queueLabel.value}'
                          : audio.queueLabel.value.isNotEmpty
                              ? '${audio.queueLabel.value} • الآية ${audio.playingSurah.value}:${audio.playingAyah.value}'
                              : 'الآية ${audio.playingSurah.value}:${audio.playingAyah.value}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: HusnTheme.fontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      [
                        if (audio.queueProgress != null) audio.queueProgress!,
                        reciterName,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: HusnTheme.fontFamily,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (audio.hasQueue)
                IconButton(
                  icon: const Icon(Icons.skip_next_outlined),
                  tooltip: 'الآية التالية',
                  onPressed: audio.skipNext,
                ),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined),
                tooltip: 'إيقاف',
                onPressed: audio.stop,
              ),
            ],
          ),
        ),
      );
    });
  }
}
