import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../data/repositories/translation_repository.dart';

/// Lazy GetX controller for the per-ayah English translation tab.
///
/// JSONs stay on disk until the الترجمة tab is first opened; afterwards
/// the surah map is served from the repository cache.
class TranslationController extends GetxController {
  TranslationController({TranslationRepository? repo})
      : _repo = repo ?? TranslationRepository(rootBundle);

  TranslationRepository? _repo;

  int? _surah;
  int? _ayah;

  final text = Rxn<String>();
  final isLoading = false.obs;
  final error = Rxn<String>();

  /// Test helper: inject a repository backed by a fake bundle.
  void primeRepository(TranslationRepository repo) {
    _repo = repo;
  }

  Future<void> loadAyah(int surah, int ayah) async {
    if (_surah == surah && _ayah == ayah && (text.value != null || isLoading.value)) {
      return;
    }
    _surah = surah;
    _ayah = ayah;
    await _fetch();
  }

  Future<void> _fetch() async {
    final surah = _surah;
    final ayah = _ayah;
    if (surah == null || ayah == null) return;
    isLoading.value = true;
    error.value = null;
    try {
      final result = await _repo!.getAyah(surah, ayah);
      if (_surah != surah || _ayah != ayah) return;
      text.value = result;
      if (result == null) error.value = 'لا توجد ترجمة لهذه الآية';
    } catch (e) {
      if (_surah != surah || _ayah != ayah) return;
      error.value = e.toString();
    } finally {
      if (_surah == surah && _ayah == ayah) isLoading.value = false;
    }
  }

  static TranslationController get to => Get.find<TranslationController>();
}

/// Register lazily: no JSON is touched until the الترجمة tab is used.
void initTranslationDependencies({TranslationRepository? repo}) {
  if (!Get.isRegistered<TranslationController>()) {
    Get.put(TranslationController(repo: repo), permanent: true);
  }
}
