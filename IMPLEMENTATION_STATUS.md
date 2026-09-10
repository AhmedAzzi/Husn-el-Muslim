# IMPLEMENTATION_STATUS.md — Husn-el-Muslim Fajr-Level Upgrade

Master spec: `Husn-el-Muslim — Fajr-Level Feature & Architecture Upgrade.md`
This file tracks every requirement. Updated incrementally as phases land.

Legend: `[ ]` Not started · `[~]` In progress · `[x]` Completed · `[!]` Blocked

## Phase 1 — Audit
- [x] Read master spec + `.md/FAJR_ARCHITECTURE.md`, `ALARM_FLOW.md`, `LOCK_SCREEN_CHALLENGE.md`
- [x] Inspect `lib/`, `android/`, `assets/`, `pubspec.yaml`, tests, manifests, notification/alarm, widgets, persistence
- [x] Verify plan vs codebase (see findings below)
- [x] Create this status file

### Audit findings (2026-09-03)
- Entry: `lib/main.dart` → `app.dart` (GetMaterialApp, GetX). State: `PrayerTimesLogic` singleton GetxController.
- Prayer calc: custom `PrayerCalculationEngine` (not `adhan` pkg despite spec claim; `adhan: ^2.0.0+1` IS in pubspec but engine is hand-rolled). Methods: mwl/egypt/makkah/isna/karachi/custom. No moonsighting. Offsets: user `offset_*` + hidden base offsets + `iqama_offset_*`. Mosque/Mawaqit via `mosque_api.dart` + `OfflineCache`, source toggle calculated/mosque. Night thirds computed Maghrib→Fajr. Hijri via `hijri` pkg + `hijriOffset`. Caching via `CacheManager` (week JSON) + SharedPreferences lat/lon.
- Alarms: `AlarmScheduler.kt` (setAlarmClock for challenge, setExactAndAllowWhileIdle for prayer), `PrayerAlarmReceiver` (PARTIAL_WAKE_LOCK 120s, HIGH full-screen notification, direct startActivity fallback), `AlarmSound` (native loop, USAGE_ALARM, 5-min timeout, honors sound toggle), `PrayerTimeService` (foreground location service, 1s tick, fallback challenge trigger, ayat overlay, dhikr overlay, widget refresh 30s), `MainActivity` (setShowWhenLocked/setTurnScreenOn ONLY on alarm trigger, volume lock, exact-alarm settings intents). Dart: `_syncFajrChallengeAlarm`, `_checkFajrChallenge` (60s timer), `flutter_local_notifications` adhkar (Fajr+1h, Asr+1h).
- GAPS vs spec: no TIME_SET/TIMEZONE_CHANGED/DATE_CHANGED/MY_PACKAGE_REPLACED/LOCKED_BOOT/EXACT_ALARM_PERMISSION receivers; wakelock released immediately in `finally` (defeats purpose); no `canUseFullScreenIntent` Android14 guard; `scheduleAllFromPrefs` restores only 1 challenge + 1 prayer; no generic AlarmType layer; no Suhoor/PreFajr/Bedtime/Pre-Post/DND; single fajr challenge type only (Questions MCQ/text, count 1-10, no difficulty); no wake-up confirmation separation; no tracking/streak; no tracking widget; no Qibla; hardcoded Arabic strings; single adhan sound; no gentle ramp; channels: only persistent LOW + fajr HIGH + flutter_local prayer/adhkar.
- Persistence: SharedPreferences only (+ in-memory cache). No Hive/SQLite. Must reuse.
- Widgets: `PrayerWidgetProvider` + `PrayerWidgetLargeProvider` via `PrayerWidgetData` reading `flutter.widget_*` prefs. No tracking widget.
- Existing features to preserve: prayer calc, mosque/Mawaqit, iqama, offsets, Hijri adjust, night thirds, morning/evening adhkar, floating dhikr overlay, persistent notification, prayer widgets, masbaha/custom dhikr, ruqyah, dua, asma, ayat/hadith dialogs, dark mode, onboarding. — none removed.

## Phase 2 — Alarm foundation
- [x] 2A Manifest + receivers (boot/timezone/date/exact-alarm permission)
- [x] 2B Generic `AlarmType` + deterministic IDs + cancel-before-schedule + diagnostics
- [x] 2C Boot/timezone rescheduling without duplicates
- [x] 2D Lock-screen handling (showWhenLocked/turnScreenOn, full-screen intent, Android 13/14 guards)
- [x] 2E WakeLock/audio lifecycle (partial WL with timeout, no immediate release, AlarmSound ownership)
- [x] Verify existing Fajr alarm still works (`flutter analyze` clean, `flutter test` 51/51 green)

