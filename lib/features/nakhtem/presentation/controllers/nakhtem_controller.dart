import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/logic/quran_index.dart';
import '../../../../core/platform/phone_experience_service.dart';
import '../../../../features/quran/presentation/providers/quran_providers.dart';
import '../../../../features/quran/presentation/providers/tafsir_providers.dart';
import '../../../quran/data/models/tafsir_source.dart';
import '../../data/models/khatma_models.dart';
import '../../data/repositories/reciter_api_service.dart';
import '../../domain/services/khatma_service.dart';
import '../../domain/services/reading_service.dart';
import 'nakhtem_settings_controller.dart';

/// Main GetX controller for the khatma reading experience.
///
/// State split (critical distinction):
///   * [progress]      — canonical persisted position (single source of truth).
///   * [viewed]        — temporary ayah the user is browsing (Previous/Next).
///                       Never persisted; only an explicit Complete advances.
///
/// So pressing Next and leaving does NOT lose or advance the canonical
/// position; only [completeCurrent] advances it.
class NakhtemController extends GetxController {
  final KhatmaService _khatmaService = Get.find<KhatmaService>();
  final ReadingService _readingService = Get.find<ReadingService>();

  final khatma = Rxn<Khatma>();
  final progress = Rxn<ReadingProgress>();

  /// The temporary ayah currently being viewed (1-based global index).
  final viewed = Rxn<int>();

  final version = Rxn<String>();
  final editions = Rxn<List<String>>();
  final isLoading = false.obs;
  final error = Rxn<String>();

  /// Full Arabic text (and tajweed slices) of the viewed ayah.
  final ayahText = Rxn<String>();
  final ayahSlices = Rxn<List<KemSlicePublic>>();
  final isAyahLoading = false.obs;
  final ayahError = Rxn<String>();

