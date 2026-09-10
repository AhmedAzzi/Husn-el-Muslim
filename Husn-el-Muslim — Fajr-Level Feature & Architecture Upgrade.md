# Husn-el-Muslim — Fajr-Level Feature & Architecture Upgrade

You are working on my existing Flutter Android application **Husn-el-Muslim**.

Your job is to significantly upgrade the app by taking the strongest ideas and architectural patterns from the reference app **Fajr by blink22**, while preserving Husn-el-Muslim's existing identity, design system, Islamic content, offline-first behavior, mosque/Mawaqit functionality, and open-source/no-ads philosophy.

## IMPORTANT RULE

**DO NOT blindly copy Fajr.**

The goal is:

> Build a better Husn-el-Muslim by integrating the missing high-value capabilities of Fajr into the existing architecture.

Do NOT replace working Husn-el-Muslim features just because Fajr implements them differently.

Do NOT rewrite large parts of the application without first understanding them.

Do NOT change the existing UI style unnecessarily.

Do NOT remove existing features.

Do NOT introduce Firebase, advertisements, analytics, tracking SDKs, or unnecessary cloud dependencies.

The application should remain:

- offline-first
- privacy-friendly
- open-source friendly
- Arabic-first
- lightweight
- reliable
- Android-focused
- compatible with existing Husn-el-Muslim functionality

---

# 1. SOURCE OF TRUTH

Before modifying anything, inspect the complete existing project.

Inspect:

```text
lib/
pubspec.yaml
assets/
android/
```

Pay particular attention to:

```text
lib/prayer_calculation_engine.dart
lib/prayer_times_logic.dart
lib/settings_screen.dart
lib/notification_settings_screen.dart
lib/fajr_challenge_screen.dart
lib/custom_dikr_screen.dart
lib/ruqyah_screen.dart
lib/ruqyah_detail_screen.dart
lib/dua_screen.dart
lib/asmaa_allah_screen.dart
lib/mosque_api.dart
lib/mosque_map_screen.dart
lib/prayer_foreground_task_handler.dart
lib/dhikr_reminder_helper.dart
lib/ayat_hadith_dialog.dart
lib/prayer_widget_sync.dart
android/
```

Also inspect all related services, models, providers, repositories, persistence code, notification code, alarm code, widgets, and settings.

There is also reference documentation describing the reverse-engineered Fajr architecture:

```text
.md/FAJR_ARCHITECTURE.md
.md/ALARM_FLOW.md
.md/LOCK_SCREEN_CHALLENGE.md
```

Read these files carefully.

Treat them as architectural reference material, NOT as code to copy.

---

# 2. FIRST TASK — FULL PROJECT AUDIT

Before writing implementation code, perform a complete architecture audit.

Determine:

### Existing prayer architecture

Identify:

- prayer calculation engine
- calculation methods
- location handling
- timezone handling
- prayer model
- prayer offsets
- iqama offsets
- mosque/Mawaqit source
- calculated vs mosque prayer source
- caching
- date changes
- midnight/night thirds
- Hijri calculations

### Existing alarm architecture

Identify:

- how alarms are scheduled
- Android AlarmManager usage
- exact alarms
- broadcast receivers
- foreground services
- notifications
- notification channels
- full-screen activities
- wake locks
- boot handling
- timezone/date-change handling
- Doze behavior
- battery optimization handling
- alarm cancellation
- rescheduling

### Existing Fajr challenge architecture

Identify:

- challenge state
- challenge configuration
- question generation
- answer validation
- persistence
- alarm integration
- screen lifecycle
- stopping the alarm
- app foreground behavior
- volume handling

### Existing widget architecture

Identify:

- widget providers
- Flutter/native bridge
- synchronization
- stored data
- update scheduling
- small widget
- large widget

### Existing content architecture

Identify:

- dhikr
- dua
- ruqyah
- Asma Allah
- custom dhikr
- Quran/content possibilities
- search
- favorites
- sharing

### Existing persistence

Determine exactly what is currently used:

- SharedPreferences
- Hive
- SQLite
- JSON
- files
- other storage

Do NOT introduce another database technology unless necessary.

---

# 3. Fajr REFERENCE CAPABILITIES

Use the following comparison as the target gap analysis.

