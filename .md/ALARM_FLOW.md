# Fajr App — Complete Alarm Flow

> Full execution trace from alarm creation to dismissal, based on decompiled code analysis.

---

## Phase 1: Alarm Scheduling — What Triggers Scheduling

Three entry points kick off alarm scheduling:

### 1a. Boot Receiver
**`BootCompletedReceiver`** — `sources/com/blink22/fajr/core/scheduler/alarm/receivers/BootCompletedReceiver.java:17`
- Registered for: `BOOT_COMPLETED`, `LOCKED_BOOT_COMPLETED`, `QUICKBOOT_POWERON`, `MY_PACKAGE_REPLACED`, `REBOOT`
- Calls `syncWorker.g()` → enqueues `ScheduleAlarmsWorkerManager` via WorkManager

### 1b. Date/Time Change Receiver
**`DateChangeReceiver`** — `sources/com/blink22/fajr/core/scheduler/alarm/receivers/DateChangeReceiver.java:17`
- Registered for: `DATE_CHANGED`, `TIME_SET`, `TIMEZONE_CHANGED`
- Same flow: `syncWorker.g()` → re-schedules all alarms

### 1c. Exact Alarm Permission Receiver
**`ExactAlarmPermissionReceiver`** — `sources/com/blink22/fajr/core/scheduler/alarm/receivers/ExactAlarmPermissionReceiver.java:46`
- Registered for: `android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED`
- Permission granted → launches `p268r4.m` coroutine → calls `ScheduleAlarmsUseCase`
- Permission denied → cancels ALL alarms across all types, posts notification

---

## Phase 2: WorkManager Orchestration

### `G4.a` (SyncWorker trigger)
**`sources/G4/a.java:32`** — `g()` method (line 93):
```java
A a10 = new A(ScheduleAlarmsWorkerManager.class);
a10.f34174c.f39678j = new C2742e();  // unique work policy
B b10 = (B) ((A) a10.d()).a();
p174l3.r rVarA0 = p174l3.r.a0(this.i);  // WorkManager.getInstance
rVarA0.m("ScheduleAlarmsWorkerManager", b10).I();  // enqueueUniqueWork
```

### `ScheduleAlarmsWorkerManager`
**`sources/com/blink22/fajr/core/workers/ScheduleAlarmsWorkerManager.java:22`**
- Extends `CoroutineWorker`
- Dependencies: `scheduleAlarmsUseCase` (`B5.C`), `toggleDoNotDisturbUseCase` (`w5.p`), logger
- `doWork()` (line 46):
  1. Launches `ScheduleAlarmsUseCase.b()` on IO scope
  2. Runs `ToggleDoNotDisturbUseCase`

---

## Phase 3: Use Case — Computing & Scheduling Each Alarm

### `ScheduleAlarmsUseCase`
**`sources/B5/C.java:17`** — Method `b()` (line 190):
- Cancels any previous scheduling job
- Launches `B5.A` coroutine — the main scheduling loop
- Iterates through **every active alarm type** and schedules each

### `ComputeAlarmTimeUseCase`
**`sources/B5/t.java:22`** — Methods `g()` and `h()`:
- Gets prayer times for the target date
- Finds the anchor prayer (Fajr/Sunrise for Suhoor/Fajr)
- Applies offset
- Checks weekday schedules
- Returns the exact `Date` for scheduling

---

## Phase 4: AlarmManager — The Actual Android Scheduling

### `DefaultAlarmHelper.x()`
**`sources/B5/f.java:686`**:
```java
public void x(V4.l alarmTime) {
    Context context = (Context) this.f1916a;
    AlarmManager alarmManager = (AlarmManager) context.getSystemService("alarm");
    PendingIntent pendingIntentN = n(alarmTime.getType());  // creates PendingIntent
    
    ((AlarmManager) systemService2).cancel(pendingIntentN);  // cancel old
    
    if (Build.VERSION.SDK_INT < 31 || alarmManager.canScheduleExactAlarms()) {
        PendingIntent activity = PendingIntent.getActivity(context, 1286, 
            launchIntentForPackage, 201326592);
        aVar.a(alarmTime.getDate().getTime(), pendingIntentN, activity);
    }
}
```

