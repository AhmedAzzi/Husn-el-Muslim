import 'dart:math';

import 'package:adhan/adhan.dart';

/// Offline Qibla math. Bearing comes from the already-vetted `adhan` package
/// ([Qibla.direction] — pure great-circle math, no network). Heading is a
/// tilt-compensated compass derived from the accelerometer (gravity) +
/// magnetometer streams, so no extra plugin is needed beyond `sensors_plus`.
class QiblaService {
  QiblaService._();

  /// Qibla bearing in compass degrees (0–360, clockwise from north).
  static double bearing(double latitude, double longitude) {
    return Qibla(Coordinates(latitude, longitude)).direction;
  }

  /// Haversine distance to the Kaaba in kilometers.
  static double distanceKm(double latitude, double longitude) {
    const kaabaLat = 21.4225241;
    const kaabaLon = 39.8261818;
    const r = 6371.0;
    final dLat = _rad(latitude - kaabaLat);
    final dLon = _rad(longitude - kaabaLon);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(kaabaLat)) *
            cos(_rad(latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(a.clamp(0.0, 1.0)));
  }

  /// Device heading in compass degrees from raw sensor vectors.
  ///
  /// [a] accelerometer (gravity), [m] magnetometer — any units, normalized
  /// internally. Returns null when the vectors are degenerate (free-fall,
  /// zero field) so the UI can show "unavailable" instead of a fake heading.
  static double? heading(
      double ax, double ay, double az, double mx, double my, double mz) {
    final aLen = sqrt(ax * ax + ay * ay + az * az);
    final mLen = sqrt(mx * mx + my * my + mz * mz);
    if (aLen < 0.1 || mLen < 0.1) return null;
    final ux = ax / aLen, uy = ay / aLen, uz = az / aLen;

    // East = normalize(m × U).
    var ex = my * uz - mz * uy;
    var ey = mz * ux - mx * uz;
    var ez = mx * uy - my * ux;
    final eLen = sqrt(ex * ex + ey * ey + ez * ez);
    if (eLen < 1e-6) return null; // device vertical / magnetic pole edge case
    ex /= eLen;
    ey /= eLen;
    ez /= eLen;

    // North = U × East. Only its Y component matters below (device Y axis
    // is (0,1,0) in device coordinates), so skip the full vector.
    final ny = uz * ex - ux * ez;

    final h = atan2(ey, ny) * 180 / pi;
    return (h + 360) % 360;
  }

  /// Exponential smoothing on a circular quantity (handles 359°→0° wrap).
  static double smoothHeading(double previous, double next, double alpha) {
    final diff = ((next - previous + 540) % 360) - 180;
    return (previous + diff * alpha + 360) % 360;
  }

  /// Signed turn to face the Qibla: negative = turn left, positive = right.
  static double turnTo(double bearingDeg, double headingDeg) {
    return ((bearingDeg - headingDeg + 540) % 360) - 180;
  }

  static double _rad(double d) => d * pi / 180;
}
