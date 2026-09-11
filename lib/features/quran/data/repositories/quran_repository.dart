import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quran_models.dart';

String _pageName(int page) => 'page-${page.toString().padLeft(3, '0')}.json';

/// Trailing Quranic annotation marks (waqf signs like U+06D9 "لا", U+06D7,
/// ayah-end markers, small-high signs). The Kemenag tajweed JSON appends
/// them to the ayah text, but the mushaf page words — and the printed
/// mushaf — don't carry them, so plain-text surfaces must drop them.
/// Mid-ayah وقف signs are part of the real mushaf and are kept.
final RegExp _trailingWaqfMarks = RegExp(r'[\u06D6-\u06ED\u08D3-\u08FF]+$');

String stripTrailingWaqf(String text) =>
    text.replaceAll(_trailingWaqfMarks, '');

/// Offline repository: loads bundled JSON exactly like the web `load()` fn.
class QuranRepository {
  QuranRepository(this._bundle);

  final AssetBundle _bundle;
  final Map<int, MushafPageData> _pageCache = {};
  final Map<int, List<TajAya>> _tajCache = {};
  List<Surah>? _surahCache;
  MushafMeta? _metaCache;

  Future<List<Surah>> loadSurahs() async {
    if (_surahCache != null) return _surahCache!;
    final raw =
        await _bundle.loadString('assets/data/kemenag/list.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList();
    _surahCache = list;
    return list;
  }

  Future<MushafMeta> loadMeta() async {
    if (_metaCache != null) return _metaCache!;
    final raw =
        await _bundle.loadString('assets/data/mushaf/meta.json');
    _metaCache = MushafMeta.fromJson(jsonDecode(raw));
    return _metaCache!;
  }

  Future<MushafPageData> loadPage(int page) async {
    final p = page.clamp(1, 604);
    if (_pageCache.containsKey(p)) return _pageCache[p]!;
    final raw = await _bundle
        .loadString('assets/data/mushaf/pages/${_pageName(p)}');
    final data = MushafPageData.fromJson(jsonDecode(raw));
    _pageCache[p] = data;
    return data;
  }

  Future<List<TajAya>> loadTaj(int surahId) async {
    if (_tajCache.containsKey(surahId)) return _tajCache[surahId]!;
    final raw = await _bundle
        .loadString('assets/data/mushaf/taj/$surahId.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => TajAya.fromJson(e as Map<String, dynamic>))
        .toList();
    _tajCache[surahId] = list;
    return list;
  }

  /// Mirrors web `+page.js load()`: page + all surahs on that page.
  Future<({MushafPageData page, Map<int, List<TajAya>> tajMap})>
      loadPageBundle(int page) async {
    final pageData = await loadPage(page);
    final surahs = <int>{};
    for (final ln in pageData.lines) {
      if (ln.t == 'h' && ln.s != null) {
        final id = int.tryParse(ln.s!);
        if (id != null) surahs.add(id);
      }
      if (ln.t == 't' && ln.v != null) {
        final id = int.tryParse(ln.v!.split(':').first);
        if (id != null) surahs.add(id);
      }
    }
    final tajMap = <int, List<TajAya>>{};
    for (final s in surahs) {
      tajMap[s] = await loadTaj(s);
    }
    return (page: pageData, tajMap: tajMap);
  }

  /// Full Arabic text + tajweed slices for a single ayah, from the bundled
  /// per-surah tajweed JSON (the canonical Kemenag Hafs text, identical to
  /// what the mushaf renderer draws). Trailing waqf marks (e.g. the "لا"
  /// sign) are stripped so plain-text consumers match the printed mushaf.
  /// Only used by the floating-ayah overlay path. Returns null if the ayah
  /// does not exist.
  Future<TajAya?> loadAyahText(int surah, int ayah) async {
    final list = await loadTaj(surah);
    for (final a in list) {
      if (a.a == ayah) {
        // Trailing-only strip: earlier slice offsets stay valid.
        return TajAya(a: a.a, text: stripTrailingWaqf(a.text), slices: a.slices);
      }
    }
    return null;
  }
}
