import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/prayer_times/data/prayer_time.dart';

/// Parses the compact offline bundle format produced by
/// `tool/fetch_mosques.py`:
/// `{"v":1,"list":[[slug,name,city,lat,lng],...]}`.
/// Pure function (no I/O) so it is cheaply unit-tested.
List<MosquePoint> parseMosqueBundle(String jsonText) {
  final dynamic data = jsonDecode(jsonText);
  final dynamic list = data is Map ? data['list'] : null;
  if (list is! List) return [];
  final out = <MosquePoint>[];
  for (final e in list) {
    if (e is! List || e.length < 5) continue;
    final slug = e[0]?.toString() ?? '';
    if (slug.isEmpty) continue;
    final lat = (e[3] as num?)?.toDouble() ?? 0;
    final lng = (e[4] as num?)?.toDouble() ?? 0;
    if (lat == 0 && lng == 0) continue;
    out.add(MosquePoint(
      slug: slug,
      name: e[1]?.toString() ?? '',
      city: e[2]?.toString() ?? '',
      latitude: lat,
      longitude: lng,
    ));
  }
  return out;
}

/// Offline mosque bundles shipped in `assets/mosques/{CODE}.json`
/// (15 countries, ~1.7 MB total for ~15k mosques).
///
/// Map screens render instantly from these with zero network: loading only
/// ever hits the network for a single mosque's prayer schedule, or when the
/// user taps refresh.
class MosqueBundle {
  static final Map<String, List<MosquePoint>> _mem = {};

  /// Country codes shipped in the app bundle.
  static const Set<String> bundledCodes = {
    'DZ', 'SA', 'EG', 'MA', 'TN', 'AE', 'FR',
    'GB', 'TR', 'DE', 'CA', 'US', 'ES', 'BE', 'IT',
  };

  static Future<List<MosquePoint>> load(String countryCode) async {
    final code = countryCode.toUpperCase();
    final hit = _mem[code];
    if (hit != null) return hit;
    final text = await rootBundle.loadString('assets/mosques/$code.json');
    final list = parseMosqueBundle(text);
    if (list.isEmpty) throw Exception('Empty mosque bundle for $code');
    _mem[code] = list;
    return list;
  }

  /// Test-only hook to reset the in-memory cache.
  static void clearMemoryCache() => _mem.clear();
}

/// A mosque returned by the country listing, with lat/lng for the map.
class MosquePoint {
  const MosquePoint({
    required this.slug,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.address,
    this.proximityMeters = 0,
  });

  final String slug;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final String? address;
  final double proximityMeters;

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'city': city,
        'lat': latitude,
        'lng': longitude,
        'address': address,
      };

  /// Returns a copy with an updated proximity (used to annotate distance
  /// from the user's location before displaying).
  MosquePoint copyWithProximity(double meters) => MosquePoint(
        slug: slug,
        name: name,
        city: city,
        latitude: latitude,
        longitude: longitude,
        address: address,
        proximityMeters: meters,
      );

  factory MosquePoint.fromJson(Map<String, dynamic> j) => MosquePoint(
        slug: j['slug'] as String? ?? '',
        name: j['name'] as String? ?? '',
        city: j['city'] as String? ?? '',
        latitude: (j['lat'] as num?)?.toDouble() ?? 0,
        longitude: (j['lng'] as num?)?.toDouble() ?? 0,
        address: j['address'] as String?,
      );

  /// Parses a mosque entry from the Mawaqit `/mosque/search` response,
  /// which uses `latitude`/`longitude`, `slug`, `name` and `localisation`.
  factory MosquePoint.fromSearch(Map<String, dynamic> j) => MosquePoint(
        slug: j['slug'] as String? ?? '',
        name: j['name'] as String? ?? '',
        city: '',
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
        address: (j['localisation'] as String?) ?? (j['label'] as String?),
        proximityMeters: (j['proximity'] as num?)?.toDouble() ?? 0,
      );
}

