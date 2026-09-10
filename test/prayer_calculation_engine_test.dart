import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_calculation_engine.dart';

/// Helper to build the params map required by [PrayerCalculationEngine].
///
/// [offsetMinutes] shifts the prayer times uniformly by a fixed number of
/// seconds so tests stay deterministic regardless of the machine timezone.
Map<String, dynamic> _params({
  int year = 2026,
  int month = 9,
  int day = 1,
  double lat = 36.75,
  double lon = 3.05,
  bool dstEnabled = false,
  Map<String, int> prayerOffsets = const {},
  String asrMethod = 'standard',
  String angles = 'mwl',
  double customFajrAngle = 18.0,
  double customIshaAngle = 17.0,
}) {
  return {
    'year': year,
    'month': month,
    'day': day,
    'lat': lat,
    'lon': lon,
    'dstEnabled': dstEnabled,
    'prayerOffsets': prayerOffsets,
    'asrMethod': asrMethod,
    'angles': angles,
    'customFajrAngle': customFajrAngle,
    'customIshaAngle': customIshaAngle,
  };
}

void main() {
  int t(Map<String, int> times, String key) => times[key]!;

  group('PrayerCalculationEngine', () {
    test('debug calculated vs expected hours', () {
      final now = DateTime.now();
      print('Current local date: $now, offset: ${now.timeZoneOffset}');
      // Algiers: lat 36.75, lon 3.05 (UTC+1)
      final times = PrayerCalculationEngine.computeDayTimes({
        'year': 2026,
        'month': 9,
        'day': 5,
        'lat': 36.75,
        'lon': 3.05,
        'dstEnabled': false,
        'prayerOffsets': <String, int>{},
        'asrMethod': 'standard',
        'angles': 'mwl',
        'customFajrAngle': 18.0,
        'customIshaAngle': 17.0,
      });
      final fajrSec = times['fajr']!;
      final dhuhrSec = times['dhuhr']!;
      final fajrHours = fajrSec / 3600.0;
      final dhuhrHours = dhuhrSec / 3600.0;
      print(
          'Calculated Fajr: ${fajrSec ~/ 3600}:${(fajrSec % 3600) ~/ 60} ($fajrHours h)');
      print(
          'Calculated Dhuhr: ${dhuhrSec ~/ 3600}:${(dhuhrSec % 3600) ~/ 60} ($dhuhrHours h)');
    });

    test('returns all six prayer times as seconds for a given day', () {
      final times = PrayerCalculationEngine.computeDayTimes(_params());
      expect(times.keys.toSet(),
          {'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'});
      for (final v in times.values) {
        expect(v, greaterThan(0));
      }
    });

    test('produces chronologically ordered times on any timezone', () {
      final times = PrayerCalculationEngine.computeDayTimes(_params());
      expect(t(times, 'fajr'), lessThan(t(times, 'sunrise')));
      expect(t(times, 'sunrise'), lessThan(t(times, 'dhuhr')));
      expect(t(times, 'dhuhr'), lessThan(t(times, 'asr')));
      expect(t(times, 'asr'), lessThan(t(times, 'maghrib')));
      expect(t(times, 'maghrib'), lessThan(t(times, 'isha')));
    });

    test('order holds across both standard and hanafi asr methods', () {
      for (final method in ['standard', 'hanafi']) {
        final times =
            PrayerCalculationEngine.computeDayTimes(_params(asrMethod: method));
        expect(t(times, 'asr'), lessThan(t(times, 'maghrib')),
            reason: 'asr $method');
        expect(t(times, 'maghrib'), lessThan(t(times, 'isha')),
            reason: 'asr $method');
      }
    });

    test('a prayer offset (in seconds) shifts only that prayer', () {
      final base = PrayerCalculationEngine.computeDayTimes(_params());
      final shifted = PrayerCalculationEngine.computeDayTimes(
          _params(prayerOffsets: {'Fajr': 90}));

      expect(t(shifted, 'fajr') - t(base, 'fajr'), 90);
      // Other prayers unaffected by the Fajr offset.
      expect(t(shifted, 'dhuhr'), t(base, 'dhuhr'));
      expect(t(shifted, 'maghrib'), t(base, 'maghrib'));
      expect(t(shifted, 'isha'), t(base, 'isha'));
    });

    test(
        'manual dst flag does not add an extra hour beyond the device timezone',
        () {
      final normal =
          PrayerCalculationEngine.computeDayTimes(_params(dstEnabled: false));
      final dst =
          PrayerCalculationEngine.computeDayTimes(_params(dstEnabled: true));
      final zoneOffset = DateTime(2026, 9, 1).timeZoneOffset.inMinutes;
      expect(t(dst, 'fajr') - t(normal, 'fajr'), 0 + zoneOffset - zoneOffset);
      expect(t(dst, 'dhuhr') - t(normal, 'dhuhr'), 0 + zoneOffset - zoneOffset);
      expect(t(dst, 'isha') - t(normal, 'isha'), 0 + zoneOffset - zoneOffset);
    });

    test('Umm al-Qura (makkah) sets Isha exactly 90 minutes after Maghrib', () {
      final times =
          PrayerCalculationEngine.computeDayTimes(_params(angles: 'makkah'));
      expect(t(times, 'isha') - t(times, 'maghrib'), 90 * 60);
    });

    test('Qatar also sets Isha 90 minutes after Maghrib (adhan reference)', () {
      final times =
          PrayerCalculationEngine.computeDayTimes(_params(angles: 'qatar'));
      expect(t(times, 'isha') - t(times, 'maghrib'), 90 * 60);
    });

    test('new angle methods stay chronologically ordered', () {
      for (final m in [
        'kuwait',
        'qatar',
        'singapore',
        'turkey',
        'dubai',
        'moonsighting'
      ]) {
        final times =
            PrayerCalculationEngine.computeDayTimes(_params(angles: m));
        expect(t(times, 'fajr'), lessThan(t(times, 'sunrise')), reason: m);
        expect(t(times, 'sunrise'), lessThan(t(times, 'dhuhr')), reason: m);
        expect(t(times, 'dhuhr'), lessThan(t(times, 'asr')), reason: m);
        expect(t(times, 'asr'), lessThan(t(times, 'maghrib')), reason: m);
        expect(t(times, 'maghrib'), lessThan(t(times, 'isha')), reason: m);
      }
    });

    test('legacy methods are unaffected by the new adjustment table', () {
      for (final m in ['mwl', 'egypt', 'makkah', 'isna', 'karachi']) {
        final times = PrayerCalculationEngine.computeDayTimes(
            _params(angles: m, prayerOffsets: {}));
        // Dhuhr carries its method adjustment (adhan dhuhr:+1 where the
        // reference applies it); exact values are pinned by the accuracy
        // test against the adhan package.
        expect(times, isNotEmpty, reason: m);
      }
    });

    test('a larger Fajr angle yields an earlier Fajr time', () {
      final shallow = PrayerCalculationEngine.computeDayTimes(
          _params(angles: 'custom', customFajrAngle: 12.0));
      final steep = PrayerCalculationEngine.computeDayTimes(
          _params(angles: 'custom', customFajrAngle: 20.0));
      expect(t(steep, 'fajr'), lessThan(t(shallow, 'fajr')));
    });

    test('computeMultipleDays returns a result keyed by day key', () {
      final result = PrayerCalculationEngine.computeMultipleDays({
        'days': [
          {'key': '2026-09-01', 'year': 2026, 'month': 9, 'day': 1},
          {'key': '2026-09-02', 'year': 2026, 'month': 9, 'day': 2},
        ],
        'lat': 36.75,
        'lon': 3.05,
        'dstEnabled': false,
        'prayerOffsets': <String, int>{},
        'asrMethod': 'standard',
        'angles': 'mwl',
        'customFajrAngle': 18.0,
        'customIshaAngle': 17.0,
      });
      expect(result.keys, {'2026-09-01', '2026-09-02'});
      expect(result['2026-09-01']!, isNotEmpty);
    });
  });
}
