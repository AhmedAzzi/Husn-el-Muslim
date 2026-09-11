import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/logic/quran_index.dart';
import '../../../nakhtem/data/models/reciter_model.dart';
import '../../../nakhtem/data/repositories/mp3quran_service.dart';
import '../../../nakhtem/data/repositories/reciter_api_service.dart';
import '../../../nakhtem/data/repositories/verse_timings_service.dart';
import '../../../nakhtem/presentation/controllers/nakhtem_settings_controller.dart';

/// A single ayah reference inside a playback queue.
typedef QueueAya = ({int surah, int ayah});

/// Audio playback for the Mushaf reader, reusing the **same** reciter list
/// and selection as Khatma ([NakhtemSettingsController]) and the shared
/// [AudioService]. Single source of truth — no duplicate reciter catalog.
///
/// A full surah ([playSurah]) or a full mushaf page ([playPage]) plays as
/// **one continuous recitation**: every ayah URL is stitched into a single
/// gapless playlist, so there are no per-ayah gaps. The queue auto-finishes
/// when the playlist completes. If playlist preparation fails, playback
/// falls back to sequential single-ayah mode (with mirror retries).
class MushafAudioController extends GetxController {
  final playingSurah = 0.obs;
  final playingAyah = 0.obs;
  final isLoading = false.obs;
  final isPlaying = false.obs;
  final error = Rxn<String>();

  /// Ordered queue for continuous playback; empty for single-ayah playback.
  final queue = <QueueAya>[].obs;

  /// Index of the currently playing ayah inside [queue].
  final queueIndex = 0.obs;

  /// Human label for the queue (e.g. surah name or `صفحة 5`), empty when idle.
  final queueLabel = ''.obs;

  /// Live ayah inside a single-file surah recording (0 = unknown). Drives
  /// the ayah-per-ayah highlight + page turns while one continuous file
  /// plays. Always 0 outside single-file mode.
  final trackedAyah = 0.obs;

  /// True while the engine plays a gapless playlist (vs sequential mode).
  bool _gapless = false;

  /// True while the engine plays one full-surah file (no queue tracking).
  bool _singleFile = false;

  /// Start offsets (ms) of each ayah inside the playing single file,
  /// stretched over the file's real duration. Null when untracked.
  List<int>? _schedOffsets;

  /// Weights awaiting the file duration before the schedule can be built.
  List<int>? _pendingWeights;
  int _pendingSurah = 0;

  StreamSubscription<void>? _completedSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<Duration?>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  AudioService get _audio => Get.find<AudioService>();
  NakhtemSettingsController get _settings =>
      Get.find<NakhtemSettingsController>();

  /// The currently selected reciter (same one Khatma uses), or null.
  Reciter? get reciter => _settings.selectedMushafReciter;

  bool get hasReciter => reciter != null;
  bool get active => playingSurah.value > 0;
  bool get hasQueue => queue.isNotEmpty;

  /// `current / total` progress text for the mini-player, or null.
  String? get queueProgress =>
      hasQueue ? '${queueIndex.value + 1} / ${queue.length}' : null;

  /// Key driving the mushaf highlighter: `'s:v'` for the exact ayah.
  /// In single-file playback the live [trackedAyah] is used when known,
  /// otherwise `'s:'` highlights the whole surah. Null when idle.
  String? get highlightKey {
    if (!active) return null;
    if (playingAyah.value == 0) {
      final t = trackedAyah.value;
      if (t > 0) return '${playingSurah.value}:$t';
      return '${playingSurah.value}:';
    }
    return '${playingSurah.value}:${playingAyah.value}';
  }

  String reciterLabel(String lang) =>
      reciter?.titleFor(lang) ??
      (lang == 'ar' ? 'اختر القارئ' : 'Select reciter');

  void _ensureCompletionHook() {
    _completedSub ??= _audio.completedStream.listen((_) => _onCompleted());
  }

  void _ensureIndexHook() {
    _indexSub ??= _audio.sequenceIndexStream.listen((i) {
      if (!_gapless || i == null) return;
      if (i < 0 || i >= queue.length) return;
      queueIndex.value = i;
      playingSurah.value = queue[i].surah;
      playingAyah.value = queue[i].ayah;
    });
  }

