/// Audio reciter configuration.
///
/// Reciters are **data-driven**, never hard-coded into widgets. The primary
/// source is the free alquran.cloud API (see `ReciterApiService`); the
/// hard-coded [ReciterCatalog.defaults] only serve as the offline fallback.
/// A reciter points at an audio source built from [audioUrlBuilder] (e.g. a
/// licensed or public Quran audio provider). No copyrighted audio is bundled
/// or redistributed by this app — URLs are configuration.
library;

import '../../../../core/logic/quran_index.dart';

enum ReciterAvailability {
  available,
  /// Requires an external/online source (default).
  online,
  /// Marked as not currently served by a configured source.
  unavailable,
}

class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.localizedName,
    required this.edition,
    this.language = 'ar',
    this.audioUrlBuilder,
    this.availability = ReciterAvailability.online,
    this.imageAsset,
    this.apiIdentifier,
  });

  final String id;
  final String name;
  final String localizedName;

  /// QuranEdition.id this reciter reads (hafs/warsh).
  final String edition;

  final String language;

  /// alquran.cloud audio edition identifier (e.g. `ar.alafasy`) when this
  /// reciter comes from the API. Null for bundled everyayah reciters.
  /// The exact per-ayah stream (bitrate included) is resolved through
  /// [ReciterApiService.audioCandidates], because not every edition is
  /// served at every bitrate.
  final String? apiIdentifier;

  /// Given a surah & ayah, returns the stream URL (or null if unavailable).
  /// e.g. many providers expose `/{surah}/{ayah}.mp3`.
  final String? Function(int surah, int ayah)? audioUrlBuilder;

  final ReciterAvailability availability;
  final String? imageAsset;

  bool get isAvailable => availability != ReciterAvailability.unavailable && audioUrlBuilder != null;

  /// Language-aware display: Arabic UI shows the Arabic name, other
  /// languages show the English name.
  String titleFor(String lang) => lang == 'ar' ? localizedName : name;

  /// Secondary line for the picker, or null when there is nothing useful
  /// to add (same as title, or Latin text in Arabic mode).
  String? subtitleFor(String lang) {
    if (lang == 'ar') return null;
    if (localizedName.isEmpty || localizedName == name) return null;
    return localizedName;
  }

  String? buildUrl(int surah, int ayah) => isAvailable ? audioUrlBuilder!(surah, ayah) : null;

  /// Ordered stream candidates for (surah, ayah): the primary URL first,
  /// then mirror origins. Players should try them in order so a single
  /// flaky host (4xx/5xx) never silences audio. Empty when unavailable.
  List<String> buildUrls(int surah, int ayah) {
    final primary = buildUrl(surah, ayah);
    if (primary == null) return const [];
    final out = <String>[primary];
    final mirror = _mirrorUrl(primary);
    if (mirror != null) out.add(mirror);
    return out;
  }

  /// Mirror equivalent of a primary everyayah URL, or null when the URL
  /// has no known mirror (e.g. API/global-number URLs).
  static String? _mirrorUrl(String primary) {
    if (primary.startsWith(ReciterCatalog.everyAyahBase)) {
      return ReciterCatalog.everyAyahMirrorBase +
          primary.substring(ReciterCatalog.everyAyahBase.length);
    }
    return null;
  }

  /// Builds a reciter served by the alquran.cloud / Islamic Network CDN.
  ///
  /// [identifier] is the API edition identifier (e.g. `ar.alafasy`). Audio
  /// is addressed by **global** ayah number (1..6236), converted from
  /// (surah, ayah) via [QuranIndex]; out-of-range pairs yield null.
  factory Reciter.fromApi({
    required String identifier,
    required String englishName,
    String? arabicName,
  }) {
    String? builder(int surah, int ayah) {
      final global = QuranIndex.instance.globalIndex(surah, ayah);
      if (global == null) return null;
      return 'https://cdn.islamic.network/quran/audio/128/$identifier/$global.mp3';
    }

    return Reciter(
      id: identifier,
      name: englishName,
      localizedName: (arabicName?.isNotEmpty ?? false) ? arabicName! : englishName,
      edition: 'hafs',
      audioUrlBuilder: builder,
      apiIdentifier: identifier,
    );
  }
}

