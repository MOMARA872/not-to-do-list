# Architecture Research

**Domain:** Flutter Android app — screen-time tracking + soft-block app launch interception, local-first, no backend
**Researched:** 2026-04-26
**Confidence:** HIGH on Android platform mechanics (verified against Android Developers docs); MEDIUM on Flutter background-isolate communication patterns (well-known footguns documented in flutter/flutter issues, but the chosen pattern below avoids them entirely).

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Flutter (Dart) — UI Process                    │
├──────────────────────────────────────────────────────────────────────┤
│  Presentation                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│  │ Onboarding & │ │ Not-To-Do    │ │ Screen-Time  │ │ Pause Screen │ │
│  │ Permissions  │ │ List CRUD    │ │ Dashboard    │ │ + Cooldown   │ │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ │
│         │                │                │                │           │
├─────────┴────────────────┴────────────────┴────────────────┴──────────┤
│  Domain (use cases, pure Dart, no Flutter imports)                    │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  StreakEngine │ BlockListService │ UsageAggregator │ PauseLogic │ │
│  └─────────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────┤
│  Data (repositories + sources)                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐ │
│  │ BlockList   │ │ Streak      │ │ UsageRepo   │ │ Settings/Prefs  │ │
│  │ Repository  │ │ Repository  │ │ (cache+pull)│ │ Repository      │ │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └────────┬────────┘ │
│         │ drift          │ drift         │ MethodChannel  │ shared_   │
│         │                │               │ + drift cache  │ prefs     │
└─────────┼────────────────┼───────────────┼────────────────┼──────────┘
          │                │               │                │
          ▼                ▼               ▼                ▼
       ┌──────────────────────────┐  ┌────────────────────────────────┐
       │  SQLite (drift) on-device│  │  Platform Channels (Pigeon)    │
       │  ─ block_list            │  │  ─ usage:queryRange            │
       │  ─ daily_streak          │  │  ─ accessibility:isEnabled     │
       │  ─ pause_events          │  │  ─ overlay:hasPermission       │
       │  ─ daily_checkins        │  │  ─ events:foregroundAppChanged │
       └──────────────────────────┘  └──────────────┬─────────────────┘
                                                    │
┌──────────────────────────────────────────────────────────────────────┐
│              Native Android (Kotlin) — same process                   │
├──────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────┐  ┌──────────────────────────────────┐   │
│  │ NotToDoAccessibility   │  │ UsageStatsBridge (Kotlin)        │   │
│  │ Service                │  │ ─ wraps UsageStatsManager        │   │
│  │ ─ TYPE_WINDOW_STATE_   │  │ ─ runs on background Executor    │   │
│  │   CHANGED listener     │  │ ─ caches per-day aggregates      │   │
│  │ ─ owns block-list copy │  └──────────────────────────────────┘   │
│  │   (loaded from SQLite) │                                          │
│  │ ─ debounces events     │  ┌──────────────────────────────────┐   │
│  │ ─ launches PauseActivity│ │ NotificationScheduler (Kotlin)   │   │
│  └────────────┬───────────┘  │ ─ AlarmManager exact-alarm for   │   │
│               │              │   user-chosen daily reminder     │   │
│               ▼              │ ─ WorkManager periodic for       │   │
│   ┌────────────────────────┐ │   streak roll-over (>15 min OK)  │   │
│   │ PauseActivity          │ └──────────────────────────────────┘   │
│   │ (Flutter Activity, full│                                          │
│   │  screen, separate route)│                                         │
│   └────────────────────────┘                                          │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| **Presentation** (Dart) | Screens, widgets, navigation, form state. Zero platform calls. | Flutter widgets + `flutter_riverpod` (or `provider`) |
| **Domain** (Dart) | Business rules: streak math, block-match logic, daily check-in resolution. Pure Dart, unit-testable without Flutter. | Plain Dart classes, no I/O |
| **Data** (Dart) | Repositories that hide source (DB vs platform channel). Caches usage queries. | `drift` for SQLite, `shared_preferences` for prefs, MethodChannel/Pigeon for native bridge |
| **Platform Bridge** (Kotlin) | Thin wrappers that expose `UsageStatsManager`, accessibility-state checks, overlay-permission checks, notification scheduling. | `MainActivity` registers Pigeon-generated channels |
| **AccessibilityService** (Kotlin) | Detects foreground-app changes, matches against block list, emits "blocked launch" events, launches PauseActivity. Owns its own block-list snapshot loaded from SQLite at start and refreshed on broadcast. | Extends `AccessibilityService`, declared in manifest with `foregroundServiceType="specialUse"` if it needs FGS escalation |
| **PauseActivity** (Flutter Activity) | Renders the Flutter pause UI as a full-screen activity launched on top of the offending app. Hosts cooldown timer, "I'll wait" / "Use anyway" choices, logs decision. | Second `FlutterActivity` declared in manifest with `singleInstance` + `excludeFromRecents`, started by the Accessibility Service via `Intent` with `FLAG_ACTIVITY_NEW_TASK` |
| **NotificationScheduler** (Kotlin) | Daily reminder at user-chosen time + streak roll-over at midnight. | `AlarmManager` (`setExactAndAllowWhileIdle`) for user-time-pinned reminder; `WorkManager` periodic worker (≥15 min interval) for streak compute |

