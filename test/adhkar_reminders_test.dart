import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

// Spec §31: Wake-up / Sleep / Friday-Kahf reminder categories.
// - Legacy morning/evening behavior is preserved (default ON).
// - New categories default OFF and require explicit opt-in.
// - Friday Kahf content follows the app language via ARB.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // loadNotificationPreference() recalculates times, which touches native
  // channels (widgets/alarms/audio/location). Mock them like
  // diagnostics_screen_test does so the prefs-loading path can be
  // exercised in unit tests.
  const prayerChannel =
      MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');
  const audioChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayersChannel = MethodChannel('xyz.luan/audioplayers');
  const geoChannel = MethodChannel('flutter.baseflow.com/geolocator');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prayerChannel, (call) async {
      if (call.method == 'canScheduleExactAlarms') return true;
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayersChannel, (call) async {
      if (call.method == 'create') return 'test-player-id';
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geoChannel, (call) async {
      // LocationPermission.deniedForever: calc falls back to cached coords.
      if (call.method == 'checkPermission') return 1;
      return null;
    });
  });

  // NOTE: the mock is intentionally left installed for the whole file
  // (no tearDown-nulling): loadNotificationPreference() fans out to
  // unawaited native calls that may resolve after a test body completes,
  // and they must still land on the mock instead of throwing
  // MissingPluginException. Each test file runs in its own isolate.

  test('new categories default OFF, legacy morning/evening stay ON', () {
    final logic = PrayerTimesLogic();
    expect(logic.morningAdhkarEnabled, isTrue);
    expect(logic.eveningAdhkarEnabled, isTrue);
    expect(logic.wakeupAdhkarEnabled, isFalse);
    expect(logic.sleepAdhkarEnabled, isFalse);
    expect(logic.fridayKahfEnabled, isFalse);
  });

  test('stored prefs override defaults (migration-safe opt-in)', () async {
    SharedPreferences.setMockInitialValues({
      'wakeupAdhkarEnabled': true,
      'sleepAdhkarEnabled': true,
      'fridayKahfEnabled': true,
      'morningAdhkarEnabled': false,
      // Steer calculation away from GPS / cache migration in tests.
      'lat': 35.9474044,
      'lon': 0.1106258,
      'internal_offsets_v2': true,
    });
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    final logic = PrayerTimesLogic();
    await logic.loadNotificationPreference();
    expect(logic.wakeupAdhkarEnabled, isTrue);
    expect(logic.sleepAdhkarEnabled, isTrue);
    expect(logic.fridayKahfEnabled, isTrue);
    expect(logic.morningAdhkarEnabled, isFalse);
    // Absent key keeps the legacy default (existing users see no change).
    expect(logic.eveningAdhkarEnabled, isTrue);
    // loadNotificationPreference() starts a periodic notification timer;
    // stop it so no channel calls outlive the test.
    logic.stopNotificationUpdates();
  });

  test('Friday Kahf reminder content localized in ar/en/fr', () {
    expect(
      lookupAppLocalizations(const Locale('ar')).nsFridayKahfTitle,
      'سورة الكهف',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).nsFridayKahfTitle,
      'Surah Al-Kahf',
    );
    expect(
      lookupAppLocalizations(const Locale('fr')).nsFridayKahfTitle,
      'Sourate Al-Kahf',
    );
    expect(
      lookupAppLocalizations(const Locale('ar')).nsFridayKahfBody,
      contains('الكهف'),
    );
    expect(
      lookupAppLocalizations(const Locale('en')).nsFridayKahfBody,
      contains('Al-Kahf'),
    );
    expect(
      lookupAppLocalizations(const Locale('fr')).nsFridayKahfBody,
      contains('Kahf'),
    );
  });
}
