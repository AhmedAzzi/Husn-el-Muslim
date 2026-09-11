import '../../data/models/khatma_models.dart';
import '../../data/repositories/khatma_repository.dart';

/// Business logic for creating, advancing, pausing, resuming and finishing a
/// khatma. It owns the rule that only an explicit completion advances the
/// canonical position, and it delegates persistence to [KhatmaRepository].
class KhatmaService {
  KhatmaService(this._khatmaRepo);

  final KhatmaRepository _khatmaRepo;

  /// Start a brand new khatma at [startingGlobalAyah] (1-based global index).
  /// Does NOT erase previous khatmas — they remain in history.
  Future<Khatma> start({
    required String name,
    required String edition,
    required int startingGlobalAyah,
    DateTime? now,
  }) async {
    if (startingGlobalAyah < 1) {
      throw ArgumentError('startingGlobalAyah must be >= 1');
    }
    return _khatmaRepo.create(
      name: name,
      edition: edition,
      startingGlobalAyah: startingGlobalAyah,
      now: now,
    );
  }

  Future<Khatma?> active() => _khatmaRepo.activeKhatma();

  /// Mark the current ayah completed and advance by exactly one global index.
  /// Returns the updated khatma (or null if the active khatma disappeared).
  Future<(Khatma?, bool completed)> completeCurrent({
    DateTime? now,
  }) async {
    final k = await active();
    if (k == null) return (null, false);

    final t = now ?? DateTime.now();
    final next = k.currentGlobalAyah + 1;
    final versesRead = k.versesRead + 1;

    final isLast = next > 6236; // beyond last ayah of the dataset
    if (isLast) {
      final done = await _khatmaRepo.update(
        k.copyWith(
            versesRead: versesRead,
            status: KhatmaStatus.completed,
            completedAt: t),
      );
      if (done != null) return (done, true);
      return (
        k.copyWith(
            versesRead: versesRead,
            status: KhatmaStatus.completed,
            completedAt: t),
        true
      );
    }

    final updated = await _khatmaRepo.update(
      k.copyWith(currentGlobalAyah: next, versesRead: versesRead),
    );
    return (updated, false);
  }

  Future<Khatma?> pause({DateTime? now}) async {
    final k = await active();
    if (k == null) return null;
    await _khatmaRepo.setStatus(k, KhatmaStatus.paused);
    return _khatmaRepo.findById(k.id);
  }

  Future<Khatma?> resume() async {
    final k = await active();
    if (k == null) return null;
    // Re-activate a paused khatma by selecting it as active.
    await _khatmaRepo.setActive(k.id);
    await _khatmaRepo.setStatus(k, KhatmaStatus.active);
    return _khatmaRepo.findById(k.id);
  }

  Future<void> finish({DateTime? now}) async {
    final k = await active();
    if (k != null) await _khatmaRepo.markCompleted(k, now);
  }

  Future<void> setActive(String id) => _khatmaRepo.setActive(id);

  Future<List<Khatma>> all() => _khatmaRepo.all();

  Future<Khatma?> update(Khatma k) => _khatmaRepo.update(k);

  /// Full reset: deletes every khatma (settings like reciter/edition kept).
  Future<void> clearAll() => _khatmaRepo.clearAll();

  Future<List<Khatma>> previous() => _khatmaRepo.previous();
}
