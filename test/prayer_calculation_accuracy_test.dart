import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_calculation_engine.dart';

/// The engine delegates astronomy to the `adhan` package, so it must track
/// the reference exactly across seasons, methods, and madhab/custom-angle
/// variants. Any drift here means the delegation layer (method mapping,
/// timezone anchoring, offsets) regressed.
///
/// Machine zone == location zone (Algiers, UTC+1, no DST) keeps the
/// comparison anchor-exact; the engine resolves both sides against the
/// device zone for the date.
Map<String, dynamic> _params({
  required int year,
  required int month,
  required int day,
  required double lat,
  required double lon,
  required String angles,
  String asrMethod = 'standard',
  Map<String, int> prayerOffsets = const {},
  double customFajrAngle = 18.0,
  double customIshaAngle = 17.0,
}) =>
    {
      'year': year,
      'month': month,
      'day': day,
      'lat': lat,
      'lon': lon,
      'dstEnabled': false,
      'prayerOffsets': prayerOffsets,
      'asrMethod': asrMethod,
      'angles': angles,
      'customFajrAngle': customFajrAngle,
      'customIshaAngle': customIshaAngle,
    };

int _deltaSeconds(
    Map<String, int> ours, DateTime ref, DateTime base, String key) {
  final oursDt = base.add(Duration(seconds: ours[key]!));
  return oursDt.difference(ref).inSeconds;
}

void main() {
  const lat = 36.75, lon = 3.05;
  const engineKey = {
    CalculationMethod.muslim_world_league: 'mwl',
    CalculationMethod.egyptian: 'egypt',
    CalculationMethod.umm_al_qura: 'makkah',
    CalculationMethod.north_america: 'isna',
    CalculationMethod.karachi: 'karachi',
    CalculationMethod.kuwait: 'kuwait',
    CalculationMethod.qatar: 'qatar',
    CalculationMethod.singapore: 'singapore',
    CalculationMethod.turkey: 'turkey',
    CalculationMethod.dubai: 'dubai',
    CalculationMethod.moon_sighting_committee: 'moonsighting',
  };

  void checkAll({
    required int year,
    required int month,
    required int day,
  }) {
    final zone = DateTime(year, month, day).timeZoneOffset.inMinutes;
    final base = DateTime(year, month, day);
    for (final entry in engineKey.entries) {
      final ours = PrayerCalculationEngine.computeDayTimes(_params(
        year: year, month: month, day: day,
        lat: lat, lon: lon, angles: entry.value,
      ));
      final p = entry.key.getParameters()..madhab = Madhab.shafi;
      final ref = PrayerTimes(
        Coordinates(lat, lon),
        DateComponents.from(DateTime(year, month, day)),
        p,
        utcOffset: Duration(minutes: zone),
      );
      final refMap = {
        'fajr': ref.fajr,
        'sunrise': ref.sunrise,
        'dhuhr': ref.dhuhr,
        'asr': ref.asr,
        'maghrib': ref.maghrib,
        'isha': ref.isha,
      };
      for (final k in refMap.keys) {
        expect(_deltaSeconds(ours, refMap[k]!, base, k), 0,
            reason: '${entry.key} $k on $year-$month-$day');
      }
    }
  }

  group('reference accuracy (equinoxes + solstices x all methods)', () {
    for (final d in const [
      [2026, 3, 20],
      [2026, 6, 21],
      [2026, 9, 4],
      [2026, 12, 21],
    ]) {
      test('${d[0]}-${d[1]}-${d[2]} matches adhan exactly', () {
        checkAll(year: d[0], month: d[1], day: d[2]);
      });
    }
  });

  test('hanafi asr matches adhan', () {
    final zone = DateTime(2026, 9, 4).timeZoneOffset.inMinutes;
    final ours = PrayerCalculationEngine.computeDayTimes(_params(
      year: 2026, month: 9, day: 4,
      lat: lat, lon: lon, angles: 'mwl', asrMethod: 'hanafi',
    ));
    final p = CalculationMethod.muslim_world_league.getParameters()
      ..madhab = Madhab.hanafi;
    final ref = PrayerTimes(
      Coordinates(lat, lon),
      DateComponents.from(DateTime(2026, 9, 4)),
      p,
      utcOffset: Duration(minutes: zone),
    );
    expect(
        _deltaSeconds(ours, ref.asr, DateTime(2026, 9, 4), 'asr'), 0);
  });

  test('custom angles match adhan other-method', () {
    final zone = DateTime(2026, 9, 4).timeZoneOffset.inMinutes;
    final ours = PrayerCalculationEngine.computeDayTimes(_params(
      year: 2026, month: 9, day: 4,
      lat: lat, lon: lon, angles: 'custom',
      customFajrAngle: 16.0, customIshaAngle: 15.0,
    ));
    final p = CalculationMethod.other.getParameters()
      ..fajrAngle = 16.0
      ..ishaAngle = 15.0;
    final ref = PrayerTimes(
      Coordinates(lat, lon),
      DateComponents.from(DateTime(2026, 9, 4)),
      p,
      utcOffset: Duration(minutes: zone),
    );
    final base = DateTime(2026, 9, 4);
    expect(_deltaSeconds(ours, ref.fajr, base, 'fajr'), 0);
    expect(_deltaSeconds(ours, ref.isha, base, 'isha'), 0);
  });
}
