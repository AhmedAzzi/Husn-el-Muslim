# Fajr App — HOW THE CHALLENGE OPENS ON A LOCKED PHONE

> This is the highest-priority analysis. Every conclusion references exact source files, line numbers, and code from the decompiled APK.

---

## Executive Summary

The Fajr alarm uses a **multi-layered approach** to display its challenge on a locked phone:

1. **`AlarmManager.setAlarmClock()`** — survives Doze mode, battery optimization, app standby
2. **`ForegroundService`** with PARTIAL WakeLock — keeps CPU alive during ringing
3. **HIGH-importance notification** (`IMPORTANCE_HIGH`) — appears on lock screen as heads-up/peek
4. **`AlarmActivity` with `setShowWhenLocked(true)` + `setTurnScreenOn(true)`** — renders the challenge UI directly on top of the keyguard
5. **Conditional full-screen intent** — used for prayer/wakeup-check alarm types, but NOT for the raw Fajr urgency alarm

The challenge does **NOT** use `KeyguardManager.requestDismissKeyguard()` or any keyguard dismissal API. On modern Android (API 27+), the keyguard stays in place — the challenge activity is simply drawn above it.

---

## The Exact Chain: Alarm Firing → Challenge on Locked Screen

### Step 1: AlarmManager fires PendingIntent

**File:** `sources/p333v4/a.java:9`
```java
public final void a(long j10, PendingIntent pendingIntent, PendingIntent pendingIntent2) {
    ((AlarmManager) systemService).setAlarmClock(
        new AlarmManager.AlarmClockInfo(j10, pendingIntent2),
        pendingIntent
    );
}
```

**File:** `sources/B5/f.java:500` — PendingIntent targets `AlarmReceiver`
```java
Intent intent = new Intent(context, AlarmReceiver.class);
intent.setAction("com.blink22.prayer_scheduler.AlarmFired");
intent.putExtra("alarmId", interfaceC1301b.getId());
return PendingIntent.getBroadcast(context, interfaceC1301b.getId(), intent, 201326592);
```

`setAlarmClock()` is the **highest-priority** alarm API — Android treats it as an alarm clock, bypassing Doze, App Standby, and battery optimization.

### Step 2: AlarmReceiver receives the broadcast

**File:** `sources/com/blink22/fajr/core/scheduler/alarm/receivers/AlarmReceiver.java:732`
```java
public final void onReceive(Context context, Intent intent) {
    d(context, intent);  // lazy DI injection (singleton pattern)
    if (q.c(intent.getAction(), "com.blink22.prayer_scheduler.AlarmFired")) {
        int intExtra = intent.getIntExtra("alarmId", -1);
        BroadcastReceiver.PendingResult pendingResultGoAsync = goAsync();  // keep alive
        A.B(Ne.i.f13454c, new p268r4.c(this, context, intExtra, null));
        A.x(..., new p268r4.d(this, pendingResultGoAsync, null), 3);
    }
}
```

- `goAsync()` keeps the BroadcastReceiver alive while the coroutine processes
- The coroutine resolves the alarm type from the ID and dispatches

### Step 3: TriggerAlarmUseCase starts AlarmService

**File:** `sources/p205n4/m.java:34` — `g()` method handles UserAlarm (Fajr/Suhoor)

**File:** `sources/Ma/E1.java:251-286` — `h()` method acquires WakeLock and starts service:
```java
public void h(Context context, InterfaceC1301b alarm) {
    // Start foreground service
    H1.c.f(context, a(context, alarm));
    g(new V4.G(alarm));  // state = "Running"

    synchronized (this) {
        PowerManager.WakeLock wakeLock = (PowerManager.WakeLock) this.f12103a;
        if (wakeLock == null || !wakeLock.isHeld()) {
            Object systemService = context.getSystemService("power");
            PowerManager.WakeLock wakeLockNewWakeLock =
                ((PowerManager) systemService).newWakeLock(1, "Wakelock: " + d());
            wakeLockNewWakeLock.setReferenceCounted(false);
            wakeLockNewWakeLock.acquire(120000L);  // 2 MINUTE TIMEOUT
            this.f12103a = wakeLockNewWakeLock;
        }
    }
}
```

