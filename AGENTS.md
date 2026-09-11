# AGENTS.md — Husn-el-Muslim (`small_husn_muslim`)

Flutter (3.41.x / Dart 3.11) Islamic app: adhkar, prayer times + native alarms, Fajr challenge, 5-prayer tracker, masbaha, quran, qibla, mosque finder. State via **GetX** (`Get.put` / `GetMaterialApp`). Entry: `lib/main.dart` → `lib/app.dart` (`MyApp`, default locale `ar`, dark default).

## Commands (verified)

```sh
flutter pub get
flutter gen-l10n          # after any ARB edit; regenerates lib/l10n/*.dart
flutter analyze
flutter test
flutter test test/<name>_test.dart   # single suite, e.g. test/plural_strings_test.dart
flutter build apk --debug            # validates Kotlin + resources compile
```

- Lint is just `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`. No CI, no task runner.
- `flutter pub get` / `flutter gen-l10n` both regenerate localizations per `l10n.yaml` (`lib/l10n`, template `app_ar.arb`).

## Architecture

- `lib/core/` — services, storage (`AppDatabase`), platform channels, theme. `lib/features/` — 16 features (`alarms/`, `prayer_times/`, `fajr_challenge/`, `tracking/`, `quran/`, `qibla/`, …). No packages/monorepo.
- Startup is staged in `main.dart`: `runApp` renders onboarding immediately; heavy init (SharedPrefs, Quran DB, notifications, Workmanager, prayer data) runs post-first-frame in `_initializeAppAsync`. `PrayerTimesLogic` is a permanent GetX singleton available from frame one.
- Prayer math: hand-rolled `PrayerCalculationEngine` delegates astronomy to the `adhan` package but keeps its own contract (device-zone midnight seconds, user offsets, madhab, custom angles). Don't bypass it with raw `adhan` calls.
- Native alarm layer (`android/app/src/main/kotlin/com/ahmed/hisnelmuslim/*.kt`): `AlarmScheduler` is the single scheduling layer → `PrayerAlarmReceiver` (goAsync + 120s WakeLock). Deterministic IDs (`AlarmKind`: Fajr 9001, prayers 9002–9010, Suhoor/Pre-Fajr/Bedtime/Pre/Post 9101–9105), cancel-before-schedule everywhere. `PrayerAlarmReceiver` is `exported=false` — shell broadcasts are rightly blocked, don't "fix" that.
- Persistence is **SharedPreferences only** (+ week-JSON cache). Keys are migration-safe: never rename/remove legacy keys (`fajrChallengeEnabled`, `fajr_log_*`, `ptrack_*`); `clearAll()` wipes logs but preserves settings. New opt-in features default OFF (`?? false`).
- Subsystem docs are authoritative: `ALARM_ARCHITECTURE.md`, `TRACKING_ARCHITECTURE.md`, `CHALLENGE_ARCHITECTURE.md`. `IMPLEMENTATION_STATUS.md` is a stale phase log — don't treat its backlog as tasks.

## Localization (strict)

- Source of truth: `lib/l10n/app_{ar,en,fr}.arb`. **Never hand-edit** generated `app_localizations*.dart`.
- Plurals must use `{count}` interpolation — never a literal `#` (`gen-l10n` emits `pluralLogic`, which never substitutes `#`). Guarded by `test/plural_strings_test.dart`.
- Never machine-translate religious source text (Quran/Hadith/adhkar/dua bodies stay Arabic). `context.loc` must be null-safe with Arabic fallback.
- Access localized strings in controllers without context via `lookupAppLocalizations(Locale(...))`.

## Test quirks (copy from existing tests)

- Always `SharedPreferences.setMockInitialValues({})` in `setUp`; code reading prefs via `SharedPrefsCache` additionally needs `SharedPrefsCache.init(await SharedPreferences.getInstance())`.
- Instantiating `PrayerTimesLogic` creates an `AudioPlayer` — mock `xyz.luan/audioplayers` + `xyz.luan/audioplayers.global` channels (see `test/settings_build_crash_test.dart`), or `dispose()` crashes on `getCurrentPosition`.
- Notification scheduling tests must use `test/support/fake_android_notifications.dart` (`FlutterLocalNotificationsPlatform.instance = fake`); the real plugin never initializes under test. Needs `flutter_local_notifications_platform_interface` (already a dev-dep).
- DB code on Windows/Linux/test host needs `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` (same guard as `main.dart`); Android/iOS/macOS use the default factory.
- Current suite is ~116 tests, all green — keep `flutter analyze` clean and `flutter test` green before finishing.
