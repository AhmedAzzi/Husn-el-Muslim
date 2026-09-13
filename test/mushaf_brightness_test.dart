import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/features/quran/presentation/widgets/mushaf_brightness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mushaf paper toggle forces light over a dark app theme',
      (tester) async {
    Brightness? seen;
    bool? darkFlag;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (ctx) => mushafOverlayTheme(
            forceLight: true,
            child: Builder(
              builder: (inner) {
                seen = Theme.of(inner).brightness;
                darkFlag = mushafDark(inner, forceLight: true);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    expect(seen, Brightness.light);
    expect(darkFlag, isFalse);
  });

  testWidgets('toggle off follows the app theme', (tester) async {
    Brightness? seen;
    bool? darkFlag;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (ctx) => mushafOverlayTheme(
            forceLight: false,
            child: Builder(
              builder: (inner) {
                seen = Theme.of(inner).brightness;
                darkFlag = mushafDark(inner, forceLight: false);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    expect(seen, Brightness.dark);
    expect(darkFlag, isTrue);
  });
}
