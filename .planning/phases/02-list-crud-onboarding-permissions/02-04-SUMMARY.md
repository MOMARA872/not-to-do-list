---
phase: 2
plan: 04
subsystem: data-layer
wave: 2
status: complete
tags: [drift, dao, repository, riverpod, schedule-window, streak-day, phase-2-wave-2]
requires:
  - 02-01 (Wave 0 — block_list_repo_test.dart + is_in_window_test.dart stubs)
  - 02-02 (Wave 1 — block_list v2 schema + PRAGMA foreign_keys = ON)
provides:
  - BlockListDao @DriftAccessor with 7 typed methods (getAll, watchAll, getById, insertEntry, insertMany, updateEntry, deleteEntryById)
  - BlockListRepository — domain-language seam UI consumes (add, insertMany, updateEntry, delete, getAll, watchAll, getById)
  - blockListDaoProvider + blockListRepoProvider hand-written Riverpod providers
  - isInScheduleWindow pure-Dart helper (3-nullable-together; half-open [start, end); cross-midnight uses START-day weekday)
  - streakDayFor pure-Dart helper (04:00 local boundary)
  - 13 WIN-NN truth-table tests passing + 9 repo round-trip tests passing
affects:
  - lib/data/database/app_database.dart (added daos: [BlockListDao] to @DriftDatabase)
  - lib/data/database/app_database.g.dart (regenerated — exposes blockListDao)
  - test/domain/schedule/is_in_window_test.dart (Wave 0 stub → 13 real tests)
  - test/data/repositories/block_list_repo_test.dart (Wave 0 stub → 9 real tests)
tech-stack:
  added: []
  patterns:
    - "Drift `@DriftAccessor(tables: [BlockList])` DAO mixed with `_$BlockListDaoMixin`. Registered via `daos: [BlockListDao]` on `@DriftDatabase`; codegen exposes `late final BlockListDao blockListDao` on AppDatabase."
    - "Hand-written Riverpod `Provider<T>` chained from `databaseProvider` (Phase 1 pattern; no `@riverpod` codegen due to Plan 01-01 analyzer-pin conflict). Single-line provider per file."
    - "Repository owns the `DateTime.now()` calls so DAO stays a pure typed-CRUD seam. `updateEntry` reads existing row, preserves immutable fields (kind, packageName, createdAt, streakBreakThresholdMinutes), bumps `updatedAt` for LIST-06 sort."
    - "Pure-Dart domain helper under `lib/domain/schedule/`: no Flutter / no Riverpod imports. Top-level function (not class); RESEARCH §Schedule Active-Window Evaluation copied verbatim."
    - "Repo round-trip tests use `AppDatabase(NativeDatabase.memory())` + direct DAO instantiation; cascade-delete test inserts a `pause_events` child via `db.into(db.pauseEvents)` then asserts the child is gone post-`repo.delete`."
key-files:
  created:
    - lib/data/database/daos/block_list_dao.dart
    - lib/data/database/daos/block_list_dao.g.dart
    - lib/data/repositories/block_list_repository.dart
    - lib/domain/schedule/schedule_window.dart
    - lib/domain/schedule/streak_day.dart
    - lib/domain/providers/block_list_dao_provider.dart
    - lib/domain/providers/block_list_repo_provider.dart
  modified:
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart
    - test/data/repositories/block_list_repo_test.dart
    - test/domain/schedule/is_in_window_test.dart