## Existing parity

Husn-el-Muslim already has:

### Prayer calculation

Current:

```text
prayer_calculation_engine.dart
adhan package
offline calculation
```

Current calculation methods include approximately:

```text
Makkah
Egypt
MWL
Karachi
ISNA
```

Fajr has approximately 12 calculation systems.

Improve this system by adding the missing commonly used methods where technically appropriate.

Do not break existing saved settings.

---

### Fajr wake-up alarm

Husn already has:

```text
fajrChallengeEnabled
native alarm sound loop
FajrChallengeScreen
volume-lock/max behavior
bringAppToForeground
```

Improve reliability rather than replacing it.

Target:

```text
Alarm scheduled
    ↓
Android AlarmManager / exact alarm
    ↓
BroadcastReceiver
    ↓
Alarm foreground handling
    ↓
WakeLock
    ↓
Turn screen on
    ↓
Show over lock screen
    ↓
Play alarm
    ↓
Launch Fajr challenge
    ↓
User completes challenge
    ↓
Stop alarm
    ↓
Wake-up confirmation
    ↓
Well Done
    ↓
Record successful Fajr
    ↓
Update streak
```

---

# 4. P0 — BUILD A REAL ALARM ENGINE

This is the most important architectural upgrade.

Create a reusable alarm system instead of implementing every alarm separately.

Design something conceptually similar to:

```text
AlarmType
    Fajr
    Suhoor
    BeforeFajr
    BeforeSuhoor
    BedtimeFajr
    BedtimeSuhoor
    PrePrayer
    PostPrayer
    DoNotDisturb
    Custom
```

Create a central alarm model containing information such as:

```text
id
type
enabled
triggerTime
relativeTo
offsetMinutes
sound
volume
vibrate
loop
fullScreen
showOnLockScreen
requiresChallenge
snoozeEnabled
```

Do not necessarily use these exact names; adapt them to the existing architecture.

The important principle is:

> All alarms should go through one reliable scheduling layer.

---

# 5. ANDROID ALARM RELIABILITY

Study the reference:

```text
.md/ALARM_FLOW.md
.md/LOCK_SCREEN_CHALLENGE.md
```

Then improve Android implementation.

Implement where appropriate:

- exact alarms
- AlarmManager
- setAlarmClock()
- BroadcastReceiver
- foreground service
- partial WakeLock
- screen wake
- show when locked
- turn screen on
- full-screen notification/activity
- Android notification channel configuration
- boot rescheduling
- timezone change rescheduling
- date change rescheduling
- exact-alarm permission handling
- battery optimization guidance

Be careful with Android version differences.

Do not use deprecated APIs blindly.

Do not request permissions that are unnecessary.

The alarm must survive:

- screen off
- app removed from recents
- normal Doze
- reboot
- date change
- timezone change
- daylight-saving changes where relevant
- temporary process death

The goal is:

> If the user enables Fajr alarm, it should reliably wake them at Fajr.

---

# 6. LOCK SCREEN HARDENING

Improve the Fajr challenge so it works reliably from the lock screen.

Target behavior:

```text
Phone locked
    ↓
Fajr alarm fires
    ↓
Screen turns on
    ↓
Alarm UI becomes visible
    ↓
User can interact without manually opening the app
    ↓
Challenge starts
    ↓
Alarm continues until challenge completion
```

Handle:

- Android lock screen
- notification visibility
- full-screen intent requirements
- Android 13+
- Android 14+
- notification permission
- exact alarm permission
- battery optimization
- activity lifecycle
- configuration changes
- process death

Do not create security vulnerabilities.

Never bypass the actual device lock/password/PIN.

The app may show its alarm/challenge UI over the lock screen, but must NOT unlock the phone.

---

# 7. P0 — GENERALIZE THE Fajr CHALLENGE

The existing Fajr challenge is currently based mainly on:

```text
Dhikr text → category
MCQ
text input
1–10 questions
```

Keep this working.

Refactor it into a generic challenge architecture.

Conceptually:

```text
WakeUpChallenge
├── QuestionChallenge
├── MathChallenge
├── MemoryChallenge
└── ShakeChallenge
```

Create a common interface/model.

For example:

```text
Challenge
    start()
    reset()
    handleInput()
    isCompleted
    progress
```

