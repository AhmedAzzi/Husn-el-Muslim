import 'package:get/get.dart';

import '../../data/models/nakhtem_settings.dart';
import '../../data/models/reciter_model.dart';
import '../../data/repositories/reciter_api_service.dart';

/// Reactive controller for [NakhtemSettings], persisted via the KV store.
/// Follows the existing GetX pattern used by [SettingsController].
class NakhtemSettingsController extends GetxController {
  NakhtemSettingsController(this._load, this._save,
      {ReciterApiService? recitersApi})
      : _recitersApi = recitersApi;

  /// Reads the persisted map (a subset of KV rows prefixed `setting_`).
  final Future<Map<String, String>> Function() _load;

  /// Persists the given setting rows.
  final Future<void> Function(Map<String, String>) _save;

  final ReciterApiService? _recitersApi;

  final settings = const NakhtemSettings().obs;

  /// Reciter list: API result when online, [ReciterCatalog.defaults] offline.
  final reciters = <Reciter>[...ReciterCatalog.defaults].obs;

  /// True while the API list is loading; false for the instant fallback.
  final recitersLoading = true.obs;

  /// Guards overlapping refreshes so the loading flag can never stick on.
  bool _loadingReciters = false;

  /// Non-null when the API fetch failed and the offline fallback is shown.
  final recitersError = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    loadReciters();
  }

  /// Fetches reciters from alquran.cloud; keeps [ReciterCatalog.defaults]
  /// when offline or when the API misbehaves. Safe to retry.
  ///
  /// Bundled reciters with no per-ayah API equivalent (e.g. Saad Al-Ghamdi,
  /// the Warsh Yassin Al-Jazaery) are always appended via
  /// [ReciterCatalog.supplementalFor] so they stay selectable online too.
  Future<void> loadReciters() async {
    final api = _recitersApi;
    if (api == null) {
      recitersLoading.value = false;
      return;
    }
    // Overlapping refreshes share the in-flight load instead of stacking,
    // so the flag always settles back to false.
    if (_loadingReciters) return;
    _loadingReciters = true;
    recitersLoading.value = true;
    recitersError.value = null;
    try {
      final fetched =
          await api.fetchReciters().timeout(const Duration(seconds: 15));
      reciters.value = [...fetched, ...ReciterCatalog.supplementalFor(fetched)];
    } catch (e) {
      recitersError.value = e.toString();
      reciters.value = [...ReciterCatalog.defaults];
    } finally {
      _loadingReciters = false;
      if (!isClosed) recitersLoading.value = false;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final kv = await _load();
      settings.value = NakhtemSettings.fromKV(kv);
    } catch (_) {
      // keep defaults
    }
  }

  Future<void> _persist([NakhtemSettings? value]) async {
    try {
      await _save((value ?? settings.value).toKV());
    } catch (_) {
      // best-effort persistence
    }
  }

  Future<void> setEdition(String edition) async {
    settings.value = settings.value.copyWith(edition: edition);
    await _persist();
  }

  Future<void> setMushafReciter(String? id) async {
    settings.value = settings.value.copyWith(mushafReciterId: id ?? '');
    await _persist();
  }

  Future<void> setKhatmaReciter(String? id) async {
    settings.value = settings.value.copyWith(khatmaReciterId: id ?? '');
    await _persist();
  }

  Future<void> setTafsirEnabled(bool v) async {
    settings.value = settings.value.copyWith(tafsirEnabled: v);
    await _persist();
  }

  Future<void> setTranslationEnabled(bool v) async {
    settings.value = settings.value.copyWith(translationEnabled: v);
    await _persist();
  }

  Future<void> setShowDailySummary(bool v) async {
    settings.value = settings.value.copyWith(showDailySummary: v);
    await _persist();
  }

  /// Returns the reciter matching the current setting, or null.
  /// Resolves against the API list first, then the offline defaults, so a
  /// reciter picked while online keeps working across restarts.
  Reciter? get selectedMushafReciter =>
      ReciterCatalog.byIdIn(reciters, settings.value.mushafReciterId);

  /// Same as [selectedMushafReciter] but for the independent khatma slot.
  Reciter? get selectedKhatmaReciter =>
      ReciterCatalog.byIdIn(reciters, settings.value.khatmaReciterId);
}
