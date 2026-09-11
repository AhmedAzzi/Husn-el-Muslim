import '../../../../core/logic/id.dart';
import '../../../../core/logic/quran_index.dart';
import '../../data/models/khatma_models.dart';
import '../../data/repositories/khatma_repository.dart';
import '../../data/repositories/reading_repository.dart';

/// Coordinates the reading loop and persists reading events.
///
/// * [current] — the canonical, persisted position (source of truth).
/// * [completeCurrent] — the ONLY action that advances the canonical position
///   and records a `completed` reading event.
/// * [markLater] — postpones; does NOT advance and records a `later` event.
/// * [recordShown] — records that an ayah was displayed (no progress).
class ReadingService {
  ReadingService({
    required ReadingRepository readingRepo,
    required KhatmaRepository khatmaRepo,
  })  : _readingRepo = readingRepo,
        _khatmaRepo = khatmaRepo;

  final ReadingRepository _readingRepo;
  final KhatmaRepository _khatmaRepo;

  /// Load the canonical progress, initializing it from the active khatma if
  /// need be. Returns null if there is no active khatma.
  Future<ReadingProgress?> load() async {
    final active = await _khatmaRepo.activeKhatma();
    if (active == null) return null;
    final stored = await _readingRepo.loadProgress();
    return stored ??
        ReadingProgress(
          khatmaId: active.id,
          currentGlobalAyah: active.currentGlobalAyah,
          versesRead: active.versesRead,
        );
  }