Adapt this to the actual codebase.

Do not over-engineer.

---

# 8. P0 — Fajr CHALLENGE IMPROVEMENTS

Improve the current challenge with:

### Difficulty

```text
Easy
Medium
Hard
```

Difficulty should affect actual challenge complexity.

### Question count

Allow configurable:

```text
1
3
5
7
10
```

Do not force users to answer 10 questions.

### Delay

Preserve a small intentional delay after successful answers if appropriate.

### Failure behavior

Define clearly:

```text
wrong answer
→ retry
```

or:

```text
wrong answer
→ new question
```

depending on the existing UX.

Do not make the challenge frustrating.

---

# 9. P1 — MATH CHALLENGE

Add a math wake-up challenge.

Difficulty:

```text
Easy
Medium
Hard
```

Examples:

Easy:

```text
7 + 5 = ?
```

Medium:

```text
18 × 4 = ?
```

Hard:

```text
72 ÷ 8 + 17 = ?
```

Requirements:

- generate questions dynamically
- validate answers
- avoid impossible/ambiguous questions
- configurable number of questions
- track correct answers
- completion state
- prevent trivial repeated questions
- support Arabic UI

Do not require network access.

---

# 10. P1 — MEMORY MATCH CHALLENGE

Implement a memory challenge.

Reference behavior:

```text
4 pairs
```

Display:

```text
8 tiles
```

User flips tiles and matches pairs.

Requirements:

- shuffled layout
- flip animation
- matched state
- incorrect pair delay
- completion detection
- reset/retry
- accessibility
- RTL support

Avoid excessive animations.

Keep it lightweight.

---

# 11. P1 — SHAKE TO WAKE

Add optional shake challenge.

Use Android sensor APIs / Flutter sensor integration.

Potential architecture:

```text
Accelerometer
    ↓
Motion detection
    ↓
Normalize movement
    ↓
Progress
    ↓
100%
    ↓
Challenge completed
```

Requirements:

- configurable sensitivity
- prevent false positives
- handle sensor unavailable
- stop listening immediately after completion
- battery-efficient
- no continuous sensor listener outside the challenge

Add the required dependency only if necessary.

---

# 12. P1 — RANDOM CHALLENGE

Add:

```text
Random Challenge
```

When enabled:

```text
Random()
    ↓
choose enabled challenge
    ↓
start challenge
```

Available challenges:

```text
Questions
Math
Memory
Shake
```

Do not select disabled challenges.

Persist the user's enabled challenge list.

---

# 13. P0 — WAKE-UP CONFIRMATION

After the challenge is completed, do not immediately assume the user is awake.

Implement:

```text
Challenge completed
        ↓
Are you awake?
        ↓
confirmation
        ↓
Well Done
```

Possible simple implementation:

```text
"أنا مستيقظ"
```

button.

Optionally require a short delay before confirmation.

The important thing is that:

> Challenge completion and successful wake-up should be separate states.

---

# 14. P0 — TRACKING SYSTEM

This is one of the biggest missing features.

Create a local tracking system.

Track at least:

```text
date
Fajr status
Fajr challenge completed
wake-up success
prayer completion where appropriate
```

Design for:

```text
daily log
day summary
prayer summary
streak
longest streak
```

Do not copy the Fajr database schema blindly.

Create the smallest schema that solves the problem.

For example:

```text
daily_logs
-------------
date
fajr_completed
fajr_challenge_completed
wake_up_confirmed
created_at
```

And:

```text
streak_summary
-------------
current_streak
longest_streak
last_success_date
```

Calculate streaks correctly across dates.

Handle:

- missed day
- future date
- timezone
- Hijri/Gregorian display
- manual corrections if needed

---

# 15. TRACKING UI

Create a clean tracking page consistent with the current Husn-el-Muslim design.

Show:

```text
Current streak
🔥 X days
```

```text
Longest streak
🏆 X days
```

Then:

```text
Today
Fajr ✓
Challenge ✓
Wake-up ✓
```

Add calendar/history.

Do not copy Fajr's exact UI.

Use the existing Husn-el-Muslim visual language.

---

# 16. TRACKING WIDGET

After the tracking system works, create an Android tracking widget.

Possible content:

```text
🔥 7 day streak

Today:
Fajr ✓
```

Or:

```text
Fajr
✓ Completed

7 day streak
```

Support at least:

```text
small
```

and optionally:

```text
medium/large
```

Reuse the existing widget architecture.

Do not create duplicated synchronization logic.

---

# 17. P1 — SUHOOR ALARM

Add a dedicated Suhoor alarm.

The alarm should be anchored to Fajr rather than being a completely independent arbitrary alarm.

Support:

```text
Suhoor time
Fajr - X minutes
```

Example:

```text
Fajr = 04:55
Suhoor alarm = 04:15
```

Allow configurable offset.

Make clear in the UI that this is:

> وقت السحور قبل الفجر

Do not confuse Suhoor with Fajr itself.

---

# 18. P1 — PRE-FAJR ALARM

Add presets:

```text
5 minutes
10 minutes
15 minutes
```

Also allow custom offset if the current app already supports it.

Preserve the existing:

```text
customOffset
10–120 minutes
```

if users already depend on it.

Do not break existing settings.

---

# 19. P2 — BEDTIME REMINDERS

Add optional bedtime reminders.

Support two concepts:

```text
Exact time
```

and:

```text
Relative to Fajr
```

Example:

```text
23:00
```

or:

```text
Fajr - 7 hours
```

Support:

```text
Fajr bedtime
Suhoor bedtime
```

Allow:

```text
Skip once
```

without disabling the recurring schedule.

---

# 20. P2 — PRE/POST PRAYER REMINDERS

Create optional notifications/alarms:

```text
Pre-Fajr
Pre-Dhuhr
Pre-Asr
Pre-Maghrib
Pre-Isha
```

and:

```text
Post-Fajr
Post-Dhuhr
Post-Asr
Post-Maghrib
Post-Isha
```

Do not spam the user.

Allow global enable/disable and per-prayer configuration if practical.

---

# 21. P2 — DND AUTOMATION

If technically and legally appropriate for Android:

Allow optional:

```text
Do Not Disturb around prayer
```

Potentially:

```text
before prayer
through prayer
after prayer
```

Do NOT silently modify DND.

Require the appropriate Android permission/access.

Explain clearly to the user.

If permission is unavailable, gracefully disable the feature.

---

# 22. P1 — MULTIPLE ADHAN / ALARM SOUNDS

Current app has:

```text
assets/adan.mp3
res/raw/adan.mp3
```

Improve this into a sound-selection architecture.

Support:

```text
default adhan
adhan 1
adhan 2
adhan 3
...
```

Do not download copyrighted audio automatically.

Keep bundled audio legally safe.

Allow:

- ringtone selection where possible
- local URI selection where supported
- preview
- volume
- vibration
- loop for wake-up alarm

Use appropriate Android audio stream for alarms.

---

# 23. GENTLE WAKE-UP

Implement optional gentle wake-up.

Instead of:

```text
100% volume immediately
```

support:

```text
low volume
    ↓
gradual increase
    ↓
maximum configured volume
```

Make duration configurable if practical.

Example:

```text
30 sec
60 sec
120 sec
```

For the Fajr challenge, ensure the alarm remains audible enough.

---

# 24. P1 — QIBLA

Add an offline Qibla compass.

Use:

```text
device heading
+
user latitude/longitude
+
Kaaba coordinates
```

Calculate bearing locally.

Do not require an online API.

Handle:

- location permission
- compass unavailable
- calibration
- magnetic interference
- device orientation
- RTL UI

Add a clean Qibla screen.

---

# 25. P1 — INTERNATIONALIZATION

Current application is Arabic-first and contains hardcoded strings.

Refactor toward Flutter localization.

Use:

```text
flutter_localizations
intl
ARB files
```

Start with:

```text
Arabic
English
French
```

Do not translate Islamic content incorrectly.

Separate:

```text
UI translations
```

from:

```text
religious source content
```

Do not automatically machine-translate Quran/Hadith/adhkar without verified sources.

---

# 26. PRAYER CALCULATION METHODS

Expand the calculation methods.

Research/implement the missing standard methods supported by the adhan calculation package or existing engine.

Do not invent astronomical formulas unnecessarily if the dependency already provides validated methods.

The UI should present understandable names.

