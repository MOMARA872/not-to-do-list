---
phase: 01-foundation-play-declaration
plan: 01-03
subsystem: data/database
tags: [drift, sqlite, schema, riverpod]
dependency_graph:
  requires:
    - "Plan 01-01: Flutter scaffold + drift/drift_dev/drift_flutter pinned in pubspec"
  provides:
    - "AppDatabase (Drift, schemaVersion=1) with 5 tables: block_list, daily_streak, pause_events, daily_checkins, daily_usage_summary"
    - "Riverpod databaseProvider singleton (plain Provider, not @riverpod)"
  affects:
    - "Phase 2 repositories will import AppDatabase via databaseProvider"
tech_stack:
  added: []
  patterns:
    - "Drift codegen output committed to git (lib/data/database/app_database.g.dart, 127KB) so clean checkouts pass tests without prerequisite codegen"
    - "Plain Riverpod Provider for the DB singleton (riverpod_generator was dropped in Plan 01-01)"
key_files:
  created:
    - "lib/data/database/app_database.dart"
    - "lib/data/database/app_database.g.dart"
    - "lib/data/database/tables/block_list_table.dart"
    - "lib/data/database/tables/daily_streak_table.dart"
    - "lib/data/database/tables/pause_events_table.dart"
    - "lib/data/database/tables/daily_checkins_table.dart"
    - "lib/data/database/tables/daily_usage_summary_table.dart"
    - "lib/domain/providers/database_provider.dart"
    - "test/data/database/app_database_test.dart"
  modified: []
decisions:
  - "Used plain `Provider<AppDatabase>` instead of `@Riverpod(keepAlive:true)` — riverpod_generator was dropped in Plan 01-01 due to analyzer-version conflict with pigeon 26.3.4 + Flutter 3.41 (see 01-01-SUMMARY.md). No `database_provider.g.dart` exists or is needed."
  - "Committed `app_database.g.dart` (127KB) to git — clean checkouts can run `flutter test` without prerequisite codegen (success criterion in plan)."
metrics:
  duration: ~4 minutes
  completed: 2026-04-26
---

# Phase 1 Plan 01-03: Drift Schema Summary

Five Drift tables + AppDatabase (schema v1) wired with Riverpod singleton provider; round-trip test green.

## What landed

- 5 Drift table classes (`BlockList`, `DailyStreak`, `PauseEvents`, `DailyCheckins`, `DailyUsageSummary`) at `lib/data/database/tables/*_table.dart`
- `AppDatabase extends _$AppDatabase` at `lib/data/database/app_database.dart` with `@DriftDatabase(tables: [...])` listing all 5 tables in the order specified by the plan, `schemaVersion => 1`, and `MigrationStrategy(onCreate: m.createAll(), onUpgrade: no-op)`
- Drift codegen output committed: `lib/data/database/app_database.g.dart` (3,378 lines, 127KB) containing the `_$AppDatabase` mixin, data classes (`BlockListData`, `DailyStreakData`, etc.), and companion classes (`BlockListCompanion`, etc.)
- Riverpod `databaseProvider` at `lib/domain/providers/database_provider.dart` — plain `Provider<AppDatabase>` with `ref.onDispose(db.close)`
- Round-trip test at `test/data/database/app_database_test.dart`: 3 tests covering schema-presence (all 5 tables in `sqlite_master`), insert+select on `block_list`, and `schemaVersion == 1`

## Pinned versions (pubspec.lock)

| Package | Resolved |
|---------|----------|
| drift | 2.33.0 |
| drift_dev | 2.33.0 |
| drift_flutter | 0.3.0 |
| sqlite3_flutter_libs | (transitive of drift_flutter) |

No version bumps needed during this plan — the pins from Plan 01-01 worked first try.

## Codegen output

```
$ dart run build_runner build --delete-conflicting-outputs
Built with build_runner/aot in 34s; wrote 22 outputs.
```

(Many of those outputs belong to parallel-wave Plan 01-04's Pigeon files; this plan's two outputs are listed below.)

```
$ ls lib/data/database/*.g.dart lib/domain/providers/*.g.dart 2>/dev/null
lib/data/database/app_database.g.dart
```

