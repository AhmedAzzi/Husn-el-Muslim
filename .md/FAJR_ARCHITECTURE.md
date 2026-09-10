# Fajr App — Architecture Analysis

> **Decompiled APK** (`com.blink22.fajr` v2.5.23) — not original source.
> Package names below use R8-obfuscated aliases alongside original names where available.

---

## 1. Application Entry

**`FajrApp`** (`sources/com/blink22/fajr/FajrApp.java:27`)
- Extends `Application`, implements Hilt/Dagger component accessors
- `attachBaseContext()`: Overrides locale configuration for RTL support (reads stored locale from `p370xd.l.D()`)
- `onCreate()`: Initializes Time4J (`ApplicationStarter.initialize`), fetches Firebase Remote Config, registers 3 WorkManager workers
- `b()` method: Lazy DI initialization — resolves the Hilt component (`Q3.h`) and wires `ScheduleAlarmsWorkerManager`, `SoundWorkerManager`, `SyncRemoteWorkerManager` into WorkManager

---

## 2. Dependency Injection

**Framework: Dagger/Hilt** (R8-obfuscated)

### Component: `Q3/h.java` (~1101 lines)
- The single DI component containing the entire dependency graph
- ~180+ `Sd.c` fields (Dagger Lazy/Provider bindings)
- Key factory methods: `P0()` → `DefaultAlarmHelper`, `o1()` → injects `AlarmReceiver`, `p1()` → injects `PrayersWidgetProvider`

### Module: `Q3/a.java`
- ViewModel multibinding map: registers **63 ViewModel classes** by class name
- Worker configuration binding

### ViewModel Factory: `Od/f.java`
- Custom `ViewModelProvider.Factory` that delegates to Hilt for `@HiltViewModel` classes
- Every Fragment/Activity overrides `getDefaultViewModelProviderFactory()` to return this

---

## 3. UI Architecture

### Single-Activity + Navigation Component

**`MainActivity`** (`sources/com/blink22/fajr/ui/MainActivity.java:88`)
- Hosts `NavHostFragment` at `R.id.nav_host_fragment`
- Navigation graph: `R.navigation.main_navigation`
- Bottom navigation: **Jetpack Compose** (`ComposeView` at `R.id.bottomNavigationView`) — not XML
- Two additional ComposeView overlays: notification overlay + unlogged prayers dialog
- Initial destination: `walkthroughContainerFragment` (onboarding) or `homeFragment`

**`AlarmActivity`** (`sources/com/blink22/fajr/ui/views/alarm/AlarmActivity.java:47`)
- **Separate Activity** from MainActivity (not a Fragment)
- Uses the same navigation graph (`R.navigation.main_navigation`)
- Has `showWhenLocked` + `turnScreenOn` for lock-screen display
- Routes to challenge/normal alarm/wakeup-check fragments via `customRoute` intent extra

### Fragment Architecture — Hybrid XML + Compose
- Base Fragment class: `q7.b` (Dagger-injected)
- All fragments override `getDefaultViewModelProviderFactory()` → returns `Od/f` (Hilt factory)
- Compose content set via `ComposeView.setViewCompositionStrategy()` + `setContent()`
- Most screens are still XML Fragments; Compose is being migrated in (bottom nav, overlays, some new screens)

### Key Destinations (from navigation graph references in code)
| Destination ID | Fragment/Screen |
|---|---|
| `homeFragment` | Home — prayer times display |
| `walkthroughContainerFragment` | Onboarding/walkthrough |
| `quranFragment` | Quran reader main |
| `mushafFragment` | Mushaf page view |
| `ayatDetailsFragment` | Ayah details |
| `khatmahListFragment` | Khatmah list |
| `khatmahFragment` | Individual khatmah |
| `starredFragment` | Bookmarked ayat |
| `quranSearchFragment` | Quran search |
| `trackingFragment` | Prayer tracking |
| `alarmFragment` | Alarm list |
| `beforeAlarmFragment` | Challenge routing screen |
| `normalAlarmFragment` | Normal (no challenge) alarm screen |
| `areYouAwakeFragment` | Wakeup check screen |
| `incompatibleVersionFragment` | Fallback for missing resources |

### Deep Links
| URI | Action |
|---|---|
| `fajr://share` | Share content via Intent.ACTION_SEND |
| `fajr://product-details` | Navigate to product details |
| `fajr://khatmah/{id}` | Open specific khatmah |
| `fajr://tracking?epochDay=N` | Open tracking for specific day |

---

## 4. Domain Layer — Use Cases

