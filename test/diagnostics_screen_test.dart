import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/features/settings/presentation/diagnostics_screen.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

import 'support/fake_android_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized;

  const prayerChannel =
      MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');
  const batteryChannel =
      MethodChannel('com.ahmed.hisnelmuslim/battery_optimization');

  var nativeCalls = <String>[];

  setUp(() async {
    nativeCalls = [];
    SharedPreferences.setMockInitialValues({});
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    FlutterLocalNotificationsPlatform.instance = FakeAndroidNotifications();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prayerChannel, (call) async {
      nativeCalls.add(call.method);
      switch (call.method) {
        case 'canScheduleExactAlarms':
          return true;
        case 'checkOverlayPermission':
          return true;
        case 'getAlarmDiagnostics':
          return 'challenge: —\nsuhoor: —\ncanExact=true sdk=34';
        case 'rescheduleAllAlarms':
          return true;
        case 'testFajrChallengeAlarm':
          return true;
        case 'updatePrayerWidgets':
          return true;
        default:
          return null;
      }
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(batteryChannel, (call) async {
      nativeCalls.add(call.method);
      if (call.method == 'isBatteryOptimizationEnabled') return false;
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prayerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(batteryChannel, null);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // Pin Arabic: the ambient test locale is en_US, but Arabic is the
    // app's default language and the strings asserted below are Arabic.
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DiagnosticsScreen(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows live native diagnostics and permission states',
      (tester) async {
    await pumpScreen(tester);

    // Native diagnostics string rendered verbatim (LTR block).
    expect(find.textContaining('canExact=true'), findsOneWidget);
    // Permission states derived from real (mocked) native answers.
    expect(find.text('مسموح — منبه الفجر يعمل بدقة'), findsOneWidget);
    expect(find.text('مستثنى — التطبيق يعمل بحرية'), findsOneWidget);
    expect(find.text('ممنوح — النوافذ العائمة تعمل'), findsOneWidget);
    // Fajr streak card starts at zero with empty prefs.
    expect(find.text('التتبع'), findsOneWidget);
  });

  testWidgets('reschedule button calls native and confirms', (tester) async {
    await pumpScreen(tester);
    nativeCalls.clear();

    await tester.scrollUntilVisible(find.text('إعادة جدولة كل المنبهات'), 300);
    await tester.tap(find.text('إعادة جدولة كل المنبهات'));
    await tester.pumpAndSettle();

    expect(nativeCalls, contains('rescheduleAllAlarms'));
    expect(find.text('تمت إعادة جدولة كل المنبهات'), findsOneWidget);
  });

  testWidgets('test-alarm button schedules a real 5s challenge alarm',
      (tester) async {
    await pumpScreen(tester);
    nativeCalls.clear();

    final button = find.text('تجربة منبه الفجر (5 ثوانٍ)');
    await tester.scrollUntilVisible(button, 300);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(nativeCalls, contains('testFajrChallengeAlarm'));
    expect(find.text('سيرن منبه التجربة بعد 5 ثوانٍ'), findsOneWidget);
  });

  testWidgets('English locale renders translated strings', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DiagnosticsScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Advanced Diagnostics'), findsOneWidget);
    expect(find.text('Reschedule all alarms'), findsOneWidget);
    expect(find.text('Allowed — the Fajr alarm rings on time'),
        findsOneWidget);
  });
}
