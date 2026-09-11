import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/platform/phone_experience_service.dart';
import '../../../../core/storage/app_database.dart';
import '../../data/repositories/khatma_repository.dart';
import '../../data/repositories/mp3quran_service.dart';
import '../../data/repositories/verse_timings_service.dart';
import '../../data/repositories/reading_repository.dart';
import '../../data/repositories/reciter_api_service.dart';
import '../../domain/services/khatma_service.dart';
import '../../domain/services/reading_service.dart';
import '../../domain/services/statistics_service.dart';
import 'nakhtem_controller.dart';
import 'nakhtem_settings_controller.dart';
import 'statistics_controller.dart';

/// Registers every Nakhtem-layered dependency with GetX, following the
/// existing `initQuranDependencies` pattern in main.dart.
///
/// [settingsCtl] must be registered before calling [init] so the settings
/// controller can resolve lazily. The [AppDatabase] is passed in explicitly.
void initNakhtemDependencies(
  AppDatabase database,
  NakhtemSettingsController settingsCtl,
) {
  if (!Get.isRegistered<AppDatabase>()) {
    Get.put<AppDatabase>(database, permanent: true);
  }

  final readingRepo = Get.put<ReadingRepository>(
    ReadingRepository(database),
    permanent: true,
  );
  final khatmaRepo = Get.put<KhatmaRepository>(
    KhatmaRepository(database),
    permanent: true,
  );

  if (!Get.isRegistered<KhatmaService>()) {
    Get.put<KhatmaService>(KhatmaService(khatmaRepo), permanent: true);
  }
  if (!Get.isRegistered<ReadingService>()) {
    Get.put<ReadingService>(
      ReadingService(readingRepo: readingRepo, khatmaRepo: khatmaRepo),
      permanent: true,
    );
  }
  final stats = Get.put<StatisticsService>(
    StatisticsService(readingRepo),
    permanent: true,
  );

  Get.put<NakhtemSettingsController>(settingsCtl, permanent: true);

  // Platform + audio services resolve on first use so tests can substitute.
  Get.lazyPut<PhoneExperienceService>(
    () => PhoneExperienceService(),
    fenix: true,
  );
  Get.lazyPut<AudioService>(() => AudioService(), fenix: true);

  Get.lazyPut<NakhtemController>(() => NakhtemController(), fenix: true);
  Get.lazyPut<StatisticsController>(
    () => StatisticsController(stats),
    fenix: true,
  );
}

/// Builds the settings controller persisted in the KV table of [database]
/// (keys namespaced `setting_` to keep them separate from other app data).
NakhtemSettingsController makeNakhtemSettingsController(AppDatabase database) {
  final recitersApi = Get.put<ReciterApiService>(
    ReciterApiService(),
    permanent: true,
  );
  Get.put<Mp3QuranService>(Mp3QuranService(), permanent: true);
  Get.put<VerseTimingsService>(VerseTimingsService(), permanent: true);
  return Get.put<NakhtemSettingsController>(
    NakhtemSettingsController(
      () => _kvLoad(database),
      (kv) => _kvSave(database, kv),
      recitersApi: recitersApi,
    ),
    permanent: true,
  );
}

Future<Map<String, String>> _kvLoad(AppDatabase database) async {
  final raw = await database.getKV('setting:nakhtem');
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    return (decoded as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
  } catch (_) {
    return {};
  }
}

Future<void> _kvSave(AppDatabase database, Map<String, String> kv) async {
  await database.putKV('setting:nakhtem', jsonEncode(kv));
}
