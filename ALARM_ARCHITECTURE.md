# ALARM_ARCHITECTURE.md — Husn-el-Muslim native alarm layer

## Chain

```text
Dart (PrayerTimesLogic computes next trigger from prayer times + offsets)
  │ MethodChannel com.ahmed.hisnelmuslim/prayer_notification
  ▼
AlarmScheduler (Kotlin object — single scheduling layer)
  │ AlarmManager.setAlarmClock [wake-up: Fajr challenge, Suhoor, Pre-Fajr]
  │ AlarmManager.setExactAndAllowWhileIdle [informational: prayer ayat, Bedtime]
  ▼
PrayerAlarmReceiver (goAsync + PARTIAL_WAKE_LOCK 120s timeout, never released early)
  │ Fajr/Suhoor/Pre-Fajr → AlarmSound.play (USAGE_ALARM loop, 5-min safety cap)
  │                     → HIGH notification + full-screen intent (Android 14 guarded)
  │                     → MainActivity (setShowWhenLocked/setTurnScreenOn ONLY on trigger)
  │ Prayer → PrayerTimeService ayat overlay
  │ Bedtime → reminder notification (no sound loop, no challenge)
  ▼
Flutter UI (FajrChallengeScreen / overlays)
```

The keyguard is never dismissed and the device PIN is never bypassed —
the activity is only drawn above it where Android permits.

## Identity & duplicates

Every alarm has a deterministic request code (`AlarmKind`: 9001/9101/9102/9103,
prayers 9002–9010). Every schedule path cancels the old PendingIntent first.
Timestamps persist in `prayer_service_prefs` gated by their Flutter toggle, so
reboot rescheduling never resurrects a user-disabled alarm.

## Rescheduling triggers

`BootReceiver` (BOOT/LOCKED_BOOT/QUICKBOOT/MY_PACKAGE_REPLACED),
`TimeChangeReceiver` (TIME_SET/TIMEZONE_CHANGED/DATE_CHANGED/MY_PACKAGE_REPLACED),
`ExactAlarmPermissionReceiver` (granted → re-arm, revoked → cancel armed exact
alarms so the UI never claims phantom success). All delegate to
`BootReceiver.reschedule()` → `AlarmScheduler.scheduleAllFromPrefs()`.

## Alarm kinds & priorities

| Kind | Code | API | Sound | UI |
|---|---|---|---|---|
| Fajr challenge | 9001 | setAlarmClock | AlarmSound loop + vibrate + ramp | full-screen + challenge + confirm |
| Suhoor | 9101 | setAlarmClock | AlarmSound loop | full-screen, distinct "وقت السحور" |
| Pre-Fajr | 9102 | setAlarmClock | AlarmSound loop | full-screen warning |
| Bedtime | 9103 | setExactAndAllowWhileIdle | none | quiet reminder (skip-tonight supported) |
| Pre-prayer | 9104 | setExactAndAllowWhileIdle | none | quiet reminder |
| Post-prayer | 9105 | setExactAndAllowWhileIdle | none | quiet reminder |
| Prayer ayat | 9002–9010 | setExactAndAllowWhileIdle | adhan overlay | ayat overlay |

## Real-world matrix (reasoned, not lab-tested on every OEM)
- Screen ON / app open / app closed / removed from recents: covered
  (AlarmManager + goAsync + foreground service + WakeLock + AlarmSound native).
- Locked: full-screen intent + showWhenLocked/turnScreenOn; keyguard NOT
  dismissed on API 27+ (by design, no security bypass).
- Reboot / update / timezone / date change: BootReceiver + TimeChangeReceiver
  rebuild from gated prefs (cancel-before-schedule, no duplicates).
- Doze / battery optimization: setAlarmClock is Doze-exempt; exact-while-idle
  for the rest; battery-opt guidance banner stays in settings.
- Exact-alarm revoked: schedules return false (no phantom success);
  ExactAlarmPermissionReceiver cancels armed alarms on revoke, re-arms on grant.
- Notification "No alert" mode: every trigger returns silently (user choice).
- Aggressive OEM killers (some Xiaomi/Huawei/OnePlus/Samsung builds) can still
  delay background delivery — platform limitation, documented, not claimed solved.
- Shake sensor missing → fallback button to Questions (never trapped).
- No Firebase/ads/tracking SDKs added. sensors_plus only (offline, no
  permissions). file_picker was already a dependency.

## Failure modes (detail)

- Exact-alarm permission revoked → schedule calls return false, UI reports it.
- Notification mode "No alert" (3) → all triggers return silently.
- Full-screen intent denied (Android 14) → heads-up notification fallback.
- Sound toggle off → AlarmSound + challenge screen stay silent.
- Doze / app-killed / reboot → setAlarmClock + foreground service + WakeLock
  cover it; OEM aggressive killers remain a documented limitation.
