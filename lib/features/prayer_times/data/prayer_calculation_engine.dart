import 'package:adhan/adhan.dart';

/// Prayer-time calculation engine.
///
/// Delegates the astronomy to the battle-tested `adhan` package (same math
/// the app validates against) and only owns the app-specific layer on top:
/// device-zone/DST anchoring, user per-prayer offsets, Asr madhab, custom
/// angles, and the Umm al-Qura +90-minute Isha rule.
///
/// Contract (unchanged for all callers):
/// - input: params map `{year, month, day, lat, lon, dstEnabled,
///   prayerOffsets, asrMethod, angles, customFajrAngle, customIshaAngle}`
/// - output: seconds since local midnight per prayer.
///
/// Previously this file hand-rolled NOAA solar math with a single noon
/// snapshot, which biased morning/evening events in opposite directions
/// (up to ~±100s near equinoxes) and mis-implemented moonsighting seasonal
/// twilight. Delegation removes that whole bug class.
class PrayerCalculationEngine {
  static Map<String, Map<String, int>> computeMultipleDays(
      Map<String, dynamic> params) {
    final List<dynamic> dayParams = params['days'];
    final result = <String, Map<String, int>>{};
    for (final dp in dayParams) {
      final key = dp['key'] as String;
      // Also pass down non-date params if they aren't embedded in the day param
      final fullParams = Map<String, dynamic>.from(params);
      fullParams.addAll(Map<String, dynamic>.from(dp));
      result[key] = computeDayTimes(fullParams);
    }
    return result;
  }

  static Map<String, int> computeDayTimes(Map<String, dynamic> params) {
    final int year = params['year'];
    final int month = params['month'];
    final int day = params['day'];
    final double lat = params['lat'];
    final double lon = params['lon'];
    final bool dstEnabled = params['dstEnabled'] ?? false;
    final Map<String, int> prayerOffsets =
        Map<String, int>.from(params['prayerOffsets']);
    final String asrMethod = params['asrMethod'];
    final String angles = params['angles'];
    final double customFajrAngle = params['customFajrAngle'];
    final double customIshaAngle = params['customIshaAngle'];

    // The platform timezone offset already includes DST when active,
    // so we don't need to add manual offset that causes the +1 hour issue.
    // PrayerTimes constructor handles timezone and DST automatically.

    final calcs = _adhanMethod(angles).getParameters();
    if (angles == 'custom') {
      calcs.fajrAngle = customFajrAngle;
      calcs.ishaAngle = customIshaAngle;
    }
    calcs.madhab = asrMethod == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

    final times = PrayerTimes(
      Coordinates(lat, lon),
      DateComponents.from(DateTime(year, month, day)),
      calcs,
    );

    final midnight = DateTime(year, month, day);
    int secs(DateTime dt, String key) =>
        dt.difference(midnight).inSeconds + (prayerOffsets[key] ?? 0);

    final fajr = secs(times.fajr, 'Fajr');
    final sunrise = secs(times.sunrise, 'Sunrise');
    final dhuhr = secs(times.dhuhr, 'Dhuhr');
    final asr = secs(times.asr, 'Asr');
    final maghrib = secs(times.maghrib, 'Maghrib');

    // Umm al-Qura (Makkah) and Qatar: Isha is exactly Maghrib + 90 minutes.
    // Derived from the (offset-adjusted, minute-rounded) Maghrib so the
    // 90-minute invariant holds exactly.
    final isha = (angles == 'makkah' || angles == 'qatar')
        ? maghrib + (90 * 60)
        : secs(times.isha, 'Isha');

    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  /// Maps the app's method keys to the reference methods. Unknown keys fall
  /// back to Muslim World League (18°/17°, the historic default here).
  static CalculationMethod _adhanMethod(String angles) {
    switch (angles) {
      case 'mwl':
        return CalculationMethod.muslim_world_league;
      case 'egypt':
        return CalculationMethod.egyptian;
      case 'makkah':
        return CalculationMethod.umm_al_qura;
      case 'isna':
        return CalculationMethod.north_america;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'kuwait':
        return CalculationMethod.kuwait;
      case 'qatar':
        return CalculationMethod.qatar;
      case 'singapore':
        return CalculationMethod.singapore;
      case 'turkey':
        return CalculationMethod.turkey;
      case 'dubai':
        return CalculationMethod.dubai;
      case 'moonsighting':
        return CalculationMethod.moon_sighting_committee;
      case 'custom':
        return CalculationMethod.other;
      default:
        return CalculationMethod.muslim_world_league;
    }
  }
}