decisions:
  - "BlockListDao.insertMany returns Future<void>, not the plan's Future<List<int>>. Drift's batch() does not surface inserted ids and Phase 2 callers (quick-add seeding) do not need them. CLAUDE.md simplicity-first."
  - "Created lib/data/database/daos/ subdirectory to mirror lib/data/database/tables/ (per 02-PATTERNS.md §DAOs: GAP)."
  - "BlockListRepository.add takes named-only params; packageName is optional (null for habits, kind=1). reasonNote and blockMode have safe defaults ('' and 'soft'). Schedule trio is all-nullable."
  - "BlockListRepository.updateEntry preserves immutable fields by re-reading the row, not by trusting caller-supplied values. Caller cannot accidentally mutate kind/packageName/createdAt/streakBreakThresholdMinutes through the seam."
  - "Test deviation: bumped LIST-04/LIST-06 setUp wait from 10ms to 1100ms. Drift's default DateTime storage is integer seconds, so 10ms collapses to the same second and the updatedAt isAfter/sort assertions flake. Rule 1 (auto-fix bug)."
  - "Used the existing test file path test/domain/schedule/is_in_window_test.dart rather than creating schedule_window_test.dart (per plan frontmatter). The Wave 0 stub already lived at the former; surgical-changes principle (CLAUDE.md §3) — don't move what isn't broken."
metrics:
  duration_minutes: ~25
  tasks_completed: 3
  test_files_created: 0
  test_files_modified: 2
  files_created: 7 (5 source + 2 generated/touched)
  files_modified: 4
  flutter_test_result: "All tests passed (+48 ~13 — 13 newly passing WIN tests + 9 newly passing repo tests vs Plan 02-02 baseline of +11 ~30; remainder from sibling 02-05 wave 2 commits interleaved on this branch)"
  dart_analyze_errors: 0
  dart_analyze_warnings: 0
completed: 2026-05-07
---

# Phase 2 Plan 04: BlockList DAO + Repository + Schedule Helper Summary

Layered Drift `BlockListDao` + `BlockListRepository` on top of the v2 schema from Plan 02-02, exposed them via hand-written Riverpod providers (`blockListDaoProvider`, `blockListRepoProvider`), and shipped the pure-Dart `isInScheduleWindow` helper with the 13-row truth table from RESEARCH §Schedule Active-Window Evaluation plus the `streakDayFor(now)` 04:00-boundary utility. All 13 WIN-NN tests + 9 repository round-trip tests pass; cascade-delete from Plan 02-02 still passes via the same `repo.delete` path.

## Tasks Completed

| Task     | Name                                                                        | Commit    | Files                                                                                                                                                                |
| -------- | --------------------------------------------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 02-04-01 | `BlockListDao` @DriftAccessor + register on AppDatabase                     | `082fc61` | `lib/data/database/daos/block_list_dao.dart`, `lib/data/database/daos/block_list_dao.g.dart`, `lib/data/database/app_database.dart`, `lib/data/database/app_database.g.dart` |
| 02-04-02 | `BlockListRepository` + DAO/repo Riverpod providers + 9 round-trip tests    | `cbe2a35` | `lib/data/repositories/block_list_repository.dart`, `lib/domain/providers/block_list_dao_provider.dart`, `lib/domain/providers/block_list_repo_provider.dart`, `test/data/repositories/block_list_repo_test.dart` |
| 02-04-03 | `isInScheduleWindow` + `streakDayFor` + 13 WIN-NN truth-table tests         | `fff2756` | `lib/domain/schedule/schedule_window.dart`, `lib/domain/schedule/streak_day.dart`, `test/domain/schedule/is_in_window_test.dart`                                     |

## Files Created / Modified

**Created (7):**
- `lib/data/database/daos/block_list_dao.dart` — `@DriftAccessor(tables: [BlockList])` with `getAll`/`watchAll`/`getById`/`insertEntry`/`insertMany`/`updateEntry`/`deleteEntryById`. Sort key is `updatedAt` desc.
- `lib/data/database/daos/block_list_dao.g.dart` — generated mixin + table-manager.
- `lib/data/repositories/block_list_repository.dart` — domain-language wrapper. `add` (named-only with safe defaults), `insertMany` (quick-add seed taking a `BlockListSeed` record list), `updateEntry` (preserves immutable fields by re-reading), `delete`, `getAll`, `watchAll`, `getById`.
- `lib/domain/schedule/schedule_window.dart` — pure-Dart `bool isInScheduleWindow({...})`. Three-nullable-together returns false; same-day `[start, end)` half-open; cross-midnight uses START-day weekday for both halves.
- `lib/domain/schedule/streak_day.dart` — pure-Dart `DateTime streakDayFor(DateTime now)`. 04:00 local-time boundary.
- `lib/domain/providers/block_list_dao_provider.dart` — `final Provider<BlockListDao> blockListDaoProvider` reading `databaseProvider`.
- `lib/domain/providers/block_list_repo_provider.dart` — `final Provider<BlockListRepository> blockListRepoProvider` reading the DAO provider.

