import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/navigation/main_destinations.dart';
import 'package:small_husn_muslim/core/navigation/main_nav_controller.dart';
import 'package:small_husn_muslim/core/widgets/app_drawer.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (Get.isRegistered<MainNavController>()) {
      Get.delete<MainNavController>(force: true);
    }
  });

  group('MainDestination mapping', () {
    test('each destination maps to a unique page, adhkar is home', () {
      expect(MainDestination.adhkar.pageIndex, 0);
      final pages = MainDestination.values.map((d) => d.pageIndex).toSet();
      // 12 destinations over 12 pages.
      expect(pages.length, 12);
    });

    test('persisted home_screen keys map to the right destination', () {
      expect(
        MainDestinationX.fromHomeScreenKey('azkar'),
        MainDestination.adhkar,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('misbaha'),
        MainDestination.tasbih,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('prayer_times'),
        MainDestination.mawaqit,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('quran'),
        MainDestination.quran,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('khatma'),
        MainDestination.khatma,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('qibla'),
        MainDestination.qibla,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('dua'),
        MainDestination.dua,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('names'),
        MainDestination.names,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('ruqyah'),
        MainDestination.ruqyah,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('mosque_map'),
        MainDestination.mosqueMap,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('tracking'),
        MainDestination.tracking,
      );
      expect(
        MainDestinationX.fromHomeScreenKey('unknown'),
        MainDestination.adhkar,
      );
    });

    test('every destination has an icon and a stable key', () {
      for (final dest in MainDestination.values) {
        expect(dest.icon, isNotNull);
        expect(dest.keyName, 'nav_${dest.name}');
      }
      expect(AppDrawer.mainEntries.length, 11);
    });
  });

  group('MainNavController', () {
    test('goTo switches destination, repeat tap is a no-op', () {
      final nav = MainNavController();
      expect(nav.destination.value, MainDestination.adhkar);
      expect(nav.pageIndex, 0);

      nav.goTo(MainDestination.mawaqit);
      expect(nav.destination.value, MainDestination.mawaqit);
      expect(nav.pageIndex, MainDestination.mawaqit.pageIndex);

      nav.goTo(MainDestination.mawaqit);
      expect(nav.destination.value, MainDestination.mawaqit);
    });

    test('goToPage resolves the default destination per page', () {
      final nav = MainNavController();
      nav.goToPage(3);
      expect(nav.destination.value, MainDestination.mawaqit);
      nav.goToPage(99);
      expect(nav.destination.value, MainDestination.adhkar);
    });
  });

  group('AppDrawer', () {
    Future<void> pumpDrawerHarness(WidgetTester tester) async {
      Get.put(MainNavController(), permanent: false);
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            key: scaffoldKey,
            appBar: AppBar(title: const Text('harness')),
            drawer: const AppDrawer(),
            body: const Text('body'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Open the drawer programmatically (tooltip text is localized).
      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('shows all main entries with the active one highlighted',
        (tester) async {
      await pumpDrawerHarness(tester);

      // Adhkar is active initially: its tile is highlighted with the accent
      // color and a check mark, other tiles are plain.
      const accent = Color(0xFFD64463);
      final adhkarTile =
          tester.widget<ListTile>(find.byKey(const ValueKey('nav_adhkar')));
      expect((adhkarTile.title! as Text).style?.color, accent);
      expect(adhkarTile.trailing, isNotNull);
      final quranTile =
          tester.widget<ListTile>(find.byKey(const ValueKey('nav_quran')));
      expect((quranTile.title! as Text).style?.color, isNot(accent));
      expect(quranTile.trailing, isNull);

      for (final dest in AppDrawer.mainEntries) {
        // The drawer list builds lazily: scroll each entry into view first.
        await tester.scrollUntilVisible(
          find.byKey(ValueKey(dest.keyName)),
          200,
        );
        expect(find.byKey(ValueKey(dest.keyName)), findsOneWidget);
      }
    });

    testWidgets('tapping a main entry switches section without pushing',
        (tester) async {
      await pumpDrawerHarness(tester);
      final nav = Get.find<MainNavController>();

      await tester.tap(find.byKey(const ValueKey('nav_mawaqit')));
      await tester.pumpAndSettle();

      expect(nav.destination.value, MainDestination.mawaqit);
      // No route was pushed: the harness Scaffold is still the only route.
      expect(find.text('body'), findsOneWidget);
      expect(find.text('harness'), findsOneWidget);
    });
  });
}