- **WakeLock type = 1** = `PARTIAL_WAKE_LOCK` (keeps CPU running, screen can be off)
- **120-second timeout** — alarm must complete within 2 minutes or the WakeLock auto-releases
- `setReferenceCounted(false)` — only one WakeLock instance at a time

### Step 4: AlarmService starts foreground with HIGH-importance notification

**File:** `sources/com/blink22/fajr/core/scheduler/alarm/fajrAlarm/AlarmService.java:240` — `onStartCommand()`

```java
// 1. Build notification
this.f24502B = c0166c.g(cVar, requestCode);  // C0166c.g() builds notification

// 2. Post notification and start foreground
AbstractC1536e.f(this, notificationId, notification, 1024);  // notify()
startForeground(notificationId2, notification2);

// 3. Start alarm sound
iVar2.e(userAlarm4, redirectionPath);  // alarmServiceHelper → starts sound coroutine
```

**File:** `sources/B5/C0166c.java:515-553` — Notification building:
```java
// Content intent → AlarmActivity with alarm extras
Intent intent2 = new Intent(contextG, AlarmActivity.class);
intent2.putExtra("customRoute", redirection);  // challenge routing
intent2.putExtra("isSuhoor", alarm == userAlarm);
intent2.putExtra("alarmTag", alarm.getTag());
intent2.putExtra("isSnoozeOn", snooze);
intent2.setFlags(FLAG_ACTIVITY_NEW_TASK);  // 268435456
PendingIntent activity = PendingIntent.getActivity(contextG, i, intent2, FLAG_IMMUTABLE);
```

**File:** `sources/B5/C0166c.java:473-888` — Notification properties:
```java
// Channel: "Fajr-Channel" (ChannelDetails.Alarm)
// Importance: 4 (IMPORTANCE_HIGH) — appears on lock screen
// Category: 1 ("alarm")
// Audio stream: 1 (STREAM_ALARM)
// Defaults: DEFAULT_SOUND
// Flags: FLAG_ONGOING_EVENT(2) | FLAG_NO_CLEAR(32)
// Visibility: PUBLIC (visible on lock screen)
```

### Step 5: Notification channel has IMPORTANCE_HIGH

**File:** `sources/B5/f.java:385-452` — Channel creation:
```java
case 2-13:  // ALL channels except CountdownNotification
    importance = 4;  // IMPORTANCE_HIGH
    break;
```

**File:** `sources/X6/a.java:16` — Channel construction:
```java
new NotificationChannel(channelId, channelName, importance)
```

`IMPORTANCE_HIGH` means:
- Notification **appears on the lock screen**
- Shows as **heads-up/peek** when screen is on
- **Makes sound** (unless overridden)
- **Can use full-screen intent**

### Step 6: AlarmActivity opens with lock-screen flags

**File:** `sources/com/blink22/fajr/ui/views/alarm/AlarmActivity.java:207-213`
```java
// In onCreate():
if (Build.VERSION.SDK_INT >= 27) {
    setShowWhenLocked(true);   // draws activity above the keyguard
    setTurnScreenOn(true);     // turns the screen on
} else {
    // Legacy flags for API < 27
    // 6816768 = 0x680400 = FLAG_SHOW_WHEN_LOCKED(0x80000) 
    //                            | FLAG_DISMISS_KEYGUARD(0x400000)
    //                            | FLAG_TURN_SCREEN_ON(0x200000)
    //                            | FLAG_KEEP_SCREEN_ON(0x400)
    getWindow().addFlags(6816768);
}
```

**Critical behavior difference:**
- **API 27+**: Uses modern `setShowWhenLocked()` + `setTurnScreenOn()`. Keyguard is **NOT dismissed** — the activity is drawn above it.
- **API < 27**: Uses legacy window flags including `FLAG_DISMISS_KEYGUARD` — actually dismisses the lock screen.

### Step 7: AlarmActivity routes to challenge

**File:** `sources/com/blink22/fajr/ui/views/alarm/AlarmActivity.java:125` — `i(intent)` method:
```java
String stringExtra = intent.getStringExtra("customRoute");
if (stringExtra != null) {
    // Routes based on customRoute value:
    // "wakeupCheck" → AreYouAwakeFragment
    // "ShakeToWake" → ShakeToWakeFragment
    // "QuestionsScreen" → QuestionsFragment
    // "MathQuestions" → MathQuestionsFragment
    // "MemoryChallenge" → MemoryChallengeFragment
    // "randomChallenge" → RandomChallengeFragment (via M4.b.b())
    // "prayerAlarm?id=N" → NormalAlarmFragment
}
```

