import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Recents (Overview □) bypass regression tests.
///
/// The Fajr challenge must survive the app being swiped from Recents:
/// - opening the screen arms the guard (`setChallengeActive(true)` +
///   max-volume lock),
/// - disposing the screen mid-challenge (what a swipe does) must NOT
///   restore the volume and must NOT clear the guard,
/// - preview mode never touches the guard,
/// - the persisted flag defaults OFF and round-trips.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prayerChannel =
      MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');
  const volumeChannel = MethodChannel('com.ahmed.hisnelmuslim/volume_lock');
  const audioChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayersChannel = MethodChannel('xyz.luan/audioplayers');

  final prayerCalls = <String>[];
  final challengeActiveArgs = <Object?>[];
  var nativeActive = false;
  final volumeCalls = <String>[];

  Future<Object?> audioHandler(MethodCall call) async {
    switch (call.method) {
      case 'create':
        return 'test-player';
      case 'getCurrentPosition':
      case 'getDuration':
        return 0;
      case 'play':
      case 'stop':
      case 'pause':
      case 'resume':
      case 'setVolume':
      case 'setReleaseMode':
      case 'dispose':
        return 1;
      default:
        return null;
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({'internal_offsets_v2': true});
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    prayerCalls.clear();
    challengeActiveArgs.clear();
    volumeCalls.clear();
    nativeActive = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prayerChannel, (call) async {
      prayerCalls.add(call.method);
      switch (call.method) {
        case 'setChallengeActive':
          challengeActiveArgs.add((call.arguments as Map?)?['active']);
          return true;
        case 'isChallengeActive':
          return nativeActive;
        case 'cancelAlarmNotification':
        case 'enableLockScreenMode':
        case 'disableLockScreenMode':
        case 'bringAppToForeground':
          return true;
        default:
          return null;
      }
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(volumeChannel, (call) async {
      volumeCalls.add(call.method);
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayersChannel, audioHandler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prayerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(volumeChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayersChannel, null);
    Get.reset();
  });

  Future<void> pumpChallenge(WidgetTester tester, {bool preview = false}) async {
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FajrChallengeScreen(preview: preview),
    ));
    // Fixed pumps instead of pumpAndSettle: the loading spinner animates
    // forever, and asset-load failure settles via microtasks.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }

  testWidgets('opening the challenge arms the Recents guard', (tester) async {
    await pumpChallenge(tester);
    expect(challengeActiveArgs, contains(true));
    expect(prayerCalls, contains('enableLockScreenMode'));
    expect(volumeCalls, contains('lockVolumeAtMax'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrayerNotificationHelper.challengeActiveKey), isTrue);
  });

  testWidgets('swiping mid-challenge keeps guard + max volume', (tester) async {
    await pumpChallenge(tester);
    expect(challengeActiveArgs, contains(true));

    // Simulate the Recents swipe: the widget is destroyed while the
    // challenge is still unanswered.
    prayerCalls.clear();
    challengeActiveArgs.clear();
    volumeCalls.clear();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    // The guard is never cleared and the volume never restored; dispose
    // only re-asserts the guard (active: true) as a best-effort fallback.
    expect(challengeActiveArgs, isNot(contains(false)));
    expect(prayerCalls, isNot(contains('disableLockScreenMode')));
    expect(volumeCalls, isNot(contains('unlockVolume')));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrayerNotificationHelper.challengeActiveKey), isTrue);
  });

  testWidgets('preview mode never touches the guard', (tester) async {
    await pumpChallenge(tester, preview: true);
    expect(prayerCalls, isNot(contains('setChallengeActive')));
    expect(volumeCalls, isNot(contains('lockVolumeAtMax')));
  });

  test('challenge-active flag defaults OFF and round-trips', () async {
    // Fresh prefs: nothing armed.
    expect(await PrayerNotificationHelper.isChallengeActive(), isFalse);

    // Local mirror alone counts (native dead / channel missing value).
    await PrayerNotificationHelper.setChallengeActive(true);
    nativeActive = false;
    expect(await PrayerNotificationHelper.isChallengeActive(), isTrue);

    // Legitimate exit clears both sides.
    await PrayerNotificationHelper.setChallengeActive(false);
    expect(await PrayerNotificationHelper.isChallengeActive(), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrayerNotificationHelper.challengeActiveKey), isFalse);
  });
}
