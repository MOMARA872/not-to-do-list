# Phase 3: Screen-Time Dashboard — Research

**Researched:** 2026-05-07
**Domain:** Android UsageStatsManager bridge + Drift cache + Material 3 dashboard UI (Flutter)
**Confidence:** HIGH

## Summary

Phase 3 implements three concrete deliverables on top of fully scaffolded
Phase-1/2 infrastructure: (1) the `UsageApi.queryRange` Pigeon channel goes
live (`UsageApiImpl.kt` mirrors Phase 2's `AppPickerHostImpl.kt` exactly —
single-thread `Executor`, AppOps gate, null-safe locked-device handling);
(2) a `/dashboard` route with a `Day | Week | Month` SegmentedButton renders
a Drift-cached, lazy-on-open list of per-app screen time with not-to-do
entries highlighted; (3) two Material 3 `Card.outlined` cards on `HomeScreen`
("Avoided today" + "Cumulative totals") feed the same Drift streams.

There is **no schema migration** in Phase 3 — `daily_usage_summary` (write)
and `pause_events` (read-only aggregate) are already declared. There is
**no chart library** — a single `LinearProgressIndicator` per row plus a
period-total ribbon delivers the entire visual surface. There is **no
WorkManager** — refresh is lazy on `DashboardScreen.initState` +
`AppLifecycleState.resumed` + `RefreshIndicator`. There is **no foreground
service** — Phase 3 stays simulator-friendly by design (research anti-pattern
#3; real-device overnight gate is Phase 4 REL-04).

The single area where Phase 3 introduces new code shape is the perf test
(`test/perf/dashboard_render_test.dart`, D-20) — it mounts `DashboardScreen`
against a 30-day × 20-app seeded Drift fixture and asserts first-frame
elapsed wall-clock < 300 ms via `Stopwatch` around `tester.pumpWidget(...)`.

**Primary recommendation:** Mirror the Phase 2 `AppPickerHostImpl.kt` +
`BlockListRepository` + `_homeEntriesProvider` patterns verbatim. Do not
introduce new framework patterns. Resist all chart-library / WorkManager /
schema-migration / foreground-service pulls during planning.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Pigeon channel + Kotlin impl (D-01..04):**
- **D-01 — Channel:** Light up the existing `pigeons/usage_api.dart` `@HostApi` (already scaffolded Phase 1). No new Pigeon classes; reuse `UsagePackageStat { packageName, foregroundSeconds, launchCount }` verbatim. Regenerate via `dart run pigeon --input pigeons/usage_api.dart` if needed.
- **D-02 — Kotlin Executor:** `Executors.newSingleThreadExecutor()` (background). `UsageStatsManager.queryUsageStats(INTERVAL_DAILY, startEpochMs, endEpochMs)` runs there. Pigeon's `@async` annotation maps cleanly to a Dart `Future`. Never call from the UI thread.
- **D-03 — Permission check on Kotlin side:** Before calling `queryUsageStats`, check `AppOpsManager.checkOpNoThrow(OPSTR_GET_USAGE_STATS, …) == MODE_ALLOWED`. If denied, throw `UsageApiError("USAGE_ACCESS_DENIED", …)`. Dart catches and routes to no-permission fallback.
- **D-04 — Locked-device behavior:** Catch `SecurityException` and null returns from `queryUsageStats` (Android R+ returns null silently when device is locked). Treat as "data unavailable, retry later" — return an empty list rather than crashing.

**Dashboard navigation shape (D-05):**
- Material 3 `SegmentedButton<DashboardRange>` at top of `DashboardScreen`: `Day | Week | Month`. Reuses `BlockModeSegmented` widget pattern. Selection persists in `StateProvider<DashboardRange>` for the session only (no `shared_preferences` write — open-on-Day each cold start).

**"Highlighted" treatment for not-to-do entries (D-06..07):**
- **D-06 — Visual treatment:** Not-to-do entries get a 4-dp left accent border in `colorScheme.primary` + their app icon at 100% opacity. Non-not-to-do entries render with NO accent border + their app icon at 60% opacity. Bar-fill uses `colorScheme.primary` for not-to-do rows and `colorScheme.outlineVariant` for others.
- **D-07 — Sort order:** Not-to-do entries pinned to the top of every D/W/M list; below them, all other foreground apps sorted by `foregroundSeconds desc`. Threshold: only show non-not-to-do apps with ≥ 60 s foreground in the period.

**"Avoided today" definition (D-08..09):**
- **D-08 — Per-entry success rule (today):**
  - **Apps:** today's `daily_usage_summary.foregroundSeconds` for the entry's `packageName` ≤ `block_list.streakBreakThresholdMinutes × 60` (default 5 min × 60 = 300 s). 0 s counts as success. If the entry has a schedule (LIST-09), only foreground time **within the active window** counts (mirrors STRK-09).
  - **Habits:** today's `daily_checkins` row exists with `avoided = true`. Habit without a check-in = "Pending today" (counts as neither success nor failure).
  - **Hard-block entries (LIST-08):** same as soft — threshold-based — because Phase 3 doesn't yet have pause-event data (Phase 4 writes it).
- **D-09 — Card copy:** `"Avoided today"` headline + `"{X of Y entries succeeded today"` subtitle. If Y = 0: `"No entries yet"` and route to `/list/add-app` on tap. If usage access offline: `"Tracking is offline — tap to fix"` (reuses Phase 2 health-banner copy and routing).

**Cumulative totals scope + storage (D-10..11):**
- **D-10 — All-time, derived on read.** No denorm counter columns. `total_launches_blocked` = `COUNT(pause_events WHERE outcome IN (0=cooldown-completed, 1=cancel))`. `total_time_avoided_seconds` = `SUM(cooldownChosenSeconds)` for the same rows. Phase 3 is **read-only** on `pause_events` — Phase 4 is the writer.
- **D-11 — Card copy:** `"Total avoided"` headline + `"{N} launches blocked · {H}h {M}m saved"`. Phase 3 starts at 0 / 0 m because `pause_events` is empty until Phase 4 ships — that is the **expected and correct** state.

**Today's data freshness + refresh trigger (D-12):**
- 5-minute soft-cache for today; immutable past:
  - **Today's row:** When `DashboardScreen` mounts OR `AppLifecycleState.resumed` fires, check today's `daily_usage_summary.aggregatedAt`. If `now - aggregatedAt > 5m` (or no row exists), call `usageApi.queryRange(midnight_today_local, now)`, upsert today's row(s), then bind UI to the Drift stream. If fresh, bind directly without calling Kotlin.
  - **Past days:** Read-only. Never re-queried. First open after calendar-day rollover, lazily backfill yesterday's row(s) using `queryRange(midnight_yesterday, midnight_today)`.
  - **Pull-to-refresh:** `RefreshIndicator` wraps the list. Pull bypasses the 5-min cache.
  - **Time anchor:** Local timezone, NOT UTC. "Today" uses `DateTime.now()` floored to local midnight.

**No-permission fallback (D-13):**
- When `permissionHealthProvider.usageAccessGranted == false`, the dashboard renders the most recent `daily_usage_summary` rows with a sticky `HealthCheckBanner` at the top using the literal copy `"Tracking is offline — tap to fix"`. Tap routes to `/onboarding/permissions/usage-access`. Dashboard never shows an empty error screen.

**Aggregation worker shape (D-14):**
- Lazy on dashboard open + on `resumed`. **NO WorkManager periodic in v1.**
- Single Dart-side aggregator function `UsageRepository.refreshIfStale()`.
- Triggered by: (a) `DashboardScreen.initState` → first refresh; (b) `WidgetsBindingObserver.AppLifecycleState.resumed` while on `/dashboard` → cache-aware refresh; (c) `RefreshIndicator` pull → unconditional refresh.
- Writes via Drift `into(...).insertOnConflictUpdate(...)`. Idempotent.

**Chart vs list rendering (D-15..16):**
- **D-15 — Flat sortable list with horizontal bar-fill per row.** No chart library dep. Each row: `[icon] [display name]      [bar fill 0..maxOfPeriod] [duration text "1 h 23 m"]`. Bar fill uses `LinearProgressIndicator` tinted per D-06.
- **D-16 — Period total ribbon:** `Card` above the list: `"Day total: 4 h 23 m across 12 apps"`. Tap collapses to "today's not-to-do total" only.

**Home cards placement (D-17):**
- Two cards stacked above the unified list on `HomeScreen`, between `HealthCheckBanner` and the entries `ListView`. Both `Card.outlined`. Tap → `context.go('/dashboard')`. NOT animated-in via `AnimatedSwitcher`.

**Routing + Riverpod plumbing (D-18..19):**
- **D-18:** Single new `GoRoute(path: '/dashboard', …)` appended to `lib/core/router/app_router.dart`. Existing redirect gate handles the post-onboarding case.
- **D-19 — Provider naming:**
  - `usageApiProvider` → `Provider<UsageApi>` returning `UsageApi()` (Pigeon-generated). Mirrors `appPickerApiProvider`.
  - `usageDaoProvider` → `Provider<DailyUsageSummaryDao>` (new DAO).
  - `usageRepositoryProvider` → `Provider<UsageRepository>` (handles `refreshIfStale` + `watchRange(period)`).
  - `dashboardRangeProvider` → `StateProvider<DashboardRange>` (enum `{ day, week, month }`, default `day`).
  - `dashboardRowsProvider` → `StreamProvider.autoDispose.family<List<DashRow>, DashboardRange>` — joins not-to-do entries with usage rows.
  - `avoidedTodayProvider` → `StreamProvider.autoDispose<AvoidedTodaySummary>`.
  - `cumulativeTotalsProvider` → `StreamProvider.autoDispose<CumulativeTotalsSummary>` (reads `pause_events` aggregate via Drift).
- **All providers hand-written, no `@riverpod` codegen** (Phase 1 deviation per `01-01-SUMMARY.md`).

**Performance budget (D-20):**
- DASH-07: < 300 ms render on mid-range Android. Validation harness:
  `test/perf/dashboard_render_test.dart` mounts `DashboardScreen` against
  seeded Drift fixture (30 days × 20 apps = 600 rows) and asserts first
  frame's measured wall-clock time < 300 ms in `flutter test`. CI-runnable;
  no real device required for Phase 3 exit. Real-device validation deferred
  to Phase 4 first task.

### Claude's Discretion

- **Drift v3 migration?** No — Phase 1 already shipped `daily_usage_summary`. **No schema change in Phase 3** (`schemaVersion` stays at 2). If during research the planner decides to add an index on `(packageName, day)`, that's a non-migrating-CREATE-INDEX-only delta — Claude's discretion.
- **Test strategy:** mirror Phase 2's pattern — Wave 0 ships test stubs; Wave 1+ fills them. Unit tests for the aggregator math, widget tests for the dashboard list + bar-fill, golden tests optional.
- **Empty Day/Week/Month copy:** "No usage tracked yet — open an app and come back" (or similar) — Claude's discretion to refine during planning.

### Deferred Ideas (OUT OF SCOPE)

- Per-app drill-down screen ("tap an app row → see its hour-by-hour use") — DIFF-05 v1.x deferred.
- Time-of-day "danger zones" breakdown — DIFF-05 v1.x deferred.
- Calendar heatmap of streak / dashboard data — DIFF-02 v1.x deferred.
- Home-screen widget for "avoided today" — DIFF-04 v1.x deferred.
- Week-over-week / month-over-month comparison — out of scope for v1.
- Chart libraries (`fl_chart`, `syncfusion_flutter_charts`, etc.) — out of scope. Reconsider in M2.
- Background isolate / dataSync foreground service for aggregation — research-anti-pattern (#3).
- Data export of usage rows — Phase 6 (SETT-01).
- Screen-time goals / quotas — explicit anti-feature per PROJECT.md.
- Real-device overnight survival test as Phase 3 exit gate — Phase 4 (REL-04).
- Localization (non-English copy) — deferred. Phase 3 ships English-only.
- Disk-cached app icons — Phase 2 already deferred.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DASH-01 | App reads per-app screen time via UsageStatsManager (background-thread only — never on UI thread) | §UsageStatsManager Kotlin impl + §Pigeon @async dispatching pattern (UsageApiImpl.kt skeleton mirrors AppPickerHostImpl.kt: `Executors.newSingleThreadExecutor()`, AppOps gate, null-safe locked-device) |
| DASH-02 | Daily view shows screen time per app, with not-to-do entries highlighted | §Architecture Patterns "Highlighted row" (4-dp left accent + primary tint + 100% icon vs 60%); §Drift join pattern (block_list LEFT JOIN daily_usage_summary, sorted not-to-do-pinned-then-by-foreground) |
| DASH-03 | Weekly view aggregates the last 7 days | §Period boundaries (`[midnight_today − 6 days, now]`); same Drift query path as Day with widened range |
| DASH-04 | Monthly view reads from a pre-aggregated `daily_usage_summary` table (not raw events) | §Drift monthly query (SELECT-only from daily_usage_summary, never `usageApi.queryRange` for 30+ days); pre-aggregated table is the only data path for the M tab |
| DASH-05 | Home shows an "Avoided today" card summarizing successful avoidance for today | §Drift query for "Avoided today" (apps: foregroundSeconds ≤ threshold; habits: daily_checkins.avoided=true; pending = no row) |
| DASH-06 | Home shows cumulative totals: total launches blocked, total time avoided | §Cumulative totals Drift query (pause_events aggregate; outcome IN (0,1); empty-table → 0/0) |
| DASH-07 | Dashboard renders within 300 ms on a mid-range device | §Render-budget perf-test harness (`Stopwatch` + `tester.pumpWidget`; `test/perf/dashboard_render_test.dart` against 30-day × 20-app fixture) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

The project's CLAUDE.md (Karpathy guidelines + multi-agent DAG) imposes:

- **Simplicity first.** Minimum code that solves the problem. No speculative abstractions, no "flexibility" not requested. → Phase 3 means: NO chart-lib, NO custom segmented control, NO Drift v3 migration, NO @riverpod codegen.
- **Surgical changes.** Touch only what you must. Don't "improve" adjacent code. → Phase 3 means: `app_router.dart` gets ONE new route. `MainActivity.kt` UsageApi block gets the body filled in (the `setUp(...)` call already exists with a stub). `home_screen.dart` gets two cards inserted between the existing banner and ListView. The 8-invariant `play_invariants_test.dart` is NOT modified.
- **Goal-driven execution.** Each task converts to a verifiable check. → Phase 3 means: Wave 0 stubs the perf test before any UI work; Wave 1 makes Drift round-trip green; Wave 2 makes the Pigeon channel green; Wave 3 makes widget tests green; Wave 4 makes the perf test green.
- **No destructive scope expansion.** Per project rules: "Do not expand scope without user approval." → Reject any planner-introduced `fl_chart`, `workmanager`, `flutter_workmanager`, foreground-service, schema migration.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Read raw foreground time per package | Native (Kotlin) | — | `UsageStatsManager.queryUsageStats` is a system-service API only available on Kotlin side. Must run on a background `Executor` (PITFALLS.md #6, ARCHITECTURE.md Pattern 3). Pigeon `@async` bridges to Dart. |
| AppOps permission gate (USAGE_ACCESS_DENIED detection) | Native (Kotlin) | Domain (Dart) | `AppOpsManager.unsafeCheckOpNoThrow` is Kotlin-only; the result is propagated to Dart as a typed `UsageApiError` and consumed by `permissionHealthProvider` for the no-permission fallback. |
| Daily aggregation (raw queryUsageStats result → daily totals) | Domain (Dart) | Data (Drift) | Aggregation is pure computation over the Pigeon-typed `List<UsagePackageStat>`. Keeping it in Dart preserves the "single SQLite writer = Dart" architecture invariant (ARCHITECTURE.md anti-pattern #5). |
| Persistence + reactive streams | Data (Drift) | — | Drift owns `daily_usage_summary` writes (via `insertOnConflictUpdate`) and reads (via `.watch()` streams). Idempotent under repeated mid-day refreshes. |
| Cache freshness (5-min staleness for today, immutable past) | Data (`UsageRepository`) | — | `refreshIfStale()` is the single seam that gates Pigeon calls — never bypassed. Mirrors Phase 2 `BlockListRepository.watchAll()` shape. |
| Aggregation trigger (when to refresh) | Presentation (`DashboardScreen`) | Domain (lifecycle observer) | Lazy on open + on resume + on pull. NO background timer. Phase 3 introduces a `WidgetsBindingObserver` mixin on `DashboardScreen` State for the resume callback. |
| Joining usage rows with not-to-do entries (highlight + sort) | Domain (`DashboardRowsProvider`) | Data | Drift LEFT JOIN runs in SQLite, but the highlight/sort decision is pure-Dart and lives behind a `StreamProvider.autoDispose.family<List<DashRow>, DashboardRange>`. |
| Bar-fill rendering | Presentation (Flutter) | — | Single `LinearProgressIndicator` per row + `colorScheme.primary` vs `outlineVariant`. No chart library. Pure Material 3 widgets. |
| App icon for non-not-to-do apps | Data (`AppIconLruCache` reuse) | Native (Kotlin via existing `AppPickerApi.getApplicationIconPng`) | Phase 2's 50-entry LRU is reused unchanged; cache miss falls back to a letter-avatar widget (no new Kotlin call needed when icon is unavailable). |
| "Avoided today" card | Presentation (Flutter) | Domain (`avoidedTodayProvider`) | Pure Drift aggregate; no Pigeon. Card is a passive consumer of the stream. |
| Cumulative totals card | Presentation (Flutter) | Domain (`cumulativeTotalsProvider`) | Pure Drift aggregate over `pause_events`; Phase 3 is read-only on this table — Phase 4 is the writer. |
| Render-budget validation | Test (Flutter) | — | `Stopwatch` around `tester.pumpWidget` against a seeded fixture. Lives in `test/perf/dashboard_render_test.dart`. CI-runnable, no real device. |

## Standard Stack

### Core (already pinned in pubspec.lock — verified 2026-05-07)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | 2.33.0 | SQLite typed ORM + reactive streams. `insertOnConflictUpdate` for upserts. `customSelect(...)` for ad-hoc aggregates. | Already in use (Phase 1 + 2). Stable. `2.33.0` is one minor newer than the STACK.md pin (2.32) — deliberate, the lockfile is authoritative. [VERIFIED: pubspec.lock] |
| `drift_dev` | 2.33.0 | Build-runner code-gen for Drift schema/DAO/companions. | DAO version must match drift minor. [VERIFIED: pubspec.lock] |
| `drift_flutter` | 0.3.0 | Convenience SQLite opener + `driftDatabase(name: ...)` helper. | Used by `app_database.dart` already. [VERIFIED: pubspec.lock] |
| `flutter_riverpod` | 3.3.1 | State management. `StreamProvider.autoDispose.family<>`, `StateProvider<>`, hand-written `Provider<>`. | Already in use. NO `@riverpod` codegen — incompatible with `pigeon 26.3.4` + `meta 1.17` per `01-01-SUMMARY.md`. [VERIFIED: pubspec.lock] |
| `pigeon` | 26.3.4 (dev) | Code-gen for Dart↔Kotlin typed channels. Phase 3 does **not** regenerate (existing `usage_api.g.dart` + `UsageApi.g.kt` are unchanged in shape). | Pinned project-wide. [VERIFIED: pubspec.lock] |
| `go_router` | 17.2.3 | Declarative routing. Phase 3 appends one route (`/dashboard`). | Already in use. [VERIFIED: pubspec.lock] |
| `mocktail` | 1.0.5 (dev) | Test doubles. `MockUsageApi extends Mock implements UsageApi`. | Already in use; Phase 2 settled `mocktail` over `mockito`. [VERIFIED: pubspec.lock] |
| `very_good_analysis` | 10.2.0 (dev) | Strict lint preset. New Phase 3 code must analyze 0 errors / 0 warnings. | Pre-existing 18 infos in `pigeons/*` + `permission_status_mock.dart` are grandfathered (deferred-items.md). [VERIFIED: pubspec.lock] |

**No new packages are needed for Phase 3.** All dependencies are already resolved.

### Supporting (existing — reuse)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Flutter Material 3 (SDK) | 3.41.x | `SegmentedButton`, `Card.outlined`, `LinearProgressIndicator`, `RefreshIndicator`, `CircleAvatar`. | All dashboard widgets are stock M3. |
| `intl` (already in pubspec) | 0.20.2 | `DateFormat` for "1 h 23 m" duration text and "Mon Apr 26" day labels. | Reuse — no new dep. |
| `WidgetsBindingObserver` (Flutter SDK) | — | `AppLifecycleState.resumed` callback on `DashboardScreen` to trigger `refreshIfStale()` (D-14). Mirrors `lib/features/health/health_lifecycle_observer.dart` pattern from Phase 2. | New mixin on `_DashboardScreenState`. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff — Why Rejected |
|------------|-----------|--------------------------|
| `LinearProgressIndicator` bar-fill | `fl_chart` 0.69.x | +~100 KB APK + 200+ lines of chart-config plumbing for a 1-bar-per-row visual. Pure overkill. **Locked out by CONTEXT.md "Deferred Ideas"** + Karpathy "Simplicity First". |
| `app_usage` 4.1.0 plugin | Direct Pigeon-typed channel | The `app_usage` plugin is hand-rolled MethodChannel (typing failures at runtime). Pigeon-typed channel was already chosen project-wide (ARCHITECTURE.md). The plugin would duplicate logic that already exists scaffolded. **CONTEXT.md D-01 picks Pigeon explicitly.** |
| `WorkManager` periodic aggregation | Lazy on `initState` + `resumed` | WorkManager-15-min-min interval + Doze throttling provides no value to "user just opened the dashboard 5s after backgrounding" — the lazy path covers it perfectly. Phase 5 (STRK-05 + NOTF-05) already pulls WorkManager in for streak rollover; Phase 3 doesn't earn it. **CONTEXT.md D-14 explicitly defers.** |
| `dataSync` foreground service polling | Lazy on open + resume | App Standby Bucket pressure + battery drain + Play scrutiny. PITFALLS.md anti-pattern #3 calls this out specifically. |
| Direct Drift query in widget `build()` | `StreamProvider.autoDispose.family<>` | Riverpod's `autoDispose` cancels Drift subscriptions on tab change; family parameterizes by `DashboardRange` cleanly. Phase 2 already uses this exact pattern in `_homeEntriesProvider` (`home_screen.dart` line 14). |
| `@riverpod` codegen | Hand-written `Provider<>` | `riverpod_generator` was dropped in Plan 01-01 because `riverpod_annotation` pins analyzer minors that conflict with `pigeon 26.3.4` + Flutter 3.41 (`meta 1.17`). All Phase 1 + 2 providers are hand-written. Same constraint applies to Phase 3. |

### Installation

No new dependencies. `pubspec.yaml` is unchanged.

**Pigeon regeneration check:** Existing `pigeons/usage_api.dart`, `lib/platform/usage_api.g.dart`, and `android/.../platform/UsageApi.g.kt` are aligned (verified 2026-05-07). Phase 3 does **not** modify the Pigeon schema — only the impl body changes. **Do not run `dart run pigeon ...` unless the Pigeon schema is intentionally changed** (regeneration would only churn copyright/version markers).

**Version verification:** All package versions are read from the actual `pubspec.lock` (the lockfile is the source of truth, not STACK.md which was written for Phase 1 and predates the 2.32 → 2.33 minor bump). [VERIFIED: pubspec.lock]

## Architecture Patterns

### System Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                  Flutter (Dart) — Phase 3 surfaces                      │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  HomeScreen (Phase 2 shell)                  DashboardScreen (NEW)     │
│  ──────────────────────────                  ─────────────────────     │
│  ┌────────────────────────┐                  ┌─────────────────────┐  │
│  │ HealthCheckBanner      │                  │ AppBar(/dashboard)   │  │
│  │ (Phase 2; reused)      │                  │ + SegmentedButton    │  │
│  └────────────────────────┘                  │   D | W | M          │  │
│  ┌────────────────────────┐                  ├─────────────────────┤  │
│  │ NEW: AvoidedTodayCard  │←─────────────────┤ Period total Card    │  │
│  │  (Card.outlined)       │   tap → /dashboard│ ("Day total: 4h")    │  │
│  └────────────────────────┘                  ├─────────────────────┤  │
│  ┌────────────────────────┐                  │ RefreshIndicator     │  │
│  │ NEW: CumulativeTotals  │←─────────────────┤  ListView.builder    │  │
│  │  Card (Card.outlined)  │   tap → /dashboard│  ┌────────────────┐ │  │
│  └────────────────────────┘                  │  │ DashRow         │ │  │
│  ┌────────────────────────┐                  │  │ [icon][name]    │ │  │
│  │ Phase 2 entries        │                  │  │ [bar][1h 23m]   │ │  │
│  │ ListView.builder       │                  │  │ + 4dp accent if │ │  │
│  └────────────────────────┘                  │  │ not-to-do       │ │  │
│                                              │  └────────────────┘ │  │
│                                              └─────────────────────┘  │
│                                                                        │
│  Riverpod providers (hand-written, no codegen)                         │
│   - usageApiProvider          (Phase 3 NEW)                            │
│   - usageDaoProvider          (Phase 3 NEW)                            │
│   - usageRepositoryProvider   (Phase 3 NEW)                            │
│   - dashboardRangeProvider    (Phase 3 NEW; StateProvider)             │
│   - dashboardRowsProvider     (Phase 3 NEW; StreamProvider.family)     │
│   - avoidedTodayProvider      (Phase 3 NEW; StreamProvider)            │
│   - cumulativeTotalsProvider  (Phase 3 NEW; StreamProvider)            │
│   - permissionHealthProvider  (Phase 2; reused for D-13 fallback)      │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Data layer                                                            │
│   ┌─────────────────────────────────────────────────────────┐          │
│   │ UsageRepository  (Phase 3 NEW)                          │          │
│   │   refreshIfStale() ─→ today's row(s) only               │          │
│   │   watchRange(range) ─→ Stream<List<DailyUsageSummary>>  │          │
│   └─────────────────────────────────────────────────────────┘          │
│              │                              │                          │
│              ▼                              ▼                          │
│   ┌──────────────────────┐        ┌──────────────────────┐             │
│   │ usageApi (Pigeon)    │        │ DailyUsageSummaryDao │             │
│   │ (Phase 3 NEW; uses   │        │ (Phase 3 NEW; reads  │             │
│   │  scaffolded Phase-1  │        │  Phase-1 schema)     │             │
│   │  generated code)     │        │  + Drift insertOn-   │             │
│   └──────────────────────┘        │  ConflictUpdate      │             │
│              │                    └──────────────────────┘             │
│              │                              │                          │
└──────────────┼──────────────────────────────┼──────────────────────────┘
               │                              │
               ▼                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Native Android (Kotlin)                  Drift SQLite (on-device)   │
│  ────────────────────────                  ──────────────────────────  │
│  UsageApiImpl.kt (Phase 3 NEW)            daily_usage_summary table   │
│   - Executors.newSingleThreadExecutor       (Phase 1; Phase 3 writes) │
│   - AppOps.OPSTR_GET_USAGE_STATS gate     pause_events table          │
│   - UsageStatsManager.queryUsageStats(      (Phase 1; Phase 3 reads   │
│       INTERVAL_DAILY, start, end)           cumulative aggregate)     │
│   - try/catch SecurityException +         block_list table            │
│     null-on-locked-device handling          (Phase 1+2; Phase 3 reads │
│                                             for join + threshold)     │
│  UsageApi.setUp(...) wires impl in        daily_checkins table        │
│   MainActivity.configureFlutterEngine        (Phase 1; Phase 3 reads  │
│   (replaces the Phase-1 stub callback)      for habit "avoided today")│
└──────────────────────────────────────────────────────────────────────┘
```

### Recommended File Layout

```
lib/
├── core/router/app_router.dart                  # MODIFIED: append /dashboard route
├── data/
│   ├── database/
│   │   ├── daos/
│   │   │   ├── block_list_dao.dart              # existing
│   │   │   └── daily_usage_summary_dao.dart     # NEW
│   │   ├── tables/                              # existing — NO changes
│   │   └── app_database.dart                    # MODIFIED: add daos: [..., DailyUsageSummaryDao]
│   └── repositories/
│       ├── block_list_repository.dart           # existing
│       └── usage_repository.dart                # NEW
├── domain/
│   └── providers/
│       ├── ...                                  # existing
│       ├── usage_api_provider.dart              # NEW (mirrors app_picker_api_provider.dart)
│       ├── usage_dao_provider.dart              # NEW
│       └── usage_repository_provider.dart       # NEW
├── features/
│   ├── home/
│   │   ├── pages/home_screen.dart               # MODIFIED: insert two cards
│   │   └── widgets/
│   │       ├── avoided_today_card.dart          # NEW
│   │       └── cumulative_totals_card.dart      # NEW
│   └── dashboard/                               # NEW feature folder
│       ├── pages/dashboard_screen.dart          # NEW
│       ├── providers/
│       │   ├── dashboard_range_provider.dart    # NEW
│       │   ├── dashboard_rows_provider.dart     # NEW
│       │   ├── avoided_today_provider.dart      # NEW
│       │   └── cumulative_totals_provider.dart  # NEW
│       ├── widgets/
│       │   ├── dashboard_segmented.dart         # NEW (mirrors block_mode_segmented.dart)
│       │   ├── dashboard_row.dart               # NEW (icon + name + bar-fill)
│       │   ├── period_total_ribbon.dart         # NEW
│       │   └── letter_avatar.dart               # NEW (icon-cache-miss fallback)
│       └── models/
│           ├── dashboard_range.dart             # NEW (enum)
│           └── dash_row.dart                    # NEW (DTO for the join result)
android/app/src/main/kotlin/com/nottodo/not_to_do_list/
├── platform/
│   ├── UsageApi.g.kt                            # existing (generated; do not modify)
│   ├── UsageApiImpl.kt                          # NEW (mirrors AppPickerHostImpl.kt)
│   └── ...                                      # existing impls
└── MainActivity.kt                              # MODIFIED: replace stub callback with UsageApiImpl
test/
├── _fixtures/
│   ├── permission_status_mock.dart              # existing
│   └── usage_summary_fixture.dart               # NEW (30-day × 20-app seed)
├── data/repositories/usage_repository_test.dart # NEW
├── platform/usage_api_test.dart                 # NEW (mock-Pigeon)
├── features/dashboard/
│   ├── dashboard_screen_test.dart               # NEW (widget)
│   ├── dashboard_row_test.dart                  # NEW (widget — bar-fill)
│   ├── avoided_today_card_test.dart             # NEW (widget)
│   └── cumulative_totals_card_test.dart         # NEW (widget)
├── perf/
│   └── dashboard_render_test.dart               # NEW (D-20 perf gate)
└── policy/play_invariants_test.dart             # existing — MUST stay green
```

### Pattern 1: Pigeon HostApi `@async` impl with Kotlin Executor + AppOps gate

**What:** `UsageApiImpl.kt` mirrors the Phase 2 exemplar (`AppPickerHostImpl.kt`). Single private `Executors.newSingleThreadExecutor()`. AppOps check before any system call. `try/catch` wraps both `SecurityException` (Android R+ locked-device) and null returns from `queryUsageStats`.

**When to use:** Every Pigeon `@async` HostApi method that touches a system service. Always.

**Example — `UsageApiImpl.kt` skeleton (planner: this is the reference shape; copy verbatim, adjusting the body of `queryRange`):**

```kotlin
// android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApiImpl.kt
// Source: mirrors AppPickerHostImpl.kt exactly (Phase 2 Plan 02-03).
package com.nottodo.not_to_do_list.platform

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process
import java.util.concurrent.Executors

/**
 * Phase 3 implementation of UsageApi.
 *
 * Runs on a private background Executor — never the UI thread (PITFALLS.md
 * anti-pattern #3: queryUsageStats drops frames if called on the main thread).
 *
 * AppOps gate: returns USAGE_ACCESS_DENIED via UsageApiError so Dart routes
 * to the no-permission fallback (D-13). NEVER throws across the channel —
 * Pigeon's @async wraps a Result<List<UsagePackageStat>> that carries either
 * success or a typed error.
 *
 * PLAY-02 invariant: this class MUST NEVER call any autonomous-action API.
 */
class UsageApiImpl(private val context: Context) : UsageApi {
    private val executor = Executors.newSingleThreadExecutor()

    override fun queryRange(
        startEpochMs: Long,
        endEpochMs: Long,
        callback: (Result<List<UsagePackageStat>>) -> Unit,
    ) {
        executor.execute {
            try {
                // AppOps gate (D-03). Mirrors PermissionStatusApiImpl.isUsageAccessGranted.
                val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                val mode = appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
                if (mode != AppOpsManager.MODE_ALLOWED) {
                    callback(
                        Result.failure(
                            UsageApiError(
                                code = "USAGE_ACCESS_DENIED",
                                message = "PACKAGE_USAGE_STATS not granted",
                            ),
                        ),
                    )
                    return@execute
                }

                val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

                // INTERVAL_DAILY = system bucket type for daily aggregates.
                // queryUsageStats returns null when the device is locked on
                // Android R+ (PITFALLS.md L313). Treat null as empty list.
                val raw = usm.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    startEpochMs,
                    endEpochMs,
                ) ?: emptyList()

                // Group by packageName, sum totalTimeInForeground (ms → s).
                // (Multiple buckets can return for the same package across day boundaries.)
                val grouped = raw
                    .filter { it.totalTimeInForeground > 0L }
                    .groupBy { it.packageName }
                    .map { (pkg, list) ->
                        UsagePackageStat(
                            packageName = pkg,
                            foregroundSeconds = list.sumOf { it.totalTimeInForeground } / 1000L,
                            launchCount = 0L, // INTERVAL_DAILY UsageStats lacks launchCount; fill 0.
                        )
                    }
                callback(Result.success(grouped))
            } catch (e: SecurityException) {
                // Android R+ locked-device occasionally surfaces SecurityException
                // even past the AppOps gate. Treat as transient.
                callback(Result.success(emptyList()))
            } catch (e: Throwable) {
                callback(Result.failure(e))
            }
        }
    }
}
```

[CITED: existing `AppPickerHostImpl.kt` lines 31–106 — same shape]
[VERIFIED: `PermissionStatusApiImpl.kt` lines 29–41 already uses `unsafeCheckOpNoThrow(OPSTR_GET_USAGE_STATS, ...)` — Phase 3 reuses that idiom]
[CITED: `pigeons/usage_api.dart` — `UsagePackageStat { packageName, foregroundSeconds, launchCount }`]

**`MainActivity.kt` modification (planner: this is a one-line semantic change in the existing `setUp(...)` block):**

```kotlin
// Replace the Phase-1 stub callback (lines 23-31 in MainActivity.kt) with:
UsageApi.setUp(
    flutterEngine.dartExecutor.binaryMessenger,
    UsageApiImpl(applicationContext),
)
```

[CITED: existing `MainActivity.kt` lines 33–36 use the identical shape for `AppPickerApi.setUp`]

### Pattern 2: Drift `insertOnConflictUpdate` for idempotent daily upserts

**What:** `DailyUsageSummaryDao.upsertDay(packageName, day, foregroundSeconds, launchCount)` uses Drift's `into(...).insertOnConflictUpdate(...)` against the unique key `(packageName, day)` declared in `daily_usage_summary_table.dart`.

**When to use:** Every refresh of today's row(s). Mid-day refreshes overwrite (no double-count); past-day backfills land idempotently.

**Example — `DailyUsageSummaryDao` skeleton:**

```dart
// lib/data/database/daos/daily_usage_summary_dao.dart
import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/tables/daily_usage_summary_table.dart';

part 'daily_usage_summary_dao.g.dart';

@DriftAccessor(tables: [DailyUsageSummary])
class DailyUsageSummaryDao extends DatabaseAccessor<AppDatabase>
    with _$DailyUsageSummaryDaoMixin {
  DailyUsageSummaryDao(super.attachedDatabase);

  /// Upsert one day's row for one package. Idempotent (D-14).
  Future<void> upsertDay({
    required String packageName,
    required DateTime day, // local-midnight, normalized
    required int foregroundSeconds,
    required int launchCount,
    required DateTime aggregatedAt,
  }) {
    return into(dailyUsageSummary).insertOnConflictUpdate(
      DailyUsageSummaryCompanion.insert(
        packageName: packageName,
        day: day,
        foregroundSeconds: foregroundSeconds,
        launchCount: Value(launchCount),
        aggregatedAt: aggregatedAt,
      ),
    );
  }

  /// Today's row for the staleness check (D-12).
  Future<DailyUsageSummaryData?> getTodayFor(String packageName, DateTime localMidnight) =>
      (select(dailyUsageSummary)
            ..where((t) =>
                t.packageName.equals(packageName) &
                t.day.equals(localMidnight)))
          .getSingleOrNull();

  /// Reactive stream over a date range (DASH-02/03/04).
  Stream<List<DailyUsageSummaryData>> watchRange(DateTime startDay, DateTime endDay) =>
      (select(dailyUsageSummary)
            ..where((t) => t.day.isBetweenValues(startDay, endDay))
            ..orderBy([(t) => OrderingTerm.desc(t.day)]))
          .watch();
}
```

[CITED: existing `BlockListDao` (`lib/data/database/daos/block_list_dao.dart`) — same `@DriftAccessor` + `select(...).watch()` pattern]
[CITED: `daily_usage_summary_table.dart` lines 14–17 — `uniqueKeys: [{packageName, day}]` is the conflict target for `insertOnConflictUpdate`]

**Index recommendation:** SQLite **automatically creates a UNIQUE INDEX** on the `(packageName, day)` unique key (Drift's `uniqueKeys: [{packageName, day}]` translates to `UNIQUE` constraint, which SQLite implements as an internal unique index). Monthly view scans 30 rows × N apps where N ≤ ~50 typical — that's < 1500 rows, well within SQLite's "table-scan is fast" zone (< 1 ms on Pixel 6 emulator). **No additional `CREATE INDEX` is needed for Phase 3.** [ASSUMED — based on standard SQLite engine behavior; the table is small enough that a query plan check is unnecessary at this scale.]

### Pattern 3: Hand-written `StreamProvider.autoDispose.family<>` for the join

**What:** `dashboardRowsProvider` is a `StreamProvider.autoDispose.family<List<DashRow>, DashboardRange>` that:
1. Reads `block_list` via `BlockListRepository.watchAll()` — the Phase 2 stream.
2. Reads `daily_usage_summary` via `UsageRepository.watchRange(period)`.
3. Computes the union (not-to-do entries pinned + non-not-to-do apps with ≥ 60 s).
4. Emits a sorted, highlighted `List<DashRow>`.

**When to use:** Whenever a stream consumer needs to combine two reactive Drift sources. `autoDispose` cancels both subscriptions when the dashboard tab unmounts.

**Example — `dashboardRowsProvider` skeleton:**

```dart
// lib/features/dashboard/providers/dashboard_rows_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/domain/providers/usage_repository_provider.dart';
import 'package:not_to_do_list/features/dashboard/models/dashboard_range.dart';
import 'package:not_to_do_list/features/dashboard/models/dash_row.dart';
import 'package:rxdart/rxdart.dart'; // OPTIONAL — avoid if it adds a dep; manual zip works

final StreamProviderFamily<List<DashRow>, DashboardRange>
    dashboardRowsProvider =
    StreamProvider.autoDispose.family<List<DashRow>, DashboardRange>(
  (ref, range) async* {
    final blockRepo = ref.watch(blockListRepoProvider);
    final usageRepo = ref.watch(usageRepositoryProvider);

    // Trigger refresh on initial bind (lazy on dashboard open, D-14).
    // refreshIfStale is idempotent — safe to call on every subscription.
    await usageRepo.refreshIfStale();

    final (start, end) = _resolveRange(range);
    // Manual zip — avoids rxdart dep. Combine streams via async-iterator
    // pattern: when either source emits, recompute. (Simplest production
    // pattern in 2026 Flutter without adding dependencies.)
    await for (final entries in blockRepo.watchAll()) {
      await for (final usage in usageRepo.watchRange(start, end)) {
        yield _join(entries, usage, range);
        break; // re-enter outer loop on next entries emission
      }
    }
  },
);

(DateTime, DateTime) _resolveRange(DashboardRange r) { ... }
List<DashRow> _join(List<BlockListData> entries, List<DailyUsageSummaryData> usage, DashboardRange r) { ... }
```

⚠ **Note on `rxdart`:** A clean stream combinator (`Rx.combineLatest2`) would simplify this — but `rxdart` is NOT in the current pubspec. **Recommendation:** for Phase 3, implement manual `Stream` combination via two `StreamSubscription`s in a `StreamController`, or use `flutter_riverpod`'s `ref.watch` cascade across two separate providers (`blockEntriesProvider.watch` + `usageRowsProvider.watch` + a derived computed `Provider`). The latter is more idiomatic and adds zero deps.

**Better alternative — derive in pure Riverpod, no `rxdart`:**

```dart
// Each side is its own StreamProvider; the dashboardRowsProvider is a
// computed Provider that re-derives synchronously when either source emits.
final _entriesProvider = StreamProvider.autoDispose<List<BlockListData>>((ref) {
  return ref.watch(blockListRepoProvider).watchAll();
});

final _usageProvider =
    StreamProvider.autoDispose.family<List<DailyUsageSummaryData>, DashboardRange>(
  (ref, range) {
    final repo = ref.watch(usageRepositoryProvider);
    final (start, end) = _resolveRange(range);
    // Trigger refresh on first read — idempotent (D-14).
    Future.microtask(repo.refreshIfStale);
    return repo.watchRange(start, end);
  },
);

final dashboardRowsProvider =
    Provider.autoDispose.family<AsyncValue<List<DashRow>>, DashboardRange>(
  (ref, range) {
    final entriesAsync = ref.watch(_entriesProvider);
    final usageAsync = ref.watch(_usageProvider(range));
    return entriesAsync.whenData((entries) {
      return usageAsync.when(
        data: (usage) => _join(entries, usage, range),
        loading: () => const <DashRow>[],
        error: (_, __) => const <DashRow>[],
      );
      // Note: `whenData` already short-circuits on loading/error of entriesAsync.
    });
  },
);
```

[CITED: existing `_homeEntriesProvider` (`lib/features/home/pages/home_screen.dart` lines 14–18) is the exact `StreamProvider.autoDispose<...>` shape Phase 2 uses for entries]
[CITED: existing `appIconBytesProvider` (`lib/features/list/providers/app_icon_cache_provider.dart` lines 47–62) is the exact `FutureProvider.autoDispose.family<>` shape — same parameterization mechanic]

### Pattern 4: `AppLifecycleState.resumed` triggers `refreshIfStale()`

**What:** `_DashboardScreenState` mixes `WidgetsBindingObserver`. `didChangeAppLifecycleState(AppLifecycleState.resumed)` calls `ref.read(usageRepositoryProvider).refreshIfStale()`.

**When to use:** Any screen whose data needs to be fresh on resume from background. Phase 2 already uses this exact pattern in `lib/features/health/health_lifecycle_observer.dart`.

**Example:**

```dart
class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First refresh fires here. The provider.watch chain also schedules
    // refreshIfStale via Future.microtask, but doing it in initState makes
    // the trigger explicit and testable.
    Future.microtask(
      () => ref.read(usageRepositoryProvider).refreshIfStale(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(usageRepositoryProvider).refreshIfStale();
    }
  }
}
```

[CITED: `lib/features/health/permission_health_provider.dart` — same `Notifier.refresh()` pattern; `lib/features/health/health_lifecycle_observer.dart` for the `WidgetsBindingObserver` mixin precedent]

### Pattern 5: Pure-widget bar-fill (no chart library)

**What:** Each `DashboardRow` widget has a `LinearProgressIndicator` whose `value = foregroundSeconds / maxOfPeriodForegroundSeconds`. Color tinted per D-06.

**Example:**

```dart
class DashboardRow extends ConsumerWidget {
  const DashboardRow({required this.row, required this.maxSeconds, super.key});
  final DashRow row;
  final int maxSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isNotToDo = row.isNotToDo;
    final fillRatio = maxSeconds == 0
        ? 0.0
        : (row.foregroundSeconds / maxSeconds).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        border: isNotToDo
            ? Border(left: BorderSide(color: cs.primary, width: 4))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        // App icon (cached) or letter-avatar fallback.
        Opacity(
          opacity: isNotToDo ? 1.0 : 0.6,
          child: _IconOrLetter(packageName: row.packageName, displayName: row.displayName),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row.displayName, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: fillRatio,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isNotToDo ? cs.primary : cs.outlineVariant,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Text(_formatDuration(row.foregroundSeconds)),
      ]),
    );
  }
}
```

[VERIFIED: Material 3 `LinearProgressIndicator` is in the Flutter SDK, no external dep needed]

### Anti-Patterns to Avoid

- **Querying `UsageStatsManager` on the UI thread.** Drops frames on slow devices; PITFALLS.md L332 documents 100ms+ UI freezes. **Always** dispatch through Pigeon's `@async` to the Kotlin Executor.
- **Trusting `queryAndAggregateUsageStats(now-1h, now)` totals as "right now."** Buckets are time-window aggregates with ~2 minute lag (PITFALLS.md L312). For point-in-time you'd need `queryEvents`, but Phase 3 doesn't need point-in-time — daily aggregates are exactly what we want.
- **Querying 90 days of `INTERVAL_DAILY` on every monthly-view open.** PITFALLS.md L329: jank after 30 days of usage. The pre-aggregated `daily_usage_summary` table (DASH-04) is the only data path for the M tab — Phase 3 NEVER calls `usageApi.queryRange` for ranges > "today" or "yesterday backfill."
- **60-second polling foreground service for "live" usage updates.** PITFALLS.md anti-pattern #3: battery drain + Standby Bucket pressure. Phase 3 stays lazy-on-open.
- **Adding a chart library for one bar per row.** Karpathy "Simplicity First" + CONTEXT.md "Deferred Ideas". `LinearProgressIndicator` is enough.
- **Re-running Pigeon code-gen for cosmetic reasons.** The existing `usage_api.g.dart` + `UsageApi.g.kt` are already aligned (verified 2026-05-07). Regenerating churns nothing useful and risks introducing diff noise; only regenerate if `pigeons/usage_api.dart` changes.
- **Modifying `play_invariants_test.dart`.** The 8 absence-grep invariants are the cross-tree policy gate. Phase 3 must NOT touch them. New code must analyze clean against all 8 patterns (no `performAction(`, no `QUERY_ALL_PACKAGES`, no `SYSTEM_ALERT_WINDOW`, etc.).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Daily-bucketed aggregation of foreground times | Custom Kotlin parsing of raw `UsageEvents` | `UsageStatsManager.queryUsageStats(INTERVAL_DAILY, ...)` | The system already aggregates by day. Going lower-level adds complexity for zero Phase-3 value. |
| Cross-process SQLite write coordination | A second writer in Kotlin | Single-writer Dart pattern (ARCHITECTURE.md anti-pattern #5) | One writer, no two-process WAL contention. |
| Permission-state polling | A custom `Timer.periodic` to recheck | `permissionHealthProvider` + `WidgetsBindingObserver.resumed` | Phase 2 already wired the resume re-check; reuse the same provider. |
| App-icon disk cache | A custom on-disk PNG cache | `AppIconLruCache` (50 entries, in-memory) + letter-avatar fallback | Phase 2 deferred disk-cache; Phase 3 inherits. PITFALLS / Privacy / `allowBackup="false"` already lock this in. |
| Chart-library bar | `fl_chart` / `syncfusion_flutter_charts` | `LinearProgressIndicator` with tinted `valueColor` | `fl_chart` adds ~100 KB + complexity for what a single Material 3 widget already does. |
| WorkManager periodic refresh | `flutter_workmanager` 0.7 | Lazy `refreshIfStale()` on `initState` + `resumed` + pull | Not earning its keep in Phase 3 (no overnight requirements; user opens dashboard → fresh data). |
| Stream combinator for two Drift streams | A custom `StreamController<List<DashRow>>` | Two `StreamProvider`s + a derived `Provider` | Riverpod's reactive cascade does this idiomatically; no new control-flow code. |
| Custom permission gate inside the Pigeon impl | Hand-rolling AppOps lookup variants | `AppOpsManager.unsafeCheckOpNoThrow(OPSTR_GET_USAGE_STATS, ...)` | Already canonical in `PermissionStatusApiImpl.kt` lines 32-36 — Phase 3 reuses verbatim. |
| Letter-avatar widget | A bespoke text-on-circle drawable | `CircleAvatar(child: Text(displayName.characters.first.toUpperCase()))` | Material 3 stock widget. |

**Key insight:** Phase 3 has 7 narrowly-bounded data-shape decisions and zero new framework patterns. **Every line of code Phase 3 ships should be traceable to a Phase 1 or Phase 2 exemplar.** If a planner draft introduces an unfamiliar idiom, that's a checkpoint.

## Local Timezone Day-Boundary Computation

Phase 3 needs reliable "midnight today local" computation. Phase 5 (STRK-08) owns full DST-correctness; Phase 3's bar is lower — the day boundary just needs to not crash on DST transition days.

**Pure-Dart helper:**

```dart
/// Local-timezone midnight floor of [t]. DST-safe enough for Phase 3:
/// on transition days the resulting DateTime might "skip" or "double" an
/// hour, but DateTime arithmetic handles this transparently — we never
/// reason about "how many hours since midnight" in Phase 3.
DateTime localMidnight(DateTime t) {
  final local = t.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Range resolution for D-12 / DASH-03 / DASH-04.
({DateTime start, DateTime end}) resolveRange(DashboardRange r, DateTime now) {
  final today = localMidnight(now);
  switch (r) {
    case DashboardRange.day:
      return (start: today, end: now);
    case DashboardRange.week:
      // Rolling 7 days, ending today.
      return (start: today.subtract(const Duration(days: 6)), end: now);
    case DashboardRange.month:
      // Rolling 30 days, ending today.
      return (start: today.subtract(const Duration(days: 29)), end: now);
  }
}
```

**Why `Duration(days: 6/29)` is safe across DST:** `Duration` is wall-clock-naive (always 24h × 6 or 24h × 29). Subtracting from a `DateTime` instance shifts the absolute instant by exactly that many hours, which is the *correct* behavior here — we want the rolling-30-day window to be a 30-day window measured in calendar days, and the slight (1-hour) drift on DST transition days does not affect the "show me roughly the last 30 days" UX. **The streak engine's stricter local-day accounting is Phase 5 (STRK-08).** [VERIFIED: Dart `DateTime` docs — `Duration` arithmetic is in absolute time, not local-clock time]

## App Icon Strategy for Non-Not-To-Do Apps

Dashboard rows include ALL foreground apps over the 60-s threshold (not just not-to-do entries). Most of those won't have icons cached.

**Strategy:**
1. Try `AppIconLruCache.get(packageName)` — Phase 2's 50-entry in-memory LRU.
2. Cache miss → request via `appIconBytesProvider(packageName)` (existing Phase 2 `FutureProvider.family`) — calls `appPickerApi.getApplicationIconPng(packageName)` on the Kotlin side.
3. If Kotlin returns null (app uninstalled, not enumerable): fall back to `LetterAvatar` widget — `CircleAvatar` with first letter of `displayName` (or first letter of last `.`-segment of `packageName` if `displayName` unavailable).

**No new Kotlin code is needed** — `AppPickerApi.getApplicationIconPng` already exists from Phase 2 and works for any installed package.

```dart
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ch = label.isEmpty ? '?' : label.characters.first.toUpperCase();
    return CircleAvatar(
      radius: 16,
      backgroundColor: cs.surfaceContainerHighest,
      child: Text(ch, style: TextStyle(color: cs.onSurfaceVariant)),
    );
  }
}
```

[CITED: existing `appIconBytesProvider` (`lib/features/list/providers/app_icon_cache_provider.dart`) returns `null` for cache miss + uninstalled — same fallback signal Phase 3 uses]

## "Avoided today" Drift Query

Given:
- `block_list` rows (entries — apps and habits — with `streakBreakThresholdMinutes`, `scheduleStartMinutes`, `scheduleEndMinutes`, `scheduleWeekdayMask`)
- `daily_usage_summary` rows (today's per-package totals)
- `daily_checkins` rows (today's per-entry self-report)

**Logic (in `avoidedTodayProvider`):**

```dart
// lib/features/dashboard/providers/avoided_today_provider.dart
final StreamProvider<AvoidedTodaySummary> avoidedTodayProvider =
    StreamProvider.autoDispose<AvoidedTodaySummary>((ref) async* {
  final db = ref.watch(databaseProvider);
  final today = localMidnight(DateTime.now());

  // Combine three streams: entries + today's usage + today's check-ins.
  // Reactive — Drift fires when any of the three changes (e.g., user
  // checks in a habit, dashboard refreshes today's usage).
  await for (final _ in db.allTablesUpdates([
    db.blockList,
    db.dailyUsageSummary,
    db.dailyCheckins,
  ])) {
    final entries = await db.select(db.blockList).get();
    final usageToday = await (db.select(db.dailyUsageSummary)
          ..where((t) => t.day.equals(today)))
        .get();
    final checkinsToday = await (db.select(db.dailyCheckins)
          ..where((t) => t.day.equals(today)))
        .get();

    var succeeded = 0;
    var pending = 0;
    var failed = 0;

    for (final e in entries) {
      switch (e.kind) {
        case 0: // App
          // Only count usage within the active window if the entry is scheduled.
          // Phase 3 simplification: if scheduled and CURRENTLY outside the window,
          // we still threshold against today's total foregroundSeconds.
          // Phase 5 STRK-09 owns the strict per-window accounting.
          final usage = usageToday.firstWhere(
            (u) => u.packageName == e.packageName,
            orElse: () => DailyUsageSummaryData(
              id: 0, packageName: e.packageName ?? '', day: today,
              foregroundSeconds: 0, launchCount: 0, aggregatedAt: today,
            ),
          );
          final thresholdSec = e.streakBreakThresholdMinutes * 60;
          if (usage.foregroundSeconds <= thresholdSec) {
            succeeded++;
          } else {
            failed++;
          }

        case 1: // Habit
          final ci = checkinsToday.firstWhereOrNull((c) => c.entryId == e.id);
          if (ci == null) {
            pending++;
          } else if (ci.avoided) {
            succeeded++;
          } else {
            failed++;
          }
      }
    }

    yield AvoidedTodaySummary(
      total: entries.length,
      succeeded: succeeded,
      pending: pending,
      failed: failed,
    );
  }
});
```

⚠ **Schedule complexity (D-08 nuance):** The CONTEXT decision says: "If the entry has a schedule (LIST-09), only foreground time **within the active window** counts (mirrors STRK-09)." Phase 5 owns full STRK-09. **Phase 3 simplification recommendation:** treat the threshold as a daily total even for scheduled entries — accept that a "scheduled-only" entry that exceeds threshold outside its window is over-counted as failed today, but the user can tap into `/dashboard` and see what happened. This avoids replicating Phase 5 schedule-window math in Phase 3. **Document this simplification explicitly in the Phase 3 plan.** When STRK-09 lands in Phase 5, `avoidedTodayProvider` gains schedule-aware filtering with no breaking change to its public stream contract.

[CITED: `block_list_table.dart` lines 11-13 — `streakBreakThresholdMinutes` default 5; lines 19-21 — schedule columns]
[CITED: `daily_checkins_table.dart` — `entryId / day / avoided` schema; unique key `(entryId, day)`]

## Cumulative Totals Drift Query

Phase 3 reads `pause_events` aggregate. **Empty-table → 0/0** (Phase 4 is the writer; Phase 3 will start with zero rows).

```dart
// lib/features/dashboard/providers/cumulative_totals_provider.dart
final StreamProvider<CumulativeTotalsSummary> cumulativeTotalsProvider =
    StreamProvider.autoDispose<CumulativeTotalsSummary>((ref) async* {
  final db = ref.watch(databaseProvider);

  // Drift's customSelect supports parameterized aggregates. Watch this single
  // table — emits on every pause_events insert (Phase 4 writes).
  await for (final _ in db.allTablesUpdates([db.pauseEvents])) {
    final row = await db.customSelect(
      'SELECT COUNT(*) AS n, '
      'COALESCE(SUM(cooldown_chosen_seconds), 0) AS s '
      'FROM pause_events '
      'WHERE outcome IN (0, 1)',
    ).getSingle();
    yield CumulativeTotalsSummary(
      launchesBlocked: row.read<int>('n'),
      timeAvoidedSeconds: row.read<int>('s'),
    );
  }
});
```

**Why outcome IN (0, 1):**
- 0 = cooldown-completed (user waited the timer out, app auto-closed) → counts as avoided
- 1 = cancel (user backed out before timer ended) → counts as avoided
- 2 = use-anyway → does NOT count as avoided (per CONTEXT.md `<specifics>`)

**Empty-table behavior:** `COUNT(*)` returns `0`, `COALESCE(SUM(...), 0)` returns `0`. The card renders `"0 launches blocked · 0 m saved"` correctly on day 1.

[CITED: `pause_events_table.dart` lines 12-15 — `cooldownChosenSeconds` (nullable!) and `outcome` columns]

⚠ **Note on `cooldown_chosen_seconds` nullability:** The column is `IntColumn get cooldownChosenSeconds => integer().nullable()()`. The comment says `null = user hit Cancel before picking`. The CONTEXT D-10 SQL `SUM(cooldownChosenSeconds)` is correct because SQLite's `SUM` ignores NULLs natively — but a row with `outcome = 1` (cancel) AND `cooldownChosenSeconds IS NULL` is conceptually "1 launch blocked, 0 seconds avoided." The query handles this correctly: `n` increments, `s` is unchanged. ✓

## Render-Budget Perf-Test Harness (D-20)

**Goal:** Assert `DashboardScreen` first frame renders in < 300 ms against a seeded 30-day × 20-app fixture.

**Pattern (canonical Flutter test as of 2026):**

```dart
// test/perf/dashboard_render_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/dashboard/pages/dashboard_screen.dart';
import 'package:drift/native.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import '../_fixtures/usage_summary_fixture.dart';