### Step 8: Challenge Fragment opens

Each challenge fragment:
1. Extends `p132i7/h.java` (base Fragment)
2. Base ViewModel calls `m()` → sends `PAUSE_ALARM` to `AlarmService` (pauses MediaPlayer ringing)
3. Shows the challenge UI
4. When completed, calls `l()` → finalize → navigate to WellDone → finish activity

---

## Full-Screen Intent — When Used vs Not Used

### Full-Screen Intent Logic

**File:** `sources/B5/C0166c.java:737-745`
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

### Which alarm types get full-screen intent

| Notification Type | `disableFullScreenIntent` | Gets Full-Screen Intent |
|---|---|---|
| `L4.c` (UserAlarm — Fajr/Suhoor urgency) | `true` | **NO** |
| `L4.g` (Prayer notification) | config-dependent | Conditional |
| `L4.i` (Challenge alarm — shake/math/etc) | `false` | **YES** |
| `L4.k` (Redirect alarm) | config-dependent | Conditional |
| `L4.d` (Athkar) | `false` | **YES** |

**Key finding:** The main Fajr urgency alarm (`L4.c`) does **NOT** use a full-screen intent. Instead, it relies entirely on:
- HIGH-importance notification → appears on lock screen
- `AlarmActivity.setShowWhenLocked(true)` → draws above keyguard
- `AlarmActivity.setTurnScreenOn(true)` → turns screen on

For **challenge alarms** (`L4.i`), a full-screen intent IS set — this means the activity launches automatically (without tap) on older Android versions.

### Android 14+ (API 34) special handling
```java
Build.VERSION.SDK_INT >= 34 && !notificationManager.canUseFullScreenIntent()
```
If the user hasn't granted `USE_FULL_SCREEN_INTENT` on Android 14+, the full-screen intent is disabled (falls back to heads-up notification).

---

## Behavior Under Different Device States

### Screen ON (unlocked)
1. `AlarmManager.setAlarmClock()` fires → `AlarmReceiver.onReceive()` runs
2. `AlarmService` starts foreground → MediaPlayer plays sound → HIGH notification heads-up appears
3. User taps notification → `AlarmActivity.onCreate()` runs with `setShowWhenLocked(true)` (no effect since already unlocked)
4. Challenge UI appears normally

### Screen OFF (locked)
1. `AlarmManager.setAlarmClock()` fires → CPU wakes up
2. `PARTIAL_WAKE_LOCK` keeps CPU alive
3. `AlarmService` starts foreground → MediaPlayer plays sound
4. `IMPORTANCE_HIGH` notification **appears on lock screen** (peek/heads-up)
5. For challenge types with full-screen intent → `AlarmActivity` launches automatically (turns screen on)
6. For urgency alarm type → user taps notification → `AlarmActivity` launches
7. `setTurnScreenOn(true)` **turns the screen on**
8. `setShowWhenLocked(true)` **draws the challenge above the keyguard**

### Device is locked (screen on or off)
- Same as above — `AlarmActivity` renders on top of the keyguard
- Keyguard is **NOT dismissed** on API 27+ (challenge is drawn above it)
- Keyguard IS dismissed on API < 27 (via `FLAG_DISMISS_KEYGUARD`)

### App is in background
- `AlarmManager.setAlarmClock()` fires regardless of app state
- `goAsync()` in `AlarmReceiver` keeps process alive during processing
- `startForeground()` in `AlarmService` prevents process death
- `PARTIAL_WAKE_LOCK` ensures CPU stays active

### App process has been killed
- `goAsync()` in `AlarmReceiver` re-creates the process
- `startForeground()` in `AlarmService` keeps it alive
- `BootCompletedReceiver` and `DateChangeReceiver` re-schedule alarms after process restart
- `EXTRA_FROM_BACKGROUND` on service intent allows foreground service start from background

### Device has rebooted
- `BootCompletedReceiver` fires on `BOOT_COMPLETED`
- Calls `syncWorker.g()` → `WorkManager.enqueueUniqueWork("ScheduleAlarmsWorkerManager")`
- All alarms are re-computed and re-scheduled
- `BootCompletedReceiver` also handles `LOCKED_BOOT_COMPLETED` (Direct Boot aware)

