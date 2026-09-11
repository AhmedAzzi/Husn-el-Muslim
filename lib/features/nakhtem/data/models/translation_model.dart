/// Translations (non-Arabic) kept strictly separate from the canonical Quran
/// Arabic text. The Quran text is never mixed with translation strings.
library;

/// A translatable "language" descriptor for the app UI.
enum AppLanguage {
  ar('ar', 'العربية', 'Arabic'),
  en('en', 'English', 'English'),
  fr('fr', 'Français', 'French');

  const AppLanguage(this.code, this.label, this.englishName);
  final String code;
  final String label;
  final String englishName;

  static AppLanguage byCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return AppLanguage.ar;
  }
}

/// A translation of an ayah into a non-Arabic language.
class AyahTranslation {
  const AyahTranslation({
    required this.id,
    required this.language,
    required this.translator,
    required this.surah,
    required this.ayah,
    required this.text,
  });

  final String id;
  final String language;
  final String translator;
  final int surah;
  final int ayah;
  final String text;
}

/// Available translation sources. Bundled content is optional; the repository
/// exposes whatever translations are legally/technically available offline.
class TranslationSource {
  const TranslationSource({
    required this.id,
    required this.language,
    required this.translator,
    required this.name,
    this.isBundled = false,
  });

  final String id;
  final String language;
  final String translator;
  final String name;
  final bool isBundled;

  static const List<TranslationSource> available = [
    TranslationSource(
      id: 'en-sahih',
      language: 'en',
      translator: 'Saheeh International',
      name: 'English — Saheeh International',
      isBundled: false,
    ),
    TranslationSource(
      id: 'fr-hamidullah',
      language: 'fr',
      translator: 'Muhammad Hamidullah',
      name: 'Français — Hamidullah',
      isBundled: false,
    ),
    TranslationSource(
      id: 'ar-kemenag',
      language: 'id',
      translator: 'Kemenag RI',
      name: 'Bahasa Indonesia — Kemenag',
      isBundled: true,
    ),
  ];
}
