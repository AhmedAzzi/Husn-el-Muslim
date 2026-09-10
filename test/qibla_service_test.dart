import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/features/qibla/services/qibla_service.dart';

void main() {
  group('QiblaService.bearing (offline, adhan reference)', () {
    test('Cairo faces south-east (~136°)', () {
      final b = QiblaService.bearing(30.0444, 31.2357);
      expect(b, greaterThan(130));
      expect(b, lessThan(142));
    });

    test('New York faces north-east (~58°)', () {
      final b = QiblaService.bearing(40.7128, -74.0060);
      expect(b, greaterThan(52));
      expect(b, lessThan(64));
    });

    test('Jakarta faces north-west (~295°)', () {
      final b = QiblaService.bearing(-6.2, 106.8);
      expect(b, greaterThan(288));
      expect(b, lessThan(302));
    });
  });

  group('QiblaService.heading (tilt-compensated compass)', () {
    test('flat phone, top toward north → 0°', () {
      // gravity +z, magnetic field with +y (north) component.
      final h = QiblaService.heading(0, 0, 9.81, 0, 20.0, -40.0)!;
      expect(h, closeTo(0, 1.0));
    });

    test('flat phone, top toward east → 90°', () {
      // North now along device −x.
      final h = QiblaService.heading(0, 0, 9.81, -20.0, 0, -40.0)!;
      expect(h, closeTo(90, 1.0));
    });

    test('degenerate vectors return null (no fake heading)', () {
      expect(QiblaService.heading(0, 0, 0, 0, 0, 0), isNull);
      expect(QiblaService.heading(0, 0, 9.81, 0, 0, 0), isNull);
    });
  });

  group('QiblaService.turnTo / smoothHeading', () {
    test('signed turn with wrap handling', () {
      expect(QiblaService.turnTo(140, 0), closeTo(140, 1e-9));
      expect(QiblaService.turnTo(10, 350), closeTo(20, 1e-9));
      expect(QiblaService.turnTo(350, 10), closeTo(-20, 1e-9));
    });

    test('smoothing crosses the 359°→0° wrap without spinning', () {
      final s = QiblaService.smoothHeading(359, 1, 0.5);
      expect(s, closeTo(0, 1.0));
    });
  });

  group('QiblaService.distanceKm', () {
    test('Cairo→Makkah is roughly 1 280 km', () {
      final d = QiblaService.distanceKm(30.0444, 31.2357);
      expect(d, greaterThan(1200));
      expect(d, lessThan(1360));
    });
  });
}
