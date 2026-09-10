import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';

// Spec §21 (P2): Do Not Disturb around prayer.
// - Explicit opt-in, default OFF; never silently modified.
// - Requires notification-policy access; gracefully inert without it.
// - Timed duration with automatic restore (native side).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Answer for the mocked isDndAccessGranted native call, per test.
  var dndGranted = false;

  const prayerChannel =
      MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');
  const audioChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayersChannel = MethodChannel('xyz.luan/audioplayers');
  const geoChannel = MethodChannel('flutter.baseflow.com/geolocator');

  setUp(() {
    dndGranted = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prayerChannel, (call) async {
      if (call.method == 'canScheduleExactAlarms') return true;
      if (call.method == 'isDndAccessGranted') return dndGranted;
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
      if (call.method == 'checkPermission') return 1;
      return null;
    });
  });

  // NOTE: mocks stay installed for the whole file (see
  // adhkar_reminders_test.dart): the controller fans out to unawaited
  // native calls that may resolve after a test body completes.

  test('DND defaults OFF with 20-minute duration', () {
    final logic = PrayerTimesLogic();
    expect(logic.dndDuringPrayerEnabled, isFalse);
    expect(logic.dndDurationMinutes, 20);
  });

  test('stored DND prefs round-trip (explicit opt-in)', () async {
    SharedPreferences.setMockInitialValues({
      'dndDuringPrayerEnabled': true,
      'dndDurationMinutes': 30,
      'lat': 35.9474044,
      'lon': 0.1106258,
      'internal_offsets_v2': true,
    });
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    final logic = PrayerTimesLogic();
    await logic.loadNotificationPreference();
    expect(logic.dndDuringPrayerEnabled, isTrue);
    expect(logic.dndDurationMinutes, 30);
    logic.stopNotificationUpdates();
  });

  test('policy access denied -> helpers report gracefully inert', () async {
    dndGranted = false;
    expect(await PrayerNotificationHelper.isDndAccessGranted(), isFalse);
    // setDndMode/openDndSettings return null from the mock -> false.
    expect(await PrayerNotificationHelper.setDndMode(true), isFalse);
    expect(await PrayerNotificationHelper.openDndSettings(), isFalse);
  });

  test('policy access granted -> helper reports granted', () async {
    dndGranted = true;
    expect(await PrayerNotificationHelper.isDndAccessGranted(), isTrue);
  });
}