## Phase 3 — Challenge engine
- [x] 3A Generic `WakeUpChallenge` abstraction (start/reset/handleInput/isCompleted/progress)
- [x] 3B Migrate existing Questions challenge (MCQ + text input, 1/3/5/7/10 counts, difficulty Easy/Med/Hard)
- [x] 3C Wake-up confirmation ("أنا مستيقظ" → Well Done → record only after confirm)

## Phase 4 — Tracking
- [x] Daily log (`date`, fajr_completed, challenge_completed, wake_up_confirmed) in SharedPreferences
- [x] current_streak / longest_streak / history (+ missed-day, timezone-safe date keys)
- [x] Tracking UI (streak cards + today + calendar, Husn design language)
- [x] Migration-safe keys (keep `fajrChallengeEnabled` etc.)

## Phase 5 — Challenges
- [x] 5A Math (Easy/Med/Hard, dynamic gen, configurable count, no repeats) — implement→test→fix
- [x] 5B Memory (4 pairs/8 tiles, shuffle, flip delay, matched state, RTL, semantics)
- [x] 5C Shake (sensors_plus accelerometer, low/med/high sensitivity, debounce, unavailable-fallback to questions, stops listening on completion/dispose)
- [x] 5D Random (picks from persisted enabled pool only, pool checkboxes in settings)

## Phase 6 — Additional alarms
- [x] Pre-Fajr presets (5/10/15 + preserve custom 10–120) anchored to Fajr
- [x] Suhoor anchored (Fajr − X min, distinct from Fajr UI)
- [x] Bedtime (exact time + relative Fajr−7h, skip-tonight without disabling)
- [x] Pre/Post prayer (global + per-prayer toggles, offsets 5–60min, quiet notifications, no spam)
- [x] Calculation methods expanded (Kuwait/Qatar/Singapore/Turkey/Dubai/Moonsighting from adhan reference; legacy methods frozen; Tehran skipped — needs 4.5° Maghrib model)

## Phase 7 — Sounds
- [x] Sound selection (bundled adhan / system alarm ringtone / custom local file; no downloads)
- [x] Preview (native 4s) with stop action / volume floor 20% (never silent) / vibration (native, VIBRATE perm present) / loop toggle / gentle ramp 0/30/60/120s (native + honored in challenge screen)

## Phase 8 — Tracking widget
- [x] Small tracking widget (🔥 streak + Fajr ✓/—) reusing PrayerWidgetData sync, single data source (daily-log truth), updates on record + prayer sync + boot

## Phase 9 — Qibla
- [x] Offline bearing via adhan Qibla (no API) + tilt-compensated heading (sensors_plus accel/mag) + permission/sensor/calibration/interference/RTL handling + distance + drawer entry

## Phase 10 — Localization
- [x] ARB scaffold (ar/en/fr) + flutter_localizations wiring + language setting (Appearance) + migrated: drawer, tracking, Qibla, wake-up confirm/done. Religious source content untouched. Remaining legacy screens: incremental next.
- [x] Migrated: diagnostics, Fajr challenge (questions/math/memory/shake/confirm/done), challenge bottom sheet, notification settings, main settings (incl. 11 calc methods, asr, offsets, iqama, Hijri, mosque/GPS/about), prayer_times, mosque_map, masbaha/custom_dikr, dua, ruqyah, ruqyah_detail, asma, onboarding, azkar details, home_page. Null-safe `context.loc` (Arabic fallback) + Arabic/English widget-test coverage.
- [x] Batch 2 complete: `prayer_times_screen`, `mosque_map_screen`, `custom_dikr_screen` (masbaha + DikrCounterScreen), `dua_screen`, `ruqyah_screen`, `ruqyah_detail_screen`, `asmaa_allah_screen`, `azkar_details_screen`, `onboarding_screen` all migrated to ARB keys. `ayat_hadith_dialog` renders religious content dynamically (kept untranslated). New keys: `msSave`, `ctRefresh`, `mmRetry`, `mmEmptyNoMosques`, `mmEmptyNoResults`, `mmRefreshTimes`, `mmActiveMosqueBadge`, `mmDistanceKm`, `mmAdoptedNow`, `mmActiveMosque`, `mmAdoptThis`, `mmDirections`, `mmShare`, `mmJumua`, `mmFriday`, `mmAppName`, `mmPrayerTimesFor`, `azSave`, `azCopied`, `azSharePrefix`.
- [ ] Still hardcoded (kept intentionally): `strings.dart` globals (shared constants), prayer-name switch labels, country names (data), religious source text (Quran/Hadith/adhkar/dua — NEVER machine-translated)

