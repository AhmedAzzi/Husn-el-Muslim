import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/tracking/presentation/sunnah_tracking_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/worship_tracking_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// The trackers follow the app locale: Arabic → RTL, other locales → LTR.
/// They declare an explicit locale-aware Directionality instead of a
/// hardcoded direction.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpTracker(
      WidgetTester tester, Widget screen, Locale locale) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ));
    await tester.pumpAndSettle();
  }

  TextDirection directionOf(WidgetTester tester) {
    final ctx = tester.element(find.byType(Scaffold));
    return Directionality.of(ctx);
  }

  testWidgets('sunnah tracker is LTR under English, RTL under Arabic',
      (tester) async {
    await pumpTracker(tester, const SunnahTrackingScreen(), const Locale('en'));
    expect(directionOf(tester), TextDirection.ltr);
    // Content renders (header + sections), proving the wrap didn't break it.
    expect(find.text('Sunnah Tracker'), findsOneWidget);

    await pumpTracker(tester, const SunnahTrackingScreen(), const Locale('ar'));
    expect(directionOf(tester), TextDirection.rtl);
    expect(find.text('تتبع السنن'), findsOneWidget);
  });

  testWidgets('worship tracker is LTR under English, RTL under Arabic',
      (tester) async {
    await pumpTracker(
        tester, const WorshipTrackingScreen(), const Locale('en'));
    expect(directionOf(tester), TextDirection.ltr);
    expect(find.text('Fasting & Wird Tracker'), findsOneWidget);

    await pumpTracker(
        tester, const WorshipTrackingScreen(), const Locale('ar'));
    expect(directionOf(tester), TextDirection.rtl);
    expect(find.text('تتبع الصيام والورد'), findsOneWidget);
  });
}
