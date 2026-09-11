import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Per-ayah timing weights from the quran.com API, used to track the live
/// ayah while a single full-surah file plays (the file itself carries no
/// per-ayah clock).
///
/// Two endpoints, both cached per session:
/// - `GET /api/v4/resources/recitations` — reciter catalog with numeric ids.
/// - `GET /api/v4/verses/by_chapter/{surah}?audio={id}` — per-verse `audio`
///   segments; each verse duration is its last segment's end time (ms).
///   Durations are proportional weights, not absolute offsets: the controller
///   stretches them over the playing file's real duration, which absorbs
///   global tempo differences between recordings.
///
/// Reciter matching is fuzzy (transliteration varies: `Mishary`/`Mishari`,
/// `Basit`/`Baset`) via bigram Dice similarity, preferring plain/Murattal
/// styles over Mujawwad/Muallim. Warsh is unsupported (Hafs-only catalog).
/// Every method is best-effort — null means "no timings, keep the
/// whole-surah highlight". Never throws.
class VerseTimingsService {
  VerseTimingsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration timeout = Duration(seconds: 10);
  static const double _minScore = 0.6;

  List<Map<String, dynamic>>? _recitations;
  final _durationsCache = <String, List<int>>{};

  /// Best quran.com recitation id for [englishName], or null.
  Future<int?> matchRecitation(String englishName) async {
    try {
      final list = await _recitationsList();
      final want = _letters(englishName);
      if (want.isEmpty) return null;
      Object? bestId;
      var bestRank = -1.0;
      for (final r in list) {
        final name = r['reciter_name']?.toString() ?? '';
        final score = _dice(want, _letters(name));
        if (score < _minScore) continue;
        // Prefer plain/Murattal recordings for murattal playback.
        final style = r['style']?.toString() ?? '';
        final penalty =
            style == 'Mujawwad' || style == 'Muallim' ? 0.15 : 0.0;
        final rank = score - penalty;
        if (rank > bestRank) {
          bestRank = rank;
          bestId = r['id'];
        }
      }
      final id = bestId;
      if (id is int) return id;
      if (id is num) return id.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Per-verse durations in ms for ([recitationId], [surah]), or null when
  /// the count mismatches [expectedAyahs] or anything fails.
  Future<List<int>?> verseDurations({
    required int recitationId,
    required int surah,
    required int expectedAyahs,
  }) async {
    final key = '$recitationId:$surah';
    final cached = _durationsCache[key];
    if (cached != null) {
      return cached.length == expectedAyahs ? cached : null;
    }
    try {
      final out = <int>[];
      var page = 1;
      while (true) {
        final uri = Uri.parse(
          'https://api.quran.com/api/v4/verses/by_chapter/$surah'
          '?language=en&words=false&audio=$recitationId'
          '&fields=verse_number&per_page=100&page=$page',
        );
        final res = await _client.get(uri).timeout(timeout);
        if (res.statusCode != 200) return null;
        final decoded = jsonDecode(res.body);
        if (decoded is! Map<String, dynamic>) return null;
        final verses = decoded['verses'];
        if (verses is! List) return null;
        for (final v in verses) {
          final end = _verseEndMs(v);
          if (end == null) return null;
          out.add(end);
        }
        final pagination = decoded['pagination'];
        final next = pagination is Map ? pagination['next_page'] : null;
        if (next == null || out.length >= expectedAyahs) break;
        page = (next as num).toInt();
      }
      if (out.length != expectedAyahs) return null;
      _durationsCache[key] = out;
      return out;
    } catch (_) {
      return null;
    }
  }

  /// End time (ms) of a verse = its last audio segment's end, or null.
  static int? _verseEndMs(dynamic verse) {
    try {
      if (verse is! Map) return null;
      final audio = verse['audio'];
      if (audio is! Map) return null;
      final segments = audio['segments'];
      if (segments is! List || segments.isEmpty) return null;
      final last = segments.last;
      if (last is! List || last.length < 4) return null;
      final end = last[3];
      if (end is! num || end <= 0) return null;
      return end.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _recitationsList() async {
    final cached = _recitations;
    if (cached != null) return cached;
    final res = await _client
        .get(
          Uri.parse(
            'https://api.quran.com/api/v4/resources/recitations?language=en',
          ),
        )
        .timeout(timeout);
    if (res.statusCode != 200) throw const VerseTimingsException('HTTP');
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw const VerseTimingsException('unexpected envelope');
    }
    final data = decoded['recitations'];
    if (data is! List) throw const VerseTimingsException('missing recitations');
    final out = [
      for (final e in data)
        if (e is Map<String, dynamic>) e,
    ];
    if (out.isEmpty) throw const VerseTimingsException('empty list');
    _recitations = out;
    return out;
  }

  static String _letters(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  /// Bigram Dice similarity in [0, 1]; tolerant to transliteration
  /// variance (`mishary`/`mishari`, `basit`/`baset`).
  static double _dice(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    Set<String> bigrams(String s) {
      final set = <String>{};
      for (var i = 0; i + 1 < s.length; i++) {
        set.add(s.substring(i, i + 2));
      }
      return set;
    }

    final x = bigrams(a);
    final y = bigrams(b);
    if (x.isEmpty || y.isEmpty) return 0;
    return 2 * x.intersection(y).length / (x.length + y.length);
  }

  void dispose() => _client.close();
}

class VerseTimingsException implements Exception {
  const VerseTimingsException(this.message);
  final String message;

  @override
  String toString() => 'VerseTimingsException($message)';
}