## DND automation — done (spec §21 P2)
- [x] Explicit opt-in toggle (default OFF, never silent) + duration slider 10–60 min (default 20) in notification settings §5; amber warning banner + grant button when policy access missing (`nsDnd*` ARB keys complete in ar/en/fr).
- [x] Permission gating on both sides: Dart `isDndAccessGranted/openDndSettings/setDndMode` channel wrappers (try/catch → false) + native `MainActivity` handlers (SDK-guarded, double-checked `isNotificationPolicyAccessGranted`).
- [x] Prayer-window hook: `PrayerAlarmReceiver.handleDndDuringPrayer()` engages PRIORITY filter at each of the 5 prayers when enabled+granted, auto-restores to ALL after the duration (clamped 5–120); inert without access.
- [x] +4 tests (`dnd_automation_test.dart`: defaults OFF/20, prefs round-trip, graceful-inert without access, granted reporting) — 62/62 green.
- [ ] Possible follow-up (spec-optional "potentially"): pre-prayer DND lead-in window — deliberately not built; would need new exact-alarm plumbing for a P2 maybe.

## Final validation
- [x] `flutter analyze` clean (no new warnings)
- [x] `flutter test` green (55 tests incl. alarm/challenge/tracking/qibla/methods/diagnostics + EN locale)
- [x] Android build (`flutter build apk --debug`) passes
- [x] Real-world alarm matrix reasoned + limitations documented (see `ALARM_ARCHITECTURE.md` matrix section; OEM killers noted as platform limitation)
- [x] No Firebase/ads/tracking SDKs; offline-first preserved; no faked UI (only `sensors_plus` added — offline, no permissions)

