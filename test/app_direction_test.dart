import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/app.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('forceRtl keeps RTL even under the English locale',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: forceRtl,
      home: Builder(
        builder: (ctx) => Text(Directionality.of(ctx).toString()),
      ),
    ));
    expect(find.text('TextDirection.rtl'), findsOneWidget);
  });

  testWidgets('forceRtl preserves the child', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: forceRtl,
      home: const Text('child-marker'),
    ));
    expect(find.text('child-marker'), findsOneWidget);
    expect(find.byType(Directionality), findsWidgets);
  });
}