/// The set of reciters exposed by default. Even when an online provider is
/// used, each entry stays configurable via [Reciter.audioUrlBuilder].
///
/// Many providers (e.g. the widely used "everyayah" segment server) expose
/// stable per-ayah URLs; the base host is centralized below so a single
/// configuration can switch providers without touching the UI.
class ReciterCatalog {
  static const String everyAyahBase = 'https://everyayah.com/data/';

  /// Independent mirror of the same everyayah folder layout
  /// (`{folder}/{surah:03d}{ayah:03d}.mp3`), served from QuranicAudio's
  /// infrastructure. Used as automatic fallback when the primary host
  /// answers 4xx/5xx.
  static const String everyAyahMirrorBase =
      'https://mirrors.quranicaudio.com/everyayah/';

  static final List<Reciter> defaults = _everyAyah().toList();
  /// Reciters served through a well-known, permission-friendly per-ayah CDN.
  /// NOTE: verify each path's licence before shipping; swap the base host for
  /// your own licensed source as needed.
  static Iterable<Reciter> _everyAyah() sync* {
    String Function(int, int) builder(String id) {
      // Standard provider layout: /{identifier}/{surah:03d}{ayah:03d}.mp3
      // e.g. Al-Fatiha 1 => 001001.mp3. Both parts MUST be zero-padded to
      // 3 digits, otherwise the CDN answers 404 (MediaPlayer error 1,-1005).
      return (int s, int a) =>
          '$everyAyahBase$id/${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';
    }

    final defs = <({String id, String name, String ar, String edition})>[
      (id: 'Alafasy_128kbps', name: 'Mishary Rashid Al-Afasy', ar: 'مشاري راشد العفاسي', edition: 'hafs'),
      (id: 'Husary_128kbps', name: 'Mahmoud Khalil Al-Husary', ar: 'محمود خليل الحصري', edition: 'hafs'),
      (id: 'Ghamadi_40kbps', name: 'Saad Al-Ghamdi', ar: 'سعد الغامدي', edition: 'hafs'),
      (id: 'MaherAlMuaiqly128kbps', name: 'Maher Al-Muaiqly', ar: 'ماهر المعيقلي', edition: 'hafs'),
      (id: 'Mustafa_Ismail_48kbps', name: 'Mustafa Ismail', ar: 'مصطفى إسماعيل', edition: 'hafs'),
      (id: 'Minshawy_Murattal_128kbps', name: 'Muhammad Siddiq Al-Minshawi', ar: 'محمد صديق المنشاوي', edition: 'hafs'),
      (id: 'Hudhaify_128kbps', name: 'Ali Al-Hudhaifi', ar: 'علي الحذيفي', edition: 'hafs'),
      (id: 'Abdul_Basit_Murattal_64kbps', name: 'Abdul Basit Abdul Samad', ar: 'عبد الباسط عبد الصمد', edition: 'hafs'),
      // Warsh narration (for users reading Warsh): same SSSAAA layout
      // under the warsh/ subfolder.
      (id: 'warsh/warsh_yassin_al_jazaery_64kbps', name: 'Yassin Al-Jazaery', ar: 'ياسين الجزائري', edition: 'warsh'),
    ];

    for (final d in defs) {
      yield Reciter(
        id: d.id,
        name: d.name,
        localizedName: d.ar,
        edition: d.edition,
        audioUrlBuilder: builder(d.id),
      );
    }
  }