## Recommended Project Structure

```
not_to_do_list/
├── lib/
│   ├── main.dart                    # App entry; Pigeon channel init; route to PauseScreen if launched as pause flow
│   ├── app.dart                     # MaterialApp, theming, router
│   │
│   ├── core/                        # Cross-cutting, no feature dependencies
│   │   ├── di/                      # Riverpod providers / GetIt registry
│   │   ├── platform/                # Pigeon-generated channel API + Dart wrappers
│   │   │   ├── usage_api.dart       # generated by Pigeon
│   │   │   ├── accessibility_api.dart
│   │   │   └── overlay_api.dart
│   │   ├── error/                   # AppFailure types, Result wrapper
│   │   └── time/                    # Clock abstraction (testability)
│   │
│   ├── data/                        # Repositories + sources (no UI, no domain logic)
│   │   ├── db/
│   │   │   ├── app_database.dart    # drift database
│   │   │   └── tables/              # block_list, streak, pause_events, checkins
│   │   ├── repositories/
│   │   │   ├── block_list_repository.dart
│   │   │   ├── streak_repository.dart
│   │   │   ├── usage_repository.dart      # caches queryRange results per day
│   │   │   └── settings_repository.dart
│   │   └── models/                  # Data DTOs (mapped to/from domain entities)
│   │
│   ├── domain/                      # Pure Dart, no Flutter or platform imports
│   │   ├── entities/                # NotToDoItem, StreakDay, PauseEvent, DailyCheckin
│   │   ├── usecases/
│   │   │   ├── compute_streak.dart
│   │   │   ├── resolve_pause_decision.dart
│   │   │   └── aggregate_usage.dart
│   │   └── policies/                # threshold rules, blocking rules
│   │
│   ├── features/                    # One folder per user-facing feature
│   │   ├── onboarding/
│   │   │   ├── pages/               # Permission grant flow
│   │   │   ├── widgets/
│   │   │   └── controllers/         # Riverpod notifiers
│   │   ├── block_list/
│   │   │   ├── pages/               # List, add-app picker, add-habit form
│   │   │   ├── widgets/
│   │   │   └── controllers/
│   │   ├── dashboard/
│   │   │   ├── pages/               # Daily / weekly / monthly views
│   │   │   ├── widgets/             # Bar charts, top-apps list
│   │   │   └── controllers/
│   │   ├── pause/                   # The pause screen — own feature module
│   │   │   ├── pages/               # PauseScreen
│   │   │   ├── widgets/             # Cooldown ring, motivation note
│   │   │   └── controllers/
│   │   ├── checkin/
│   │   └── settings/
│   │
│   └── theme/                       # Colors, typography, dimensions
│
├── android/
│   └── app/
│       └── src/main/
│           ├── AndroidManifest.xml  # Service declarations, permissions, PauseActivity
│           ├── kotlin/com/.../
│           │   ├── MainActivity.kt
│           │   ├── PauseActivity.kt              # Second FlutterActivity
│           │   ├── service/
│           │   │   └── NotToDoAccessibilityService.kt
│           │   ├── platform/
│           │   │   ├── UsageStatsBridge.kt       # Pigeon @HostApi impl
│           │   │   ├── AccessibilityBridge.kt
│           │   │   ├── OverlayBridge.kt
│           │   │   └── NotificationScheduler.kt
│           │   ├── work/
│           │   │   ├── StreakRolloverWorker.kt   # WorkManager
│           │   │   └── DailyReminderReceiver.kt  # AlarmManager target
│           │   └── pigeon/                       # Pigeon-generated Kotlin
│           └── res/
│               └── xml/
│                   └── accessibility_service_config.xml
│
├── pigeons/                         # Pigeon schema (single source of truth for Dart↔Kotlin types)
│   ├── usage_api.dart
│   ├── accessibility_api.dart
│   └── overlay_api.dart
│
└── test/
    ├── domain/                      # Unit tests for use cases (no Flutter)
    ├── data/                        # Repository tests with in-memory drift
    ├── features/                    # Widget tests
    └── golden/                      # Pause screen golden tests
```

