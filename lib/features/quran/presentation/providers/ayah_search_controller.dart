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
/// - Arabic-insensitive matching: tashkeel/tatweel stripped, alef forms,
///   taa marbuta, hamza seats unified on both sides.
/// - Multi-word AND: every query word must appear (any order); exact phrase
///   matches rank first.
/// - Direct references: `2:255`, `2-255`, `٢:٢٥٥` jump straight to the ayah.
/// - Results carry their mushaf page for one-tap opening.
class AyahSearchController extends GetxController {
  static const int resultLimit = 120;
  static const Duration debounce = Duration(milliseconds: 350);

  final query = ''.obs;
  final hits = <AyahSearchHit>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  final Map<int, List<TajAya>> _tajCache = {};
  Timer? _debounce;

  void setQuery(String q) {
    query.value = q;
    _debounce?.cancel();
    _debounce = Timer(debounce, () => search(q));
  }

  Future<void> search(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      hits.clear();
      hasSearched.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final ref = _parseReference(q);
      if (ref != null) {
        final hit = await _referenceHit(ref.$1, ref.$2);
        hits.value = hit == null ? [] : [hit];
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

  List<AyahSearchHit> _filter(String q) {
    final normQ = normAr(q);
    final tokens = normQ
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return [];
    final ranked = <({AyahSearchHit hit, int rank})>[];
    for (var s = 1; s <= 114; s++) {
      final list = _tajCache[s] ?? const <TajAya>[];
      for (final t in list) {
        final normT = normAr(t.text);
        final rank = _rank(normT, normQ, tokens);
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
        if (ranked.length >= resultLimit * 3) break;
      }
      if (ranked.length >= resultLimit * 3) break;
    }
    ranked.sort((a, b) {
      final r = a.rank.compareTo(b.rank);
      if (r != 0) return r;
      final s = a.hit.surah.compareTo(b.hit.surah);
      return s != 0 ? s : a.hit.ayah.compareTo(b.hit.ayah);
    });
    return [for (final r in ranked.take(resultLimit)) r.hit];
  }

  /// 0 = exact phrase, 1 = all words, -1 = no match.
  int _rank(String normText, String normQuery, List<String> tokens) {
    if (normText.contains(normQuery)) return 0;
    for (final t in tokens) {
      if (!normText.contains(t)) return -1;
    }
    return 1;
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
  static String normAr(String s) {
    var o = s.replaceAll(RegExp('[\u064B-\u065F\u0670\u0640]'), '');
    o = o.replaceAll(RegExp('[أإآٱ]'), 'ا');
    o = o.replaceAll('ة', 'ه');
    o = o.replaceAll('ئ', 'ي');
    o = o.replaceAll('ؤ', 'و');
    o = o.replaceAll('ى', 'ي');
    return o;
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