void main() {
  testWidgets(
    'DASH-07: DashboardScreen first frame < 300 ms with 30d × 20-app seed',
    (tester) async {
      // Seed an in-memory Drift DB with 30 days × 20 apps = 600 rows.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedUsageSummaryFixture(db, days: 30, apps: 20);

      // Mount Dashboard with the seeded DB.
      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            // Override permissionHealthProvider so the no-permission fallback
            // doesn't trip on a missing platform channel during widget tests.
            // (Phase 2 test harness has the pattern already in
            // test/_fixtures/permission_status_mock.dart.)
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      stopwatch.stop();

      // First frame is rendered (single tester.pumpWidget triggers one frame).
      // Assert wall-clock budget. 300 ms is the DASH-07 success criterion.
      // CI environments are slower than mid-range Android; we keep the
      // budget in absolute terms because the perf-test asserts on a real
      // wall-clock measurement (not a frame-policy proxy).
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(300),
        reason: 'DASH-07: dashboard first frame must render in < 300 ms; '
            'measured ${stopwatch.elapsedMilliseconds} ms with seed fixture',
      );
    },
  );
}
```

**Pattern verification:**

- `Stopwatch + tester.pumpWidget(...)` is the canonical first-frame-time measurement in Flutter test. [CITED: api.flutter.dev/flutter/flutter_test/WidgetTester-class.html — confirms `pumpWidget` "Renders the UI from the given widget"]
- `pumpFrames` is for multi-frame measurements (animations); not what we want for "first paint."
- `pumpAndSettle` is for "wait until animations stop" — overkill for first-frame and would mask the budget.
- `LiveTestWidgetsFlutterBindingFramePolicy` is a binding option for `live_test` (real device) — not applicable to `flutter test` widget tests.

**Caveat:** `flutter test` runs on the host (Linux/macOS), not on Android. The 300 ms budget is asserted in test-runner wall-clock time, which is a **proxy** for mid-range Android performance. This is a known limitation (called out explicitly in CONTEXT D-20: "real-device validation is recorded as a Phase 4-time pre-flight check"). **Phase 3 owns the CI-runnable proxy gate; Phase 4 owns the real-device gate.**

**Reference dataset shape (`usage_summary_fixture.dart`):**

```dart
Future<void> seedUsageSummaryFixture(
  AppDatabase db, {
  int days = 30,
  int apps = 20,
}) async {
  // 5 not-to-do apps + 15 non-list apps = 20 packages.
  final notToDo = [
    ('com.instagram.android', 'Instagram'),
    ('com.zhiliaoapp.musically', 'TikTok'),
    ('com.twitter.android', 'X'),
    ('com.google.android.youtube', 'YouTube'),
    ('com.reddit.frontpage', 'Reddit'),
  ];
  final filler = List.generate(15, (i) => ('com.example.filler$i', 'Filler $i'));
  final allPkgs = [...notToDo, ...filler];

  // Insert block_list rows for the not-to-do 5.
  final now = DateTime.now();
  for (final (pkg, name) in notToDo) {
    await db.into(db.blockList).insert(BlockListCompanion.insert(
      kind: 0,
      packageName: Value(pkg),
      displayName: name,
      createdAt: now,
      updatedAt: now,
    ));
  }

  // Seed 30 days × 20 apps of daily_usage_summary rows.
  final today = localMidnight(now);
  for (var d = 0; d < days; d++) {
    final day = today.subtract(Duration(days: d));
    for (var a = 0; a < apps; a++) {
      final (pkg, _) = allPkgs[a];
      await db.into(db.dailyUsageSummary).insert(
        DailyUsageSummaryCompanion.insert(
          packageName: pkg,
          day: day,
          foregroundSeconds: 60 + (a * 30) + (d * 5), // deterministic
          launchCount: const Value(3),
          aggregatedAt: now,
        ),
      );
    }
  }
}
```

[CITED: `test/data/database/app_database_test.dart` line 11 — `AppDatabase(NativeDatabase.memory())` is the existing in-memory DB pattern]

## Runtime State Inventory

Phase 3 is **not** a rename / refactor / migration phase. **This section is therefore omitted as instructed by Step 2.5.**

For completeness: Phase 3 introduces only new code (UsageApiImpl.kt, UsageRepository, dashboard widgets, etc.) and modifies three existing files (`MainActivity.kt`, `app_router.dart`, `home_screen.dart`, `app_database.dart` for the `daos:` list addition). No string renames, no database migrations, no OS-level state changes.

## Common Pitfalls

### Pitfall 1: Calling `queryUsageStats` on the UI thread

**What goes wrong:** `UsageStatsManager.queryUsageStats(INTERVAL_DAILY, ...)` is documented to drop frames if called from the main thread.
**Why it happens:** Pigeon's default dispatching is on the platform thread (which is the UI thread on Android). Without an explicit `Executor`, even `@async` HostApi methods can block the UI message loop.
**How to avoid:** Always wrap the body in `executor.execute { ... }` (mirror `AppPickerHostImpl.kt` lines 35-58). The `Executor` field must be private and module-singleton-scoped (one per `UsageApiImpl` instance is fine).
**Warning signs:** Frame drops during dashboard open on a low-end device. `flutter test` won't catch this — only real-device profiling will. Phase 3 perf test asserts on widget render time, not platform-thread latency, so this footgun must be prevented at code-review time, not at test-time.

### Pitfall 2: Trusting `getTotalTimeInForeground` as point-in-time

**What goes wrong:** `UsageStats.getTotalTimeInForeground()` lags by ~2 minutes (PITFALLS.md L312). On dashboard refresh at 12:00:01 PM, the row may show 0 s for the app the user JUST closed at 11:59:55 AM.
**Why it happens:** `INTERVAL_DAILY` returns aggregate buckets; the system flushes events into buckets on a delay.
**How to avoid:** Accept the lag. The 5-min staleness budget (D-12) more than absorbs it. Don't try to compensate with `queryEvents` — that's Phase 4/5 territory. **Phase 3 user surface is "show me what I did today" not "show me what I'm doing right now."**
**Warning signs:** User opens Instagram for 30 s, switches to dashboard, sees "0 s on Instagram today" — this is correct system behavior; not a bug.

### Pitfall 3: Locked-device returning `null` from `queryUsageStats`

**What goes wrong:** On Android R+ (API 30+), `queryUsageStats` returns `null` silently when the device is locked (PITFALLS.md L313). Phase 3's minSdk 29 covers this.
**Why it happens:** Privacy hardening — locked-device data is masked.
**How to avoid:** Wrap in `try/catch` and treat `null` as `emptyList()`. The `UsageApiImpl.kt` skeleton above does this. Returning empty (vs. throwing) lets the dashboard render the cached state instead of an error.
**Warning signs:** Dashboard shows 0 entries on first open of the day — could be locked-device-during-aggregation; check for stale `aggregatedAt` and retry on next foreground.

### Pitfall 4: Querying 30 days × 20 apps from `queryUsageStats` on every monthly view

**What goes wrong:** PITFALLS.md L329: 30+ second jank after 30 days of usage.
**Why it happens:** Each call to `queryUsageStats(INTERVAL_DAILY, t0, t1)` does a system-wide IPC + bucket scan; cost scales with range × installed-app count.
**How to avoid:** **Never call `usageApi.queryRange` for ranges > "today" or "yesterday backfill."** Monthly view reads only `daily_usage_summary` via Drift. DASH-04 mandates this; Phase 3 enforces it by NOT exposing a `queryRange` for arbitrary date ranges from the dashboard layer (`UsageRepository.refreshIfStale()` is the only caller, and it's hardcoded to "today" or "yesterday-rollover backfill").
**Warning signs:** Dashboard cold-start > 1 s on monthly view — check for an accidental `usageApi.queryRange(today.subtract(Duration(days: 30)), now)` call.

### Pitfall 5: Drift unique-key conflict on past-day backfill

**What goes wrong:** Calling `into(dailyUsageSummary).insert(...)` (without `OnConflictUpdate`) for a row that already exists throws a SQLite UNIQUE constraint violation.
**Why it happens:** `daily_usage_summary` has unique key `(packageName, day)`. Re-running aggregation mid-day or after a backfill triggers conflicts.
**How to avoid:** Always use `into(dailyUsageSummary).insertOnConflictUpdate(...)`. Phase 2 already uses this idiom in `BlockListDao.insertMany` for batch seed (LIST-07). Idempotent by construction.
**Warning signs:** Dashboard refresh fails with a Drift `SqliteException`; check the call site uses `insertOnConflictUpdate`.

### Pitfall 6: `cumulativeTotalsProvider` over-counts "use anyway"

**What goes wrong:** A planner reads CONTEXT D-10 too quickly and writes `WHERE outcome IS NOT NULL` instead of `WHERE outcome IN (0, 1)`. Now the cumulative totals include "use anyway" rows.
**Why it matters:** "Use anyway" means the user did NOT avoid — counting it as avoided would be a credibility-breaking bug ("the app says I avoided 200 minutes, but I actually opened those apps anyway").
**How to avoid:** Stick to `outcome IN (0, 1)` literally as in CONTEXT.md `<specifics>`. Document the outcome enum in the DAO method's docstring.
**Warning signs:** Manual UAT: insert a `pause_events` row with `outcome = 2` (use-anyway), reload home, verify the cumulative card did NOT increment.

### Pitfall 7: Refresh storms from chained provider invalidation

**What goes wrong:** `dashboardRowsProvider` watches both `_entriesProvider` and `_usageProvider`. If both Drift streams emit on the same write batch, the join recomputes twice in quick succession.
**Why it happens:** Drift's `.watch()` emits on every transaction commit. A batch insert of 30 daily_usage_summary rows can trigger 30 emissions if not batched.
**How to avoid:** `UsageRepository.refreshIfStale()` should wrap its writes in a single Drift `transaction` block — Drift batches the watcher emission. Mirrors `BlockListDao.insertMany` lines 42-48 which uses `await batch((b) { ... })`.
**Warning signs:** Dashboard widget rebuilds excessively visible in `flutter test` debug output or Flutter DevTools.

### Pitfall 8: HealthCheckBanner double-rendering on `/dashboard`

**What goes wrong:** Phase 2 mounts `HealthCheckBanner` only on `HomeScreen`. If the user taps a home card → goes to `/dashboard` while permission is offline, the banner doesn't appear by default — but D-13 requires it.
**Why it happens:** `HealthCheckBanner` is mounted inline in `HomeScreen`'s `Column`, not as a global router-level widget.
**How to avoid:** Re-mount the same `HealthCheckBanner` widget at the top of `DashboardScreen`'s body, gated on `permissionHealthProvider.usageAccess == false`. Reuses the exact widget — no duplication. (Or, alternatively, lift the banner to a router-level `ShellRoute` — but that's a larger Phase 2 refactor and out of scope.)
**Warning signs:** User revokes Usage Access from Settings, returns to app, taps a home card → dashboard renders empty without explanation.

### Pitfall 9: Pigeon regen drift introducing diff noise

**What goes wrong:** A planner runs `dart run pigeon --input pigeons/usage_api.dart` "to be safe" and the regenerated `.g.dart` / `.g.kt` files differ from the committed versions in copyright lines, formatting, or codec versioning, churning the diff.
**Why it happens:** Pigeon code-gen is reproducible per Pigeon version, but cosmetic markers can shift across patch versions (e.g., `26.3.4` → `26.3.5`).
**How to avoid:** Don't regenerate. The existing `usage_api.g.dart` (verified 2026-05-07, generated by Pigeon 26.3.4 per its `// Autogenerated from Pigeon (v26.3.4)` line) and `UsageApi.g.kt` (same) are aligned. Phase 3 implements the impl, not the bindings.
**Warning signs:** PR diff shows changes in `lib/platform/usage_api.g.dart` or `android/.../UsageApi.g.kt` — those should be untouched in Phase 3.