**Modified (4):**
- `lib/data/database/app_database.dart` — added `import` + `daos: [BlockListDao]` to the `@DriftDatabase` annotation.
- `lib/data/database/app_database.g.dart` — regenerated; exposes `late final BlockListDao blockListDao = BlockListDao(this as AppDatabase)`.
- `test/data/repositories/block_list_repo_test.dart` — Wave 0 stub replaced with 9 real tests covering LIST-02 through LIST-09 + cascade-delete.
- `test/domain/schedule/is_in_window_test.dart` — Wave 0 stub replaced with 13 real WIN-NN truth-table assertions.

## REQ-ID Coverage

| REQ-ID  | Demonstrated by                                                                                                  |
| ------- | ---------------------------------------------------------------------------------------------------------------- |
| LIST-02 | `repo.add(kind: 1, …)` for habit; `kind: 0, packageName: …` for app — round-trip test passes.                    |
| LIST-03 | 500-char `reasonNote` round-trips intact (no truncation).                                                        |
| LIST-04 | `repo.updateEntry` overwrites name + reason + blockMode + schedule and bumps `updatedAt` (>1s gap proven).        |
| LIST-05 | `repo.delete` removes the row AND child `pause_events` row (cascade test); PRAGMA from Plan 02-02 still hot.     |
| LIST-06 | `repo.getAll` returns rows ordered by `updatedAt` desc; touched-id1 bubbles above id2 after `updateEntry`.        |
| LIST-07 | `repo.insertMany` seeds the curated 5 (Instagram, TikTok, X, YouTube, Reddit) regardless of install status.       |
| LIST-08 | `blockMode` round-trips exactly as 'soft' or 'hard'; default is 'soft'.                                          |
| LIST-09 | Schedule trio round-trips when all three non-null; `isInScheduleWindow` 13/13 truth-table cases pass.            |

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] Bumped LIST-04 / LIST-06 inter-write delay 10 ms → 1100 ms**
- **Found during:** Task 02-04-02 first run (LIST-04 failed `after.updatedAt.isAfter(before)` returning false).
- **Issue:** Drift's default `DateTimeColumn` storage is integer seconds-since-epoch (per the regenerated `app_database.g.dart`: `type: DriftSqlType.dateTime` maps to `INTEGER` storing `microsecondsSinceEpoch ÷ 1_000_000`). The plan's 10 ms delay between `add` and `updateEntry` collapses to the same stored second, so `isAfter` returns `false` and the desc-order sort in LIST-06 ties.
- **Fix:** Bumped both delays to 1100 ms — the minimum reliable gap for seconds-precision storage.
- **Files modified:** `test/data/repositories/block_list_repo_test.dart`
- **Commit:** `cbe2a35`
- **Trade-off:** the test suite gains ~3.4 s of wall-clock time (2 × 1.1 s in LIST-04 + 2 × 1.1 s in LIST-06). Wave 5 may switch the schema to TEXT-stored ISO datetimes (`storeDateTimeAsText: true`) to recover sub-second precision; not in 02-04 scope.

**2. [Rule 2 — Missing critical functionality] `BlockListRepository.updateEntry` preserves immutable fields**
- **Found during:** drafting the repository contract.
- **Issue:** the plan's `updateEntry` signature only takes `displayName` / `reasonNote` / `blockMode` / schedule trio. If the caller could mutate `kind`, `packageName`, `createdAt`, or `streakBreakThresholdMinutes` through the seam, edit-screen widgets could silently corrupt entries (e.g., flipping a habit row to an app row). The repository now reads the existing row first and re-supplies those four columns from the DB, not from the caller. Karpathy §3 (surgical) — the seam refuses to accept what shouldn't be mutated.
- **Fix:** `updateEntry` does a `getById` first; if the row is gone (TOCTOU race with `delete`), the call is a no-op rather than re-creating the row.
- **Files modified:** `lib/data/repositories/block_list_repository.dart`
- **Commit:** `cbe2a35`

