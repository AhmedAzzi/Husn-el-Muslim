import 'package:get/get.dart';

import '../../data/repositories/irab_repository.dart';

/// Lazy GetX controller for ayah i'rab (bundled `earab.json`).
///
/// Mirrors [TafsirController]'s pattern but source-less: the index loads on
/// first use and stays cached in the repository. The dialog tab reads
/// [text]/[isLoading]/[error]; background paths use [peekIrab], which never
/// touches the tab state.
class IrabController extends GetxController {
  IrabController({IrabRepository? repo}) : _repo = repo ?? IrabRepository();

  final IrabRepository? _repo;

  int _surah = 0;
  int _ayah = 0;
  String _word = '';

  final text = Rxn<String>();
  final isLoading = false.obs;
  final error = Rxn<String>();

  /// Load i'rab for [surah]:[ayah]. Skips reload for the same ayah.
  Future<void> loadAyah(int surah, int ayah) async {
    if (_surah == surah &&
        _ayah == ayah &&
        (text.value != null || isLoading.value)) {
      return;
    }
    _surah = surah;
    _ayah = ayah;
    isLoading.value = true;
    error.value = null;
    try {
      final result = await _repo?.getIrab(surah, ayah);
      if (_surah != surah || _ayah != ayah) return; // stale
      text.value = result;
      if (result == null) error.value = 'لا يوجد إعراب لهذه الآية';
    } catch (e) {
      if (_surah != surah || _ayah != ayah) return; // stale
      error.value = e.toString();
    } finally {
      if (_surah == surah && _ayah == ayah) isLoading.value = false;
    }
  }

  /// Load i'rab for only the tapped word in an ayah.
  Future<void> loadWord(int surah, int ayah, String word) async {
    if (_surah == surah &&
        _ayah == ayah &&
        _word == word &&
        (text.value != null || isLoading.value)) {
      return;
    }
    _surah = surah;
    _ayah = ayah;
    _word = word;
    isLoading.value = true;
    error.value = null;
    try {
      final result = await _repo?.getWordIrab(surah, ayah, word);
      if (_surah != surah || _ayah != ayah || _word != word) return;
      text.value = result;
      if (result == null) error.value = 'لا يوجد إعراب لهذه الكلمة';
    } catch (e) {
      if (_surah != surah || _ayah != ayah || _word != word) return;
      error.value = e.toString();
    } finally {
      if (_surah == surah && _ayah == ayah && _word == word) {
        isLoading.value = false;
      }
    }
  }

  /// One-shot read that never touches the tab UI state.
  /// Returns null when the data is unavailable or the ayah has no entry.
  Future<String?> peekIrab(int surah, int ayah) async {
    try {
      return await _repo?.getIrab(surah, ayah);
    } catch (_) {
      return null;
    }
  }

  static IrabController get to => Get.find<IrabController>();
}

/// Register lazily: no JSON is parsed until the الإعراب tab is used.
void initIrabDependencies({IrabRepository? repo}) {
  if (!Get.isRegistered<IrabController>()) {
    Get.put(IrabController(repo: repo), permanent: true);
  }
}
