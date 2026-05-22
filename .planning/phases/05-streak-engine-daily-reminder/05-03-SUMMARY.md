---
phase: 05-streak-engine-daily-reminder
plan: "03"
subsystem: domain-streak
tags: [streak, rollover, riverpod, kotlin-parity, dst-safety, clock-tamper, tdd-green]
dependency_graph:
  requires: [05-01, 05-02]
  provides: [StreakRolloverService, streakBadgeProvider, streakHistoryProvider, StreakDay.kt]
  affects: [05-04-BootMonotonicPigeon, 05-06-StreakBadgeWidget, 05-07-CheckinScreen]
tech_stack:
  added: []
  patterns: [async-notifier-rollover, 2x2-status-source-matrix, dst-safe-datetime-constructor, soft-cache-60s, 30-day-backfill-cap, riverpod-future-provider-family, kotlin-jvm-unit-test-parity]
key_files:
  created:
    - lib/domain/streak/streak_rollover_service.dart
    - lib/domain/streak/streak_rollover_service_providers.dart
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/StreakDay.kt
  modified:
    - test/domain/streak/streak_rollover_service_test.dart
    - test/domain/streak/streak_rollover_dst_test.dart
    - android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/StreakDayAnchoringTest.kt
    - test/_fixtures/streak_fixture.dart
decisions:
  - "bootNanosProvider injected as a constructor parameter (not global mock) so tests deterministically control the monotonic clock reading before Plan 05-04 wires the real Pigeon method"
  - "StreakRolloverService internal DAO providers use private backing variables re-exported as public providers so tests can override individual DAOs without depending on the providers file"
  - "DST test: lastEvaluatedDay must be set to day-before-processed-day (not the processed day itself) so the cursor loop runs at least one iteration"
  - "streakBadgeProvider falls back to watchForEntry stream first-emit when today's row is absent — no additional DAO method needed"
metrics:
  duration: "~13 minutes"
  completed: "2026-05-22T20:09:00Z"
  tasks_completed: 1
  files_changed: 7
requirements: [STRK-02, STRK-04, STRK-05, STRK-06, STRK-08, STRK-09]
---

# Phase 5 Plan 03: StreakRolloverService (pure-Dart) + Kotlin parity oracle Summary

Pure-Dart `StreakRolloverService` with 2x2 status/source matrix, DST-safe DateTime constructor day-stepping, clock-tamper detection via boot-monotonic divergence, soft-cache idempotency, and 30-day backfill cap; `streakBadgeProvider` exports `({int current, int longest, bool breakDetectedToday})` 3-field record; Kotlin `StreakDay.kt` + `StreakDayAnchoringTest.kt` parity oracle all GREEN.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | StreakRolloverService + providers + Kotlin StreakDay + flip RED stubs GREEN | 492de71 | streak_rollover_service.dart, streak_rollover_service_providers.dart, StreakDay.kt, streak_rollover_service_test.dart, streak_rollover_dst_test.dart, StreakDayAnchoringTest.kt, streak_fixture.dart |

## What Was Built

**StreakRolloverService** (`lib/domain/streak/streak_rollover_service.dart`): `AsyncNotifier<void>` implementing the RESEARCH §4 lazy rollover algorithm:
- Constructor-injected `clock` and `bootNanosProvider` for deterministic test control
- Soft-cache 60s: `_lastCalled` check prevents re-evaluation within 60 seconds
- Clock-tamper detection: `|wallDelta - bootDeltaMs| > Duration(hours:24).inMilliseconds` flags all rolled days `status=2` incomplete-data
- DST-safe day step: `DateTime(cursor.year, cursor.month, cursor.day + 1)` — never `cursor.add(Duration(days:1))`
- 30-day backfill cap: gap days beyond 30 written `status=2` in a batch before the per-day loop
- 2x2 `_resolveDay` matrix (priority-ordered): broken-by-system → broken-by-self-report → success-checkin → success-a11y-fallback → incomplete-data
- `_usageMinutesForEntry`: habit entries (packageName == null) return 0 per RESEARCH §10 R-8
- `_a11yWasOnFor`: current-state proxy; per-day accuracy deferred to v1.x
- Today's row seeded via `upsertIfAbsent(status=3 pending)` — never clobbers finalized rows

**streakBadgeProvider** (`lib/domain/streak/streak_rollover_service_providers.dart`): `FutureProviderFamily<({int current, int longest, bool breakDetectedToday}), int>` — `breakDetectedToday` wired in this plan (not deferred to 05-07). Detection: most recently finalized row `status==1 broken AND evaluatedAt < 24h ago`. Plan 05-07 consumes without mutating the provider.

**StreakDay.kt** (`android/.../service/StreakDay.kt`): Kotlin port of `streakDayFor` — applies 4h subtraction then strips to local midnight using `Calendar`. Parity contract verified by `StreakDayAnchoringTest.kt`.

**StreakDayAnchoringTest.kt** (`android/.../service/StreakDayAnchoringTest.kt`): 3 `@Test` methods (no `@Ignore`) covering cross-midnight-23:00-→-Mon-midnight, 03:00-Tue-→-Mon-midnight, and midday-Tue-→-Tue-midnight.

## Verification Results