/// The parsed prayer schedule for a single mosque.
class MosqueSchedule {
  const MosqueSchedule({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.jumua,
    this.jumuaAsDuhr = false,
    this.calendar,
    this.iqamaCalendar,
  });

  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String? jumua;
  final bool jumuaAsDuhr;
  final List<dynamic>? calendar;
  final List<dynamic>? iqamaCalendar;

  Map<String, dynamic> toJson() => {
        'fajr': fajr,
        'sunrise': sunrise,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'jumua': jumua,
        'jumuaAsDuhr': jumuaAsDuhr,
        'calendar': calendar,
        'iqamaCalendar': iqamaCalendar,
        'cachedAt': DateTime.now().toIso8601String(),
      };

  factory MosqueSchedule.fromJson(Map<String, dynamic> j) => MosqueSchedule(
        fajr: j['fajr'] as String? ?? '',
        sunrise: j['sunrise'] as String? ?? '',
        dhuhr: j['dhuhr'] as String? ?? '',
        asr: j['asr'] as String? ?? '',
        maghrib: j['maghrib'] as String? ?? '',
        isha: j['isha'] as String? ?? '',
        jumua: j['jumua'] as String?,
        jumuaAsDuhr: j['jumuaAsDuhr'] == true,
        calendar: j['calendar'] as List<dynamic>?,
        iqamaCalendar: j['iqamaCalendar'] as List<dynamic>?,
      );

