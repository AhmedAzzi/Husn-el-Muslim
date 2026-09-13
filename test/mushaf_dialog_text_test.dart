import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/quran/data/models/word_meaning.dart';
import 'package:small_husn_muslim/features/quran/presentation/widgets/word_detail_dialog.dart';

/// High-fidelity reproduction of the reported bug: dark app theme + mushaf
/// forced-light toggle. Pumps the real [WordDetailDialog] with a selected
/// word and asserts the body text resolves to a DARK effective color on the
/// light paper (i.e. readable — never light-on-light).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Effective text color of [finder] after merging inherited defaults.
  Color effectiveColor(WidgetTester tester, Finder finder) {
    final el = tester.element(finder);
    final base = DefaultTextStyle.of(el).style;
    final self = (el.widget as Text).style;
    return (self?.color ?? base.color) ?? const Color(0xFF000000);
  }

  Future<void> pumpDialog(WidgetTester tester) async {
    final selected = Rxn<WordMeaning>(
      const WordMeaning(
        surah: 1,
        ayah: 2,
        word: 1,
        wordWithHaraqah: 'الْحَمْدُ',
        root: 'حمد',
        meaning: 'الثناء على الله',
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.dark(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: WordDetailDialog(
          selected: selected,
          isLoading: false.obs,
          error: Rxn<String>(),
          forceLight: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('meaning body text is dark on the forced-light paper',
      (tester) async {
    await pumpDialog(tester);
    final meaning = find.text('الثناء على الله');
    expect(meaning, findsOneWidget);
    final c = effectiveColor(tester, meaning);
    expect(
      c.computeLuminance(),
      lessThan(0.5),
      reason: 'meaning text $c is too light to read on paper',
    );
  });

  testWidgets('root line text is dark on the forced-light paper',
      (tester) async {
    await pumpDialog(tester);
    // The body root line (grey, default-on-paper) — not the header pill,
    // which is intentionally light on the burgundy gradient.
    final root = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          (w.data?.contains('الجذر') ?? false) &&
          w.style?.fontSize == 13,
    );
    expect(root, findsOneWidget);
    final t = tester.widget<Text>(root);
    final base = DefaultTextStyle.of(tester.element(root)).style;
    final c = (t.style?.color ?? base.color) ?? const Color(0xFF000000);
    expect(
      c.computeLuminance(),
      lessThan(0.5),
      reason: 'root text $c is too light to read on paper',
    );
  });
}
