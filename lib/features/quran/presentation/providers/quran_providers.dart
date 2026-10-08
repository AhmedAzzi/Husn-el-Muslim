import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../data/models/quran_models.dart';
import '../../data/repositories/quran_repository.dart';

/// Bundle type for one mushaf page + its tajweed maps.
typedef PageBundle = ({MushafPageData page, Map<int, List<TajAya>> tajMap});

/// GetX replacement for the old Riverpod `quranRepoProvider` /
/// `surahListProvider` / `mushafMetaProvider` / `mushafPageProvider`.
class QuranController extends GetxController {
  QuranController(this.repo);

  final QuranRepository repo;

  final surahs = Rxn<List<Surah>>();
  final surahsError = Rxn<String>();
  final isLoadingSurahs = false.obs;

  final meta = Rxn<MushafMeta>();
  final metaError = Rxn<String>();
  final isLoadingMeta = false.obs;

  final Map<int, Future<PageBundle>> _pageFutures = {};

  @override
  void onInit() {
    super.onInit();
    loadSurahs();
    loadMeta();
  }

  Future<void> loadSurahs() async {
    if (surahs.value != null || isLoadingSurahs.value) return;
    isLoadingSurahs.value = true;
    try {
      surahs.value = await repo.loadSurahs();
      surahsError.value = null;
    } catch (e) {
      surahsError.value = e.toString();
    } finally {
      isLoadingSurahs.value = false;
    }
  }

  Future<void> loadMeta() async {
    if (meta.value != null || isLoadingMeta.value) return;
    isLoadingMeta.value = true;
    try {
      meta.value = await repo.loadMeta();
      metaError.value = null;
    } catch (e) {
      debugPrint('QuranController.loadMeta failed: $e');
      metaError.value = e.toString();
    } finally {
      isLoadingMeta.value = false;
    }
  }

  /// Cached page bundle future (replaces `mushafPageProvider(family)`).
  ///
  /// Batch 4 (perf-only): capped LRU. An uncapped map retains all 604
  /// bundles (each with tajweed maps) after a full read-through — tens of
  /// MB held forever. Evicted pages re-parse on revisit with identical
  /// content; the PageView working set (±1 page) always stays cached.
  static const int _maxCachedPages = 12;

  Future<PageBundle> pageBundle(int page) {
    final existing = _pageFutures[page];
    if (existing != null) {
      // Refresh recency: reinsert so eviction drops the stalest page.
      _pageFutures.remove(page);
      _pageFutures[page] = existing;
      return existing;
    }
    if (_pageFutures.length >= _maxCachedPages) {
      _pageFutures.remove(_pageFutures.keys.first);
    }
    final created = repo.loadPageBundle(page);
    _pageFutures[page] = created;
    return created;
  }

  /// Test helper: inject a pre-resolved bundle without touching assets.
  void primePageBundle(int page, PageBundle bundle) {
    _pageFutures[page] = Future.value(bundle);
  }

  static QuranController get to => Get.find<QuranController>();
}

/// Home search state (mirrors `+page.svelte` locals).
class HomeFilterController extends GetxController {
  final query = ''.obs;

  void setQuery(String q) => query.value = q;

  static HomeFilterController get to => Get.find<HomeFilterController>();
}

/// Convenience factory used by `main()` and tests to register everything.
void initQuranDependencies(QuranRepository repo) {
  if (!Get.isRegistered<QuranController>()) {
    Get.put(QuranController(repo), permanent: true);
  }
  if (!Get.isRegistered<HomeFilterController>()) {
    Get.put(HomeFilterController(), permanent: true);
  }
  // Eagerly kick off loads (also triggered by onInit).
  Get.find<QuranController>().loadSurahs();
  Get.find<QuranController>().loadMeta();
}

/// Test-only: build a controller backed by an arbitrary [AssetBundle].
QuranController makeQuranControllerForTests(AssetBundle bundle) {
  final c = QuranController(QuranRepository(bundle));
  if (Get.isRegistered<QuranController>()) Get.delete<QuranController>();
  Get.put<QuranController>(c);
  return c;
}
