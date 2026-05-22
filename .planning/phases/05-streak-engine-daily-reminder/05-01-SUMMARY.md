---
phase: 05-streak-engine-daily-reminder
plan: "01"
subsystem: test-infrastructure
tags:
  - wave-0
  - red-stubs
  - streak-engine
  - daily-reminder
  - tdd
dependency_graph:
  requires: []
  provides:
    - test/data/dao/daily_streak_dao_test.dart
    - test/data/dao/daily_checkins_dao_test.dart
    - test/domain/streak/streak_rollover_service_test.dart
    - test/domain/streak/streak_rollover_dst_test.dart
    - test/features/streak/streak_badge_test.dart
    - test/features/streak/streak_history_section_test.dart
    - test/features/checkin/checkin_screen_test.dart
    - test/features/reminder/reminder_settings_test.dart
    - test/features/reminder/deep_link_navigation_test.dart
    - test/features/onboarding/post_notifications_earned_test.dart
    - test/features/home/reminder_off_banner_test.dart
    - test/policy/phase_5_invariants_test.dart
    - test/_fixtures/streak_fixture.dart
    - android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/StreakDayAnchoringTest.kt
    - .planning/phases/05-streak-engine-daily-reminder/05-VERIFICATION.md
  affects:
    - test/policy/play_invariants_test.dart
tech_stack:
  added: []
  patterns:
    - Wave 0 RED stub pattern (mirrors Phase 4 Plan 04-01)
    - JUnit 4 @Ignore pattern for Kotlin JVM oracle
    - mocktail MockPermissionStatusApi factory pattern
    - testWidgets skip: true for widget stubs (vs test() skip: String)
key_files:
  created:
    - test/data/dao/daily_streak_dao_test.dart
    - test/data/dao/daily_checkins_dao_test.dart
    - test/domain/streak/streak_rollover_service_test.dart
    - test/domain/streak/streak_rollover_dst_test.dart
    - test/features/streak/streak_badge_test.dart
    - test/features/streak/streak_history_section_test.dart
    - test/features/checkin/checkin_screen_test.dart
    - test/features/reminder/reminder_settings_test.dart
    - test/features/reminder/deep_link_navigation_test.dart
    - test/features/onboarding/post_notifications_earned_test.dart
    - test/features/home/reminder_off_banner_test.dart
    - test/policy/phase_5_invariants_test.dart
    - test/_fixtures/streak_fixture.dart
    - android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/StreakDayAnchoringTest.kt
    - .planning/phases/05-streak-engine-daily-reminder/05-VERIFICATION.md
  modified: []
decisions:
  - "testWidgets() skip parameter is bool? not String — used skip: true for all widget stubs to avoid compile error"
  - "NOTF-02 and NOTF-04 are manual-only; added to phase_5_invariants_test.dart as skipped tests to satisfy REQ-ID grep coverage"
  - "buildClockMockApi does not stub bootMonotonicNanos() yet — method doesn't exist on PermissionStatusApi until Plan 05-04 extends the Pigeon interface; documented in fixture comment"
  - "Kotlin StreakDayAnchoringTest uses @Ignore on all methods so BUILD SUCCESSFUL even though bodies throw NotImplementedError"
metrics:
  duration: "14 min"
  completed_date: "2026-05-22"
  tasks_completed: 1
  files_created: 15
---

# Phase 5 Plan 01: Wave 0 RED stubs + REL-05 protocol skeleton + Kotlin parity oracle + policy invariants Summary

All 15 Phase 5 Wave 0 artifacts created: 14 Dart RED test stubs (all skipped), 1 shared fixture, 1 JVM Kotlin oracle (@Ignore), and 1 REL-05 VERIFICATION.md sign-off template.

## What Was Built

**Task 1: Stub all 14 Phase 5 RED test files + shared fixture + REL-05 verification skeleton (commit 383c5a2)**

Created the full Wave 0 test surface for Phase 5 Streak Engine & Daily Reminder. Every Phase 5 REQ-ID (STRK-01..09 + NOTF-01..07) has at least one named `group(...)` declaration in test files. The test suite stays green with all new stubs skipped.

Files created:

| File | REQ-IDs Covered | Fill Plan |
|------|----------------|-----------|
| `test/data/dao/daily_streak_dao_test.dart` | STRK-01, STRK-05, STRK-07, D-16 | 05-02 |
| `test/data/dao/daily_checkins_dao_test.dart` | STRK-03 | 05-02 |
| `test/domain/streak/streak_rollover_service_test.dart` | STRK-02, STRK-04, STRK-06, STRK-09, D-12 | 05-03 |
| `test/domain/streak/streak_rollover_dst_test.dart` | STRK-08 | 05-03 |
| `test/features/streak/streak_badge_test.dart` | STRK-07, D-14, D-15, D-05 | 05-07 |
| `test/features/streak/streak_history_section_test.dart` | D-16, D-07 | 05-07 |
| `test/features/checkin/checkin_screen_test.dart` | D-01, D-02, D-03 | 05-06 |
| `test/features/reminder/reminder_settings_test.dart` | NOTF-01, D-09 | 05-08 |
| `test/features/reminder/deep_link_navigation_test.dart` | NOTF-03 | 05-05 |
| `test/features/onboarding/post_notifications_earned_test.dart` | NOTF-06 | 05-08 |
| `test/features/home/reminder_off_banner_test.dart` | NOTF-07 | 05-07 |
| `test/policy/phase_5_invariants_test.dart` | STRK-05, NOTF-02, NOTF-04, NOTF-05, USE_EXACT_ALARM, FCM | 05-01/05-05 |
| `test/_fixtures/streak_fixture.dart` | Shared fixture for STRK-04/STRK-06 tests | — |
| `android/.../StreakDayAnchoringTest.kt` | STRK-09 parity oracle | 05-03 |
| `.planning/.../05-VERIFICATION.md` | REL-05 sign-off template | 05-09 |

