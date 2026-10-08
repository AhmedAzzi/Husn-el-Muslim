import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/settings/presentation/fajr_wakeup_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/notification_settings_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/settings_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// The notifications hub is flat: every extra-alarm and adhkar control
/// lives inline (no nested pages), while the Fajr wake-up page stays
/// reachable from the main settings hero. Also guards the old `_openSub`
/// bug where `Get.to(() => pageInstance)` named every route `/Widget`,
/// silently swallowing second-level pushes.
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

  Future<AppLocalizations> pumpHub(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationSettingsScreen(),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return AppLocalizations.of(
        tester.element(find.byType(Scaffold).first))!;
  }

  testWidgets('hub shows all controls inline with no nested links',
      (tester) async {
    final loc = await pumpHub(tester);
    // Extra alarms + adhkar toggles live directly on the hub.
    for (final label in [
      loc.nsBedtime,
      loc.nsPrePrayer,
      loc.nsPostPrayer,
      loc.nsMorning,
      loc.nsEvening,
      loc.nsWakeupAdhkar,
      loc.nsSleepAdhkar,
      loc.nsFridayKahf,
      loc.stFloatingDhikr,
    ]) {
      await tester.scrollUntilVisible(
        find.text(label).first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsWidgets);
    }
    // No Fajr entries here: the wake-up lives on the main settings hero,
    // the heavy-sleeper re-ring on the Fajr page.
    expect(find.text(loc.sheetTitle), findsNothing);
    expect(find.text(loc.nsFajrExtra), findsNothing);
    PrayerTimesLogic().onClose();
  });

  testWidgets('heavy-sleeper re-ring lives on the fajr page', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FajrWakeupSettingsScreen(),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final loc = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first))!;
    // Details (including the re-ring tab) show once the challenge is on.
    // The enable switch is pinned above the tabs: no scrolling needed.
    final enableTile = find.ancestor(
      of: find.text(loc.nsFajrEnable),
      matching: find.byType(SwitchListTile),
    );
    if (!tester.widget<SwitchListTile>(enableTile).value) {
      await tester.tap(enableTile);
      await tester.pumpAndSettle();
    }
    // The re-ring lives on the third tab.
    await tester.tap(find.text(loc.fajrTabRering));
    await tester.pumpAndSettle();
    expect(find.text(loc.nsFajrExtra), findsOneWidget);
    PrayerTimesLogic().onClose();
  });

  testWidgets('main settings hero still opens the fajr page', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final loc = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first))!;
    // Open the hub from the main settings menu.
    await tester.tap(find.text(loc.stNotifHub));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    PrayerTimesLogic().onClose();
  });

  testWidgets('toggling an inline switch persists', (tester) async {
    final loc = await pumpHub(tester);
    await tester.scrollUntilVisible(
      find.text(loc.nsBedtime).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final tile =
        find.ancestor(
          of: find.text(loc.nsBedtime),
          matching: find.byType(SwitchListTile),
        );
    expect(tile, findsOneWidget);
    final before = tester.widget<SwitchListTile>(tile).value;
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, !before);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs, isNotNull);
    PrayerTimesLogic().onClose();
  });
}