### Surgical adjustments to plan text

**3. `insertMany` returns `Future<void>` instead of `Future<List<int>>`.** The plan body acknowledges that Drift's `batch()` does not surface inserted ids ("re-query by createdAt to retrieve the most-recent insertions if needed. For Phase 2 quick-add, the caller does not need the ids — return an empty list."). Returning an always-empty list is misleading; honest signatures are smaller. Both DAO and repo expose `Future<void>`. CLAUDE.md §2.

**4. Used `super.attachedDatabase`, not `super.db`, in BlockListDao constructor.** `very_good_analysis 10.2.0` flags `matching_super_parameters` because the super constructor parameter is named `attachedDatabase`. Plan example used `super.db`; renamed to silence the lint without an `// ignore_for_file:` directive.

**5. Stayed on the existing test file path `test/domain/schedule/is_in_window_test.dart`.** The plan frontmatter listed this file; the prompt's verification list mentioned `schedule_window_test.dart`. The Wave 0 stub already lived at `is_in_window_test.dart` — surgical-changes principle: don't move what isn't broken. The 13 WIN tests are filled in place.

### Removed-from-scope (Karpathy §2)

None. The plan's three tasks were complete in scope.

### Auth gates

None. All work is local code + Drift in-memory tests; no native APIs touched.

### Architectural changes (Rule 4)

None. The plan was an additive layer on top of frozen Phase 2 schema.

## Verification

- [x] `lib/data/database/daos/block_list_dao.dart` exists and contains literal `@DriftAccessor(tables: [BlockList])` and `class BlockListDao extends DatabaseAccessor<AppDatabase>`.
- [x] All 7 method names appear: `getAll`, `watchAll`, `getById`, `insertEntry`, `insertMany`, `updateEntry`, `deleteEntryById`.
- [x] `lib/data/database/app_database.dart` `@DriftDatabase(...)` contains literal `daos: [BlockListDao]`.
- [x] `lib/data/database/app_database.g.dart` contains literal `BlockListDao blockListDao` (generated as `late final BlockListDao blockListDao = BlockListDao(this as AppDatabase);`).
- [x] `lib/data/repositories/block_list_repository.dart` declares `class BlockListRepository` with `add`, `insertMany`, `updateEntry`, `delete`, `getAll`, `watchAll`, `getById`.
- [x] `lib/domain/providers/block_list_dao_provider.dart` declares `final Provider<BlockListDao> blockListDaoProvider`.
- [x] `lib/domain/providers/block_list_repo_provider.dart` declares `final Provider<BlockListRepository> blockListRepoProvider`.
- [x] Neither provider file contains `@riverpod` annotation or `part '` directive.
- [x] `lib/domain/schedule/schedule_window.dart` contains literal `bool isInScheduleWindow({` and the null-guard `if (startMinutes == null || endMinutes == null || weekdayMask == null)`.
- [x] No `package:flutter` or `package:flutter_riverpod` import in `lib/domain/schedule/schedule_window.dart`.
- [x] `lib/domain/schedule/streak_day.dart` contains literal `const Duration(hours: 4)`.
- [x] `test/domain/schedule/is_in_window_test.dart` contains exactly 13 `test('WIN-` declarations (verified `grep -c` = 13).
- [x] `flutter test test/data/repositories/block_list_repo_test.dart` exits 0; all 9 tests pass.
- [x] `flutter test test/domain/schedule/is_in_window_test.dart` exits 0; all 13 tests pass (none skipped).
- [x] Full `flutter test`: All tests passed (+48 ~13).
- [x] `dart analyze` on modified files: No issues found.

## TDD Gate Compliance

