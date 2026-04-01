import 'dart:math';

class PrayerCalculationEngine {
  // All math functions copied EXACTLY from original prayer_times_logic.dart

  static Map<String, Map<String, int>> computeMultipleDays(Map<String, dynamic> params) {
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
    final Map<String, int> prayerOffsets = Map<String, int>.from(params['prayerOffsets']);
    final String asrMethod = params['asrMethod'];
    final String angles = params['angles'];
    final double customFajrAngle = params['customFajrAngle'];
    final double customIshaAngle = params['customIshaAngle'];
    final jd = _toJulianDay(year, month, day);
    final sunCoords = _sunCoords(jd);
    final latRad = _deg2rad(lat);
    final noonUTC = _solarNoonUTCMinutes(lon, sunCoords['eoT']!);

    // Get local timezone offset in minutes.
    // Base timezone offset from the system
    int offset = DateTime(year, month, day).timeZoneOffset.inMinutes;
    // Add manual corrections (like DST)
    offset += (dstEnabled ? 60 : 0);

    final opts = _getOptions(angles, customFajrAngle, customIshaAngle, asrMethod);
    final fajrAlt = _deg2rad(-opts['fajrAngle']!);
    final ishaAlt = _deg2rad(-opts['ishaAngle']!);
    final sunriseAlt = _deg2rad(-0.833);

    final hf = _hourAngleForAltitude(latRad, sunCoords['decl']!, fajrAlt);
    final hs = _hourAngleForAltitude(latRad, sunCoords['decl']!, sunriseAlt);
    final hi = _hourAngleForAltitude(latRad, sunCoords['decl']!, ishaAlt);
    final ha = _hourAngleForAltitude(latRad, sunCoords['decl']!,
        _asrAltitude(latRad, sunCoords['decl']!, opts['asrFactor']!));

    double toMin(double r) => _rad2deg(r) * 4;

    final int fajrSecs = ((noonUTC + offset - toMin(hf)) * 60 + (prayerOffsets['Fajr'] ?? 0)).round();
    final int sunriseSecs = ((noonUTC + offset - toMin(hs)) * 60 + (prayerOffsets['Sunrise'] ?? 0)).round();
    // Dhuhr: Use solar noon + 1 minute safety buffer (Zawal)
    final int dhuhrSecs = ((noonUTC + offset) * 60 + 60 + (prayerOffsets['Dhuhr'] ?? 0)).round();
    final int asrSecs = ((noonUTC + offset + toMin(ha)) * 60 + (prayerOffsets['Asr'] ?? 0)).round();
    final int maghribSecs = ((noonUTC + offset + toMin(hs)) * 60 + (prayerOffsets['Maghrib'] ?? 0)).round();
    
    // Isha special case for Umm al-Qura (Makkah): Fixed 90 minutes after Maghrib
    int ishaSecs;
    if (angles == 'makkah') {
      ishaSecs = maghribSecs + (90 * 60);
    } else {
      ishaSecs = ((noonUTC + offset + toMin(hi)) * 60 + (prayerOffsets['Isha'] ?? 0)).round();
    }

    return {
      'fajr': fajrSecs,
      'sunrise': sunriseSecs,
      'dhuhr': dhuhrSecs,
      'asr': asrSecs,
      'maghrib': maghribSecs,
      'isha': ishaSecs,
    };
  }

  static Map<String, double> _getOptions(String angles, double customFajrAngle, double customIshaAngle, String asrMethod) {
    double fajr = 18.0;
    double isha = 17.0;

    switch (angles) {
      case 'mwl':
        fajr = 18.0;
        isha = 17.0;
        break;
      case 'egypt':
        fajr = 19.5;
        isha = 17.5;
        break;
      case 'makkah':
        fajr = 18.5;
        isha = 18.5;
        break;
      case 'isna':
        fajr = 15.0;
        isha = 15.0;
        break;
      case 'karachi':
        fajr = 18.0;
        isha = 18.0;
        break;
      case 'custom':
        fajr = customFajrAngle;
        isha = customIshaAngle;
        break;
      default:
        fajr = 18.0;
        isha = 17.0;
    }

    return {
      'fajrAngle': fajr,
      'ishaAngle': isha,
      'asrFactor': asrMethod == 'hanafi' ? 2.0 : 1.0,
    };
  }

  static double _toJulianDay(int y, int m, int d) {
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final A = (y / 100).floor();
    final B = 2 - A + (A / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        B -
        1524.5;
  }

  static Map<String, double> _sunCoords(double jd) {
    final t = (jd - 2451545.0) / 36525;
    final l0 = (280.46646 + 36000.76983 * t + 0.0003032 * t * t) % 360;
    final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
    final e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
    final mRad = _deg2rad(m);
    final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(mRad) +
        (0.019993 - 0.000101 * t) * sin(2 * mRad) +
        0.000289 * sin(3 * mRad);
    final trueLong = l0 + c;
    final omega = 125.04 - 1934.136 * t;
    final lambda = trueLong - 0.00569 - 0.00478 * sin(_deg2rad(omega));
    final epsilon0 = 23.439291 -
        0.0130042 * t -
        0.0000001639 * t * t +
        0.0000005036 * t * t * t;
    final epsilon = epsilon0 + 0.00256 * cos(_deg2rad(omega));
    final lambdaRad = _deg2rad(lambda);
    final epsRad = _deg2rad(epsilon);
    final decl = asin(sin(epsRad) * sin(lambdaRad));

    final valY = tan(epsRad / 2);
    final y2 = valY * valY;
    final sin2L0 = sin(2 * _deg2rad(l0));
    final sinM = sin(mRad);
    final cos2L0 = cos(2 * _deg2rad(l0));
    final sin4L0 = sin(4 * _deg2rad(l0));
    final sin2M = sin(2 * mRad);
    final eoT = 4 *
        _rad2deg(y2 * sin2L0 -
            2 * e * sinM +
            4 * e * y2 * sinM * cos2L0 -
            0.5 * y2 * y2 * sin4L0 -
            1.25 * e * e * sin2M);

    return {'decl': decl, 'eoT': eoT};
  }

  static double _solarNoonUTCMinutes(double lon, double eoT) {
    return 720 - 4 * lon - eoT;
  }

  static double _hourAngleForAltitude(double latRad, double decl, double altitudeRad) {
    final cosH = (sin(altitudeRad) - sin(latRad) * sin(decl)) /
        (cos(latRad) * cos(decl));
    return acos(max(-1, min(1, cosH)));
  }

  static double _asrAltitude(double latRad, double decl, double f) {
    return atan(1 / (f + tan((latRad - decl).abs())));
  }

  static double _deg2rad(double d) => d * pi / 180;
  static double _rad2deg(double r) => r * 180 / pi;
}