**3 REAL (non-skipped) passing invariants in phase_5_invariants_test.dart today:**
1. `PLAY-Phase5: no USE_EXACT_ALARM permission` — manifest grep passes
2. `no FCM / firebase_messaging imports under lib/` — source tree grep passes
3. `STRK-05: no WorkManager PeriodicWorkRequest in android/.../streak/` — path absent (trivially passes)

## Verification Results

| Check | Result |
|-------|--------|
| `flutter test` (full suite) | PASS — 397 passing, 76 skipped (0 failures) |
| `flutter test test/policy/play_invariants_test.dart` | PASS — 9/9 green (no regression) |
| `flutter test test/policy/phase_5_invariants_test.dart` | PASS — 3 real passing, 4 skipped |
| `./gradlew :app:testDebugUnitTest --tests "*.StreakDayAnchoringTest"` | BUILD SUCCESSFUL (all methods @Ignore'd) |
| All 16 Phase 5 REQ-IDs grep-positive in test/ | PASS |
| `grep -c 'REL-05' 05-VERIFICATION.md` | 7 (≥5 required) |
| `grep -c 'buildClockMockApi' streak_fixture.dart` | 2 (≥1 required) |
| No lib/ files added or modified | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] testWidgets() skip parameter type mismatch**
- **Found during:** Task 1 (compile error on first flutter test run)
- **Issue:** `testWidgets()` accepts `skip: bool?` not `skip: String` (unlike `test()`). The plan spec used `skip: 'Plan 05-NN fills'` inside `testWidgets()` calls which causes a compile error.
- **Fix:** Changed all `testWidgets()` stubs to use `skip: true` with an inline comment `// Plan 05-NN fills`.
- **Files modified:** streak_badge_test.dart, streak_history_section_test.dart, checkin_screen_test.dart, reminder_settings_test.dart, deep_link_navigation_test.dart, post_notifications_earned_test.dart, reminder_off_banner_test.dart
- **Commit:** 383c5a2

**2. [Rule 2 - Missing Critical Functionality] NOTF-02 and NOTF-04 missing from test/ grep**
- **Found during:** Post-task verification (acceptance criterion grep)
- **Issue:** NOTF-02 and NOTF-04 are manual-only in 05-VALIDATION.md (no stub test file listed), but the plan acceptance criterion requires every REQ-ID to appear in test/ as a literal substring. These two were missing.
- **Fix:** Added two explicitly-skipped test stubs in phase_5_invariants_test.dart with the REQ-ID in the test name, plus file-header comments documenting their manual-only nature.
- **Files modified:** test/policy/phase_5_invariants_test.dart
- **Commit:** 383c5a2

**3. [Rule 2 - Missing Critical Functionality] streak_rollover_dst_test.dart const DateTime compilation error**
- **Found during:** Task 1 (compile error — `DateTime.utc()` is not const)
- **Issue:** Initial stub used `const List<_DstTuple>` with `DateTime.utc()` which is non-const.
- **Fix:** Changed to `final List<_DstTuple>` (non-const) to allow `DateTime.utc()`.
- **Files modified:** test/domain/streak/streak_rollover_dst_test.dart
- **Commit:** 383c5a2

**4. [Rule 2 - Note] streak_fixture.dart bootMonotonicNanos() not yet stubbed**
- **Observed:** `PermissionStatusApi` does not yet have `bootMonotonicNanos()` — it is a new Pigeon method to be added in Plan 05-04.
- **Action:** The `buildClockMockApi` factory accepts the parameter but does not call `when(() => m.bootMonotonicNanos())` since the method doesn't exist on the interface. Documented clearly in the fixture. Plan 05-04 will extend this when the Pigeon method is added.
- **No behavioral impact:** All STRK-06 tests are skipped (`Plan 05-03 fills`).

## Known Stubs

All 15 files are intentional stubs. Every test body is empty or contains a comment only. The plan's Wave 0 invariant is "suite stays green + every Phase 5 REQ-ID has a named group" — both satisfied.

No stubs prevent the plan's goal from being achieved. Each stub is annotated with the exact downstream plan number that fills it.

## Threat Flags

No new security-relevant surface introduced. Wave 0 is test-only — no lib/ or android/src/main/ files modified.

## Self-Check: PASSED

- test/data/dao/daily_streak_dao_test.dart: FOUND
- test/policy/phase_5_invariants_test.dart: FOUND
- test/_fixtures/streak_fixture.dart: FOUND
- android/.../StreakDayAnchoringTest.kt: FOUND
- .planning/.../05-VERIFICATION.md: FOUND
- Commit 383c5a2: FOUND (git log confirmed)
- flutter test: 397 passing, 76 skipped, 0 failures
- play_invariants: 9/9 green
- phase_5_invariants: 3 real passing, 4 skipped
- Gradle StreakDayAnchoringTest: BUILD SUCCESSFUL
- All 16 REQ-IDs grep-positive in test/
- REL-05 appears 7 times in 05-VERIFICATION.md
- buildClockMockApi appears 2 times in streak_fixture.dart
- No lib/ changes