  /// Timestamp when the currently viewed ayah was opened (for duration).
  DateTime? _viewedOpenedAt;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    error.value = null;
    try {
      final k = await _khatmaService.active();
      khatma.value = k;
      if (k != null) {
        final p = await _readingService.load();
        progress.value = p;
        final pub = p ??
            ReadingProgress(
              khatmaId: k.id,
              currentGlobalAyah: k.currentGlobalAyah,
              versesRead: k.versesRead,
            );
        final loc = QuranIndex.instance.locationOf(pub.currentGlobalAyah);
        final meta =
            loc == null ? null : QuranIndex.instance.surahMeta(loc.surah);
        version.value = pub.currentGlobalAyah == 0
            ? ''
            : '${meta?.nameAr ?? ''} ${loc?.ayah ?? ''}';
        editions.value = QuranEdition.all.map((e) => e.id).toList();
        proceedTo(pub.currentGlobalAyah);
        // Reconcile a ✓ tapped while the engine was away, then refresh the
        // native unlock cache for the next genuine OFF → unlock cycle.
        await reconcilePendingCompletion();
      } else {
        progress.value = null;
        viewed.value = null;
        ayahText.value = null;
        await Get.find<PhoneExperienceService>()
            .cacheOverlayAyah(enabled: false);
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Move the *temporary* viewed ayah to [globalIndex] and load its text.
  /// Does not alter canonical progress.
  Future<void> proceedTo(int globalIndex) async {
    final loc = QuranIndex.instance.locationOf(globalIndex);
    if (loc == null) {
      ayahText.value = null;
      ayahError.value = 'invalid_ayah';
      return;
    }
    viewed.value = globalIndex;
    _viewedOpenedAt = DateTime.now();
    await _loadAyahLoc(loc.surah, loc.ayah);
  }

  /// Load ayah text from the canonical bundled data (taj JSON).
  Future<void> _loadAyahLoc(int surah, int ayah) async {
    isAyahLoading.value = true;
    ayahError.value = null;
    try {
      final taj =
          await Get.find<QuranController>().repo.loadAyahText(surah, ayah);
      if (taj == null) {
        ayahError.value = 'missing_ayah';
        ayahText.value = null;
        return;
      }
      ayahText.value = taj.text;
      ayahSlices.value = taj.slices
          .map((s) => KemSlicePublic(start: s.start, end: s.end, cls: s.cls))
          .toList();
    } catch (e) {
      ayahError.value = e.toString();
      ayahText.value = null;
    } finally {
      isAyahLoading.value = false;
    }
  }

  Future<void> previous() async {
    final cur = viewed.value ?? progress.value?.currentGlobalAyah ?? 1;
    if (cur <= 1) return;
    await proceedTo(cur - 1);
  }

  Future<void> next() async {
    final cur = viewed.value ?? progress.value?.currentGlobalAyah ?? 1;
    final nextIdx = cur + 1;
    final loc = QuranIndex.instance.locationOf(nextIdx);
    if (loc == null) return; // end of quran
    await proceedTo(nextIdx);
  }

  /// The ONLY action that completes the current ayah and advances the
  /// canonical position + khatma. Records a completed reading event.
  Future<bool> completeCurrent({String? source}) async {
    final elapsed = _viewedOpenedAt == null
        ? Duration.zero
        : DateTime.now().difference(_viewedOpenedAt!);
    final result = await _readingService.completeCurrent(
      source: source ?? 'reader',
      now: DateTime.now(),
      elapsed: elapsed,
    );
    await _khatmaService.active().then((k) => khatma.value = k);
    final p = result.progress;
    if (p == null) {
      error.value = 'no_active_khatma';
      return false;
    }
    progress.value = p;
    if (result.khatmaCompleted) {
      // Khatma finished.
      khatma.value = null;
      progress.value = null;
      viewed.value = null;
      ayahText.value = null;
      await syncOverlayCache();
      return true;
    }
    await proceedTo(p.currentGlobalAyah);
    await syncOverlayCache();
    return true;
  }

  /// "Later": postpone without advancing. Records a later event.
  Future<void> later({String? source}) async {
    await _readingService.markLater(source: source ?? 'reader');
    // Keep the same canonical + viewed ayah so the next open shows it again.
  }

  /// Complete the ayah currently displayed in the overlay (which may differ
  /// from the canonical position after prev/next browsing). Forward-only:
  /// re-reading an already-read ayah changes nothing.
  Future<bool> completeDisplayed(int globalAyah, {String? source}) async {
    final elapsed = _viewedOpenedAt == null
        ? Duration.zero
        : DateTime.now().difference(_viewedOpenedAt!);
    final result = await _readingService.completeAt(
      globalAyah: globalAyah,
      source: source ?? 'overlay',
      now: DateTime.now(),
      elapsed: elapsed,
    );
    await _khatmaService.active().then((k) => khatma.value = k);
    final p = result.progress;
    if (p == null) {
      error.value = 'no_active_khatma';
      return false;
    }
    progress.value = p;
    if (result.khatmaCompleted) {
      khatma.value = null;
      progress.value = null;
      viewed.value = null;
      ayahText.value = null;
      await syncOverlayCache();
      return true;
    }
    await proceedTo(p.currentGlobalAyah);
    await syncOverlayCache();
    return true;
  }

  /// Start a new khatma at [startingGlobalAyah] after onboarding.
  Future<bool> startKhatma({
    required int startingGlobalAyah,
    required String edition,
    String? name,
  }) async {
    final n = name ?? 'ختمة';
    try {
      final k = await _khatmaService.start(
        name: n,
        edition: edition,
        startingGlobalAyah: startingGlobalAyah,
      );
      khatma.value = k;
      final p = ReadingProgress(
        khatmaId: k.id,
        currentGlobalAyah: startingGlobalAyah,
        versesRead: 0,
      );
      await _readingService.saveProgress(p);
      progress.value = p;
      await proceedTo(startingGlobalAyah);
      await syncOverlayCache();
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    }
  }

  int? get currentGlobalAyah => progress.value?.currentGlobalAyah;

  /// Moves the active khatma's current position to [globalIndex] (manual
  /// reposition from the home selectors — forward or backward).
  /// Persists both the khatma row and the canonical progress, reloads state
  /// and refreshes the overlay cache. Returns false when there is no active
  /// khatma or the index is out of range.
  Future<bool> moveTo(int globalIndex) async {
    try {
      final k = khatma.value;
      if (k == null) return false;
      if (QuranIndex.instance.locationOf(globalIndex) == null) return false;
      final updated = await _khatmaService.update(
        k.copyWith(currentGlobalAyah: globalIndex),
      );
      if (updated == null) return false;
      khatma.value = updated;
      final p = progress.value;
      if (p != null) {
        final moved = p.copyWith(currentGlobalAyah: globalIndex);
        await _readingService.saveProgress(moved);
        progress.value = moved;
      }
      await proceedTo(globalIndex);
      await syncOverlayCache();
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    }
  }

  /// Resolved (surah, ayah) for the temporary viewed ayah.
  ({int surah, int ayah})? get viewedLocation {
    final idx = viewed.value;
    if (idx == null) return null;
    return QuranIndex.instance.locationOf(idx);
  }

  /// Pushes the *canonical* next ayah (the one to read) to the always-on-top
  /// system overlay, together with its neighbours so prev/next work inside
  /// the overlay. The in-app screens never display the ayah — it lives only
  /// in the overlay.
  ///
  /// Returns false when there is no khatma or the overlay permission is
  /// missing.
  Future<bool> publishAyahToOverlay() async {
    final idx =
        progress.value?.currentGlobalAyah ?? khatma.value?.currentGlobalAyah;
    if (idx == null || idx == 0) return false;
    await proceedTo(idx); // ensure the text is loaded for this ayah
    final cur = await _ayahBundle(idx);
    if (cur == null) return false;
    final svc = Get.find<PhoneExperienceService>();
    return svc.showAyahOverlay(
      title: cur['title'] as String,
      body: cur['body'] as String,
      globalAyah: idx,
      surah: cur['surah'] as int,
      ayah: cur['ayah'] as int,
      meta: cur['meta'] as String,
      // Short Mukhtasar gloss (overlay-sized); the native card hides the
      // section when empty (religious text is never fabricated).
      tafsir: cur['tafsir'] as String? ?? '',
      audioUrl: cur['audioUrl'] as String? ?? '',
      prev: await _ayahBundle(idx - 1),
      next: await _ayahBundle(idx + 1),
    );
  }

  /// Handles one of the native overlay buttons:
  ///   * `completed` (✓) — the displayed ayah was read → complete it (which
  ///     advances from there; forward-only, never moves backwards).
  ///   * `later` (◷ clock) — postpones → the SAME ayah is shown next time.
  Future<void> handleOverlayAction(
    String action, {
    int globalAyah = 0,
    int surah = 0,
    int ayah = 0,
  }) async {
    if (action == 'completed') {
      final cur = progress.value?.currentGlobalAyah ??
          khatma.value?.currentGlobalAyah ??
          0;
      if (globalAyah > 0 && cur > 0 && globalAyah > cur) {
        await completeDisplayed(globalAyah, source: 'overlay');
      } else if (globalAyah <= 0 || cur <= 0 || globalAyah == cur) {
        await completeCurrent(source: 'overlay');
      }
      // globalAyah < cur: re-read of an old ayah → nothing to advance.
    } else if (action == 'later') {
      await later(source: 'overlay');
    }
    await dismissOverlay();
  }

  /// Loads one ayah bundle (title/body/meta/tafsir/location) without touching
  /// the temporary viewed state. Returns null for out-of-range or missing
  /// ayahs. Tafsir is the short Mukhtasar gloss (overlay-sized); '' when the
  /// tafsir DB is not ready yet — the native card hides the section then.
  Future<Map<String, Object?>?> _ayahBundle(int globalIndex) async {
    final loc = QuranIndex.instance.locationOf(globalIndex);
    if (loc == null) return null;
    try {
      final taj = await Get.find<QuranController>().repo.loadAyahText(
            loc.surah,
            loc.ayah,
          );
      if (taj == null || taj.text.isEmpty) return null;
      final meta = QuranIndex.instance.surahMeta(loc.surah);
      final name = meta?.nameAr ?? '';
      // Tafsir section of the floating overlay (native hides it when empty).
      String tafsir = '';
      final tafsirOn = !Get.isRegistered<NakhtemSettingsController>() ||
          Get.find<NakhtemSettingsController>().settings.value.tafsirEnabled;
      if (tafsirOn && Get.isRegistered<TafsirController>()) {
        tafsir = await TafsirController.to.peekTafsir(
              TafsirSource.mukhtasar,
              loc.surah,
              loc.ayah,
            ) ??
            '';
      }
      // Per-ayah streams for the native overlay play button, ordered
      // primary-first with mirror fallbacks and newline-joined into one
      // string ('' when no reciter is selected — native toasts instead of
      // failing silently). The native player tries each in order.
      // API reciters resolve their exact bitrate via audioCandidates,
      // because not every edition is served at every bitrate.
      List<String> urls = const [];
      try {
        final reciter =
            Get.find<NakhtemSettingsController>().selectedKhatmaReciter;
        final apiId = reciter?.apiIdentifier;
        if (reciter != null && apiId != null) {
          try {
            urls = await Get.find<ReciterApiService>().audioCandidates(
              identifier: apiId,
              globalAyah: globalIndex,
            );
          } catch (_) {
            urls = reciter.buildUrls(loc.surah, loc.ayah);
          }
        } else {
          urls = reciter?.buildUrls(loc.surah, loc.ayah) ?? const [];
        }
      } catch (_) {
        // best effort only
      }
      final audioUrl = urls.join('\n');
      return {
        'title': '$name ${loc.ayah}',
        'body': taj.text,
        // Reference-style location line, e.g. "(نوح - 4 / 28)".
        'meta': '($name - ${loc.ayah} / ${meta?.ayahCount ?? ''})',
        'tafsir': tafsir,
        'audioUrl': audioUrl,
        'globalAyah': globalIndex,
        'surah': loc.surah,
        'ayah': loc.ayah,
      };
    } catch (_) {
      return null;
    }
  }

  /// Writes the canonical next ayah + its neighbours + the enabled flag to the
  /// native cache so the unlock receiver can draw the overlay while Dart is
  /// paused (screen off). Best effort — never throws.
  Future<void> syncOverlayCache() async {
    try {
      final svc = Get.find<PhoneExperienceService>();
      // The overlay has no settings toggle — it is always enabled whenever
      // a khatma is active, so the unlock receiver can draw the ayah.
      final idx = progress.value?.currentGlobalAyah ??
          khatma.value?.currentGlobalAyah ??
          0;
      if (idx <= 0 || khatma.value == null) {
        await svc.cacheOverlayAyah(enabled: false);
        return;
      }
      final cur = await _ayahBundle(idx);
      if (cur == null) {
        await svc.cacheOverlayAyah(enabled: false);
        return;
      }
      await svc.cacheOverlayAyah(
        enabled: true,
        title: cur['title'] as String,
        body: cur['body'] as String,
        meta: cur['meta'] as String,
        tafsir: cur['tafsir'] as String? ?? '',
        audioUrl: cur['audioUrl'] as String? ?? '',
        globalAyah: idx,
        surah: cur['surah'] as int,
        ayah: cur['ayah'] as int,
        prev: await _ayahBundle(idx - 1),
        next: await _ayahBundle(idx + 1),
      );
    } catch (_) {
      // best effort only
    }
  }

  /// Reconciles a ✓ tap that was persisted natively while the engine was dead
  /// or frozen, then refreshes the unlock cache. Safe to call on every resume
  /// and startup: it advances at most once, forward-only.
  Future<void> reconcilePendingCompletion() async {
    try {
      final svc = Get.find<PhoneExperienceService>();
      final pending = await svc.consumePendingCompletion();
      if (pending > 0 && khatma.value != null) {
        final cur = progress.value?.currentGlobalAyah ??
            khatma.value?.currentGlobalAyah ??
            0;
        if (cur > 0 && pending == cur) {
          await completeCurrent(source: 'overlay-pending');
          return;
        }
        if (cur > 0 && pending > cur) {
          await completeDisplayed(pending, source: 'overlay-pending');
          return;
        }
      }
      await syncOverlayCache();
    } catch (_) {
      // best effort only
    }
  }

  /// Dismisses any currently shown overlay.
  Future<void> dismissOverlay() async =>
      Get.find<PhoneExperienceService>().dismissAyahOverlay();

  /// Full reset: dismisses the overlay, wipes every khatma + reading event +
  /// saved position, then reloads (khatma/progress become null).
  /// Khatma *settings* (reciter, edition, display flags) are kept.
  Future<void> resetAllProgress() async {
    try {
      final svc = Get.find<PhoneExperienceService>();
      try {
        await svc.dismissAyahOverlay();
      } catch (_) {}
      try {
        await svc.cacheOverlayAyah(enabled: false);
      } catch (_) {}
    } catch (_) {}
    await _khatmaService.clearAll();
    await _readingService.clearAll();
    await refresh();
    await syncOverlayCache();
  }
}

/// Public-friendly slice used to render tajweed-colored ayah without leaking
/// the internal [Skeleton]-style types.
class KemSlicePublic {
  const KemSlicePublic({
    required this.start,
    required this.end,
    required this.cls,
  });
  final int start;
  final int end;
  final String cls;
}