Example:

```text
Muslim World League
Egyptian General Authority
University of Islamic Sciences, Karachi
Umm al-Qura, Makkah
ISNA
Moonsighting Committee
```

Only expose methods actually supported by the implementation.

---

# 27. EXISTING HUSN-EL-MUSLIM FEATURES MUST REMAIN

DO NOT remove or regress:

### Electronic Masbaha

Keep:

- counter
- scores
- custom dhikr
- CRUD
- custom_dikr.json
- click sound
- vibration toggle

### Ruqyah

Keep:

- Ruqyah list
- detail pages
- sharing

### Dua

Keep.

### Asma Allah

Keep all 99 names and current presentation.

### Mosque map

Keep:

- Mawaqit
- nearby mosque search
- Haversine sorting
- map
- markers
- clustering
- offline cache
- calculated/mosque prayer source

### Iqama

Keep:

- per-prayer iqama offsets
- manual prayer adjustments

### Night thirds

Keep:

```text
First Third
Midnight
Last Third
```

### Floating Dhikr overlay

Keep.

### Persistent notification

Keep.

### Ayat/Hadith dialogs

Keep.

### Hijri adjustment

Keep.

---

# 28. DO NOT ADD THESE YET

Do NOT implement the full Quran ecosystem during this phase.

Do not add:

```text
quran.db
mushaf
tafsir database
audio download system
Khatmah
18-table Quran database
```

unless the existing project already contains infrastructure for them.

These should be a later phase.

Reason:

The current priority is:

```text
Prayer
→ Alarm
→ Wake-up
→ Challenge
→ Tracking
→ Streak
```

not becoming a complete Quran application immediately.

---

# 29. SETTINGS ARCHITECTURE

The settings page should be reorganized logically.

Suggested structure:

```text
Settings
│
├── Prayer Times
│   ├── Calculation method
│   ├── Location
│   ├── Prayer adjustments
│   ├── Iqama
│   └── Mosque source
│
├── Fajr & Wake-up
│   ├── Fajr challenge
│   ├── Challenge type
│   ├── Difficulty
│   ├── Number of questions
│   ├── Alarm sound
│   ├── Gentle wake-up
│   └── Wake-up confirmation
│
├── Alarms
│   ├── Pre-Fajr
│   ├── Suhoor
│   ├── Bedtime
│   ├── Pre-prayer
│   └── Post-prayer
│
├── Notifications
│   ├── Morning adhkar
│   ├── Evening adhkar
│   ├── Prayer notifications
│   └── Persistent notification
│
├── Tracking
│   ├── Enable tracking
│   ├── Streaks
│   └── Widget
│
├── Qibla
│
├── Appearance
│   ├── Dark mode
│   ├── Language
│   └── Hijri adjustment
│
└── Advanced
    ├── Battery optimization
    ├── Exact alarm permission
    └── Diagnostics
```

Use the existing design system.

---

# 30. NOTIFICATION CHANNEL ARCHITECTURE

The reference uses multiple notification channels.

Husn should not necessarily create exactly 13 channels, but it should separate important notification categories.

Create appropriate channels such as:

```text
Prayer times
Prayer alarms
Fajr wake-up
Suhoor
Adhkar
Bedtime
Tracking
General
```

Use appropriate importance.

Alarm-related notifications should not be treated like ordinary low-priority notifications.

Respect Android user-controlled channel settings.

---

# 31. MORNING / EVENING ADHKAR

Current:

```text
Morning = approximately 1 hour after Fajr
Evening = approximately 1 hour after Asr
```

Keep this behavior unless there is a clear reason to improve it.

Add missing reminder categories where useful:

```text
Wake-up
Sleep
Friday Kahf
```

Do not automatically enable everything.

Give users explicit controls.

---

# 32. DATA DESIGN PRINCIPLES

Before introducing any database:

1. Check existing persistence.
2. Reuse it where possible.
3. Avoid duplicate sources of truth.
4. Avoid storing derived data unnecessarily.
5. Store dates in a timezone-safe way.
6. Handle migration.
7. Never destroy existing user settings.

Every new persistent model must have:

```text
serialization
deserialization
migration strategy
default values
backward compatibility
```

---

# 33. ERROR HANDLING

Every alarm subsystem must fail gracefully.