  /// Converts this mosque schedule into a full list of [PrayerTime] objects for [date].
  /// Also computes the night thirds (First Third, Midnight, Last Third) relative to Fajr and Maghrib.
  /// When iqamaCalendar is available, computes iqama times (adhan + offset).
  List<PrayerTime> toPrayerTimes(DateTime date) {
    String dayFajr = fajr;
    String daySunrise = sunrise;
    String dayDhuhr = dhuhr;
    String dayAsr = asr;
    String dayMaghrib = maghrib;
    String dayIsha = isha;

    // If full yearly calendar is available, use date-specific times
    if (calendar != null && calendar!.length >= date.month) {
      final monthData = calendar![date.month - 1];
      if (monthData is Map) {
        final dayList = monthData[date.day.toString()] as List?;
        if (dayList != null && dayList.length >= 6) {
          dayFajr = dayList[0].toString();
          daySunrise = dayList[1].toString();
          dayDhuhr = dayList[2].toString();
          dayAsr = dayList[3].toString();
          dayMaghrib = dayList[4].toString();
          dayIsha = dayList[5].toString();
        }
      }
    }

    // Parse iqama offsets from iqamaCalendar (5 values: Fajr, Dhuhr, Asr, Maghrib, Isha)
    List<int> iqamaOffsets = [];
    if (iqamaCalendar != null && iqamaCalendar!.length >= date.month) {
      final iqamaMonthData = iqamaCalendar![date.month - 1];
      if (iqamaMonthData is Map) {
        final iqamaDayList = iqamaMonthData[date.day.toString()] as List?;
        if (iqamaDayList != null) {
          iqamaOffsets = iqamaDayList.map((e) {
            final s = e.toString().trim();
            return int.tryParse(s) ?? 0;
          }).toList();
        }
      }
    }

    DateTime parseTime(String timeStr, {int dayOffset = 0}) {
      final parts = timeStr.split(':');
      final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final d = date.add(Duration(days: dayOffset));
      return DateTime(d.year, d.month, d.day, hour, minute, 0);
    }

    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final fajrDt = parseTime(dayFajr);
    final sunriseDt = parseTime(daySunrise);
    final dhuhrDt = parseTime(dayDhuhr);
    final asrDt = parseTime(dayAsr);
    final maghribDt = parseTime(dayMaghrib);
    final ishaDt = parseTime(dayIsha);

    // Helper to get iqama time for a given adhan DateTime and offset index
    DateTime? getIqama(DateTime adhanTime, int offsetIndex) {
      if (offsetIndex < iqamaOffsets.length) {
        final offsetMin = iqamaOffsets[offsetIndex];
        if (offsetMin != 0) {
          return adhanTime.add(Duration(minutes: offsetMin));
        }
      }
      return null;
    }

    final mainPrayers = <PrayerTime>[
      PrayerTime(name: 'Fajr', time: fajrDt, time24h: fmt(fajrDt), iqamaTime: getIqama(fajrDt, 0)),
      PrayerTime(name: 'Sunrise', time: sunriseDt, time24h: fmt(sunriseDt)),
      PrayerTime(name: 'Dhuhr', time: dhuhrDt, time24h: fmt(dhuhrDt), iqamaTime: getIqama(dhuhrDt, 1)),
      PrayerTime(name: 'Asr', time: asrDt, time24h: fmt(asrDt), iqamaTime: getIqama(asrDt, 2)),
      PrayerTime(name: 'Maghrib', time: maghribDt, time24h: fmt(maghribDt), iqamaTime: getIqama(maghribDt, 3)),
      PrayerTime(name: 'Isha', time: ishaDt, time24h: fmt(ishaDt), iqamaTime: getIqama(ishaDt, 4)),
    ];

    mainPrayers.sort((a, b) => a.time.compareTo(b.time));

    // Calculate night portions (First Third, Midnight, Last Third)
    final now = DateTime.now();
    DateTime refMaghrib;
    DateTime refFajr;

    if (now.isBefore(fajrDt)) {
      refMaghrib = parseTime(dayMaghrib, dayOffset: -1);
      refFajr = fajrDt;
    } else {
      refMaghrib = maghribDt;
      refFajr = parseTime(dayFajr, dayOffset: 1);
    }

    final nightDuration = refFajr.difference(refMaghrib);
    final thirdDuration =
        Duration(seconds: (nightDuration.inSeconds / 3).round());
    final halfDuration =
        Duration(seconds: (nightDuration.inSeconds / 2).round());

    final firstThirdDt = refMaghrib.add(thirdDuration);
    final midnightDt = refMaghrib.add(halfDuration);
    final lastThirdDt = refMaghrib.add(thirdDuration * 2);

    final nightPrayers = <PrayerTime>[
      PrayerTime(
          name: 'First Third', time: firstThirdDt, time24h: fmt(firstThirdDt)),
      PrayerTime(
          name: 'Midnight', time: midnightDt, time24h: fmt(midnightDt)),
      PrayerTime(
          name: 'Last Third', time: lastThirdDt, time24h: fmt(lastThirdDt)),
    ];

    return [...mainPrayers, ...nightPrayers];
  }
}

/// Simple offline cache backed by shared_preferences, keyed by mosque slug /
/// country code. Holds the (JSON-encoded) mosque list and per-mosque schedules.
class OfflineCache {
  static const _mosquesKey = 'cache_mosques_';
  static const _scheduleKey = 'cache_schedule_v2_';
  static const _activeMosqueKey = 'active_mosque_point';
  
  // Cache TTL constants
  static const Duration _mosqueListTtl = Duration(days: 7);
  static const Duration _scheduleTtl = Duration(days: 1);
  static const int _maxCountries = 10; // Limit number of cached countries

