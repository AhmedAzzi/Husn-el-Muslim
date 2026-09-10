# TRACKING_ARCHITECTURE.md — 5-prayer tracker ecosystem (SharedPreferences, no new DB)

## Per-prayer logs
Keys: `ptrack_log_yyyy-MM-dd_<0..4>` → `{date, prayer, status, ts}` (local-date
key, timezone-safe; index 0 Fajr .. 4 Isha). Status: takbeer / mosque / jamaa /
onTimeAlone / late / missed. Absence = unlogged.

Settings: `ptrack_context` (man/woman; woman hides the mosque option),
`ptrack_disabled` (pause), `ptrack_onboarded`, `ptrack_daily_goal` (1..5,
default 5), `ptrack_streak_longest` (high-water mark), `ptrack_reminders`
(smart-reminder opt-in, default OFF).

- Streak day = ≥ daily-goal prayers performed (missed excluded). `currentStreak()`
  walks back from today (or yesterday if today is pending); a missed past day
  breaks the chain; future dates ignored; re-logs replace idempotently.
- `history`/`entriesForRange` feed the calendar + 30-day overview — no derived
  data stored, no fakes.

## Points engine (pure, `PointsEngine`)
Base: takbeer +30, mosque +27, jamaa +14, onTimeAlone +1, late +1, missed −10.
Multipliers: Fajr ×2, Dhuhr/Asr/Maghrib ×1, Isha ×1.5 (rounded; missed scales
too, e.g. Fajr missed = −20). 30-day rolling total → levels 1..8 at thresholds
1 / 250 / 600 / 1100 / 1800 / 2800 / 4100 / 5450.

## Fajr legacy (migration-safe)
- `recordWakeUpSuccess()` (alarm confirm) also mirrors Fajr=onTimeAlone into the
  5-prayer log — manual entries always win (never overwritten).
- `migrateFajrLogs()` imports old `fajr_log_*` wake-up successes once
  (flag `ptrack_fajr_migrated` + per-day guards). Old keys
  (`fajr_log_*`, `fajr_streak_longest`) are left untouched.
- `clearAll()` ("مسح بيانات التتبع") wipes `ptrack_log_*` + longest only;
  settings (context/goal/onboarded/reminders) survive.

## Smart logging reminders (`PrayerReminderService`, IDs 200..204)
- Quiet ONE-SHOT exact schedules (never daily-repeat): prayer time + 30 min,
  only for unlogged prayers with fire time in the future. Payload
  `PrayerTrack_Log` opens the tracker (live tap + cold-start pending payload).
- `refreshWithMoments()` (prayer sync: app start + settings changes) caches
  times at `ptrack_times_<date>` and reschedules. `refreshFromCache()`
  (onboarding accept, settings toggle, un-pause) reuses the cache.
- `onLogged()` cancels that prayer's reminder (no times needed);
  `onCleared()` re-arms one from cache. Pause / opt-out cancels all.
- Coverage: today only (times shift daily); needs one app open / sync per day.
  All service methods are infallible (never throw).

## Localization (gen-l10n, ARB sources of truth)
Keys live in `lib/l10n/app_{ar,en,fr}.arb` (`pt*`, plural-safe `{count}`
interpolation — never hand-edit the generated `app_localizations*.dart`;
`flutter pub get` / `flutter gen-l10n` regenerates them).
