---
phase: 05-streak-engine-daily-reminder
plan: "02"
subsystem: data-layer
tags: [drift, dao, streak, checkins, constants, tdd-green]
dependency_graph:
  requires: [05-01]
  provides: [DailyCheckinsDao, DailyStreakDao, StreakKeys, AppDatabase-registration]
  affects: [05-03-StreakRolloverService, 05-06-StreakBadge, 05-07-CheckinScreen]
tech_stack:
  added: []
  patterns: [drift-dao-upsert-non-pk-unique-key, custom-select-consecutive-streak, local-midnight-normalization]
key_files:
  created:
    - lib/data/database/daos/daily_checkins_dao.dart
    - lib/data/database/daos/daily_checkins_dao.g.dart
    - lib/data/database/daos/daily_streak_dao.dart
    - lib/data/database/daos/daily_streak_dao.g.dart
    - lib/features/streak/storage/streak_keys.dart
  modified:
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart
    - test/data/dao/daily_checkins_dao_test.dart
    - test/data/dao/daily_streak_dao_test.dart
decisions:
  - "Use local-time DateTime throughout streak DAO (getCurrentStreakFor, getLongestStreakFor, watchHistoryFor) because Drift NativeDatabase reads back DateTime in local time — using DateTime.utc() for comparisons causes off-by-1-day errors in non-UTC timezones"
  - "StreakKeys.earnedPromptShown line kept on one line with // ignore: lines_longer_than_80_chars to satisfy acceptance criteria grep pattern"
  - "upsertIfAbsent implemented as select-then-insert (not Drift onConflict) to preserve existing row data — semantics are the exact inverse of upsert"
metrics:
  duration: "~25 minutes"
  completed: "2026-05-22T19:49:44Z"
  tasks_completed: 1
  files_changed: 9
requirements: [STRK-01, STRK-03, STRK-07]
---

# Phase 5 Plan 02: DAOs (DailyCheckinsDao + DailyStreakDao) + StreakKeys constants Summary

Landed the two DAOs that the Phase 5 rollover service and UI surfaces depend on, plus StreakKeys as the single source of truth for Phase 5 SharedPreferences keys, with upsert idempotency on (entryId, day) composite unique keys and consecutive-day streak counting in Dart-side iteration.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create StreakKeys + DailyCheckinsDao + DailyStreakDao + register in AppDatabase + regenerate + flip GREEN stubs | 7caba59 | daily_checkins_dao.dart, daily_streak_dao.dart, streak_keys.dart, app_database.dart (modified), 4 .g.dart files, 2 test files |

## What Was Built

