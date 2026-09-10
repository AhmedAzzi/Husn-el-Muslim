import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_log_entry.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_reminder_service.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';

import 'support/fake_android_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  late FakeAndroidNotifications fake;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    fake = FakeAndroidNotifications();
    FlutterLocalNotificationsPlatform.instance = fake;
  });

  List<PrayerMoment> momentsFromNow(List<Duration> offsets) {
    const names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final now = DateTime.now();
    return List.generate(
        5, (i) => PrayerMoment(names[i], now.add(offsets[i])));
  }

  group('planner', () {
    test('unlogged future prayers are due at time + offset', () {
      final now = DateTime(2026, 9, 4, 12, 0);
      final moments = [
        PrayerMoment('Fajr', DateTime(2026, 9, 4, 5, 0)),
        PrayerMoment('Dhuhr', DateTime(2026, 9, 4, 12, 30)),
        PrayerMoment('Asr', DateTime(2026, 9, 4, 16, 0)),
        PrayerMoment('Maghrib', DateTime(2026, 9, 4, 19, 0)),
        PrayerMoment('Isha', DateTime(2026, 9, 4, 20, 30)),
      ];
      final due = PrayerReminderService.plan(
          now: now, moments: moments, logged: {});
      // Fajr 5:30 past; Dhuhr 13:00, Asr 16:30, Maghrib 19:30, Isha 21:00.
      expect(due.map((d) => d.prayerIndex).toList(), [1, 2, 3, 4]);
      expect(due.first.fireAt, DateTime(2026, 9, 4, 13, 0));
    });

    test('logged prayers are excluded', () {
      final now = DateTime(2026, 9, 4, 12, 0);
      final moments = [
        PrayerMoment('Fajr', DateTime(2026, 9, 4, 5, 0)),
        PrayerMoment('Dhuhr', DateTime(2026, 9, 4, 12, 30)),
        PrayerMoment('Asr', DateTime(2026, 9, 4, 16, 0)),
        PrayerMoment('Maghrib', DateTime(2026, 9, 4, 19, 0)),
        PrayerMoment('Isha', DateTime(2026, 9, 4, 20, 30)),
      ];
      final due = PrayerReminderService.plan(
          now: now, moments: moments, logged: {1, 3});
      expect(due.map((d) => d.prayerIndex).toList(), [2, 4]);
    });

    test('custom offset shifts fire times', () {
      final now = DateTime(2026, 9, 4, 12, 0);
      final moments = [
        PrayerMoment('Dhuhr', DateTime(2026, 9, 4, 12, 30)),
      ];
      final due0 = PrayerReminderService.plan(
          now: now, moments: moments, logged: {}, offsetMinutes: 0);
      expect(due0.length, 1);
      final due60 = PrayerReminderService.plan(
          now: now, moments: moments, logged: {}, offsetMinutes: 60);
      expect(due60.first.fireAt, DateTime(2026, 9, 4, 13, 30));
    });
  });

  group('flag + service', () {
    test('reminders default OFF', () async {
      expect(
          await PrayerTrackingRepository.instance.remindersEnabled(),
          isFalse);
    });

    test('refresh schedules only due prayers on tracking channel', () async {
      final repo = PrayerTrackingRepository.instance;
      await repo.setReminders(true);
      // Fajr + Dhuhr in the past, rest in the future.
      await PrayerReminderService.instance
          .refreshWithMoments(momentsFromNow(const [
        Duration(hours: -5),
        Duration(hours: -2),
        Duration(hours: 2),
        Duration(hours: 3),
        Duration(hours: 4),
      ]));
      expect(fake.scheduled.map((s) => s['id']).toList(), [202, 203, 204]);
      // One-shot: no daily-repeat component.
      expect(
          fake.scheduled.map((s) => s['match']).toSet(), {isNull});
      expect(fake.scheduled.first['channel'], 'tracking_channel');
      expect(fake.scheduled.first['payload'], 'PrayerTrack_Log');
      expect(
          (fake.scheduled.first['body'] as String).contains('العصر'),
          isTrue);
      // Stale IDs always cancelled first.
      expect(fake.cancelled, containsAll([200, 201, 202, 203, 204]));
    });

    test('refresh is inert when reminders are off', () async {
      await PrayerReminderService.instance
          .refreshWithMoments(momentsFromNow(const [
        Duration(hours: 2),
        Duration(hours: 3),
        Duration(hours: 4),
        Duration(hours: 5),
        Duration(hours: 6),
      ]));
      expect(fake.scheduled, isEmpty);
    });

    test('refresh is inert when tracking is paused', () async {
      final repo = PrayerTrackingRepository.instance;
      await repo.setReminders(true);
      await repo.setDisabled(true);
      await PrayerReminderService.instance
          .refreshWithMoments(momentsFromNow(const [
        Duration(hours: 2),
        Duration(hours: 3),
        Duration(hours: 4),
        Duration(hours: 5),
        Duration(hours: 6),
      ]));
      expect(fake.scheduled, isEmpty);
      await repo.setDisabled(false);
    });

    test('logging a prayer cancels its reminder', () async {
      final repo = PrayerTrackingRepository.instance;
      await repo.setReminders(true);
      await repo.logPrayer(
          date: DateTime.now(),
          prayerIndex: 2,
          status: PrayerStatus.onTimeAlone);
      expect(fake.cancelled, contains(202));
    });

    test('refreshFromCache works after a refresh', () async {
      final repo = PrayerTrackingRepository.instance;
      await repo.setReminders(true);
      final svc = PrayerReminderService.instance;
      await svc.refreshWithMoments(momentsFromNow(const [
        Duration(hours: -5),
        Duration(hours: -2),
        Duration(hours: 2),
        Duration(hours: 3),
        Duration(hours: 4),
      ]));
      fake.scheduled.clear();
      fake.cancelled.clear();
      await svc.refreshFromCache();
      expect(fake.scheduled.map((s) => s['id']).toList(), [202, 203, 204]);
    });
  });
}
