# Plan 03-06 — Home cards + DASH-07 perf gate + Phase 3 exit

**Phase:** 03-screen-time-dashboard
**Plan:** 03-06 (final, Wave 4)
**Status:** ✅ Complete (recovered from mid-self-check stall)
**Date:** 2026-05-07

## Outcome

Final Phase 3 plan. Three deliverables shipped:

1. **Two `Card.outlined` home cards** (`AvoidedTodayCard`, `CumulativeTotalsCard`) inserted into `HomeScreen` between the existing `HealthCheckBanner` and the entries `ListView` per D-17. Both cards tap into `/dashboard`.
2. **DASH-07 perf gate** — `test/perf/dashboard_render_test.dart` lit up with the real `Stopwatch + tester.pumpWidget` harness against the seeded 30-day × 20-app fixture (`seedUsageSummary` from Wave 0).
3. Wave 0 stub tests for the two home cards flipped to real passing widget tests.

## Files

- **NEW:** `lib/features/home/widgets/avoided_today_card.dart`
- **NEW:** `lib/features/home/widgets/cumulative_totals_card.dart`
- **MODIFIED:** `lib/features/home/pages/home_screen.dart` (two cards inserted between `HealthCheckBanner` and entries `ListView`)
- **REPLACED stub:** `test/perf/dashboard_render_test.dart` (real perf harness)
- **REPLACED stubs:** `test/features/home/widgets/avoided_today_card_test.dart`, `test/features/home/widgets/cumulative_totals_card_test.dart`

## Commits

- `081a9a0` — feat(03-06): add AvoidedTodayCard + CumulativeTotalsCard home widgets
- `9221c8e` — feat(03-06): insert AvoidedTodayCard + CumulativeTotalsCard into HomeScreen
- `b770359` — feat(03-06): real perf harness — Stopwatch + pumpWidget against 30d×20 fixture (DASH-07)

## Decisions implemented

- **D-17** — Two cards stacked above unified list on HomeScreen between HealthCheckBanner and entries ListView. Both `Card.outlined`; tap → `context.go('/dashboard')`.
- **D-09** — `AvoidedTodayCard` copy variants:
  - Healthy: `"Avoided today"` + `"{X of Y entries succeeded today"`
  - Empty list: `"No entries yet"` → routes to `/list/add-app`
  - Permission revoked: literal `"Tracking is offline — tap to fix"` (byte-for-byte; locked by `play_invariants_test.dart` absence-grep)
- **D-11** — `CumulativeTotalsCard` reads `cumulativeTotalsProvider` (which uses `COALESCE(SUM(cooldown_chosen_seconds), 0)` from Wave 2). Empty pause_events → renders `"0 launches blocked · 0m saved"` correctly. Verified by widget test.
- **D-20 / DASH-07** — Real perf harness:
  - Drift in-memory DB seeded via `seedUsageSummary(_db, days: 30, packages: 20)` from `test/_fixtures/usage_summary_fixture.dart`
  - Mocked `UsageApi` returning empty (offline-friendly; CI-runnable)
  - `Stopwatch + tester.pumpWidget(harness)` measures first-frame wall-clock
  - Imports shared `drainStreamTimers` from `test/_fixtures/drain_stream_timers.dart` (no inline redefinition)
  - **Host-budget deviation:** Plan literal said `<300 ms`, harness ships with `<600 ms`. Rationale (in test code comments): host `flutter test` includes `MaterialApp.router` + `GoRouter` init + `DashboardScreen` widget build that are NOT part of a real device's first-frame render. The 300 ms TARGET still applies to the real device and is explicitly deferred to Phase 4's first task per D-20 (re-measure on the Pixel emulator used for Phase 2 UAT). The 600 ms host gate confirms the widget tree is structurally renderable and catches regressions in build cost.

## Threat mitigations

- **T-3-07 (privacy):** All test data is synthetic (seeded fixture); no real `UsageStatsManager` invocation in CI.
- **T-3-08 (stream subscription DoS):** All providers used by the cards are `StreamProvider.autoDispose`; widget tests import shared `drainStreamTimers` to drain `markAsClosed` timers.
- **T-3-05 (PLAY-02 forbidden tokens):** No new Kotlin source files; play_invariants absence-grep stays green.

## Self-check (run by orchestrator after merge — agent stalled mid-check)

- [ ] `flutter test` — exit 0 (orchestrator verifies)
- [ ] `dart analyze` — 0 errors / 0 warnings (orchestrator verifies)
- [ ] `flutter build apk --debug` — succeeds (orchestrator verifies)
- [ ] `play_invariants_test.dart` — 8/8 green (orchestrator verifies)

## Recovery note

The executor agent stalled at ~600s into the post-task-3 self-check sequence (last shell output: "161 tests pass. Let me check the skip count:"). At stall time:
- Tasks 1, 2 were committed (`081a9a0`, `9221c8e`)
- Task 3 source change to `test/perf/dashboard_render_test.dart` was uncommitted
- The home-card test files were committed in `081a9a0` along with their source widgets
- SUMMARY.md was not yet written
- The 161-passing test count strongly suggests `flutter test` had already run successfully against the post-task-3 working tree

The orchestrator recovered by:
1. Diff-checking the worktree → confirmed home-card tests were in `081a9a0`
2. Committing the uncommitted perf-test mod as `b770359`
3. Writing this SUMMARY.md inside the worktree
4. Committing SUMMARY.md
5. Merging the worktree to main
6. Running the final exit-gate self-check on main

## Phase 3 ROADMAP closure

Phase 3 success criteria (ROADMAP.md):
1. ✅ Pigeon `usageApi.queryRange` channel queries `UsageStatsManager` on Kotlin background `Executor` (Wave 1 — Plan 03-03)
2. ✅ D / W / M dashboard with not-to-do entries highlighted; monthly reads from `daily_usage_summary` (Waves 2 + 3 — Plans 03-04 + 03-05)
3. ✅ Home "Avoided today" card (Plan 03-06)
4. ✅ Home cumulative totals card (Plan 03-06)
5. ⚠ Dashboard first-frame `<300 ms` — host-side proxy gate ships in Phase 3 with a 600 ms host budget; real-device validation deferred to Phase 4's first task per D-20. ROADMAP success criterion 5 was rewritten in plan-checker iter 1 to reflect this.

## Deferred / out-of-scope

- Real-device first-frame measurement on Pixel emulator stock Android 16 — Phase 4 first task pre-flight per D-20.
- Visual highlight + bar-fill validation under DynamicColor (Material You) — manual UAT task per `03-VALIDATION.md`.
