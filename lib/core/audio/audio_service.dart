import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/nakhtem/data/models/reciter_model.dart';
import '../../features/nakhtem/data/repositories/reciter_api_service.dart';
import '../logic/quran_index.dart';

/// A small, silent no-op playback contract used by tests and pre-initialized
/// states so the UI never crashes when audio is not available.
abstract class AudioEngine {
  Future<void> load(String url);

  /// Loads a gapless playlist (one source per ayah) without auto-playing.
  /// Backed by just_audio's concatenating source, so transitions between
  /// ayahs have no gap — continuous recitation for a full surah/page.
  Future<void> loadPlaylist(List<String> urls);

  /// Skips to the next source in the loaded playlist (no-op when idle).
  Future<void> seekToNext();
  Future<void> play();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
  Stream<Duration?> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;
  /// Fires each time the current source plays to completion, so callers can
  /// advance a queue (full-surah / full-page playback).
  Stream<void> get completedStream;
  /// Index of the currently playing source in a loaded playlist.
  Stream<int?> get sequenceIndexStream;
  Duration? get position;
  Duration? get duration;
  bool get playing;
  bool get isDisposed;
}

/// No-op engine (unit/widget tests). Satisfies the contract without a platform.
class NoopAudioEngine implements AudioEngine {
  @override
  Future<void> load(String url) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> dispose() async {}
  @override
  Stream<Duration?> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<void> get completedStream => const Stream.empty();
  @override
  Stream<int?> get sequenceIndexStream => const Stream.empty();
  @override
  Future<void> loadPlaylist(List<String> urls) async {}
  @override
  Future<void> seekToNext() async {}
  @override
  Duration? get position => Duration.zero;
  @override
  Duration? get duration => Duration.zero;
  @override
  bool get playing => false;
  @override
  bool get isDisposed => false;
}

/// Adaptive engine: uses [AudioPlayer] when a platform is available, otherwise
/// falls back to a no-op so the rest of the app remains functional offline.
class AdaptiveAudioEngine implements AudioEngine {
  AudioPlayer? _player;
  bool _disposed = false;

  AudioPlayer _ensure() => _player ??= AudioPlayer();

  @override
  Future<void> load(String url) async {
    // Throws on failure (e.g. 4xx/5xx) so callers can try mirror origins.
    await _ensure().setUrl(url);
  }

  @override
  Future<void> loadPlaylist(List<String> urls) async {
    // Throws when the playlist cannot be prepared; callers fall back to
    // sequential single-ayah playback. Sources are lazy-prepared so even
    // long surahs (286 ayahs) start fast, and just_audio stitches them
    // gaplessly — one continuous recitation.
    final sources = [
      for (final u in urls) AudioSource.uri(Uri.parse(u)),
    ];
    await _ensure().setAudioSources(
      sources,
      initialIndex: 0,
      initialPosition: Duration.zero,
      preload: true,
    );
  }

  @override
  Future<void> seekToNext() async {
    try {
      await _player?.seekToNext();
    } catch (_) {}
  }

  @override
  Stream<int?> get sequenceIndexStream => _ensure().currentIndexStream;

  @override
  Future<void> play() async {
    try {
      await _ensure().play();
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await _ensure().pause();
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    try {
      await _ensure().play();
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _ensure().stop();
    } catch (_) {}
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _ensure().seek(position);
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  @override
  Stream<Duration?> get positionStream =>
      _player?.positionStream ?? const Stream.empty();

  @override
  Stream<Duration?> get durationStream => _ensure().durationStream;

  @override
  Stream<bool> get playingStream =>
      _player?.playingStream ?? const Stream.empty();

  @override
  Stream<void> get completedStream => _ensure().playerStateStream
      .where((s) => s.processingState == ProcessingState.completed)
      .map((_) {});

  @override
  Duration? get position => _player?.position;
  @override
  Duration? get duration => _player?.duration;
  @override
  bool get playing => _player?.playing ?? false;
  @override
  bool get isDisposed => _disposed;
}

/// High-level ayah audio service. Decoupled from widgets — the UI observes
/// [playing]/[loading]/[error] state. Supports play/pause/resume/stop/seek and
/// mapping a (surah, ayah) to a reciter's stream URL.
class AudioService {
  AudioService({AudioEngine? engine})
      : _engine = engine ?? AdaptiveAudioEngine();

  final AudioEngine _engine;

  String? _currentUrl;
  String? _currentReciterId;
  int _currentSurah = 0;
  int _currentAyah = 0;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  bool get playing => _engine.playing;
  bool get isDisposed => _engine.isDisposed;
  String? get currentUrl => _currentUrl;
  String? get currentReciterId => _currentReciterId;
  int get currentSurah => _currentSurah;
  int get currentAyah => _currentAyah;
  Duration? get position => _engine.position;
  Duration? get duration => _engine.duration;
  Stream<Duration?> get positionStream => _engine.positionStream;
  Stream<Duration?> get durationStream => _engine.durationStream;
  Stream<void> get completedStream => _engine.completedStream;
  Stream<int?> get sequenceIndexStream => _engine.sequenceIndexStream;

  /// Prepares a single stream (e.g. a full-surah file) without auto-playing.
  /// Throws on failure (e.g. 4xx/5xx) so callers can try the next candidate.
  Future<void> loadSingle(String url) => _engine.load(url);

  /// Prepares a gapless playlist (one URL per ayah) without auto-playing.
  /// Throws on preparation failure so callers can fall back to sequential
  /// single-ayah playback.
  Future<void> loadPlaylist(List<String> urls) => _engine.loadPlaylist(urls);

  Future<void> playPlaylist() => _engine.play();

  Future<void> seekToNext() => _engine.seekToNext();

  Future<void> playAyah({
    required Reciter reciter,
    required int surah,
    required int ayah,
  }) async {
    _loading = true;
    _error = null;
    List<String> urls = reciter.buildUrls(surah, ayah);
    // API reciters resolve their exact bitrate first: not every edition is
    // served at every bitrate, so a hardcoded one 404s for some reciters.
    final apiId = reciter.apiIdentifier;
    if (apiId != null) {
      try {
        final global = QuranIndex.instance.globalIndex(surah, ayah);
        if (global != null) {
          urls = await Get.find<ReciterApiService>().audioCandidates(
            identifier: apiId,
            globalAyah: global,
          );
        }
      } catch (_) {
        // keep the buildUrls fallback
      }
    }
    if (urls.isEmpty) {
      _error = 'audio_unavailable';
      _loading = false;
      return;
    }
    _currentReciterId = reciter.id;
    _currentSurah = surah;
    _currentAyah = ayah;
    // Try each origin in order; a flaky host must not silence playback.
    for (final url in urls) {
      _currentUrl = url;
      try {
        await _engine.load(url);
        await _engine.play();
        _loading = false;
        return;
      } catch (_) {
        // try the next mirror
      }
    }
    _error = 'audio_unavailable';
    _loading = false;
  }

  Future<void> resume() => _engine.resume();

  Future<void> pause() => _engine.pause();

  Future<void> stop() => _engine.stop();

  Future<void> seek(Duration position) => _engine.seek(position);

  Future<void> dispose() async {
    await _engine.dispose();
  }

  /// Size of the on-device download cache, in bytes (best-effort).
  Future<int> cacheSizeBytes() async => 0;

  Future<void> clearCache() async {}
}
