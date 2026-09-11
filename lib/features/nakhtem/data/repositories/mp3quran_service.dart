import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Second full-surah audio source (after the Islamic Network `audio-surah`
/// CDN): the mp3quran.net API, which serves one continuous MP3 per surah for
/// a large catalog of reciters: `{server}/{surah:03d}.mp3`.
///
/// Endpoint: `GET /api/v3/reciters?language=ar` returns reciters with Arabic
/// names and a `moshaf` list (`server`, `surah_list`, ...). A reciter is
/// matched by normalized Arabic name; the Hafs (default) or Warsh moshaf
/// containing the surah wins. Returns null when nothing matches — callers
/// fall back to the gapless per-ayah playlist. Never throws.
class Mp3QuranService {
  Mp3QuranService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri recitersUri = Uri.parse(
    'https://www.mp3quran.net/api/v3/reciters?language=ar',
  );

  static const Duration timeout = Duration(seconds: 10);

  /// Session cache of the raw reciter entries.
  List<Map<String, dynamic>>? _cache;

  /// Full-surah single-file URL for ([arabicName], [surah]), or null.
  Future<String?> surahUrl({
    required String arabicName,
    required int surah,
    String edition = 'hafs',
  }) async {
    if (surah < 1 || surah > 114) return null;
    try {
      final reciters = await _reciters();
      final want = _normalize(arabicName);
      if (want.isEmpty) return null;
      for (final r in reciters) {
        final have = _normalize(r['name']?.toString() ?? '');
        if (have.isEmpty) continue;
        if (have != want && !have.contains(want) && !want.contains(have)) {
          continue;
        }
        final raw = r['moshaf'];
        if (raw is! List) continue;
        final moshafs = [
          for (final m in raw)
            if (m is Map<String, dynamic>) m,
        ];
        for (final m in _ranked(moshafs, edition)) {
          if (!_containsSurah(m['surah_list']?.toString(), surah)) continue;
          var server = m['server']?.toString() ?? '';
          if (server.isEmpty) continue;
          if (!server.endsWith('/')) server += '/';
          return '$server${surah.toString().padLeft(3, '0')}.mp3';
        }
        return null; // matched reciter, but no moshaf carries this surah
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _reciters() async {
    final cached = _cache;
    if (cached != null) return cached;
    final res = await _client.get(recitersUri).timeout(timeout);
    if (res.statusCode != 200) throw const Mp3QuranException('HTTP');
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw const Mp3QuranException('unexpected envelope');
    }
    final data = decoded['reciters'];
    if (data is! List) throw const Mp3QuranException('missing reciters');
    final out = [
      for (final e in data)
        if (e is Map<String, dynamic>) e,
    ];
    if (out.isEmpty) throw const Mp3QuranException('empty reciter list');
    _cache = out;
    return out;
  }

  /// Hafs callers prefer a Hafs moshaf, Warsh callers a Warsh one; every
  /// other moshaf follows in API order as fallback.
  List<Map<String, dynamic>> _ranked(
    List<Map<String, dynamic>> moshafs,
    String edition,
  ) {
    final keyword = edition == 'warsh' ? 'ورش' : 'حفص';
    final preferred = <Map<String, dynamic>>[];
    final rest = <Map<String, dynamic>>[];
    for (final m in moshafs) {
      final name = m['name']?.toString() ?? '';
      if (name.contains(keyword)) {
        preferred.add(m);
      } else {
        rest.add(m);
      }
    }
    return [...preferred, ...rest];
  }

  static bool _containsSurah(String? list, int surah) {
    if (list == null || list.isEmpty) return false;
    return list.split(',').contains('$surah');
  }

  /// Arabic-insensitive comparison: drops tashkeel/tatweel, parenthetical
  /// style notes (`(مرتل)`), unifies alef forms, and ignores spacing so
  /// `عبد الباسط` also matches `عبدالباسط`.
  static String _normalize(String input) {
    var s = input.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    s = s.replaceAll(RegExp('[\u064B-\u065F\u0670\u0640]'), '');
    s = s.replaceAll(RegExp('[أإآٱ]'), 'ا');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll(RegExp(r'\s+'), '');
    return s.trim();
  }

  void dispose() => _client.close();
}

class Mp3QuranException implements Exception {
  const Mp3QuranException(this.message);
  final String message;

  @override
  String toString() => 'Mp3QuranException($message)';
}