Examples:

If exact alarm permission is unavailable:

```text
show explanation
```

If sensor unavailable:

```text
disable shake challenge
```

If location unavailable:

```text
Qibla unavailable
```

If notification permission denied:

```text
show settings guidance
```

If battery optimization interferes:

```text
show optional guidance
```

Never crash the application.

---

# 34. OFFLINE-FIRST REQUIREMENT

All core functionality must work without internet:

```text
Prayer calculation
Fajr alarm
Challenges
Tracking
Streaks
Qibla calculation
Dhikr
Dua
Ruqyah
Asma Allah
Masbaha
```

Internet may be used for:

```text
Mawaqit / mosque schedules
```

when the user chooses online mosque mode.

Cache mosque data.

Never make Fajr alarm dependent on network connectivity.

---

# 35. PRIVACY

Do not add:

```text
Firebase
Google Analytics
Facebook SDK
Ads SDK
tracking SDK
remote behavioral tracking
```

unless explicitly requested later.

Location should be used only for:

- prayer calculations
- mosque discovery
- Qibla

Do not upload location unnecessarily.

---

# 36. PERFORMANCE

The application should remain lightweight.

Avoid:

- unnecessary rebuilds
- permanent sensor listeners
- unnecessary foreground services
- huge in-memory datasets
- excessive timers
- battery-draining polling

For alarms, prefer Android scheduling rather than continuously running Dart timers.

For widgets, update only when necessary.

---

# 37. ANDROID BACKGROUND EXECUTION

This is critical.

Do not rely solely on:

```dart
Timer
Future.delayed
```

for alarm execution.

Android should own scheduled alarm events.

Flutter should handle UI/business logic after the alarm event is delivered.

Use native Android components where reliability requires them.

Architecture should resemble:

```text
Flutter
    │
    │ MethodChannel
    ▼
Native AlarmScheduler
    │
    ▼
AlarmManager
    │
    ▼
BroadcastReceiver
    │
    ▼
AlarmService / AlarmActivity
    │
    ▼
Flutter UI / Challenge
```

Adapt this to the current project rather than duplicating systems.

---

# 38. BOOT / TIME CHANGE

After reboot:

```text
BOOT_COMPLETED
    ↓
load enabled alarms
    ↓
calculate next occurrence
    ↓
schedule
```

Also handle:

```text
TIMEZONE_CHANGED
TIME_SET
DATE_CHANGED
```

Whenever prayer times change:

```text
cancel obsolete alarms
calculate new schedule
reschedule
update widgets
```

Avoid duplicate alarms.

---

# 39. ALARM IDENTITY

Every scheduled alarm must have a deterministic identity.

Example concept:

```text
date + prayer + alarm type
```

so that:

```text
reschedule()
```

does not create duplicates.

Before scheduling:

```text
cancel old
schedule new
```

where appropriate.

Maintain an internal diagnostic representation so we can debug scheduled alarms.

---

# 40. TESTING

Create tests for:

### Prayer calculation

- calculation methods
- offsets
- midnight
- night thirds
- Hijri adjustment

### Alarm scheduling

- correct timestamp
- offsets
- date rollover
- timezone
- duplicate prevention

### Fajr challenge

- question generation
- validation
- completion
- difficulty
- random selection

### Tracking

Test:

```text
1 successful day
2 successful days
missed day
recovery after missed day
timezone transition
month transition
year transition
```

### Widgets

Verify:

- data synchronization
- updates
- stale data handling

---

# 41. UI/UX RULES

Do not make the application look like Fajr.

Keep the Husn-el-Muslim design language.

Use:

- existing cards
- existing typography
- existing spacing
- existing colors
- existing icons where possible
- existing RTL behavior

New features should visually feel native to Husn-el-Muslim.

Avoid excessive:

- gradients
- animations
- rounded containers
- visual noise

The app should feel calm and Islamic.

---

# 42. Fajr EXPERIENCE

The final Fajr experience should feel extremely polished.

Example:

```text
04:45
Fajr

🔔 Wake-up alarm

"حان وقت الفجر"

[Start Challenge]
```

Then:

```text
السؤال 1 من 3

أيٌّ من الأذكار التالية يُقال في الصباح؟

A
B
C
D
```

