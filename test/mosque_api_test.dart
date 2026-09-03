import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/prayer_times/data/mosque_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MawaqitApi', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('parses country mosque list', () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode([
              {
                'slug': 'masjid-hudaa-mombasa-80100-kenya',
                'name': 'Masjid Hudaa',
                'city': 'Mombasa',
                'lat': -4.05,
                'lng': 39.68,
              }
            ]),
            200,
          ));
      final api = MawaqitApi(client: mock);
      final list = await api.mosquesByCountry('KE');
      expect(list, hasLength(1));
      expect(list.single.slug, 'masjid-hudaa-mombasa-80100-kenya');
      expect(list.single.latitude, -4.05);
    });

    test('parses schedule from confData page (5 times with shuruq)', () async {
      final page = '''
<html><script>var confData = {"times":["04:30","12:30","15:45","18:20","19:30"],"shuruq":"05:50","jumua":"12:55","jumuaAsDuhr":true};</script></html>
''';
      final mock = MockClient((_) async => http.Response(page, 200));
      final api = MawaqitApi(client: mock);
      final s = await api.scheduleBySlug('some-mosque');
      expect(s.fajr, '04:30');
      expect(s.sunrise, '05:50');
      expect(s.dhuhr, '12:30');
      expect(s.asr, '15:45');
      expect(s.maghrib, '18:20');
      expect(s.isha, '19:30');
      expect(s.jumua, '12:55');
      expect(s.jumuaAsDuhr, isTrue);
    });

    test('throws on non-200', () async {
      final mock = MockClient((_) async => http.Response('', 500));
      final api = MawaqitApi(client: mock);
      expect(() => api.mosquesByCountry('DZ'), throwsException);
    });

    test('returns cached list when network fails (offline fallback)', () async {
      await OfflineCache.saveMosques('DZ', const [
        MosquePoint(
            slug: 'mosquee-x',
            name: 'X',
            city: 'Y',
            latitude: 1.0,
            longitude: 2.0),
      ]);
      final mock = MockClient((_) async => http.Response('', 500));
      final api = MawaqitApi(client: mock);
      final list = await api.mosquesByCountry('DZ');
      expect(list.single.slug, 'mosquee-x');
    });

    test('returns cached schedule when network fails (offline fallback)', () async {
      await OfflineCache.saveSchedule('mosquee-x', const MosqueSchedule(
          fajr: '05:00',
          sunrise: '06:00',
          dhuhr: '13:00',
          asr: '16:00',
          maghrib: '19:00',
          isha: '20:00',
          jumua: '13:00',
          jumuaAsDuhr: true));
      final mock = MockClient((_) async => http.Response('', 500));
      final api = MawaqitApi(client: mock);
      final s = await api.scheduleBySlug('mosquee-x');
      expect(s.fajr, '05:00');
      expect(s.jumuaAsDuhr, isTrue);
    });

    test('toPrayerTimes converts MosqueSchedule into PrayerTime list including night thirds', () {
      const s = MosqueSchedule(
        fajr: '05:15',
        sunrise: '06:40',
        dhuhr: '12:45',
        asr: '16:10',
        maghrib: '19:05',
        isha: '20:30',
      );
      final times = s.toPrayerTimes(DateTime(2026, 9, 1));
      expect(times, isNotEmpty);
      expect(times.any((p) => p.name == 'Fajr' && p.time24h == '05:15'), isTrue);
      expect(times.any((p) => p.name == 'Dhuhr' && p.time24h == '12:45'), isTrue);
      expect(times.any((p) => p.name == 'Maghrib' && p.time24h == '19:05'), isTrue);
      expect(times.any((p) => p.name == 'Last Third'), isTrue);
    });

    test('OfflineCache saves and loads active mosque', () async {
      const mosque = MosquePoint(
        slug: 'great-mosque-algiers',
        name: 'جامع الجزائر الكبير',
        city: 'الجزائر العاصمة',
        latitude: 36.73,
        longitude: 3.14,
      );
      await OfflineCache.saveActiveMosque(mosque);
      final loaded = await OfflineCache.getActiveMosque();
      expect(loaded, isNotNull);
      expect(loaded!.slug, 'great-mosque-algiers');
      expect(loaded.name, 'جامع الجزائر الكبير');
    });
  });
}
