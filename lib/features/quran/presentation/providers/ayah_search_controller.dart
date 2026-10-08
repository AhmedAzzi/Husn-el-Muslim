import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/logic/quran_index.dart';
import '../../data/models/quran_models.dart';
import 'quran_providers.dart';

/// One ayah search hit.
class AyahSearchHit {
  const AyahSearchHit({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.page,
  });

  final int surah;
  final int ayah;
  final String text;
  final int page;
}

/// Smart offline ayah search over the bundled mushaf text (per-surah taj
/// files — no network, no extra assets).
///
/// Smart behaviors:
/// - Arabic-insensitive matching: tashkeel/tatweel/Quranic marks stripped,
///   alef forms, taa marbuta, hamza seats, kaf/yeh variants unified, bare
///   hamza dropped — on both sides, so typing without tashkeel just works.
/// - Uthmani-tolerant tiers: exact phrase → all-words AND → alef-insensitive
///   skeleton (رحمان finds الرحمن, ذالك finds ذلك) → weak-letter skeleton
///   (الصلاة finds الصلوة, السماوات finds السموات).
/// - Multi-word AND: every query word must appear (any order); exact phrase
///   matches rank first.
/// - Direct references: `2:255`, `2-255`, `٢:٢٥٥` jump straight to the ayah.
/// - Results carry their mushaf page for one-tap opening.
/// - `totalCount` holds the full match count even when the displayed list is
///   capped at [resultLimit].
class AyahSearchController extends GetxController {
  static const int resultLimit = 120;
  static const Duration debounce = Duration(milliseconds: 350);

  final query = ''.obs;
  final hits = <AyahSearchHit>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;
  final totalCount = 0.obs;

  final Map<int, List<TajAya>> _tajCache = {};
  Timer? _debounce;

  // Batch 2 (perf-only): normalized corpus. normAr() per ayah per keystroke
  // (~6236 × regex recompiles) dominates search cost. Normalization is a pure
  // function of the ayah text, so cache it once per loaded corpus; rebuilt
  // only when the corpus grows. Matching logic, order, and caps unchanged.
  final Map<String, String> _normCache = {};
  final Map<String, String> _skelCache = {};
  final Map<String, String> _consCache = {};
  int _normCacheAyahCount = -1;

  // Hoisted: identical patterns, compiled once instead of per call.
  // Covers harakat/shadda/sukun/maddah (U+064B-065F), other vocalization
  // marks (U+0610-061A), superscript alef (U+0670), tatweel (U+0640),
  // Quranic annotation/waqf signs (U+06D6-06ED), extended Quranic marks
  // (U+08D3-08FF), and zero-width joiners (U+200C-200D).
  static final RegExp _diacritics = RegExp(
    '[\u0610-\u061A\u0640\u064B-\u065F\u0670\u06D6-\u06ED\u08D3-\u08FF\u200C\u200D]',
  );
  static final RegExp _alefForms = RegExp('[أإآٱ\u0672\u0673\u0675]');
  static final RegExp _kafForms = RegExp('[ك\u06A9]');
  static final RegExp _yehForms = RegExp('[ي\u06CC\u06D0\u06D2]');
  static final RegExp _tehForms = RegExp('[ة\u06C3]');
  static final RegExp _weakLetters = RegExp('[اوي]');
  static final RegExp _whitespace = RegExp(r'\s+');

  void setQuery(String q) {
    query.value = q;
    _debounce?.cancel();
    _debounce = Timer(debounce, () => search(q));
  }

