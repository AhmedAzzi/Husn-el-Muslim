import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/logic/mushaf_align.dart';
import '../../../../core/logic/quran_index.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../../../core/theme/tajweed_colors.dart';
import '../../../nakhtem/presentation/controllers/nakhtem_settings_controller.dart';
import '../../../nakhtem/presentation/screens/reciter_picker_screen.dart';
import '../../data/models/quran_models.dart';
import '../../presentation/providers/mushaf_audio_controller.dart';
import '../../presentation/providers/word_meaning_providers.dart';

/// The immutable coordinate system for every rendered Mushaf page.
///
/// The existing renderer already used a 560-point paper width and a 524-point
/// text measure. Keeping those values and using a fixed 560x960 portrait frame
/// gives every page the same physical dimensions; only the viewport scale is
/// allowed to vary.
abstract final class MushafPageMetrics {
  static const double width = 560;
  static const double height = 960;
  static const double horizontalPadding = 18;
  static const double topPadding = 10;
  static const double bottomPadding = 10;
  static const double headerHeight = 30;
  static const double headerGap = 8;

  static const double contentWidth = width - horizontalPadding * 2;
  static const double bodyHeight =
      height - topPadding - bottomPadding - 2 - headerHeight - headerGap;
}

/// Port of `MushafPage.svelte` + `mushaf/[page]/+page.svelte` body.
///
/// Renders one 604-edition page with per-letter tajweed colors, surah bands,
/// basmala, aya-end markers (tap = save last read), share footer and tooltip
/// bottom-sheet for tajweed rules. Now powered by GetX.
class MushafPageView extends StatelessWidget {
  const MushafPageView({
    super.key,
    required this.pageNum,
    required this.pageData,
    required this.tajMap,
    required this.surahName,
    required this.juz,
    this.surahBadge,
    this.highlightAya,
    this.forceLight = false,
  });

  final int pageNum;
  final MushafPageData pageData;
  final Map<int, List<TajAya>> tajMap;
  final String Function(int id) surahName;
  final int juz;

  /// Currently recited ayah key (`'s:v'`) — or whole-surah mode (`'s:'`,
  /// highlights every ayah of `s` on this page). Null disables.
  final String? highlightAya;

  /// Mushaf-only brightness override: when true the page always renders
  /// the light paper even if the app is in dark mode. False = follow the
  /// app theme (historical behavior).
  final bool forceLight;

  /// Surah order number + verse count for the `surah.png` header band.
  /// Falls back to the raw id with no count when omitted.
  final ({int order, int ayatCount}) Function(int id)? surahBadge;

  static const basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

  /// The fixed type scale inside the logical page canvas.
  static const double fontSize = 22;
  static const double firstPagesFontScale = 2.0;

  String _latinDigits(Object value) {
    const latin = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return value.toString().split('').map((character) {
      final index = arabic.indexOf(character);
      return index == -1 ? character : latin[index];
    }).join();
  }

  Map<String, ({String text, List<KemSlice> slices})> _kemLookup() {
    final m = <String, ({String text, List<KemSlice> slices})>{};
    tajMap.forEach((sid, list) {
      for (final a in list) {
        m['$sid:${a.a}'] = (text: a.text, slices: a.slices);
      }
    });
    return m;
  }

  List<RenderWord> _alignLine(
    List<List<String>> words,
    Map<String, ({String text, List<KemSlice> slices})> kem,
  ) {
    final groups = <({String key, List<LayWord> words})>[];
    for (final pair in words) {
      final loc = pair[0];
      final word = pair[1];
      final key = loc.split(':').take(2).join(':');
      if (groups.isNotEmpty && groups.last.key == key) {
        groups.last.words.add(LayWord(raw: word, location: loc));
      } else {
        groups.add((key: key, words: [LayWord(raw: word, location: loc)]));
      }
    }
    final out = <RenderWord>[];
    for (final g in groups) {
      final entry = kem[g.key];
      if (entry == null) {
        for (final w in g.words) {
          final d = stripVerseNumber(w.raw);
          out.add(
            RenderWord(
              segs: d.core.isEmpty
                  ? const []
                  : [RenderSeg(text: d.core, cls: '')],
              digits: d.digits,
              location: w.location,
            ),
          );
        }
        continue;
      }
      out.addAll(alignAya(entry.text, entry.slices, g.words));
    }
    return out;
  }

