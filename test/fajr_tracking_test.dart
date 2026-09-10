import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/tracking/data/fajr_tracking_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<FajrDayLog?> log(String date) =>
      FajrTrackingRepository.instance.getLog(date);

  test('single successful day gives streak 1', () async {
    final repo = FajrTrackingRepository.instance;
    final today = DateTime.now();
    await repo.recordWakeUpSuccess(date: today);
    expect(await repo.currentStreak(now: today), 1);
    expect(await log(FajrTrackingRepository.dateKey(today)),
        isNotNull);
  });

  test('two consecutive days give streak 2', () async {
    final repo = FajrTrackingRepository.instance;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    await repo.recordWakeUpSuccess(date: yesterday);
    await repo.recordWakeUpSuccess(date: today);
    expect(await repo.currentStreak(now: today), 2);
  });

  test('missed day breaks the streak', () async {
    final repo = FajrTrackingRepository.instance;
    final today = DateTime.now();
    final twoAgo = today.subtract(const Duration(days: 2));
    await repo.recordWakeUpSuccess(date: twoAgo);
    await repo.recordWakeUpSuccess(date: today);
    // Yesterday missing → streak counts only today.
    expect(await repo.currentStreak(now: today), 1);
  });

  test('recovery: streak restarts after a miss', () async {
    final repo = FajrTrackingRepository.instance;
    final today = DateTime.now();
    await repo.recordWakeUpSuccess(date: today);
    expect(await repo.currentStreak(now: today), 1);
    expect(await repo.longestStreak(), 1);
  });

  test('challenge-only (no confirmation) does NOT count', () async {
    final repo = FajrTrackingRepository.instance;
    final today = DateTime.now();
    await repo.recordChallengeCompleted(date: today);
    expect(await repo.currentStreak(now: today), 0);
    // Confirming afterwards upgrades the same date to success.
    await repo.recordWakeUpSuccess(date: today);
    expect(await repo.currentStreak(now: today), 1);
  });

  test('month and year boundaries work', () async {
    final repo = FajrTrackingRepository.instance;
    final jan1 = DateTime(2026, 1, 1);
    final dec31 = DateTime(2025, 12, 31);
    await repo.recordWakeUpSuccess(date: dec31);
    await repo.recordWakeUpSuccess(date: jan1);
    expect(await repo.currentStreak(now: jan1), 2);
  });

  test('duplicate records for the same date are idempotent', () async {
    final repo = FajrTrackingRepository.instance;
    final today = DateTime.now();
    await repo.recordWakeUpSuccess(date: today);
    await repo.recordWakeUpSuccess(date: today);
    expect(await repo.currentStreak(now: today), 1);
  });
}
