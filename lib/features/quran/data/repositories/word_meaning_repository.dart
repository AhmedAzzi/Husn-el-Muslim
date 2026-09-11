import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/word_meaning.dart';

/// Read-only access to the prebuilt `word_meaning.db` asset.
///
/// The DB is shipped under `assets/data/words/word_meaning.db`, copied to the
/// app databases directory on first use, then opened read-only. Never merged
/// into `khatma_app.db` so user data can be cleared without touching Quran data.
class WordMeaningRepository {
  WordMeaningRepository._(this._db);

  final Database _db;

  static const assetPath = 'assets/data/words/word_meaning.db';
  static const dbFileName = 'word_meaning.db';

  /// Ayah-level cache: `s * 1e6 + a -> rows`. Bounded to recent ayahs.
  final Map<int, List<WordMeaning>> _ayahCache = {};
  static const _maxCachedAyahs = 30;

  /// Open the repository, copying the asset on first run.
  /// Pass [overridePath] in tests to open an existing DB file directly.
  static Future<WordMeaningRepository> open({String? overridePath}) async {
    final target = overridePath ?? p.join(await getDatabasesPath(), dbFileName);
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
    return WordMeaningRepository._(db);
  }

  /// Test helper: wrap an already-open database without asset copying.
  static WordMeaningRepository fromDatabase(Database db) =>
      WordMeaningRepository._(db);

  Future<WordMeaning?> getWord(int surah, int ayah, int word) async {
    final rows = await _db.query(
      'QuranWordInfo',
      where: 'surahNo = ? AND ayahNo = ? AND wordNo = ?',
      whereArgs: [surah, ayah, word],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final info = rows.first;
    final meaningRows = await _db.query(
      'word_content_meaning',
      columns: ['meaning'],
      where: 'surahNo = ? AND ayahNo = ? AND wordNo = ?',
      whereArgs: [surah, ayah, word],
      limit: 1,
    );
    return WordMeaning(
      surah: surah,
      ayah: ayah,
      word: word,
      wordWithHaraqah: info['wordWithHaraqah'] as String?,
      imlaee: info['imlaee'] as String?,
      plain: info['wordWithOutHaraqah'] as String?,
      root: info['Root'] as String?,
      translationEn: info['TranslationEn'] as String?,
      meaning: meaningRows.isEmpty
          ? null
          : meaningRows.first['meaning'] as String?,
    );
  }

  /// All word rows for one ayah (excludes the `w=0` header row).
  Future<List<WordMeaning>> getAyahWords(int surah, int ayah) async {
    final key = surah * 1000000 + ayah;
    final cached = _ayahCache[key];
    if (cached != null) return cached;
    final rows = await _db.query(
      'QuranWordInfo',
      where: 'surahNo = ? AND ayahNo = ? AND wordNo > 0',
      whereArgs: [surah, ayah],
      orderBy: 'wordNo ASC',
    );
    final meanings = await _db.query(
      'word_content_meaning',
      where: 'surahNo = ? AND ayahNo = ? AND wordNo > 0',
      whereArgs: [surah, ayah],
    );
    final byWord = <int, String>{};
    for (final m in meanings) {
      final w = (m['wordNo'] as num?)?.toInt();
      if (w != null) byWord[w] = (m['meaning'] ?? '').toString();
    }
    final out = rows
        .map(
          (info) => WordMeaning(
            surah: surah,
            ayah: ayah,
            word: ((info['wordNo'] as num?)?.toInt() ?? 0),
            wordWithHaraqah: info['wordWithHaraqah'] as String?,
            imlaee: info['imlaee'] as String?,
            plain: info['wordWithOutHaraqah'] as String?,
            root: info['Root'] as String?,
            translationEn: info['TranslationEn'] as String?,
            meaning: byWord[((info['wordNo'] as num?)?.toInt() ?? 0)],
          ),
        )
        .toList();
    if (_ayahCache.length >= _maxCachedAyahs) {
      _ayahCache.remove(_ayahCache.keys.first);
    }
    _ayahCache[key] = out;
    return out;
  }

  Future<void> close() => _db.close();
}
