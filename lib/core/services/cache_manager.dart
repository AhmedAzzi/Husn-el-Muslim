import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:geolocator/geolocator.dart';

class CacheManager {
  static const String _prayerTimesKey = 'cached_prayer_times_v2';
  static const String _locationTimestampKey = 'location_timestamp';

  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _prefs = SharedPrefsCache.instance;
      _isInitialized = true;
    } catch (e) {
      // Handle SharedPreferences initialization error if needed
      _isInitialized = false;
    }
  }

  // --- Location Caching ---

  Future<void> cacheLocation(Position position) async {
    if (!_isInitialized) await init();
    if (_prefs == null) return;

    await _prefs!.setDouble('lat', position.latitude);
    await _prefs!.setDouble('lon', position.longitude);
    await _prefs!
        .setInt(_locationTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Position? getCachedLocation({Duration maxAge = const Duration(minutes: 30)}) {
    if (!_isInitialized || _prefs == null) return null;

    final lat = _prefs!.getDouble('lat');
    final lon = _prefs!.getDouble('lon');
    final timestamp = _prefs!.getInt(_locationTimestampKey);

    if (lat == null || lon == null || timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cacheTime) > maxAge) {
      return null; // Cache expired
    }

    return Position(
      latitude: lat,
      longitude: lon,
      timestamp: cacheTime,
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  // --- Prayer Times Caching ---

  Future<void> cacheWeekPrayerTimes(Map<String, dynamic> weekData) async {
    if (!_isInitialized) await init();
    if (_prefs == null) return;

    await _prefs!.setString(_prayerTimesKey, jsonEncode(weekData));
  }

  Map<String, dynamic>? getCachedWeekPrayerTimes() {
    if (!_isInitialized || _prefs == null) return null;

    final data = _prefs!.getString(_prayerTimesKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    if (!_isInitialized) await init();
    if (_prefs == null) return;

    await _prefs!.remove(_prayerTimesKey);
    await _prefs!.remove(_locationTimestampKey);
  }
}