### `AlarmScheduler` — `sources/p333v4/a.java:9`
```java
public final void a(long j10, PendingIntent pendingIntent, PendingIntent pendingIntent2) {
    ((AlarmManager) systemService).setAlarmClock(
        new AlarmManager.AlarmClockInfo(j10, pendingIntent2),  // show in alarm clock UI
        pendingIntent  // the actual trigger PendingIntent
    );
}
```
Uses **`AlarmManager.setAlarmClock()`** — the highest priority alarm type in Android, survives Doze and battery optimization.

### `DefaultAlarmHelper.n()` — PendingIntent factory
**`sources/B5/f.java:500`**:
```java
public PendingIntent n(InterfaceC1301b interfaceC1301b) {
    Context context = (Context) this.f1916a;
    Intent intent = new Intent(context, AlarmReceiver.class);
    intent.setAction("com.blink22.prayer_scheduler.AlarmFired");
    intent.putExtra("alarmId", interfaceC1301b.getId());
    return PendingIntent.getBroadcast(context, interfaceC1301b.getId(), 
        intent, 201326592);  // FLAG_UPDATE_CURRENT | FLAG_IMMUTABLE
}
```

---

## Phase 5: Alarm Fires — BroadcastReceiver

### `AlarmReceiver.onReceive()`
**`sources/com/blink22/fajr/core/scheduler/alarm/receivers/AlarmReceiver.java:732`**
```java
public final void onReceive(Context context, Intent intent) {
    d(context, intent);  // lazy DI injection
    if (q.c(intent.getAction(), "com.blink22.prayer_scheduler.AlarmFired")) {
        int intExtra = intent.getIntExtra("alarmId", -1);
        if (intExtra == 13) return;  // suhoor removed special case
        
        BroadcastReceiver.PendingResult pendingResultGoAsync = goAsync();  // keep alive
        A.B(Ne.i.f13454c, new p268r4.c(this, context, intExtra, null));
        A.x(..., new p268r4.d(this, pendingResultGoAsync, null), 3);
    }
}
```

### Dispatch Logic — `AlarmReceiver.a()` (line 118)
Resolves alarm type from ID, then dispatches:

| Alarm type | Handler | Service Started |
|---|---|---|
| `UserAlarm` (Fajr/Suhoor) | `triggerAlarmUseCase.g()` | `AlarmService` |
| `Prayer` | `triggerAlarmUseCase.h()` | `PrayerService` |
| `PrePostPrayer` | inline | silent notification OR `PrePostPrayerService` |
| `BedtimeAlarm` | `triggerAlarmUseCase.e()` | bedtime notification |
| `WakeupCheck` (Fajr) | `triggerAlarmUseCase.d()` | `WakeupCheckService` |
| `WakeupCheck` (Suhoor) | `triggerAlarmUseCase.c()` | `WakeupCheckService` |
| `BeforeAlarm` | `triggerAlarmUseCase.f()` | "before alarm" notification |
| `AthkarAlarm` | inline | athkar notification |
| `DoNotDisturbAlarm` | `triggerAlarmUseCase.o.c()` | toggles DND mode |

---

## Phase 6: AlarmService — Sound + Foreground + Notification

### `AlarmService.onStartCommand()`
**`sources/com/blink22/fajr/core/scheduler/alarm/fajrAlarm/AlarmService.java:240`**

1. **Extracts alarm type** from intent extra (`"alarmType"`)
2. **Gets `AlarmChallenge`** (normal, math, memory, shake, questions, random)
3. **Builds notification** via `C0166c.g(L4.c(userAlarm, str), requestCode+344)`:
   - Channel: `Fajr-Channel` (`ChannelDetails.Alarm`)
   - Importance: `IMPORTANCE_HIGH` (4)
   - Category: `"alarm"`
   - Audio stream: `STREAM_ALARM`
   - Flags: `FLAG_ONGOING_EVENT | FLAG_NO_CLEAR`
   - Content intent: `PendingIntent.getActivity()` → `AlarmActivity.class` with extras `customRoute`, `alarmTag`, `isSnoozeOn`
   - Delete intent: `PendingIntent.getBroadcast()` → `DeleteNotificationReceiver`
