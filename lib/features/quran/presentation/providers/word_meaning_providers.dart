import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/word_meaning.dart';
import '../../data/repositories/word_meaning_repository.dart';
import '../widgets/word_detail_dialog.dart';

/// Lazy GetX controller for tap-to-show word meanings.
///
/// The 20MB DB is NOT opened at startup. The first tap triggers the
/// asset copy + `openDatabase(readOnly: true)` once, off the critical path;
/// later taps hit the ayah cache inside the repository.
class WordMeaningController extends GetxController {
  WordMeaningController({WordMeaningRepository? repo}) : _repo = repo;

  WordMeaningRepository? _repo;
  Future<WordMeaningRepository>? _opening;

  final selected = Rxn<WordMeaning>();
  final isLoading = false.obs;
  final error = Rxn<String>();

  Future<WordMeaningRepository> _ensureRepo() async {
    final existing = _repo;
    if (existing != null) return existing;
    final opening = _opening ??= WordMeaningRepository.open();
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
  void primeRepository(WordMeaningRepository repo) {
    _repo = repo;
    _opening = null;
  }

  Future<WordMeaning?> fetchWord(int surah, int ayah, int word) async {
    isLoading.value = true;
    error.value = null;
    try {
      final repo = await _ensureRepo();
      final result = await repo.getWord(surah, ayah, word);
      selected.value = result;
      if (result == null) error.value = 'لا توجد معاني لهذه الكلمة';
      return result;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Parse a `s:a:w` location and show the centered tabbed word dialog.
  /// No-op for ayah markers or malformed locations.
  ///
  /// [tajweedClasses] are the distinct non-empty tajweed rule ids covering
  /// the tapped word; [initialTab] selects the opening tab (0 = المعنى,
  /// 1 = التجويد). Extra tabs (tafsir, …) can be passed via [extraTabs].
  Future<void> showWordDialog(
    BuildContext context,
    String location, {
    List<String> tajweedClasses = const [],
    int initialTab = 0,
    List<({String label, Widget view})> extraTabs = const [],
  }) async {
    final parsed = WordMeaning.parseLocation(location);
    if (parsed == null) return;
    final result = await fetchWord(parsed.s, parsed.a, parsed.w);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => WordDetailDialog(
        selected: selected,
        isLoading: isLoading,
        error: error,
        tajweedClasses: tajweedClasses,
        initialTab: result == null ? 0 : initialTab,
        surah: parsed.s,
        ayah: parsed.a,
        word: result?.wordWithHaraqah ?? result?.plain,
        extraTabs: extraTabs,
      ),
    );
  }

  /// Backwards-compatible alias (bottom sheet removed in favor of dialog).
  Future<void> showWordSheet(BuildContext context, String location) =>
      showWordDialog(context, location);

  static WordMeaningController get to => Get.find<WordMeaningController>();
}

/// Register lazily: does NOT open the DB until the first word tap.
void initWordMeaningDependencies({WordMeaningRepository? repo}) {
  if (!Get.isRegistered<WordMeaningController>()) {
    Get.put(WordMeaningController(repo: repo), permanent: true);
  }
}
