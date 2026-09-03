import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/features/book/data/book_models.dart';
import 'package:small_husn_muslim/features/book/services/book_service.dart';

void main() {
  test('book_structured.json parses correctly into BookData model', () async {
    final file = File('assets/book_structured.json');
    expect(file.existsSync(), isTrue);

    final jsonString = await file.readAsString();
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    final bookData = BookData.fromJson(jsonData);

    expect(bookData.title, isNotEmpty);
    expect(bookData.asmaAllahHusna.length, greaterThan(90));

    // Dua Section
    expect(bookData.duaSection.quranicDuas.length, 48);
    expect(bookData.duaSection.sunnahDuas.length, greaterThan(80));
    expect(bookData.duaSection.virtues.items, isNotEmpty);
    expect(bookData.duaSection.adab.items, isNotEmpty);
    expect(bookData.duaSection.times.items, isNotEmpty);

    // Ruqyah Section
    expect(bookData.ruqyahSection.treatments.length, 19);
    for (var treatment in bookData.ruqyahSection.treatments) {
      expect(treatment.title, isNotEmpty);
      expect(treatment.items, isNotEmpty);
    }
  });

  test('BookService Arabic normalization and query matching works', () {
    expect(BookService.matchesQuery('رَبَّنَا آتِنَا', 'ربنا اتنا'), isTrue);
    expect(BookService.matchesQuery('عِلاَجُ السِّحْرِ', 'السحر'), isTrue);
    expect(BookService.matchesQuery('سُورَةُ الْفَاتِحَةِ', 'الفاتحه'), isTrue);
  });
}
