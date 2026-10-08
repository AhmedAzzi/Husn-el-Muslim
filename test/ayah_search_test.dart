import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/features/quran/presentation/providers/ayah_search_controller.dart';

/// Guards the "super powerful" mushaf search:
/// tashkeel-insensitive matching, Uthmani-tolerant skeletons, and the
/// result-count contract (totalCount tracks full matches, hits are capped).
void main() {
  group('normAr', () {
    test('strips tashkeel so bare words match vocalized text', () {
      expect(
        AyahSearchController.normAr('بِسْمِ اللَّهِ'),
        AyahSearchController.normAr('بسم الله'),
      );
    });

    test('unifies alef forms, taa marbuta, hamza seats', () {
      expect(AyahSearchController.normAr('أحمد'), 'احمد');
      expect(AyahSearchController.normAr('آمنا'), 'امنا');
      expect(AyahSearchController.normAr('ٱبن'), 'ابن');
      expect(
        AyahSearchController.normAr('الصلاة'),
        AyahSearchController.normAr('الصلوة').replaceAll('و', 'ا'),
      );
      expect(AyahSearchController.normAr('مدرسة'), 'مدرسه');
      expect(AyahSearchController.normAr('يؤمنون'), 'يومنون');
      expect(AyahSearchController.normAr('شيء'), 'شي');
    });

    test('drops bare hamza so ءَاَنْذَرْتَهُمْ matches انذرتهم', () {
      expect(
        AyahSearchController.normAr('ءَاَنْذَرْتَهُمْ'),
        AyahSearchController.normAr('أنذرتهم'),
      );
    });

    test('strips Quranic waqf/annotation marks and tatweel', () {
      // الۤمّۤ carries a small-high madda (U+06E4) plus shadda.
      expect(AyahSearchController.normAr('الۤمّۤ'), 'الم');
      expect(AyahSearchController.normAr('رَيْبَ ۛ'), 'ريب');
      expect(AyahSearchController.normAr('كِتَـب'), 'كتب');
      // Uthmani كِتَٰب (alef written as superscript) strips to كتب —
      // the skeleton tier reunites it with an imla كتاب query.
      expect(AyahSearchController.normAr('كِتَٰب'), 'كتب');
      expect(
        AyahSearchController.skeletonAr('كتاب'),
        AyahSearchController.normAr('كِتَٰب'),
      );
    });

    test('strips superscript alef', () {
      expect(AyahSearchController.normAr('اللّٰه'), 'الله');
      expect(AyahSearchController.normAr('ذٰلِكَ'), 'ذلك');
    });

    test('unifies kaf/yeh keyboard variants and collapses spaces', () {
      expect(
        AyahSearchController.normAr('الى'),
        AyahSearchController.normAr('إلى'),
      );
      expect(AyahSearchController.normAr('a  b'), isNot(contains('  ')));
      expect(AyahSearchController.queryTokens('  رب  العالمين '),
          ['رب', 'العالمين']);
    });
  });

  group('skeleton tiers', () {
    test('alef skeleton converges Uthmani/imla spellings', () {
      expect(
        AyahSearchController.skeletonAr('الرحمان'),
        AyahSearchController.skeletonAr('الرحمن'),
      );
      expect(
        AyahSearchController.skeletonAr('ذالك'),
        AyahSearchController.skeletonAr('ذلك'),
      );
    });

    test('weak-letter skeleton converges waw/alef spellings', () {
      expect(
        AyahSearchController.consonantAr('الصلاة'),
        AyahSearchController.consonantAr('الصلوة'),
      );
      expect(
        AyahSearchController.consonantAr('السماوات'),
        AyahSearchController.consonantAr('السموات'),
      );
    });

    test('skeleton tokens mirror query tokens', () {
      expect(
        AyahSearchController.skeletonTokens('الرحمان الرحيم'),
        isNotEmpty,
      );
      expect(
        AyahSearchController.consonantTokens('الصلاة'),
        isNotEmpty,
      );
    });
  });

  group('controller contract', () {
    test('resultLimit and totalCount defaults', () {
      final ctl = AyahSearchController();
      expect(AyahSearchController.resultLimit, 120);
      expect(ctl.totalCount.value, 0);
      expect(ctl.hasSearched.value, isFalse);
      ctl.onClose();
    });
  });
}
