import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/theme/husn_style.dart';
import 'package:small_husn_muslim/core/theme/tajweed_colors.dart';
import 'package:small_husn_muslim/features/quran/data/models/word_meaning.dart';
import 'package:small_husn_muslim/features/quran/presentation/widgets/tajweed_legend.dart';
import 'package:small_husn_muslim/features/quran/presentation/widgets/word_detail_dialog.dart';

/// Regression tests for the mushaf paper toggle: with a dark app theme and
/// `forceLight: true`, every overlay must render light (paper background +
/// dark text) so no light-on-light text appears.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDarkApp(
    WidgetTester tester,
    Widget home,
  ) {
    return tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.dark(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: home,
      ),
    );
  }

  Brightness inheritedBrightness(WidgetTester tester, Finder finder) =>
      Theme.of(tester.element(finder)).brightness;

  group('tajweed legend sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pumpDarkApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showTajweedLegendSheet(
                ctx,
                forceLight: true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('sheet background is paper under a dark app theme',
        (tester) async {
      await openSheet(tester);
      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.backgroundColor, AppPalette.paper);
    });

    testWidgets('title and swatch labels inherit the light theme',
        (tester) async {
      await openSheet(tester);
      final title = find.text('دليل ألوان التجويد');
      expect(title, findsOneWidget);
      expect(inheritedBrightness(tester, title), Brightness.light);
      final titleText = tester.widget<Text>(title);
      expect(titleText.style?.color, HusnTheme.primary);
    });
  });

  group('word tap dialogue', () {
    Future<void> pumpDialog(WidgetTester tester) async {
      await pumpDarkApp(
        tester,
        WordDetailDialog(
          selected: Rxn<WordMeaning>(),
          isLoading: false.obs,
          error: Rxn<String>(),
          initialTab: 1,
          forceLight: true,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('dialog background is paper under a dark app theme',
        (tester) async {
      await pumpDialog(tester);
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, AppPalette.paper);
    });

    testWidgets('default-colored body text inherits the light theme',
        (tester) async {
      await pumpDialog(tester);
      // Tajweed tab with no classes: plain default-color text. It must
      // resolve against the light theme (dark text), not the dark app.
      final empty = find.text('لا يوجد حكم تجويد في هذه الكلمة');
      expect(empty, findsOneWidget);
      expect(inheritedBrightness(tester, empty), Brightness.light);
    });
  });
}
