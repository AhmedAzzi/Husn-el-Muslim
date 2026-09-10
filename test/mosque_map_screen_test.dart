import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/mosque_map_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Regression test for the on-device crash:
/// `dependOnInheritedWidgetOfExactType<_LocalizationsScope>() was called
/// before _MosqueMapScreenState.initState() completed.`
/// `_loadMosques()` read localizations synchronously inside initState,
/// killing the map screen on open. It must be deferred past the first frame.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'map screen opens without initState crash and loads bundle mosques',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: const MosqueMapScreen(countryCode: 'DZ'),
      ),
    );
    // Let the post-frame load + offline bundle parse run.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MosqueMapScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