## Remaining / follow-up (honest backlog, not blockers)
- [x] On-device bake-in (2026-09-04, SM M115F Android 12 / API 31, debug APK): install OK, MainActivity renders full prayer screen (Asr 16:37, Hijri/Gregorian correct, cached loc 35.947,0.111), no crash, no FATAL. `dumpsys alarm`: RTC_WAKEUP ACTION_PRAYER pending for Asr + ACTION_FAJR_CHALLENGE/SUHOOR/PRE_FAJR/BEDTIME/PRE_PRAYER/POST_PRAYER all registered at startup; cancel-before-schedule visible. Receivers registered: BootReceiver (BOOT/LOCKED_BOOT/MY_PACKAGE_REPLACED), TIME_SET/TIMEZONE_CHANGED/DATE_CHANGED, SCHEDULE_EXACT_ALARM granted. PrayerAlarmReceiver is exported=false (correct — shell broadcast test rightly blocked; spoof-proof).
- [ ] NEEDS HUMAN WITH PHONE: (1) device has notifications BLOCKED for the app (`allowNoti=false`, persisted via -r reinstall) — re-enable in Settings → Apps → Husn → Notifications or alarm heads-up/full-screen will be suppressed; (2) overnight Fajr lock-screen challenge + (3) real reboot reschedule — not auto-tested (reboot declined without asking; shell can't fire the non-exported receiver).
- [x] Advanced → Diagnostics UI screen (`diagnostics_screen.dart`: live permission states, native `AlarmScheduler.diagnostics()`, reschedule-all, streak sanity, real 5s alarm test + 3 widget tests)
- [x] Legacy ARB migration (drawer, tracking, Qibla, confirm/done, settings, diagnostics, challenge screens, prayer_times, mosque_map, masbaha, dua, ruqyah, asma, onboarding, azkar details, home_page) — done; `strings.dart` globals + religious source text kept intentionally
- [x] Extra adhkar reminder categories — spec §31: Wake-up (at Fajr), Sleep (Isha+1h), Friday Kahf (Fri 09:00 weekly, IDs 102/103/104) all scheduled/cancelled in `scheduleAdhkarNotifications()`; explicit toggles in notification settings §4 (`nsExtraAdhkarSection`); new categories default OFF (`?? false`), morning/evening keep legacy ON. Wake-up/sleep dua bodies stay Arabic (authentic source text, never translated); Kahf title/body now localized via existing `nsFridayKahfTitle/Body` ARB keys (ar/en/fr complete), resolved in-controller via `lookupAppLocalizations(app_language)` with Arabic fallback. +3 tests (`adhkar_reminders_test.dart`: defaults, migration-safe opt-in, trilingual Kahf) — 58/58 green.
- [ ] DND automation — spec §21 P2, needs notification-policy access + prayer-window hooks
- [ ] Quran/Khatmah ecosystem — explicitly out of scope for this phase per spec §28

## Phase 11 — 5-prayer tracker ecosystem (tracker/ reference design)
- [x] M1 data layer: `PrayerLogEntry`/`PrayerStatus`, pure `PointsEngine` (base table + Fajr ×2 / Isha ×1.5 + 8 level thresholds), `PrayerTrackingRepository` (goal-based streaks, settings, `clearAll`, one-time `migrateFajrLogs`), Fajr alarm mirror (manual wins). 15 unit tests.
- [x] M2 main screen: level pill + gem strip, اليوم 5-circle card (RTL), الهدف اليومي (goal stepper dialog), Hijri/Gregorian calendar (honors `hijriOffset`), 30-day overview + empty state. Drawer entry repointed (label → تتبع الصلوات). 15 `pt*` ARB keys. 3 widget tests.
- [x] M3 how-picker sheet: 6 options with effective-points preview, clear-entry, woman context hides mosque. 9 more ARB keys. 3 widget tests (options/points, context filter, clear flow).
- [x] M4 details/onboarding/menu: التفاصيل sheet (levels, context toggle, points table + meanings dialog, multipliers), first-run onboarding carousel (accept persists + opts into reminders), ⋯ menu (settings incl. reminders toggle / replay / widget how-to / pause with banner / destructive clear with confirm). ~40 ARB keys. 6 widget tests.
- [x] M5 smart reminders: quiet one-shot nudges (IDs 200–204, prayer+30min, unlogged only, `tracking_channel`, tap → tracker incl. cold start). Pure planner + `PrayerReminderService` (cache/refresh/cancel/re-arm, infallible). Hooks: prayer sync, onboarding accept, settings toggle, pause/resume, log/clear. `ptRemind*` ARB keys. Fake-platform tests (IDs/channel/payload/one-shot-ness) + planner tests — 9 tests + settings-toggle widget test.
- [x] L10n discipline: ARB files are the source of truth (`flutter gen-l10n` regenerates; never hand-edit generated Dart). Fixed `trackDays` `#`-literal bug at ARB layer (`{count}` interpolation).
- [x] Phase 12 cleanup: fixed remaining `#`-literal plurals at ARB layer (`sheetMinutes`, `nsDndMinutes`, `mmMosqueCount`, `azTimes`, `stEveryMinutes`, `nsBedtimeRelativeSub`) + `plural_strings_test.dart` (9 tests incl. tri-locale no-literal-`#` guard); diagnostics tracking card extended with 5-prayer snapshot (`diagnosticsSnapshot()`: streaks, level/points/goal, flags, reminder cache) + `diagFivePrayer` ARB key + snapshot/widget tests.
- [x] Phase 13 old-screen removal: deleted `FajrTrackingScreen` (superseded by `PrayerTrackingScreen`); notification-settings log button repointed (label `nsOpenLog` reused, no string changes); pruned 7 orphaned ARB keys (`trackTitle/Fajr/Challenge/Confirm/Done/Pending/Last30`) across ar/en/fr + regen. `trackToday/Current/Longest/Days` retained (used by new screen + challenge screen).
- [x] Phase 14 widget upgrade: tracking widget shows 5-prayer day progress (`●●●○○ n/5` + streak, title → تتبع الصلوات). New `widget_day_done`/`widget_day_goal` sync keys (log/clear/goal-change/prayer-sync rollover; legacy keys kept); tap opens the tracker (native `screen_to_open=tracking` + Dart routing in `onOpenScreen` and both cold-start consumers). Native metadata/labels updated. Sync-keys unit test; `flutter build apk --debug` passes (Kotlin + resources compile).
- [x] Phase 15 Husn-style restyle + settings move: tracker screens (main/sheets/onboarding/details) switched from reference purple to app language (Amiri, #1E1E28 cards, rose #D64463, settings-style AppBar). ⋯ menu + goal/settings sheets removed from tracker page (goal تعديل deep-links to Settings); new `TrackingSettingsSection` (goal, context, reminders, pause, replay, widget help, destructive clear) embedded in app Settings after prayer-data. Details context is display-only + Settings link. 5 section widget tests.
- [x] Phase 16 live widget countdown: small + large widget countdowns are now `Chronometer` ticking every second natively (`setLiveCountdown`: elapsedRealtime base, "- %s" format, countdown mode, API 24+ guard with static fallback). Seconds stay exact between re-renders and while the app/service is idle; prayer transitions still ride the 30s service tick / app open / boot. `flutter build apk --debug` passes.
- [x] Phase 17 offline calculation fix: the hand-rolled solar engine biased Asr/Maghrib/Isha ~±100s near equinoxes (single noon snapshot), mis-set Dhuhr +60s for Umm al-Qura-family methods (reference applies dhuhr:+1 only to MWL/Egypt/Karachi/ISNA/Singapore), and mis-implemented moonsighting seasonal twilight (Isha off by up to ~33 min). The engine now delegates astronomy to the `adhan` package (already a dependency) keeping the identical contract (seconds since local midnight, device-zone+DST anchoring, user offsets, madhab, custom angles, exact Maghrib+90m Isha for makkah/qatar). New `prayer_calculation_accuracy_test.dart`: 4 seasons × 11 methods + hanafi + custom angles match the reference exactly.
- [x] `flutter analyze` clean, `flutter test` 116/116 green.
