import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/qibla/services/qibla_service.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Offline Qibla compass. Bearing is computed locally from the prayer location
/// (no API). Heading comes from the accelerometer + magnetometer streams.
///
/// Honest failure states — never a fake compass:
/// - location denied/unavailable → guidance + retry (falls back to the cached
///   prayer coordinates when they exist)
/// - sensors missing/silent for 5s → "compass unavailable" message
/// - magnetic interference → calibration hint (figure-8 motion)
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _bearing;
  double? _distanceKm;
  double? _heading;
  String? _error;
  bool _locating = true;
  bool _sensorsDead = false;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  // Low-pass gravity estimate + latest magnetic vector.
  double _gx = 0, _gy = 0, _gz = 9.81;
  double _mx = 0, _my = 0, _mz = 0;
  bool _hasMag = false;
  Timer? _sensorTimeout;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    double? lat;
    double? lon;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final after = await Geolocator.checkPermission();
      if (after == LocationPermission.whileInUse ||
          after == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 10));
        lat = pos.latitude;
        lon = pos.longitude;
      }
    } on TimeoutException {
      // Fall through to cached coordinates.
    } catch (_) {
      // Fall through to cached coordinates.
    }
    lat ??= PrayerTimesLogic().lat;
    lon ??= PrayerTimesLogic().lon;

    if (!mounted) return;
    if (lat == 0 && lon == 0) {
      setState(() {
        _locating = false;
        _error = AppLocalizations.of(context)!.qiblaNoLocation;
      });
      return;
    }
    setState(() {
      _bearing = QiblaService.bearing(lat!, lon!);
      _distanceKm = QiblaService.distanceKm(lat, lon);
      _locating = false;
    });
    _listenSensors();
  }

  void _listenSensors() {
    _sensorTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted && _heading == null) {
        setState(() => _sensorsDead = true);
      }
    });
    _accelSub = accelerometerEventStream().listen((e) {
      const alpha = 0.8;
      _gx = alpha * _gx + (1 - alpha) * e.x;
      _gy = alpha * _gy + (1 - alpha) * e.y;
      _gz = alpha * _gz + (1 - alpha) * e.z;
      _updateHeading();
    }, onError: (_) => _sensorFailed());
    _magSub = magnetometerEventStream().listen((e) {
      _mx = e.x;
      _my = e.y;
      _mz = e.z;
      _hasMag = true;
      _updateHeading();
    }, onError: (_) => _sensorFailed());
  }

  void _updateHeading() {
    if (!_hasMag || !mounted) return;
    final h = QiblaService.heading(_gx, _gy, _gz, _mx, _my, _mz);
    if (h == null) return;
    setState(() {
      _heading =
          _heading == null ? h : QiblaService.smoothHeading(_heading!, h, 0.15);
      _sensorsDead = false;
    });
    _sensorTimeout?.cancel();
  }

  void _sensorFailed() {
    if (mounted) setState(() => _sensorsDead = true);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _sensorTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF14141C) : const Color(0xFFF7F7FA),
        appBar: AppBar(
          title: Text(loc.qiblaTitle,
              style: const TextStyle(
                  fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Get.back()),
        ),
        body: _locating
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _message(_error!, Icons.location_off_rounded, isDark)
                : _sensorsDead && _heading == null
                    ? _message(
                        loc.qiblaNoSensor,
                        Icons.compass_calibration_rounded,
                        isDark,
                        extra: _bearingInfo(isDark, loc))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _compass(isDark, loc),
                            const SizedBox(height: 24),
                            _bearingInfo(isDark, loc),
                            const SizedBox(height: 16),
                            Text(
                              loc.qiblaCalibrate,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Amiri',
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54),
                            ),
                          ],
                        ),
                      ),
      );
  }

  Widget _bearingInfo(bool isDark, AppLocalizations loc) {
    final turn = (_bearing != null && _heading != null)
        ? QiblaService.turnTo(_bearing!, _heading!)
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(loc.qiblaBearing(_bearing?.toStringAsFixed(1) ?? '…'),
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          if (_distanceKm != null)
            Text(loc.qiblaDistance(_distanceKm!.toStringAsFixed(0)),
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 16)),
          if (turn != null)
            Text(
                turn.abs() < 3
                    ? loc.qiblaFacing
                    : loc.qiblaTurn(turn.abs().toStringAsFixed(0),
                        turn > 0 ? loc.qiblaRight : loc.qiblaLeft),
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD64463))),
        ],
      ),
    );
  }

  Widget _compass(bool isDark, AppLocalizations loc) {
    final rotation = (_bearing != null && _heading != null)
        ? (_bearing! - _heading!) * pi / 180
        : 0.0;
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        border: Border.all(color: const Color(0xFFC2A36B), width: 3),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(loc.qiblaNorth,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),          Transform.rotate(
            angle: rotation,
            child: const Icon(Icons.navigation_rounded,
                size: 120, color: Color(0xFFD64463)),
          ),
          Positioned(
            bottom: 18,
            child: Text(
                _heading == null
                    ? '…'
                    : '${_heading!.toStringAsFixed(0)}°',
                style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _message(String text, IconData icon, bool isDark, {Widget? extra}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 17)),
            if (extra != null) ...[const SizedBox(height: 16), extra],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _locating = true;
                  _error = null;
                });
                _init();
              },
              child: Text(AppLocalizations.of(context)!.qiblaRetry,
                  style: const TextStyle(fontFamily: 'Amiri')),
            ),
          ],
        ),
      ),
    );
  }
}

