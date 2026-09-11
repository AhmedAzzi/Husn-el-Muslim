import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/reciter_model.dart';

/// Fetches the reciter list from the free alquran.cloud API (no key needed).
///
/// Endpoint: `GET /v1/edition?format=audio&language=ar` returns audio
/// editions (`identifier`, `englishName`, ...). Each identifier streams
/// per-ayah audio from the Islamic Network CDN:
/// `https://cdn.islamic.network/quran/audio/128/<identifier>/<globalAyah>.mp3`
/// where `globalAyah` is 1..6236.
///
/// Throws on transport errors / non-200 / unexpected shape — callers fall
/// back to [ReciterCatalog.defaults] (offline) so audio selection never
/// breaks without connectivity.
class ReciterApiService {
  ReciterApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri editionsUri = Uri.parse(
    'https://api.alquran.cloud/v1/edition?format=audio&language=ar',
  );

  static const Duration timeout = Duration(seconds: 10);

  Future<List<Reciter>> fetchReciters() async {
    final res = await _client.get(editionsUri).timeout(timeout);
    if (res.statusCode != 200) {
      throw ReciterApiException('HTTP ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ReciterApiException('unexpected envelope');
    }
    final data = decoded['data'];
    if (data is! List) {
      throw const ReciterApiException('missing data list');
    }
    final reciters = ReciterCatalog.fromApiEditions(data);
    if (reciters.isEmpty) {
      throw const ReciterApiException('empty reciter list');
    }
    return reciters;
  }

  /// Bitrates tried (in order) when the exact one is unknown.
  static const guessBitrates = [128, 64, 192];

  /// Origins tried (in order) for API reciter audio.
  static const audioHosts = [
    'https://cdn.islamic.network',
    'https://cdn.alislam.ru',
  ];

  /// In-memory cache: edition identifier -> URL templates with a `{N}`
  /// placeholder for the global ayah number.
  final _audioTemplates = <String, List<String>>{};

  /// Ordered per-ayah stream candidates for an API reciter edition.
  ///
  /// The exact streams (bitrate included) come from `GET /v1/ayah/1/<id>`
  /// (`audio` + `audioSecondary`) and are cached per session — not every
  /// edition is served at every bitrate, so a hardcoded bitrate 404s for
  /// some reciters. When that lookup fails, falls back to a guess chain
  /// across common bitrates and mirror origins. Never throws.
  Future<List<String>> audioCandidates({
    required String identifier,
    required int globalAyah,
  }) async {
    try {
      final templates = _audioTemplates[identifier] ??
          await _fetchAudioTemplates(identifier);
      if (templates != null) {
        _audioTemplates[identifier] = templates;
        return templates
            .map((t) => t.replaceFirst('{N}', '$globalAyah'))
            .toList();
      }
    } catch (_) {
      // fall through to the guess chain
    }
    return _guessCandidates(identifier, globalAyah);
  }

  Future<List<String>?> _fetchAudioTemplates(String identifier) async {
    try {
      final uri = Uri.parse(
        'https://api.alquran.cloud/v1/ayah/1/$identifier',
      );
      final res = await _client.get(uri).timeout(timeout);
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      final raw = <String>[
        if (data['audio'] is String) data['audio'] as String,
        if (data['audioSecondary'] is List)
          for (final u in (data['audioSecondary'] as List))
            if (u is String) u,
      ];
      final templates = <String>[];
      for (final u in raw) {
        final t = _toTemplate(u);
        if (t != null && !templates.contains(t)) templates.add(t);
      }
      return templates.isEmpty ? null : templates;
    } catch (_) {
      return null;
    }
  }

  /// Turns a global-ayah-1 stream URL into a `{N}` template. Returns null
  /// for unexpected shapes (never fabricated).
  static String? _toTemplate(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.path.contains('/quran/audio/')) return null;
    final segs = uri.pathSegments;
    if (segs.isEmpty || !segs.last.endsWith('.mp3')) return null;
    final base = segs.sublist(0, segs.length - 1).join('/');
    return '${uri.scheme}://${uri.host}/$base/{N}.mp3';
  }

  static List<String> _guessCandidates(String identifier, int globalAyah) => [
        for (final b in guessBitrates)
          for (final h in audioHosts)
            '$h/quran/audio/$b/$identifier/$globalAyah.mp3',
      ];

  /// Ordered full-surah single-file candidates for an API reciter edition:
  /// `…/quran/audio-surah/{bitrate}/{identifier}/{surah}.mp3`.
  ///
  /// One continuous recording of the whole surah (the reciter's own breaks),
  /// so surah playback never stitches per-ayah cuts. The exact bitrate is
  /// derived from the cached per-ayah templates when known (same host +
  /// bitrate serve the surah file); otherwise a guess chain across common
  /// bitrates and mirror origins. Callers try each in order until one loads.
  /// Never throws (empty list when nothing can be built — never empty here,
  /// the guess chain always applies).
  Future<List<String>> surahCandidates({
    required String identifier,
    required int surah,
  }) async {
    assert(surah >= 1 && surah <= 114);
    try {
      final templates = _audioTemplates[identifier] ??
          await _fetchAudioTemplates(identifier);
      if (templates != null) {
        _audioTemplates[identifier] = templates;
        final exact = <String>[];
        for (final t in templates) {
          final u = _surahFromTemplate(t, surah);
          if (u != null && !exact.contains(u)) exact.add(u);
        }
        if (exact.isNotEmpty) return exact;
      }
    } catch (_) {
      // fall through to the guess chain
    }
    return [
      for (final b in guessBitrates)
        for (final h in audioHosts)
          '$h/quran/audio-surah/$b/$identifier/$surah.mp3',
    ];
  }

  /// Turns a per-ayah `{N}` template into its full-surah equivalent, or null
  /// when the template has an unexpected shape (never fabricated).
  static String? _surahFromTemplate(String template, int surah) {
    final m = RegExp(
      r'^(https?://[^/]+)/quran/audio/(\d+)/([^/]+)/\{N\}\.mp3$',
    ).firstMatch(template);
    if (m == null) return null;
    return '${m.group(1)}/quran/audio-surah/${m.group(2)}/${m.group(3)}/$surah.mp3';
  }

  void dispose() => _client.close();
}

class ReciterApiException implements Exception {
  const ReciterApiException(this.message);
  final String message;

  @override
  String toString() => 'ReciterApiException($message)';
}
