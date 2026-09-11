/// Canonical metadata about the Quran dataset bundled with this app.
///
/// This module encodes the *counting convention* used by the bundled mushaf
/// (Kemenag / Madani Hafs, total 6236 ayahs across 114 surahs). It exists to:
///   * build a stable **global ayah index** (0..6235 or 1..6236) that the
///     khatma/reading engine uses as the single source of truth for position,
///   * map any (surah, ayah) to a global index and back,
///   * expose juz / hizb / rub grouping helpers when authoritative numbers are
///     known, and
///   * keep *narration/edition* a first-class configuration value.
///
/// IMPORTANT — Quran data integrity:
///   * The ayah counts below MUST match `assets/data/kemenag/list.json`
///     (HAFS / Kufan convention). They are validated by `QuranIntegrityTest`.
///   * We never generate, normalize, or auto-correct the Arabic text.
///   * Only Hafs data is bundled today; Warsh is modelled as an edition but
///     requires its own licensed data package (never fabricated).
library;

/// Counting convention identifiers.
enum QuranCounting {
  /// Hafs / Kufan counting — the bundled dataset (6236 ayahs).
  hafs,
  /// Warsh / Madani (based on the verse numbering common in North/West Africa).
  warsh,
}

/// Narration/edition descriptor. Kept as plain config so every data layer
/// (text, diacritics, orthography, audio, pagination, tajweed) can key off it.
class QuranEdition {
  const QuranEdition({
    required this.id,
    required this.label,
    required this.labelAr,
    required this.counting,
    required this.totalAyahs,
    required this.isBundled,
  });

  final String id;
  final String label;
  final String labelAr;
  final QuranCounting counting;
  final int totalAyahs;

  /// Whether the data for this edition ships with the app bundle.
  final bool isBundled;

  static const hafs = QuranEdition(
    id: 'hafs',
    label: 'Hafs',
    labelAr: 'حفص عن عاصم',
    counting: QuranCounting.hafs,
    totalAyahs: 6236,
    isBundled: true,
  );

  static const warsh = QuranEdition(
    id: 'warsh',
    label: 'Warsh',
    labelAr: 'ورش عن نافع',
    counting: QuranCounting.warsh,
    totalAyahs: 6236,
    // Bundled data is Hafs-only. Warsh requires a separate licensed package.
    isBundled: false,
  );

  static const all = [hafs, warsh];

