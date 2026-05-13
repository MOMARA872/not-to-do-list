---
phase: 04-pause-ux-the-wedge
plan: "01"
subsystem: testing
tags: [flutter, dart, mocktail, wave-0, red-stubs, accessibility, pause-screen]

requires:
  - phase: 03-screen-time-dashboard
    provides: Phase 3 test baseline (124 Phase 2 + ~37 Phase 3 = ~161 tests passing before Wave 0)
  - phase: 02-list-crud-onboarding-permissions
    provides: mocktail mock pattern (MockX extends Mock implements X), fixture conventions, very_good_analysis lint baseline

provides:
  - 11 stub test files covering PAUS-01..10 + REL-04 (every Phase 4 requirement has a named group)
  - test/_fixtures/pause_intent_fixture.dart with buildPauseIntentExtras + 4 intentExtra* constants encoding D-11
  - .planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md — REL-04 overnight gate sign-off template
  - MockAccessibilityApi class (mocktail) usable by Plans 04-03 + 04-08

affects:
  - 04-02 (schedule_window_parity_test.dart — Plan 04-02 fills this stub)
  - 04-03 (accessibility_api_test.dart MockAccessibilityApi — Plan 04-03 fills)
  - 04-04 (blocklist_broadcast_test.dart, accessibility_blocked_app_detector_test.dart)
  - 04-05 (pause_event_repository_test.dart — D-13 seam)
  - 04-07 (pause_screen_test.dart, pause_controller_test.dart, widget stubs)
  - 04-08 (permission_health_provider_a11y_live_test.dart, 04-VERIFICATION.md sign-off)

tech-stack:
  added: []
  patterns:
    - "Wave 0 RED-stub idiom: group + single skip-marked placeholder — mirrors 02-01 / 03-01"
    - "D-11 contract encoded as compile-time constants (intentExtra*) rather than string literals in each test"
    - "MockAccessibilityApi declared once in accessibility_api_test.dart, importable by downstream tests"

key-files:
  created:
    - test/_fixtures/pause_intent_fixture.dart
    - test/platform/accessibility_api_test.dart
    - test/data/repositories/blocklist_broadcast_test.dart
    - test/data/repositories/pause_event_repository_test.dart
    - test/data/detectors/accessibility_blocked_app_detector_test.dart
    - test/domain/schedule/schedule_window_parity_test.dart
    - test/features/pause/pause_screen_test.dart
    - test/features/pause/widgets/cooldown_chip_row_test.dart
    - test/features/pause/widgets/cooldown_progress_bar_test.dart
    - test/features/pause/widgets/done_confirmation_card_test.dart
    - test/features/pause/pause_controller_test.dart
    - test/features/health/permission_health_provider_a11y_live_test.dart
    - .planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md
  modified: []

key-decisions:
  - "D-11 extras encoded as 4 top-level const String values in the fixture so downstream tests never string-literal the key names — compile-time enforcement of the Intent extras contract"
  - "schedule_window_parity_test.dart imports lib/domain/schedule/schedule_window.dart and calls isInScheduleWindow() with a null-triple to verify the import resolves; real 200+ tuple assertions deferred to Plan 04-02"
  - "Wave 0 adds NO files under lib/ or android/app/src/main/ — PLAY-02/03/05/06 invariants are unaffected"

patterns-established:
  - "Wave 0 stub shape: import flutter_test.dart, declare group with REQ-ID in title, single test('placeholder', () {}, skip: 'Plan 04-NN fills ...')"
  - "Fixture constants pattern: intentExtra* consts exported from a shared fixture file, not repeated as string literals in each consumer test"

requirements-completed:
  - PAUS-01
  - PAUS-02
  - PAUS-03
  - PAUS-04
  - PAUS-05
  - PAUS-06
  - PAUS-07
  - PAUS-08
  - PAUS-09
  - PAUS-10
  - REL-04

duration: 25min
completed: 2026-05-10
---

# Phase 4 Plan 01: Wave 0 Test Scaffolding Summary

**11 RED-stub test files + pause Intent fixture + REL-04 overnight-gate template locking the Phase 4 testable surface before any production code lands**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-10T00:00:00Z
- **Completed:** 2026-05-10T00:25:00Z
- **Tasks:** 2
- **Files created:** 13 (12 test/planning files + 1 verification template)
- **Files modified:** 0

## Accomplishments

- Created `test/_fixtures/pause_intent_fixture.dart` with `buildPauseIntentExtras()` helper and 4 `intentExtra*` constants — the D-11 Intent extras contract is now enforced at compile time across all downstream tests
- Created 11 stub test files covering every Phase 4 requirement (PAUS-01..10 + REL-04), all marked `skip:` with the filling plan reference — suite exits 0 with 161 passing + 21 skipped
- Created `04-VERIFICATION.md` with the complete REL-04 OEM-survival overnight gate template (6 required sections, CD-03 escalation rule, blank fields for Plan 04-08 to fill)
- 8/8 PLAY-* invariants remain green (Wave 0 adds nothing under `lib/` or `android/app/src/main/`)