4. **Starts foreground**: `startForeground(notificationId, notification)`
5. **Starts audio playback** via coroutine:
   - Creates `MediaPlayer` with `AudioAttributes(USAGE_ALARM, CONTENT_TYPE_MUSIC)`
   - `setLooping(true)` — alarm loops until dismissed
   - Resolves sound URI via `O8.h.d()` (user-selected or default azan)
   - `MediaPlayer.setDataSource()` → `prepare()` → `seekTo(0)` → `start()`
6. **Acquires WakeLock** via `AlarmServiceHelper.h()`:
   - `PowerManager.newWakeLock(PARTIAL_WAKE_LOCK, "Alarm wakeLock")`
   - `acquire(120000L)` — 2 minute timeout
7. **Acquires FULL_WAKE_LOCK** for screen-on (via `AlarmServiceHelper` additional path)

### Audio Attributes Decision (`p221o4/h.java`)
Checks 3 conditions:
1. DoNotDisturb disabled in Firebase config
2. Another DND config flag
3. `NotificationManager.interruptionFilter == FILTER_ALL`

Only if ALL pass → `USAGE_ALARM` (bypasses DND). Otherwise → `USAGE_NOTIFICATION`.

### AlarmService.onDestroy()
**`sources/com/blink22/fajr/core/scheduler/alarm/fajrAlarm/AlarmService.java:194`**:
```java
mediaPlayer.stop();
mediaPlayer.release();
audioManager.setStreamVolume(STREAM_ALARM, savedVolume, 0);
stopForeground(STOP_FOREGROUND_REMOVE);
sendBroadcast("com.blink22.fajr.ALARM_DISMISSED");
```

---

## Phase 7: AlarmActivity — The Challenge Screen

### `AlarmActivity.onCreate()`
**`sources/com/blink22/fajr/ui/views/alarm/AlarmActivity.java:195`**

1. **Lock-screen setup** (lines 207-213):
```java
if (Build.VERSION.SDK_INT >= 27) {
    setShowWhenLocked(true);
    setTurnScreenOn(true);
} else {
    getWindow().addFlags(6816768);  // SHOW_WHEN_LOCKED | DISMISS_KEYGUARD | TURN_SCREEN_ON
}
```

2. **Inflates layout**: `activity_alarm` (contains `NavHostFragment`)

3. **Routes to correct screen** via `i(intent)` (line 125):
   - `"wakeupCheck"` → `AreYouAwakeFragment`
   - `"suhoorWakeupCheck"` → `AreYouAwakeFragment`
   - UserAlarm tag match → `BeforeAlarmFragment` (challenge routing)
   - Default → `NormalAlarmFragment`

---

## Phase 8: Challenge System

### Challenge Routing — `BeforeAlarmFragment.q()`
**`sources/com/blink22/fajr/ui/views/alarm/` — BeforeAlarmFragment**
- Maps `AlarmChallenge` → navigation action via `p055d8/c.java`:
  - `ShakeToWake` → `ShakeToWakeFragment`
  - `AnswerQuestions` → `QuestionsFragment`
  - `MathQuestions` → `MathQuestionsFragment`
  - `MemoryChallenge` — `MemoryChallengeFragment`
  - `RandomChallenge` → `M4.b.b()` picks random from `isChallenge==true` items

### Challenge Base Classes

**Base Fragment** (`p132i7/h.java`):
- Registers BroadcastReceiver for `ALARM_FIRED` → finishes activity if new alarm fires
- Observes countdown arc state and finalize result SharedFlow
- Sets up screen brightness, tutorial snackbar, back press handling

**Base ViewModel** (`p132i7/l.java`):
- `l()` (line 127): **Completion entry point** — sets `f32247S = true`, cancels countdown, launches finalize coroutine
- `m()`: Pauses alarm (sends `PAUSE_ALARM` intent to `AlarmService`)
- `onStop()`: Restarts alarm (sends `RESTART_ALARM` intent) — unless `f32247S == true` (completed)

### Per-Challenge Completion Detection