## Code Examples

### Example 1: Verified Pigeon HostApi `@async` shape

[CITED: `pigeons/usage_api.dart`]
```dart
@HostApi()
abstract class UsageApi {
  @async
  List<UsagePackageStat> queryRange(int startEpochMs, int endEpochMs);
}
```

The `@async` annotation generates the Kotlin signature:
```kotlin
fun queryRange(
  startEpochMs: Long,
  endEpochMs: Long,
  callback: (Result<List<UsagePackageStat>>) -> Unit,
)
```

[CITED: `android/.../UsageApi.g.kt` lines 266 — verified the generated callback shape]

### Example 2: Verified AppOps gate

[CITED: `android/.../PermissionStatusApiImpl.kt` lines 29-41]
```kotlin
override fun isUsageAccessGranted(callback: (Result<Boolean>) -> Unit) {
    try {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName,
        )
        callback(Result.success(mode == AppOpsManager.MODE_ALLOWED))
    } catch (e: Throwable) {
        callback(Result.failure(e))
    }
}
```

The same `unsafeCheckOpNoThrow(OPSTR_GET_USAGE_STATS, ...)` call goes inside `UsageApiImpl.queryRange` BEFORE the `queryUsageStats` call (D-03). On `MODE_ALLOWED != mode`, throw `UsageApiError("USAGE_ACCESS_DENIED", ...)` instead of attempting the query.

