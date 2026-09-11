import 'package:get/get.dart';

import '../../data/repositories/asbab_repository.dart';

/// Lazy GetX controller for sabab al-nuzul (al-Wahidy, bundled JSON).
///
/// Mirrors [IrabController]'s source-less pattern: the index loads on first
/// use and stays cached in the repository. The dialog tab reads
/// [text]/[isLoading]/[error]; background paths use [peekSabab], which never
/// touches the tab state.
class AsbabController extends GetxController {
  AsbabController({AsbabRepository? repo}) : _repo = repo ?? AsbabRepository();

  final AsbabRepository? _repo;

  int _surah = 0;
  int _ayah = 0;

  final text = Rxn<String>();
  final isLoading = false.obs;
  final error = Rxn<String>();

  /// Load sabab al-nuzul for [surah]:[ayah]. Skips reload for the same ayah.
  Future<void> loadAyah(int surah, int ayah) async {
    if (_surah == surah && _ayah == ayah && (text.value != null || isLoading.value)) {
      return;
    }
    _surah = surah;
    _ayah = ayah;
    isLoading.value = true;
    error.value = null;
    try {
      final result = await _repo?.getSabab(surah, ayah);
      if (_surah != surah || _ayah != ayah) return; // stale
      text.value = result;
      if (result == null) error.value = 'لا يوجد سبب نزول لهذه الآية';
    } catch (e) {
      if (_surah != surah || _ayah != ayah) return; // stale
      error.value = e.toString();
    } finally {
      if (_surah == surah && _ayah == ayah) isLoading.value = false;
    }
  }

  /// One-shot read that never touches the tab UI state.
  /// Returns null when the data is unavailable or the ayah has no narration.
  Future<String?> peekSabab(int surah, int ayah) async {
    try {
      return await _repo?.getSabab(surah, ayah);
    } catch (_) {
      return null;
    }
  }

  static AsbabController get to => Get.find<AsbabController>();
}

/// Register lazily: no JSON is parsed until the سبب النزول tab is used.
void initAsbabDependencies({AsbabRepository? repo}) {
  if (!Get.isRegistered<AsbabController>()) {
    Get.put(AsbabController(repo: repo), permanent: true);
  }
}