After completion:

```text
أحسنت 🌙

لقد استيقظت لصلاة الفجر

🔥 سلسلة 7 أيام

[متابعة]
```

Do not copy exact Fajr text/UI.

Use Husn-el-Muslim's own identity.

---

# 43. IMPORTANT — CHALLENGE SHOULD NEVER PREVENT PRAYER

The challenge exists to help wake the user.

It must not create an unreasonable barrier to prayer.

Provide emergency/escape handling where appropriate.

Never trap the user indefinitely.

Do not make challenges mathematically impossible.

Do not create infinite loops.

---

# 44. MIGRATION SAFETY

Before changing existing settings:

Inspect current keys.

Do not rename/delete keys without migration.

For example:

```text
fajrChallengeEnabled
```

must continue working.

If replacing it:

```text
old key
    ↓
migration
    ↓
new structure
```

Existing users must retain their settings.

---

# 45. IMPLEMENTATION ORDER

Implement in this exact broad order:

## Phase 1 — Audit

Do not modify code.

Inspect:

```text
lib/
pubspec.yaml
android/
assets/
.md reference docs
```

Produce:

```text
ARCHITECTURE_AUDIT.md
```

containing:

- current architecture
- relevant files
- dependencies
- existing alarm flow
- existing challenge flow
- existing widget flow
- risks
- proposed architecture

---

## Phase 2 — Alarm foundation

Improve:

```text
AlarmScheduler
AlarmReceiver
AlarmService
Lock-screen handling
Exact alarms
WakeLock
Boot rescheduling
Timezone/date handling
```

Do not add new features yet.

Verify existing Fajr alarm still works.

---

## Phase 3 — Generic challenge engine

Refactor:

```text
Fajr challenge
```

into:

```text
ChallengeEngine
```

without changing the existing user experience unnecessarily.

---

## Phase 4 — Tracking

Implement:

```text
daily logs
Fajr completion
challenge completion
wake-up confirmation
current streak
longest streak
history
```

---

## Phase 5 — New challenges

Implement:

```text
Math
Memory
Shake
Random
```

one by one.

Test each independently.

---

## Phase 6 — Additional alarms

Implement:

```text
Pre-Fajr
Suhoor
Bedtime
Pre/Post prayer
```

---

## Phase 7 — Sounds

Implement:

```text
sound selection
preview
gentle wake-up
volume
vibration
```

---

## Phase 8 — Tracking widget

Implement after tracking is stable.

---

## Phase 9 — Qibla

Implement offline compass.

---

## Phase 10 — Localization

Move UI strings into localization.

Start with:

```text
Arabic
English
French
```

---

# 46. CODE QUALITY

Follow the project's existing architecture unless there is a strong reason to improve it.

Prefer:

```text
services
repositories
models
providers/controllers
screens
widgets
```

Keep responsibilities separated.

Avoid giant files.

If a file becomes too large, split it logically.

Do not perform unrelated refactors.

Do not rename hundreds of files merely for aesthetics.

---

# 47. DEPENDENCY RULE

Before adding any package:

Ask:

1. Do we already have this capability?
2. Can Android/Flutter provide it natively?
3. Is the package maintained?
4. Does it increase APK size significantly?
5. Does it require unnecessary permissions?
6. Does it work offline?
7. Does it introduce tracking?

Only add the dependency if justified.

---

# 48. DOCUMENT EVERYTHING IMPORTANT

Create/update documentation for:

```text
ALARM_ARCHITECTURE.md
CHALLENGE_ARCHITECTURE.md
TRACKING_ARCHITECTURE.md
```

Document:

- data flow
- Android components
- scheduling
- permissions
- lifecycle
- failure modes
- migration
- testing

---

# 49. DO NOT CLAIM SUCCESS WITHOUT TESTING

After every major phase:

Run:

```text
flutter analyze
flutter test
```

and appropriate Android build checks.

If possible:

```text
flutter build apk
```

Inspect Android compilation.

Fix:

- analyzer errors
- warnings caused by your changes
- build errors
- dependency conflicts

Do not finish by saying "implemented" if it has not compiled.

---

# 50. FINAL VALIDATION CHECKLIST

Before declaring the work complete, verify:

## Prayer