### Example 3: Verified Drift watch + customSelect pattern

[CITED: `lib/data/database/daos/block_list_dao.dart` lines 17-28 — `select(...).watch()` shape]
[CITED: `test/data/database/app_database_test.dart` lines 19-25 — `customSelect(...)` shape for arbitrary aggregates]

### Example 4: Verified hand-written `StreamProvider.autoDispose` shape

[CITED: `lib/features/home/pages/home_screen.dart` lines 14-18]
```dart
final StreamProvider<List<BlockListData>> _homeEntriesProvider =
    StreamProvider.autoDispose<List<BlockListData>>((ref) {
  final repo = ref.watch(blockListRepoProvider);
  return repo.watchAll();
});
```

Phase 3 shape:
```dart
final StreamProvider<List<DailyUsageSummaryData>> _usageRowsProvider =
    StreamProvider.autoDispose.family<List<DailyUsageSummaryData>, DashboardRange>(
  (ref, range) {
    final repo = ref.watch(usageRepositoryProvider);
    final (start, end) = resolveRange(range, DateTime.now());
    Future.microtask(repo.refreshIfStale);
    return repo.watchRange(start, end);
  },
);
```

### Example 5: Verified `WidgetsBindingObserver` resume pattern

[CITED: Phase 2 `lib/features/health/health_lifecycle_observer.dart` (referenced by `permissionHealthProvider` doc-comment at line 33)]

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    ref.read(usageRepositoryProvider).refreshIfStale();
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| MethodChannel hand-written `invokeMethod('queryRange', {...})` | Pigeon-typed `@HostApi` with `@async` | Pigeon stable since 2022 | Compile-time type checking; eliminated `MissingPluginException` class of bugs |
| 1-min foreground service polling for "live usage" | Lazy-on-open + 5-min cache | Documented in PITFALLS.md (#3 anti-pattern) | Battery saved; Standby Bucket pressure avoided |
| `getRunningTasks()` for foreground app | `UsageStatsManager.queryUsageStats` (history) + AccessibilityService (live, Phase 4) | API 21 deprecation | Required for Play Store + privacy |
| `INTERVAL_BEST` for "let the system pick" | `INTERVAL_DAILY` for daily-bucketed dashboard | Phase 3 design choice | Predictable bucket boundaries; matches "today / week / month" UX |
| `fl_chart` / `syncfusion_flutter_charts` for one-bar-per-row visuals | `LinearProgressIndicator` Material 3 widget | 2025 ecosystem matures | Saves ~100 KB APK + 200+ lines of plumbing |
| `@riverpod` codegen | Hand-written `Provider<>` | Phase 1 deviation (Plan 01-01) | Sidesteps `analyzer + meta + Pigeon` version conflict |

**Deprecated/outdated:**
- `getRunningTasks()` — deprecated since API 21; returns only caller's own tasks on modern Android.
- `usage_stats` Flutter package (1.3.1) — last published 13 months ago, "unverified uploader." Phase 3 doesn't need it; we have direct Pigeon channel access.
- `flutter_overlay_window` — Phase 1 architecture decision rejected SYSTEM_ALERT_WINDOW overlays. Phase 3 doesn't touch this either.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SQLite's automatic UNIQUE INDEX on `(packageName, day)` is fast enough for 30-day × 50-app monthly query (no explicit `CREATE INDEX` needed) | Pattern 2 (Drift upsert) | If wrong: monthly view jank after ~50 entries × 30 days = 1500 rows. Mitigation: Phase 3 perf test (D-20) catches it on the seeded 600-row fixture. If perf test fails, add `CREATE INDEX idx_usage_day ON daily_usage_summary(day)` (additive, no migration). |
| A2 | Dart `Duration(days: 6/29)` arithmetic is "DST-safe-enough" for Phase 3 dashboard ranges (not for streak-day boundaries — that's STRK-08) | Local Timezone Day-Boundary Computation | If wrong: on DST transition days the rolling 7-day or 30-day window edge slides by 1 hour, which is invisible in the dashboard UI. Phase 5 STRK-08 owns full DST rigor. |
| A3 | `flutter test` runner wall-clock can serve as a proxy for "mid-range Android first frame < 300 ms" via `Stopwatch + tester.pumpWidget` | Render-Budget Perf-Test Harness | If wrong: CI green doesn't guarantee real-device green. Mitigation: CONTEXT D-20 explicitly defers real-device validation to Phase 4's first task (re-measure on Pixel emulator used for Phase 2 UAT). |
| A4 | Pigeon `@async` callback dispatched from the Kotlin `Executors.newSingleThreadExecutor()` reaches Dart `Future.then` on the Dart UI isolate without an explicit handover (the BinaryMessenger handles it) | Pattern 1 (UsageApiImpl skeleton) | If wrong: a UI-isolate race could surface as a "Future never completed" hang. Mitigation: Phase 2's `AppPickerHostImpl.kt` uses the identical pattern in production already (verified 2026-05-07) — no Phase 2 reports of this issue. |
| A5 | `INTERVAL_DAILY` `UsageStats` rows do not contain a meaningful `launchCount` for daily-bucket aggregation; Phase 3 fills `launchCount: 0` | Pattern 1 skeleton | If wrong: the `daily_usage_summary.launchCount` column will read as 0 forever. Mitigation: Phase 3 doesn't surface launchCount in any UI — it's stored for Phase 5's potential STRK use. If Phase 5 needs accurate launch counts, switch to `queryEvents` then. |
| A6 | The CONTEXT D-08 nuance "If the entry has a schedule, only foreground time within the active window counts" can be **deferred** to Phase 5 STRK-09 — Phase 3 thresholds against the daily total even for scheduled entries | "Avoided today" Drift Query | If wrong: scheduled entries that exceed threshold outside their window will be over-counted as failed today. Mitigation: rare in practice (a user with a schedule has, by definition, declared they only want to avoid the app inside the window — usage outside is by their design "OK"). Document in plan; revisit in Phase 5 STRK-09 with no breaking interface change. |

**If this table is empty:** Most claims in this research were verified or cited from the codebase. The 6 assumptions above are honest residual uncertainties that the planner and `/gsd-discuss-phase` follow-ups should treat as low-priority confirmations (not blockers).

## Open Questions (RESOLVED)

1. **Schedule-aware "Avoided today" thresholding (per A6):** RESOLVED.
   - What we know: D-08 says "only foreground time within the active window counts (mirrors STRK-09)." Phase 5 STRK-09 owns the strict computation.
   - What's unclear: Does Phase 3 need to ship the schedule-aware version of the query, or can it ship the simpler "daily-total threshold" version with a documented Phase 5 upgrade path?
   - **Resolution:** Phase 3 ships the simpler daily-total-threshold version. Schedule-window filtering deferred to Phase 5 STRK-09 with no public-stream interface change. Both 03-CONTEXT.md `<specifics>` and the planner's plan acceptance criteria explicitly document the A6 carve-out and the Phase 5 upgrade path. The `avoidedTodayProvider` docstring cites this as an A6 simplification.

2. **Where does `HealthCheckBanner` mount on `/dashboard`?** RESOLVED.
   - What we know: D-13 says the dashboard reuses the banner with the same copy.
   - What's unclear: Is it a per-page mount (in `DashboardScreen`'s body) or a global lift to `ShellRoute`?
   - **Resolution:** Per-page mount. ShellRoute lift is a cross-cutting Phase-2 refactor and out of Phase 3 scope. Two banner instances (one in `HomeScreen`, one in `DashboardScreen`) is acceptable duplication for now.

3. **Does `dashboardRangeProvider` survive a hot-reload in dev?** RESOLVED.
   - What we know: `StateProvider<DashboardRange>` is in-memory; default = `Day`.
   - What's unclear: Whether dev-loop friction (resetting to Day on every hot reload) is annoying enough to justify a `shared_preferences` write.
   - **Resolution:** D-05 explicitly says "no `shared_preferences` write — open-on-Day each cold start matches user expectation." Honor the decision. Hot-reload reset is a dev-only cost.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All Dart code | ✓ | 3.41.x | — |
| Java 17 / JDK | Android build | ✓ | (project standard) | — |
| Android SDK platform-36 | `compileSdk = 36` | ✓ | (project standard) | — |
| Android emulator (Pixel running stock Android 16) | UAT + Phase 4 perf re-measurement | ✓ | (Phase 2 UAT signed off on this) | — |
| `drift` 2.33 | DAO codegen | ✓ | 2.33.0 [VERIFIED: pubspec.lock] | — |
| `drift_dev` 2.33 | DAO codegen (`build_runner build`) | ✓ | 2.33.0 [VERIFIED: pubspec.lock] | — |
| `pigeon` 26.3.4 (dev) | NOT regenerated in Phase 3 | ✓ | 26.3.4 [VERIFIED: pubspec.lock] | — |
| `flutter_riverpod` 3.3.1 | All providers | ✓ | 3.3.1 [VERIFIED: pubspec.lock] | — |
| `mocktail` 1.0.5 (dev) | `MockUsageApi`, `MockDailyUsageSummaryDao` | ✓ | 1.0.5 [VERIFIED: pubspec.lock] | — |
| `intl` 0.20.2 | `DateFormat`, duration formatting | ✓ | (in pubspec.yaml line 26) | — |
| Real Android device (Xiaomi/Samsung overnight) | NOT required for Phase 3 (Phase 4 REL-04 gate) | — | — | Phase 3 is simulator-friendly by design — no fallback needed. |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

**All Phase 3 work can proceed against the existing toolchain.** No new packages, no new SDK installs.

## Validation Architecture

> Project config has `workflow.nyquist_validation: true`. Including this section.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter SDK) + `mocktail` 1.0.5 |
| Config file | `analysis_options.yaml` (lints) + Flutter SDK defaults (test discovery via `test/` convention) |
| Quick run command | `flutter test test/perf/dashboard_render_test.dart -r expanded` (single perf test) |
| Full suite command | `flutter test` (Phase 2 baseline: 124 passing, 0 skipped; Phase 3 must add tests and keep all green) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DASH-01 | UsageApi runs on background Executor; AppOps gate; null-on-locked-device | unit (Kotlin: manual code review against PLAY-02 + PITFALLS.md anti-pattern #3); platform (Dart side: mock UsageApi via `MockUsageApi extends Mock implements UsageApi`) | `flutter test test/platform/usage_api_test.dart -x` | ❌ Wave 0 |
| DASH-02 | Daily view shows per-app screen time + not-to-do highlighted (4dp accent + primary color) | widget | `flutter test test/features/dashboard/dashboard_screen_test.dart -x` + `dashboard_row_test.dart -x` | ❌ Wave 0 |
| DASH-03 | Weekly view aggregates last 7 days from daily_usage_summary | widget + integration (in-memory Drift) | `flutter test test/features/dashboard/dashboard_screen_test.dart -x` (range parameterized) | ❌ Wave 0 |
| DASH-04 | Monthly view reads pre-aggregated table only (NEVER calls usageApi.queryRange for 30 days) | unit (`UsageRepository` test asserts no Pigeon call when `range == month`) | `flutter test test/data/repositories/usage_repository_test.dart -x` | ❌ Wave 0 |
| DASH-05 | "Avoided today" card: succeeded/pending/failed counts | widget + provider unit | `flutter test test/features/dashboard/avoided_today_card_test.dart -x` | ❌ Wave 0 |
| DASH-06 | Cumulative totals: COUNT + SUM over outcome IN (0,1) | widget + provider unit (verify outcome=2 NOT counted) | `flutter test test/features/dashboard/cumulative_totals_card_test.dart -x` | ❌ Wave 0 |
| DASH-07 | First frame < 300 ms with 30d × 20-app fixture | perf | `flutter test test/perf/dashboard_render_test.dart -x` | ❌ Wave 0 |

**Cross-cutting tests (must remain green):**

| Test | What it gates | Phase 3 impact |
|------|---------------|---------------|
| `test/policy/play_invariants_test.dart` (8 invariants) | PLAY-02..06 + BIND_DEVICE_ADMIN + forbidden tokens | New `UsageApiImpl.kt`, new `lib/features/dashboard/`, new `lib/data/repositories/usage_repository.dart` MUST not contain `performAction`/`performGlobalAction`/`dispatchGesture`/`QUERY_ALL_PACKAGES`/`SYSTEM_ALERT_WINDOW`/`BIND_DEVICE_ADMIN`/parental-control tokens |
| `test/data/database/app_database_test.dart` | Schema v1/v2 round-trip | Phase 3 adds `daos: [..., DailyUsageSummaryDao]` — verify the test still asserts schemaVersion = 2 (no bump) |
| `test/data/database/migration_v1_to_v2_test.dart` | v1→v2 migration | No changes; Phase 3 doesn't touch migrations |

### Sampling Rate

- **Per task commit:** `flutter test` (full suite — < 30 s on dev machine for the current 124-test baseline; Phase 3 adds ~12-15 tests)
- **Per wave merge:** `flutter test && dart analyze` (0 errors / 0 warnings; pre-existing 18 pigeon/mock infos grandfathered)
- **Phase gate:** Full suite green + `dart analyze` clean + `flutter build apk --debug` succeeds + `play_invariants_test.dart` 8/8 green

### Wave 0 Gaps

- [ ] `test/_fixtures/usage_summary_fixture.dart` — 30-day × 20-app seeder for the perf test and widget tests
- [ ] `test/perf/dashboard_render_test.dart` — DASH-07 first-frame < 300 ms gate
- [ ] `test/data/repositories/usage_repository_test.dart` — refreshIfStale logic + DASH-04 invariant (no Pigeon for 30-day)
- [ ] `test/platform/usage_api_test.dart` — Dart-side `UsageApi` mock harness (`MockUsageApi extends Mock implements UsageApi`)
- [ ] `test/features/dashboard/dashboard_screen_test.dart` — D/W/M segmented control + range switch
- [ ] `test/features/dashboard/dashboard_row_test.dart` — bar-fill + 4dp accent for not-to-do
- [ ] `test/features/dashboard/avoided_today_card_test.dart` — counts (succeeded/pending/failed)
- [ ] `test/features/dashboard/cumulative_totals_card_test.dart` — outcome-2 not counted
- [ ] `test/features/dashboard/period_total_ribbon_test.dart` — collapse to not-to-do total
- [ ] Framework install: NONE — `mocktail` and `flutter_test` already in dev dependencies

## Security Domain

> Project default: `security_enforcement` is enabled (key absent in config = enabled). Including this section.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | v1 has no accounts (PROJECT.md "no backend in v1") |
| V3 Session Management | no | No sessions; on-device only |
| V4 Access Control | yes (locally — between user and OS-level data) | AppOpsManager.OPSTR_GET_USAGE_STATS gate. App never reads usage data without OS-granted permission. |
| V5 Input Validation | yes (Pigeon channel boundary + Drift query parameters) | Pigeon: typed channel — `int startEpochMs / int endEpochMs` are statically typed at compile time; no string parsing. Drift: parameterized queries via `customSelect` and DAO companions; never string-interpolation SQL. |
| V6 Cryptography | no | Phase 3 doesn't introduce new crypto; project-wide on-device data is unencrypted (this matches Phase 1 / Phase 2 stance — `android:allowBackup="false"` is the trust boundary). |
| V8 Data Protection | yes | All usage data stays on-device. No telemetry, no FCM, no analytics SDK. Privacy stance verified by `play_invariants_test.dart` v1-scope token sweep. |
| V11 Business Logic | yes | "Avoided today" math, cumulative SUM, threshold logic — all unit-tested. Outcome enum (0/1/2) documented to prevent off-by-one or missing-cases. |
| V14 Configuration | yes | No new permissions in Phase 3. Manifest unchanged. `play_invariants_test.dart` enforces invariants. |

### Known Threat Patterns for Flutter + Android + UsageStatsManager

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via `customSelect` string-interpolation | Tampering | Phase 3 uses ONE `customSelect` (cumulative totals) with NO interpolation — the WHERE clause `outcome IN (0, 1)` is hardcoded literal SQL. All other queries use Drift's typed DAO methods. ✓ |
| Cross-process race on SQLite (Kotlin reading while Dart writes) | Tampering | Phase 3 maintains single-writer = Dart invariant (ARCHITECTURE.md anti-pattern #5). Kotlin `UsageApiImpl` does NOT touch SQLite — it only reads system services and returns Pigeon-typed data. ✓ |
| Untrusted intent receiver (the new `/dashboard` route) | Spoofing | `/dashboard` is a Flutter-internal GoRouter route — there is NO new `<intent-filter>` in AndroidManifest.xml. The route is unreachable from outside the app process. ✓ |
| Pigeon channel data tampering | Tampering | Pigeon uses `BinaryMessenger` over `MessageChannel` — same-process, in-memory IPC. Not network-exposed. Type-checked at compile time. ✓ |
| Sensitive data in logcat | Information Disclosure | `UsageApiImpl.kt` skeleton above does NOT log package names or foreground times. Phase 1 + 2 maintain the same discipline. ✓ |
| Backup leakage of `daily_usage_summary` | Information Disclosure | Phase 1's `android:allowBackup="false"` prevents Google Drive auto-backup. Verified by Phase 2. Phase 3 inherits. ✓ |
| Battery drain via continuous polling | Denial of Service (resource) | Lazy-on-open + 5-min cache. NO foreground service. NO WorkManager periodic. ✓ (D-14 explicit) |
| Play Store policy violation (autonomous a11y action) | Compliance | Phase 3 does NOT touch AccessibilityService. Phase 4 owns that. `play_invariants_test.dart` PLAY-02 absence-grep gates new Phase 3 Kotlin/Dart files. ✓ |
| `QUERY_ALL_PACKAGES` accidentally introduced | Compliance | `play_invariants_test.dart` PLAY-04 absence-grep blocks at next test run. ✓ |
| `SYSTEM_ALERT_WINDOW` accidentally introduced | Compliance | `play_invariants_test.dart` PLAY-05 absence-grep blocks at next test run. ✓ |

## Sources

### Primary (HIGH confidence)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/STACK.md` — UsageStatsManager / Pigeon / Drift / Riverpod stack pins (Phase 1 research)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` Pattern 3 (lines 209–224) — load-bearing for D-12, D-14
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/PITFALLS.md` Pitfall #3 (lines 312–315) + Pitfall #6 (lines 327–333) — load-bearing for D-04, D-12, D-14
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/SUMMARY.md` lines 88, 108, 119 — Phase 3 framing
- `/Users/jintanakhomwong/projects/not-to-do-list/pigeons/usage_api.dart` — UsageApi `@HostApi` schema
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/platform/usage_api.g.dart` — Pigeon-generated Dart binding (Pigeon v26.3.4)
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt` — Pigeon-generated Kotlin shim
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt` — exemplar Kotlin Pigeon impl pattern (Executor + AppOps + UsageStatsManager)
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt` — exemplar AppOps gate pattern
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/daily_usage_summary_table.dart` — Phase 3 write target
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/pause_events_table.dart` — Phase 3 read aggregate
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/home/pages/home_screen.dart` — Phase 3 modification target + StreamProvider exemplar
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/list/widgets/block_mode_segmented.dart` — SegmentedButton exemplar
- `/Users/jintanakhomwong/projects/not-to-do-list/test/policy/play_invariants_test.dart` — 8 invariants Phase 3 must keep green
- `/Users/jintanakhomwong/projects/not-to-do-list/pubspec.lock` — verified package versions (drift 2.33.0, pigeon 26.3.4, flutter_riverpod 3.3.1, go_router 17.2.3, mocktail 1.0.5)

### Secondary (MEDIUM confidence)
- https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html — `pumpWidget` / `pumpFrames` / `pumpAndSettle` semantics (cited via WebFetch 2026-05-07)
- https://developer.android.com/reference/android/app/usage/UsageStatsManager — UsageStatsManager API surface (cited indirectly via Phase 1 STACK.md and PITFALLS.md, which were verified against this URL during their original research)

### Tertiary (LOW confidence — assumptions logged for plan-checker)
- A1: SQLite implicit unique-key index sufficient for monthly-view performance — perf test (D-20) catches if wrong
- A2: `Duration(days: 6/29)` arithmetic DST-safe-enough for Phase 3 — Phase 5 STRK-08 owns rigorous handling
- A3: `flutter test` wall-clock as proxy for mid-range Android render time — Phase 4 first task validates on real emulator
- A6: D-08 schedule-aware "Avoided today" thresholding can be deferred to STRK-09 — Phase 5 upgrade path

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every package version verified against actual `pubspec.lock`; no new dependencies needed.
- Architecture: HIGH — every pattern has a Phase 1 or Phase 2 exemplar with file/line citations.
- Pitfalls: HIGH — anchored to the project's own PITFALLS.md and ARCHITECTURE.md research, plus codebase verification.
- Render-budget perf-test: MEDIUM — `Stopwatch + tester.pumpWidget` is canonical, but the host-vs-Android wall-clock proxy is a known limitation explicitly accepted by D-20.
- "Avoided today" schedule-aware logic: MEDIUM — A6 assumption that simplification is acceptable for Phase 3.

**Research date:** 2026-05-07
**Valid until:** 2026-06-07 (30 days for stable patterns + already-pinned dependencies)