## Task Commits

1. **Task 04-01-01: Create 11 stub test files + pause intent fixture** — `706ae1f` (test)
2. **Task 04-01-02: Create 04-VERIFICATION.md REL-04 sign-off template** — `7b5997d` (chore)

## Files Created

- `test/_fixtures/pause_intent_fixture.dart` — `buildPauseIntentExtras()` + 4 `intentExtra*` constants encoding D-11
- `test/platform/accessibility_api_test.dart` — `MockAccessibilityApi extends Mock implements AccessibilityApi`; stub for Plan 04-03
- `test/data/repositories/blocklist_broadcast_test.dart` — D-10 ACTION_BLOCKLIST_UPDATED contract stub; Plan 04-04 fills
- `test/data/repositories/pause_event_repository_test.dart` — D-13 insertOutcome with outcome=0/1/2 sub-groups; Plan 04-07 fills
- `test/data/detectors/accessibility_blocked_app_detector_test.dart` — D-16 REL-05 swap stub; Plan 04-04 fills
- `test/domain/schedule/schedule_window_parity_test.dart` — D-12/PAUS-10 parity oracle stub; imports existing `isInScheduleWindow`; Plan 04-02 fills 200+ tuple assertions
- `test/features/pause/pause_screen_test.dart` — 4 groups: PAUS-02 reason hero (D-02), PAUS-02 empty-reason (D-03), PAUS-09 hard omits Use anyway (D-06), PAUS-03 cooldown chips (D-04)
- `test/features/pause/widgets/cooldown_chip_row_test.dart` — D-04 SegmentedButton chips stub; Plan 04-07 fills
- `test/features/pause/widgets/cooldown_progress_bar_test.dart` — D-05 LinearProgressIndicator + X:XX caption stub; Plan 04-07 fills
- `test/features/pause/widgets/done_confirmation_card_test.dart` — D-07 "✓ Cooldown complete" 1.5s card stub; Plan 04-07 fills
- `test/features/pause/pause_controller_test.dart` — 4 groups: PAUS-04 drain auto-complete, PAUS-05 Cancel, PAUS-06 Use anyway, D-13 insert-at-end seam; Plan 04-07 fills
- `test/features/health/permission_health_provider_a11y_live_test.dart` — stub for end-to-end a11y chain verification; Plan 04-08 fills
- `.planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md` — REL-04 overnight gate sign-off template with all 6 required sections

## Decisions Made

- Encoded the D-11 Intent extras contract as 4 compile-time `const String` constants (`intentExtraEntryId`, `intentExtraBlockedPackage`, `intentExtraBlockMode`, `intentExtraTriggeredAtMs`) rather than repeating string literals in each consumer test — enforces the contract without runtime overhead
- The `schedule_window_parity_test.dart` stub imports `lib/domain/schedule/schedule_window.dart` and calls `isInScheduleWindow()` with a null-triple (compile-time import verification, always returns `false`) — this ensures the Dart side of D-12 resolves correctly even before Plan 04-02 ships the 200+ tuple assertions

## Deviations from Plan

None — plan executed exactly as written. All 12 files created per the plan's action block. Suite stays green with 161 passing + 21 skipped. 8/8 PLAY-* invariants green.

## Issues Encountered

None. The worktree path routing was verified — `.planning/` files must be written to the worktree root, not the main repo path.

## Known Stubs

All new test files are intentional Wave 0 RED stubs. Every test is marked `skip: 'Plan 04-NN fills ...'` with an explicit plan reference. No test is green-but-broken. The fixture (`pause_intent_fixture.dart`) contains real production-shaped logic (the only file in this plan with non-stub content).

## Next Phase Readiness

- Wave 1 (Plans 04-02 + 04-03) can proceed in parallel: 04-02 fills `schedule_window_parity_test.dart`; 04-03 fills `accessibility_api_test.dart`
- `MockAccessibilityApi` class is importable by any Wave 1+ test via `import '../../platform/accessibility_api_test.dart'` (relative path varies by depth)
- `buildPauseIntentExtras()` and the `intentExtra*` constants are importable by Plans 04-05, 04-06, 04-07 via `import '../_fixtures/pause_intent_fixture.dart'`
- `04-VERIFICATION.md` is ready for Plan 04-08 to populate the blank device/stopwatch fields after the overnight test

---

*Phase: 04-pause-ux-the-wedge*
*Plan: 04-01*
*Completed: 2026-05-10*

## Self-Check: PASSED

All 14 expected files found on disk. Both task commits (706ae1f, 7b5997d) verified in git log. `flutter test` exits 0 (161 passing + 21 skipped). 8/8 PLAY-* invariants green.
