# Phase 5: Streak Engine & Daily Reminder — Research

**Researched:** 2026-05-21
**Domain:** Hybrid honest per-item streak engine + exact-alarm daily reminder, on-device Android/Flutter
**Confidence:** HIGH (CONTEXT.md locks all four discussion blocks D-01..D-16; schemas + Pigeon stub already exist; carry-forward patterns from Phases 1–4 dictate most of the engine surface)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Daily check-in UX (D-01..04)**

- **D-01 — Trigger: BOTH reminder tap AND Home open.** On day D+1 cold-start of Home, if any entry has `daily_checkins WHERE day=D AND entryId=X` missing, surface the pending state. Reminder notification fires at user's chosen time on day D (NOTF-02) and deep-links to `/checkin` (NOTF-03) — same destination as the Home-triggered path. Both code paths route to the same `/checkin` screen. No double-prompt: `/checkin` is idempotent — already-answered entries just show as completed in the list.
- **D-02 — Surface: dedicated `/checkin` GoRoute.** Full-screen, calm, focused. Lists all pending entries with `Yes` / `No` toggle per row plus a single `Submit` button. NOT a bottom-sheet on Home, NOT per-card inline toggle. Reminder deep-link target. New `GoRoute(path: '/checkin', builder: …)` added to `lib/core/router/app_router.dart` (same pattern Phase 3 used for `/dashboard`).
- **D-03 — Multi-entry: single screen, all entries listed, single submit.** Yes/No per row, one `Submit` action writes N rows to `daily_checkins` in a single Drift transaction. NOT one-by-one swipe-through. Fastest, lowest friction.
- **D-04 — Answer window: all-day until next midnight.** Yesterday's check-in is answerable until tonight's midnight (home-tz `LocalDate` boundary per STRK-08). At next-midnight rollover, unanswered entries are written with `source=1` (self-reported-only = false implied) — streak source falls back to system-confirmed-only IF a11y was tracking, else `status=2` (incomplete-data). 48-hour grace was rejected.

**Streak break + recovery copy (D-05..08)**

- **D-05 — Break visual: inline strikethrough on counter.** `🔥 ~~3~~ → 0` on the day of detection; `🔥 0 · best 12` from next day. NO modal, NO sticky banner, NO snackbar.
- **D-06 — Recovery copy: calm fresh-start.** Reset state literal copy = `"🔥 0 · best {N}"`. Settings → Streak help text uses `"Each day is a fresh start"`.
- **D-07 — Day labels (4 distinct dot styles in Streak history calendar):**
  - **green ✓** = `status=0 success` AND `source=0 system-confirmed`
  - **blue ○** = `status=0 success` AND `source=1 self-reported-only`
  - **red ×** = `status=1 broken`
  - **grey —** = `status=2 incomplete-data` (with tap-tooltip `"Tracking was off this day"`)
  Today's pending day = no dot (just date number). Tooltip is MANDATORY on grey.
- **D-08 — Threshold UI: Settings-only global, no per-entry override in v1.** Single `streak_threshold_minutes` setting (default 5 per STRK-02). No per-entry override field on `block_list`.

**Reminder default + notification copy (D-09..12)**

- **D-09 — Default time: 21:00 (9:00 PM) local.** Stored in `shared_preferences` key `reminder_hour_minute` as single int = `hour * 60 + minute`.
- **D-10 — Notification copy: calm question.** Title `"Daily check-in"`, body `"How did today go?"`. PendingIntent deep-link to `/checkin`. NO streak-aware personalization. NO entry names (privacy).
- **D-11 — Notification scope: ONE notification covering all entries.** Single `Notification` with channel `daily_checkin`. NOT one per entry. NOT suppress-if-already-checked-in.
- **D-12 — NOTF-07 banner: sticky top of Home, reuse Phase 3 `HealthCheckBanner` pattern.** Copy `"Reminder is off — tap to fix"`. Tap → `ACTION_APP_NOTIFICATION_SETTINGS` if `shouldShowRequestPermissionRationale` is false; else in-app rationale + re-prompt. No dismiss button. Banner stack order: tracking-offline (Phase 3) > reminder-off (Phase 5).

**Home streak surface (D-13..16)**

- **D-13 — Placement: inline per-entry badge on each home entry card.** Per-item streak per STRK-01. NOT an aggregated card.
- **D-14 — Badge format: `🔥 3 · best 12`** (literal — flame emoji + current + middot + literal `"best"` + longest).
- **D-15 — Day-0 / never-tracked: render honestly as `🔥 0 · best 0`.** No CTA copy.
- **D-16 — Badge tap target: entry detail screen `/list/edit/:entryId` gains a new "Streak history" section.** 7-column GridView of last 30 days. NOT a new `/streak/:entryId` route.

### Claude's Discretion

- **Schedule-window day-anchoring (STRK-09):** Kotlin `isInScheduleWindow` parity helper from Phase 4 is the source of truth. Cross-midnight windows belong to the **start day's** streak row. Pure-Dart + Kotlin parity test (`schedule_window_streak_anchoring_test.dart`) keeps both in lockstep.
- **`AlarmManager` re-arm pattern:** standard `BOOT_COMPLETED` receiver + alarm re-set on every successful fire. Foreground service NOT needed.
- **Clock-tamper detection cadence:** evaluate on every lazy rollover open. Persisted state = last `(wallClockMs, bootMonotonicNs)` pair in `shared_preferences`. Divergence threshold: > 24 h `|wallDelta - bootMonoDelta|`.
- **Drift schema additions:** **none — `DailyCheckins` and `DailyStreak` tables already exist (Phase 1 scaffold). Add Riverpod providers + DAOs only.** [VERIFIED: read `lib/data/database/tables/daily_checkins_table.dart` + `daily_streak_table.dart`]
- **Notification channel registration:** single channel `daily_checkin` registered at app start, importance = `IMPORTANCE_DEFAULT`.

### Deferred Ideas (OUT OF SCOPE)

- Per-entry streak threshold override → v1.x (DIFF-01)
- Streak-aware notification copy ("Keep your 3-day streak going")
- One notification per entry
- Suppress notification when already checked-in via Home
- Onboarding step for reminder time (uses 21:00 default; Settings any time)
- Dedicated `/streak/:entryId` top-level route
- Engagement copy ("Start your streak", "Yesterday was rough", "Try again")
- Modal/snackbar/banner on streak break
- 48-hour check-in grace window
- Streak sharing / social features / leaderboards (PROJECT.md anti-feature)
- Badges / points / levels (PROJECT.md anti-feature)
- Aggregated "best streak across all entries" card
- Streak threshold per-entry tuning UI
- Multi-window schedules per entry

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **STRK-01** | Each entry has its own per-item streak counter | DailyStreak unique key `(entryId, day)` + Home badge per row (§8) |
| **STRK-02** | Streak auto-breaks if usage > 5 min/day default | Lazy rollover queries `daily_usage_summary.foregroundSeconds` vs `streak_threshold_minutes` (§4) |
| **STRK-03** | Daily self-report check-in, one prompt per entry per day | DailyCheckins unique `(entryId, day)`; `/checkin` idempotent (§7) |
| **STRK-04** | Each day labeled system-confirmed vs self-reported-only | `DailyStreak.source` enum 0/1; resolved by §4 algorithm |
| **STRK-05** | Lazy roll-over on every app open | Algorithm §4 — no WorkManager periodic; runs on `resumed` + cold-start |
| **STRK-06** | Clock tampering detected via boot-monotonic clock | `SystemClock.elapsedRealtimeNanos()` Pigeon call + comparison §4 |
| **STRK-07** | Home shows current + longest streak per entry | Badge per BlockListRow, format `🔥 N · best M` (§8) |
| **STRK-08** | DST + timezone correctness; 23 h and 25 h test days pass | `streakDayFor()` already exists (lib/domain/schedule/streak_day.dart, 04:00 boundary); use DateTime year/month/day constructor not subtract (§4) |
| **STRK-09** | Scheduled entries — only active-window usage counts | Reuse Phase 4 `isInScheduleWindow`; cross-midnight belongs to start day (§4) |
| **NOTF-01** | User configures daily reminder time in Settings (24h selector) | `showTimePicker` + `shared_preferences` (§5, §8) |
| **NOTF-02** | Reminder fires at chosen time | `AlarmManager.setExactAndAllowWhileIdle` via Pigeon (§5) |
| **NOTF-03** | Tap deep-links to `/checkin` | PendingIntent with explicit Intent + GoRouter `/checkin` (§5, §7) |
| **NOTF-04** | Fires within 5 min even under Doze | `setExactAndAllowWhileIdle` is the API contract (§5) |
| **NOTF-05** | Re-armed after reboot via `BOOT_COMPLETED` | `BootReceiver` re-reads `reminder_hour_minute` from `shared_preferences` and re-sets alarm (§5) |
| **NOTF-06** | `POST_NOTIFICATIONS` only after first not-to-do added (earned) | Triggered from `BlockListRepository.insertEntry` post-write hook (§6) |
| **NOTF-07** | If denied, in-app banner reminds | Reminder-off banner mirrors Phase 3 `HealthCheckBanner` (§6, §8) |

</phase_requirements>

---

## 1. Phase Goal Summary

Phase 5 delivers the **trust layer** of the v1 wedge: an honest per-item streak engine (system-threshold + daily self-report hybrid) and a single daily reminder at the user's chosen time. The streak is the only reinforcement loop in v1 (gamification, badges, social are PROJECT.md anti-features). The engine is **lazy-evaluated on every app open** (STRK-05) — no midnight cron. It joins `daily_usage_summary` (Phase 3 writer), `pause_events` (Phase 4 writer), `daily_checkins` (this phase), and `block_list.schedule_*` (Phase 2) to compute each entry's `DailyStreak` row for yesterday on resume. The daily reminder uses `AlarmManager.setExactAndAllowWhileIdle()` (Doze-tolerant) with a `BOOT_COMPLETED` receiver for reboot re-arm; `POST_NOTIFICATIONS` is requested as an **earned prompt** after the user's first not-to-do entry, not in the install funnel. Phase 5 closes with REL-05 — overnight survival on a real Xiaomi or Samsung device (mirroring the REL-04 protocol passed 2026-05-21 on Samsung Galaxy S20 Ultra 5G).