  /// Returns cached mosque list for [countryCode], or null if none or expired.
  static Future<List<MosquePoint>?> getMosques(String countryCode) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_mosquesKey + countryCode.toUpperCase());
    if (raw == null) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(data['cachedAt'] as String? ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt) > _mosqueListTtl) {
        await p.remove(_mosquesKey + countryCode.toUpperCase());
        return null;
      }
      return (data['mosques'] as List? ?? [])
          .whereType<Map>()
          .map((m) => MosquePoint.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveMosques(
      String countryCode, List<MosquePoint> mosques) async {
    final p = await SharedPreferences.getInstance();
    // Enforce max countries limit by removing oldest if needed
    await _enforceMaxCountries(p);
    await p.setString(_mosquesKey + countryCode.toUpperCase(),
        jsonEncode({'cachedAt': DateTime.now().toIso8601String(), 'mosques': mosques.map((m) => m.toJson()).toList()}));
  }

  /// Enforces a maximum number of cached countries by removing the oldest.
  static Future<void> _enforceMaxCountries(SharedPreferences p) async {
    final keys = p.getKeys().where((k) => k.startsWith(_mosquesKey)).toList();
    if (keys.length >= _maxCountries) {
      // Parse timestamps and find oldest
      DateTime? oldestTime;
      String? oldestKey;
      for (final key in keys) {
        final raw = p.getString(key);
        if (raw != null) {
          try {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            final cachedAt = DateTime.tryParse(data['cachedAt'] as String? ?? '');
            if (cachedAt != null && (oldestTime == null || cachedAt.isBefore(oldestTime))) {
              oldestTime = cachedAt;
              oldestKey = key;
            }
          } catch (_) {}
        }
      }
      if (oldestKey != null) {
        await p.remove(oldestKey);
      }
    }
  }

  /// Returns cached schedule for [slug], or null if none, expired, or corrupt.
  static Future<MosqueSchedule?> getSchedule(String slug) async {
    final p = await SharedPreferences.getInstance();
    // Clean up any legacy pre-v2 cache for this slug
    if (p.containsKey('cache_schedule_$slug')) {
      await p.remove('cache_schedule_$slug');
    }
    final raw = p.getString(_scheduleKey + slug);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(data['cachedAt'] as String? ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt) > _scheduleTtl) {
        await p.remove(_scheduleKey + slug);
        return null;
      }
      final s = MosqueSchedule.fromJson(
          (data['schedule'] as Map<String, dynamic>? ?? data));
      // Validate that the schedule is complete and has no shifted/missing times
      if (s.fajr.isEmpty ||
          s.dhuhr.isEmpty ||
          s.maghrib.isEmpty ||
          s.isha.isEmpty) {
        await p.remove(_scheduleKey + slug);
        return null;
      }
      return s;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSchedule(String slug, MosqueSchedule s) async {
    final p = await SharedPreferences.getInstance();
    // Remove legacy key if still present
    await p.remove('cache_schedule_$slug');
    await p.setString(_scheduleKey + slug, jsonEncode({
      'cachedAt': DateTime.now().toIso8601String(),
      'schedule': s.toJson(),
    }));
  }

  /// Saves the active/selected mosque point.
  static Future<void> saveActiveMosque(MosquePoint m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_activeMosqueKey, jsonEncode(m.toJson()));
  }

  /// Gets the currently selected active mosque, or null if none selected.
  static Future<MosquePoint?> getActiveMosque() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_activeMosqueKey);
    if (raw == null) return null;
    try {
      return MosquePoint.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// Your own Mawaqit client - direct HTTP calls, no third-party API service.
class MawaqitApi {
  static const _base = 'https://mawaqit.net';

  final http.Client _http;
  MawaqitApi({http.Client? client}) : _http = client ?? http.Client();

  /// Load the mosque list for a country, fastest source first:
  /// in-memory → fresh user-refreshed prefs cache → offline asset bundle.
  ///
  /// The network is hit ONLY on explicit [forceRefresh] (or for a country
  /// with no shipped bundle). Map screens therefore open instantly offline;
  /// loading only ever requests a single mosque's prayer schedule.
  ///
  /// When offline and nothing is cached or bundled, throws so the UI can
  /// show a message.
  Future<List<MosquePoint>> mosquesByCountry(String countryCode,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await OfflineCache.getMosques(countryCode);
      if (cached != null) return cached;
      try {
        return await MosqueBundle.load(countryCode);
      } catch (_) {
        // No bundle for this code: fall through to the network attempt below.
      }
    }
    final r = await _http
        .get(Uri.parse(
            '$_base/api/2.0/mosque/map/${countryCode.toUpperCase()}'))
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      // Fall back to cache if the network request failed.
      final cached = await OfflineCache.getMosques(countryCode);
      if (cached != null) return cached;
      throw Exception('HTTP ${r.statusCode}');
    }
    final raw = jsonDecode(r.body);
    final list = raw is List ? raw : <dynamic>[];
    final mosques = list
        .whereType<Map>()
        .map((m) => MosquePoint.fromJson(m.cast<String, dynamic>()))
        .where((m) => m.slug.isNotEmpty)
        .toList();
    await OfflineCache.saveMosques(countryCode, mosques);
    return mosques;
  }

  /// Fetch one mosque's prayer times from its public page (by slug).
  ///
  /// Returns the cached schedule first if [forceRefresh] is false; refreshes
  /// from the network and updates the cache when online. Falls back to cache
  /// when offline.
  Future<MosqueSchedule> scheduleBySlug(String slug,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await OfflineCache.getSchedule(slug);
      if (cached != null) return cached;
    }
    final r = await _http
        .get(Uri.parse('$_base/fr/$slug'))
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      final cached = await OfflineCache.getSchedule(slug);
      if (cached != null) return cached;
      throw Exception('HTTP ${r.statusCode}');
    }
    final m = RegExp(r'confData\s*=\s*(\{.*?\})\s*;', dotAll: true)
        .firstMatch(r.body);
    if (m == null) {
      final cached = await OfflineCache.getSchedule(slug);
      if (cached != null) return cached;
      throw Exception('No schedule for $slug');
    }
    final c = jsonDecode(m.group(1)!) as Map<String, dynamic>;
    final t = (c['times'] as List?)?.cast<String>() ?? const <String>[];
    String g(int i) => t.length > i ? t[i] : '';
    final String shuruq =
        (c['shuruq'] as String?) ?? (c['sunrise'] as String?) ?? '';

    String fajr = '';
    String sunrise = '';
    String dhuhr = '';
    String asr = '';
    String maghrib = '';
    String isha = '';

    if (t.length == 5) {
      // Standard Mawaqit times array: [Fajr, Dhuhr, Asr, Maghrib, Isha]
      // Shuruq is provided in the separate 'shuruq' field.
      fajr = g(0);
      sunrise = shuruq;
      dhuhr = g(1);
      asr = g(2);
      maghrib = g(3);
      isha = g(4);
    } else if (t.length >= 6) {
      // 6-element times array: [Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha]
      fajr = g(0);
      sunrise = g(1).isNotEmpty ? g(1) : shuruq;
      dhuhr = g(2);
      asr = g(3);
      maghrib = g(4);
      isha = g(5);
    } else {
      fajr = g(0);
      sunrise = shuruq;
      dhuhr = g(1);
      asr = g(2);
      maghrib = g(3);
      isha = g(4);
    }

    final calendar = c['calendar'] as List<dynamic>?;
    final iqamaCalendar = c['iqamaCalendar'] as List<dynamic>?;

    final schedule = MosqueSchedule(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      jumua: c['jumua'] as String?,
      jumuaAsDuhr: c['jumuaAsDuhr'] == true,
      calendar: calendar,
      iqamaCalendar: iqamaCalendar,
    );
    await OfflineCache.saveSchedule(slug, schedule);
    return schedule;
  }

  /// Search mosques near a coordinate, ordered by proximity.
  /// Returns a list of [MosquePoint] sorted nearest-first.
  Future<List<MosquePoint>> searchNearby(double lat, double lon) async {
    final r = await _http
        .get(Uri.parse(
            '$_base/api/2.0/mosque/search?lat=$lat&lon=$lon&page=0'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final raw = jsonDecode(r.body);
    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map>()
        .map((m) => MosquePoint.fromSearch(m.cast<String, dynamic>()))
        .where((m) => m.slug.isNotEmpty)
        .toList();
  }

  void dispose() => _http.close();
}
