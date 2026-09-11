import 'dart:convert';

import 'package:flutter/services.dart';

/// Per-ayah English translation from `assets/data/trans/en/<surah>.json`.
///
/// Files are shaped `[{"a": 1, "t": "..."}, ...]` (Saheeh International),
/// one file per surah. Loaded lazily per surah and cached — same pattern
/// as the tajweed JSONs, tiny footprint (~0.94MB total).
class TranslationRepository {
  TranslationRepository(this._bundle);

  final AssetBundle _bundle;

  final Map<int, Map<int, String>> _surahCache = {};

  /// Parse helper kept pure for unit tests.
  static Map<int, String> parseTranslationJson(String raw) {
    final out = <int, String>{};
    final list = jsonDecode(raw) as List;
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      final a = (m['a'] as num?)?.toInt();
      final t = (m['t'] ?? '').toString();
      if (a != null && t.isNotEmpty) out[a] = t;
    }
    return out;
  }

  Future<Map<int, String>> loadSurah(int surahId) async {
    final cached = _surahCache[surahId];
    if (cached != null) return cached;
    final raw = await _bundle.loadString(
      'assets/data/trans/en/$surahId.json',
    );
    final parsed = parseTranslationJson(raw);
    _surahCache[surahId] = parsed;
    return parsed;
  }

  Future<String?> getAyah(int surah, int ayah) async {
    final map = await loadSurah(surah);
    return map[ayah];
  }
}
