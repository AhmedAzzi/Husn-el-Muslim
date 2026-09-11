import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/data/mosque_api.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/mosque_suggest_dialog.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

const _nearby = MosquePoint(
  slug: 'mosquee-near',
  name: 'مسجد النور',
  city: 'الجزائر',
  latitude: 36.75,
  longitude: 3.05,
  proximityMeters: 500,
);

const _other = MosquePoint(
  slug: 'mosquee-far',
  name: 'مسجد السلام',
  city: 'الجزائر',
  latitude: 36.80,
  longitude: 3.10,
  proximityMeters: 2500,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'internal_offsets_v2': true});
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    // PrayerTimesLogic ctor creates an AudioPlayer (platform channels).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'),
            (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers'),
            (call) async => switch (call.method) {
                  'create' => 'test-player',
                  'getCurrentPosition' || 'getDuration' => 0,
                  _ => null,
                });
    // PrayerTimesLogic is a process-wide singleton: reset suggestion state.
    final logic = PrayerTimesLogic();
    logic.selectedMosque = null;
    logic.nearbyMosquesRx.value = [];
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers'), null);
  });

  group('shouldSuggestMosque decision', () {
    test('null or slug-less mosque is never suggested', () {
      expect(
        PrayerTimesLogic.shouldSuggestMosque(
          nearest: null,
          selected: null,
          dismissedSlugs: const [],
        ),
        isFalse,
      );
      expect(
        PrayerTimesLogic.shouldSuggestMosque(
          nearest: const MosquePoint(
              slug: '', name: 'X', city: '', latitude: 1, longitude: 1),
          selected: null,
          dismissedSlugs: const [],
        ),
        isFalse,
      );
    });

    test('already-default mosque is not suggested', () {
      expect(
        PrayerTimesLogic.shouldSuggestMosque(
          nearest: _nearby,
          selected: _nearby,
          dismissedSlugs: const [],
        ),
        isFalse,
      );
    });

    test('dismissed mosque is not suggested again', () {
      expect(
        PrayerTimesLogic.shouldSuggestMosque(
          nearest: _nearby,
          selected: null,
          dismissedSlugs: const ['mosquee-near'],
        ),
        isFalse,
      );
    });

    test('fresh nearest mosque is suggested', () {
      expect(
        PrayerTimesLogic.shouldSuggestMosque(
          nearest: _nearby,
          selected: _other,
          dismissedSlugs: const ['mosquee-far'],
        ),
        isTrue,
      );
    });
  });

  group('dismissal store', () {
    test('mark + read roundtrip, idempotent append', () async {
      final logic = PrayerTimesLogic();
      expect(await logic.dismissedMosqueSuggestions(), isEmpty);
      await logic.markMosqueSuggestionDismissed('mosquee-near');
      await logic.markMosqueSuggestionDismissed('mosquee-near');
      await logic.markMosqueSuggestionDismissed('mosquee-far');
      expect(
        await logic.dismissedMosqueSuggestions(),
        ['mosquee-near', 'mosquee-far'],
      );
    });

    test('empty slug is ignored', () async {
      final logic = PrayerTimesLogic();
      await logic.markMosqueSuggestionDismissed('');
      expect(await logic.dismissedMosqueSuggestions(), isEmpty);
    });
  });

  group('nearestSuggestedMosque', () {
    test('null when no nearby mosques were found', () async {
      final logic = PrayerTimesLogic();
      expect(await logic.nearestSuggestedMosque(), isNull);
    });

    test('returns the nearest mosque when fresh', () async {
      final logic = PrayerTimesLogic();
      logic.nearbyMosquesRx.value = [_nearby, _other];
      final suggested = await logic.nearestSuggestedMosque();
      expect(suggested?.slug, 'mosquee-near');
    });

    test('null once dismissed or already default', () async {
      final logic = PrayerTimesLogic();
      logic.nearbyMosquesRx.value = [_nearby, _other];
      await logic.markMosqueSuggestionDismissed('mosquee-near');
      expect(await logic.nearestSuggestedMosque(), isNull);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mosque_suggest_dismissed');
      logic.selectedMosque = _nearby;
      expect(await logic.nearestSuggestedMosque(), isNull);
    });
  });

  group('MosqueSuggestDialog widget', () {
    Future<void> pumpOpener(
      WidgetTester tester, {
      required String distanceText,
      required void Function(BuildContext ctx) onOpen,
    }) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => onOpen(ctx),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mm_suggest_dialog')), findsOneWidget);
    }

    testWidgets('shows name, distance, body and both actions',
        (tester) async {
      bool? result;
      await pumpOpener(
        tester,
        distanceText: '500 م',
        onOpen: (ctx) async {
          result = await showMosqueSuggestDialog(
            context: ctx,
            mosqueName: 'مسجد النور',
            distanceText: '500 م',
          );
        },
      );
      expect(find.text('مسجد النور'), findsOneWidget);
      expect(find.text('500 م'), findsOneWidget);
      expect(find.text('تعيين كافتراضي'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mm_suggest_set')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('cancel returns false and hides distance when empty',
        (tester) async {
      bool? result = true;
      await pumpOpener(
        tester,
        distanceText: '',
        onOpen: (ctx) async {
          result = await showMosqueSuggestDialog(
            context: ctx,
            mosqueName: 'مسجد النور',
            distanceText: '',
          );
        },
      );
      expect(
          find.byKey(const ValueKey('mm_suggest_distance')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mm_suggest_cancel')));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