---

## All Lock-Screen Related APIs Found in Code

### In `AlarmActivity.java` (lines 207-213)
```java
// API 27+ path:
setShowWhenLocked(true);
setTurnScreenOn(true);

// API < 27 path:
getWindow().addFlags(6816768);  // SHOW_WHEN_LOCKED | DISMISS_KEYGUARD | TURN_SCREEN_ON | KEEP_SCREEN_ON
```

### In `Ma/E1.java` (lines 274-277) — WakeLock
```java
PowerManager.WakeLock wakeLockNewWakeLock =
    ((PowerManager) systemService).newWakeLock(1, "Wakelock: " + d());
wakeLockNewWakeLock.setReferenceCounted(false);
wakeLockNewWakeLock.acquire(120000L);
```
Type 1 = `PARTIAL_WAKE_LOCK`

### In `B5/C0166c.java` (lines 737-745) — Full-screen intent
```java
c1548q.f21733h = activity;  // fullScreenIntent
c1548q.e(128, true);        // FLAG_HIGH_PRIORITY
```

### In `B5/f.java:385-452` — Notification channel
```java
importance = 4;  // IMPORTANCE_HIGH
```

### In `B5/C0166c.java:473-888` — Notification properties
```java
c1548q.f21721D = 1;  // audioStreamType = STREAM_ALARM
c1548q.f21735k = 2;  // priority = PRIORITY_HIGH
// category = "alarm"
// visibility = PUBLIC
```

### NOT found anywhere in app code:
- `KeyguardManager` — only found in Firebase SDK (`Fc/f.java:894`), not in app code
- `requestDismissKeyguard` — **zero matches**
- `FLAG_DISMISS_KEYGUARD` — only in legacy path for API < 27

---

## The Challenge System — Complete Class Map

### Challenge Routing

**File:** `sources/com/blink22/fajr/ui/views/alarm/` — `BeforeAlarmFragment.q()`

Routes based on `AlarmChallenge` enum:
| Challenge | Navigation Action | Fragment | ViewModel |
|---|---|---|---|
| `ShakeToWake` | `action_to_shakeToWakeFragment` | `ShakeToWakeFragment` | `p208n7/a.java` |
| `AnswerQuestions` | `action_to_alarmQuestionsFragment` | `QuestionsFragment` | `p194m7/g.java` |
| `MathQuestions` | `action_to_mathQuestionsFragment` | `MathQuestionsFragment` | `p160k7/c.java` |
| `MemoryChallenge` | `action_to_memoryChallengeFragment` | `MemoryChallengeFragment` | `p178l7/i.java` |
| `RandomChallenge` | `M4.b.b()` picks random | → maps to one of above | → maps to one of above |

### Challenge Base Classes

**Base Fragment:** `sources/p132i7/h.java`
- Registers BroadcastReceiver for `ALARM_FIRED` → finishes activity if new alarm fires
- Observes `q().f32244P` (countdown arc state) and `q().f32238J` (finalize SharedFlow)
- Sets up screen brightness, tutorial snackbar, back press handling

**Base ViewModel:** `sources/p132i7/l.java`
- `l()` (line 127): Completion entry point — sets completed flag, launches finalize coroutine
- `m()`: Pauses alarm (sends `PAUSE_ALARM` to `AlarmService`)
- `onStop()`: Restarts alarm (sends `RESTART_ALARM`) — unless completed

### Shake Challenge

**ViewModel:** `sources/p208n7/a.java`
**Logic:** `sources/p208n7/d.java`
- Uses `SensorManager` + `TYPE_ACCELEROMETER`
- `progress += 150` per valid shake
- `percentage = min(progress * 100 / total, 100)`
- Completed when `percentage >= 100`
- Calls `l()` on completion

### Math Challenge

**ViewModel:** `sources/p160k7/c.java`
**Logic:** `sources/p160k7/e.java` → `sources/p160k7/f.java`
- Generates math questions based on `ChallengeDifficulty` (EASY/MEDIUM/HARD)
- Tracks `questionsAnswered`
- Completed when `questionsAnswered >= 3`
- 1000ms delay between questions
- Calls `l()` on completion

### Memory Challenge