- `dart run build_runner build` — exit 0, no codegen regressions
- `flutter test test/domain/streak/streak_rollover_service_test.dart` — **23/23 PASS** (no skips)
- `flutter test test/domain/streak/streak_rollover_dst_test.dart` — **2/2 PASS** (no skips)
- `./gradlew :app:testDebugUnitTest --tests "*.StreakDayAnchoringTest"` — **BUILD SUCCESSFUL** (3/3 tests pass)
- `./gradlew :app:testDebugUnitTest --tests "*.ScheduleWindowTest"` — **BUILD SUCCESSFUL** (Phase 4 oracle untouched)
- `flutter test test/policy/play_invariants_test.dart` — **9/9 PASS** (no PLAY-02 regression)
- `flutter analyze lib/domain/streak/` — 0 errors, 0 warnings (10 info-level only)
- `grep -c 'cursor.add(Duration' streak_rollover_service.dart` = 0 (DST-unsafe pattern absent)
- `grep -c 'DateTime(cursor.year, cursor.month, cursor.day + 1)' streak_rollover_service.dart` = 1 (DST-safe pattern present)
- `grep -c 'soft-cache 60s' streak_rollover_service.dart` = 2 (soft-cache region marked)
- `grep -c 'Duration(hours: 24).inMilliseconds' streak_rollover_service.dart` = 2 (24h tamper threshold)
- `grep -c 'fun streakDayFor(' StreakDay.kt` = 1
- `grep -c 'breakDetectedToday' streak_rollover_service_providers.dart` = 6
- `grep -c 'int current, int longest, bool breakDetectedToday' streak_rollover_service_providers.dart` = 3
- `grep -c 'breakDetectedToday' streak_rollover_service_test.dart` = 8 (≥4 dedicated tests)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] DST test: lastEvaluatedDay set to processed-day instead of day-before**
- **Found during:** Task 1 (DST test run)
- **Issue:** Both DST tests set `lastEvaluatedDay = processed_day` (e.g., March 7). The cursor starts at `lastEvaluatedDay + 1 = March 8 = today`, so the per-day loop is empty and no row is written for March 7.
- **Fix:** Changed `lastEvaluatedDay` to `processed_day - 1` (March 6 / Oct 31) so cursor = processed_day, which is before today → loop executes.
- **Files modified:** `test/domain/streak/streak_rollover_dst_test.dart`
- **Commit:** 492de71 (inline fix)

**2. [Rule 1 - Bug] Clock-tamper test: bootNanosProvider defaulting to 0 caused false divergence**
- **Found during:** Task 1 (test run — "no tamper detected" test failed)
- **Issue:** When `bootNanosProvider` returns 0 (default) but `lastBootNs` in prefs was set to 24h_in_ns, the bootDeltaMs became `(0 - 24h_in_ns) / 1000000` — a large negative → huge divergence → "no tamper" test wrongly flagged tamper.
- **Fix:** (1) Added `bootNanosProvider` as constructor parameter on `StreakRolloverService`; (2) Updated `buildContainer` in test to accept and pass `bootNanosProvider`; (3) Updated tamper tests to pass explicit boot nano values and set `lastBootNs=0` in prefs so the delta math is well-defined.
- **Files modified:** `lib/domain/streak/streak_rollover_service.dart`, `test/domain/streak/streak_rollover_service_test.dart`
- **Commit:** 492de71 (inline fix)

**3. [Rule 3 - Blocking] `DailyStreakData` not importable from providers file**
- **Found during:** Task 1 (analyze run)
- **Issue:** Used `export` directive but the `DailyStreakData` type is generated in `app_database.g.dart` part file — it's importable via `app_database.dart` but an `export` in the same file doesn't make the type visible to the file's own code.
- **Fix:** Changed to `import 'package:not_to_do_list/data/database/app_database.dart' show DailyStreakData;`
- **Files modified:** `lib/domain/streak/streak_rollover_service_providers.dart`
- **Commit:** 492de71 (inline fix)

**4. [Rule 3 - Blocking] Missing `import 'package:drift/drift.dart'` in test files**
- **Found during:** Task 1 (test compilation)
- **Issue:** `Value(...)` constructor from Drift not found in `streak_rollover_service_test.dart` and `streak_rollover_dst_test.dart`.
- **Fix:** Added `import 'package:drift/drift.dart' hide isNull, isNotNull;` to both test files.
- **Files modified:** `test/domain/streak/streak_rollover_service_test.dart`, `test/domain/streak/streak_rollover_dst_test.dart`
- **Commit:** 492de71 (inline fix)

## Known Stubs

**`_a11yWasOnFor()`** in `lib/domain/streak/streak_rollover_service.dart`: uses current `isAccessibilityServiceEnabled()` state as a proxy rather than a historical per-day reading. Days where a11y was on earlier in the day but off now may be under-counted. Documented in doc-comment as v1.x follow-up when `a11y_enabled_since` timestamp is persisted. Does NOT prevent the plan's streak goal from being achieved — honest fallback to `status=2 incomplete-data` is the correct v1 behavior.

**`bootNanosProvider` defaults to `() async => 0`**: until Plan 05-04 wires `PermissionStatusApi.bootMonotonicNanos()`, the monotonic clock always returns 0. This means clock-tamper detection has zero sensitivity until 05-04 lands. Acceptable per plan sequencing (05-03 may land before 05-04 since tests mock the API).

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns. The clock-tamper boundary (T-05-07) is mitigated by the `_resolveDay` matrix tests. The DST false-positive threat (T-05-08) is mitigated by the grep-gate and DST test pair.

## Self-Check: PASSED

- `lib/domain/streak/streak_rollover_service.dart` — FOUND
- `lib/domain/streak/streak_rollover_service_providers.dart` — FOUND
- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/StreakDay.kt` — FOUND
- `test/domain/streak/streak_rollover_service_test.dart` — FOUND (no skips)
- `test/domain/streak/streak_rollover_dst_test.dart` — FOUND (no skips)
- `android/app/src/test/kotlin/.../StreakDayAnchoringTest.kt` — FOUND (no @Ignore)
- Commit 492de71 — FOUND