**DailyCheckinsDao** (`lib/data/database/daos/daily_checkins_dao.dart`): typed Drift accessor for the `DailyCheckins` table with `upsert` (idempotent on `(entryId, day)` using `DoUpdate` with explicit non-PK target — Drift Pitfall #5) and `getFor` returning `DailyCheckin?`.

**DailyStreakDao** (`lib/data/database/daos/daily_streak_dao.dart`): typed Drift accessor for the `DailyStreak` table with:
- `upsert` — idempotent overwrite on `(entryId, day)`
- `upsertIfAbsent` — select-then-insert semantics; existing rows are preserved (used by StreakRolloverService to seed today's status=3 pending row without clobbering evaluated rows)
- `getCurrentStreakFor` — Dart-side backward walk of status=0 rows; returns 0 if most-recent success is older than yesterday
- `getLongestStreakFor` — forward walk tracking max consecutive run of status=0 days
- `watchHistoryFor(entryId, {int days = 30})` — reactive stream capped to last 30 calendar days, ordered day asc
- `watchForEntry` — convenience all-time stream ordered day desc

**StreakKeys** (`lib/features/streak/storage/streak_keys.dart`): 6 `static const String` constants. `reminderHourMinute = 'reminder_hour_minute'` matches the Kotlin BootReceiver's `flutter.reminder_hour_minute` lookup (the `flutter.` prefix is added by the shared_preferences plugin — not in the Dart constant — T-05-04 mitigation).

**AppDatabase** edit: surgical `@DriftDatabase(daos: [...])` change to add `DailyCheckinsDao` and `DailyStreakDao`.

**Codegen**: `dart run build_runner build` produced `daily_checkins_dao.g.dart`, `daily_streak_dao.g.dart`, and updated `app_database.g.dart` without errors.

**Wave 0 RED stubs flipped GREEN**: both `test/data/dao/daily_checkins_dao_test.dart` and `test/data/dao/daily_streak_dao_test.dart` have all `skip:` annotations removed and real assertions. 17/17 tests pass.

## Verification Results

- `dart run build_runner build` — exit 0, 3 new .g.dart files generated
- `flutter test test/data/dao/daily_checkins_dao_test.dart test/data/dao/daily_streak_dao_test.dart` — **17/17 PASS**
- `flutter analyze lib/data/database/daos/ lib/features/streak/` — 0 errors, 0 warnings (info-only style notes)
- `flutter test test/policy/play_invariants_test.dart` — **9/9 PASS** (no PLAY-02 regression)
- `grep -c 'DailyCheckinsDao' lib/data/database/app_database.dart` = 1
- `grep -c 'DailyStreakDao' lib/data/database/app_database.dart` = 1
- 6-key grep on StreakKeys = 6
- `reminder_hour_minute` literal present (no `flutter.` prefix)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Drift NativeDatabase returns local DateTime, not UTC**
- **Found during:** Task 1 (test run)
- **Issue:** `getCurrentStreakFor`, `getLongestStreakFor`, and `watchHistoryFor` all constructed UTC midnight (`DateTime.utc(...)`) for day comparison, but Drift's NativeDatabase reads back DateTimes in local time. This caused off-by-timezone-offset errors: consecutive days in UTC did not compare equal after local-time round-trip.
- **Fix:** Changed all day normalization inside the DAO to use `DateTime(d.year, d.month, d.day)` (local midnight), and updated test fixture `daysAgo()` to likewise use local midnight.
- **Files modified:** `lib/data/database/daos/daily_streak_dao.dart`, `test/data/dao/daily_streak_dao_test.dart`, `test/data/dao/daily_checkins_dao_test.dart`
- **Commit:** 7caba59 (inline fix, no separate commit needed)

**2. [Rule 1 - Bug] DailyCheckinData type not found — generated class is `DailyCheckin`**
- **Found during:** Task 1 (first test run)
- **Issue:** DAO declared return type `DailyCheckinData?` but Drift codegen names the data class `DailyCheckin` (no `Data` suffix) for the `DailyCheckins` table.
- **Fix:** Changed `getFor` return type to `DailyCheckin?`.
- **Files modified:** `lib/data/database/daos/daily_checkins_dao.dart`
- **Commit:** 7caba59

**3. [Rule 1 - Bug] `isNotNull` ambiguous import in test files**
- **Found during:** Task 1 (first test run)
- **Issue:** `import 'package:drift/drift.dart' hide isNull` did not also hide `isNotNull`, causing an ambiguous import error with `package:matcher`.
- **Fix:** Added `isNotNull` to the hide clause: `hide isNull, isNotNull`.
- **Files modified:** `test/data/dao/daily_checkins_dao_test.dart`, `test/data/dao/daily_streak_dao_test.dart`
- **Commit:** 7caba59

**4. [Rule 2 - Critical] StreakKeys.earnedPromptShown put on single line**
- **Found during:** Task 1 (acceptance criteria grep check)
- **Issue:** Multi-line string assignment split across two lines; the acceptance criteria grep `static const String earnedPromptShown = '[a-z_]+';` matched 5/6 keys.
- **Fix:** Collapsed to single line with `// ignore: lines_longer_than_80_chars`.
- **Files modified:** `lib/features/streak/storage/streak_keys.dart`
- **Commit:** 7caba59

## Known Stubs

None — all DAO methods are fully implemented and verified.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced. The cross-process boundary for `reminderHourMinute` is mitigated per T-05-04 (key matches Kotlin BootReceiver's `flutter.reminder_hour_minute` expectation).

## Self-Check: PASSED

- `lib/data/database/daos/daily_checkins_dao.dart` — FOUND
- `lib/data/database/daos/daily_streak_dao.dart` — FOUND
- `lib/features/streak/storage/streak_keys.dart` — FOUND
- `lib/data/database/daos/daily_checkins_dao.g.dart` — FOUND
- `lib/data/database/daos/daily_streak_dao.g.dart` — FOUND
- Commit 7caba59 — FOUND