Clean Architecture pattern: Fragments → ViewModels → Use Cases → Repositories

### Key Use Cases (obfuscated names with original purpose)
| Obfuscated | Purpose | Location |
|---|---|---|
| `B5.C` | `ScheduleAlarmsUseCase` — master scheduling orchestrator | `sources/B5/C.java` |
| `B5.t` | `ComputeAlarmTimeUseCase` — computes next alarm trigger time | `sources/B5/t.java` |
| `B5.f` | `DefaultAlarmHelper` — schedules/cancels alarms, creates notifications, manages channels | `sources/B5/f.java` |
| `p205n4.m` | `TriggerAlarmUseCase` — dispatches fired alarms to correct service | `sources/p205n4/m.java` |
| `p221o4.i` | `AlarmServiceHelper` — starts/stops foreground services, acquires WakeLock | `sources/p221o4/i.java` |
| `p132i7.l` | Base `ChallengeViewModel` — completion, pause/restart alarm | `sources/p132i7/l.java` |
| `w5.p` | `ToggleDoNotDisturbUseCase` — DND mode management | — |
| `l4.c` | `RemoteConfigInitializer` — Firebase Remote Config | — |

---

## 5. Data Layer

### Persistence — 4 Storage Mechanisms

#### A. Room Databases
| Database | Tables | File |
|---|---|---|
| `AppDatabase` | `locations` | `sources/com/blink22/fajr/core/database/AppDatabase.java` |
| `TrackingDatabase` | `metric`, `daily_log`, `day_summary`, `day_status_count`, `prayer_day_summary`, `longest_streak` | `sources/com/blink22/fajr/core/tracking/database/TrackingDatabase.java` |
| `QuranDatabase` | 18 tables (Quran text, translations, audio, khatmah, starred, etc.) | `sources/com/blink22/fajr/quran/data/local/database/QuranDatabase.java` |
| `CityDatabase` | City coordinates (reads from `cities.db` asset) | `sources/com/blink22/fajr/core/database/city/CityDatabase.java` |

#### B. SharedPreferences
- Widget-specific prefs (`widget_prefs`)
- Legacy alarm config keys (`flutter.beforeFajrOption`, `flutter.offType`, `flutter.triggerOption`, `flutter.difficulty`)

#### C. Jetpack DataStore
- Two DataStore instances for prayer times preferences and tracking preferences
- Used for alarm toggles, dark mode, and other settings

#### D. Pre-packaged Asset Databases
- `cities.db` — City coordinates for prayer time calculation
- `quran.db` — Quran text data
- `quran.sqbpro` — SQLite query optimizer config

### Networking
- **Retrofit2** + **OkHttp3** (vendored in `sources/retrofit2/` and `sources/okhttp3/`)
- **Firebase**: Auth, Firestore, Storage, Messaging, Analytics, Crashlytics, Remote Config, In-App Messaging
- **Google Play Services**: Location, Maps, Ads

### Key Data Models

#### Alarm Types (all implement `InterfaceC1301b`)
| Model | Values | Purpose |
|---|---|---|
| `UserAlarm` | `FajrAlarm`, `SuhoorAlarm` | User-configurable alarm triggers |
| `Prayer` | Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha, + 3 night prayers | Standard prayer time notifications |
| `BeforeAlarm` | `BeforeFajrAlarm`, `BeforeSuhoorAlarm` | Early-warning before Fajr/Suhoor |
| `PrePostPrayer` | PreFajr..PostIsha (9 values) | Pre/post prayer reminders |
| `DoNotDisturbAlarm` | PreFajr..PostIsha (10 values) | DND mode toggles |
| `BedtimeAlarm` | `FajrBedtimeAlarm`, `SuhoorBedtimeAlarm` | Bedtime reminders |
| `AthkarAlarm` | Wakeup, Morning, Evening, Sleep, FridayKahf | Athkar notifications |

#### Challenge Models
| Model | Values |
|---|---|
| `AlarmChallenge` | `NormalAlarm`, `ShakeToWake`, `AnswerQuestions`, `MathQuestions`, `MemoryChallenge`, `RandomChallenge` |
| `ChallengeDifficulty` | `EASY(0)`, `MEDIUM(1)`, `HARD(2)` |
| `MemoryTileLayout` | Card layout configuration |
| `MemoryTileStatus` | Card flip state |