- [ ] Offline calculation works
- [ ] Existing methods still work
- [ ] New methods work
- [ ] offsets work
- [ ] Iqama works
- [ ] mosque mode works
- [ ] night thirds work

## Fajr

- [ ] alarm fires
- [ ] alarm works with screen off
- [ ] alarm works after app is closed
- [ ] lock screen UI works
- [ ] challenge starts
- [ ] alarm stops correctly
- [ ] wake-up confirmation works
- [ ] success is tracked

## Challenges

- [ ] Questions
- [ ] Math
- [ ] Memory
- [ ] Shake
- [ ] Random
- [ ] Difficulty
- [ ] Question count
- [ ] Retry

## Tracking

- [ ] Daily log
- [ ] Current streak
- [ ] Longest streak
- [ ] History
- [ ] Missed days
- [ ] Widget

## Alarms

- [ ] Fajr
- [ ] Pre-Fajr
- [ ] Suhoor
- [ ] Bedtime
- [ ] Pre-prayer
- [ ] Post-prayer
- [ ] DND if implemented
- [ ] Boot
- [ ] Date change
- [ ] Timezone change

## Existing features

- [ ] Masbaha
- [ ] Custom dhikr
- [ ] Ruqyah
- [ ] Dua
- [ ] Asma Allah
- [ ] Mosque map
- [ ] Mawaqit
- [ ] Iqama
- [ ] Floating overlay
- [ ] Persistent notification
- [ ] Ayat/Hadith
- [ ] Hijri adjustment

## Quality

- [ ] No regressions
- [ ] No Firebase
- [ ] No ads
- [ ] Offline core functionality
- [ ] RTL
- [ ] Arabic
- [ ] flutter analyze passes
- [ ] flutter test passes
- [ ] Android build passes

---

# 51. MOST IMPORTANT DEVELOPMENT RULE

Work incrementally.

For every phase:

```text
INSPECT
  ↓
PLAN
  ↓
IMPLEMENT
  ↓
ANALYZE
  ↓
TEST
  ↓
FIX
  ↓
DOCUMENT
  ↓
NEXT PHASE
```

Never make a huge uncontrolled rewrite.

Before modifying an important file, understand its callers and dependencies.

Before deleting code, prove that it is unused.

Before changing a data model, identify migration requirements.

Before changing alarm behavior, verify existing alarms.

---

# 52. FINAL PRODUCT GOAL

The final Husn-el-Muslim should become:

```text
                    HUSN-EL-MUSLIM
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
     PRAYER             WAKE-UP            CONTENT
        │                  │                  │
   Prayer Times       Fajr Alarm          Dhikr
   Mosque             Challenges          Dua
   Iqama              Wake-up             Ruqyah
   Night Thirds       Tracking            Asma Allah
   Hijri              Streaks             Masbaha
        │                  │
        └──────────────────┼──────────────────┘
                           │
                       UTILITIES
                           │
                    Qibla / Widgets
```

The key experience should be:

```text
Prayer time
     ↓
Fajr alarm
     ↓
Reliable lock-screen wake-up
     ↓
Challenge
     ↓
"I'm awake"
     ↓
Fajr recorded
     ↓
Streak increases
     ↓
User sees progress
```

This is the core product loop.

Make that loop **extremely reliable and polished before expanding into the giant Quran/Khatmah ecosystem**.

---

# START NOW

Do NOT immediately start coding.

First:

1. Inspect the repository.
2. Inspect `pubspec.yaml`.
3. Inspect the Android alarm implementation.
4. Inspect the Fajr challenge implementation.
5. Inspect widgets.
6. Inspect persistence.
7. Read:
   - `.md/FAJR_ARCHITECTURE.md`
   - `.md/ALARM_FLOW.md`
   - `.md/LOCK_SCREEN_CHALLENGE.md`
8. Produce a concise architecture audit.
9. Identify exact files that must change.
10. Identify risks and migration requirements.
11. Propose Phase 1 implementation.
12. Only after that, begin implementation.

**Do not ask me to manually explain code that you can inspect yourself.**

If something is unclear, investigate the repository first.

The existing Husn-el-Muslim application is the source of truth for its current behavior.

The Fajr documentation is the source of truth for the reference architecture.

Build the best combination of both without destroying either.