| Challenge | ViewModel | Detection | File |
|---|---|---|---|
| **Shake** | `p208n7/a.java` | `progress += 150` per shake, `percentage >= 100%` | `p208n7/d.java` |
| **Math** | `p160k7/c.java` | 3 correct answers, 1000ms delay between | `p160k7/e.java` → `p160k7/f.java` |
| **Memory** | `p178l7/i.java` | Match all 4 pairs, 600ms delay after match | `p178l7/g.java` |
| **Questions** | `p194m7/g.java` | 3 questions answered, 1000ms delay | `p194m7/f.java` |

---

## Phase 9: Challenge Completion → Alarm Dismissal

### Step 1: Challenge calls `l()`
When completion is detected, the challenge ViewModel calls base `l()` (`p132i7/l.java:127`):
```java
public final void l() {
    f32247S = true;  // mark completed
    h();  // cancel countdown
    // launch finalize coroutine
}
```

### Step 2: Finalize coroutine — `p132i7/i.java:33`
```java
if (tutorial mode) {
    emit(action → shows tutorial snackbar);
} else {
    C0166c.k(userAlarm);  // stops AlarmService
    emit(action → navigate to WellDone);
}
```

### Step 3: Navigate to WellDone
**`p132i7/d.java:68`** — observer on SharedFlow:
- `a.f32216a` → `Y6.F` → `action_alarm_challenge_to_wellDone` with `popUpToInclusive=true`
- `popUpToInclusive` **pops the entire nav graph** (main_navigation) — WellDone becomes the only fragment

### Step 4: AlarmService stops
- `C0166c.k()` stops `AlarmService`
- `AlarmService.onDestroy()` (line 194):
  - `mediaPlayer.stop()` + `mediaPlayer.release()`
  - `stopForeground(STOP_FOREGROUND_REMOVE)`
  - `audioManager.setStreamVolume()` — restores original volume
  - `sendBroadcast("com.blink22.fajr.ALARM_DISMISSED")`

### Step 5: Activity finishes
- WellDoneFragment is the only fragment left (backstack cleared)
- No outgoing navigation actions
- User presses Back → backstack empty → `AlarmActivity.finish()`
- Alternatively: `F7/j.java` case 3 catches `ALARM_DISMISSED` broadcast → calls `activity.finish()`

---

## Complete Flow Diagram

```
BOOT_COMPLETED / DATE_CHANGED / EXACT_ALARM_PERMISSION
         │
         ▼
BootCompletedReceiver / DateChangeReceiver / ExactAlarmPermissionReceiver
         │
         ▼
G4.a.g() ── WorkManager.enqueueUniqueWork("ScheduleAlarmsWorkerManager")
         │
         ▼
ScheduleAlarmsWorkerManager.doWork()
         │
         ├──► B5.C.b() (ScheduleAlarmsUseCase)
         │         │
         │         ├──► B5.t.g()/h() (compute next alarm time)
         │         │
         │         └──► B5.f.x() (DefaultAlarmHelper)
         │                   │
         │                   ├── n() → PendingIntent.getBroadcast(AlarmReceiver)
         │                   └── p333v4.a.a() → AlarmManager.setAlarmClock()
         │
         └──► w5.p.b() (toggle DND)

  ════════════════════ TIME PASSES ════════════════════

Android fires PendingIntent
         │
         ▼
AlarmReceiver.onReceive("com.blink22.prayer_scheduler.AlarmFired")
         │
         ├── goAsync() → keeps process alive
         ├── resolves alarmId → alarm type
         ├── checks isCorrectPrayerTimeUseCase
         │
         ▼
TriggerAlarmUseCase dispatch:
         │
         ├── UserAlarm ──► AlarmServiceHelper.h()
         │                    │
         │                    ├── WakeLock.acquire(120s)
         │                    └── startForeground()
         │                          │
         │                          ├── MediaPlayer(looping=true, USAGE_ALARM)
         │                          ├── Notification(HIGH importance)
         │                          └── AlarmActivity(showWhenLocked + turnScreenOn)
         │
         ├── Prayer ────► PrayerService
         ├── PrePostPrayer ──► PrePostPrayerService
         ├── WakeupCheck ──► WakeupCheckService
         └── DoNotDisturbAlarm ──► toggle DND

  ════════════════════ ALARM RINGING ════════════════════

User taps notification / Full-screen intent fires
         │
         ▼
AlarmActivity.onCreate()
         │
         ├── setShowWhenLocked(true) + setTurnScreenOn(true)
         ├── routes to BeforeAlarmFragment
         │
         ▼
BeforeAlarmFragment.q() → routes to challenge:
         │
         ├── ShakeToWakeFragment
         ├── QuestionsFragment
         ├── MathQuestionsFragment
         ├── MemoryChallengeFragment
         └── RandomChallengeFragment → M4.b.b() picks one
         │
         ▼
Challenge ViewModel detects completion
         │
         ▼
l() → sets completed flag → finalize coroutine
         │
         ├── C0166c.k() → stops AlarmService
         │                    │
         │                    ├── mediaPlayer.stop() + release()
         │                    ├── stopForeground()
         │                    ├── restore audio volume
         │                    └── broadcast ALARM_DISMISSED
         │
         └── emit action → navigate to WellDone
                              │
                              ▼
                    WellDoneFragment (popUpToInclusive clears backstack)
                              │
                              ▼
                    User presses Back → AlarmActivity.finish()
```