This plan is `type: execute` (not `type: tdd`), so the plan-level RED/GREEN/REFACTOR gate does not apply. Per-task commits use conventional types: `feat(02-04)` for the three tasks because each ships production code + tests in the same atomic unit (the Wave 0 stubs already existed and were filled in lockstep with the production code they exercise).

## Self-Check: PASSED

**File existence:**
- ✓ FOUND: lib/data/database/daos/block_list_dao.dart
- ✓ FOUND: lib/data/database/daos/block_list_dao.g.dart
- ✓ FOUND: lib/data/repositories/block_list_repository.dart
- ✓ FOUND: lib/domain/schedule/schedule_window.dart
- ✓ FOUND: lib/domain/schedule/streak_day.dart
- ✓ FOUND: lib/domain/providers/block_list_dao_provider.dart
- ✓ FOUND: lib/domain/providers/block_list_repo_provider.dart

**Commit existence:**
- ✓ FOUND: 082fc61 (feat(02-04): add BlockListDao + register on AppDatabase)
- ✓ FOUND: cbe2a35 (feat(02-04): add BlockListRepository + DAO/repo providers + round-trip tests)
- ✓ FOUND: fff2756 (feat(02-04): add isInScheduleWindow + streakDayFor + 13-row truth table)

## Wave 3 Hand-off Notes

Plans 02-06 (edit screen) and 02-08 (onboarding quick-add finalize / home wiring) can now build on:

1. **`blockListRepoProvider` is the single seam.** UI code never touches `BlockListDao` directly. Public surface:
   - `repo.add({required int kind, required String displayName, String? packageName, String reasonNote = '', String blockMode = 'soft', int? scheduleStartMinutes, int? scheduleEndMinutes, int? scheduleWeekdayMask}) → Future<int>`
   - `repo.insertMany(List<({int kind, String? packageName, String displayName})>) → Future<void>` (quick-add seed; uses default `block_mode='soft'` and null schedule)
   - `repo.updateEntry({required int id, required String displayName, required String reasonNote, required String blockMode, int? scheduleStartMinutes, int? scheduleEndMinutes, int? scheduleWeekdayMask}) → Future<void>` (no-op if row gone; preserves kind/packageName/createdAt; bumps updatedAt)
   - `repo.delete(int id) → Future<void>` (cascade-deletes children via PRAGMA enabled in Plan 02-02)
   - `repo.getAll() / watchAll() / getById(int)` for read paths

2. **Schedule trio is all-or-nothing.** UI must enforce: passing partial values (e.g., start without mask) is allowed by the schema but breaks `isInScheduleWindow` (which returns false on any null). The edit screen's "Set schedule" toggle should atomically write all three or all three null.

3. **`isInScheduleWindow` is the contract for any "is this entry currently active?" check.** Phase 4 PAUS-10 (interception gate) and Phase 5 STRK-09 (streak attribution) MUST consume this helper, not roll their own.

4. **`streakDayFor(now)` is in `lib/domain/schedule/streak_day.dart`.** Phase 5 streak-rollover code consumes this; do NOT inline a 4-hour shift elsewhere.

5. **Sort order on home today is `updatedAt desc` only.** When Phase 4 lands `pause_events.last_pause_event_time` and Phase 5 lands `daily_checkins.last_check_in_time`, extend the DAO with a query that does `ORDER BY MAX(updatedAt, lastPauseEventTime, lastCheckInTime) DESC`. The DAO method to extend is `getAll` / `watchAll`; the repository's `getAll` / `watchAll` will pick it up transparently.

6. **`BlockListSeed` typedef is the public seed shape.** Quick-add (Plan 02-08) should construct `List<BlockListSeed>` and call `repo.insertMany(...)` rather than calling `repo.add` in a loop — `insertMany` uses Drift's `batch()` for one transaction round-trip.

7. **Test deviation to remember.** Any future repo test that asserts `updatedAt` ordering MUST use ≥1.1 s gaps until/unless the schema migrates DateTime to TEXT-with-microseconds. Sub-second timestamps are silently lost.