**Primary recommendation:** All the heavy lifting is **schema-locked** (Phase 1 scaffold) and **Pigeon-stubbed** (`NotificationApi` exists in MainActivity with `NotImplementedError`). The scope is: (1) fill the Pigeon `NotificationApi` Kotlin body with a real `AlarmManager` + `BroadcastReceiver` implementation, (2) add 2 new DAOs (`DailyCheckinsDao`, `DailyStreakDao`), (3) write the pure-Dart `StreakRolloverService` with the algorithm in §4, (4) wire 3 new UI surfaces (Home badge, `/checkin` route, entry-detail Streak history section), (5) extend Pigeon `PermissionStatusApi` with a `POST_NOTIFICATIONS` check + `bootMonotonicNanos()` call, (6) ship the OEM-survival REL-05 protocol. No schema migration. No new Drift tables. One bumped `schemaVersion` is **not needed** unless we add columns — and CONTEXT.md D-08 explicitly closes the door on per-entry threshold columns.

---

## 2. Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Streak rollover computation | Dart / app process | — | Pure logic over Drift queries; STRK-05 lazy-on-open; no service needed. The streak engine is a Dart-side `StreakRolloverService` invoked on `AppLifecycleState.resumed`. |
| Clock-tamper detection | Dart + Kotlin (Pigeon read-only) | — | Wall clock = `DateTime.now()` on Dart side; boot-monotonic = `SystemClock.elapsedRealtimeNanos()` via Pigeon read. Comparison runs in Dart. |
| Schedule-window day-anchoring | Dart (`isInScheduleWindow`) | Kotlin parity helper exists from Phase 4 | Reuse pure-Dart helper; Kotlin parity preserved (already proven by 04-02 parity test) — streak engine runs Dart-side, but the helper is shared truth. |
| Daily reminder schedule + fire | Android Platform (AlarmManager + BroadcastReceiver) | Dart (Pigeon caller) | `AlarmManager.setExactAndAllowWhileIdle()` is a platform API; only Kotlin can set it. Dart calls `NotificationApi.scheduleDailyReminder(h, m)`. |
| `BOOT_COMPLETED` re-arm | Android Platform (`BootReceiver`) | — | Manifest-declared `BroadcastReceiver` reads `SharedPreferences` (Android-native, same file as Flutter's `shared_preferences` plugin) and re-arms alarm. Does NOT start a FlutterEngine. |
| `POST_NOTIFICATIONS` runtime prompt | Dart (via Pigeon) | Android Platform | Use `permission_handler` package OR extend `PermissionStatusApi` with a new method. CONTEXT pattern: extend the existing Pigeon API to keep the architecture consistent. |
| `/checkin` screen + idempotency | Dart (GoRouter + Riverpod) | — | Pure Flutter UI. Single Drift transaction on submit. |
| Notification deep-link to `/checkin` | Android Platform (PendingIntent) | Dart (GoRouter handles route) | Intent extras parsed in `MainActivity.onNewIntent` → `context.go('/checkin')`. |
| Streak history calendar grid | Dart (Flutter widgets) | — | `GridView` of last 30 day-dot widgets in entry detail. |
| Home reminder-off banner | Dart (Flutter widget) | Android Platform (deep-link to system settings) | Mirror Phase 3 `HealthCheckBanner`. |
| OEM-survival test (REL-05) | Manual / real device | — | Cannot be unit-tested; mirror REL-04 protocol on Xiaomi or Samsung. |

---

## 3. Standard Stack

### Core (no new packages needed — all in pubspec already)

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| **drift** | ^2.33.0 [VERIFIED: pubspec.yaml] | Local DB — `DailyStreak` + `DailyCheckins` DAOs | Schema already defined Phase 1; mirror the `DailyUsageSummaryDao` + `PauseEventDao` patterns |
| **flutter_riverpod** | ^3.3.1 [VERIFIED: pubspec.yaml] | State management for streak service, check-in screen, reminder settings | Established pattern across Phases 1–4; hand-written providers (no codegen — codegen dropped per pubspec.yaml notes) |
| **go_router** | ^17.2.3 [VERIFIED: pubspec.yaml] | `/checkin` route addition | Mirror how `/dashboard` (Phase 3) and `/pause/:entryId` (Phase 4) were added |
| **shared_preferences** | ^2.5.5 [VERIFIED: pubspec.yaml] | Store `reminder_hour_minute`, `streak_threshold_minutes`, last `(wallClockMs, bootMonotonicNs)` pair | Extend `OnboardingKeys`-pattern with `StreakKeys` constants |
| **intl** | ^0.20.2 [VERIFIED: pubspec.yaml] | `DateFormat.jm()` for "9:00 PM" reminder picker subtitle | Already in pubspec; no new dep |
| **pigeon** | ^26.3.4 [VERIFIED: pubspec.yaml dev_dependencies] | Extend `NotificationApi` body; add `bootMonotonicNanos()` and `postNotificationsGranted()` to existing APIs | Established pattern; all Dart↔Kotlin calls go through Pigeon (T-04 D-10 of Phase 4) |
| **url_launcher** | ^6.3.0 [VERIFIED: pubspec.yaml] | Deep-link to `Settings.ACTION_APP_NOTIFICATION_SETTINGS` for NOTF-07 denial path | Already in pubspec |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| **`flutter_local_notifications`** | NOT NEEDED | Was a candidate in CLAUDE.md tech stack, but adds 100+ KB and Phase 5 uses **hand-rolled `AlarmManager` + native `NotificationManager`** via Pigeon | The Pigeon `NotificationApi` is the agreed pattern (CONTEXT carry-forward from Phase 4 — Kotlin-typed channels, no MethodChannel). flutter_local_notifications uses its own MethodChannel layer that bypasses our Pigeon discipline and introduces an opaque dependency. |
| **`permission_handler`** | NOT NEEDED | Same rationale | `PermissionStatusApi` already exists; add `isPostNotificationsGranted()` + `requestPostNotifications()` methods to it. Consistent with how Usage Access + Accessibility + Battery Opt are wired. |
| **`timezone`** | NOT NEEDED for v1 | Was a peer of flutter_local_notifications | Without flutter_local_notifications we use plain `DateTime` (local timezone) + the `streakDayFor` 04:00 boundary helper that already exists. AlarmManager is scheduled with wall-clock `RTC_WAKEUP` and re-armed on every fire — DST handled naturally because we recompute `next 21:00` each time. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Pigeon `NotificationApi` hand-roll | `flutter_local_notifications ^21.0.0` | Would save ~150 lines of Kotlin. But introduces a maintained-by-third-party MethodChannel layer the project has deliberately avoided since Phase 1 (Pigeon-typed only). Adds 100+ KB. Loses the strict T-04 Phase-4 broadcast pattern. **Verdict: keep Pigeon hand-roll.** |
| `permission_handler ^12.0.1` for POST_NOTIFICATIONS | Extend `PermissionStatusApi` | Same rationale — permission_handler is a MethodChannel package; we already have a Pigeon-typed `PermissionStatusApi` covering Usage / Accessibility / Battery. Adding one more method (`isPostNotificationsGranted()`, `requestPostNotifications()`, `shouldShowRationale()`) costs <30 lines of Kotlin. **Verdict: extend the existing Pigeon API.** |
| `flutter_local_notifications zonedSchedule` (TZDateTime) | Pure `DateTime` + recompute on each fire | We don't need IANA timezone math; we re-arm the alarm on every fire and use `DateTime` wall-clock for "next 21:00." DST transitions resolve naturally because we never store a pre-computed wall-clock timestamp across multiple days. **Verdict: pure DateTime is sufficient.** |
| Polling for streak rollover via WorkManager periodic | Lazy-on-open (STRK-05 lock) | STATE.md key decision + STRK-05 + Phase 4 carry-forward: lazy is robust against Doze, reboots, offline. WorkManager periodic = fragile, 15-min minimum interval, throttled. **Verdict: locked lazy-on-open.** |

**Installation:** no new packages. All work is in:
- `pigeons/notification_api.dart` (extend signature)
- `pigeons/permission_status_api.dart` (add 3 methods)
- New Kotlin files: `ReminderScheduler.kt`, `ReminderAlarmReceiver.kt`, `BootReceiver.kt`, `NotificationApiImpl.kt`
- New Dart files: `daily_checkins_dao.dart`, `daily_streak_dao.dart`, `streak_rollover_service.dart`, `streak_keys.dart`, `/checkin` screen, streak badge widget, streak history section

**Version verification:** All current versions confirmed via `pubspec.yaml`. No upgrades required.

---

## 4. Streak Algorithm Pseudocode (Lazy Rollover)

### State carried in `shared_preferences`

```
streak_threshold_minutes : int (default 5)
reminder_hour_minute      : int (default 1260 = 21*60)
last_wall_clock_ms        : int (millis since epoch, last evaluation)
last_boot_monotonic_ns    : int (SystemClock.elapsedRealtimeNanos, last evaluation)
last_evaluated_streak_day : int (DateTime millis at local midnight, last fully-rolled day)
```

### Trigger points

1. `AppLifecycleState.resumed` (`HomeScreen` `WidgetsBindingObserver`, mirrors Phase 2 `HealthLifecycleObserver`)
2. Home cold-open (initial frame after onboarding redirect)
3. Idempotent — multiple calls in <60 s are no-ops (5-min soft-cache pattern mirroring Phase 3 D-12)

### Algorithm (pure-Dart, runs in `StreakRolloverService`)

```dart
Future<void> rollover() async {
  // 1. Read clocks
  final nowWallMs = DateTime.now().millisecondsSinceEpoch;
  final nowBootNs = await permissionStatusApi.bootMonotonicNanos(); // NEW Pigeon method
  final lastWallMs = prefs.getInt(StreakKeys.lastWallClockMs) ?? nowWallMs;
  final lastBootNs = prefs.getInt(StreakKeys.lastBootMonotonicNs) ?? nowBootNs;

  // 2. Clock-tamper detection (STRK-06)
  // If wall clock advanced significantly more (or less) than boot-monotonic
  // clock since last evaluation → user tampered. Threshold: 24h delta.
  final wallDelta = nowWallMs - lastWallMs;
  final bootDeltaMs = (nowBootNs - lastBootNs) ~/ 1000000;
  final divergenceMs = (wallDelta - bootDeltaMs).abs();
  final clockTampered = divergenceMs > Duration(hours: 24).inMilliseconds;

  // 3. Compute "today" (STRK-08 — 04:00 local boundary already in streakDayFor)
  final todayStreakDay = streakDayFor(DateTime.now()); // local midnight after 04:00 shift
  final lastEvaluatedDay = prefs.getInt(StreakKeys.lastEvaluatedStreakDay);

  // 4. If no rollover needed (same streak day as last evaluation), bail.
  if (lastEvaluatedDay != null && lastEvaluatedDay == todayStreakDay.millisecondsSinceEpoch) {
    // Within same streak day — refresh "today pending" rows only, no break detection.
    await _refreshPendingTodayRows(todayStreakDay);
    return;
  }

  // 5. Roll over every day between lastEvaluatedDay+1 ... todayStreakDay-1
  //    (i.e., for each completed day, compute its DailyStreak row if missing).
  final entries = await blockListDao.getAll();
  final threshold = prefs.getInt(StreakKeys.streakThresholdMinutes) ?? 5;

  DateTime cursor = lastEvaluatedDay != null
      ? DateTime.fromMillisecondsSinceEpoch(lastEvaluatedDay).add(const Duration(days: 1))
      : todayStreakDay.subtract(const Duration(days: 1));

  while (cursor.isBefore(todayStreakDay)) {
    for (final entry in entries) {
      // Skip days before entry creation
      if (cursor.isBefore(streakDayFor(entry.createdAt))) continue;

      // 5a. CLOCK TAMPER → status=2 incomplete-data, source=0 (no fake signal)
      if (clockTampered) {
        await dailyStreakDao.upsert(
          entryId: entry.id,
          day: cursor,
          status: 2,  // incomplete-data
          source: 0,
          usageMinutesObserved: 0,
          evaluatedAt: DateTime.now(),
        );
        continue;
      }

      // 5b. Gather observations
      final usageMinutes = await _usageMinutesForEntry(entry, cursor, threshold);
      final checkin = await dailyCheckinsDao.getFor(entry.id, cursor);
      final a11yWasOnForDay = await _a11yWasOnFor(cursor); // proxy: any pause_events row OR Build.FINGERPRINT unchanged

      // 5c. Compute (status, source) per the 2x2 matrix
      final (status, source) = _resolveDay(
        usageMinutes: usageMinutes,
        threshold: threshold,
        checkinAvoided: checkin?.avoided,
        a11yWasOn: a11yWasOnForDay,
      );

      await dailyStreakDao.upsert(
        entryId: entry.id,
        day: cursor,
        status: status,
        source: source,
        usageMinutesObserved: usageMinutes,
        evaluatedAt: DateTime.now(),
      );
    }
    // Use DateTime constructor, NOT add(Duration(days:1)) — DST safety (§10)
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  }

  // 6. Today's row gets status=3 pending
  for (final entry in entries) {
    await dailyStreakDao.upsertIfAbsent(
      entryId: entry.id,
      day: todayStreakDay,
      status: 3, // pending
      source: 0,
      usageMinutesObserved: 0,
      evaluatedAt: DateTime.now(),
    );
  }

  // 7. Persist new state
  await prefs.setInt(StreakKeys.lastWallClockMs, nowWallMs);
  await prefs.setInt(StreakKeys.lastBootMonotonicNs, nowBootNs);
  await prefs.setInt(StreakKeys.lastEvaluatedStreakDay, todayStreakDay.millisecondsSinceEpoch);
}

/// 2x2 matrix per D-07:
/// usage <= threshold AND checkin == yes        → (0 success, 0 system-confirmed)
/// usage <= threshold AND checkin == null AND a11yOn → (0 success, 0 system-confirmed)
/// usage <= threshold AND checkin == yes AND !a11yOn → (0 success, 1 self-reported)
/// usage <= threshold AND checkin == null AND !a11yOn → (2 incomplete-data, 0)
/// usage  > threshold (regardless of checkin)    → (1 broken, 0 system-confirmed)
/// checkin == no                                  → (1 broken, source = a11yOn ? 0 : 1)
(int status, int source) _resolveDay({
  required int usageMinutes,
  required int threshold,
  required bool? checkinAvoided,
  required bool a11yWasOn,
}) {
  // Broken by system data
  if (a11yWasOn && usageMinutes > threshold) {
    return (1, 0); // broken, system-confirmed
  }
  // Broken by self-report
  if (checkinAvoided == false) {
    return (1, a11yWasOn ? 0 : 1);
  }
  // Success branches
  if (checkinAvoided == true) {
    return (0, a11yWasOn ? 0 : 1);
  }
  // No check-in — fall back to system data if available
  if (a11yWasOn) {
    return (0, 0); // success, system-confirmed
  }
  // No system data AND no check-in → incomplete-data
  return (2, 0);
}

/// STRK-09 — only usage inside the schedule window counts.
/// Cross-midnight: window belongs to its START day's streak row.
Future<int> _usageMinutesForEntry(
  BlockListData entry,
  DateTime streakDayMidnight,
  int threshold,
) async {
  if (entry.packageName == null) return 0; // habit — no usage data
  final summary = await dailyUsageSummaryDao.getTodayFor(
    entry.packageName!,
    streakDayMidnight,
  );
  if (summary == null) return 0;

  // Always-on entry (no schedule) → all usage counts
  if (entry.scheduleStartMinutes == null) {
    return summary.foregroundSeconds ~/ 60;
  }

  // Scheduled — bucket the day's usage by window
  // v1 simplification: daily_usage_summary only holds *day totals*, not
  // minute-resolution events. For scheduled entries with cross-midnight
  // windows, the usage row belongs to the START-day streak row (D-08-domain).
  // Use the helper to decide whether the (entry, day) pair is in-window:
  // we anchor on the CURRENT moment relative to a window that starts on
  // streakDayMidnight — if it's a cross-midnight window starting that day,
  // we attribute ALL of the next 24h foreground seconds to this row.
  //
  // Same-day windows (start <= end): the day total is already the day total;
  // we attribute it to the start day's streak row.
  //
  // Both branches converge: streak row = start day; usage = day total from
  // daily_usage_summary keyed on start day. The helper is consulted only at
  // pause-time (Phase 4) — for the streak engine, day-anchoring is sufficient.
  return summary.foregroundSeconds ~/ 60;
}

/// Proxy: did the AccessibilityService have a chance to observe this day?
/// We use the heuristic "the service was enabled for the entire day."
/// Implementation: persist `a11y_enabled_since` in prefs every time the
/// service flips on; if `cursor` is fully inside [a11y_enabled_since, now]
/// → return true. Otherwise → false. This is conservative — any window
/// during which the user disabled a11y flags the day as "self-reported only."
Future<bool> _a11yWasOnFor(DateTime day) async { ... }
```

### DST + Timezone Correctness (STRK-08)

| Edge | Approach |
|---|---|
| **Spring forward (23h day)** | We never compare two `DateTime` instances via `add(Duration(days: 1))` for day-boundary math — instead use `DateTime(y, m, d + 1)` which navigates calendar days, not 24h windows. The `streakDayFor` helper already uses local-tz subtract-4h then strips to `DateTime(y, m, d)`. Spring-forward days will compute a `cursor` of May 5 → May 6 even though only 23 wall-clock hours elapsed. |
| **Fall back (25h day)** | Same constructor-based day math. The 25-hour day has the same `(y, m, d)` tuple; we run the rollover for that day once. |
| **Timezone change while traveling** | Streak day anchored to *current* device local time (PROJECT.md is silent on multi-tz support — we treat the device's current `TZDateTime.local` as the home timezone). If the user changes tz mid-day, the `cursor` shift to the next day might be off by ±1 day for one rollover. **Acceptable risk** — the alternative (asking user to pick a home tz) breaks calm/simple v1 UX. Document as `[ASSUMED]` and surface in Settings help text in v1.x. |
| **Clock tampered** | §4 step 2 detects, §4 step 5a writes `status=2 incomplete-data` for all affected days. |

[VERIFIED: `lib/domain/schedule/streak_day.dart` already implements the 04:00-shift + `DateTime(y, m, d)` strip]

[CITED: https://medium.com/pinch-nl/datetime-and-daylight-saving-time-in-dart-9c9468633b5d — DST in Dart, avoid `add(Duration)` for day-level math]

[CITED: https://csdcorp.com/blog/coding/dst-dart-and-datetime/ — unit-testing DST with mocked clocks]

---

## 5. AlarmManager Strategy

### Permissions (manifest already has these — [VERIFIED: AndroidManifest.xml])

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

Note: `USE_EXACT_ALARM` is **NOT** declared (CLAUDE.md tech stack note: "Reserved for alarm/calendar-class apps. Triggers store auditing"). Use `SCHEDULE_EXACT_ALARM` only — user-grantable, appropriate for a daily reminder.

### Pigeon `NotificationApi` body (Kotlin)

```kotlin
// android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApiImpl.kt
class NotificationApiImpl(private val context: Context) : NotificationApi {
    override fun scheduleDailyReminder(hour: Long, minute: Long, cb: (Result<Unit>) -> Unit) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = buildPendingIntent(context)  // ReminderAlarmReceiver, flags = FLAG_IMMUTABLE | FLAG_UPDATE_CURRENT
        val triggerAtMs = computeNextOccurrenceMs(hour.toInt(), minute.toInt())

        // Android 12+ requires canScheduleExactAlarms() check
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!am.canScheduleExactAlarms()) {
                // Surface as a Pigeon error; Dart side falls back to setAndAllowWhileIdle (inexact)
                // and shows the NOTF-07 banner with a deeper sub-message.
                cb(Result.failure(NotificationApiError("EXACT_ALARM_DENIED")))
                return
            }
        }

        am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)

        // Persist hour/minute for BootReceiver re-arm
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putLong("flutter.reminder_hour_minute", hour * 60 + minute)
            .apply()

        cb(Result.success(Unit))
    }

    override fun cancelDailyReminder(cb: (Result<Unit>) -> Unit) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(buildPendingIntent(context))
        cb(Result.success(Unit))
    }

    private fun computeNextOccurrenceMs(h: Int, m: Int): Long {
        val now = Calendar.getInstance()
        val target = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, h)
            set(Calendar.MINUTE, m)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (!target.after(now)) target.add(Calendar.DAY_OF_YEAR, 1)
        return target.timeInMillis
    }

    companion object {
        fun buildPendingIntent(ctx: Context): PendingIntent {
            val intent = Intent(ctx, ReminderAlarmReceiver::class.java).apply {
                `package` = ctx.packageName  // explicit, defence-in-depth
            }
            return PendingIntent.getBroadcast(
                ctx, REMINDER_REQUEST_CODE, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
        const val REMINDER_REQUEST_CODE = 5001  // Phase 5 — arbitrary, but stable
    }
}
```

### `ReminderAlarmReceiver` (fires the notification + re-arms)

```kotlin
class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // 1. Fire notification (channel "daily_checkin", IMPORTANCE_DEFAULT)
        showCheckinNotification(context)

        // 2. CRITICAL: re-arm for the NEXT day. setExactAndAllowWhileIdle is one-shot.
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val hm = prefs.getLong("flutter.reminder_hour_minute", 21 * 60).toInt()
        val h = hm / 60
        val m = hm % 60
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
            // User revoked exact-alarm permission since last schedule. Drop to inexact.
            am.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                computeNextOccurrenceMs(h, m),
                NotificationApiImpl.buildPendingIntent(context),
            )
        } else {
            am.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                computeNextOccurrenceMs(h, m),
                NotificationApiImpl.buildPendingIntent(context),
            )
        }
    }

    private fun showCheckinNotification(ctx: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID, "Daily check-in", NotificationManager.IMPORTANCE_DEFAULT,
        )
        val nm = ctx.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)

        // PendingIntent to open MainActivity with extra triggering /checkin deep-link
        val deepLinkIntent = Intent(ctx, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("deep_link_to", "/checkin")
        }
        val pi = PendingIntent.getActivity(
            ctx, 0, deepLinkIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val n = NotificationCompat.Builder(ctx, CHANNEL_ID)
            .setContentTitle("Daily check-in")
            .setContentText("How did today go?")
            .setSmallIcon(R.drawable.ic_notification)  // re-use launcher icon variant
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()
        nm.notify(REMINDER_NOTIFICATION_ID, n)
    }

    companion object {
        const val CHANNEL_ID = "daily_checkin"
        const val REMINDER_NOTIFICATION_ID = 5001
    }
}
```

### `BootReceiver` (NOTF-05 re-arm after reboot)

```kotlin
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val hm = prefs.getLong("flutter.reminder_hour_minute", 21 * 60).toInt()
        val h = hm / 60
        val m = hm % 60
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Same exact-or-inexact branch as ReminderAlarmReceiver.onReceive
        val triggerMs = computeNextOccurrenceMs(h, m)
        val pi = NotificationApiImpl.buildPendingIntent(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        } else {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        }
    }
}
```

### Manifest additions needed

```xml
<receiver android:name=".ReminderAlarmReceiver" android:exported="false" />
<receiver
    android:name=".BootReceiver"
    android:exported="true"
    android:enabled="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.LOCKED_BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

`MainActivity.onNewIntent` handles `deep_link_to == "/checkin"` extra and calls `flutterEngine.dartExecutor`'s `MethodChannel` (or use platform channel callback) to fire `context.go('/checkin')` Dart-side. Simpler alternative: write `pending_deep_link = "/checkin"` to `SharedPreferences` and have HomeScreen's `initState` check + clear it.

### Doze + OEM Behavior

| Vendor | Concern | Mitigation |
|---|---|---|
| **Stock Android (Pixel)** | Doze defers alarms unless `setExactAndAllowWhileIdle` | `setExactAndAllowWhileIdle` is the contract — fires within 5 min even in Doze [CITED: developer.android.com/develop/background-work/services/alarms]. NOTF-04 requirement satisfied. |
| **Xiaomi MIUI** | Aggressive battery saver kills receivers + drops alarms; ignores `setExactAndAllowWhileIdle` unless app is whitelisted | (1) Battery-opt exemption already in Phase 2 onboarding (ONBD-01 step 4) addresses most of this. (2) OemFallbackPanel from Phase 2 (REL-03) already routes user to "Autostart" + "Background activity" settings via dontkillmyapp.com slugs. (3) REL-05 overnight gate on real Xiaomi MUST verify reminder fires. |
| **Samsung One UI** | "Put unused apps to sleep" auto-sleep after 3+ days of inactivity | Phase 4 REL-04 PASSED on Samsung S20 Ultra (Android 13, One UI 5.1) after ≥71h Doze. Streak engine is **lazy-on-open** — only the reminder + BOOT_COMPLETED need to survive overnight idle. Battery-opt exemption suffices on Samsung. |
| **OPPO/Vivo ColorOS** | Notification importance throttled; receivers killed | dontkillmyapp.com flow + IMPORTANCE_DEFAULT channel + exact alarm. v1 ships baseline; if REL-05 fails, escalate. |

[CITED: https://developer.android.com/about/versions/14/changes/schedule-exact-alarms — Android 14 SCHEDULE_EXACT_ALARM denied-by-default behavior]

[CITED: https://developer.android.com/develop/background-work/services/alarms — `canScheduleExactAlarms()` check is required]

[VERIFIED: `targetSdk 36` (Android 16) per pubspec.yaml/CLAUDE.md — must handle Android 14 denied-by-default exact-alarm policy]

---

## 6. POST_NOTIFICATIONS Earned-Prompt Flow

### Trigger

- After the user successfully inserts their **first** `BlockList` entry (LIST-01 or LIST-02 path), check `POST_NOTIFICATIONS` status.
- Wire location: hook into `BlockListRepository.insertEntry` post-write OR add a Riverpod listener on `blockListWatcher` that fires when `count` transitions 0 → 1.
- Save a "seen earned prompt" flag in `SharedPreferences` (`StreakKeys.earnedPromptShown = true`) so we only fire once per install.

### Pigeon API additions (extend `PermissionStatusApi`)

```dart
// pigeons/permission_status_api.dart — additions
@async
bool isPostNotificationsGranted();

@async
String postNotificationsRationaleState(); // returns "grantable" | "rationale" | "permanently_denied"

@async
bool requestPostNotifications(); // launches system dialog, returns post-result granted state

@async
int bootMonotonicNanos(); // SystemClock.elapsedRealtimeNanos() for STRK-06 clock-tamper
```

Kotlin side uses:
- `ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS)` for `isPostNotificationsGranted`
- `activity.shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)` for state resolution
- `ActivityCompat.requestPermissions(activity, ...)` for the actual request (must be hosted in `MainActivity`, not the impl class — pass `Activity` ref or use `ActivityResultContracts.RequestPermission`)

[CITED: https://developer.android.com/develop/ui/views/notifications/notification-permission — shouldShowRequestPermissionRationale returns false BEFORE the first request and AFTER permanent denial; true only between first dismiss and permanent denial]

### Three-state UX

| State | Returned by | UI Action |
|---|---|---|
| `grantable` | First-time request OR rationale screen not yet shown | Show in-app rationale screen → user taps "Continue" → system dialog (`requestPostNotifications`) |
| `rationale` | User dismissed once but didn't pick "Don't allow again" | Show rationale with stronger framing ("Reminders help your streak stay honest") → system dialog re-prompt |
| `permanently_denied` | User picked "Don't allow" or "Don't ask again" — `shouldShowRequestPermissionRationale` returns false AFTER first deny | NOTF-07 banner only path forward: deep-link to `ACTION_APP_NOTIFICATION_SETTINGS` |

### Rationale screen contract

- Reuse Phase 2 `RationaleScreen` shell pattern (ONBD-02 carry-forward).
- Body copy: `"Get a daily reminder to confirm your not-to-do list. Without notifications, you'll need to open the app to record each day."`
- Single CTA: `"Continue"` (no skip — user can dismiss the system dialog).
- Route: `/onboarding/permissions/notifications` OR an ad-hoc dialog launched post-first-entry. Decision deferred to planner; CONTEXT D-12 implies "in-app rationale + requestPermissions re-prompt screen" — suggests a route.

### NOTF-07 banner-tap behavior (D-12 lock)

```dart
Future<void> _onReminderBannerTap() async {
  final state = await permissionStatusApi.postNotificationsRationaleState();
  if (state == 'permanently_denied') {
    // Deep-link to system settings — only path forward
    await url_launcher.launchUrl(
      Uri.parse('app-settings:notification?package=com.nottodo.not_to_do_list'),
    );
    // OR: use a new Pigeon method openAppNotificationSettings()
  } else {
    // Re-prompt in-app
    context.go('/onboarding/permissions/notifications');
  }
}
```

---

## 7. Daily Check-In Flow (`/checkin`)

### Route addition

```dart
// lib/core/router/app_router.dart
GoRoute(path: '/checkin', builder: (_, __) => const CheckinScreen()),
```

### Riverpod providers

```dart
// lib/features/checkin/providers/checkin_providers.dart
final pendingCheckinsTodayProvider = FutureProvider<List<BlockListData>>((ref) async {
  final entries = await ref.read(blockListRepoProvider).getAll();
  final today = streakDayFor(DateTime.now());
  final dao = ref.read(dailyCheckinsDaoProvider);
  final pending = <BlockListData>[];
  for (final e in entries) {
    if (await dao.getFor(e.id, today) == null) pending.add(e);
  }
  return pending;
});

final checkinAnswersProvider = StateProvider<Map<int, bool>>((_) => {});
```

### Submit handler (D-03 single Drift transaction)

```dart
Future<void> _submit(WidgetRef ref) async {
  final answers = ref.read(checkinAnswersProvider);
  final today = streakDayFor(DateTime.now());
  final now = DateTime.now();
  await ref.read(appDatabaseProvider).transaction(() async {
    final dao = ref.read(dailyCheckinsDaoProvider);
    for (final entry in answers.entries) {
      await dao.upsert(
        entryId: entry.key,
        day: today,
        avoided: entry.value,
        answeredAt: now,
      );
    }
  });
  // Re-trigger streak rollover so the badge updates immediately
  await ref.read(streakRolloverServiceProvider).rollover();
  if (context.mounted) context.go('/');
}
```

### Idempotency (UI-SPEC.md screen 1)

- Already-answered entries appear in the list but with the `SegmentedButton` disabled and showing the stored answer.
- Submit button label flips to `"All done"` (UI-SPEC copy lock) when all entries are pre-answered.

### Scheduled-entry window logic (STRK-09)

- A scheduled entry shows up in `/checkin` ONLY if today's streak day falls inside the schedule's weekday mask. Out-of-mask days → not pending (the entry was "dormant" that day — no streak row needed).
- Implementation: filter `entries` by `isInScheduleWindow(now: streakDay.add(start - 1 minute), ...)` returning true for the start-day weekday bit.

---

## 8. UI/UX Hooks (per UI-SPEC.md — Engine surface)

### Streak engine must surface (Riverpod providers)

| Provider | Returns | Consumed By |
|---|---|---|
| `streakBadgeProvider(entryId)` | `StreakBadgeData(current: int, longest: int, breakDetectedToday: bool)` | Home `BlockListRow` trailing slot |
| `streakHistoryProvider(entryId, days: 30)` | `List<DailyStreakData>` ordered by day asc | Entry detail Streak history GridView |
| `pendingCheckinsTodayProvider` | `List<BlockListData>` | `/checkin` body + Home cold-open trigger |
| `reminderTimeProvider` | `int` (hour * 60 + minute) | Settings picker subtitle |
| `postNotificationsGrantedProvider` | `bool` | NOTF-07 banner visibility |

### Format strings (UI-SPEC copy lock — DO NOT paraphrase)

| Element | Exact Copy |
|---|---|
| Streak badge | `"🔥 {current} · best {longest}"` |
| Streak badge day-0 | `"🔥 0 · best 0"` |
| Streak history section label | `"Streak history"` |
| Streak summary text | `"{N} days · best {M}"` |
| Streak threshold help | `"Streak breaks if you use this app over 5 min/day (change in Settings)"` |
| Reminder settings label | `"Daily reminder"` |
| NOTF-07 banner | `"Reminder is off — tap to fix"` |
| Notification title | `"Daily check-in"` |
| Notification body | `"How did today go?"` |
| Grey dot tooltip | `"Tracking was off this day"` |
| Settings streak help | `"Each day is a fresh start"` |
| Check-in heading | `"How did today go?"` |
| Submit button | `"Save check-in"` (or `"All done"` when fully answered) |
| Empty check-in heading | `"You're all caught up"` |
| Empty check-in body | `"Check back tomorrow."` |
| Check-in error | `"Something went wrong — your check-in wasn't saved. Try again."` |

### Day-dot rendering (UI-SPEC color section)

| State | Light | Dark | Shape |
|---|---|---|---|
| green ✓ | `Color(0xFF2E7D32)` | `Color(0xFF66BB6A)` | filled circle 8px |
| blue ○ | `Color(0xFF1565C0)` | `Color(0xFF64B5F6)` | outlined 1.5px |
| red × | `Color(0xFFC62828)` | `Color(0xFFEF9A9A)` | filled + × overlay |
| grey — | `Color(0xFF757575)` | `Color(0xFF9E9E9E)` | outlined + — overlay + `Tooltip` |
| today (pending) | — | — | no dot; date number only |
| empty (before creation) | — | — | empty `SizedBox(24,24)` |

### Banner amber tokens (NOTF-07, reuse Phase 3)

| | Light | Dark |
|---|---|---|
| Background | `Color(0xFFFFF3CD)` | `Color(0xFF3D2E00)` |
| Foreground | `Color(0xFF856404)` | `Color(0xFFFFD966)` |

### Accessibility (UI-SPEC §A11Y)

- 4 day-states have `Semantics(label: ...)` wrappers.
- Touch targets ≥ 44×44 dp on Yes/No toggles, dot cells, banner.
- Streak badge text is read directly by screen readers — no extra label.

---

## 9. Validation Architecture

> Required by `workflow.nyquist_validation: true` in `.planning/config.json` [VERIFIED].

### Test Framework

| Property | Value |
|---|---|
| Framework | `flutter_test` (Flutter 3.41 / Dart 3.5) + `mocktail ^1.0.5`; Kotlin side: JUnit 4.13.2 via `./gradlew :app:test` |
| Config file | `pubspec.yaml` (dev_dependencies); `analysis_options.yaml` (`very_good_analysis ^10.2.0`); `android/app/build.gradle.kts` (testImplementation JUnit 4) |
| Quick run command | `flutter test test/policy/play_invariants_test.dart test/features/streak/ test/features/checkin/ test/features/reminder/ test/data/dao/daily_streak_dao_test.dart test/data/dao/daily_checkins_dao_test.dart test/domain/streak/streak_rollover_service_test.dart` |
| Full suite command | `flutter test` + `cd android && ./gradlew :app:testDebugUnitTest` |
| Estimated runtime | ~20 s (Phase 5 surface) / ~140 s (full Dart suite) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| **STRK-01** | per-item streak counter | unit (DAO) | `flutter test test/data/dao/daily_streak_dao_test.dart` | ❌ Wave 0 |
| **STRK-02** | auto-break at 5 min/day threshold | unit (service) | `flutter test test/domain/streak/streak_rollover_service_test.dart::test_breaks_when_usage_exceeds_threshold` | ❌ Wave 0 |
| **STRK-03** | one check-in per entry per day (UNIQUE) | unit (DAO) | `flutter test test/data/dao/daily_checkins_dao_test.dart::test_upsert_idempotent_per_entry_per_day` | ❌ Wave 0 |
| **STRK-04** | system-confirmed vs self-reported-only labels | unit (service) | `flutter test test/domain/streak/streak_rollover_service_test.dart::test_source_resolution_matrix` | ❌ Wave 0 |
| **STRK-05** | lazy on app open, no scheduled job | unit (policy absence-grep) | `flutter test test/policy/phase_5_invariants_test.dart::test_no_workmanager_periodic_for_streak` | ❌ Wave 0 |
| **STRK-06** | clock-tamper > 24 h → incomplete-data | unit (service) | `flutter test test/domain/streak/streak_rollover_service_test.dart::test_clock_tamper_flags_status_2` | ❌ Wave 0 |
| **STRK-07** | home shows current + longest streak | widget | `flutter test test/features/home/widgets/streak_badge_test.dart` | ❌ Wave 0 |
| **STRK-08** | DST 23h + 25h day correctness | unit (service) | `flutter test test/domain/streak/streak_rollover_dst_test.dart::test_spring_forward_23h_day test_fall_back_25h_day` | ❌ Wave 0 |
| **STRK-09** | scheduled entries — only in-window usage counts | unit (service) | `flutter test test/domain/streak/streak_rollover_service_test.dart::test_scheduled_window_anchoring` | ❌ Wave 0 |
| **STRK-09 (parity)** | Kotlin parity for streak day-anchoring | unit (JVM) | `cd android && ./gradlew :app:testDebugUnitTest --tests "*.StreakDayAnchoringTest"` | ❌ Wave 0 (parity helper exists from Phase 4) |
| **NOTF-01** | 24h time picker in Settings | widget | `flutter test test/features/reminder/reminder_settings_test.dart::test_time_picker_persists_to_prefs` | ❌ Wave 0 |
| **NOTF-02** | reminder fires at chosen time | manual (instrumented or manual) | logcat dump + adb time-mock OR real-device wait | ❌ Wave 0 — manual-only per nature |
| **NOTF-03** | tap deep-links to `/checkin` | widget + Pigeon mock | `flutter test test/features/reminder/deep_link_navigation_test.dart::test_pending_deep_link_routes_to_checkin` | ❌ Wave 0 |
| **NOTF-04** | fires within 5 min even under Doze | manual (real device) | `adb shell dumpsys deviceidle force-idle` + wait + observe | ❌ Wave 0 — manual-only |
| **NOTF-05** | `BOOT_COMPLETED` re-arm | unit (policy + manual) | `flutter test test/policy/phase_5_invariants_test.dart::test_boot_receiver_declared` + manual reboot test | ❌ Wave 0 |
| **NOTF-06** | earned prompt after first entry | widget | `flutter test test/features/onboarding/post_notifications_earned_test.dart::test_prompt_fires_on_first_insert` | ❌ Wave 0 |
| **NOTF-07** | denied → in-app banner | widget | `flutter test test/features/home/reminder_off_banner_test.dart::test_banner_visible_when_denied test_banner_hidden_when_granted` | ❌ Wave 0 |
| **REL-05** | overnight OEM survival | manual (real Xiaomi or Samsung) | `.planning/phases/05-streak-engine-daily-reminder/05-VERIFICATION.md` REL-05 protocol | ❌ Wave 0 — manual-only |
| **Policy invariants (cross-tree)** | no FCM, no Firebase, no WorkManager periodic for streak, BootReceiver exported correctly, no `USE_EXACT_ALARM` | unit (policy absence-grep) | `flutter test test/policy/play_invariants_test.dart test/policy/phase_5_invariants_test.dart` | ❌ Wave 0 — extend existing |

### Sampling Rate

- **Per task commit:** `flutter test test/policy/ test/features/streak/ test/features/checkin/ test/features/reminder/ test/domain/streak/ test/data/dao/daily_streak_dao_test.dart test/data/dao/daily_checkins_dao_test.dart` (< 30 s)
- **Per wave merge:** `flutter test` + `cd android && ./gradlew :app:testDebugUnitTest` (< 140 s)
- **Phase gate (REL-05):** Full suite green + REL-05 protocol PASS on Xiaomi or Samsung before `/gsd-verify-work`.

### Wave 0 Gaps (all must be created in Plan 05-01)

- [ ] `test/data/dao/daily_streak_dao_test.dart` — covers STRK-01, upsert idempotency
- [ ] `test/data/dao/daily_checkins_dao_test.dart` — covers STRK-03, upsert idempotency
- [ ] `test/domain/streak/streak_rollover_service_test.dart` — covers STRK-02, STRK-04, STRK-06, STRK-09 (the 2x2 matrix from §4)
- [ ] `test/domain/streak/streak_rollover_dst_test.dart` — covers STRK-08 (23h + 25h days with mocked DateTime)
- [ ] `test/features/streak/streak_badge_test.dart` — covers STRK-07 + D-15 day-0 rendering + D-05 strikethrough
- [ ] `test/features/streak/streak_history_section_test.dart` — covers D-07 4 dot states + grey tooltip mandatory
- [ ] `test/features/checkin/checkin_screen_test.dart` — covers D-02 + D-03 (single submit) + idempotency (D-01)
- [ ] `test/features/reminder/reminder_settings_test.dart` — covers NOTF-01 time picker
- [ ] `test/features/reminder/deep_link_navigation_test.dart` — covers NOTF-03
- [ ] `test/features/onboarding/post_notifications_earned_test.dart` — covers NOTF-06
- [ ] `test/features/home/reminder_off_banner_test.dart` — covers NOTF-07
- [ ] `test/policy/phase_5_invariants_test.dart` — absence-grep for FCM, Firebase, WorkManager-periodic-for-streak, BootReceiver manifest declaration, no `USE_EXACT_ALARM`
- [ ] `test/_fixtures/streak_fixture.dart` — shared mock `(usageMinutes, checkin, a11yWasOn) → (status, source)` tuples for the 2x2 matrix
- [ ] `android/app/src/test/.../StreakDayAnchoringTest.kt` — Kotlin parity for cross-midnight day-anchoring (mirrors Phase 4 ScheduleWindowTest.kt)
- [ ] `.planning/phases/05-streak-engine-daily-reminder/05-VERIFICATION.md` — REL-05 overnight gate protocol (mirror Phase 4 REL-04 9-step procedure for Xiaomi or Samsung)

---

## 10. Risks & Landmines

### R-1: Clock tamper false positives during DST (HIGH)
**What goes wrong:** Spring-forward day = 23 wall-clock hours, but `SystemClock.elapsedRealtimeNanos()` measures real elapsed time. A 23h wall-delta vs 24h boot-delta = 1h divergence — well under the 24h threshold, so no false positive. **Safe.**
**Confirmation:** [CITED: https://medium.com/pinch-nl/datetime-and-daylight-saving-time-in-dart-9c9468633b5d] — `DateTime.now().millisecondsSinceEpoch` is UTC-anchored, so DST doesn't shift the wall delta. The 24h threshold is robust.

### R-2: AlarmManager `setExactAndAllowWhileIdle` permission revoked mid-flight (MEDIUM)
**What goes wrong:** User grants `SCHEDULE_EXACT_ALARM` at first prompt, then revokes in Settings. On next `BOOT_COMPLETED` or alarm fire, `canScheduleExactAlarms()` returns false → if we don't check, we crash with `SecurityException`.
**Mitigation:** Both `ReminderAlarmReceiver.onReceive` AND `BootReceiver.onReceive` check `canScheduleExactAlarms()` before re-arm; fall back to `setAndAllowWhileIdle` (inexact). Pigeon API surface returns a tagged error `"EXACT_ALARM_DENIED"` that the Dart side maps to a NOTF-07 banner sub-message.
[CITED: https://developer.android.com/develop/background-work/services/alarms]

### R-3: OEM kills `BootReceiver` before it fires (HIGH on Xiaomi/Huawei)
**What goes wrong:** Xiaomi/Huawei/OPPO ship "Autostart" disabled by default — `BOOT_COMPLETED` receivers don't fire on these devices unless user enables Autostart in Settings.
**Mitigation:** (1) battery-opt exemption from Phase 2 helps but doesn't cover Autostart. (2) OEM Fallback Panel from Phase 2 (`OemFallbackPanel` keyed on `Build.MANUFACTURER`) routes user to dontkillmyapp.com for the right vendor instructions. (3) Add a Phase 5 health check: on app open after a reboot detection (compare `SystemClock.elapsedRealtimeNanos()` vs persisted `last_boot_nanos`), verify the alarm is still pending via `canScheduleExactAlarms()` + a Dart-side "scheduled" flag, and re-arm if missing.

### R-4: WorkManager creep — someone schedules a periodic job for streak (HIGH if regressed)
**What goes wrong:** A future plan/developer adds `WorkManager.enqueue(PeriodicWorkRequest)` for streak rollover, violating STRK-05 lock.
**Mitigation:** Add `test/policy/phase_5_invariants_test.dart` absence-grep for `PeriodicWorkRequest`, `WorkManager.enqueueUniquePeriodicWork`, and any class named `*StreakRollover*Worker*`. Mirror Phase 4's `phase_4_invariants_test.dart` pattern.

### R-5: `POST_NOTIFICATIONS` permanently denied path breaks reminder forever (MEDIUM)
**What goes wrong:** User picks "Don't allow" on first prompt. `shouldShowRequestPermissionRationale` returns false forever. App cannot ever re-prompt.
**Mitigation:** NOTF-07 banner deep-links to `Settings.ACTION_APP_NOTIFICATION_SETTINGS`. Banner re-evaluates on `AppLifecycleState.resumed` — when user grants in Settings, banner disappears on next app open. **No retry-prompt logic needed** — system handles it. [CITED: https://developer.android.com/develop/ui/views/notifications/notification-permission]

### R-6: `BootReceiver` does not run if app is in "stopped" state (KitKat+) (MEDIUM)
**What goes wrong:** On fresh install, until the user manually launches the app at least once, `BOOT_COMPLETED` won't trigger our receiver (Android stopped-state policy).
**Mitigation:** Acceptable — user must complete onboarding before any reminder is even scheduled (the first reminder schedule happens after they accept POST_NOTIFICATIONS, which requires opening the app). Document in REL-05 protocol: test scenario is "reminder set → reboot → reminder still fires," which assumes app was already launched.

### R-7: Streak engine OOM or slow on entries × days = O(N × 30+) (LOW)
**What goes wrong:** User has 20 entries × 30 unprocessed days = 600 streak rows to compute on first open after a month of disuse.
**Mitigation:** Streak rollover only processes days BETWEEN `lastEvaluatedStreakDay` and today (capped — see §4 step 5). Cap at 30 days backstop: if `lastEvaluatedDay < today - 30`, skip backfill and write `status=2 incomplete-data` for the gap. Use Drift batch insert.

### R-8: `daily_usage_summary` is keyed on `packageName`, not `entryId` — habit entries (no packageName) have no usage rows (LOW)
**What goes wrong:** Habit entries (`kind=1`, `packageName=null`) can never have `daily_usage_summary` rows. Streak engine attempting to look them up by packageName will get null.
**Mitigation:** §4 `_usageMinutesForEntry` guards with `if (entry.packageName == null) return 0`. Habit streaks are 100% self-report (source=1 if check-in present, status=2 if no check-in).

### R-9: BootReceiver reads `SharedPreferences` with `FlutterSharedPreferences` file (MEDIUM)
**What goes wrong:** Flutter's `shared_preferences` package stores keys with a `flutter.` prefix in a file named `FlutterSharedPreferences`. Native receivers reading this file must use the exact filename + prefix.
**Mitigation:** Use `context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)` and key `"flutter.reminder_hour_minute"`. **Verify on real device** because shared_preferences 2.x may have changed the storage backend (DataStore migration is in flight). [ASSUMED] — verify behavior in Plan 05-01 Wave 0 by writing a key from Dart, reading from Kotlin in a test.

### R-10: REL-05 OEM-survival flake on Xiaomi (HIGH if Phase 4 Samsung-only proves insufficient)
**What goes wrong:** Phase 4 REL-04 PASSED on Samsung only (S20 Ultra 5G, Android 13, OneUI 5.1). Xiaomi MIUI is known to be more aggressive than One UI for both alarm and receiver kills.
**Mitigation:** CONTEXT exit gate language says "Xiaomi OR Samsung" — Samsung sufficient. Plan 05-08 should document Xiaomi as a stretch goal; if Samsung passes overnight, REL-05 closes.

---

## 11. Implementation Order Recommendation (subsystem-first, parallel-where-safe)

### Wave 0 — Test scaffold (must be RED) + verification template

1. **Plan 05-01** — 14 RED test files + Kotlin parity stub + REL-05 protocol template (`05-VERIFICATION.md`). Pattern-match Plan 04-01 exactly. **Outputs:** all test files in §9 Wave 0 Gaps list. Estimated 1 task, ~25 min.

### Wave 1 — Pure-Dart foundation (no platform deps)

2. **Plan 05-02** — `StreakKeys` constants + `DailyCheckinsDao` + `DailyStreakDao` + their `.g.dart`. Bump nothing in schema. Drift codegen via `dart run build_runner build`. **Outputs:** `lib/data/database/daos/daily_checkins_dao.dart`, `lib/data/database/daos/daily_streak_dao.dart`, register in `app_database.dart`. ~30 min.

3. **Plan 05-03** — `StreakRolloverService` (pure-Dart, takes injected DAOs + clock provider + `PermissionStatusApi`). 2x2 status/source matrix + DST helpers + 30-day backfill cap. **Outputs:** `lib/domain/streak/streak_rollover_service.dart` + provider + `streak_keys.dart`. ~45 min.

### Wave 2 — Platform body (Pigeon + Kotlin)

4. **Plan 05-04** — Extend `PermissionStatusApi.dart` with `isPostNotificationsGranted`, `postNotificationsRationaleState`, `requestPostNotifications`, `bootMonotonicNanos`. Regenerate Pigeon. Implement in `PermissionStatusApiImpl.kt`. Update `MainActivity.configureFlutterEngine`. ~30 min.

5. **Plan 05-05** — `NotificationApiImpl.kt` (real body) + `ReminderAlarmReceiver.kt` + `BootReceiver.kt`. Manifest additions for both receivers. Channel registration on app start. Test via Kotlin unit tests (parity for `computeNextOccurrenceMs` 24-h-wrap behaviour) + manual instrumented for alarm fire. ~60 min.

### Wave 3 — UI surfaces (parallel-safe within wave)

6. **Plan 05-06** — `/checkin` route + `CheckinScreen` + providers. Single Drift transaction submit. Idempotent already-answered handling. ~45 min.

7. **Plan 05-07** — Home `BlockListRow` streak badge (D-13..15) + entry detail Streak history section (D-16) + reminder-off banner (D-12 / NOTF-07). Parallel-safe with 05-06. ~60 min.

8. **Plan 05-08** — Settings reminder time picker (NOTF-01) + earned POST_NOTIFICATIONS rationale screen (NOTF-06) + wire post-first-entry trigger. ~45 min.

### Wave 4 — Phase exit gate

9. **Plan 05-09** — Final phase-exit gate: extend `play_invariants_test.dart` with Phase 5 invariants (no FCM, no WorkManager periodic for streak, no `USE_EXACT_ALARM`, BootReceiver `exported="true"` + intent-filter present). Execute REL-05 overnight protocol on Samsung S20 Ultra (or Xiaomi if available). Update bookkeeping (`REQUIREMENTS.md` STRK-01..09 + NOTF-01..07 → Complete; `STATE.md` completed_phases → 5). ~30 min + overnight wait.

### Critical Path

- Wave 0 → Wave 1 → Wave 2 → Wave 3 → Wave 4 is the strict ordering.
- Within Wave 1: Plan 05-02 must complete before 05-03 (service depends on DAOs).
- Within Wave 3: 05-06, 05-07, 05-08 are **parallel-safe** (different routes/widgets).
- REL-05 overnight is the long-tail blocker — kick off as early as Wave 2 complete if possible.

---

## 12. Project Constraints (from CLAUDE.md)

| Directive | Compliance Path |
|---|---|
| Android-only, Flutter | All work in `lib/` (Dart) + `android/app/src/main/kotlin/...` |
| No backend in v1 | No FCM, no Supabase. Pure on-device. **Absence-grep test.** |
| 100% on-device privacy | No telemetry. No analytics SDK. Notification body must NOT contain entry names (privacy — D-10 lock). |
| Free / OSS only | All proposed deps are MIT/BSD/Apache. No paid APIs. |
| Pigeon-typed channels for all Dart↔Kotlin | Extend existing `NotificationApi` and `PermissionStatusApi`. No new MethodChannel. |
| AlarmManager for user-perceived precise time | `setExactAndAllowWhileIdle` per NOTF-04 |
| WorkManager Doze-tolerant rollover | **NOT for streak** (STRK-05). Could appear in v1.x for non-time-critical bg jobs. |
| `isAccessibilityTool="false"` | No change in Phase 5; Phase 4 service config unchanged. |
| Streak roll-over lazy on app open | STRK-05 + §4 algorithm |
| AccessibilityService swappable behind Riverpod abstraction | No change. Streak engine reads `pause_events` + `daily_usage_summary`, not the service. |
| Earned `POST_NOTIFICATIONS` prompt | NOTF-06 + §6 |
| `flutter test`, `mocktail`, `very_good_analysis` | All test files use these. No code-gen for Riverpod (per pubspec.yaml notes). |
| `test/policy/play_invariants_test.dart` invariants must not regress | Extend with Phase 5 absence-greps; do not weaken existing 9 PLAY-02 + foundation invariants. |
| GSD Workflow Enforcement | All file edits in Phase 5 must go through `/gsd-plan-phase 5` → `/gsd-execute-phase 5` |

---

## 13. Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Flutter's `shared_preferences` plugin still uses file `FlutterSharedPreferences` with key prefix `flutter.` for Kotlin-side reads from `BootReceiver` | §5, §10 R-9 | BootReceiver reads wrong file → no re-arm → REL-05 fails. **Mitigation:** Wave 0 includes a "read Kotlin-side, write Dart-side" parity test. |
| A2 | Multi-timezone travel: streak day anchored to *current* device local tz (not a persisted "home tz") | §4 DST table | One-day drift on tz change; acceptable per CONTEXT silent on multi-tz. Surface in v1.x. |
| A3 | `Build.FINGERPRINT` change OR Accessibility off proxy → `a11yWasOn=false` for day | §4 `_a11yWasOnFor` | Edge case — user enabled a11y mid-day. Current heuristic flags whole day as self-reported. Acceptable per "honest streak" framing. |
| A4 | Xiaomi MIUI Autostart not auto-enabled — user must follow OemFallbackPanel flow for `BootReceiver` to fire | §10 R-3 | If Xiaomi user skips Autostart prompt, reminders stop after first reboot. Mitigated by health-check + banner; REL-05 will surface if widespread. |
| A5 | `daily_usage_summary` day-granular only; minute-resolution events not stored. Scheduled entries with sub-day windows attribute full-day total to start-day streak row. | §4 `_usageMinutesForEntry` | Slightly over-attributes usage on cross-midnight schedules. Acceptable for v1 — exact minute bucketing deferred to v1.x (DIFF-05 time-of-day breakdown). |
| A6 | `ReminderAlarmReceiver` runs in app process — can call `NotificationManagerCompat` without launching a FlutterEngine | §5 | Standard Android pattern — BroadcastReceivers can post notifications without an activity context. **Verified by Android docs** [CITED: developer.android.com]. |
| A7 | `targetSdk 36` (Android 16) implies same exact-alarm policy as Android 14 (denied by default, `canScheduleExactAlarms()` check required) | §5 | Verified through Android 14 docs; Android 16 has not loosened the policy. Confirm via Plan 05-05 build/run on Android 16 emulator. |

---

## 14. Open Questions

1. **`SharedPreferences` cross-process Kotlin/Dart key compatibility**
   - What we know: Flutter's `shared_preferences` plugin stores with file `FlutterSharedPreferences` and `flutter.` key prefix (default backend).
   - What's unclear: Whether the active package version uses DataStore backend (which is NOT readable by classic `SharedPreferences` calls).
   - Recommendation: Wave 0 includes a Kotlin↔Dart parity test that writes from Dart and reads from Kotlin.

2. **Where the reminder time picker lives in Phase 5 scope**
   - What we know: CONTEXT D-09 says "Settings under a 'Streak & Reminder' section" but Phase 6 owns the Settings screen.
   - What's unclear: Should Phase 5 ship a minimal `/settings/reminder` route as a stand-in, or expose the picker via a `ListTile` in a temporary location (e.g., the AppBar overflow menu on Home)?
   - Recommendation: Plan 05-08 ships a minimal `/settings/reminder` route accessible via an AppBar action on Home. Phase 6 reorganizes into a proper Settings screen.

3. **Sort order on Home when streak data lands**
   - What we know: Phase 2 sorts by `block_list.updatedAt desc`. CONTEXT.md Phase 2 mentions Phase 4/5 will "join last activity desc."
   - What's unclear: Should Phase 5 introduce a join on `MAX(pause_events.triggered_at, daily_checkins.answered_at)` for "recent activity" sort?
   - Recommendation: Defer to Plan 05-07. Default to `updatedAt desc` if no time pressure. Discuss as a sub-decision during planning.

4. **Notification channel deletion on settings change**
   - What we know: A `NotificationChannel` is created on app start with `IMPORTANCE_DEFAULT`.
   - What's unclear: If the user later changes channel importance in system settings, do we honor that or recreate?
   - Recommendation: Android caches user changes — we never recreate or override. Behavior matches platform contract.

---

## 15. Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Flutter SDK | All Dart work | ✓ | 3.41.x (pubspec.yaml) | — |
| Drift codegen (`build_runner`) | DAO codegen | ✓ | 2.4.0 dev-dep | — |
| Pigeon codegen | API extensions | ✓ | 26.3.4 dev-dep | — |
| Android Gradle Plugin + Kotlin | Native receivers + impl | ✓ | AGP 8.11.1+ (Flutter 3.41 standard) | — |
| Real Samsung device | REL-05 overnight gate | ✓ | Samsung Galaxy S20 Ultra 5G (proven Phase 4) | Xiaomi (acceptable per CONTEXT) |
| Real Xiaomi device | REL-05 stretch | ? | unknown availability | Samsung alone is sufficient |
| `adb shell dumpsys deviceidle force-idle` | NOTF-04 manual verification | ✓ | adb available | Manual long-wait fallback |
| Android 14 emulator | Phase 5 dev gate (POST_NOTIFICATIONS + exact-alarm-denied-by-default) | ✓ | AVD available | Real device |
| Android 16 emulator | Phase 5 final gate (targetSdk 36) | ✓ | AVD available | Skip; Android 14 covers most policy changes |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** Xiaomi device (use Samsung-only for REL-05, per CONTEXT "Xiaomi or Samsung").

---

## 16. Security Domain

> Required because `security_enforcement` is enabled by default (config silent → enabled).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No accounts in v1 |
| V3 Session Management | no | No sessions in v1 |
| V4 Access Control | yes | Receivers `exported="false"` except `BootReceiver` (must be `exported="true"` to receive `BOOT_COMPLETED`); `Intent.setPackage(ctx.packageName)` defence-in-depth on PendingIntents |
| V5 Input Validation | yes | Pigeon-generated DTOs already type-check; explicit fail-closed in `MainActivity.onNewIntent` for `deep_link_to` extra (only `"/checkin"` accepted) |
| V6 Cryptography | no | No crypto in Phase 5 |
| V8 Data Protection | yes | Notification body MUST NOT contain entry names (D-10 lock) — already covered |
| V9 Communications | no | No network calls in Phase 5 |
| V12 Files and Resources | no | No file IO beyond `SharedPreferences` |

### Known Threat Patterns for Phase 5

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Implicit broadcast hijacking (3rd-party app pretends to be our `ReminderAlarmReceiver`) | Spoofing | `Intent.setPackage(ctx.packageName)` on the PendingIntent + `android:exported="false"` on the receiver |
| `BootReceiver` spoofing (3rd-party app sends fake BOOT_COMPLETED) | Spoofing | Receiver checks `intent.action == Intent.ACTION_BOOT_COMPLETED` — platform sets sender = system, no spoof possible from userland apps without system perms |
| `POST_NOTIFICATIONS` prompted before user wants → user reflexively denies → reminder dead forever | Denial of Service (against ourselves) | Earned prompt (NOTF-06) waits for first not-to-do entry; rationale screen frames the prompt |
| Deep-link parameter injection (3rd-party Intent with `deep_link_to` extra) | Tampering | `MainActivity.onNewIntent` validates `extra == "/checkin"`; reject all others |
| Notification body leaks entry names to lock-screen observers | Information disclosure | D-10 lock — body is generic `"How did today go?"`, no entry names |
| Clock-tamper to fake a streak | Tampering | STRK-06 — `SystemClock.elapsedRealtimeNanos()` vs wall-clock divergence → `status=2 incomplete-data` |
| User uninstalls + reinstalls to reset streak | Acknowledged anti-feature | PROJECT.md "uninstall-resets-streak is by design"; not mitigated |

---

## 17. Sources

### Primary (HIGH confidence — read verbatim)

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/05-streak-engine-daily-reminder/05-CONTEXT.md` — all D-01..D-16 decisions
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/05-streak-engine-daily-reminder/05-UI-SPEC.md` — UI contract + copy lock
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` § STRK-01..09 + NOTF-01..07
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/STATE.md` — key decisions + risk register
- `/Users/jintanakhomwong/projects/not-to-do-list/CLAUDE.md` — stack constraints
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/daily_streak_table.dart` — schema (status/source enums)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/daily_checkins_table.dart` — schema (unique key entryId+day)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/pause_events_table.dart` — Phase 4 writer
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/daily_usage_summary_table.dart` — Phase 3 writer
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/block_list_table.dart` — schedule fields + threshold field exists but D-08 says don't surface
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/schedule/schedule_window.dart` — `isInScheduleWindow` source of truth
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/schedule/streak_day.dart` — `streakDayFor` 04:00 boundary
- `/Users/jintanakhomwong/projects/not-to-do-list/pigeons/notification_api.dart` — stub signature already in place
- `/Users/jintanakhomwong/projects/not-to-do-list/pigeons/permission_status_api.dart` — existing pattern to extend
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/AndroidManifest.xml` — POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED + SCHEDULE_EXACT_ALARM already declared
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` — NotificationApi `NotImplementedError` stub present
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/daos/daily_usage_summary_dao.dart` — DAO pattern to mirror
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/daos/pause_event_dao.dart` — DAO pattern to mirror
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/04-pause-ux-the-wedge/04-VALIDATION.md` — test pattern to mirror
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/config.json` — `nyquist_validation: true`, `granularity: standard`, `mode: yolo`

### Secondary (MEDIUM confidence — official docs, verified)

- [Android Developers — Schedule exact alarms denied by default (Android 14)](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms) — `SCHEDULE_EXACT_ALARM` denied by default on apps targeting 13+, fresh-install API 14+
- [Android Developers — Schedule alarms](https://developer.android.com/develop/background-work/services/alarms) — `canScheduleExactAlarms()` check requirement
- [Android Developers — Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission) — `shouldShowRequestPermissionRationale` semantics
- [Android Developers — Notification permission AOSP doc](https://source.android.com/docs/core/display/notification-perm) — Android 13+ runtime permission model
- [DateTime and Daylight Saving Time in Dart — Pinch.nl](https://medium.com/pinch-nl/datetime-and-daylight-saving-time-in-dart-9c9468633b5d) — DST handling, avoid `add(Duration(days:1))` for calendar days
- [DST Dart and DateTime — Corner Software](https://csdcorp.com/blog/coding/dst-dart-and-datetime/) — unit-testing DST in Dart
- [pub.dev: flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) — confirmed NOT needed (Pigeon hand-roll preferred)
- [pub.dev: timezone](https://pub.dev/packages/timezone) — confirmed NOT needed (no IANA tz math required)

### Tertiary (LOW confidence — flagged for verification)

- [Esper Blog — How Android 13's new restrictions on alarm APIs will improve battery life](https://www.esper.io/blog/android-13-exact-alarm-api-restrictions) — context only, not authoritative
- [findnerd — Restart your schedule with AlarmManager after phone reboot](https://findnerd.com/list/view/Restart-your-schedule-with-AlarmManager-after-phone-reboot-/7903/) — pattern guidance only
- [Medium — Android Alarm Manager Doze Mode Handling](https://medium.com/@pawan.mrin/android-alarm-manager-handle-with-care-73c2c5857786) — community blog, MEDIUM confidence

---

## 18. Metadata

**Confidence breakdown:**
- Standard stack: HIGH — already in pubspec, no new deps, Pigeon stub exists, schemas locked
- Architecture: HIGH — CONTEXT.md locked 16 decisions, UI-SPEC locked 5 screens, mirroring Phase 4 patterns
- Pitfalls: HIGH — Android 14 exact-alarm policy verified, OEM kill behavior documented through Phase 4 REL-04 PASS
- Test strategy: HIGH — Phase 4 validation pattern (`04-VALIDATION.md`) is the template

**Research date:** 2026-05-21
**Valid until:** 2026-06-21 (30 days — stable platform, no breaking Flutter releases expected)

---

## RESEARCH COMPLETE

Phase 5 is well-bounded by an unusually rich amount of pre-locked context: `DailyCheckins` + `DailyStreak` Drift tables already exist (Phase 1 scaffold), `NotificationApi` Pigeon channel is stubbed in `MainActivity.kt` with a `NotImplementedError` body, the AndroidManifest already declares `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` + `SCHEDULE_EXACT_ALARM`, the pure-Dart `streakDayFor` 04:00-boundary helper is in `lib/domain/schedule/streak_day.dart`, and the `isInScheduleWindow` helper has Kotlin↔Dart parity from Phase 4. CONTEXT.md D-01..D-16 lock all interaction decisions (single `/checkin` route, 21:00 default reminder time, NOTF-07 banner reuses Phase 3 `HealthCheckBanner`, no streak-aware notification copy, 4-state day dots with mandatory grey tooltip). No new Drift tables, no schema migration, no new pub.dev packages required — the scope is filling the existing Pigeon stub with a real `AlarmManager.setExactAndAllowWhileIdle()` body, writing two DAOs that mirror the existing `PauseEventDao` + `DailyUsageSummaryDao` patterns, implementing the §4 lazy rollover service (with the 2x2 status/source matrix and DST-safe day math), and shipping three UI surfaces (`/checkin`, Home streak badge, entry-detail Streak history section). Exit gate REL-05 mirrors the REL-04 protocol Phase 4 PASSED on Samsung Galaxy S20 Ultra 5G on 2026-05-21. The single highest-risk landmine is `BootReceiver` reading the `FlutterSharedPreferences` file across the Dart/Kotlin process boundary — Wave 0 will verify with a parity test. Planner can proceed; 9 plans recommended across 4 waves matching the Phase 4 cadence.

Sources:
- [Android Developers — Schedule exact alarms (Android 14 denied by default)](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
- [Android Developers — Schedule alarms (canScheduleExactAlarms check)](https://developer.android.com/develop/background-work/services/alarms)
- [Android Developers — Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)
- [DateTime and Daylight Saving Time in Dart — Pinch.nl Medium](https://medium.com/pinch-nl/datetime-and-daylight-saving-time-in-dart-9c9468633b5d)
- [DST Dart and DateTime — Corner Software](https://csdcorp.com/blog/coding/dst-dart-and-datetime/)
- [flutter_local_notifications — pub.dev (rejected, reference only)](https://pub.dev/packages/flutter_local_notifications)
- [Android Open Source Project — Notification permission for opt-in notifications](https://source.android.com/docs/core/display/notification-perm)
