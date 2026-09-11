import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/tracking/data/fajr_tracking_repository.dart';
import 'package:small_husn_muslim/features/tracking/data/points_engine.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_log_entry.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  PrayerLogEntry entry(int prayer, PrayerStatus status) => PrayerLogEntry(
        date: '2026-09-04',
        prayerIndex: prayer,
        status: status,
        updatedAt: 0,
      );

  group('PointsEngine', () {
    test('base points table matches the design', () {
      expect(PointsEngine.basePoints[PrayerStatus.takbeer], 30);
      expect(PointsEngine.basePoints[PrayerStatus.mosque], 27);
      expect(PointsEngine.basePoints[PrayerStatus.jamaa], 14);
      expect(PointsEngine.basePoints[PrayerStatus.onTimeAlone], 1);
      expect(PointsEngine.basePoints[PrayerStatus.late], 1);
      expect(PointsEngine.basePoints[PrayerStatus.missed], -10);
    });

    test('Fajr doubles points, Isha is x1.5, rest x1', () {
      // Takbeer: Fajr 60, Dhuhr 30, Isha 45.
      expect(PointsEngine.entryPoints(entry(0, PrayerStatus.takbeer)), 60);
      expect(PointsEngine.entryPoints(entry(1, PrayerStatus.takbeer)), 30);
      expect(PointsEngine.entryPoints(entry(2, PrayerStatus.takbeer)), 30);
      expect(PointsEngine.entryPoints(entry(3, PrayerStatus.takbeer)), 30);
      expect(PointsEngine.entryPoints(entry(4, PrayerStatus.takbeer)), 45);
      // Mosque in Isha: 27 * 1.5 = 40.5 -> 41 (rounds half away from zero).
      expect(PointsEngine.entryPoints(entry(4, PrayerStatus.mosque)), 41);
      // Missed Fajr hurts double: -20. Missed Dhuhr: -10.
      expect(PointsEngine.entryPoints(entry(0, PrayerStatus.missed)), -20);
      expect(PointsEngine.entryPoints(entry(1, PrayerStatus.missed)), -10);
    });

    test('level thresholds: 8 levels', () {
      expect(PointsEngine.maxLevel, 8);
      expect(PointsEngine.levelForPoints(0), 1);
      expect(PointsEngine.levelForPoints(1), 1);
      expect(PointsEngine.levelForPoints(249), 1);
      expect(PointsEngine.levelForPoints(250), 2);
      expect(PointsEngine.levelForPoints(600), 3);
      expect(PointsEngine.levelForPoints(1100), 4);
      expect(PointsEngine.levelForPoints(1800), 5);
      expect(PointsEngine.levelForPoints(2800), 6);
      expect(PointsEngine.levelForPoints(4100), 7);
      expect(PointsEngine.levelForPoints(5450), 8);
      expect(PointsEngine.levelForPoints(99999), 8);
    });

    test('progress and points-to-next behave at boundaries', () {
      expect(PointsEngine.progressToNextLevel(0), 0.0);
      expect(PointsEngine.pointsToNextLevel(0), 1);
      expect(PointsEngine.pointsToNextLevel(249), 1);
      expect(PointsEngine.pointsToNextLevel(250), 350);
      expect(PointsEngine.pointsToNextLevel(5450), isNull);
      expect(PointsEngine.progressToNextLevel(99999), 1.0);
      final mid = PointsEngine.progressToNextLevel(425);
      expect(mid, greaterThan(0.0));
      expect(mid, lessThan(1.0));
    });
  });

  group('PrayerTrackingRepository', () {
    test('log + read back one day in prayer order', () async {
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.logPrayer(
          date: today, prayerIndex: 0, status: PrayerStatus.takbeer);
      await repo.logPrayer(
          date: today, prayerIndex: 4, status: PrayerStatus.mosque);
      final day = await repo.dayEntries(today);
      expect(day.length, 5);
      expect(day[0]?.status, PrayerStatus.takbeer);
      expect(day[1], isNull);
      expect(day[4]?.status, PrayerStatus.mosque);
    });

    test('re-logging replaces the status', () async {
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.logPrayer(
          date: today, prayerIndex: 1, status: PrayerStatus.late);
      await repo.logPrayer(
          date: today, prayerIndex: 1, status: PrayerStatus.jamaa);
      final day = await repo.dayEntries(today);
      expect(day[1]?.status, PrayerStatus.jamaa);
    });

    test('clear removes a single prayer only', () async {
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.logPrayer(
          date: today, prayerIndex: 0, status: PrayerStatus.onTimeAlone);
      await repo.logPrayer(
          date: today, prayerIndex: 1, status: PrayerStatus.onTimeAlone);
      await repo.clearPrayer(date: today, prayerIndex: 0);
      final day = await repo.dayEntries(today);
      expect(day[0], isNull);
      expect(day[1]?.status, PrayerStatus.onTimeAlone);
    });

    test('full-goal day counts, partial day breaks the streak', () async {
      final repo = PrayerTrackingRepository.instance;
      // Anchored to the real today: the longest-streak refresh walks back
      // from DateTime.now(), so fixed historic dates would leave it at 0.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      for (var p = 0; p < 5; p++) {
        await repo.logPrayer(
            date: yesterday, prayerIndex: p, status: PrayerStatus.onTimeAlone);
      }
      await repo.logPrayer(
          date: today, prayerIndex: 0, status: PrayerStatus.onTimeAlone);
      // Today pending (1/5) -> streak walks from yesterday -> 1.
      expect(await repo.currentStreak(now: today), 1);
      // Finish today -> streak 2.
      for (var p = 1; p < 5; p++) {
        await repo.logPrayer(
            date: today, prayerIndex: p, status: PrayerStatus.jamaa);
      }
      expect(await repo.currentStreak(now: today), 2);
      expect(await repo.longestStreak(), 2);
    });

    test('missed prayers do not count toward the goal', () async {
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      for (var p = 0; p < 4; p++) {
        await repo.logPrayer(
            date: today, prayerIndex: p, status: PrayerStatus.onTimeAlone);
      }
      await repo.logPrayer(
          date: today, prayerIndex: 4, status: PrayerStatus.missed);
      // 4/5 with default goal 5 -> streak 0.
      expect(await repo.currentStreak(now: today), 0);
    });

    test('custom daily goal lowers the streak bar', () async {
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.setDailyGoal(3);
      for (var p = 0; p < 3; p++) {
        await repo.logPrayer(
            date: today, prayerIndex: p, status: PrayerStatus.late);
      }
      expect(await repo.currentStreak(now: today), 1);
    });

    test('rolling 30-day points sum across days and prayers', () async {
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      final yesterday = DateTime(2026, 9, 3);
      // Fajr takbeer today: 30*2 = 60. Isha mosque yesterday: 27*1.5 -> 41.
      await repo.logPrayer(
          date: today, prayerIndex: 0, status: PrayerStatus.takbeer);
      await repo.logPrayer(
          date: yesterday, prayerIndex: 4, status: PrayerStatus.mosque);
      expect(await repo.rolling30DayPoints(now: today), 101);
    });

    test('disabled tracking refuses new logs', () async {
      final repo = PrayerTrackingRepository.instance;
      await repo.setDisabled(true);
      final logged = await repo.logPrayer(
          date: DateTime(2026, 9, 4),
          prayerIndex: 0,
          status: PrayerStatus.onTimeAlone);
      expect(logged, isNull);
      await repo.setDisabled(false);
    });

    test('clearAll wipes logs but keeps settings', () async {
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime(2026, 9, 4);
      await repo.setDailyGoal(3);
      await repo.setContext(PrayerTrackingRepository.contextWoman);
      for (var p = 0; p < 5; p++) {
        await repo.logPrayer(
            date: today, prayerIndex: p, status: PrayerStatus.onTimeAlone);
      }
      await repo.clearAll();
      final day = await repo.dayEntries(today);
      expect(day.every((e) => e == null), isTrue);
      expect(await repo.dailyGoal(), 3);
      expect(await repo.context(),
          PrayerTrackingRepository.contextWoman);
    });

    test('Fajr alarm success auto-logs Fajr without clobbering manual', () async {
      final fajrRepo = FajrTrackingRepository.instance;
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime.now();
      await fajrRepo.recordWakeUpSuccess(date: today);
      var day = await repo.dayEntries(today);
      expect(day[0]?.status, PrayerStatus.onTimeAlone);
      // Manual correction survives a repeated alarm record.
      await repo.logPrayer(
          date: today, prayerIndex: 0, status: PrayerStatus.mosque);
      await fajrRepo.recordWakeUpSuccess(date: today);
      day = await repo.dayEntries(today);
      expect(day[0]?.status, PrayerStatus.mosque);
    });

    test('migrateFajrLogs imports legacy successes once', () async {
      final repo = PrayerTrackingRepository.instance;
      final prefs = await SharedPreferences.getInstance();
      // Simulate an old install predating the alarm mirror: raw legacy keys.
      await prefs.setString('fajr_log_2026-08-20',
          '{"date":"2026-08-20","fajr":true,"challenge":true,"wakeup":true}');
      await prefs.setString('fajr_log_2026-08-21',
          '{"date":"2026-08-21","fajr":true,"challenge":true,"wakeup":false}');
      // Only the wake-up success imports; the challenge-only key is skipped.
      expect(await repo.migrateFajrLogs(), 1);
      var day = await repo.dayEntries(DateTime(2026, 8, 20));
      expect(day[0]?.status, PrayerStatus.onTimeAlone);
      day = await repo.dayEntries(DateTime(2026, 8, 21));
      expect(day[0], isNull);
      // Second run is a no-op (flag + per-day guards).
      expect(await repo.migrateFajrLogs(), 0);
    });
    test('sync writes day-progress widget keys', () async {
      final repo = PrayerTrackingRepository.instance;
      final today = DateTime.now();
      await repo.logPrayer(
          date: today, prayerIndex: 0, status: PrayerStatus.takbeer);
      await repo.logPrayer(
          date: today, prayerIndex: 2, status: PrayerStatus.missed);
      final prefs = await SharedPreferences.getInstance();
      // Missed doesn't count: 1 done of default goal 5.
      expect(prefs.getInt('widget_day_done'), 1);
      expect(prefs.getInt('widget_day_goal'), 5);
      await repo.setDailyGoal(3);
      expect(prefs.getInt('widget_day_goal'), 3);
    });

    test('diagnosticsSnapshot reflects seeded state', () async {
      final repo = PrayerTrackingRepository.instance;
      // Anchored to the real today (see the streak test above).
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (var p = 0; p < 5; p++) {
        await repo.logPrayer(
            date: today, prayerIndex: p, status: PrayerStatus.onTimeAlone);
      }
      await repo.setReminders(true);
      await repo.setContext(PrayerTrackingRepository.contextWoman);
      await repo.setOnboarded(true);

      final snap = await repo.diagnosticsSnapshot(now: today);
      // Fajr 1x2=2, Dhuhr/Asr/Maghrib 1 each, Isha round(1.5)=2 → 7 pts.
      expect(snap, {
        'current': 1,
        'longest': 1,
        'goal': 5,
        'points30': 7,
        'level': 1,
        'todayLogged': 5,
        'reminders': true,
        'disabled': false,
        'context': 'woman',
        'onboarded': true,
        'cacheToday': false,
      });
    });
  });
}
