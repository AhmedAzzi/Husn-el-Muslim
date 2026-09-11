/// Word-level meaning entry, joined from `QuranWordInfo` + `word_content_meaning`.
library;

/// `word_meaning.db` tables:
///   QuranWordInfo(surahNo, ayahNo, wordNo, wordWithHaraqah, imlaee,
///     wordWithOutHaraqah, Root, TranslationEn)
///   word_content_meaning(surahNo, ayahNo, wordNo, meaning)
/// Both indexed on (surahNo, ayahNo, wordNo).
class WordMeaning {
  const WordMeaning({
    required this.surah,
    required this.ayah,
    required this.word,
    this.wordWithHaraqah,
    this.imlaee,
    this.plain,
    this.root,
    this.translationEn,
    this.meaning,
  });

  final int surah;
  final int ayah;
  final int word;
  final String? wordWithHaraqah;
  final String? imlaee;
  final String? plain;
  final String? root;
  final String? translationEn;
  final String? meaning;

  /// Display fallback chain: detailed Arabic meaning, else English gloss,
  /// else null when the row carries no gloss (e.g. ayah header w=0).
  String? get display => (meaning?.trim().isNotEmpty ?? false)
      ? meaning
      : (translationEn?.trim().isNotEmpty ?? false)
          ? translationEn
          : null;

  /// Parse a mushaf `location` string of the form `s:a[:w]`.
  /// Returns null when the location has no word part (ayah marker).
  static ({int s, int a, int w})? parseLocation(String location) {
    final parts = location.split(':');
    if (parts.length < 3) return null;
    final s = int.tryParse(parts[0]);
    final a = int.tryParse(parts[1]);
    final w = int.tryParse(parts[2]);
    if (s == null || a == null || w == null || w <= 0) return null;
    return (s: s, a: a, w: w);
  }
}
