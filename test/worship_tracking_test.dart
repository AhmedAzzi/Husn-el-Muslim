import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/tracking/data/worship_tracking_repository.dart';
import 'package:small_husn_muslim/features/tracking/data/worship_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('WorshipTrackingRepository deeds', () {
    test('toggle + read back one day in type order', () async {
      final repo = WorshipTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      expect(
          await repo.toggleDeed(
              date: today, type: DeedType.quranWird),
          isTrue);
      expect(
          await repo.toggleDeed(date: today, type: DeedType.sadaqah),
          isTrue);
      final day = await repo.dayEntries(today);
      expect(day.length, DeedType.values.length);
      expect(day[DeedType.quranWird.index], isTrue);
      expect(day[DeedType.morningAdhkar.index], isFalse);
      expect(day[DeedType.sadaqah.index], isTrue);
    });

    test('toggling twice un-does the entry', () async {
      final repo = WorshipTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.toggleDeed(date: today, type: DeedType.istighfar);
      await repo.toggleDeed(date: today, type: DeedType.istighfar);
      final day = await repo.dayEntries(today);
      expect(day[DeedType.istighfar.index], isFalse);
    });

    test('day points sum the deed table', () async {
      final repo = WorshipTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.setDeed(date: today, type: DeedType.quranWird, done: true);
      await repo.setDeed(date: today, type: DeedType.sadaqah, done: true);
      // 10 + 8 = 18.
      expect(await repo.dayPoints(today), 18);
    });

    test('goal-meeting day counts, partial day breaks the streak', () async {
      final repo = WorshipTrackingRepository.instance;
      // Anchored to the real today: the longest refresh walks back from
      // DateTime.now(), so fixed historic dates would leave it at 0.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      await repo.setDailyGoal(2);
      await repo.setDeed(
          date: yesterday, type: DeedType.quranWird, done: true);
      await repo.setDeed(
          date: yesterday, type: DeedType.sadaqah, done: true);
      await repo.setDeed(
          date: today, type: DeedType.quranWird, done: true);
      // Today pending (1/2) -> streak walks from yesterday -> 1.
      expect(await repo.currentStreak(now: today), 1);
      await repo.setDeed(date: today, type: DeedType.sadaqah, done: true);
      expect(await repo.currentStreak(now: today), 2);
      expect(await repo.longestStreak(), 2);
    });

    test('disabled tracking refuses new toggles and fasts', () async {
      final repo = WorshipTrackingRepository.instance;
      await repo.setDisabled(true);
      expect(
          await repo.toggleDeed(
              date: DateTime(2026, 9, 4), type: DeedType.quranWird),
          isNull);
      expect(
          await repo.logFast(
              date: DateTime(2026, 9, 4), kind: FastKind.monday),
          isNull);
      await repo.setDisabled(false);
    });

    test('clearAll wipes deeds and fasts but keeps the goal', () async {
      final repo = WorshipTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.setDailyGoal(3);
      await repo.setDeed(date: today, type: DeedType.quranWird, done: true);
      await repo.logFast(date: today, kind: FastKind.monday);
      await repo.clearAll();
      expect(await repo.dayCount(today), 0);
      expect(await repo.fastOn(today), isNull);
      expect(await repo.dailyGoal(), 3);
    });
  });

  group('WorshipTrackingRepository fasting', () {
    test('log + read back a fast, re-log replaces the kind', () async {
      final repo = WorshipTrackingRepository.instance;
      final monday = DateTime(2026, 9, 7); // a Monday
      expect(monday.weekday, 1);
      await repo.logFast(date: monday, kind: FastKind.monday);
      expect(await repo.fastOn(monday), FastKind.monday);
      await repo.logFast(date: monday, kind: FastKind.nafl);
      expect(await repo.fastOn(monday), FastKind.nafl);
      await repo.clearFast(monday);
      expect(await repo.fastOn(monday), isNull);
    });

    test('fast points follow the kind table', () async {
      final repo = WorshipTrackingRepository.instance;
      final monday = DateTime(2026, 9, 7);
      await repo.logFast(date: monday, kind: FastKind.monday);
      expect(await repo.fastPointsOn(monday), 20);
      await repo.logFast(date: monday, kind: FastKind.arafah);
      expect(await repo.fastPointsOn(monday), 30);
      expect(await repo.fastPointsOn(DateTime(2026, 9, 8)), 0);
    });

    test('full Mon+Thu weeks build the fasting streak', () async {
      final repo = WorshipTrackingRepository.instance;
      // Explicit anchor (a Saturday): the two weeks ending then are fully
      // elapsed, so the streak is deterministic whatever the real today is.
      final anchor = DateTime(2026, 9, 12);
      expect(anchor.weekday, 6);
      final thisMonday =
          WorshipTrackingRepository.mondayOfWeek(anchor);
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      for (final mon in [lastMonday, thisMonday]) {
        await repo.logFast(date: mon, kind: FastKind.monday);
        await repo.logFast(
            date: mon.add(const Duration(days: 3)),
            kind: FastKind.thursday);
      }
      expect(await repo.fastingWeekStreak(now: anchor), 2);
    });

    test('fasting longest tracks complete weeks', () async {
      final repo = WorshipTrackingRepository.instance;
      // Anchored to the real today: the longest refresh walks back from
      // DateTime.now(). Elapsed days only, so a Sunday run logs 3 weeks.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisMonday = WorshipTrackingRepository.mondayOfWeek(today);
      for (final mon in [
        thisMonday.subtract(const Duration(days: 14)),
        thisMonday.subtract(const Duration(days: 7)),
        thisMonday,
      ]) {
        final thu = mon.add(const Duration(days: 3));
        if (!mon.isAfter(today)) {
          await repo.logFast(date: mon, kind: FastKind.monday);
        }
        if (!thu.isAfter(today)) {
          await repo.logFast(date: thu, kind: FastKind.thursday);
        }
      }
      expect(await repo.fastingLongest(), greaterThanOrEqualTo(2));
    });

    test('a missed Thursday breaks the fasting streak', () async {
      final repo = WorshipTrackingRepository.instance;
      final thisMonday =
          WorshipTrackingRepository.mondayOfWeek(DateTime.now());
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      // Last week: Monday only — Thursday missed and fully elapsed.
      await repo.logFast(date: lastMonday, kind: FastKind.monday);
      expect(await repo.fastingWeekStreak(), 0);
    });

    test('fast counts and rolling points span deeds + fasts', () async {
      final repo = WorshipTrackingRepository.instance;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      await repo.logFast(date: today, kind: FastKind.thursday);
      await repo.logFast(date: yesterday, kind: FastKind.monday);
      expect(await repo.fastCount30(now: today), 2);
      await repo.setDeed(date: today, type: DeedType.quranWird, done: true);
      // 20 + 20 + 10 = 50.
      expect(await repo.rolling30DayPoints(now: today), 50);
    });
  });
}