  /// Bundled reciters with no per-ayah equivalent in the API list, always
  /// appended after it so they stay selectable online. Dedupes by Arabic
  /// name so a future API addition never shows twice.
  static List<Reciter> supplementalFor(List<Reciter> api) {
    const ids = {'Ghamadi_40kbps', 'warsh/warsh_yassin_al_jazaery_64kbps'};
    final have = api.map((r) => r.localizedName.trim()).toSet();
    return defaults.where((d) {
      if (!ids.contains(d.id)) return false;
      if (api.any((r) => r.id == d.id)) return false;
      return !have.contains(d.localizedName.trim());
    }).toList();
  }

  static Reciter? byId(String? id) {
    final mapped = _legacyIds[id] ?? id;
    for (final r in defaults) {
      if (r.id == mapped) return r;
    }
    return null;
  }

  /// Old folder IDs shipped in earlier versions that do not exist on the
  /// provider (every request 404s). Mapped to the verified equivalent so
  /// stored settings keep resolving after the fix.
  static const Map<String, String> _legacyIds = {
    'Saad_Al-Ghamdi_128kbps': 'Ghamadi_40kbps',
    'Mustafa_Ismail_128kbps': 'Mustafa_Ismail_48kbps',
    'Minshawi_128kbps': 'Minshawy_Murattal_128kbps',
    'Ali_Hudhaifi_128kbps': 'Hudhaify_128kbps',
    'Abdul_Basit_Murattal_128kbps': 'Abdul_Basit_Murattal_64kbps',
  };

  /// Well-known Arabic display names for alquran.cloud edition identifiers.
  /// Identifiers missing here fall back to the API's `englishName`.
  static const Map<String, String> apiArabicNames = {
    'ar.alafasy': 'مشاري راشد العفاسي',
    'ar.husary': 'محمود خليل الحصري',
    'ar.husarymujawwad': 'محمود خليل الحصري (مجوّد)',
    'ar.minshawi': 'محمد صديق المنشاوي',
    'ar.minshawimujawwad': 'محمد صديق المنشاوي (مجوّد)',
    'ar.muhammadayyoub': 'محمد أيوب',
    'ar.muhammadjibreel': 'محمد جبريل',
    'ar.aymanswoyd': 'أيمن سويد',
    'ar.mahermuaiqly': 'ماهر المعيقلي',
    'ar.abdullahawadaljuhany': 'عبد الله عواد الجهني',
    'ar.abdulbasitmurattal': 'عبد الباسط عبد الصمد (مرتل)',
    'ar.abdulsamad': 'عبد الباسط عبد الصمد',
  };

  /// Parses the alquran.cloud `/edition?format=audio` `data` list into
  /// [Reciter]s. Malformed entries are skipped; `surahbysurah` editions are
  /// skipped too (per-surah files only — per-ayah URLs would 404). An empty
  /// result means the caller should fall back to [defaults].
  ///
  /// The API's own `name` field is Arabic and is used as the display name;
  /// [apiArabicNames] only fills gaps when it is missing.
  static List<Reciter> fromApiEditions(List<dynamic> data) {
    final out = <Reciter>[];
    final seen = <String>{};
    for (final e in data) {
      if (e is! Map) continue;
      final identifier = e['identifier']?.toString() ?? '';
      if (identifier.isEmpty || !seen.add(identifier)) continue;
      if (e['type']?.toString() == 'surahbysurah') continue;
      final englishName = e['englishName']?.toString().trim() ?? '';
      if (englishName.isEmpty) continue;
      final apiName = e['name']?.toString().trim() ?? '';
      out.add(
        Reciter.fromApi(
          identifier: identifier,
          englishName: englishName,
          arabicName: apiName.isNotEmpty
              ? apiName
              : apiArabicNames[identifier],
        ),
      );
    }
    return out;
  }

  /// Resolves [id] against an API-fetched list first, then [defaults].
  static Reciter? byIdIn(List<Reciter> reciters, String? id) {
    for (final r in reciters) {
      if (r.id == id) return r;
    }
    return byId(id);
  }
}