#### Other Key Models
| Model | Purpose |
|---|---|
| `ChannelDetails` | 13 notification channel definitions |
| `AlarmAnchor` | Fajr or Sunrise (alarm time anchor) |
| `Bedtime` | hour/minute + BedtimeType (RELATIVE/EXACT) |
| `SnoozeDetails` | isSnoozeOn, interval, times |
| `WakeupCheck` | Post-snooze wakeup verification config |
| `WeekDay` | Day-of-week scheduling |
| `Language` | 11 supported languages |

---

## 6. Workers (WorkManager)

| Worker | Purpose |
|---|---|
| `ScheduleAlarmsWorkerManager` | Schedules all prayer alarms + toggles DND mode |
| `SoundWorkerManager` | Manages prayer sound playback |
| `SyncRemoteWorkerManager` | Syncs Firebase Remote Config data |

---

## 7. Quran Module (Self-Contained)

```
sources/com/blink22/fajr/quran/
  data/
    local/database/    → QuranDatabase (18 DAOs, ~1131 lines impl)
    local/models/      → Local data models
    remote/            → API services
    reminder/          → Quran reminder system (KhatmahReminderReceiver, KhatmahReminderBootReceiver)
  domain/
    entities/          → Starred, KhatmahScheduleStatus, ContinueReadingEntry, RevelationType
    models/            → Domain models
  ui/
    audio/             → QuranAudioService (foreground mediaPlayback)
    AyatDetails/       → Ayah detail view
    components/        → Shared UI components
    download/          → QuranDownloadService (foreground dataSync)
    khatmah/           → Khatmah management
    MushafPage/        → Mushaf page rendering
    playbacksettings/  → Audio playback settings
    Quran/             → Main Quran reader
    search/            → Quran search
    starred/           → Bookmarked ayat
```

---

## 8. Widgets

| Widget | File | Lines |
|---|---|---|
| `PrayersWidgetProvider` | `sources/com/blink22/fajr/widgets/PrayersWidgetProvider.java` | ~800 |
| `TrackingWidgetProvider` | `sources/com/blink22/fajr/widgets/TrackingWidgetProvider.java` | ~2512 |
| `TrackingWidgetUpdateWorker` | `sources/com/blink22/fajr/widgets/TrackingWidgetUpdateWorker.java` | — |
| `TrackingWidgetUpdateReceiver` | `sources/com/blink22/fajr/widgets/TrackingWidgetUpdateReceiver.java` | — |
| `LocaleChangeReceiver` | `sources/com/blink22/fajr/widgets/LocaleChangeReceiver.java` | — |

---

## 9. Tech Stack Summary

| Layer | Technology |
|---|---|
| Language | Kotlin (primary) + Java |
| DI | Dagger/Hilt (R8-obfuscated) |
| Database | Room (4 databases) + SharedPreferences + DataStore |
| Network | Retrofit2 + OkHttp3 |
| Backend | Firebase (Auth, Firestore, Storage, Messaging, Analytics, Crashlytics, Remote Config, In-App Messaging) |
| Maps | Google Maps SDK |
| Ads | Google Ads SDK |
| UI | Jetpack Compose (partial migration) + XML Fragments + Navigation Component |
| Images | Glide |
| Animations | Lottie |
| Calendar/Time | Time4J |
| Background | WorkManager |
| Audio | MediaPlayer (API) |
| Build Variant | `app_productionRelease` |
| Target SDK | 36 |
| Min SDK | 23 |

---

## 10. Full Dependency Flow

```
Fragment/Activity
    ↓ ViewModelProvider.get() via HiltViewModelFactory (Od/f)
ViewModel (63 registered, Hilt-injected)
    ↓ Use cases injected via constructor
Use Cases (ScheduleAlarmsUseCase, TriggerAlarmUseCase, etc.)
    ↓ Repository calls
Repository Layer (AlarmRepository, TrackingRepository, etc.)
    ↓ Data access
Persistence (Room DBs / SharedPreferences / DataStore)
    ↓ Network
API Layer (Retrofit + Firebase)
```

---

## 11. Decompiler Awareness

- All class names with single-letter or `p000*` prefixes are R8/ProGuard obfuscated — they have no meaningful original name
- `@Metadata` annotations on classes preserve original Kotlin class info (type params, name) — use them to understand intent
- Some methods throw `UnsupportedOperationException("Method not decompiled: ...")` — these are Jadx failures on complex coroutine state machines
- Field names like `f24493A`, `f14438D` are Jadx-assigned; original names are lost to obfuscation
- `j$/` directory contains desugared java.util (for pre-API-24 support)
- `Fb/`, `Q3/`, `B5/`, `Od/`, `p205n4/`, `Ma/`, `L4/`, `R4/`, etc. are all obfuscated package names — their contents are library or generated code, not app source