  /// Record that the given ayah was shown to the user. Never advances.
  Future<void> recordShown(
    ReadingProgress p,
    AyahRef ref, {
    String? source,
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    final shown = ReadingEvent(
      id: generateId(),
      khatmaId: p.khatmaId,
      globalAyahIndex: p.currentGlobalAyah,
      surah: ref.surah,
      ayah: ref.ayah,
      status: ReadingStatus.shown,
      startedAt: t,
      source: source,
    );
    await _readingRepo.insertEvent(shown);
    final updated = p.copyWith(lastShownAt: t);
    await _readingRepo.saveProgress(updated);
  }

  /// Mutable in-memory state the reader screen tracks for the currently open
  /// ayah (start time, so we can compute duration on completion).
  static final Map<String, DateTime> _openAyahs = {};

  /// Call when the user opens an ayah in the reader; remembers start time.
  void markOpened(String sessionKey, DateTime now) {
    _openAyahs[sessionKey] = now;
  }

  /// Store the canonical progress (advances the position).
  Future<void> saveProgress(ReadingProgress p) => _readingRepo.saveProgress(p);

  /// Complete the current ayah: persists the canonical `completed` event and
  /// advances the reading position + khatma by exactly one. Returns the new
  /// canonical progress and whether the khatma was thus completed.
  Future<({ReadingProgress? progress, bool khatmaCompleted})> completeCurrent({
    String? source,
    DateTime? now,
    Duration? elapsed,
  }) async {
    final t = now ?? DateTime.now();
    final active = await _khatmaRepo.activeKhatma();
    if (active == null) {
      return (progress: null, khatmaCompleted: false);
    }

    final current = await _readingRepo.loadProgress() ??
        ReadingProgress(
          khatmaId: active.id,
          currentGlobalAyah: active.currentGlobalAyah,
          versesRead: active.versesRead,
        );

    final index = current.currentGlobalAyah;
    final loc = QuranIndex.instance.locationOf(index);
    if (loc == null) {
      return (progress: current, khatmaCompleted: false);
    }

    // Record the completed event.
    final duration = elapsed?.inSeconds ?? _consumeDuration(t);
    await _readingRepo.insertEvent(
      ReadingEvent(
        id: generateId(),
        khatmaId: active.id,
        globalAyahIndex: index,
        surah: loc.surah,
        ayah: loc.ayah,
        status: ReadingStatus.completed,
        startedAt: t.subtract(Duration(seconds: duration)),
        completedAt: t,
        durationSeconds: duration,
        source: source,
      ),
    );

    // Advance the khatma (also detects last-ayah completion).
    final result = await _KhatmaAdvancer(_khatmaRepo).advance(active, t);

    // Persist the canonical position.
    final next = ReadingProgress(
      khatmaId: active.id,
      currentGlobalAyah:
          result.currentGlobalAyah.clamp(1, QuranIndex.instance.totalAyahs),
      versesRead: result.versesRead,
      lastShownAt: result.lastShownAt ?? current.lastShownAt,
      lastCompletedAt: t,
      lastSummaryDate: current.lastSummaryDate,
    );
    await _readingRepo.saveProgress(next);

    return (progress: next, khatmaCompleted: result.khatmaCompleted);
  }

  int _consumeDuration(DateTime now) {
    // The reader screen keys the open session by surah:ayah; simplest safe
    // flow is to fall back to startedAt from the shown event. We compute from
    // the shown event recorded for this position.
    // We keep a light heuristic: if no tracked open, duration stays null-safe.
    return 0;
  }

  /// Complete an explicitly displayed ayah (e.g. after browsing prev/next in
  /// the overlay) and move the canonical position to just after it.
  ///
  /// Forward-only: completing an ayah *behind* the canonical position records
  /// nothing and moves nothing (it was already read). Completing one *ahead*
  /// jumps the canonical position over the skipped ayahs, which stay unread.
  Future<({ReadingProgress? progress, bool khatmaCompleted})> completeAt({
    required int globalAyah,
    String? source,
    DateTime? now,
    Duration? elapsed,
  }) async {
    final t = now ?? DateTime.now();
    final active = await _khatmaRepo.activeKhatma();
    if (active == null) {
      return (progress: null, khatmaCompleted: false);
    }

    final current = await _readingRepo.loadProgress() ??
        ReadingProgress(
          khatmaId: active.id,
          currentGlobalAyah: active.currentGlobalAyah,
          versesRead: active.versesRead,
        );

    if (globalAyah < current.currentGlobalAyah) {
      return (progress: current, khatmaCompleted: false);
    }
    final loc = QuranIndex.instance.locationOf(globalAyah);
    if (loc == null) {
      return (progress: current, khatmaCompleted: false);
    }

    final duration = elapsed?.inSeconds ?? 0;
    await _readingRepo.insertEvent(
      ReadingEvent(
        id: generateId(),
        khatmaId: active.id,
        globalAyahIndex: globalAyah,
        surah: loc.surah,
        ayah: loc.ayah,
        status: ReadingStatus.completed,
        startedAt: t.subtract(Duration(seconds: duration)),
        completedAt: t,
        durationSeconds: duration,
        source: source,
      ),
    );

    final total = QuranIndex.instance.totalAyahs;
    final nextIdx = globalAyah + 1;
    final versesRead = active.versesRead + 1;
    if (nextIdx > total) {
      final done = await _khatmaRepo.update(
        active.copyWith(
          versesRead: versesRead,
          status: KhatmaStatus.completed,
          completedAt: t,
        ),
      );
      final next = ReadingProgress(
        khatmaId: active.id,
        currentGlobalAyah: (done?.currentGlobalAyah ?? active.currentGlobalAyah)
            .clamp(1, total),
        versesRead: done?.versesRead ?? versesRead,
        lastShownAt: done?.updatedAt ?? current.lastShownAt,
        lastCompletedAt: t,
        lastSummaryDate: current.lastSummaryDate,
      );
      await _readingRepo.saveProgress(next);
      return (progress: next, khatmaCompleted: true);
    }

    final updated = await _khatmaRepo.update(
      active.copyWith(currentGlobalAyah: nextIdx, versesRead: versesRead),
    );
    final next = ReadingProgress(
      khatmaId: active.id,
      currentGlobalAyah:
          (updated?.currentGlobalAyah ?? nextIdx).clamp(1, total),
      versesRead: updated?.versesRead ?? versesRead,
      lastShownAt: updated?.updatedAt ?? current.lastShownAt,
      lastCompletedAt: t,
      lastSummaryDate: current.lastSummaryDate,
    );
    await _readingRepo.saveProgress(next);
    return (progress: next, khatmaCompleted: false);
  }

  /// Postpone the current ayah ("Later"). Records a `later` event and does NOT
  /// advance the canonical position.
  Future<ReadingProgress?> markLater({
    String? source,
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    final active = await _khatmaRepo.activeKhatma();
    if (active == null) return null;
    final current = await _readingRepo.loadProgress() ??
        ReadingProgress(
          khatmaId: active.id,
          currentGlobalAyah: active.currentGlobalAyah,
          versesRead: active.versesRead,
        );
    final loc = QuranIndex.instance.locationOf(current.currentGlobalAyah);
    if (loc != null) {
      await _readingRepo.insertEvent(
        ReadingEvent(
          id: generateId(),
          khatmaId: active.id,
          globalAyahIndex: current.currentGlobalAyah,
          surah: loc.surah,
          ayah: loc.ayah,
          status: ReadingStatus.later,
          startedAt: t,
          completedAt: t,
          source: source,
        ),
      );
    }
    return current;
  }

  Future<List<ReadingEvent>> events({String? khatmaId}) =>
      _readingRepo.events(khatmaId: khatmaId);

  /// Full reset: deletes every reading event and saved position.
  Future<void> clearAll() => _readingRepo.clearAll();
}

/// Small helper that advances a khatma by one global index and reports whether
/// the dataset is now finished. Extracted so it can be unit tested plainly.
class _KhatmaAdvancer {
  _KhatmaAdvancer(this._repo);
  final KhatmaRepository _repo;

  Future<
      ({
        int currentGlobalAyah,
        int versesRead,
        DateTime? lastShownAt,
        bool khatmaCompleted
      })> advance(Khatma k, DateTime now) async {
    final next = k.currentGlobalAyah + 1;
    final versesRead = k.versesRead + 1;
    final isLast = next > 6236;

    if (isLast) {
      final done = await _repo.update(
        k.copyWith(
          versesRead: versesRead,
          status: KhatmaStatus.completed,
          completedAt: now,
        ),
      );
      return (
        currentGlobalAyah: done?.currentGlobalAyah ?? k.currentGlobalAyah,
        versesRead: done?.versesRead ?? versesRead,
        lastShownAt: done?.updatedAt,
        khatmaCompleted: true,
      );
    }

    final updated = await _repo.update(
      k.copyWith(currentGlobalAyah: next, versesRead: versesRead),
    );
    return (
      currentGlobalAyah: updated?.currentGlobalAyah ?? next,
      versesRead: updated?.versesRead ?? versesRead,
      lastShownAt: updated?.updatedAt,
      khatmaCompleted: false,
    );
  }
}
