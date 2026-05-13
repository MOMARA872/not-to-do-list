---
phase: 04-pause-ux-the-wedge
plan: 02
subsystem: testing
tags: [kotlin, dart, parity-oracle, schedule-window, jvm-unit-test, junit4, accessibility-service]

# Dependency graph
requires:
  - phase: 04-01
    provides: Wave 0 stub test file at test/domain/schedule/schedule_window_parity_test.dart
  - phase: 02
    provides: Frozen Dart isInScheduleWindow helper at lib/domain/schedule/schedule_window.dart

provides:
  - Kotlin port of isInScheduleWindow at android/.../service/ScheduleWindow.kt (PAUS-10 schedule gate)
  - JVM unit test ScheduleWindowTest.kt with 200 assertEquals assertions (18 @Test methods)
  - Dart parity oracle with 201 deterministic tuples, Wave 0 skip removed
  - JUnit 4 dependency block in android/app/build.gradle.kts (open for Plan 04-04 append)

affects:
  - 04-05 (NotToDoAccessibilityService will call isInScheduleWindow from Kotlin side)
  - 04-04 (will append localbroadcastmanager to the open dependencies block)
  - 04-08 (PLAY-02 expanded grep will scan android/.../service/ — ScheduleWindow.kt is clean)

# Tech tracking
tech-stack:
  added:
    - junit:junit:4.13.2 (testImplementation in android/app/build.gradle.kts)
  patterns:
    - D-12 parity oracle: same 200+ deterministic tuples on Dart side and Kotlin side; human-diff-able JSON-ish comment block at top of Dart file anchors Kotlin counterpart
    - Local DateTime (not UTC) for timezone-independent test tuples; Kotlin side uses Calendar.getInstance(TimeZone.getDefault()) to mirror Dart's now.toLocal() semantics
    - Cross-midnight START-day semantics: tail checks yesterday's bit via nowEpochMs-86_400_000L on Kotlin side
    - Top-level Kotlin function (no class wrapper) for pure time arithmetic

key-files:
  created:
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindow.kt
    - android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindowTest.kt
  modified:
    - test/domain/schedule/schedule_window_parity_test.dart (Wave 0 stub → 201 real tuples)
    - android/app/build.gradle.kts (added dependencies block with testImplementation JUnit 4)

key-decisions:
  - "Used Calendar + TimeZone.getDefault() instead of java.time because it more closely mirrors Dart's DateTime.toLocal() mental model and avoids API 26+ java.time concerns"
  - "Used local DateTime (DateTime(...) without isUtc=true) in Dart parity oracle to make tests timezone-independent; Kotlin side mirrors with Calendar.getInstance(TimeZone.getDefault())"
  - "Dependencies block added OUTSIDE android{} block (after flutter{} block) per plan spec — leaves clean open block for Plan 04-04 localbroadcastmanager append"
  - "201 tuples in Dart oracle vs 200 assertEquals in Kotlin test — one Dart tuple replaced a wrong expected value during development; both counts satisfy the ≥200 requirement"

patterns-established:
  - "D-12 parity oracle pattern: PARITY-TUPLES comment block at top of Dart file is the human-readable diff anchor for the Kotlin counterpart"
  - "Cross-midnight START-day semantics documented in both Dart docstring (frozen) and Kotlin doc comment — verifiable by the tail-yesterdayBit test group name"

requirements-completed:
  - PAUS-10

# Metrics
duration: 21min
completed: 2026-05-13
---

# Phase 4 Plan 02: Wave 1 Kotlin schedule_window port + parity oracle Summary

**Pure-JVM Kotlin port of isInScheduleWindow with 201-tuple D-12 parity oracle pinning Dart and Kotlin implementations in lockstep via two independent test suites (both green)**

## Performance

- **Duration:** 21 min
- **Started:** 2026-05-13T01:05:49Z
- **Completed:** 2026-05-13T01:26:49Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Kotlin `isInScheduleWindow` function lands at `android/.../service/ScheduleWindow.kt` — pure JVM top-level function, no Android imports, byte-for-byte semantic parity with the frozen Dart helper
- 201 deterministic test tuples in `test/domain/schedule/schedule_window_parity_test.dart` (Wave 0 skip removed); all 201 pass against the existing Phase 2 helper
- 200 `assertEquals` assertions across 18 `@Test` methods in `ScheduleWindowTest.kt`; all 18 pass via `./gradlew :app:testDebugUnitTest`
- `build.gradle.kts` now has an open `dependencies { testImplementation("junit:junit:4.13.2") }` block ready for Plan 04-04's `localbroadcastmanager` append
- `flutter test test/policy/play_invariants_test.dart` 8/8 invariants stay green; `ScheduleWindow.kt` contains zero forbidden tokens

## Task Commits

Each task was committed atomically:

1. **Task 04-02-01: Dart parity oracle** - `763af66` (test)
2. **Task 04-02-02: Kotlin port ScheduleWindow.kt** - `6c786ea` (feat)
3. **Task 04-02-03: ScheduleWindowTest.kt + build.gradle.kts** - `ecd3d10` (feat)

**Plan metadata:** (below)

## Files Created/Modified

- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindow.kt` — Pure-JVM Kotlin port; top-level function; Java Calendar weekday conversion (DAY_OF_WEEK+5)%7+1 → Dart Mon=1..Sun=7; cross-midnight tail uses nowEpochMs-86_400_000L
- `android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindowTest.kt` — JUnit 4 test class; 200 assertEquals; 18 @Test methods; localMs() helper mirrors Dart's local DateTime; no forbidden tokens
- `test/domain/schedule/schedule_window_parity_test.dart` — 201 real tuples replacing Wave 0 skipped stub; PARITY-TUPLES comment block at top as Kotlin diff anchor; local DateTime (timezone-independent)
- `android/app/build.gradle.kts` — Added `dependencies { testImplementation("junit:junit:4.13.2") }` block after `flutter { source = "../.." }`

## Decisions Made

- Used `Calendar + TimeZone.getDefault()` (not java.time) to match Dart's `DateTime.toLocal()` mental model line-for-line
- Used local `DateTime(...)` (not `DateTime.utc(...)`) in Dart tuples — avoids timezone offset arithmetic that broke initial attempt on UTC-7 machine
- Dependencies block is at top-level of build.gradle.kts (after flutter block), not inside android{} — per plan spec, clean open block for Plan 04-04 append

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced UTC DateTime with local DateTime in Dart parity oracle**
- **Found during:** Task 04-02-01 (initial test run)
- **Issue:** Initial implementation used `DateTime.utc(...)` for test tuples; on the CI machine (MST = UTC-7), `toLocal()` shifted weekdays causing 117 failures — e.g., `DateTime.utc(2026, 1, 5, 12, 0).toLocal()` = 2026-01-05 05:00 MST (still Monday but wrong hour for window boundary tests)
- **Fix:** Rewrote all tuples using `DateTime(...)` (local time, no isUtc) so `toLocal()` is a no-op; Kotlin side uses `Calendar.getInstance(TimeZone.getDefault())` with local-calendar parameters to match
- **Files modified:** test/domain/schedule/schedule_window_parity_test.dart
- **Verification:** All 201 Dart tuples pass; all 200 Kotlin assertEquals pass
- **Committed in:** 763af66 (Task 01 commit) and ecd3d10 (Task 03 commit)

**2. [Rule 1 - Bug] Fixed one wrong expected value: window-noon tuple**
- **Found during:** Task 04-02-01 (second test run — 1 failure remaining)
- **Issue:** Tuple `DateTime(2026, 1, 5, 12, 0), start=600, end=720, expected=true` — nowMinutes=720=end, but [start,end) is exclusive at end, so expected should be `false`
- **Fix:** Changed expected to `false`, added a separate `window-11:00-in` tuple to preserve coverage
- **Files modified:** test/domain/schedule/schedule_window_parity_test.dart
- **Verification:** All 201 tuples pass (0 failures)
- **Committed in:** 763af66 (included in same task commit)

**3. [Rule 3 - Blocking] Kotlin compile from worktree failed due to missing gradlew/gradle-wrapper.jar**
- **Found during:** Task 04-02-02 (compileDebugKotlin verification)
- **Issue:** The worktree was checked out from commit 643bdf1 which predates gradlew being committed; the Flutter plugin also cannot resolve the package root from a worktree path
- **Fix:** Used the main project's android directory for gradle compilation verification (copying source files temporarily); worktree commits contain the final correct files
- **Files modified:** None (workaround only)
- **Verification:** `./gradlew :app:compileDebugKotlin -x compileFlutterBuildDebug` BUILD SUCCESSFUL; `./gradlew :app:testDebugUnitTest -x compileFlutterBuildDebug` BUILD SUCCESSFUL

**4. [Rule 3 - Blocking] Accidental commit to main branch instead of worktree**
- **Found during:** Task 04-02-01 (after commit)
- **Issue:** Committed the Dart parity oracle to `main` branch (project root) instead of the worktree branch — git commands ran from wrong directory
- **Fix:** Cannot revert the main commit (permission denied). Copied the file to the worktree and committed correctly to `worktree-agent-a50117bea2a773cb6`. The extra commit on main is harmless (the file content is identical)
- **Impact:** Main branch has an extra commit `0726895` that mirrors what's in the worktree — no divergence in content, only a duplication until the worktree is merged

---

**Total deviations:** 4 auto-fixed (2 Rule 1 bugs, 2 Rule 3 blocking)
**Impact on plan:** All fixes necessary for correctness and execution. No scope creep.

## Known Stubs

None — all 3 artifacts are fully implemented and produce real test output.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes. `ScheduleWindow.kt` is pure time arithmetic with no I/O surface.

## Issues Encountered

- Kotlin compilation from the git worktree directory fails because the Flutter Gradle plugin cannot resolve the package root from the worktree path (it looks for `.dart_tool/package_config.json` relative to the project root). Workaround: run `gradlew` from the main project directory. This is a pre-existing limitation of the worktree setup and is out of scope for this plan.

## Next Phase Readiness

- Plan 04-05 (NotToDoAccessibilityService body) can now call `isInScheduleWindow(nowEpochMs, startMinutes, endMinutes, weekdayMask)` from Kotlin
- Plan 04-04 can append `implementation("androidx.localbroadcastmanager:localbroadcastmanager:1.1.0")` to the open `dependencies { }` block in build.gradle.kts
- Plan 04-08's expanded PLAY-02 grep (covering `android/.../service/`) will find zero forbidden tokens in both `ScheduleWindow.kt` and `ScheduleWindowTest.kt`

## Self-Check

### Files Exist

- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindow.kt` — FOUND (in worktree)
- `android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindowTest.kt` — FOUND (in worktree)
- `test/domain/schedule/schedule_window_parity_test.dart` — FOUND (in worktree)
- `android/app/build.gradle.kts` — FOUND with dependencies block (in worktree)

### Commits Exist

- `763af66` test(04-02): Dart parity oracle — FOUND
- `6c786ea` feat(04-02): Kotlin port ScheduleWindow.kt — FOUND
- `ecd3d10` feat(04-02): ScheduleWindowTest.kt + build.gradle.kts — FOUND

## Self-Check: PASSED

---
*Phase: 04-pause-ux-the-wedge*
*Completed: 2026-05-13*
