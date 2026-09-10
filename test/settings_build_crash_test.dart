import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/settings/presentation/settings_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Regression test for the release crash:
/// `Settings.initState → _loadSettings → loadNotificationPreference`
/// mutated RxMaps from an async gap landing mid-build, dirtying an Obx
/// that was already building ("setState() or markNeedsBuild() called
/// during build"). The loader now publishes past the current frame.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      // Skip the one-time recalculation cascade inside
      // loadNotificationPreference (native channels in production).
      'internal_offsets_v2': true,
    });
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    // PrayerTimesLogic ctor creates an AudioPlayer (platform channels).
    // Return type-correct values: dispose() queries integer position.
    Future<Object?> audioHandler(MethodCall call) async {
      switch (call.method) {
        case 'create':
          return 'test-player';
        case 'getCurrentPosition':
        case 'getDuration':
          return 0;
        default:
          return null;
      }
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'),
            (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers'), audioHandler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers'), null);
  });

  test('loadNotificationPreference populates both maps', () async {
    final logic = PrayerTimesLogic();
    await logic.loadNotificationPreference();
    // Main prayers default ON, special times OFF.
    expect(logic.prayerNotificationsEnabled['الفجر'], isTrue);
    expect(logic.prayerNotificationsEnabled['الشروق'], isFalse);
    expect(logic.prayerAyatHadithEnabled['Fajr'], isTrue);
    expect(logic.prayerAyatHadithEnabled['Sunrise'], isFalse);
  });

  testWidgets('SettingsScreen first build settles without exceptions',
      (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    // Screen rendered with its sections, including the tracker one.
    expect(find.text('الإعدادات والتفضيلات'), findsOneWidget);
    expect(find.text('تتبع الصلوات'), findsOneWidget);
    // Loader results applied.
    expect(
        PrayerTimesLogic()
            .prayerNotificationsEnabled['الفجر'],
        isTrue);
    // loadNotificationPreference starts the production 60s update timer;
    // stop it inside the test: the post-test timer invariant runs before
    // tearDown, so cleanup here is the only in-time option.
    PrayerTimesLogic().onClose();
  });
}
