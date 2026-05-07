# Phase 3: Screen-Time Dashboard — Context

**Gathered:** 2026-05-07
**Status:** Ready for planning
**Source:** /gsd-discuss-phase 3 (executed in `--auto` mode under runtime auto-mode directive — Claude auto-selected the recommended option for every gray area; see `03-DISCUSSION-LOG.md` for the per-question audit trail)

<domain>
## Phase Boundary

Phase 3 delivers the user's first **visible value** after install/onboarding and validates the **Pigeon channel pattern on a low-risk surface** before Phase 4's blocker depends on it.

Three concrete deliverables (DASH-01..07):

1. **The Pigeon `usageApi.queryRange()` channel goes live.** Phase 1 shipped the stub; Phase 3 lights it up. Kotlin `UsageApi.g.kt` impl wraps `UsageStatsManager.queryUsageStats(INTERVAL_DAILY, …)` on a background `Executor` (never UI thread). Returns `List<UsagePackageStat>` (packageName / foregroundSeconds / launchCount) — the existing Pigeon-typed class, no schema change.
2. **A Day / Week / Month dashboard** at `/dashboard`. Reads from a Drift cache (`daily_usage_summary`, schema already exists from Phase 1). Today's row is soft-cached for 5 minutes; past days are immutable. All apps with foreground time are listed; **not-to-do entries are visually highlighted** (DASH-02). Renders in <300 ms on a mid-range device (DASH-07).
3. **Two home cards** above the existing unified list: **"Avoided today"** (DASH-05 — per-entry success summary) and **"Cumulative totals"** (DASH-06 — total launches blocked + total time avoided, all-time). Tap on either card opens the dashboard.

Phase 3 does NOT implement: launch interception (Phase 4 wedge), pause-screen UI (Phase 4), pause-event writing (Phase 4 — Phase 3 reads `pause_events` for the cumulative card but never writes), the streak engine (Phase 5), daily reminder notifications (Phase 5), or settings/export/theme switching (Phase 6). The `daily_usage_summary` table written in Phase 3 is the same table Phase 5 reads for streak threshold checks (STRK-02).

</domain>

<v1_scope_carryforward>
## v1 Product Scope — locked, carried forward from PROJECT.md (2026-05-05) and 02-CONTEXT.md

Per the v1 positioning locked 2026-05-05 in `7119f85`, downstream agents MUST respect:

**In scope (v1, Phase 3):**
- Adult self-control only — single-user model
- Read-only dashboard surface — no write ops to system settings, no telemetry, no FCM
- 100% on-device: every byte stays in the local Drift DB (`daily_usage_summary`, `pause_events`)
- Pigeon-typed `UsageApi` only — no hand-rolled MethodChannels, no `flutter_overlay_window`, no `SYSTEM_ALERT_WINDOW`, no `QUERY_ALL_PACKAGES`
- Existing Phase 2 manifest invariants stay intact — `test/policy/play_invariants_test.dart` (8 absence-grep policy tests) must remain green at phase exit

