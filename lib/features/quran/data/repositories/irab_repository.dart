import 'dart:convert';

import 'package:flutter/services.dart';

/// Ayah i'rab from the bundled `assets/data/earab.json`. Records use
/// `{id, sura, aya, words}`, where `words` maps each Arabic word (and any
/// sentence-level key) to its grammatical explanation. Parsed once per
/// session into an ayah-keyed index; lookups are map hits afterwards.
class IrabRepository {
  IrabRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Map<String, String>? _index;
  Map<String, Map<String, String>>? _wordIndex;
  bool _missing = false;

  /// I'rab text for [surah]:[ayah], or null when missing.
  Future<String?> getIrab(int surah, int ayah) async {
    var index = _index;
    if (index == null && !_missing) {
      index = await _load();
      _index = index;
      if (index == null) _missing = true;
    }
    return index?['$surah:$ayah'];
  }

  /// I'rab for one Arabic word in [surah]:[ayah], or null when unavailable.
  Future<String?> getWordIrab(int surah, int ayah, String word) async {
    if (_index == null && !_missing) {
      final index = await _load();
      _index = index;
      if (index == null) _missing = true;
    }
    final words = _wordIndex?['$surah:$ayah'];
    if (words == null) return null;
    return words[word] ??
        words.entries
            .where((entry) => _normalize(entry.key) == _normalize(word))
            .map((entry) => entry.value)
            .firstOrNull;
  }

  Future<Map<String, String>?> _load() async {
    try {
      final raw = await _bundle.loadString('assets/data/earab.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final index = <String, String>{};
      final wordIndex = <String, Map<String, String>>{};
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final s = _num(e['sura']);
        final a = _num(e['aya']);
        if (s == null || a == null) continue;

        final words = e['words'];
        final text = words is Map
            ? _formatWords(words)
            : _clean(e['text']?.toString() ?? '');
        if (words is Map) {
          final entries = <String, String>{};
          for (final entry in words.entries) {
            final word = entry.key.toString().trim();
            final explanation = entry.value?.toString().trim() ?? '';
            if (word.isNotEmpty && explanation.isNotEmpty) {
              entries[word] = explanation;
            }
          }
          if (entries.isNotEmpty) wordIndex['$s:$a'] = entries;
        }
        if (text.isEmpty) continue;
        index['$s:$a'] = text;
      }
      _wordIndex = wordIndex;
      return index.isEmpty ? null : index;
    } catch (_) {
      return null;
    }
  }

  static int? _num(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

  /// Keeps the source JSON's insertion order so the ayah is read naturally.
  static String _formatWords(Map words) {
    final lines = <String>[];
    for (final entry in words.entries) {
      final word = entry.key.toString().trim();
      final explanation = entry.value?.toString().trim() ?? '';
      if (word.isEmpty || explanation.isEmpty) continue;
      lines.add('$word: $explanation');
    }
    return lines.join('\n\n');
  }

  static String _normalize(String value) => value
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('ٱ', 'ا')
      .trim();

  /// HTML (`<p>`, entities) → plain paragraphs.
  static String _clean(String html) {
    var t = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
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
