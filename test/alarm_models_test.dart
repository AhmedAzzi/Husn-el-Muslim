import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/features/alarms/models/alarm_models.dart';

void main() {
  group('AlarmConfig', () {
    test('deterministic IDs are stable and unique per type+date', () {
      final d = DateTime(2026, 9, 3);
      final a = AlarmConfig.deterministicId(AlarmType.fajr, d);
      final b = AlarmConfig.deterministicId(AlarmType.fajr, d);
      final c = AlarmConfig.deterministicId(AlarmType.suhoor, d);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('wake-up types use setAlarmClock priority', () {
      for (final t in [
        AlarmType.fajr,
        AlarmType.suhoor,
        AlarmType.preFajr,
        AlarmType.tahajjud,
        AlarmType.fajrExtra1,
        AlarmType.fajrExtra2,
      ]) {
        expect(
            AlarmConfig(id: 'x', type: t).priority, AlarmPriority.wakeUp);
      }
      expect(AlarmConfig(id: 'x', type: AlarmType.bedtime).priority,
          AlarmPriority.informational);
    });

    test('JSON round-trips with defaults (migration-safe)', () {
      const cfg = AlarmConfig(id: 'fajr|2026-09-03|', type: AlarmType.fajr);
      final back = AlarmConfig.fromJson(cfg.toJson());
      expect(back.id, cfg.id);
      expect(back.type, AlarmType.fajr);
      expect(back.enabled, isFalse);
      // Unknown type falls back to custom instead of crashing.
      final unknown = AlarmConfig.fromJson({'id': 'z', 'type': 'nope'});
      expect(unknown.type, AlarmType.custom);
    });
  });

  group('fajrAnchoredTrigger', () {
    test('Suhoor example: Fajr 04:55 − 40min = 04:15', () {
      final fajr = DateTime(2026, 9, 3, 4, 55);
      final now = DateTime(2026, 9, 2, 22, 0);
      final t = fajrAnchoredTrigger(
          fajrToday: fajr, offsetMinutes: 40, now: now)!;
      expect(t.hour, 4);
      expect(t.minute, 15);
    });

    test('rolls to tomorrow when the time already passed', () {
      final fajr = DateTime(2026, 9, 3, 4, 55);
      final now = DateTime(2026, 9, 3, 6, 0);
      final t = fajrAnchoredTrigger(
          fajrToday: fajr, offsetMinutes: 40, now: now)!;
      expect(t.day, 4);
      expect(t.hour, 4);
      expect(t.minute, 15);
    });

    test('negative offset is rejected', () {
      expect(
          fajrAnchoredTrigger(
              fajrToday: DateTime(2026, 9, 3, 4, 55),
              offsetMinutes: -5,
              now: DateTime(2026, 9, 2)),
          isNull);
    });

    test('new kinds have deterministic IDs distinct from legacy kinds', () {
      final d = DateTime(2026, 9, 3);
      final ids = {
        for (final t in AlarmType.values)
          AlarmConfig.deterministicId(t, d),
      };
      // One unique ID per kind (tahajjud + extras included).
      expect(ids.length, AlarmType.values.length);
    });

    test('heavy-sleeper extra delay clamps to 1..60 minutes', () {
      expect(0.clamp(1, 60), 1);
      expect(5.clamp(1, 60), 5);
      expect(120.clamp(1, 60), 60);
    });
  });
}