**ViewModel:** `sources/p178l7/i.java`
**Logic:** `sources/p178l7/g.java`
- Creates card pairs based on difficulty
- `MemoryTileStatus` tracks flip state
- `MemoryTileLayout` defines card layout
- Completed when `matchedPairs == 4` (all 4 pairs matched)
- 600ms delay after final match before calling `l()`

### Questions/Quiz Challenge

**ViewModel:** `sources/p194m7/g.java`
**Logic:** `sources/p194m7/f.java`
- Loads questions from `AlarmQuestions` resources
- Tracks `questionsAnswered`
- Completed when `questionsAnswered >= 3`
- 1000ms delay between questions
- Calls `l()` on completion

### Random Challenge Selector

**File:** `sources/M4/b.java`
- `b()` method: Filters `AlarmChallenge.values()` where `isChallenge == true`
- Picks randomly from the filtered list
- Maps to the appropriate challenge fragment

---

## Challenge Completion → Alarm Dismissal — Exact Chain

### Step 1: Challenge detects completion
Each challenge ViewModel detects its completion condition and calls base `l()`.

### Step 2: Base `l()` method
**File:** `sources/p132i7/l.java:127`
```java
public final void l() {
    f32247S = true;  // mark completed
    h();  // cancel countdown coroutine
    // launch finalize coroutine (p132i7/i)
}
```

### Step 3: Finalize coroutine
**File:** `sources/p132i7/i.java:33`
```java
if (f32239K) {  // tutorial mode
    emit(action → shows tutorial snackbar);
} else {
    C0166c.k(userAlarm);  // stops AlarmService (failed to decompile)
    emit(action → navigate to WellDone);
}
```

### Step 4: Navigation to WellDone
**File:** `sources/p132i7/d.java:68`
```java
// Observer on f32238J SharedFlow:
a.f32216a → hVar.j(new F(alarmType));
// F maps to: action_alarm_challenge_to_wellDone with popUpToInclusive=true
```

**File:** `sources/Y6/F.java` — Navigation direction:
- `action_alarm_challenge_to_wellDone`
- `popUpToInclusive=true`
- `popUpTo="@+id/main_navigation"` → **pops the entire nav graph**

### Step 5: AlarmService stops
**File:** `sources/com/blink22/fajr/core/scheduler/alarm/fajrAlarm/AlarmService.java:194`
```java
onDestroy() {
    mediaPlayer.stop();
    mediaPlayer.release();
    audioManager.setStreamVolume(STREAM_ALARM, savedVolume, 0);
    stopForeground(STOP_FOREGROUND_REMOVE);
    sendBroadcast("com.blink22.fajr.ALARM_DISMISSED");
}
```

### Step 6: Activity finishes
- WellDoneFragment is the only fragment left (backstack cleared by `popUpToInclusive`)
- WellDoneFragment has **no outgoing navigation actions**
- User presses Back → backstack empty → `AlarmActivity.finish()`
- Alternatively: `F7/j.java` case 3 catches `ALARM_DISMISSED` → calls `activity.finish()`

---

## Notification Channel Configuration

### `ChannelDetails.Alarm` — The main alarm channel
**File:** `sources/com/blink22/fajr/data/models/ChannelDetails.java:12`
- `baseId = "Fajr-Channel"`
- `channelName = "Fajr Alarm"`
- `importance = 4` (IMPORTANCE_HIGH)
- **No explicit sound set** in channel creation switch — uses system default for HIGH channels

### Channel Creation
**File:** `sources/B5/f.java:385-452`
```java
public void k(ChannelDetails channelDetails) {
    int importance;
    switch (iArr[channelDetails.ordinal()]) {
        case 1:  // CountdownNotification
            importance = 2;  // IMPORTANCE_LOW
            break;
        case 2-13:  // ALL OTHER channels
            importance = 4;  // IMPORTANCE_HIGH
            break;
    }
    NotificationChannel channel = X6.a.d(channelId, importance, channelName);
    notificationManager.createNotificationChannel(channel);
}
```

---

## Keyguard Behavior — API Level Differences

### API 27+ (Android 8.0+)
- `setShowWhenLocked(true)` — Activity renders above keyguard
- `setTurnScreenOn(true)` — Screen turns on
- Keyguard is **NOT dismissed** — user still sees it behind the challenge
- No `FLAG_DISMISS_KEYGUARD` used