### Structure Rationale

- **`lib/core/`, `lib/data/`, `lib/domain/`, `lib/features/`** — A layered + feature-first hybrid. `domain` is pure Dart and stays unit-testable in isolation; `features` are vertical slices that own their own UI + controllers but share the `data` and `domain` layers. This keeps the tree shallow enough for a solo dev while preventing the "everything in one folder" mess.
- **`pigeons/`** — Pigeon generates type-safe Dart↔Kotlin code from a Dart schema. Strongly preferred over hand-written MethodChannel string keys: catches breaking changes at compile time, eliminates a class of "wrong type passed across channel" bugs, and the schema doubles as documentation of the bridge surface.
- **`features/pause/`** — Pause is structurally a feature, not just a screen. It has its own controller, its own UX (cooldown ring, "use anyway" CTA, decision logging) and is launched via a different entrypoint than the rest of the app. Treating it as a feature module makes the dual-activity nature explicit.
- **`android/.../service/` separate from `android/.../platform/`** — Services are long-lived OS-managed components; platform bridges are short-lived call handlers. Mixing them obscures lifecycle.

## Architectural Patterns

### Pattern 1: Native-owned event source, Dart-owned UI state

**What:** The AccessibilityService is the source of truth for "blocked app launched." It does *not* try to push events back to Dart in real time. Instead, when a blocked launch is detected, the service:
1. Logs the event to SQLite directly (Kotlin reads/writes the same drift database file via Room or SQLDelight on the Kotlin side, OR via a small Kotlin SQLite wrapper that reads the same schema).
2. Launches `PauseActivity` (a Flutter Activity) with intent extras: `packageName`, `eventTimestamp`.
3. The PauseActivity boots Flutter with a route that reads those extras and shows the pause UI.

