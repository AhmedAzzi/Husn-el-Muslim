import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/tafsir_source.dart';

/// Read-only access to the prebuilt `tafsir.db` asset (all six tafsirs).
///
/// Shipped under `assets/data/tafsir/tafsir.db`, copied to the app databases
/// directory on first use, then opened read-only. Lazily opened — never at
/// startup — and never merged into `khatma_app.db`.
class TafsirRepository {
  TafsirRepository._(this._db);

  final Database _db;

  static const assetPath = 'assets/data/tafsir/tafsir.db';
  static const dbFileName = 'tafsir.db';

  /// Ayah cache: `(sourceIndex * 10^7 + s * 10^4 + a) -> text`.
  final Map<int, String?> _ayahCache = {};
  static const _maxCached = 20;

  /// Open the repository, copying the asset on first run.
  /// Pass [overridePath] in tests to open an existing DB file directly.
  static Future<TafsirRepository> open({String? overridePath}) async {
    final target =
        overridePath ?? p.join(await getDatabasesPath(), dbFileName);
    final file = File(target);
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    final db = await openDatabase(target, readOnly: true);
    return TafsirRepository._(db);
  }

  /// Test helper: wrap an already-open database without asset copying.
  static TafsirRepository fromDatabase(Database db) =>
      TafsirRepository._(db);

  static final _brRe = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final _tagRe = RegExp(r'<[^>]*>');

  static String cleanHtml(String raw) {
    var s = raw.replaceAll(_brRe, '\n');
    s = s.replaceAll(_tagRe, '');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  /// The mukhtasar table marks emphasis with markdown underscores
  /// (e.g. `_نعاس_`); strip them for plain-text surfaces.
  static String cleanMarkdown(String raw) =>
      raw.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m.group(1)!);

  Future<String?> getTafsir(
    TafsirSource source,
    int surah,
    int ayah,
  ) async {
    final key = source.index * 10000000 + surah * 10000 + ayah;
    if (_ayahCache.containsKey(key)) return _ayahCache[key];
    final String? text;
    if (source == TafsirSource.mukhtasar) {
      final rows = await _db.query(
        source.table,
        columns: ['ar'],
        where: 'surahNo = ? AND ayahNo = ?',
        whereArgs: [surah, ayah],
        limit: 1,
      );
      final raw =
          rows.isEmpty ? '' : (rows.first['ar'] ?? '').toString();
      text = raw.isEmpty ? null : cleanMarkdown(cleanHtml(raw));
    } else {
      final rows = await _db.query(
        source.table,
        columns: ['tafsir'],
        where: 'sura = ? AND aya = ?',
        whereArgs: [surah, ayah],
        limit: 1,
      );
      final raw =
          rows.isEmpty ? '' : (rows.first['tafsir'] ?? '').toString();
      text = raw.isEmpty ? null : cleanHtml(raw);
    }
    if (_ayahCache.length >= _maxCached) {
      _ayahCache.remove(_ayahCache.keys.first);
    }
    _ayahCache[key] = text;
    return text;
  }

  Future<void> close() => _db.close();
}