  /// True laid-out width of one verse line at [size]: real word widths
  /// (same text engine as the renderer) + exact aya-marker boxes. No gap
  /// allowance — the spaceBetween Row owns inter-word gaps for free.
  double _measureWords(List<RenderWord> words, double size) {
    var lineWidth = 0.0;
    for (final word in words) {
      final text = word.segs.map((s) => s.text).join();
      if (text.isNotEmpty) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: 'KemenagLPMQ',
              fontSize: size,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.rtl,
          textScaler: TextScaler.noScaling,
          maxLines: 1,
        )..layout();
        lineWidth += painter.width;
      }
      if (word.digits.isNotEmpty) {
        // Exact marker box: medallion (size*1.5 + 2) × ornament ratio 1.28.
        lineWidth += (size * 1.5 + 2) * 1.28;
      }
    }
    return lineWidth;
  }

  double _contentScale(
    List<List<RenderWord>?> aligned, {
    double availableWidth = MushafPageMetrics.contentWidth,
    double fontScale = 1.0,
  }) {
    final widths = <double>[];
    for (final words in aligned) {
      if (words == null) continue;
      widths.add(_measureWords(words, fontSize * fontScale));
    }
    if (widths.isEmpty) return 1;
    widths.sort();
    // Bind to the SECOND-widest line instead of the widest: most lines
    // grow visibly bigger, and the rare outlier line is shrunk to fit by
    // [justifiedLine]'s scale-down guard. Upscale capped at 1.25× so the
    // 15-line column (2.0 line height + header bands) never overflows
    // the fixed page frame vertically.
    final binding = widths.length > 1 ? widths[widths.length - 2] : widths.last;
    if (binding <= 0) return 1;
    final scale = (availableWidth / binding) * 0.99;
    return scale > 1 ? math.min(scale, 1.25) : scale;
  }

  /// Single font size for opening pages (1-2) so every line looks identical.
  /// Per-line `FittedBox.scaleDown` shrinks long lines more than short ones,
  /// which is why some lines looked big and others small. Measuring every
  /// verse line at [base] and scaling once by the widest line keeps all
  /// lines pixel-uniform. Factors mirror the opening render: 0.12
  /// inter-word gap, `0.95 * 1.28` aya-marker width. Basmala self-fits full
  /// width via `fitWidth`, so it is excluded from the measurement.
  double _uniformOpeningScale(
    List<List<RenderWord>?> aligned,
    double base,
    double innerWidth,
  ) {
    var widest = 0.0;
    for (final words in aligned) {
      if (words == null) continue;
      var lineWidth = 0.0;
      for (final word in words) {
        final text = word.segs.map((s) => s.text).join();
        if (text.isNotEmpty) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                fontFamily: 'KemenagLPMQ',
                fontSize: base,
                fontWeight: FontWeight.w900,
              ),
            ),
            textDirection: TextDirection.rtl,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
          )..layout();
          lineWidth += painter.width;
        }
        if (word.digits.isNotEmpty) {
          lineWidth += base * 0.95 * 1.28;
        }
      }
      if (words.length > 1) {
        lineWidth += (words.length - 1) * base * 0.12;
      }
      widest = math.max(widest, lineWidth);
    }
    if (widest <= innerWidth || widest == 0) return 1;
    return (innerWidth / widest) * 1.0;
  }

  List<int> _pageSurahs() {
    final ids = <int>[];
    for (final ln in pageData.lines) {
      if (ln.t == 'h' && ln.s != null) {
        final id = int.tryParse(ln.s!);
        if (id != null && !ids.contains(id)) ids.add(id);
      }
    }
    if (ids.isEmpty) {
      for (final ln in pageData.lines) {
        if (ln.t == 't' && ln.v != null) {
          final id = int.tryParse(ln.v!.split(':').first);
          if (id != null) {
            ids.add(id);
            break;
          }
        }
      }
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    // Mushaf-only brightness override: `forceLight` keeps the light paper
    // even when the rest of the app is dark. Otherwise the page follows
    // the app theme (historical behavior).
    final dark = forceLight
        ? false
        : Theme.of(context).brightness == Brightness.dark;
    final kem = _kemLookup();
    final surahs = _pageSurahs();
    final openingPage = pageNum <= 2;

    /// Aya markers open the main multi-tab dialogue (المعنى / التجويد /
    /// التفسير / الترجمة) directly on the التفسير tab for that ayah.
    void onMarkerTap(String location) {
      if (!Get.isRegistered<WordMeaningController>()) return;
      WordMeaningController.to.showWordDialog(context, location, initialTab: 2);
    }

    /// True when this word belongs to the currently recited ayah.
    /// `'s:'` (whole-surah single-file mode) matches every ayah of `s`.
    bool isHighlighted(RenderWord word) {
      final key = highlightAya;
      if (key == null || key.isEmpty) return false;
      if (key.endsWith(':')) return word.location.startsWith(key);
      return word.location.split(':').take(2).join(':') == key;
    }

    /// Single entry point for every word tap: plain taps open المعنى,
    /// colored-segment taps open التجويد — same centered dialog, no ambiguity.
    void onWordTap(RenderWord word, {String tappedCls = ''}) {
      if (!Get.isRegistered<WordMeaningController>()) return;
      final classes = <String>[];
      for (final seg in word.segs) {
        if (seg.cls.isNotEmpty && !classes.contains(seg.cls)) {
          classes.add(seg.cls);
        }
      }
      WordMeaningController.to.showWordDialog(
        context,
        word.location,
        tajweedClasses: classes,
        initialTab: tappedCls.isEmpty ? 0 : 1,
      );
    }

    Widget wordText(
      RenderWord w, {
      required Color base,
      required double size,
      required double lineHeight,
    }) {
      final highlighted = isHighlighted(w);
      final highlightBg =
          highlighted ? HusnTheme.gold.withValues(alpha: 0.35) : null;
      final spans = <InlineSpan>[];
      for (final s in w.segs) {
        final color =
            s.cls.isEmpty ? base : TajweedColors.of(s.cls, dark: dark);
        spans.add(
          TextSpan(
            text: s.text,
            style: TextStyle(
              fontFamily: 'KemenagLPMQ',
              color: color,
              backgroundColor: highlightBg,
              fontSize: size,
              height: lineHeight,
              fontWeight: FontWeight.w900,
            ),
            recognizer: s.cls.isEmpty
                ? (TapGestureRecognizer()..onTap = () => onWordTap(w))
                : (TapGestureRecognizer()
                  ..onTap = () => onWordTap(w, tappedCls: s.cls)),
          ),
        );
      }
      return RichText(
        textDirection: TextDirection.rtl,
        softWrap: false,
        overflow: TextOverflow.visible,
        textScaler: TextScaler.noScaling,
        strutStyle: StrutStyle(
          fontFamily: 'KemenagLPMQ',
          fontSize: size,
          height: lineHeight,
          forceStrutHeight: true,
          fontWeight: FontWeight.w900,
        ),
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'KemenagLPMQ',
            color: base,
            fontSize: size,
            height: lineHeight,
            fontWeight: FontWeight.w900,
          ),
          children: spans,
        ),
      );
    }

    Widget ayaMarker(
      RenderWord w, {
      required double size,
      required double lineHeight,
    }) {
      final highlighted = isHighlighted(w);
      final numColor = highlighted
          ? HusnTheme.gold
          : (dark
              ? const Color(0xFFFFFFFF)
              : (openingPage ? const Color(0xFF1E1E1E) : AppPalette.ayaMark));
      final ornamentAsset =
          dark ? 'assets/images/ayah_dark.png' : 'assets/images/ayah_light.png';

      // ============================================================
      // MARKER MASTER SIZE
      // ============================================================
      final medallion = size * 1.5;
      final ornamentWidth = medallion * 1;

      // ============================================================
      // ORNAMENT POSITION
      //
      // These values move the WHOLE ornament image.
      //
      // X:
      //   positive = right
      //   negative = left
      //
      // Y:
      //   positive = down
      //   negative = up
      // ============================================================
      final markerX = 0.0;
      final markerY = -medallion * 0.1;

      // ============================================================
      // NUMBER (centered in the ornament's hollow)
      // ============================================================
      final numberSize = medallion * 0.34;

      // Position of the number relative to the marker.
      final numberX = 0.0;
      final numberY = 0.0;

      return RichText(
        textDirection: TextDirection.rtl,
        softWrap: false,
        overflow: TextOverflow.visible,
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'KemenagLPMQ',
            fontSize: size,
            height: lineHeight,
            // make bold
          ),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => onMarkerTap(w.location),
                child: SizedBox(
                  width: ornamentWidth,
                  height: medallion,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ==========================================================
                      // ORNAMENT IMAGE (ayah_dark / ayah_light)
                      // ==========================================================
                      Positioned(
                        left: (ornamentWidth - medallion) / 2 + markerX,
                        top: markerY,
                        width: medallion,
                        height: medallion,
                        child: Image.asset(
                          ornamentAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              '۝',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: numColor,
                                fontFamily: 'AmiriQuran',
                                fontSize: medallion,
                                height: 1.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ==========================================================
                      // NUMBER
                      // ==========================================================
                      Positioned(
                        left: (ornamentWidth - numberSize) / 2 +
                            markerX +
                            numberX,
                        top: (medallion - numberSize) / 2 + markerY + numberY,
                        width: numberSize,
                        height: numberSize,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _latinDigits(w.digits),
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              softWrap: false,
                              style: TextStyle(
                                color: numColor,
                                fontFamily: 'AmiriQuran',
                                fontSize: numberSize,
                                height: 1.0,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      );
    }

    List<Widget> lineItems(
      List<RenderWord> words,
      double size,
      double lh,
      Color base,
    ) {
      final items = <Widget>[];
      for (final w in words) {
        if (w.segs.isNotEmpty) {
          items.add(wordText(w, base: base, size: size, lineHeight: lh));
        }
        if (w.digits.isNotEmpty) {
          items.add(ayaMarker(w, size: size, lineHeight: lh));
        }
      }
      return items;
    }

    final pagePadding =
        openingPage ? 96.0 : MushafPageMetrics.horizontalPadding;
    final pageTopPadding = openingPage ? 192.0 : MushafPageMetrics.topPadding;
    final pageBottomPadding =
        openingPage ? 215.0 : MushafPageMetrics.bottomPadding;
    final pageContentWidth =
        openingPage ? 368.0 : (MushafPageMetrics.width - pagePadding * 2);
    // Inner verse width inside the opening frame after horizontal padding.
    // Widened frame (392) + tighter padding to raise the uniform-fit
    // ceiling: the longest 8-word line dictates every line's size.
    const openingFrameWidth = 392.0;
    const openingHorizontalPadding = 18.0;
    const openingInnerWidth = openingFrameWidth - openingHorizontalPadding * 2;

    /// True mushaf justification: one data line == exactly one visual
    /// line. `TextAlign.justify` cannot do this in Flutter because it
    /// never justifies the last (here: only) line and it wraps long
    /// lines, leaving a 1-word tail stretched with huge gaps (see the
    /// «رَقِيبًا» / «كَبِيرًا» orphans). A nowrap [Row] with
    /// [MainAxisAlignment.spaceBetween] is the
    /// `text-align-last: justify` equivalent and cannot wrap by
    /// construction: inter-word gaps absorb the free space, so the
    /// line always spans edge-to-edge. Words carry no trailing space
    /// (gaps are owned by the Row), and each word is `softWrap: false`,
    /// so a word can never spill onto a second visual row.
    /// The logical page is bounded by [MushafPageMetrics], so the viewport
    /// scales this complete row together with every other page element.
    Widget justifiedLine(List<RenderWord> words, double size) {
      final base = dark ? const Color(0xFFE5E7EB) : Colors.black;
      final lh = openingPage ? 1.5 : 2.0;
      final items = lineItems(words, size, lh, base);
      if (items.isEmpty) return const SizedBox.shrink();
      if (items.length == 1) {
        return Center(child: items.first);
      }
      final row = Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: items,
      );
      if (openingPage) {
        final row = Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: size * 0.12,
          children: items,
        );
        return SizedBox(
          width: openingInnerWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: row,
          ),
        );
      }
      // Outlier guard: the uniform size binds to the second-widest line,
      // so a rarer wider line is shrunk to fit instead of overflowing.
      final trueWidth = _measureWords(words, size);
      if (trueWidth <= pageContentWidth) return row;
      return SizedBox(
        width: pageContentWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(width: trueWidth, child: row),
        ),
      );
    }

    Widget centeredLine(List<RenderWord> words, double size) {
      final base = dark ? const Color(0xFFE5E7EB) : Colors.black;
      final lh = openingPage ? 1.5 : 2.0;
      final items = lineItems(words, size, lh, base);
      if (items.isEmpty) return const SizedBox.shrink();
      final row = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        spacing: size * (openingPage ? 0.10 : 0.35),
        children: items,
      );
      if (openingPage) {
        return SizedBox(
          width: openingInnerWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: row,
          ),
        );
      }
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Transform.scale(scale: 0.8, child: row),
      );
    }

    // Page 2 ships with 5 text lines + basmala = 6 rows; rebalance its
    // words into 6 text lines so it renders 7 rows including basmala,
    // matching page 1. Page 1 already has 6 text lines + basmala.
    var effectiveLines = pageData.lines;
    if (openingPage && pageNum == 2) {
      final tWords = <List<String>>[];
      String? lastV;
      for (final ln in pageData.lines) {
        if (ln.t == 't') {
          lastV = ln.v ?? lastV;
          tWords.addAll(ln.w);
        }
      }
      final tCount = pageData.lines.where((l) => l.t == 't').length;
      const targetT = 6;
      // Exact user-approved break pattern (word counts per verse line):
      // 7 / 5 / 4 / 8 / 6 / 6 = 36 words total.
      const pattern = [7, 5, 4, 8, 6, 6];
      if (tWords.isNotEmpty && tCount < targetT) {
        final chunks = <List<List<String>>>[];
        var idx = 0;
        final usePattern = tWords.length == pattern.reduce((a, b) => a + b);
        if (usePattern) {
          for (final size in pattern) {
            final end = (idx + size).clamp(0, tWords.length);
            chunks.add(tWords.sublist(idx, end));
            idx = end;
          }
        } else {
          final base = tWords.length ~/ targetT;
          var rem = tWords.length % targetT;
          for (var c = 0; c < targetT && idx < tWords.length; c++) {
            var size = base + (rem > 0 ? 1 : 0);
            if (rem > 0) rem--;
            if (size <= 0) size = 1;
            final end = (idx + size).clamp(0, tWords.length);
            chunks.add(tWords.sublist(idx, end));
            idx = end;
          }
        }
        final rebuilt = <MushafLine>[];
        var ci = 0;
        for (final ln in pageData.lines) {
          if (ln.t == 't') {
            if (ci < chunks.length) {
              rebuilt.add(MushafLine(t: 't', v: ln.v, w: chunks[ci++]));
            }
          } else {
            rebuilt.add(ln);
          }
        }
        while (ci < chunks.length) {
          rebuilt.add(MushafLine(t: 't', v: lastV, w: chunks[ci++]));
        }
        effectiveLines = rebuilt;
      }
    }

    // Surah header for the cover band overlay.
    // Prefers the page data (`h` line), falls back to hardcoded names.
    var openingSurahName =
        pageNum == 1 ? 'سُورَةُ ٱلْفَاتِحَةِ' : 'سُورَةُ ٱلْبَقَرَةِ';
    int? openingSurahId = pageNum;
    for (final ln in effectiveLines) {
      if (ln.t == 'h') {
        if ((ln.x ?? '').isNotEmpty) openingSurahName = ln.x!;
        openingSurahId = int.tryParse(ln.s ?? '') ?? openingSurahId;
        break;
      }
    }
    // Vocalized cover title (page data carries plain names).
    final openingVocalized = openingSurahId == null
        ? null
        : QuranIndex.instance.surahMeta(openingSurahId)?.nameAr;
    if (openingVocalized != null && openingVocalized.isNotEmpty) {
      openingSurahName = 'سُورَةُ $openingVocalized';
    }
    final openingBadge = _badgeTexts(openingSurahId);

    // Pre-align once per build so each logical line remains a single row.
    final aligned = <List<RenderWord>?>[];
    for (final ln in effectiveLines) {
      aligned.add(ln.t == 't' ? _alignLine(ln.w, kem) : null);
    }
    // Uniform size for opening pages: one scale for all lines so short
    // and long lines render identically instead of shrinking per-line.
    double unifiedOpeningSize = pageNum == 1 ? 65.0 : 71.0;
    if (openingPage) {
      final base = unifiedOpeningSize;
      unifiedOpeningSize =
          base * _uniformOpeningScale(aligned, base, openingInnerWidth);
    }
    final fittedScale = _contentScale(
      aligned,
      availableWidth: pageContentWidth,
    );
    final contentFontSize = openingPage ? 22.0 : (fontSize * fittedScale);
    final headerFontSize = openingPage ? 22.0 : (fontSize * fittedScale);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final viewportWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MushafPageMetrics.width;
        final viewportHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : MushafPageMetrics.height;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: ValueKey('mushaf-page-$pageNum'),
            width: viewportWidth,
            height: viewportHeight,
            child: FittedBox(
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
              child: MediaQuery.withNoTextScaling(
                child: SizedBox(
                  width: MushafPageMetrics.width,
                  height: MushafPageMetrics.height,
                  child: Stack(
                    children: [
                      if (openingPage) ...[
                        // Single illumination frame for both opening pages.
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/cover.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                        // The `surah.png` header band laid over the cover's
                        // built-in header. Nudge to fully cover it.
                        Positioned(
                          left: 107.0,
                          top: 138.0,
                          width: 347.0,
                          height: 64.0,
                          child: _surahBand(
                            name: openingSurahName,
                            orderText: openingBadge.orderText,
                            ayatText: openingBadge.ayatText,
                            height: 60,
                            verticalMargin: 2,
                            dark: dark,
                            onTap: () => _playFullSurah(
                              context,
                              openingSurahId,
                              openingSurahName,
                            ),
                          ),
                        ),
                        // Verses container positioned exactly inside the inner frame box
                        Positioned(
                          left: 84.0,
                          top: 230.0,
                          width: 392.0,
                          height: 553.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 38.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var li = 0;
                                    li < effectiveLines.length;
                                    li++)
                                  if (effectiveLines[li].t != 'h')
                                    Align(
                                      alignment: Alignment.center,
                                      child: _buildLogicalLine(
                                        context,
                                        effectiveLines[li],
                                        aligned[li],
                                        pageNum == 1 && (li == 4 || li == 7),
                                        unifiedOpeningSize,
                                        dark,
                                        centeredLine,
                                        justifiedLine,
                                        openingPage: true,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Standard page container for pages >= 3
                        Container(
                          width: MushafPageMetrics.width,
                          height: MushafPageMetrics.height,
                          padding: EdgeInsets.fromLTRB(
                            pagePadding,
                            pageTopPadding,
                            pagePadding,
                            pageBottomPadding,
                          ),
                          decoration: BoxDecoration(
                            color:
                                dark ? AppPalette.darkCard : AppPalette.paper,
                            border: Border.all(
                              color: dark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5D9B8),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          foregroundDecoration: BoxDecoration(
                            border: Border.all(
                              color: dark
                                  ? const Color(0xFF4B5563)
                                  : AppPalette.gold,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: MushafPageMetrics.headerHeight,
                                child: Container(
                                  // padding: const EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: dark
                                            ? const Color(0xFF374151)
                                            : const Color(0xFFE5D9B8),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (surahs.isNotEmpty)
                                        Text(
                                          surahs.map(surahName).join('، '),
                                          style: TextStyle(
                                            fontFamily: 'KemenagLPMQ',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: dark
                                                ? const Color(0xFFE5E7EB)
                                                : Colors.black,
                                          ),
                                        ),
                                      Text(
                                        pageNum.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'KemenagLPMQ',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: dark
                                              ? const Color(0xFFE5E7EB)
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'الجزء $juz',
                                        style: TextStyle(
                                          fontFamily: 'KemenagLPMQ',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: dark
                                              ? const Color(0xFFE5E7EB)
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: MushafPageMetrics.headerGap,
                              ),
                              SizedBox(
                                width: pageContentWidth,
                                height: MushafPageMetrics.bodyHeight,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (var li = 0;
                                        li < pageData.lines.length;
                                        li++)
                                      Align(
                                        alignment: Alignment.center,
                                        child: _buildLogicalLine(
                                          context,
                                          pageData.lines[li],
                                          aligned[li],
                                          false,
                                          pageData.lines[li].t == 'h'
                                              ? headerFontSize
                                              : contentFontSize,
                                          dark,
                                          centeredLine,
                                          justifiedLine,
                                          openingPage: false,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Surah name inside the center cartouche of `surah.png`.
  ///
  /// The cartouche is transparent, so the page background shows through:
  /// black text on the light paper, white text on the dark card.
  Widget _bandName(String text, {required bool dark}) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'KemenagLPMQ',
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w900,
            color: dark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  /// Label + value inside a green side medallion of `surah.png`.
  Widget _bandOval(String label, String value) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'KemenagLPMQ',
                fontSize: 9,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 1.5,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'KemenagLPMQ',
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 1.5,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Authentic header band: `surah.png` art with the surah name in the
  /// white cartouche, order number (ترتيبها) in the right medallion and
  /// verse count (آياتها) in the left one. Flexes mirror the artwork
  /// layout (measured from surah.png pixels).
  Widget _surahBand({
    required String name,
    required String orderText,
    required String ayatText,
    required double height,
    required bool dark,
    double verticalMargin = 2,
    VoidCallback? onTap,
  }) {
    Widget band = Center(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: verticalMargin),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/surah.png',
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: dark
                        ? const Color(0xFF3E252B)
                        : const Color(0xFF5A3038),
                    alignment: Alignment.center,
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'KemenagLPMQ',
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    // Fractions measured from surah.png pixels:
                    // ovals 0.161-0.232 / 0.766-0.838, panel 0.245-0.753.
                    children: [
                      const Spacer(flex: 162),
                      Expanded(
                        flex: 72,
                        child: _bandOval('ترتيبها', orderText),
                      ),
                      const Spacer(flex: 13),
                      Expanded(
                          flex: 508, child: _bandName(name, dark: dark)),
                      const Spacer(flex: 13),
                      Expanded(flex: 71, child: _bandOval('آياتها', ayatText)),
                      const Spacer(flex: 161),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: band);
    }
    return band;
  }

  /// Tapping a surah header band opens the recitation dialogue (surah /
  /// page / ayah choices) instead of reciting directly.
  void _playFullSurah(BuildContext context, int? surahId, String surahName) {
    _showSurahSheet(
      context,
      surahId,
      surahName,
      pageNum: pageNum,
      pageAyahs: pageQueueAyahs(pageData.lines),
    );
  }

  /// Badge texts for a surah header: Latin order number + verse count.
  ({String orderText, String ayatText}) _badgeTexts(int? surahId) {
    final badge = surahId == null ? null : surahBadge?.call(surahId);
    return (
      orderText: _latinDigits(badge?.order ?? surahId ?? ''),
      ayatText: badge == null || badge.ayatCount <= 0
          ? ''
          : _latinDigits(badge.ayatCount),
    );
  }

  Widget _buildLogicalLine(
    BuildContext context,
    MushafLine line,
    List<RenderWord>? words,
    bool centerText,
    double size,
    bool dark,
    Widget Function(List<RenderWord>, double) centeredLine,
    Widget Function(List<RenderWord>, double) justifiedLine, {
    bool openingPage = false,
  }) {
    if (line.t == 'h') {
      final surahId = int.tryParse(line.s ?? '');
      final badge = _badgeTexts(surahId);
      // Vocalized band title (page data carries plain names).
      final vocalized = surahId == null
          ? null
          : QuranIndex.instance.surahMeta(surahId)?.nameAr;
      final bandName = vocalized != null && vocalized.isNotEmpty
          ? 'سُورَةُ $vocalized'
          : (line.x ?? '');
      return _surahBand(
        name: bandName,
        orderText: badge.orderText,
        ayatText: badge.ayatText,
        height: 72,
        dark: dark,
        onTap: () => _playFullSurah(context, surahId, bandName),
      );
    }
    if (line.t == 'b') {
      final basmalaText = Text(
        basmala,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontFamily: 'KemenagLPMQ',
          fontSize: openingPage ? size * 0.45 : size,
          height: openingPage ? 1.4 : 2,
          fontWeight: FontWeight.w900,
          color: dark ? const Color(0xFFE5E7EB) : Colors.black,
        ),
      );
      if (openingPage) {
        // Full-width basmala, inset to read ~3pt smaller.
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.center,
              child: basmalaText,
            ),
          ),
        );
      }
      return basmalaText;
    }
    return centerText
        ? centeredLine(words ?? const [], size)
        : justifiedLine(words ?? const [], size);
  }
}

/// Shared reciter guard for mushaf audio sheets: returns true when a
/// reciter is selected, otherwise closes the sheet and navigates to the
/// picker (or toasts when audio is unavailable).
bool _requireReciterForAudio(
  BuildContext context,
  BuildContext sheetCtx,
  bool hasNakhtem,
) {
  if (!hasNakhtem) {
    Navigator.of(sheetCtx).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('الصوت غير متاح')));
    return false;
  }
  if (Get.find<NakhtemSettingsController>().selectedMushafReciter == null) {
    Navigator.of(sheetCtx).pop();
    showReciterPickerSheet(forKhatma: false);
    return false;
  }
  return true;
}

/// Shows the latest [MushafAudioController] error (if any) as a snackbar.
void _reportAudioError(BuildContext context) {
  if (!Get.isRegistered<MushafAudioController>()) return;
  final err = Get.find<MushafAudioController>().error.value;
  if (err != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err == 'no_reciter' ? 'اختر القارئ أولًا' : 'تعذّر تشغيل الصوت',
        ),
      ),
    );
  }
}

/// Public entry to the surah recitation dialogue (same sheet as tapping a
/// surah header band): shared reciter plus whole-surah / page / ayah
/// choices. Used by the reader AppBar audio button for the visible page.
void showSurahAudioSheet(
  BuildContext context, {
  required int surahId,
  required String surahName,
  required int pageNum,
  required List<QueueAya> pageAyahs,
}) {
  _showSurahSheet(
    context,
    surahId,
    surahName,
    pageNum: pageNum,
    pageAyahs: pageAyahs,
  );
}

/// Tapping a surah header band opens the recitation dialogue: the shared
/// reciter plus three choices — whole surah, current page, or one ayah.
void _showSurahSheet(
  BuildContext context,
  int? surahId,
  String surahName, {
  required int pageNum,
  required List<QueueAya> pageAyahs,
}) {
  if (surahId == null || surahId <= 0) return;
  ensureMushafAudioController();
  final hasNakhtem = Get.isRegistered<NakhtemSettingsController>();
  final lang = hasNakhtem ? khatmaLang() : 'ar';
  final ayahCount = QuranIndex.instance.surahMeta(surahId)?.ayahCount ?? 0;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  surahName.isNotEmpty ? surahName : 'سورة $surahId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: HusnTheme.fontFamily,
                    fontSize: HusnTheme.fontSize18,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasNakhtem)
                  Obx(() {
                    final ctl = Get.find<NakhtemSettingsController>();
                    final r = ctl.selectedMushafReciter;
                    return ListTile(
                      leading: const Icon(
                        Icons.volume_up_outlined,
                        color: HusnTheme.primary,
                      ),
                      title: Text(
                        r?.titleFor(lang) ?? 'اختر القارئ',
                        style: const TextStyle(
                          fontFamily: HusnTheme.fontFamily,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        showReciterPickerSheet(forKhatma: false);
                      },
                    );
                  }),
                const SizedBox(height: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: HusnTheme.gold,
                    foregroundColor: HusnTheme.primaryDark,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.playlist_play),
                  label: const Text(
                    'تلاوة السورة كاملة',
                    style: TextStyle(
                      fontFamily: HusnTheme.fontFamily,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () async {
                    if (!_requireReciterForAudio(
                      context,
                      sheetCtx,
                      hasNakhtem,
                    )) {
                      return;
                    }
                    Navigator.of(sheetCtx).pop();
                    await Get.find<MushafAudioController>().playSurah(surahId);
                    if (!context.mounted) return;
                    _reportAudioError(context);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.auto_stories_outlined,
                          color: HusnTheme.primary,
                        ),
                        label: Text(
                          'تلاوة الصفحة ($pageNum)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: HusnTheme.fontFamily,
                          ),
                        ),
                        onPressed: () async {
                          if (!_requireReciterForAudio(
                            context,
                            sheetCtx,
                            hasNakhtem,
                          )) {
                            return;
                          }
                          if (pageAyahs.isEmpty) {
                            Navigator.of(sheetCtx).pop();
                            return;
                          }
                          Navigator.of(sheetCtx).pop();
                          await Get.find<MushafAudioController>().playPage(
                            pageAyahs,
                            label: 'صفحة $pageNum',
                          );
                          if (!context.mounted) return;
                          _reportAudioError(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.audiotrack_outlined,
                          color: HusnTheme.primary,
                        ),
                        label: const Text(
                          'تلاوة آية',
                          style: TextStyle(fontFamily: HusnTheme.fontFamily),
                        ),
                        onPressed: ayahCount <= 0
                            ? null
                            : () => _showSurahAyahPicker(
                                  context,
                                  surahId,
                                  surahName,
                                  ayahCount,
                                  hasNakhtem,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Ayah picker inside the surah dialogue: a number grid for that surah;
/// tapping one recites just that ayah.
void _showSurahAyahPicker(
  BuildContext context,
  int surah,
  String surahName,
  int ayahCount,
  bool hasNakhtem,
) {
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
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    surahName.isNotEmpty
                        ? 'اختر الآية — $surahName'
                        : 'اختر الآية — سورة $surah',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: HusnTheme.fontFamily,
                      fontSize: HusnTheme.fontSize18,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: ayahCount,
                    itemBuilder: (ctx, i) {
                      final ayah = i + 1;
                      return Material(
                        color: HusnTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            if (!_requireReciterForAudio(
                              context,
                              sheetCtx,
                              hasNakhtem,
                            )) {
                              return;
                            }
                            // Close the picker, then the surah dialogue.
                            Navigator.of(sheetCtx).pop();
                            Navigator.of(context).pop();
                            await Get.find<MushafAudioController>().play(
                              surah,
                              ayah,
                            );
                            if (!context.mounted) return;
                            _reportAudioError(context);
                          },
                          child: Center(
                            child: Text(
                              '$ayah',
                              style: const TextStyle(
                                fontFamily: HusnTheme.fontFamily,
                                fontSize: HusnTheme.fontSize18,
                                color: HusnTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Ayahs visible on a mushaf page, in reading order, derived from the
/// word-level locations (`s:v:...`) so they stay exact even on the
/// rebalanced opening pages.
List<QueueAya> pageQueueAyahs(List<MushafLine> lines) {
  final out = <QueueAya>[];
  final seen = <String>{};
  for (final ln in lines) {
    if (ln.t != 't') continue;
    for (final pair in ln.w) {
      if (pair.isEmpty) continue;
      final parts = pair[0].split(':');
      if (parts.length < 2) continue;
      final s = int.tryParse(parts[0]);
      final v = int.tryParse(parts[1]);
      if (s == null || v == null) continue;
      if (seen.add('$s:$v')) out.add((surah: s, ayah: v));
    }
  }
  return out;
}