  Future<void> search(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      hits.clear();
      totalCount.value = 0;
      hasSearched.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final ref = _parseReference(q);
      if (ref != null) {
        final hit = await _referenceHit(ref.$1, ref.$2);
        hits.value = hit == null ? [] : [hit];
        totalCount.value = hits.length;
      } else {
        await _ensureAllLoaded();
        hits.value = _filter(q);
      }
      hasSearched.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// `surah:ayah` in Latin or Arabic-Indic digits (`٢:٢٥٥`), separators `: - /`.
  (int, int)? _parseReference(String q) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final latin = q.split('').map((c) {
      final i = arabic.indexOf(c);
      return i == -1 ? c : '$i';
    }).join();
    final m =
        RegExp(r'^\s*(\d{1,3})\s*[:\-/]\s*(\d{1,3})\s*$').firstMatch(latin);
    if (m == null) return null;
    final s = int.parse(m.group(1)!);
    final a = int.parse(m.group(2)!);
    final meta = QuranIndex.instance.surahMeta(s);
    if (meta == null || a < 1 || a > meta.ayahCount) return null;
    return (s, a);
  }

  Future<AyahSearchHit?> _referenceHit(int surah, int ayah) async {
    final repo = Get.find<QuranController>().repo;
    try {
      var list = _tajCache[surah];
      list ??= await repo.loadTaj(surah);
      _tajCache[surah] = list;
      final text = _ayahText(list, ayah);
      return AyahSearchHit(
        surah: surah,
        ayah: ayah,
        text: text,
        page: _pageOf(surah, ayah),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureAllLoaded() async {
    if (_tajCache.length >= 114) return;
    final repo = Get.find<QuranController>().repo;
    final missing = [
      for (var s = 1; s <= 114; s++)
        if (!_tajCache.containsKey(s)) s,
    ];
    final loaded = await Future.wait([
      for (final s in missing)
        () async {
          try {
            return MapEntry(s, await repo.loadTaj(s));
          } catch (_) {
            return MapEntry(s, const <TajAya>[]);
          }
        }(),
    ]);
    for (final e in loaded) {
      _tajCache[e.key] = e.value;
    }
  }

  /// Tokenizes a raw query exactly as [_filter] does (shared so highlight
  /// code never recompiles the splitter per row).
  static List<String> queryTokens(String q) => normAr(q)
      .split(_whitespace)
      .where((t) => t.isNotEmpty)
      .toList();

  /// Alef-stripped skeleton of a raw string (Uthmani-tolerant: رحمان matches
  /// الرحمن, ذالك matches ذلك). Derived from [normAr], never for display.
  static String skeletonAr(String s) => normAr(s).replaceAll('ا', '');

  /// Weak-letter skeleton of a raw string (الصلوة/الصلاة, السموات/السماوات
  /// converge). Derived from [normAr], never for display.
  static String consonantAr(String s) =>
      normAr(s).replaceAll(_weakLetters, '');

  /// Token lists for the skeleton tiers, mirroring [queryTokens].
  static List<String> skeletonTokens(String q) => skeletonAr(q)
      .split(_whitespace)
      .where((t) => t.isNotEmpty)
      .toList();
  static List<String> consonantTokens(String q) => consonantAr(q)
      .split(_whitespace)
      .where((t) => t.isNotEmpty)
      .toList();

  List<AyahSearchHit> _filter(String q) {
    final normQ = normAr(q);
    final tokens = queryTokens(q);
    if (tokens.isEmpty) {
      totalCount.value = 0;
      return [];
    }
    final skelQ = skeletonAr(q);
    final skelTokens = skeletonTokens(q);
    final consQ = consonantAr(q);
    final consTokens = consonantTokens(q);
    _refreshNormCache();
    final ranked = <({AyahSearchHit hit, int rank})>[];
    for (var s = 1; s <= 114; s++) {
      final list = _tajCache[s] ?? const <TajAya>[];
      for (final t in list) {
        final key = '$s:${t.a}';
        final normT = _normCache[key] ?? normAr(t.text);
        final rank = _rank(
          normT,
          normQ,
          tokens,
          _skelCache[key] ?? skeletonAr(t.text),
          skelQ,
          skelTokens,
          _consCache[key] ?? consonantAr(t.text),
          consQ,
          consTokens,
        );
        if (rank < 0) continue;
        ranked.add((
          hit: AyahSearchHit(
            surah: s,
            ayah: t.a,
            text: t.text,
            page: _pageOf(s, t.a),
          ),
          rank: rank,
        ));
      }
    }
    ranked.sort((a, b) {
      final r = a.rank.compareTo(b.rank);
      if (r != 0) return r;
      final s = a.hit.surah.compareTo(b.hit.surah);
      return s != 0 ? s : a.hit.ayah.compareTo(b.hit.ayah);
    });
    totalCount.value = ranked.length;
    return [for (final r in ranked.take(resultLimit)) r.hit];
  }

  /// Rebuilds the normalized corpus only when ayahs were added since the
  /// last build (first search, or reference-hit loads racing a full load).
  /// Covers every cached ayah, so [_filter] hits the cache for all of them.
  void _refreshNormCache() {
    var count = 0;
    for (var s = 1; s <= 114; s++) {
      count += _tajCache[s]?.length ?? 0;
    }
    if (count == _normCacheAyahCount) return;
    for (var s = 1; s <= 114; s++) {
      final list = _tajCache[s] ?? const <TajAya>[];
      for (final t in list) {
        final key = '$s:${t.a}';
        final norm = _normCache.putIfAbsent(key, () => normAr(t.text));
        _skelCache.putIfAbsent(key, () => norm.replaceAll('ا', ''));
        _consCache.putIfAbsent(key, () => norm.replaceAll(_weakLetters, ''));
      }
    }
    _normCacheAyahCount = count;
  }

  /// 0 = exact phrase, 1 = all words, 2 = skeleton phrase, 3 = skeleton
  /// words, 4 = weak-letter phrase, 5 = weak-letter words, -1 = no match.
  /// Empty skeleton/weak queries are skipped so a bare-alef query can't
  /// match the whole mushaf.
  static int _rank(
    String normText,
    String normQuery,
    List<String> tokens,
    String skelText,
    String skelQuery,
    List<String> skelTokens,
    String consText,
    String consQuery,
    List<String> consTokens,
  ) {
    if (normText.contains(normQuery)) return 0;
    var all = true;
    for (final t in tokens) {
      if (!normText.contains(t)) {
        all = false;
        break;
      }
    }
    if (all) return 1;
    if (skelQuery.isNotEmpty) {
      if (skelText.contains(skelQuery)) return 2;
      if (skelTokens.isNotEmpty) {
        var sAll = true;
        for (final t in skelTokens) {
          if (!skelText.contains(t)) {
            sAll = false;
            break;
          }
        }
        if (sAll) return 3;
      }
    }
    if (consQuery.isNotEmpty) {
      if (consText.contains(consQuery)) return 4;
      if (consTokens.isNotEmpty) {
        for (final t in consTokens) {
          if (!consText.contains(t)) return -1;
        }
        return 5;
      }
    }
    return -1;
  }

  String _ayahText(List<TajAya> list, int ayah) {
    for (final t in list) {
      if (t.a == ayah) return t.text;
    }
    return '';
  }

  int _pageOf(int surah, int ayah) {
    try {
      return Get.find<QuranController>().meta.value?.aya['$surah:$ayah'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Arabic-insensitive normalization for search (never touches display).
  /// Strips tashkeel, tatweel, superscript alef, and Quranic waqf/annotation
  /// marks; unifies alef seats, taa marbuta, hamza seats, and kaf/yeh
  /// keyboard variants; drops the bare hamza; collapses whitespace.
  static String normAr(String s) {
    var o = s.replaceAll(_diacritics, '');
    o = o.replaceAll(_alefForms, 'ا');
    o = o.replaceAll(_kafForms, 'ك');
    o = o.replaceAll(_yehForms, 'ي');
    o = o.replaceAll('ؤ', 'و');
    o = o.replaceAll('ئ', 'ي');
    o = o.replaceAll('ء', '');
    o = o.replaceAll(_tehForms, 'ه');
    o = o.replaceAll('ۀ', 'ه');
    o = o.replaceAll('ى', 'ي');
    o = o.replaceAll(_whitespace, ' ');
    return o.trim();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}

void ensureAyahSearchController() {
  if (!Get.isRegistered<AyahSearchController>()) {
    Get.put(AyahSearchController(), permanent: true);
  }
}
