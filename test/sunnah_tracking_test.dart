import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/tracking/data/sunnah_tracking_repository.dart';
import 'package:small_husn_muslim/features/tracking/data/sunnah_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SunnahTrackingRepository', () {
    test('toggle + read back one day in type order', () async {
      final repo = SunnahTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      expect(
          await repo.toggleSunnah(
              date: today, type: SunnahType.fajrSunnah),
          isTrue);
      expect(
          await repo.toggleSunnah(date: today, type: SunnahType.witr),
          isTrue);
      final day = await repo.dayEntries(today);
      expect(day.length, SunnahType.values.length);
      expect(day[SunnahType.fajrSunnah.index], isTrue);
      expect(day[SunnahType.dhuhrBefore.index], isFalse);
      expect(day[SunnahType.witr.index], isTrue);
    });

    test('toggling twice un-does the entry', () async {
      final repo = SunnahTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.toggleSunnah(date: today, type: SunnahType.duha);
      await repo.toggleSunnah(date: today, type: SunnahType.duha);
      final day = await repo.dayEntries(today);
      expect(day[SunnahType.duha.index], isFalse);
    });

    test('day points include the full-Rawatib bonus', () async {
      final repo = SunnahTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      for (final t in rawatibTypes) {
        await repo.setSunnah(date: today, type: t, done: true);
      }
      // 5 x 10 + 10 bonus = 60.
      expect(await repo.dayPoints(today), 60);
      expect(await repo.rawatibComplete(today), isTrue);
      // Duha adds 8 on top.
      await repo.setSunnah(date: today, type: SunnahType.duha, done: true);
      expect(await repo.dayPoints(today), 68);
    });

    test('partial Rawatib earns no bonus', () async {
      final repo = SunnahTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.setSunnah(
          date: today, type: SunnahType.fajrSunnah, done: true);
      expect(await repo.dayPoints(today), 10);
      expect(await repo.rawatibComplete(today), isFalse);
    });

    test('goal-meeting day counts, partial day breaks the streak', () async {
      final repo = SunnahTrackingRepository.instance;
      // Anchored to the real today: the longest-streak refresh walks back
      // from DateTime.now(), so fixed historic dates would leave it at 0.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      await repo.setDailyGoal(2);
      await repo.setSunnah(
          date: yesterday, type: SunnahType.fajrSunnah, done: true);
      await repo.setSunnah(
          date: yesterday, type: SunnahType.witr, done: true);
      await repo.setSunnah(
          date: today, type: SunnahType.fajrSunnah, done: true);
      // Today pending (1/2) -> streak walks from yesterday -> 1.
      expect(await repo.currentStreak(now: today), 1);
      await repo.setSunnah(
          date: today, type: SunnahType.witr, done: true);
      expect(await repo.currentStreak(now: today), 2);
      expect(await repo.longestStreak(), 2);
    });

    test('disabled tracking refuses new toggles', () async {
      final repo = SunnahTrackingRepository.instance;
      await repo.setDisabled(true);
      expect(
          await repo.toggleSunnah(
              date: DateTime(2026, 9, 4),
              type: SunnahType.fajrSunnah),
          isNull);
      await repo.setDisabled(false);
    });

    test('clearAll wipes logs but keeps the goal', () async {
      final repo = SunnahTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.setDailyGoal(3);
      await repo.setSunnah(
          date: today, type: SunnahType.fajrSunnah, done: true);
      await repo.clearAll();
      expect(await repo.dayCount(today), 0);
      expect(await repo.dailyGoal(), 3);
    });

    test('rolling 30-day points sum across days', () async {
      final repo = SunnahTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      final yesterday = DateTime(2026, 9, 3);
      await repo.setSunnah(
          date: today, type: SunnahType.qiyam, done: true);
      await repo.setSunnah(
          date: yesterday, type: SunnahType.witr, done: true);
      // 15 + 12 = 27.
      expect(await repo.rolling30DayPoints(now: today), 27);
    });

    test('countsForRange returns newest-first counts', () async {
      final repo = SunnahTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.setSunnah(
          date: today, type: SunnahType.fajrSunnah, done: true);
      final counts = await repo.countsForRange(2, end: today);
      expect(counts.length, 2);
      expect(counts[0], 1);
      expect(counts[1], 0);
    });
  });
}
