import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:small_husn_muslim/features/book/data/book_models.dart';

class BookService {
  static final BookService _instance = BookService._internal();
  factory BookService() => _instance;
  BookService._internal();

  BookData? _cachedBookData;

  Future<BookData> getBookData() async {
    if (_cachedBookData != null) {
      return _cachedBookData!;
    }
    final String jsonString =
        await rootBundle.loadString('assets/book_structured.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    _cachedBookData = BookData.fromJson(jsonData);
    return _cachedBookData!;
  }

  /// Normalize Arabic text for search by removing tashkeel (diacritics)
  /// and standardizing alef / yaa / taa marbouta letters.
  static String normalizeArabic(String text) {
    if (text.isEmpty) return '';
    var normalized = text;
    // Remove diacritics / tashkeel (fatha, damma, kasra, sukun, shadda, tanween, dagger alif, etc.)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // Normalize Alef variants
    normalized = normalized.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    // Normalize Yaa / Alef Maksura
    normalized = normalized.replaceAll('ى', 'ي');
    // Normalize Taa Marbuta
    normalized = normalized.replaceAll('ة', 'ه');
    return normalized.toLowerCase().trim();
  }

  /// Checks if [source] matches [query] using normalized Arabic comparison
  static bool matchesQuery(String source, String query) {
    if (query.trim().isEmpty) return true;
    final normalizedSource = normalizeArabic(source);
    final normalizedQuery = normalizeArabic(query);
    return normalizedSource.contains(normalizedQuery);
  }
}