**When to use:** Whenever the native side is the authoritative event source AND the user-visible reaction is a full-screen UI. This sidesteps the well-known [EventChannel-from-background-isolate footgun](https://github.com/flutter/flutter/issues/76988) entirely — there is no background isolate to keep alive.

**Trade-offs:**
- Pro: Zero IPC reliability concerns. PauseActivity launches are handled by the OS, not by a custom IPC channel.
- Pro: Works even if the main Flutter UI process was killed.
- Con: Two FlutterEngine instances briefly (main UI engine + pause engine). Mitigate with `FlutterEngineCache` so the pause engine pre-warms once and reuses on subsequent triggers.
- Con: Two processes touching the SQLite file → must use WAL mode and short-lived connections on the Kotlin side, or route writes through the foreground process via a content-provider/broadcast and only do a single direct read in the service to load the block list.

**Recommended simplification:** keep the AccessibilityService's view of the block list as a small in-memory `Set<String>` of package names. Loaded once on service start, refreshed when the Dart app sends a `BLOCK_LIST_UPDATED` LocalBroadcast. The service does NOT write to SQLite; it sends the pause event as intent extras to PauseActivity, and PauseActivity (running Flutter) writes the row through the normal Dart repository. One writer, no contention.

### Pattern 2: Pigeon for synchronous Dart→Native calls; LocalBroadcast for Native→Dart pokes

**What:** Use Pigeon-generated `@HostApi` interfaces for everything Dart asks Kotlin to do (query usage stats, check accessibility-enabled, schedule a notification). Use `LocalBroadcastManager` (or its modern equivalent — a flow exposed by a singleton bridge) for the few pokes the native side needs to send to a *running* Dart app — most importantly, to invalidate the usage cache when the user returns from Settings.

**When to use:** Whenever Dart→Native is request/response. EventChannel is reserved for one specific use: streaming live foreground-app changes to the dashboard while the app is in the foreground (debug/diagnostics use only — production blocking flow uses the Activity-launch pattern above).

**Trade-offs:**
- Pro: Avoids EventChannel-from-background-isolate complexity entirely.
- Pro: Pigeon catches type mismatches at build time.
- Con: One more code-gen step in the dev loop (`dart run pigeon ...` after schema changes).

### Pattern 3: Polling + caching for UsageStatsManager, never streaming

**What:** Don't try to "tail" usage stats. `UsageStatsManager.queryUsageStats()` is a snapshot API that aggregates by interval. The pattern:
1. `UsageRepository.queryDay(date)` checks an in-memory + drift cache keyed by `(date, lastQueryAt)`.
2. On cache miss (or staleness > 5 min for today, never for past days), call the platform via Pigeon.
3. Kotlin runs `queryUsageStats(INTERVAL_DAILY, dayStart, dayEnd)` on a background `Executor` and returns a list of `UsagePackageStat`.
4. Dart aggregates into `UsageRepository`'s drift-backed cache; future reads are local.

**When to use:** Always. The dashboard reads from the cache. The "is the user over the threshold today?" check (for streak-break detection) reads the same cache and refreshes today's slot at most once per minute.

**Trade-offs:**
- Pro: Cheap. No background polling loop, no battery cost.
- Pro: Past days are immutable once cached — fast historical views.
- Con: "Latest" data is up to 5 minutes stale. This is fine for a mindfulness app; do not optimize for sub-minute freshness.

**Important:** `queryUsageStats` is documented to be slow enough to drop frames if called on the main thread. Always call from a background `Executor` on the Kotlin side; Pigeon's async API maps cleanly to Dart `Future`.

### Pattern 4: Daily reminder via AlarmManager, streak job via WorkManager

**What:** Two distinct schedulers, two distinct jobs:
- **Daily reminder** (user-chosen time, must fire near that exact minute) → `AlarmManager.setExactAndAllowWhileIdle()` with `RECEIVE_BOOT_COMPLETED` to re-arm after reboot. The receiver posts a local notification via `NotificationCompat`.
- **Streak roll-over** (compute "did yesterday count?" and update streak counter) → `WorkManager` periodic worker, 24h interval with a few hours of flex. This job tolerates Doze and batching — exact timing doesn't matter because the streak rolls over conceptually at midnight but the *computation* can happen at the next available wake window.

**When to use:** This split is canonical: AlarmManager for "user-perceived precise time," WorkManager for "needs to happen reliably but timing is flexible."

**Trade-offs:**
- Pro: Battery-friendly default (WorkManager respects Doze).
- Pro: User-chosen reminder still feels punctual.
- Con: Exact alarms on Android 12+ require `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` permission; `USE_EXACT_ALARM` is whitelisted for "calendar/reminder/alarm app" categories on Play. Document the use-case in the permission justification.

**Doze caveat:** `WorkManager` periodic minimum is 15 minutes, and even then the system batches. Do **not** try to use it for sub-15-minute polling. There is no need to — the streak job is daily.

### Pattern 5: Pause UI as a Flutter Activity, NOT a system overlay

**What:** When the AccessibilityService detects a blocked launch, it starts `PauseActivity` (a `FlutterActivity` declared in the manifest) with `Intent.FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TOP`. PauseActivity covers the screen the same way any other foreground activity does.

**When to use:** Always for v1. See "Decision: Pause UI mechanism" below.

**Trade-offs:**
- Pro: No `SYSTEM_ALERT_WINDOW` permission needed → cleaner Play Store review story.
- Pro: Full Flutter widget tree available, including Material theming, Hero animations, charts.
- Pro: Back button + system gestures work normally.
- Con: There is a brief flash of the blocked app before PauseActivity covers it. Mitigate with `android:launchMode="singleInstance"` + warm `FlutterEngine` from the cache so cold-start is sub-300ms.
- Con: On some OEMs, launching activities from a service in the background is restricted post-Android 10. AccessibilityService is one of the documented exceptions (`canStartActivityFromBackground` is implicitly granted to active accessibility services).

## Data Flow

### Flow 1: Blocked-app launch detected → pause screen shown

```
User taps Instagram on launcher
        ↓
Android compositor brings Instagram activity forward
        ↓
AccessibilityService receives TYPE_WINDOW_STATE_CHANGED
  ─ event.packageName = "com.instagram.android"
  ─ debounce: ignore if same pkg fired < 800ms ago
        ↓
Service checks in-memory blockList (Set<String>)
  ─ "com.instagram.android" ∈ blockList → matched
        ↓
Service builds Intent for PauseActivity:
  ─ Intent(this, PauseActivity::class.java)
  ─ flags: FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TOP
  ─ extras: blocked_pkg, ts, source = "accessibility"
        ↓
startActivity(intent)  ── allowed because we are an active AccessibilityService
        ↓
PauseActivity boots Flutter (warm engine from FlutterEngineCache)
        ↓
Flutter route /pause reads extras via initial route args
        ↓
PauseController:
  ─ loads NotToDoItem(pkg) from BlockListRepository
  ─ loads user's default cooldown
  ─ logs PauseEvent row to drift
  ─ starts cooldown timer
        ↓
User chooses [Wait it out 1m] / [Wait 3m] / [Use anyway]
        ↓
On "Wait" expiry → finishActivity() → user is back on launcher
On "Use anyway" → log decision → finishActivity() → Instagram resumes
```

### Flow 2: Block list updated → AccessibilityService refreshes

```
User adds "TikTok" to not-to-do list in Flutter UI
        ↓
BlockListController.add(pkg)
        ↓
BlockListRepository.insert(pkg) → drift INSERT
        ↓
Repository fires LocalBroadcast: ACTION_BLOCKLIST_UPDATED
        ↓
NotToDoAccessibilityService receives broadcast
        ↓
Reloads its in-memory Set<String> from drift via a single read
```

### Flow 3: Dashboard render → usage data displayed

```
User opens Dashboard tab
        ↓
DashboardController watches UsageRepository.weekStream
        ↓
Repository checks drift cache: 7 days needed
  ─ days [today-6 .. today-1] cached → return immediately
  ─ today: stale > 5 min → refresh
        ↓
Repository.refreshToday():
  ─ via Pigeon: usageApi.queryRange(todayStart, now)
        ↓
UsageStatsBridge (Kotlin) on Executor:
  ─ usageStatsManager.queryUsageStats(INTERVAL_DAILY, todayStart, now)
  ─ map to List<UsagePackageStat>
        ↓
Pigeon returns Future<List<UsagePackageStat>> to Dart
        ↓
Repository upserts today's row in drift cache
        ↓
DashboardController receives new data via stream
        ↓
Bar chart rebuilds; not-to-do items highlighted in red
```

### Flow 4: Daily reminder fires

```
User sets reminder time = 21:00 in Settings
        ↓
SettingsController saves to shared_preferences
        ↓
Calls notificationApi.scheduleDailyReminder(hour=21, min=0) via Pigeon
        ↓
NotificationScheduler (Kotlin):
  ─ AlarmManager.setExactAndAllowWhileIdle(
        RTC_WAKEUP,
        nextOccurrenceOf(21:00),
        pendingIntent → DailyReminderReceiver
    )
        ↓
Phone reaches 21:00
        ↓
DailyReminderReceiver.onReceive():
  ─ posts NotificationCompat notification: "How did today go?"
  ─ tap → opens app to /checkin route
  ─ re-arms alarm for tomorrow 21:00
```

### Flow 5: Daily streak roll-over

```
Phone is on, somewhere between 00:00 and 06:00
        ↓
WorkManager finds StreakRolloverWorker is due (24h periodic, flex 4h)
        ↓
Worker.doWork():
  ─ via Pigeon (or direct DB read on Kotlin side, see note below):
       query yesterday's usage for each blocked pkg
  ─ compute: did any pkg exceed threshold? did user check in?
  ─ insert StreakDay row (status: success / broken / pending)
        ↓
If broken → post a "streak broken" notification (if user opted in)
```
*Note:* simplest is to have the worker just call into Dart via the Flutter engine using `flutter_workmanager`. For v1, given that the streak compute touches drift, prefer doing the entire computation in Dart inside a background isolate spawned by `flutter_workmanager`. This keeps streak logic in one language.

## Suggested Build Order

The build order stages risk: get permissions and platform plumbing right first (they have the longest tail of "weird OEM bugs"), then layer features on a known-good foundation.

| # | Phase | Goal (verifiable) | Why this slot |
|---|-------|-------------------|---------------|
| 1 | **Foundation: data + domain skeleton** | drift database with empty tables, BlockListRepository CRUD, domain entities, unit tests pass. App boots to an empty list screen. | Establishes layering before any platform work. Pure-Dart, fast feedback. |
| 2 | **Block list CRUD UI** | User can add/remove/edit a not-to-do item. List persists across restarts. | Ships visible value first; gives a concrete data model to build everything else on top of. |
| 3 | **Permission onboarding flow** | App detects whether `PACKAGE_USAGE_STATS` and Accessibility are granted; deep-links to Settings; refreshes state on resume. | Both subsequent features depend on these permissions. Doing this early surfaces Play Store policy questions while you can still pivot. |
| 4 | **UsageStatsManager bridge + dashboard** | Pigeon channel `usageApi.queryRange()` works. Dashboard renders today's top apps. Caching layer in place. | Independent of the blocker; ships value (screen-time view) and validates the platform-channel pattern. |
| 5 | **Accessibility Service + blocker MVP** | Service detects foreground-app changes, matches against block list, opens a placeholder full-screen activity. No real pause UX yet. | Highest-risk piece — get the platform integration working before investing in UX. |
| 6 | **Pause UX + cooldown timer** | PauseActivity hosts the real Flutter pause screen with cooldown picker (1/3/5/10 min), motivation note, "use anyway" path. PauseEvent rows are logged. | Builds on (5). This is the wedge — the magic moment. Iterate on UX here. |
| 7 | **Streak engine + daily check-in** | StreakRolloverWorker runs nightly. Daily check-in screen prompts on first open of the day. Streak counter on home screen. | Needs blocker (6) and usage data (4) to compute honest streaks. |
| 8 | **Daily reminder notification** | User picks reminder time in Settings; AlarmManager fires; tapping opens to check-in. Survives reboot. | Last because it's the simplest and depends on check-in flow existing. |
| 9 | **Polish: empty states, animations, app picker UX, theming, settings, permission-revoked recovery** | Pass internal-test pre-flight checklist. | Final mile. |
| 10 | **Play Store submission prep** | Permission justification copy, privacy-policy page, screenshots, store listing. | Last; requires a stable build. |

**Hard dependencies:** 5 → 6 (no pause UX without the service detecting), 4 + 6 → 7 (streak needs usage + pause data), 7 → 8 (reminder routes to check-in).

**Parallelizable cuts if behind schedule:** 9 can compress; 4 (dashboard) can ship as a bare list before charts.

## Scaling Considerations

This is an on-device app with no backend. "Scale" means: device, time, and historical-data growth.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Day 1 (single device, small list) | Synchronous reads, no caching needed for block list. UsageStatsManager queries cached for 5 min on today. |
| 6 months in (180 days of streak history, 50 not-to-do apps, 1000s of pause events) | Index pause_events by `(timestamp, package)`. Add periodic compaction worker that deletes per-app raw usage rows older than 90 days, keeping daily aggregates. |
| 2 years in | Same as above; SQLite easily handles tens of thousands of rows. The bottleneck will be drift query performance on the dashboard's monthly view, not storage. |

### Scaling Priorities

1. **First bottleneck: monthly-view query.** Aggregating 30 days × N apps in Dart is slow if done naïvely. Pre-aggregate at write time into a `daily_usage_summary` table. Read summaries, not raw events.
2. **Second bottleneck: pause_events table.** A user opening a blocked app 50 times a day generates 18k rows/year. Add an automatic cull (keep last 90 days raw, summarize older).
3. **Non-bottleneck: AccessibilityService load.** TYPE_WINDOW_STATE_CHANGED fires frequently but matching against a `Set<String>.contains()` is O(1). Don't over-engineer this.

## Anti-Patterns

### Anti-Pattern 1: System-overlay (`TYPE_APPLICATION_OVERLAY`) for the pause screen

**What people do:** Use `WindowManager.addView()` with `TYPE_APPLICATION_OVERLAY` to draw the pause UI as an overlay window on top of the blocked app. Requires `SYSTEM_ALERT_WINDOW` permission.
**Why it's wrong for v1:**
1. `SYSTEM_ALERT_WINDOW` is increasingly restricted on Android 12+ and is heavily scrutinized by Play Store review (the policy associates it with overlay-fraud and tap-jacking malware).
2. Overlays can't host a Flutter widget tree without significant gymnastics (FlutterView attached to a non-Activity window).
3. On Android 15+, foreground-service-from-overlay rules add even more constraints.
4. Provides marginal benefit over launching an Activity for our use case (we want the user to clearly perceive "the app you opened was interrupted," and a full-screen Activity does that fine).
**Do this instead:** Launch a `FlutterActivity` ("PauseActivity") from the AccessibilityService. AccessibilityServices are explicitly allowed to start activities from the background. No overlay permission needed. Full Flutter widget tree available.

### Anti-Pattern 2: Long-lived EventChannel from a background isolate

**What people do:** Run a Flutter background isolate (via `flutter_background_service` or similar), hold an `EventChannel` open from the AccessibilityService, push every foreground-app event into Dart in real time.
**Why it's wrong:** Documented to be unreliable across OEMs and Android versions ([flutter#76988](https://github.com/flutter/flutter/issues/76988), [flutter#62738](https://github.com/flutter/flutter/issues/62738)). The background isolate gets killed by Doze, app-standby, OEM "battery optimizers" (Xiaomi, Oppo, Huawei kill aggressively). Race conditions between engine startup and the first event are common. Adds a foreground service notification the user has to see permanently.
**Do this instead:** Keep all event handling in Kotlin. Marshal only the moment-of-action (a blocked launch happening *now*) across the boundary by launching an Activity. Persist anything else (event logs, aggregates) in the database, then read from Dart on next foreground.

### Anti-Pattern 3: Polling foreground app via `UsageStatsManager`

**What people do:** Run a periodic worker every minute that queries usage events to detect "is the user in a blocked app right now?"
**Why it's wrong:** `UsageStatsManager` lags by tens of seconds and aggregates by interval; it cannot reliably detect "the user just opened Instagram 200ms ago" — by the time you see the event, the user has scrolled. Also: 1-min polling is incompatible with WorkManager's 15-min minimum and would require an always-on foreground service.
**Do this instead:** Use AccessibilityService for real-time detection (the platform tells *you* synchronously when the foreground window changes); use UsageStatsManager only for aggregate reporting and threshold checks.

### Anti-Pattern 4: Hand-written MethodChannel string keys

**What people do:** `MethodChannel('com.app/usage').invokeMethod('queryRange', {'start': ..., 'end': ...})` everywhere, with no type checking on either side.
**Why it's wrong:** Every refactor breaks at runtime, not compile time. Argument typos surface as `MissingPluginException` at the worst possible moment.
**Do this instead:** Use [Pigeon](https://pub.dev/packages/pigeon). Define a Dart schema in `pigeons/`, run code-gen, get type-safe Dart and Kotlin bindings.

### Anti-Pattern 5: AccessibilityService writing directly to the same SQLite file the Dart side writes to

**What people do:** Have the service do `INSERT INTO pause_events ...` from Kotlin in parallel with Dart writes.
**Why it's wrong:** Two-process SQLite writers require WAL + careful locking; even then, you have two ORMs with two views of the schema that must stay in sync. This is the kind of bug that surfaces months in.
**Do this instead:** One writer (Dart). Service holds an in-memory block-list snapshot, refreshed on broadcast. When a pause happens, the service hands the event to PauseActivity via Intent extras; PauseActivity (Dart) does the write. Single owner, no contention.

## Integration Points

### Platform APIs

| API | Integration Pattern | Notes |
|-----|---------------------|-------|
| `UsageStatsManager` | Kotlin wrapper exposed via Pigeon `@HostApi`. Run on `Executors.newSingleThreadExecutor()`. | Slow on main thread → drops frames. Requires `PACKAGE_USAGE_STATS` granted via Settings (no runtime prompt). |
| `AccessibilityService` | Direct Kotlin service; no Flutter involvement until PauseActivity launches. Config XML in `res/xml/accessibility_service_config.xml` declares `accessibilityEventTypes="typeWindowStateChanged"`. | Granted via Settings → Accessibility. Play Store requires explicit justification copy. |
| `AlarmManager` (exact) | Kotlin scheduler called via Pigeon. `USE_EXACT_ALARM` permission for Android 13+ (auto-granted for "alarm/reminder" use case). | Re-arm in `BOOT_COMPLETED` receiver. |
| `WorkManager` | Used for streak roll-over. Either pure-Kotlin worker or `flutter_workmanager` for Dart-resident logic. | Min interval 15 min. Doze-aware. |
| `NotificationManager` (system) | Wrapped in Kotlin; Dart calls `notificationApi.show(...)` via Pigeon for the daily reminder. | Channels created on first use. POST_NOTIFICATIONS runtime permission on Android 13+. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Flutter UI ↔ Domain layer | Direct Dart calls | Pure Dart, no Flutter imports in domain |
| Domain ↔ Data | Repository interfaces in domain, impls in data | Allows mocking in tests |
| Data ↔ Platform (Kotlin) | Pigeon-generated `@HostApi` | Type-safe, codegen on schema change |
| Dart UI process ↔ AccessibilityService | One-way: Dart broadcasts block-list changes; service launches PauseActivity Intent on detection | No long-lived IPC; each interaction is fire-and-forget |
| AccessibilityService ↔ PauseActivity | Intent extras (blocked_pkg, ts, source) | Standard Android activity launch |
| PauseActivity ↔ rest of app | Shared SQLite database (drift) | PauseActivity is a separate FlutterActivity but shares the same drift DB file via the same package |

## Decision: Pause UI mechanism — Flutter Activity over native overlay

**Decision:** Launch a `FlutterActivity` ("PauseActivity") from the AccessibilityService. Do **not** use `TYPE_APPLICATION_OVERLAY` / `SYSTEM_ALERT_WINDOW`.

**Rationale:**
1. **Play Store policy.** `SYSTEM_ALERT_WINDOW` is associated with overlay-malware patterns and gets extra review scrutiny. AccessibilityService permission is already a heavy review item; adding overlay permission compounds the risk.
2. **Android 12+ restrictions.** The system tightened overlay-permission grant flow on Android 12; on Android 15+, foreground services started from an overlay window have additional constraints that complicate the architecture.
3. **Flutter integration.** Hosting a Flutter widget tree inside a `WindowManager.addView()` overlay requires manually constructing a `FlutterView` with a custom engine; full theming, navigation, gestures, and animations all require extra plumbing. A `FlutterActivity` gives all of that for free.
4. **AccessibilityService is permitted to launch activities from the background.** This is one of the documented exemptions to Android 10's background-activity-launch restrictions, removing the main reason developers historically reached for overlays.
5. **UX is equivalent.** The user perceives "I tapped Instagram, then the pause screen appeared." Whether that screen is technically an overlay or a full-screen activity is invisible to them.

**Trade-off accepted:** ~200–400ms of the blocked app being briefly visible before PauseActivity covers it. Mitigated by pre-warming a `FlutterEngine` in `FlutterEngineCache` at app start, so PauseActivity's first frame renders fast.

## Foreground Service / Battery / Doze Considerations

- **AccessibilityService does NOT need to be a foreground service.** AccessibilityServices have their own lifecycle managed by the system; they remain bound as long as the user has the service enabled in Settings, and they are not subject to the same Doze restrictions as regular background services. No persistent "App is running" notification is required.
- **Avoid foreground services entirely in v1.** No persistent notification, no `foregroundServiceType` declaration headaches, no Android 14 `specialUse` justification metadata to fight through Play review. The architecture above does not need one.
- **Doze impact on the streak worker:** `WorkManager` runs during maintenance windows even in Doze. Streak roll-over does not need exact timing, so this is fine.
- **Doze impact on the daily reminder:** `setExactAndAllowWhileIdle` is the documented escape hatch — it fires even in Doze. This is the right tool for a user-perceived precise time.
- **OEM "battery optimizer" risk (Xiaomi, Oppo, Huawei, Samsung).** These vendors aggressively kill background work beyond stock Android rules. Mitigation:
  - Use AlarmManager (not just WorkManager) for the reminder — fewer OEMs interfere with alarms.
  - On first reminder failure, prompt user to whitelist the app from battery optimization via `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
  - Document this explicitly in the onboarding flow as "Step 3: tell your phone not to kill the app at night."
- **Permission revocation recovery:** If the user disables Accessibility from Settings, the app must detect this on next foreground (via `AccessibilityManager.getEnabledAccessibilityServiceList`) and route to a re-grant screen. Same for `PACKAGE_USAGE_STATS`. Build this from day 1, not as an afterthought.

## Sources

- [AccessibilityService — Android Developers](https://developer.android.com/reference/android/accessibilityservice/AccessibilityService) (HIGH)
- [Create an accessibility service — Android Developers guide](https://developer.android.com/guide/topics/ui/accessibility/service) (HIGH)
- [UsageStatsManager — Android Developers](https://developer.android.com/reference/android/app/usage/UsageStatsManager) (HIGH)
- [Foreground service types — Android Developers](https://developer.android.com/develop/background-work/services/fgs/service-types) (HIGH)
- [Foreground service types are required (Android 14)](https://developer.android.com/about/versions/14/changes/fgs-types-required) (HIGH)
- [Behavior changes: Apps targeting Android 15 or higher](https://developer.android.com/about/versions/15/behavior-changes-15) (HIGH)
- [Define work requests — WorkManager](https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work) (HIGH)
- [Schedule alarms — Android Developers](https://developer.android.com/develop/background-work/services/alarms) (HIGH)
- [WorkManager periodicity — Android Developers blog](https://medium.com/androiddevelopers/workmanager-periodicity-ff35185ff006) (MEDIUM)
- [Pigeon — pub.dev](https://pub.dev/packages/pigeon) (HIGH — official Flutter team package)
- [flutter#76988: EventChannel not working when app is in background](https://github.com/flutter/flutter/issues/76988) (HIGH — documents the footgun the architecture avoids)
- [flutter#62738: platform channel invokeMethod from background service](https://github.com/flutter/flutter/issues/62738) (HIGH)
- [usage_stats Flutter package](https://pub.dev/packages/usage_stats) (MEDIUM — reference for the Pigeon wrapper shape)
- [Secure sensitive activities — Android Developers (overlay/fraud guidance)](https://developer.android.com/security/fraud-prevention/activities) (HIGH)
- [Android 12 behavior changes — Android Developers](https://developer.android.com/about/versions/12/behavior-changes-all) (HIGH)

---
*Architecture research for: Not To-Do List (Flutter + native Android)*
*Researched: 2026-04-26*