**Explicitly NOT in v1 (Phase 3) — do not absorb during planning:**
- Real-device overnight survival test as exit gate — that's Phase 4's gate (REL-04). Phase 3 is **simulator-friendly** by design (research/SUMMARY.md "low-risk first integration").
- WorkManager periodic aggregation — defer to Phase 5 (NOTF-04 + STRK-05 already need WorkManager; Phase 3 is lazy-on-open only)
- Per-app drill-down screen, time-of-day breakdown, week-over-week comparison, calendar heatmap — DIFF-02 / DIFF-05 / DIFF-04 are v1.x deferred per REQUIREMENTS.md
- Chart libraries (`fl_chart`, `syncfusion_flutter_charts`, etc.) — out of scope (free/OSS budget + minimum-code principle); v1 ships a pure-widget bar-fill row
- Background isolate / dataSync foreground service for aggregation — research-anti-pattern (#3); Phase 3 stays lazy-evaluated on open
- Data export of usage rows — that's Phase 6 (SETT-01)

If gray areas surface during research or planning that would require any of the above, defer to a later phase — DO NOT silently add them.
</v1_scope_carryforward>

<decisions>
## Implementation Decisions

### Pigeon channel + Kotlin impl (D-01..04)

- **D-01 — Channel:** Light up the existing `pigeons/usage_api.dart` `@HostApi` (already scaffolded Phase 1). No new Pigeon classes; reuse `UsagePackageStat { packageName, foregroundSeconds, launchCount }` verbatim. Regenerate via `dart run pigeon --input pigeons/usage_api.dart` if needed.
- **D-02 — Kotlin Executor:** `Executors.newSingleThreadExecutor()` (background). `UsageStatsManager.queryUsageStats(INTERVAL_DAILY, startEpochMs, endEpochMs)` runs there. Pigeon's `@async` annotation maps cleanly to a Dart `Future`. Never call from the UI thread (PITFALLS.md anti-pattern #3, FEATURES.md L51).
- **D-03 — Permission check on Kotlin side:** Before calling `queryUsageStats`, check `AppOpsManager.checkOpNoThrow(OPSTR_GET_USAGE_STATS, …) == MODE_ALLOWED`. If denied, throw `UsageApiError("USAGE_ACCESS_DENIED", …)`. Dart catches and routes to the no-permission fallback (D-13).
- **D-04 — Locked-device behavior:** Catch `SecurityException` and null returns from `queryUsageStats` (PITFALLS.md L313 — Android R+ returns null silently when device is locked). Treat as "data unavailable, retry later" — return an empty list rather than crashing.

### Dashboard navigation shape (D-05)

- **D-05 — Segmented control at top of `DashboardScreen`:** `Day | Week | Month`. Reuses the same Material 3 `SegmentedButton` widget pattern Phase 2 used for `BlockModeSegmentedControl` in `lib/features/list/widgets/block_mode_segmented.dart`. Selection persists in a `StateProvider<DashboardRange>` for the session only (no `shared_preferences` write — open-on-Day each cold start matches user expectation). NOT scrollable cards, NOT a hamburger picker, NOT bottom-tabs.

### "Highlighted" treatment for not-to-do entries (D-06..07)

- **D-06 — Visual treatment:** Not-to-do entries get a 4-dp left accent border in `colorScheme.primary` (forest-green seed) + their app icon at 100% opacity. Non-not-to-do entries render with NO accent border + their app icon at 60% opacity (grey-on-grey). The bar-fill (D-15) uses `colorScheme.primary` for not-to-do rows and `colorScheme.outlineVariant` for others. Single visual delta drives all three list/chart/card surfaces.
- **D-07 — Sort order in views:** Not-to-do entries pinned to the top of every D/W/M list; below them, all other foreground apps sorted by foreground_seconds desc. Threshold: only show non-not-to-do apps with ≥60s foreground in the period (filters out trivial background ticks).

### "Avoided today" definition (D-08..09)

- **D-08 — Per-entry success rule (today):**
  - **Apps:** today's `daily_usage_summary.foregroundSeconds` for the entry's `packageName` ≤ `block_list.streakBreakThresholdMinutes × 60` (default 5 min × 60 = 300 s). If the user opened the app for 0 s, that counts as success. If the entry has a schedule (LIST-09), only foreground time **within the active window** counts (mirrors STRK-09).
  - **Habits:** today's `daily_checkins` row exists with `avoided = true`. If no row exists yet for today, the habit is "Pending today" (counts as neither success nor failure). Habits without a check-in are never auto-credited.
  - **Hard-block entries (LIST-08):** same as soft — threshold-based — because Phase 3 doesn't yet have pause-event data (Phase 4 writes it). The hard/soft distinction matters at the pause screen (Phase 4), not the dashboard.
- **D-09 — Card copy:** `"Avoided today"` headline + `"{X of Y entries succeeded today"` subtitle (small grey text). If Y = 0 (empty list), show `"No entries yet"` and route to `/list/add-app` on tap. If usage access is offline, show `"Tracking is offline — tap to fix"` (reuses the Phase 2 health-banner copy and routing).

### Cumulative totals scope + storage (D-10..11)

- **D-10 — All-time, derived on read:** No denorm counter columns. `total_launches_blocked` = `COUNT(pause_events WHERE outcome IN (0=cooldown-completed, 1=cancel))`. `total_time_avoided_seconds` = `SUM(cooldownChosenSeconds)` for the same rows. Pure SQL aggregate, runs on every home open. Phase 3 is **read-only** on `pause_events` — Phase 4 is the writer (PauseActivity).
- **D-11 — Card copy:** `"Total avoided"` headline + `"{N} launches blocked · {H}h {M}m saved"` subtitle. Phase 3 starts at 0 / 0 m because `pause_events` is empty until Phase 4 ships; that is the **expected and correct** state. The card still renders ("0 launches blocked · 0 m saved") as a forward-looking promise to the user.

### Today's data freshness + refresh trigger (D-12)

- **D-12 — 5-minute soft-cache for today; immutable past:**
  - **Today's row:** When `DashboardScreen` mounts OR `AppLifecycleState.resumed` fires, check today's `daily_usage_summary.aggregatedAt`. If `now - aggregatedAt > 5m` (or no row exists), call `usageApi.queryRange(midnight_today_local, now)`, upsert today's row(s), then bind the UI to the Drift stream. If `aggregatedAt` is fresh (≤5 m old), bind directly without calling Kotlin.
  - **Past days:** Read-only. Never re-queried. The first time the user opens the dashboard after a calendar-day rollover, lazily backfill yesterday's row(s) using `queryRange(midnight_yesterday, midnight_today)`. After that, yesterday is also immutable.
  - **Pull-to-refresh:** Yes — a `RefreshIndicator` wraps the list. Pull bypasses the 5-min cache and hits Kotlin immediately. Reuses Material 3 default UX.
  - **Time anchor:** Local timezone, NOT UTC. "Today" uses `DateTime.now()` floored to local midnight. (DST handling lives in Phase 5's streak engine — Phase 3 doesn't compute streak day boundaries.)

### No-permission fallback (D-13)

- **D-13 — Last-cached snapshot + sticky banner:** When `permissionHealthProvider.usageAccessGranted == false`, the dashboard renders the most recent `daily_usage_summary` rows (could be empty on first run, or stale by hours/days) with a sticky `HealthCheckBanner` at the top using the literal copy `"Tracking is offline — tap to fix"`. Tap routes to `/onboarding/permissions/usage-access` (the existing Phase 2 step, re-entered from outside the funnel — same code path as the Phase 2 health-banner re-walk). The dashboard never shows an empty error screen — it always renders SOMETHING (cached, or "no data yet" placeholder).

### Aggregation worker shape (D-14)

- **D-14 — Lazy on dashboard open + on `resumed`. NO WorkManager periodic in v1:**
  - Single Dart-side aggregator function `UsageRepository.refreshIfStale()` (mirrors Phase 2's `BlockListRepository` shape).
  - Triggered by: (a) `DashboardScreen.initState` → first refresh; (b) `WidgetsBindingObserver.AppLifecycleState.resumed` while on the dashboard route → cache-aware refresh; (c) `RefreshIndicator` pull → unconditional refresh.
  - Writes to `daily_usage_summary` via Drift `into(...).insertOnConflictUpdate(...)`.
  - Idempotent — re-running mid-day overwrites today's row with fresh totals (no double-count risk).
  - **No WorkManager periodic in v1.** Defers to Phase 5 where WorkManager already pulls its weight for streak rollover (STRK-05) and reminder re-arm (NOTF-05).

### Chart vs list rendering (D-15..16)

- **D-15 — Flat sortable list with horizontal bar-fill per row.** No chart library dep. NO axes, NO time-series line, NO pie chart. Each row: `[icon] [display name]      [bar fill 0..maxOfPeriod] [duration text "1 h 23 m"]`. Bar fill uses `LinearProgressIndicator` (Material 3 default) tinted per D-06. Renders in <300 ms easily, accessible (screen readers read the duration text — bar is decorative), familiar pattern (Digital Wellbeing uses the same shape).
- **D-16 — Period total ribbon:** Above the list, a single `Card` shows the period total: `"Day total: 4 h 23 m across 12 apps"`. Tap collapses to "today's not-to-do total" only — quick filter. NOT a stacked bar, NOT a donut.

### Home cards placement (D-17)

- **D-17 — Two cards stacked above the unified list on `HomeScreen`,** between the existing `HealthCheckBanner` (when shown) and the existing `_homeEntriesProvider` `ListView`. Card 1: "Avoided today" (D-09). Card 2: "Cumulative totals" (D-11). Both cards use Material 3 `Card.outlined` for visual lightness — they should not compete with the entries list for visual weight. Tap on either card → `context.go('/dashboard')`. Cards are present from app cold-start onwards (do NOT animate-in via `AnimatedSwitcher` — they belong to the home identity, not transient state).

### Routing + Riverpod plumbing (D-18..19)

- **D-18 — GoRouter additions:** Single new route `GoRoute(path: '/dashboard', builder: …)` appended to `lib/core/router/app_router.dart`. The redirect gate stays as-is — `/dashboard` is a post-onboarding route (not under `/onboarding/*`), so the existing `onboardingCompleteProvider` redirect handles it correctly.
- **D-19 — Provider naming (mirrors Phase 2 patterns):**
  - `usageApiProvider` → `Provider<UsageApi>` returning `UsageApi()` (the Pigeon-generated class). Mirrors `appPickerApiProvider`.
  - `usageDaoProvider` → `Provider<DailyUsageSummaryDao>` (new DAO, mirrors `BlockListDao`).
  - `usageRepositoryProvider` → `Provider<UsageRepository>` (handles `refreshIfStale` + `watchRange(period)`). Mirrors `blockListRepoProvider`.
  - `dashboardRangeProvider` → `StateProvider<DashboardRange>` (enum `{ day, week, month }`, default `day`).
  - `dashboardRowsProvider` → `StreamProvider.autoDispose.family<List<DashRow>, DashboardRange>` — joins not-to-do entries with usage rows, applies highlight + sort.
  - `avoidedTodayProvider` → `StreamProvider.autoDispose<AvoidedTodaySummary>` — feeds Card 1.
  - `cumulativeTotalsProvider` → `StreamProvider.autoDispose<CumulativeTotalsSummary>` — feeds Card 2 (reads `pause_events` aggregate via Drift).
- **All providers hand-written, no `@riverpod` codegen** — same constraint Phase 1 + 2 hit (`riverpod_generator` + `meta 1.17` + Pigeon 26.3 incompatibility per `01-01-SUMMARY.md`).

### Performance budget (D-20)

- **D-20 — DASH-07 success criterion: <300 ms render on mid-range Android.** Validation harness: Phase 3 ships a `test/perf/dashboard_render_test.dart` that mounts the `DashboardScreen` against a seeded Drift fixture (30 days × 20 apps = 600 rows) and asserts the first frame's `tester.binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps` measured frame time < 300 ms in `flutter test`. CI-runnable; no real device required for Phase 3's exit. Real-device validation is recorded as a Phase 4-time pre-flight check (Phase 4's first task should re-measure on the same Pixel emulator used for Phase 2 UAT).

### Claude's Discretion (downstream — not pre-decided)

- **Drift v3 migration?** No — Phase 1 already shipped the `daily_usage_summary` table; Phase 3 only writes data into it. NO schema change in Phase 3 (`schemaVersion` stays at 2 from Phase 2). If during research the planner decides to add an index on `(packageName, day)`, that's a non-migrating-CREATE-INDEX-only delta — Claude's discretion.
- **Test strategy:** mirror Phase 2's pattern — Wave 0 ships test stubs; Wave 1+ fills them. Unit tests for the aggregator math, widget tests for the dashboard list + bar-fill, golden tests optional.
- **Empty Day/Week/Month copy:** "No usage tracked yet — open an app and come back" (or similar) — Claude's discretion to refine during planning.

### Folded Todos
None — `gsd-sdk query todo.match-phase 3` returned no matches (STATE.md "Active Todos: None").

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project-level (locked decisions)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/PROJECT.md` — v1 product scope (adult self-control; on-device only; no telemetry; no FCM; no Apple costs)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` — 68 v1 REQ-IDs; Phase 3 owns DASH-01..07 (lines 454–460)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` §"Phase 3: Screen-Time Dashboard" (lines 317–328) — 5 success criteria locked; "Plans: TBD" — Phase 3 plan count is the planner's call

### Project-level research (do not duplicate; read directly)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/STACK.md` — `app_usage` 4.1 / Pigeon 26.3 / Drift 2.32 pins
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` Pattern 3 (lines 209–224) — "Polling + caching for UsageStatsManager, never streaming". Background `Executor`. 5-min staleness for today; immutable past. **Load-bearing for D-12, D-14.**
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/PITFALLS.md` Pitfall #3 (lines 312–315) — `queryAndAggregateUsageStats` returning null when device locked; `MethodChannel` only supports primitives (Pigeon-typed avoids this). Pitfall #6 (lines 327–333) — querying 90 days on every open is a footgun; cache aggregated daily totals in local DB. **Load-bearing for D-04, D-12, D-14.**
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/FEATURES.md` lines 49–56, 102, 195, 237 — dashboard feature decomposition + "Avoided today" highlighted card definition
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/SUMMARY.md` lines 88, 108, 119 — Phase 3 framing: "validates the Pigeon channel pattern on a low-risk surface"; lazy aggregation; no streaming

### Phase 1 outputs (Pigeon scaffolding + Drift schema already shipped)
- `/Users/jintanakhomwong/projects/not-to-do-list/pigeons/usage_api.dart` — `UsageApi.queryRange(int startEpochMs, int endEpochMs)` HostApi + `UsagePackageStat` data class. **Phase 3 lights this up; no Pigeon schema change.**
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/platform/usage_api.g.dart` — Pigeon-generated Dart binding (read-only; regenerate if pigeons/usage_api.dart changes)
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt` — Pigeon-generated Kotlin shim. Phase 3 adds a sibling `UsageApiImpl.kt` mirroring `AppPickerHostImpl.kt` + `PermissionStatusApiImpl.kt`.
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt` — exemplar Kotlin Pigeon impl pattern (Executor, error wrapping, MainActivity registration). Phase 3's `UsageApiImpl.kt` mirrors this shape.
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` — registers Pigeon HostApi impls. Phase 3 appends one line registering `UsageApi`.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/daily_usage_summary_table.dart` — `DailyUsageSummary` table (Phase 1; lines exist). Phase 3 writes to this table; **no schema change**.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/app_database.dart` — current `@DriftDatabase`, `schemaVersion = 2`, `PRAGMA foreign_keys = ON` `beforeOpen` hook. Phase 3 does not bump `schemaVersion`.

### Phase 2 outputs (UI + provider patterns to mirror)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/home/pages/home_screen.dart` — `HomeScreen` shell. Phase 3 inserts the two home cards between `HealthCheckBanner` and the entries `ListView`.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/list/widgets/block_mode_segmented.dart` — exemplar Material 3 `SegmentedButton` for the D/W/M nav.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/health/widgets/health_check_banner.dart` — banner pattern + literal copy `"Tracking is offline — tap to fix"`. Phase 3 reuses verbatim for the no-permission fallback (D-13).
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/health/permission_health_provider.dart` — `permissionHealthProvider` exposes `usageAccessGranted` bool; Phase 3 reads this.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/list/providers/app_icon_cache_provider.dart` — `AppIconLruCache` (in-memory, 50-entry LRU). Phase 3 reuses for dashboard row icons; cache miss → letter-avatar.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/repositories/block_list_repository.dart` — exemplar repo shape (DAO injection, `watchAll()` Stream, mutating methods). Phase 3's `UsageRepository` mirrors.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/providers/block_list_repo_provider.dart` — exemplar hand-written `Provider` for repo injection.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/router/app_router.dart` — GoRouter spec. Phase 3 appends one route.
- `/Users/jintanakhomwong/projects/not-to-do-list/test/policy/play_invariants_test.dart` — 8 absence-grep policy invariants (PLAY-02..06 + v1-scope BIND_DEVICE_ADMIN + forbidden-token sweep). **Must remain green at Phase 3 exit.** No new manifest entries from Phase 3 should regress these.
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/02-list-crud-onboarding-permissions/02-CONTEXT.md` — locked-from-Phase-2 carry-forward (block-mode + schedule columns Phase 3 reads from `block_list`)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/02-list-crud-onboarding-permissions/02-VERIFICATION.md` — Phase 2 verification report (244 lines, committed e8e618f) — establishes the surface-integrity baseline Phase 3 must not regress
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/01-foundation-play-declaration/01-01-SUMMARY.md` — explains the `riverpod_generator` drop (analyzer-pin / `meta 1.17` / Pigeon 26.3 incompatibility); Phase 3 also writes hand-rolled Riverpod providers

### External (Android docs)
- https://developer.android.com/reference/android/app/usage/UsageStatsManager — `queryUsageStats`, `INTERVAL_DAILY`, `OPSTR_GET_USAGE_STATS`
- https://developer.android.com/training/articles/perf-anr — UI-thread query latency budget (UsageStatsManager exceeds this on slow devices — see PITFALLS.md anti-pattern #3)

### CLAUDE.md guardrails
- `/Users/jintanakhomwong/projects/not-to-do-list/CLAUDE.md` — Karpathy guidelines: simplicity first, surgical changes, no speculative scope. Particularly relevant for resisting chart-library + WorkManager pull during planning.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`pigeons/usage_api.dart` + `lib/platform/usage_api.g.dart` + `android/.../UsageApi.g.kt`** — entire Pigeon channel scaffolded in Phase 1, currently `throw UnimplementedError()` in Kotlin. Phase 3's "light up" task is the body of `UsageApiImpl.kt` (mirrors `AppPickerHostImpl.kt`).
- **`lib/data/database/tables/daily_usage_summary_table.dart`** — `DailyUsageSummary` Drift table already declared with the right columns (packageName, day, foregroundSeconds, launchCount, aggregatedAt, unique key on `(packageName, day)`). Phase 3 writes here; no schema change.
- **`lib/data/database/tables/pause_events_table.dart`** — `PauseEvents` table already declared (entryId, packageName, triggeredAt, cooldownChosenSeconds, outcome). Phase 3 reads via aggregate query for the cumulative card; Phase 4 is the writer.
- **`HealthCheckBanner` (lib/features/health/widgets/health_check_banner.dart)** — shipped in Phase 2 with the literal `"Tracking is offline — tap to fix"` copy enforced by `play_invariants_test.dart`. Phase 3 reuses the same widget for the dashboard's no-permission state.
- **`AppIconLruCache` (lib/features/list/providers/app_icon_cache_provider.dart)** — 50-entry in-memory LRU. Phase 3 extends usage to all foreground apps in the dashboard list (cache miss → letter-avatar).
- **`SegmentedButton` pattern (lib/features/list/widgets/block_mode_segmented.dart)** — exemplar for the D/W/M nav.
- **`BlockListRepository` shape (lib/data/repositories/block_list_repository.dart)** — Phase 3's `UsageRepository` mirrors this: DAO injection, `Stream<List<…>> watchRange(period)`, mutating `Future<void> refreshIfStale()`.
- **`StreamProvider.autoDispose` pattern (lib/features/home/pages/home_screen.dart line 14)** — Phase 2 uses for entry list; Phase 3 reuses for dashboard rows + home cards.

### Established Patterns
- **All Riverpod providers hand-written** — no `@riverpod` codegen (Phase 1 deviation per `01-01-SUMMARY.md`).
- **All Pigeon HostApi impls follow the `*Impl.kt` sibling pattern** — `AppPickerHostImpl.kt`, `PermissionStatusApiImpl.kt`. Phase 3 adds `UsageApiImpl.kt`.
- **MainActivity registers HostApi impls in `configureFlutterEngine()`** — Phase 3 appends one line.
- **Drift uses `insertOnConflictUpdate(...)`** for upserts (Phase 2 used in `BlockListDao.replaceMany` for quick-add seeding). Phase 3 reuses for daily_usage_summary upserts.
- **Tests use `mocktail`, not `mockito`** — Phase 2 settled this. Phase 3 mocks `UsageApi` for unit tests via `MockUsageApi extends Mock implements UsageApi`.
- **Lints: `very_good_analysis 10.2.0`** — Phase 3 code must analyze clean (0 errors/0 warnings; existing 18 pigeons/* infos are pre-existing per `deferred-items.md` and grandfathered).
- **GoRouter routes append-only** — Phase 3 adds `/dashboard`; existing 9 routes untouched.
- **PRAGMA `foreign_keys = ON`** is set globally in `app_database.dart`'s `beforeOpen` hook; cascade delete on `pause_events.entryId → block_list.id` is live (Phase 2 fix). Phase 3 cumulative-card aggregate inherits this — orphan pause_events are impossible.

### Integration Points
- **`/dashboard` is the new entry route**, reachable from (a) tap on either home card, (b) (future Phase 6 — Settings link), (c) future deep links (out of Phase 3 scope).
- **`UsageRepository.refreshIfStale()` is the single seam** the dashboard + home cards both call. Idempotent. Lazy. No background timer.
- **`pause_events` cumulative aggregate is read-only in Phase 3**; Phase 4 (PauseActivity) becomes the writer. Phase 3 should not rely on any non-zero data — the card renders 0/0 m correctly.
- **Permission state lives in `permissionHealthProvider`** (Phase 2). Phase 3 reads `usageAccessGranted` to decide between live-fetch and cached-fallback paths.
- **Frozen Phase-1/2 surface** — Phase 3 does not modify: `AndroidManifest.xml` (no new permissions), `docs/play-declaration.md`, `docs/data-safety.md`, the GoRouter redirect, `BlockListRepository`, `OnboardingComplete*`, the 8-invariant `play_invariants_test.dart`. If a planner gray-areas any of these, it's an escalation back to discuss-phase.

</code_context>

<specifics>
## Specific Ideas and Constraints

- **Dashboard route:** `/dashboard` — single screen, segmented D/W/M state inside.
- **Default nav state:** `Day` on cold start (no persistence; opens-on-Day).
- **Today cache TTL:** 5 minutes (`Duration(minutes: 5)`). PITFALLS.md / ARCHITECTURE.md research-locked. Past days: never re-queried.
- **App-foreground threshold for non-not-to-do row inclusion:** ≥ 60 seconds in the period (filters trivial background ticks).
- **Highlighted color:** `colorScheme.primary` (forest-green seed `0xFF2D6A4F` from Phase 2's Material 3 theme).
- **No-permission banner copy:** `"Tracking is offline — tap to fix"` — byte-for-byte identical to Phase 2's `HealthCheckBanner` (already locked by `play_invariants_test.dart`'s absence-grep invariant suite).
- **Avoided-today success rule:** `daily_usage_summary.foregroundSeconds(today, packageName) ≤ block_list.streakBreakThresholdMinutes × 60`. Default threshold = 5 min × 60 = 300 s. Habits: `daily_checkins(today).avoided = true`. Habits without a check-in are "Pending today" (not auto-success).
- **Cumulative card SQL (Drift):** `SELECT COUNT(*) AS n, COALESCE(SUM(cooldown_chosen_seconds), 0) AS s FROM pause_events WHERE outcome IN (0, 1)`. (Outcome 2 = "use anyway" — does NOT count as avoided.)
- **Locked-device error:** `queryUsageStats` returns null when device is locked on Android R+ (PITFALLS.md L313). Treat as "no data this poll, retry on next foreground." Never throw to UI.
- **Period boundaries (local timezone):**
  - Day: `[midnight_today, now]`.
  - Week: `[midnight_today − 6 days, now]` (rolling 7 days, ending today).
  - Month: `[midnight_today − 29 days, now]` (rolling 30 days, ending today). NOT calendar-month — rolling makes "this is what I did recently" the consistent question.
- **Render budget:** <300 ms first frame on mid-range device, validated via `test/perf/dashboard_render_test.dart` against a seeded 30-day × 20-app fixture.
- **Performance hint for monthly view:** SELECT-only from `daily_usage_summary` (DASH-04 mandates this). NEVER query raw events for monthly aggregation. Pre-aggregated table is the only data path for the M tab.
- **Testing fixtures:** Wave 0 (mirroring Phase 2) seeds a `test/_fixtures/usage_summary_fixture.dart` with 30 days × 20 apps for perf tests + per-day-edge-case asserts.

</specifics>

<deferred>
## Deferred Ideas (captured during analysis, NOT in v1 Phase 3)

- **Per-app drill-down screen** ("tap an app row → see its hour-by-hour use") — DIFF-05 v1.x deferred.
- **Time-of-day "danger zones" breakdown** — DIFF-05 v1.x deferred per REQUIREMENTS.md.
- **Calendar heatmap of streak / dashboard data** — DIFF-02 v1.x deferred.
- **Home-screen widget for "avoided today"** — DIFF-04 v1.x deferred.
- **Week-over-week / month-over-month comparison** — out of scope for v1; one-period view at a time.
- **Chart libraries (`fl_chart`, `syncfusion_flutter_charts`, etc.)** — out of scope; pure-widget bar-fill is sufficient and matches free/OSS budget. Reconsider in M2 if validation data demands richer visuals.
- **Background isolate / dataSync foreground service for aggregation** — research-anti-pattern (#3); v1 stays lazy-on-open. WorkManager periodic deferred to Phase 5 where it's earning its keep already.
- **Data export of usage rows** — Phase 6 (SETT-01).
- **Screen-time goals / quotas** — explicit anti-feature per PROJECT.md "Per-app daily quota limits."
- **Real-device overnight survival test as Phase 3 exit gate** — Phase 4's gate (REL-04). Phase 3 is simulator-friendly by research design.
- **Localization (non-English copy)** — deferred to a future milestone; Phase 3 ships English-only like Phase 2.
- **Disk-cached app icons** — Phase 2 already deferred this; Phase 3 inherits the 50-entry in-memory LRU.

### Reviewed Todos (not folded)
None — no active todos matched on `gsd-sdk query todo.match-phase 3`.

</deferred>

---

*Phase: 03-screen-time-dashboard*
*Context gathered: 2026-05-07 via /gsd-discuss-phase 3 (executed in --auto mode)*
*Next step: /gsd-plan-phase 3 in a fresh session*