Note: only **one** `.g.dart` was produced for this plan (not two as the plan's frontmatter listed). `database_provider.g.dart` does NOT exist because we used plain `Provider` instead of `@riverpod`. See "Deviations" below.

## Test report

```
$ flutter test test/data/database/app_database_test.dart -r expanded
00:00 +0: loading test/data/database/app_database_test.dart
00:00 +0: AppDatabase schema v1 round-trip all 5 tables exist after onCreate
00:00 +1: AppDatabase schema v1 round-trip block_list insert + select round-trips
00:00 +2: AppDatabase schema v1 round-trip schemaVersion is 1
00:00 +3: All tests passed!
```

3/3 tests passed in <1s.

## Analyzer

```
$ flutter analyze lib/data/database lib/domain/providers/database_provider.dart test/data/database/app_database_test.dart
Analyzing 3 items...
No issues found! (ran in 11.4s)
```

Note: `flutter analyze` was scoped to plan-01-03 paths because parallel-wave Plans 01-02/01-04 are concurrently writing to other lib/ paths and a full `flutter analyze` pass would have included their in-flight files. The repo-wide `flutter analyze` will be run at the Phase 1 wave-2 gate after all wave-1 plans land.

## Codegen-vs-source consistency check

```
$ dart run build_runner build --delete-conflicting-outputs
Built with build_runner/aot in 5s; wrote 4 outputs.
$ git diff --exit-code lib/data/database/ lib/domain/providers/database_provider.dart
$ echo $?
0
```

Committed codegen matches sources — clean checkouts can run tests without prerequisite codegen.

## Deviations from Plan

### 1. [User-prompt override] `database_provider.dart` uses plain `Provider`, not `@Riverpod`

**Found during:** Task 2.

**Issue:** The plan's `<action>` for Task 2 instructed `@Riverpod(keepAlive: true)` annotation with a generated `database_provider.g.dart` sibling. But the executor prompt explicitly directed: "use plain `Provider` — riverpod_generator was dropped in Phase 1; do not use `@riverpod` annotation". This matches Plan 01-01's documented dependency drop (riverpod_generator pins analyzer minors that conflict with pigeon 26.3.4 — see 01-01-SUMMARY.md).

**Fix:** Wrote `lib/domain/providers/database_provider.dart` as:

```dart
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

No `database_provider.g.dart` is generated or committed.

**Files modified:** `lib/domain/providers/database_provider.dart`

**Acceptance criteria affected:**
- ❌ "contains: `@riverpod`" — replaced with the equivalent plain-Provider singleton pattern. Same behaviour: keepAlive, onDispose closes the DB.
- ❌ "lib/domain/providers/database_provider.g.dart exists" — does not exist; not needed.
- ✅ "Riverpod databaseProvider returns a singleton AppDatabase" — yes, via `Provider<AppDatabase>`.

This is a forward-compat-known deviation already telegraphed by Plan 01-01.

### 2. [Rule 1 - Lint cleanup] Tightened imports + wrapped long lines

**Found during:** Task 2 — first `flutter analyze` produced 14 info-level lints from `very_good_analysis 10.2.0`.

**Issue:** RESEARCH §2 used relative imports (`import 'block_list_table.dart';`) and a few lines exceeded 80 chars. `very_good_analysis` enforces `always_use_package_imports` and `lines_longer_than_80_chars` as info-level lints, and the plan's acceptance criterion is `flutter analyze` exits clean.

**Fix:** Replaced all relative imports of sibling table files with `package:not_to_do_list/...` imports and wrapped 6 long inline-comment lines. After fix: "No issues found!"

**Files modified:**
- `lib/data/database/app_database.dart` (5 imports + 1 comment line)
- `lib/data/database/tables/block_list_table.dart` (1 comment line)
- `lib/data/database/tables/daily_streak_table.dart` (1 import + 3 inline comments moved to dedicated lines)
- `lib/data/database/tables/pause_events_table.dart` (1 import + 2 inline comments moved)
- `lib/data/database/tables/daily_checkins_table.dart` (1 import)

**Verification:** Re-ran codegen after the import edits — `git diff --exit-code` exit 0, generated file unchanged. Tests still 3/3 green.

This is a scoped cleanup of files I just authored (no spillover into adjacent code).

### 3. [Procedural] Test file imports `package:drift/drift.dart` for `Value`

**Found during:** Task 3 — RESEARCH §2 line 466 uses `BlockListCompanion.insert(... packageName: const Value('com.instagram.android') ...)` which requires `Value` from `package:drift/drift.dart`.

**Fix:** Added `import 'package:drift/drift.dart';` to the test file alongside the `package:drift/native.dart` import. RESEARCH §2 omitted this import; verbatim copy would not have compiled.

**Files modified:** `test/data/database/app_database_test.dart`

## Acceptance criteria

| Criterion | Status |
|-----------|--------|
| All 5 Drift table classes exist in lib/data/database/tables/ | PASS |
| @DriftDatabase listing all 5 tables, schemaVersion=1, m.createAll() | PASS |
| app_database.g.dart committed | PASS |
| ~~database_provider.g.dart committed~~ | N/A — see Deviation 1 |
| Riverpod databaseProvider exists with @riverpod / equivalent | PASS (plain Provider) |
| Round-trip test (3 tests: schema-presence, insert+select, schemaVersion) | PASS |
| `flutter analyze` passes (plan-scope) | PASS |
| `flutter test test/data/database/app_database_test.dart -r expanded` passes | PASS (3/3) |
| Phase-1 success criterion #1 (5 tables exist by name) | PASS — verified by sqlite_master query |

## Self-Check: PASSED

Files verified to exist:
- `lib/data/database/app_database.dart` FOUND
- `lib/data/database/app_database.g.dart` FOUND
- `lib/data/database/tables/block_list_table.dart` FOUND
- `lib/data/database/tables/daily_streak_table.dart` FOUND
- `lib/data/database/tables/pause_events_table.dart` FOUND
- `lib/data/database/tables/daily_checkins_table.dart` FOUND
- `lib/data/database/tables/daily_usage_summary_table.dart` FOUND
- `lib/domain/providers/database_provider.dart` FOUND
- `test/data/database/app_database_test.dart` FOUND

Commits verified in `git log`:
- `d5fd10f` (Task 1: 5 tables + AppDatabase) FOUND
- `a0c07e7` (Tasks 2+3: codegen + provider + test) FOUND