### API < 27 (Android 7.x and below)
- `getWindow().addFlags(6816768)`:
  - `FLAG_SHOW_WHEN_LOCKED (0x80000)` — Activity renders above lock
  - `FLAG_DISMISS_KEYGUARD (0x400000)` — **Dismisses the lock screen**
  - `FLAG_TURN_SCREEN_ON (0x200000)` — Screen turns on
  - `FLAG_KEEP_SCREEN_ON (0x400)` — Screen stays on

### No `KeyguardManager` usage
- `requestDismissKeyguard()` — **zero matches** in entire codebase
- `KeyguardManager` — only found in Firebase SDK (`Fc/f.java:894`), not in app code
- The app relies entirely on Activity flags for lock-screen behavior

---

## Alarm Audio on Lock Screen

**File:** `sources/com/blink22/fajr/core/scheduler/alarm/fajrAlarm/AlarmService.java:186-190`
```java
AudioAttributes audioAttributesBuild = new AudioAttributes.Builder()
    .setUsage(/* USAGE_ALARM(5) or USAGE_NOTIFICATION(4) */)
    .setContentType(2)  // CONTENT_TYPE_MUSIC
    .build();

MediaPlayer mediaPlayer = new MediaPlayer();
mediaPlayer.setAudioAttributes(audioAttributesBuild);
mediaPlayer.setLooping(true);  // loops until dismissed
```

- `USAGE_ALARM` bypasses Do Not Disturb mode
- `STREAM_ALARM` volume (not ringtone volume)
- Loops until `AlarmService.onDestroy()` calls `mediaPlayer.stop()`

---

## WakeLock Details

**File:** `sources/Ma/E1.java:251-286`
```java
// Acquire:
PowerManager.WakeLock wakeLockNewWakeLock =
    ((PowerManager) systemService).newWakeLock(1, "Wakelock: Alarm wakeLock");
wakeLockNewWakeLock.setReferenceCounted(false);
wakeLockNewWakeLock.acquire(120000L);  // 2 minutes

// Release (in f()):
PowerManager.WakeLock wakeLock = (PowerManager.WakeLock) this.f12103a;
if (wakeLock != null) {
    wakeLock.release();
}
```

- **Type 1** = `PARTIAL_WAKE_LOCK` — keeps CPU on, does NOT keep screen on
- **120-second timeout** — auto-releases if alarm doesn't complete
- Screen-on is handled by `AlarmActivity.setTurnScreenOn(true)`, not by WakeLock

---

## Complete Permission Chain for Lock-Screen Behavior

From `resources/base.apk/AndroidManifest.xml`:

| Permission | Line | Purpose |
|---|---|---|
| `SCHEDULE_EXACT_ALARM` | 19 | Exact alarms (API ≤ 32) |
| `USE_EXACT_ALARM` | 21 | Exact alarms (API 33+) |
| `USE_FULL_SCREEN_INTENT` | 24 | Full-screen alarm notification |
| `WAKE_LOCK` | 25 | Keep CPU alive during alarm |
| `FOREGROUND_SERVICE` | 15 | Alarm as foreground service |
| `FOREGROUND_SERVICE_SYSTEM_EXEMPTED` | 22 | System-exempted foreground service |
| `POST_NOTIFICATIONS` | 23 | Show alarm notification |
| `RECEIVE_BOOT_COMPLETED` | 16 | Re-schedule on reboot |

---

## Decompiler Awareness for This Analysis

- `C0166c.k()` — finalize/dismiss method body **failed to decompile** (Jadx overflow). Its role is confirmed by call sites but exact implementation is opaque.
- `AlarmService` has **duplicated Runnable blocks** from Jadx `IfRegionVisitor` errors — these are decompiler bugs, not app bugs.
- `p221o4/h.java` — AudioAttributes usage decision uses Kotlin coroutine state machine that Jadx partially decompiled.
- `TriggerAlarmUseCase.g()` — UserAlarm handler body not fully available.
- Field names (`f24502B`, `f32247S`, etc.) are Jadx-assigned — original names lost to R8 obfuscation.
- `F7/j.java` — Multi-purpose BroadcastReceiver; case numbers correspond to different intent actions.
- `Y6/F.java` and `Y6.G.java` — Navigation direction classes; their `j()` method holds the action ID reference.
