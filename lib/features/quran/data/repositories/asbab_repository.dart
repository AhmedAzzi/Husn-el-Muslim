import 'dart:convert';

import 'package:flutter/services.dart';

/// Asbab al-nuzul (al-Wahidy) from the bundled
/// `assets/data/nozool-wahidy.json`: one flat list of
/// `{id, sura, aya, text}` (HTML paragraphs, only ayahs that have a
/// narration). Parsed once per session into an ayah-keyed index; lookups
/// are map hits afterwards. Returns null for ayahs without a narration.
class AsbabRepository {
  AsbabRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Map<String, String>? _index;
  bool _missing = false;

  /// Sabab al-nuzul text for [surah]:[ayah] (plain paragraphs), or null.
  Future<String?> getSabab(int surah, int ayah) async {
    var index = _index;
    if (index == null && !_missing) {
      index = await _load();
      _index = index;
      if (index == null) _missing = true;
    }
    return index?['$surah:$ayah'];
  }

  Future<Map<String, String>?> _load() async {
    try {
      final raw =
          await _bundle.loadString('assets/data/nozool-wahidy.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final index = <String, String>{};
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final s = _num(e['sura']);
        final a = _num(e['aya']);
        final text = e['text']?.toString() ?? '';
        if (s == null || a == null || text.isEmpty) continue;
        index['$s:$a'] = _clean(text);
      }
      return index.isEmpty ? null : index;
    } catch (_) {
      return null;
    }
  }

  static int? _num(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('$v');

  /// HTML (`<p>`, entities) → plain paragraphs.
  static String _clean(String html) {
    var t = html.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    t = t.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
    t = t.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'<[^>]+>'), '');
    t = t
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
