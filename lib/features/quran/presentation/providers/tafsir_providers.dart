import 'package:get/get.dart';

import '../../data/models/tafsir_source.dart';
import '../../data/repositories/tafsir_repository.dart';

/// Lazy GetX controller for ayah tafsir.
///
/// The 100MB+ DB is NOT opened at startup. The first opening of the التفسير
/// tab triggers the asset copy + `openDatabase(readOnly: true)` once, off
/// the critical path; later reads hit the repository ayah cache.
class TafsirController extends GetxController {
  TafsirController({TafsirRepository? repo}) : _repo = repo;

  WordTafsirRef? _ref;
  TafsirRepository? _repo;
  Future<TafsirRepository>? _opening;

  final source = TafsirSource.moyassar.obs;
  final text = Rxn<String>();
  final isLoading = false.obs;
  final error = Rxn<String>();

  Future<TafsirRepository> _ensureRepo() async {
    final existing = _repo;
    if (existing != null) return existing;
    final opening = _opening ??= TafsirRepository.open();
    try {
      final repo = await opening;
      _repo = repo;
      return repo;
    } catch (e) {
      _opening = null;
      rethrow;
    }
  }

  /// Test helper: inject an already-open repository.
  void primeRepository(TafsirRepository repo) {
    _repo = repo;
    _opening = null;
  }

  /// Load tafsir for [surah]:[ayah] in the current [source].
  /// Skips reload when the same ayah+source is already shown.
  Future<void> loadAyah(int surah, int ayah) async {
    final ref = WordTafsirRef(
      surah: surah,
      ayah: ayah,
      source: source.value,
    );
    if (_ref == ref && (text.value != null || isLoading.value)) return;
    _ref = ref;
    await _fetch();
  }

  Future<void> setSource(TafsirSource s) async {
    if (source.value == s) return;
    source.value = s;
    final ref = _ref;
    if (ref == null) return;
    _ref = WordTafsirRef(surah: ref.surah, ayah: ref.ayah, source: s);
    await _fetch();
  }

  Future<void> _fetch() async {
    final ref = _ref;
    if (ref == null) return;
    isLoading.value = true;
    error.value = null;
    try {
      final repo = await _ensureRepo();
      final result = await repo.getTafsir(ref.source, ref.surah, ref.ayah);
      // Ignore stale responses after a source/ayah switch mid-flight.
      if (_ref != ref) return;
      text.value = result;
      if (result == null) error.value = 'لا يوجد تفسير لهذه الآية';
    } catch (e) {
      if (_ref != ref) return;
      error.value = e.toString();
    } finally {
      if (_ref == ref) isLoading.value = false;
    }
  }

  /// One-shot read that never touches the tab UI state ([source], [text]).
  /// Used by background paths (e.g. the unlock overlay) that need tafsir
  /// without disturbing what the dialog tab currently shows.
  /// Returns null when the DB is unavailable or the ayah has no entry.
  Future<String?> peekTafsir(
    TafsirSource peekSource,
    int surah,
    int ayah,
  ) async {
    try {
      final repo = await _ensureRepo();
      return await repo.getTafsir(peekSource, surah, ayah);
    } catch (_) {
      return null;
    }
  }

  static TafsirController get to => Get.find<TafsirController>();
}

/// Register lazily: does NOT open the DB until the التفسير tab is used.
void initTafsirDependencies({TafsirRepository? repo}) {
  if (!Get.isRegistered<TafsirController>()) {
    Get.put(TafsirController(repo: repo), permanent: true);
  }
}

class WordTafsirRef {
  const WordTafsirRef({
    required this.surah,
    required this.ayah,
    required this.source,
  });

  final int surah;
  final int ayah;
  final TafsirSource source;

  @override
  bool operator ==(Object other) =>
      other is WordTafsirRef &&
      other.surah == surah &&
      other.ayah == ayah &&
      other.source == source;

  @override
  int get hashCode => Object.hash(surah, ayah, source);
}
