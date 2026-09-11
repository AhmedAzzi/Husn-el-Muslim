import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/tracking/presentation/tracking_home_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// The unified tracking page: one themed AppBar, three tabs, SafeArea.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpHome(WidgetTester tester) async {
    // Tall surface so lazily-built ListView rows below the fold exist.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TrackingHomeScreen(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows themed app bar with three tabs', (tester) async {
    await pumpHome(tester);
    expect(find.text('Tracking'), findsOneWidget);
    expect(find.byKey(const ValueKey('tr_tab_prayers')), findsOneWidget);
    expect(find.byKey(const ValueKey('tr_tab_sunnah')), findsOneWidget);
    expect(find.byKey(const ValueKey('tr_tab_worship')), findsOneWidget);
    expect(find.byKey(const ValueKey('tr_tabs')), findsOneWidget);
    expect(find.byType(SafeArea), findsWidgets);
  });

  testWidgets('page forces RTL under the English locale', (tester) async {
    await pumpHome(tester);
    final ctx = tester.element(find.byType(TabBarView));
    expect(Directionality.of(ctx), TextDirection.rtl);
  });

  testWidgets('starts on prayers and switches tabs', (tester) async {
    await pumpHome(tester);
    // Prayers tab content by default (no nested app bars).
    expect(find.byKey(const ValueKey('pt_circle_0')), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    // Tap the tab labels (the Tab widget box itself is not hit-testable).
    await tester.tap(find.text('Sunnah Tracker'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('sn_row_fajrSunnah')), findsOneWidget);

    await tester.tap(find.text('Fasting & Wird Tracker'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wt_row_quranWird')), findsOneWidget);

    await tester.tap(find.text('Prayer Tracker'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pt_circle_0')), findsOneWidget);
  });

  testWidgets('initialTab opens the requested tab', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TrackingHomeScreen(initialTab: 2),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wt_row_quranWird')), findsOneWidget);
  });
}
