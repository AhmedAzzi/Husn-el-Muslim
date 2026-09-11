/// Product / app settings for the khatma ("ختمة") experience.
///
/// Only the settings the app actually reads are kept: the mushaf edition
/// (narration) and the selected reciter. Everything else (theme, language,
/// overlay/audio/display toggles, goals) either lives in Husn-el-Muslim's
/// global settings or was never consumed by any code, so it was removed.
///
/// Stored in the local key-value store so it survives restarts.
library;

class NakhtemSettings {
  const NakhtemSettings({
    this.edition = 'hafs',
    this.mushafReciterId = '',
    this.khatmaReciterId = '',
    this.tafsirEnabled = true,
    this.translationEnabled = false,
    this.showDailySummary = true,
  });

  final String edition; // QuranEdition.id

  /// Reciter for mushaf reading audio (independent from khatma).
  final String mushafReciterId;

  /// Reciter for khatma overlay/floating-ayah audio (independent from mushaf).
  final String khatmaReciterId;

  /// Show the tafsir tab in word details and the tafsir section of the
  /// floating ayah overlay.
  final bool tafsirEnabled;

  /// Show the translation tab in word details.
  final bool translationEnabled;

  /// Show the end-of-day reading summary once per day on the khatma home.
  final bool showDailySummary;

  NakhtemSettings copyWith({
    String? edition,
    String? mushafReciterId,
    String? khatmaReciterId,
    bool? tafsirEnabled,
    bool? translationEnabled,
    bool? showDailySummary,
  }) =>
      NakhtemSettings(
        edition: edition ?? this.edition,
        mushafReciterId: mushafReciterId ?? this.mushafReciterId,
        khatmaReciterId: khatmaReciterId ?? this.khatmaReciterId,
        tafsirEnabled: tafsirEnabled ?? this.tafsirEnabled,
        translationEnabled: translationEnabled ?? this.translationEnabled,
        showDailySummary: showDailySummary ?? this.showDailySummary,
      );

  Map<String, String> toKV() => {
        'edition': edition,
        'mushaf_reciter_id': mushafReciterId,
        'khatma_reciter_id': khatmaReciterId,
        'tafsir_enabled': tafsirEnabled.toString(),
        'translation_enabled': translationEnabled.toString(),
        'show_daily_summary': showDailySummary.toString(),
      };

  static NakhtemSettings fromKV(Map<String, String> kv) {
    bool b(String k) => kv[k] == 'true';
    // Migrate the old shared `reciter_id` into both independent slots.
    final legacyReciter = kv['reciter_id'] ?? '';
    return NakhtemSettings(
      edition: kv['edition'] ?? 'hafs',
      mushafReciterId: kv['mushaf_reciter_id'] ?? legacyReciter,
      khatmaReciterId: kv['khatma_reciter_id'] ?? legacyReciter,
      tafsirEnabled:
          kv.containsKey('tafsir_enabled') ? b('tafsir_enabled') : true,
      translationEnabled: b('translation_enabled'),
      showDailySummary:
          kv.containsKey('show_daily_summary') ? b('show_daily_summary') : true,
    );
  }
}