  void _ensurePositionHook() {
    _positionSub ??= _audio.positionStream.listen((pos) {
      // Sound is out — never show a loading spinner from here on.
      if ((pos?.inMilliseconds ?? 0) > 0 && isLoading.value) {
        isLoading.value = false;
      }
      if (!_singleFile || pos == null) return;
      final offs = _schedOffsets;
      if (offs == null || offs.isEmpty) return;
      final t = pos.inMilliseconds;
      var idx = offs.length - 1;
      for (var i = 0; i < offs.length; i++) {
        if (t < offs[i]) {
          idx = i - 1;
          break;
        }
      }
      final ayah = idx.clamp(0, offs.length - 1) + 1;
      if (trackedAyah.value != ayah) trackedAyah.value = ayah;
    });
  }

  /// Builds the ayah schedule for a single-file surah recording: per-verse
  /// duration weights stretched over the file's real duration, so the live
  /// ayah can be tracked from the playback position. Best-effort — leaves
  /// tracking off (whole-surah highlight) when timings are unavailable.
  ///
  /// Reciters missing from the timings catalog fall back to Alafasy's
  /// weights as a tempo proxy: relative ayah lengths are dominated by the
  /// text itself, so the highlight stays approximately correct.
  Future<void> _beginTrackedSchedule(
      Reciter r, int surah, int ayahCount) async {
    _schedOffsets = null;
    _pendingWeights = null;
    _pendingSurah = 0;
    trackedAyah.value = 0;
    try {
      if (_settings.settings.value.edition == 'warsh') return;
      if (!Get.isRegistered<VerseTimingsService>()) return;
      final svc = Get.find<VerseTimingsService>();
      var id = await svc.matchRecitation(r.name);
      id ??= await svc.matchRecitation('Mishary Rashid Alafasy');
      if (id == null) return;
      if (!_singleFile || playingSurah.value != surah) return; // stale
      final weights = await svc.verseDurations(
        recitationId: id,
        surah: surah,
        expectedAyahs: ayahCount,
      );
      if (weights == null || weights.isEmpty) return;
      if (!_singleFile || playingSurah.value != surah) return; // stale
      _pendingWeights = weights;
      _pendingSurah = surah;
      _ensureDurationHook();
      _tryBuildSchedule();
    } catch (_) {
      // tracking stays off
    }
  }

  /// Builds the schedule once the file duration is known. Called after the
  /// weights arrive and again whenever fresh duration metadata lands, so
  /// late-parsed durations still enable tracking.
  void _tryBuildSchedule() {
    final weights = _pendingWeights;
    if (weights == null || !_singleFile) return;
    final surah = _pendingSurah;
    if (surah <= 0 || playingSurah.value != surah) return;
    final durationMs = _audio.duration?.inMilliseconds ?? 0;
    if (durationMs <= 0) return;
    final total = weights.fold(0, (a, b) => a + b);
    if (total <= 0) return;
    final offs = <int>[];
    var cum = 0;
    for (final w in weights) {
      offs.add(durationMs * cum ~/ total);
      cum += w;
    }
    _schedOffsets = offs;
    _pendingWeights = null;
    _pendingSurah = 0;
    _ensurePositionHook();
  }

  void _ensureDurationHook() {
    _durationSub ??= _audio.durationStream.listen((_) {
      if (_singleFile && _schedOffsets == null) _tryBuildSchedule();
    });
  }

  /// Completion means the whole surah/page/file finished → stop.
  /// Only the sequential fallback mode advances the queue ayah-by-ayah.
  Future<void> _onCompleted() async {
    if (_gapless || _singleFile || queue.isEmpty) {
      await stop();
      return;
    }
    await _playNext();
  }

