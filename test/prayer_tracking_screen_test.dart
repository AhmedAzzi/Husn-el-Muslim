import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_log_entry.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';
import 'package:small_husn_muslim/features/tracking/presentation/prayer_tracking_screen.dart';
import 'package:small_husn_muslim/features/tracking/presentation/tracking_settings_section.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

import 'support/fake_android_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized;

  const prayerChannel =
      MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    FlutterLocalNotificationsPlatform.instance =
        FakeAndroidNotifications();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prayerChannel, (call) async => true);
    // Skip first-run onboarding by default; dedicated tests opt out.
    await PrayerTrackingRepository.instance.setOnboarded(true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prayerChannel, null);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PrayerTrackingScreen(),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: TrackingSettingsSection(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToOverview(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('نظرة عامة على الصلاة'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders 5 prayers, level, goal and empty overview',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('تتبع الصلوات'), findsOneWidget);
    expect(find.text('المستوى 1'), findsOneWidget);
    for (final name in ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('الهدف اليومي'), findsOneWidget);
    // Zero streaks (visible before scrolling; goal card scrolls offstage).
    expect(find.text('0 أيام'), findsNWidgets(2));
    await scrollToOverview(tester);
    expect(find.text('نظرة عامة على الصلاة'), findsOneWidget);
    // No data yet → empty state.
    expect(find.text('لا توجد بيانات صلاة مسجلة بعد'), findsOneWidget);
  });

  testWidgets('tapping a circle opens the how-picker; picking logs it',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('pt_circle_0')));
    await tester.pumpAndSettle();

    // Sheet with all options + effective Fajr points (takbeer 30x2=60).
    expect(find.textContaining('كيف صليت؟'), findsOneWidget);
    expect(find.text('تكبيرة الإحرام'), findsOneWidget);
    expect(find.text('+60 نقطة'), findsOneWidget);

    // Pick congregation: Fajr jamaa = 14x2 = 28 pts.
    expect(find.text('+28 نقطة'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pt_opt_jamaa')));
    await tester.pumpAndSettle();

    // Sheet closed, Fajr logged, goal counter moved.
    expect(find.textContaining('كيف صليت؟'), findsNothing);
    expect(find.text('1/5'), findsOneWidget);
    await scrollToOverview(tester);
    expect(find.text('لا توجد بيانات صلاة مسجلة بعد'), findsNothing);
  });

  testWidgets('woman context hides the mosque option', (tester) async {    await PrayerTrackingRepository.instance
        .setContext(PrayerTrackingRepository.contextWoman);
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('pt_circle_1')));
    await tester.pumpAndSettle();

    expect(find.textContaining('كيف صليت؟'), findsOneWidget);
    expect(find.text('في المسجد'), findsNothing);
    expect(find.text('جماعة'), findsOneWidget);
  });

  testWidgets('sheet clear-entry removes the log', (tester) async {
    final repo = PrayerTrackingRepository.instance;
    final today = DateTime.now();
    await repo.logPrayer(
        date: today, prayerIndex: 0, status: PrayerStatus.mosque);
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('pt_circle_0')));
    await tester.pumpAndSettle();
    expect(find.text('مسح التسجيل'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pt_opt_clear')));
    await tester.pumpAndSettle();

    expect(find.textContaining('كيف صليت؟'), findsNothing);
    await scrollToOverview(tester);
    expect(find.text('لا توجد بيانات صلاة مسجلة بعد'), findsOneWidget);
  });

  testWidgets('tracker opens directly with no onboarding gate',
      (tester) async {
    await PrayerTrackingRepository.instance.setOnboarded(false);
    await pumpScreen(tester);

    expect(find.text('تتبع صلواتك'), findsNothing);
    expect(find.text('تتبع الصلوات'), findsOneWidget);
  });

  testWidgets('level pill opens details with stages and context',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('pt_level_pill')));
    await tester.pumpAndSettle();

    expect(find.text('كيف يعمل'), findsOneWidget);
    expect(find.text('المراحل'), findsOneWidget);

    // Lower sections are lazily built: scroll the sheet's own list.
    final detailsList = find.byKey(const ValueKey('pt_details_list'));
    final detailsScroll = find
        .descendant(
          of: detailsList,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('النقاط في التطبيق'),
      400,
      scrollable: detailsScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('النقاط في التطبيق'), findsOneWidget);
    expect(find.text('مضاعف النقاط'), findsOneWidget);

    // Context is display-only here; editing lives in app Settings.
    await tester.scrollUntilVisible(
      find.text('امرأة'),
      -400,
      scrollable: detailsScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('امرأة'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('pt_ctx_settings')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pt_details_close')));
    await tester.pumpAndSettle();
    expect(find.text('كيف يعمل'), findsNothing);
  });

  testWidgets('paused banner locks circles; resume clears it',
      (tester) async {
    await PrayerTrackingRepository.instance.setDisabled(true);
    await pumpScreen(tester);

    expect(find.text('التتبع متوقف مؤقتًا'), findsOneWidget);
    // Circles locked while paused: tapping opens nothing.
    await tester.tap(find.byKey(const ValueKey('pt_circle_0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('كيف صليت؟'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pt_resume_btn')));
    await tester.pumpAndSettle();
    expect(find.text('التتبع متوقف مؤقتًا'), findsNothing);
  });

  testWidgets('settings section edits goal', (tester) async {
    await pumpSection(tester);

    expect(find.text('5/5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pt_settings_goal')));
    await tester.pumpAndSettle();
    // Stepper down to 3, then save.
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(await PrayerTrackingRepository.instance.dailyGoal(), 3);
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('settings section switches context', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.byKey(const ValueKey('pt_settings_ctx')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('امرأة'));
    await tester.pumpAndSettle();

    expect(await PrayerTrackingRepository.instance.context(),
        PrayerTrackingRepository.contextWoman);
  });

  testWidgets('settings section toggles reminders and pause',
      (tester) async {
    await pumpSection(tester);
    final repo = PrayerTrackingRepository.instance;

    Finder switchIn(Key key) => find.descendant(
          of: find.byKey(key),
          matching: find.byType(Switch),
        );
    await tester.tap(switchIn(const ValueKey('pt_settings_reminders')));
    await tester.pumpAndSettle();
    expect(await repo.remindersEnabled(), isTrue);

    await tester.tap(switchIn(const ValueKey('pt_settings_pause')));
    await tester.pumpAndSettle();
    expect(await repo.isDisabled(), isTrue);
  });

  testWidgets('settings section widget help and clears data',
      (tester) async {
    final repo = PrayerTrackingRepository.instance;
    final today = DateTime.now();
    await repo.logPrayer(
        date: today, prayerIndex: 0, status: PrayerStatus.takbeer);
    await pumpSection(tester);

    // Widget help dialog.
    await tester.tap(find.byKey(const ValueKey('pt_settings_widget')));
    await tester.pumpAndSettle();
    expect(find.text('إضافة التطبيق المصغر'), findsOneWidget);
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();

    // Destructive clear with confirm.
    await tester.tap(find.byKey(const ValueKey('pt_settings_clear')));
    await tester.pumpAndSettle();
    expect(find.text('مسح بيانات التتبع؟'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pt_clear_confirm')));
    await tester.pumpAndSettle();
    final day = await repo.dayEntries(today);
    expect(day.every((e) => e == null), isTrue);
  });

  testWidgets('seeded full day shows streak and overview stats',
      (tester) async {
    final repo = PrayerTrackingRepository.instance;
    final today = DateTime.now();
    for (var p = 0; p < 5; p++) {
      await repo.logPrayer(
          date: today, prayerIndex: p, status: PrayerStatus.onTimeAlone);
    }
    await pumpScreen(tester);

    expect(find.text('1 يوم'), findsNWidgets(2)); // current + longest
    expect(find.text('✓'), findsOneWidget); // goal met shows a check
    await scrollToOverview(tester);
    expect(find.text('مجموع الصلوات'), findsOneWidget);
    expect(find.text('5'), findsWidgets); // total performed + calendar day
  });
}