  static QuranEdition? byId(String? id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// The canonical per-surah metadata in Mushaf (Hafs) order.
/// [totalAyahs] values match `assets/data/kemenag/list.json` `count_ayat`.
///
/// sourceCount = index of the ayah where the surah's *sajdah* (prostration)
/// markers begin the next line — not used here; kept minimal.
class SurahMeta {
  const SurahMeta({
    required this.number,
    required this.ayahCount,
    required this.name,
    required this.nameAr,
  });

  final int number;
  final int ayahCount;
  final String name;
  final String nameAr;
}

/// The 114 surahs in canonical order with their Hafs ayah counts and names.
/// Names mirror `list.json` (`surat_name` and the Arabic name). The counts are
/// authoritative for the global index.
const List<SurahMeta> kSurahs = [
  SurahMeta(number: 1, ayahCount: 7, name: 'Al-Fatihah', nameAr: 'الفَاتِحَة'),
  SurahMeta(number: 2, ayahCount: 286, name: 'Al-Baqarah', nameAr: 'البَقَرَة'),
  SurahMeta(
      number: 3, ayahCount: 200, name: "Ali 'Imran", nameAr: 'آل عِمْرَان'),
  SurahMeta(number: 4, ayahCount: 176, name: "An-Nisa'", nameAr: 'النِّسَاء'),
  SurahMeta(number: 5, ayahCount: 120, name: "Al-Ma'idah", nameAr: 'المَائِدَة'),
  SurahMeta(number: 6, ayahCount: 165, name: "Al-An'am", nameAr: 'الأَنْعَام'),
  SurahMeta(number: 7, ayahCount: 206, name: "Al-A'raf", nameAr: 'الأَعْرَاف'),
  SurahMeta(
      number: 8, ayahCount: 75, name: 'Al-Anfal', nameAr: 'الأَنْفَال'),
  SurahMeta(number: 9, ayahCount: 129, name: 'At-Tawbah', nameAr: 'التَّوْبَة'),
  SurahMeta(
      number: 10, ayahCount: 109, name: 'Yunus', nameAr: 'يُونُس'),
  SurahMeta(
      number: 11, ayahCount: 123, name: 'Hud', nameAr: 'هُود'),
  SurahMeta(
      number: 12, ayahCount: 111, name: 'Yusuf', nameAr: 'يُوسُف'),
  SurahMeta(
      number: 13, ayahCount: 43, name: "Ar-Ra'd", nameAr: 'الرَّعْد'),
  SurahMeta(
      number: 14, ayahCount: 52, name: 'Ibrahim', nameAr: 'إِبْرَاهِيم'),
  SurahMeta(
      number: 15, ayahCount: 99, name: 'Al-Hijr', nameAr: 'الحِجْر'),
  SurahMeta(
      number: 16, ayahCount: 128, name: 'An-Nahl', nameAr: 'النَّحْل'),
  SurahMeta(
      number: 17, ayahCount: 111, name: "Al-Isra'", nameAr: 'الإِسْرَاء'),
  SurahMeta(
      number: 18, ayahCount: 110, name: 'Al-Kahf', nameAr: 'الكَهْف'),
  SurahMeta(
      number: 19, ayahCount: 98, name: 'Maryam', nameAr: 'مَرْيَم'),
  SurahMeta(
      number: 20, ayahCount: 135, name: 'Ta-Ha', nameAr: 'طٰهٰ'),
  SurahMeta(
      number: 21, ayahCount: 112, name: "Al-Anbiya'", nameAr: 'الأَنْبِيَاء'),
  SurahMeta(
      number: 22, ayahCount: 78, name: 'Al-Hajj', nameAr: 'الحَجّ'),
  SurahMeta(
      number: 23, ayahCount: 118, name: "Al-Mu'minun", nameAr: 'المُؤْمِنُون'),
  SurahMeta(
      number: 24, ayahCount: 64, name: 'An-Nur', nameAr: 'النُّور'),
  SurahMeta(
      number: 25, ayahCount: 77, name: 'Al-Furqan', nameAr: 'الفُرْقَان'),
  SurahMeta(
      number: 26, ayahCount: 227, name: "Ash-Shu'ara'", nameAr: 'الشُّعَرَاء'),
  SurahMeta(
      number: 27, ayahCount: 93, name: 'An-Naml', nameAr: 'النَّمْل'),
  SurahMeta(
      number: 28, ayahCount: 88, name: 'Al-Qasas', nameAr: 'القَصَص'),
  SurahMeta(
      number: 29, ayahCount: 69, name: 'Al-Ankabut', nameAr: 'العَنْكَبُوت'),
  SurahMeta(
      number: 30, ayahCount: 60, name: 'Ar-Rum', nameAr: 'الرُّوم'),
  SurahMeta(
      number: 31, ayahCount: 34, name: 'Luqman', nameAr: 'لُقْمَان'),
  SurahMeta(
      number: 32, ayahCount: 30, name: 'As-Sajdah', nameAr: 'السَّجْدَة'),
  SurahMeta(
      number: 33, ayahCount: 73, name: "Al-Ahzab", nameAr: 'الأَحْزَاب'),
  SurahMeta(
      number: 34, ayahCount: 54, name: "Saba'", nameAr: 'سَبَأ'),
  SurahMeta(
      number: 35, ayahCount: 45, name: 'Fatir', nameAr: 'فَاطِر'),
  SurahMeta(
      number: 36, ayahCount: 83, name: 'Ya-Sin', nameAr: 'يس'),
  SurahMeta(
      number: 37, ayahCount: 182, name: 'As-Saffat', nameAr: 'الصَّافَّات'),
  SurahMeta(
      number: 38, ayahCount: 88, name: 'Sad', nameAr: 'ص'),
  SurahMeta(
      number: 39, ayahCount: 75, name: 'Az-Zumar', nameAr: 'الزُّمَر'),
  SurahMeta(
      number: 40, ayahCount: 85, name: 'Ghafir', nameAr: 'غَافِر'),
  SurahMeta(
      number: 41, ayahCount: 54, name: 'Fussilat', nameAr: 'فُصِّلَت'),
  SurahMeta(
      number: 42, ayahCount: 53, name: 'Ash-Shura', nameAr: 'الشُّورَى'),
  SurahMeta(
      number: 43, ayahCount: 89, name: 'Az-Zukhruf', nameAr: 'الزُّخْرُف'),
  SurahMeta(
      number: 44, ayahCount: 59, name: 'Ad-Dukhan', nameAr: 'الدُّخَان'),
  SurahMeta(
      number: 45, ayahCount: 37, name: 'Al-Jathiyah', nameAr: 'الجَاثِيَة'),
  SurahMeta(
      number: 46, ayahCount: 35, name: "Al-Ahqaf", nameAr: 'الأَحْقَاف'),
  SurahMeta(
      number: 47, ayahCount: 38, name: 'Muhammad', nameAr: 'مُحَمَّد'),
  SurahMeta(
      number: 48, ayahCount: 29, name: 'Al-Fath', nameAr: 'الفَتْح'),
  SurahMeta(
      number: 49, ayahCount: 18, name: 'Al-Hujurat', nameAr: 'الحُجُرَات'),
  SurahMeta(
      number: 50, ayahCount: 45, name: 'Qaf', nameAr: 'ق'),
  SurahMeta(
      number: 51, ayahCount: 60, name: 'Adh-Dhariyat', nameAr: 'الذَّارِيَات'),
  SurahMeta(
      number: 52, ayahCount: 49, name: 'At-Tur', nameAr: 'الطُّور'),
  SurahMeta(
      number: 53, ayahCount: 62, name: 'An-Najm', nameAr: 'النَّجْم'),
  SurahMeta(
      number: 54, ayahCount: 55, name: 'Al-Qamar', nameAr: 'القَمَر'),
  SurahMeta(
      number: 55, ayahCount: 78, name: 'Ar-Rahman', nameAr: 'الرَّحْمَن'),
  SurahMeta(
      number: 56, ayahCount: 96, name: "Al-Waqi'ah", nameAr: 'الوَاقِعَة'),
  SurahMeta(
      number: 57, ayahCount: 29, name: 'Al-Hadid', nameAr: 'الحَدِيد'),
  SurahMeta(
      number: 58, ayahCount: 22, name: 'Al-Mujadila', nameAr: 'المُجَادَلَة'),
  SurahMeta(
      number: 59, ayahCount: 24, name: 'Al-Hashr', nameAr: 'الحَشْر'),
  SurahMeta(
      number: 60, ayahCount: 13, name: 'Al-Mumtahanah', nameAr: 'المُمْتَحَنَة'),
  SurahMeta(
      number: 61, ayahCount: 14, name: 'As-Saff', nameAr: 'الصَّفّ'),
  SurahMeta(
      number: 62, ayahCount: 11, name: "Al-Jumu'ah", nameAr: 'الجُمُعَة'),
  SurahMeta(
      number: 63, ayahCount: 11, name: 'Al-Munafiqun', nameAr: 'المُنَافِقُون'),
  SurahMeta(
      number: 64, ayahCount: 18, name: 'At-Taghabun', nameAr: 'التَّغَابُن'),
  SurahMeta(
      number: 65, ayahCount: 12, name: 'At-Talaq', nameAr: 'الطَّلَاق'),
  SurahMeta(
      number: 66, ayahCount: 12, name: 'At-Tahrim', nameAr: 'التَّحْرِيم'),
  SurahMeta(
      number: 67, ayahCount: 30, name: 'Al-Mulk', nameAr: 'المُلْك'),
  SurahMeta(
      number: 68, ayahCount: 52, name: 'Al-Qalam', nameAr: 'القَلَم'),
  SurahMeta(
      number: 69, ayahCount: 52, name: 'Al-Haqqah', nameAr: 'الحَاقَّة'),
  SurahMeta(
      number: 70, ayahCount: 44, name: "Al-Ma'arij", nameAr: 'المَعَارِج'),
  SurahMeta(
      number: 71, ayahCount: 28, name: 'Nuh', nameAr: 'نُوح'),
  SurahMeta(
      number: 72, ayahCount: 28, name: 'Al-Jinn', nameAr: 'الجِنّ'),
  SurahMeta(
      number: 73, ayahCount: 20, name: 'Al-Muzzammil', nameAr: 'المُزَّمِّل'),
  SurahMeta(
      number: 74, ayahCount: 56, name: "Al-Muddaththir", nameAr: 'المُدَّثِّر'),
  SurahMeta(
      number: 75, ayahCount: 40, name: 'Al-Qiyamah', nameAr: 'القِيَامَة'),
  SurahMeta(
      number: 76, ayahCount: 31, name: 'Al-Insan', nameAr: 'الإِنْسَان'),
  SurahMeta(
      number: 77, ayahCount: 50, name: "Al-Mursalat", nameAr: 'المُرْسَلَات'),
  SurahMeta(
      number: 78, ayahCount: 40, name: "An-Naba'", nameAr: 'النَّبَأ'),
  SurahMeta(
      number: 79, ayahCount: 46, name: "An-Nazi'at", nameAr: 'النَّازِعَات'),
  SurahMeta(
      number: 80, ayahCount: 42, name: "'Abasa", nameAr: 'عَبَسَ'),
  SurahMeta(
      number: 81, ayahCount: 29, name: 'At-Takwir', nameAr: 'التَّكْوِير'),
  SurahMeta(
      number: 82, ayahCount: 19, name: 'Al-Infitar', nameAr: 'الاِنْفِطَار'),
  SurahMeta(
      number: 83, ayahCount: 36, name: 'Al-Mutaffifin', nameAr: 'المُطَفِّفِين'),
  SurahMeta(
      number: 84, ayahCount: 25, name: 'Al-Inshiqaq', nameAr: 'الاِنْشِقَاق'),
  SurahMeta(
      number: 85, ayahCount: 22, name: 'Al-Buruj', nameAr: 'البُرُوج'),
  SurahMeta(
      number: 86, ayahCount: 17, name: 'At-Tariq', nameAr: 'الطَّارِق'),
  SurahMeta(
      number: 87, ayahCount: 19, name: "Al-A'la", nameAr: 'الأَعْلَى'),
  SurahMeta(
      number: 88, ayahCount: 26, name: 'Al-Ghashiyah', nameAr: 'الغَاشِيَة'),
  SurahMeta(
      number: 89, ayahCount: 30, name: 'Al-Fajr', nameAr: 'الفَجْر'),
  SurahMeta(
      number: 90, ayahCount: 20, name: 'Al-Balad', nameAr: 'البَلَد'),
  SurahMeta(
      number: 91, ayahCount: 15, name: 'Ash-Shams', nameAr: 'الشَّمْس'),
  SurahMeta(
      number: 92, ayahCount: 21, name: 'Al-Layl', nameAr: 'اللَّيْل'),
  SurahMeta(
      number: 93, ayahCount: 11, name: 'Ad-Duha', nameAr: 'الضُّحَى'),
  SurahMeta(
      number: 94, ayahCount: 8, name: 'Ash-Sharh', nameAr: 'الشَّرْح'),
  SurahMeta(
      number: 95, ayahCount: 8, name: 'At-Tin', nameAr: 'التِّين'),
  SurahMeta(
      number: 96, ayahCount: 19, name: "Al-'Alaq", nameAr: 'العَلَق'),
  SurahMeta(
      number: 97, ayahCount: 5, name: 'Al-Qadr', nameAr: 'القَدْر'),
  SurahMeta(
      number: 98, ayahCount: 8, name: 'Al-Bayyinah', nameAr: 'البَيِّنَة'),
  SurahMeta(
      number: 99, ayahCount: 8, name: 'Az-Zalzalah', nameAr: 'الزَّلْزَلَة'),
  SurahMeta(
      number: 100, ayahCount: 11, name: "Al-'Adiyat", nameAr: 'العَادِيَات'),
  SurahMeta(
      number: 101, ayahCount: 11, name: "Al-Qari'ah", nameAr: 'القَارِعَة'),
  SurahMeta(
      number: 102, ayahCount: 8, name: 'At-Takathur', nameAr: 'التَّكَاثُر'),
  SurahMeta(
      number: 103, ayahCount: 3, name: "Al-'Asr", nameAr: 'العَصْر'),
  SurahMeta(
      number: 104, ayahCount: 9, name: 'Al-Humazah', nameAr: 'الهُمَزَة'),
  SurahMeta(
      number: 105, ayahCount: 5, name: 'Al-Fil', nameAr: 'الفِيل'),
  SurahMeta(
      number: 106, ayahCount: 4, name: 'Quraysh', nameAr: 'قُرَيْش'),
  SurahMeta(
      number: 107, ayahCount: 7, name: "Al-Ma'un", nameAr: 'المَاعُون'),
  SurahMeta(
      number: 108, ayahCount: 3, name: 'Al-Kawthar', nameAr: 'الكَوْثَر'),
  SurahMeta(
      number: 109, ayahCount: 6, name: 'Al-Kafirun', nameAr: 'الكَافِرُون'),
  SurahMeta(
      number: 110, ayahCount: 3, name: 'An-Nasr', nameAr: 'النَّصْر'),
  SurahMeta(
      number: 111, ayahCount: 5, name: 'Al-Masad', nameAr: 'المَسَد'),
  SurahMeta(
      number: 112, ayahCount: 4, name: 'Al-Ikhlas', nameAr: 'الإِخْلَاص'),
  SurahMeta(
      number: 113, ayahCount: 5, name: 'Al-Falaq', nameAr: 'الفَلَق'),
  SurahMeta(
      number: 114, ayahCount: 6, name: 'An-Nas', nameAr: 'النَّاس'),
];

const int kTotalAyahs = 6236;

/// A concrete ayah location, always resolved against an edition.
class AyahRef {
  const AyahRef({required this.surah, required this.ayah, this.edition});

  final int surah; // 1..114
  final int ayah; // 1..surah.ayahCount
  final String? edition;

  String get key => '$edition:$surah:$ayah';

  @override
  String toString() => 'AyahRef($surah:$ayah)';

  @override
  bool operator ==(Object other) =>
      other is AyahRef &&
      other.surah == surah &&
      other.ayah == ayah &&
      other.edition == edition;

  @override
  int get hashCode => Object.hash(surah, ayah, edition);
}

/// Pure, dependency-free index over the bundled Hafs dataset.
/// Maps between global ayah index (1..kTotalAyahs) and (surah, ayah).
class QuranIndex {
  QuranIndex._(this._start, this._surahs);

  final List<int> _start; // surahNumber -> 1-based global index of its ayah 1
  final List<SurahMeta> _surahs;

  static final QuranIndex instance = QuranIndex._build();

  static QuranIndex _build() {
    final start = List<int>.filled(kSurahs.length + 1, 1);
    var total = 1;
    for (var i = 0; i < kSurahs.length; i++) {
      start[i + 1] = total;
      total += kSurahs[i].ayahCount;
    }
    // sanity: matches kTotalAyahs
    assert(total - 1 == kTotalAyahs);
    return QuranIndex._(start, kSurahs);
  }

  /// 1-based global index of ayah 1 of [surah].
  int startOfSurah(int surah) =>
      (surah >= 1 && surah <= kSurahs.length) ? _start[surah] : 1;

  /// Number of total ayahs in the dataset.
  int get totalAyahs => kTotalAyahs;

  /// Number of surahs (114).
  int get surahCount => kSurahs.length;

  SurahMeta? surahMeta(int surah) =>
      (surah >= 1 && surah <= kSurahs.length) ? _surahs[surah - 1] : null;

  /// 1-based global index for a (surah, ayah). Returns null if out of range.
  int? globalIndex(int surah, int ayah) {
    final meta = surahMeta(surah);
    if (meta == null) return null;
    if (ayah < 1 || ayah > meta.ayahCount) return null;
    return _start[surah] + (ayah - 1);
  }

  /// (surah, ayah) for a 1-based global index. Returns null if out of range.
  ({int surah, int ayah})? locationOf(int globalIndex) {
    if (globalIndex < 1 || globalIndex > kTotalAyahs) return null;
    // binary search for the owning surah
    int lo = 1, hi = kSurahs.length, ans = 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_start[mid] <= globalIndex) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    final ayah = globalIndex - _start[ans] + 1;
    return (surah: ans, ayah: ayah);
  }

  /// Total ayahs from [globalStart] through [globalEnd] inclusive.
  int countBetween(int globalStart, int globalEnd) =>
      (globalEnd - globalStart + 1).clamp(0, kTotalAyahs);
}
