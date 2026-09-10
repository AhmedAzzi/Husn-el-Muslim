import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Guards the ARB plural layer: every `{var}` must render the number
/// (regression test for the literal-`#` bug — gen-l10n emits `pluralLogic`,
/// which never substitutes `#`).
void main() {
  AppLocalizations loc(String code) =>
      lookupAppLocalizations(Locale(code));

  group('arabic plurals interpolate the count', () {
    final ar = loc('ar');

    test('trackDays', () {
      expect(ar.trackDays(0), '0 أيام');
      expect(ar.trackDays(1), '1 يوم');
      expect(ar.trackDays(2), '2 يومان');
      expect(ar.trackDays(5), '5 أيام');
    });

    test('sheetMinutes', () {
      expect(ar.sheetMinutes(1), '1 دقيقة');
      expect(ar.sheetMinutes(2), '2 دقيقتان');
      expect(ar.sheetMinutes(15), '15 دقائق');
    });

    test('nsDndMinutes', () {
      expect(ar.nsDndMinutes(1), '1 دقيقة');
      expect(ar.nsDndMinutes(2), '2 دقيقتان');
      expect(ar.nsDndMinutes(20), '20 دقائق');
    });

    test('mmMosqueCount', () {
      expect(ar.mmMosqueCount(1), '1 مسجد');
      expect(ar.mmMosqueCount(2), '2 مسجداً');
      expect(ar.mmMosqueCount(7), '7 مسجد');
    });

    test('azTimes', () {
      expect(ar.azTimes(1), 'مرة واحدة');
      expect(ar.azTimes(2), '2 مرتان');
      expect(ar.azTimes(3), '3 مرات');
    });

    test('stEveryMinutes', () {
      expect(ar.stEveryMinutes(1), 'كل 1 دقيقة');
      expect(ar.stEveryMinutes(30), 'كل 30 دقائق');
    });

    test('nsBedtimeRelativeSub', () {
      expect(ar.nsBedtimeRelativeSub(1), 'الفجر − 1 ساعة');
      expect(ar.nsBedtimeRelativeSub(7), 'الفجر − 7 ساعات');
    });
  });

  group('english plurals interpolate the count', () {
    final en = loc('en');

    test('spot checks', () {
      expect(en.trackDays(1), '1 day');
      expect(en.trackDays(4), '4 days');
      expect(en.sheetMinutes(5), '5 minutes');
      expect(en.mmMosqueCount(1), '1 mosque');
      expect(en.azTimes(1), 'once');
      expect(en.azTimes(3), '3 times');
      expect(en.nsDndMinutes(20), '20 minutes');
    });
  });

  test('no rendered plural contains a literal #', () {
    for (final l in [loc('ar'), loc('en'), loc('fr')]) {
      for (final s in [
        l.trackDays(0),
        l.trackDays(2),
        l.sheetMinutes(3),
        l.sheetQuestions(1),
        l.sheetQuestions(3),
        l.nsDndMinutes(10),
        l.mmMosqueCount(2),
        l.azTimes(2),
        l.stEveryMinutes(5),
        l.nsBedtimeRelativeSub(2),
      ]) {
        expect(s.contains('#'), isFalse, reason: s);
      }
    }
  });
}
