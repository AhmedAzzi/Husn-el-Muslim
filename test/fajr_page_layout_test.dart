import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/settings/presentation/fajr_wakeup_settings_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Guards the compact Fajr tab layout against overlapping/colliding
/// elements: pumps the page at small phone sizes, in ar/en/fr, walks
/// every tab through its widest option combo, and fails on any
/// RenderFlex overflow (reported via [WidgetTester.takeException]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'internal_offsets_v2': true});
    SharedPrefsCache.init(await SharedPreferences.getInstance());
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
    Get.reset();
  });

  Future<AppLocalizations> pumpPage(
    WidgetTester tester,
    Locale locale,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(GetMaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FajrWakeupSettingsScreen(),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return AppLocalizations.of(
        tester.element(find.byType(Scaffold).first))!;
  }

  /// Taps a control that may sit below the fold inside its tab scroll.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  /// Drives the page through its widest state on every tab.
  Future<void> driveWidestState(
      WidgetTester tester, AppLocalizations loc) async {
    // Challenge tab: custom ring time + random pool + hard difficulty.
    await tapVisible(tester, find.text(loc.sheetCustom));
    await tapVisible(tester, find.text(loc.nsTypeRandom));
    await tapVisible(tester, find.text(loc.nsHard));
    // Sound tab: custom file picker button visible.
    await tapVisible(tester, find.text(loc.fajrTabSound));
    await tapVisible(tester, find.text(loc.nsSoundCustom));
    // Re-ring tab: both extra delays default ON (dropdowns visible).
    await tapVisible(tester, find.text(loc.fajrTabRering));
    expect(find.text(loc.nsFajrExtra), findsOneWidget);
  }

  const sizes = [
    Size(320, 568), // small legacy phone
    Size(360, 640), // common phone
    Size(412, 915), // tall phone
  ];
  const locales = [
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  for (final size in sizes) {
    for (final locale in locales) {
      testWidgets(
          'fajr page has no overlap at ${size.width.toInt()}x${size.height.toInt()}'
          ' in ${locale.languageCode}', (tester) async {
        final loc = await pumpPage(tester, locale, size);
        await driveWidestState(tester, loc);
        PrayerTimesLogic().onClose();
      });
    }
  }
}