---

## Supporting Receivers

| Receiver | Action | Purpose |
|---|---|---|
| `DeleteNotificationReceiver` | `com.blink22.prayer_scheduler.notification_cancelled` | Cleans up when user swipes notification |
| `BeforeAlarmSkipOnceReceiver` | `com.blink22.fajr.ACTION_TURN_OFF_ALARM` | Skip next fajr/suhoor once |
| `SuhoorBedtimeSkipOnceReceiver` | `com.blink22.fajr.ACTION_SKIP_SUHOOR_ONCE` | Skip suhoor bedtime once |

---

## Notification Type Hierarchy — `sources/L4/l.java`

| Class | Channel | Full-Screen | Purpose |
|---|---|---|---|
| `L4.c` | `Fajr-Channel` | disabled | UserAlarm (Fajr/Suhoor) urgency |
| `L4.g` | `SilentPrayerChannel` | conditional | Prayer notification |
| `L4.i` | `SilentPrayerChannel` | conditional | Challenge alarm (shake/math/etc) |
| `L4.k` | `SilentPrayerChannel` | conditional | Redirect alarm with custom URL |
| `L4.d` | Athkar channel | disabled | Athkar alarm |
| `L4.e/f/h/j` | various | various | Dismissable/bedtime/before types |

### Full-Screen Intent Logic — `sources/B5/C0166c.java:737-745`
```java
if (zBooleanValue || (Build.VERSION.SDK_INT >= 34 && !notificationManager.canUseFullScreenIntent())) {
    z12 = false;  // NO full-screen intent
} else {
    z12 = true;   // USE full-screen intent
}
if (z12) {
    c1548q.f21733h = activity;  // sets fullScreenIntent
    c1548q.e(128, true);        // FLAG_HIGH_PRIORITY (heads-up)
}
```

---

## Permission Summary (from AndroidManifest.xml)

| Permission | Purpose |
|---|---|
| `SCHEDULE_EXACT_ALARM` (maxSdkVersion=32) | Exact alarms on older APIs |
| `USE_EXACT_ALARM` | Exact alarms on API 33+ |
| `USE_FULL_SCREEN_INTENT` | Full-screen alarm notification |
| `WAKE_LOCK` | Keep CPU alive during alarm |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SYSTEM_EXEMPTED` | Alarm as foreground service |
| `POST_NOTIFICATIONS` | Show alarm notification |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule alarms on boot |
| `VIBRATE` | Alarm vibration (declared but not used in alarm flow) |
| `ACCESS_FINE_LOCATION` | Qibla compass |
| `INTERNET` | Firebase/online features |

---

## Decompiler Notes

- `C0166c.k()` (finalize/dismiss alarm) failed to decompile — method body skipped by Jadx
- `TriggerAlarmUseCase.g()` (UserAlarm handler) method body not fully available
- `AlarmService` decompiled code has duplicated Runnable blocks from Jadx `IfRegionVisitor` errors — these are Jadx bugs, not app bugs
- `F7/j.java` is a multi-purpose BroadcastReceiver handling multiple action cases (ALARM_FIRED, ALARM_DISMISSED, HIDE_NOTIFICATION, etc.)