  Future<void> _playOne(Reciter r, int surah, int ayah) async {
    error.value = null;
    isLoading.value = true;
    playingSurah.value = surah;
    playingAyah.value = ayah;
    try {
      await _audio.playAyah(reciter: r, surah: surah, ayah: ayah);
      if (_audio.error != null) {
        error.value = _audio.error;
        isPlaying.value = false;
      } else {
        isPlaying.value = true;
        _ensurePositionHook();
      }
    } catch (e) {
      error.value = e.toString();
      isPlaying.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sequential fallback: advances the queue after an ayah completes.
  /// Stops when exhausted.
  Future<void> _playNext() async {
    if (queue.isEmpty) return;
    final next = queueIndex.value + 1;
    if (next >= queue.length) {
      await stop();
      return;
    }
    final r = reciter;
    if (r == null) {
      error.value = 'no_reciter';
      await stop();
      return;
    }
    queueIndex.value = next;
    await _playOne(r, queue[next].surah, queue[next].ayah);
  }

  /// Resolves the primary stream URL per ayah, keeping (ayah, url) pairs
  /// aligned so playlist indexes always map back to the right ayah.
  /// API reciters share one cached template lookup, resolved concurrently.
  Future<List<(QueueAya, String)>> _resolvePairs(
    Reciter r,
    List<QueueAya> ayahs,
  ) async {
    final apiId = r.apiIdentifier;
    if (apiId == null) {
      final out = <(QueueAya, String)>[];
      for (final a in ayahs) {
        final url = r.buildUrl(a.surah, a.ayah);
        if (url != null) out.add((a, url));
      }
      return out;
    }
    final svc = Get.find<ReciterApiService>();
    final resolved = await Future.wait([
      for (final a in ayahs)
        () async {
          final global = QuranIndex.instance.globalIndex(a.surah, a.ayah);
          if (global == null) return null;
          final candidates =
              await svc.audioCandidates(identifier: apiId, globalAyah: global);
          if (candidates.isEmpty) return null;
          return (a, candidates.first);
        }(),
    ]);
    return resolved.whereType<(QueueAya, String)>().toList();
  }

  /// Starts gapless playback of [ayahs]; falls back to sequential mode when
  /// the playlist cannot be prepared.
  Future<void> _playContinuous(
    Reciter r,
    List<QueueAya> ayahs,
    String label,
  ) async {
    _ensureCompletionHook();
    _ensureIndexHook();
    _schedOffsets = null;
    _pendingWeights = null;
    _pendingSurah = 0;
    trackedAyah.value = 0;
    error.value = null;
    isLoading.value = true;
    final pairs = await _resolvePairs(r, ayahs);
    if (pairs.isEmpty) {
      isLoading.value = false;
      error.value = 'audio_unavailable';
      return;
    }
    queue.value = [for (final p in pairs) p.$1];
    queueIndex.value = 0;
    queueLabel.value = label;
    playingSurah.value = queue.first.surah;
    playingAyah.value = queue.first.ayah;
    try {
      await _audio.loadPlaylist([for (final p in pairs) p.$2]);
      _gapless = true;
      _singleFile = false;
      await _audio.playPlaylist();
      isPlaying.value = true;
      _ensurePositionHook();
    } catch (_) {
      // Playlist preparation failed — sequential mode with mirror retries.
      _gapless = false;
      await _playOne(r, queue.first.surah, queue.first.ayah);
      return;
    } finally {
      isLoading.value = false;
    }
  }

  /// Plays a single ayah, replacing any active queue.
  Future<void> play(int surah, int ayah) async {
    final r = reciter;
    if (r == null) {
      error.value = 'no_reciter';
      return;
    }
    _gapless = false;
    _singleFile = false;
    _schedOffsets = null;
    _pendingWeights = null;
    _pendingSurah = 0;
    trackedAyah.value = 0;
    queue.clear();
    queueLabel.value = '';
    queueIndex.value = 0;
    await _playOne(r, surah, ayah);
  }

  /// Plays an entire surah as one continuous recitation.
  ///
  /// Prefers a single full-surah file so the reciter's own breaks are
  /// respected — per-ayah cuts are never stitched. Two single-file sources
  /// are tried in order: the Islamic Network `audio-surah` CDN (exact
  /// edition match) then mp3quran.net (matched by reciter name, large
  /// catalog). Falls back to the gapless per-ayah playlist only when no
  /// single-file stream loads.
  Future<void> playSurah(int surah) async {
    final r = reciter;
    if (r == null) {
      error.value = 'no_reciter';
      return;
    }
    final meta = QuranIndex.instance.surahMeta(surah);
    if (meta == null || meta.ayahCount <= 0) return;
    _ensureCompletionHook();
    _ensureIndexHook();
    error.value = null;
    isLoading.value = true;
    try {
      // Source 1: Islamic Network audio-surah CDN (exact edition match).
      final apiId = r.apiIdentifier;
      if (apiId != null) {
        try {
          final candidates = await Get.find<ReciterApiService>()
              .surahCandidates(identifier: apiId, surah: surah);
          for (final url in candidates) {
            if (await _playSingleFile(url, surah, meta.nameAr)) return;
          }
        } catch (_) {
          // fall through to the next source
        }
      }
      // Source 2: mp3quran.net full-surah recording (matched by name).
      try {
        if (Get.isRegistered<Mp3QuranService>()) {
          final name = r.localizedName.isNotEmpty ? r.localizedName : r.name;
          final url = await Get.find<Mp3QuranService>().surahUrl(
            arabicName: name,
            surah: surah,
            edition: _settings.settings.value.edition,
          );
          if (url != null && await _playSingleFile(url, surah, meta.nameAr)) {
            return;
          }
        }
      } catch (_) {
        // fall through to the playlist fallback
      }
    } finally {
      isLoading.value = false;
    }
    await _playContinuous(
      r,
      [for (var a = 1; a <= meta.ayahCount; a++) (surah: surah, ayah: a)],
      meta.nameAr,
    );
  }

  /// Loads one full-surah file and starts it. Returns true on success,
  /// false when the URL fails to load (caller tries the next candidate).
  /// Kicks off ayah tracking in the background so the highlight follows
  /// ayah-per-ayah while the single file plays.
  Future<bool> _playSingleFile(String url, int surah, String label) async {
    try {
      await _audio.loadSingle(url);
    } catch (_) {
      return false;
    }
    final r = reciter;
    final ayahCount = QuranIndex.instance.surahMeta(surah)?.ayahCount ?? 0;
    _gapless = false;
    _singleFile = true;
    _schedOffsets = null;
    _pendingWeights = null;
    _pendingSurah = 0;
    trackedAyah.value = 0;
    queue.clear();
    queueIndex.value = 0;
    queueLabel.value = label;
    playingSurah.value = surah;
    playingAyah.value = 0;
    await _audio.playPlaylist();
    isPlaying.value = true;
    _ensurePositionHook();
    if (r != null && ayahCount > 0) {
      unawaited(_beginTrackedSchedule(r, surah, ayahCount));
    }
    return true;
  }

  /// Plays every ayah visible on a mushaf page as one continuous recitation.
  Future<void> playPage(List<QueueAya> ayahs, {String label = ''}) async {
    final r = reciter;
    if (r == null) {
      error.value = 'no_reciter';
      return;
    }
    if (ayahs.isEmpty) return;
    await _playContinuous(r, ayahs, label);
  }

  /// Skips to the next ayah (mini-player ⏭). No-op during single-file
  /// surah playback — there is only one continuous stream.
  Future<void> skipNext() async {
    if (_singleFile) return;
    if (_gapless) {
      await _audio.seekToNext();
    } else {
      await _playNext();
    }
  }

  Future<void> toggle(int surah, int ayah) async {
    if (isPlaying.value &&
        playingSurah.value == surah &&
        playingAyah.value == ayah) {
      await pause();
    } else if (!isPlaying.value &&
        playingSurah.value == surah &&
        playingAyah.value == ayah) {
      await resume();
    } else {
      await play(surah, ayah);
    }
  }

  Future<void> pause() async {
    await _audio.pause();
    isPlaying.value = false;
  }

  Future<void> resume() async {
    await _audio.resume();
    if (active) isPlaying.value = true;
  }

  Future<void> stop() async {
    await _audio.stop();
    _gapless = false;
    _singleFile = false;
    _schedOffsets = null;
    _pendingWeights = null;
    _pendingSurah = 0;
    trackedAyah.value = 0;
    isPlaying.value = false;
    isLoading.value = false;
    playingSurah.value = 0;
    playingAyah.value = 0;
    queue.clear();
    queueIndex.value = 0;
    queueLabel.value = '';
  }

  @override
  void onClose() {
    _completedSub?.cancel();
    _indexSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.onClose();
  }
}

/// Registers [MushafAudioController] on first use (safe in tests where
/// Nakhtem dependencies may be absent — caller must handle missing
/// AudioService/NakhtemSettings via [Get.isRegistered] guards).
void ensureMushafAudioController() {
  if (!Get.isRegistered<MushafAudioController>()) {
    Get.put(MushafAudioController(), permanent: true);
  }
}
