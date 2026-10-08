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

  // Batch 2 (perf-only): memoize the week-prayer decode. The blob is read
  // 1-5x per calculation/summary pass; re-parsing the same string is pure
  // waste. Keyed on the exact prefs string, so any write (here or elsewhere)
  // is picked up automatically. Same map content as a fresh decode.
  String? _memoWeekRaw;
  Map<String, dynamic>? _memoWeekDecoded;

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

    // Encode once and write-through the memo (callers mutate the map they
    // got from the getter before writing it back, so storing the reference
    // keeps the memo consistent with prefs by construction).
    final raw = jsonEncode(weekData);
    await _prefs!.setString(_prayerTimesKey, raw);
    _memoWeekRaw = raw;
    _memoWeekDecoded = weekData;
  }

  Map<String, dynamic>? getCachedWeekPrayerTimes() {
    if (!_isInitialized || _prefs == null) return null;

    final data = _prefs!.getString(_prayerTimesKey);
    if (data == null) {
      _memoWeekRaw = null;
      _memoWeekDecoded = null;
      return null;
    }
    if (data == _memoWeekRaw && _memoWeekDecoded != null) {
      return _memoWeekDecoded;
    }
    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      _memoWeekRaw = data;
      _memoWeekDecoded = decoded;
      return decoded;
    } catch (e) {
      _memoWeekRaw = null;
      _memoWeekDecoded = null;
      return null;
    }
  }

  Future<void> clearCache() async {
    if (!_isInitialized) await init();
    if (_prefs == null) return;

    await _prefs!.remove(_prayerTimesKey);
    await _prefs!.remove(_locationTimestampKey);
    _memoWeekRaw = null;
    _memoWeekDecoded = null;
  }
}
