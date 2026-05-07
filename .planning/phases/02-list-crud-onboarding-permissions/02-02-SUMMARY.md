---
phase: 2
plan: 02
subsystem: data-layer
wave: 1
status: complete
tags: [drift, schema-migration, cascade-delete, foreign-keys, phase-2-wave-1]
requires:
  - 02-01 (Wave 0 — drift_schemas/drift_schema_v1.json fixture, stubbed migration_v1_to_v2_test.dart, stubbed cascade_delete_test.dart)
provides:
  - block_list table extended with block_mode (TEXT NOT NULL DEFAULT 'soft') + 3 nullable schedule columns
  - AppDatabase schemaVersion = 2 with onUpgrade addColumn migration
  - PRAGMA foreign_keys = ON in beforeOpen (production fix — was missing; cascade was silently inert without it)
  - test/generated_migrations/{schema.dart, schema_v1.dart} from `dart run drift_dev schema generate`
  - filled migration_v1_to_v2_test.dart (3 tests, all passing) and cascade_delete_test.dart (1 test, passing)
affects:
  - lib/data/database/tables/block_list_table.dart (4 columns added, surgical)
  - lib/data/database/app_database.dart (schemaVersion bump + onUpgrade body + beforeOpen PRAGMA hook)
  - lib/data/database/app_database.g.dart (regenerated)
  - test/data/database/app_database_test.dart (Phase 1 snapshot assertion bumped 1→2)
  - test/data/database/migration_v1_to_v2_test.dart (stub → real)
  - test/data/repositories/cascade_delete_test.dart (stub → real)
  - analysis_options.yaml (added test/generated_migrations/** to exclude list)
tech-stack:
  added: []
  patterns:
    - "Drift `addColumn` migration: NOT-NULL TEXT column with `withDefault(Constant('soft'))` translates to `ALTER TABLE … ADD COLUMN … TEXT NOT NULL DEFAULT 'soft'`, dodging SQLite's drift #457 NOT-NULL-without-default refusal."
    - "Cascade-aware Drift connection: `beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON;'); }` — required because SQLite default is OFF and Drift does not auto-enable. Without this, `onDelete: KeyAction.cascade` is silently inert. Verified via failing test before fix."
    - "Schema verifier round-trip pattern: `verifier.schemaAt(1) → schema.newConnection() → v1.DatabaseAtV1 → insert → close → AppDatabase(schema.newConnection()) → onUpgrade fires → assert post-upgrade columns/values`. Uses independent connections to the same backing rawDatabase per drift_dev/api/migrations_common.dart line 134 docs."
    - "`hide isNull` on `package:drift/drift.dart` import to disambiguate from matcher's `isNull` in test files where both column-side matchers and expect-side matchers coexist."
key-files:
  created:
    - test/generated_migrations/schema.dart
    - test/generated_migrations/schema_v1.dart
  modified:
    - lib/data/database/tables/block_list_table.dart
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart
    - test/data/database/app_database_test.dart
    - test/data/database/migration_v1_to_v2_test.dart
    - test/data/repositories/cascade_delete_test.dart
    - analysis_options.yaml
decisions:
  - "PRAGMA foreign_keys=ON in beforeOpen (Rule 2 deviation). RESEARCH §Cascade-delete behavior asserted Drift auto-enables this; failing cascade_delete_test on NativeDatabase.memory() proved otherwise. One-line production fix; required for LIST-05."
  - "Used `hide isNull` on the drift import in migration_v1_to_v2_test.dart instead of `import 'package:drift/drift.dart' as drift` (more invasive) — surgical fix to a real symbol clash."
  - "Did NOT add a v2 schema fixture or `migrateAndValidate(db, 2)` assertion. The plan only required asserting data survival + correct defaults, which a typed select after the upgrade does. v2 schema dump is the responsibility of the next migration plan when v2→v3 lands. Karpathy #2 (no speculative scope)."
  - "Dropped one of my own additions (`migrateAndValidate` test) when it failed for a known-out-of-scope reason rather than expanding scope to make it pass. Karpathy #1 (think before coding — confess and remove)."
  - "test/generated_migrations/** added to analyzer.exclude. Drift's `schema generate` output uses `TableInfo<Table, dynamic>` raw types that trigger `strict_raw_type` warnings under very_good_analysis 10.2.0. The output is regenerated; matches the existing `**/*.g.dart` pattern."
  - "Used typed Drift API (`PauseEventsCompanion.insert`) in cascade_delete_test rather than the plan's example raw SQL with placeholder column names (`occurred_at`, `action`) — the plan body explicitly says verify against the actual Phase 1 columns and adjust. Real columns: `entryId`, `packageName`, `triggeredAt`, `outcome`."
  - "Bumped `expect(db.schemaVersion, 1)` → `expect(db.schemaVersion, 2)` in Phase 1's app_database_test.dart per plan instruction — a one-line snapshot version bump, not a contract change."
metrics:
  duration_minutes: ~25
  tasks_completed: 3
  test_files_created: 0
  test_files_modified: 3
  generated_files_created: 2 (test/generated_migrations/)
  total_files_created: 2
  total_files_modified: 7
  flutter_test_result: "All tests passed (+11 passing ~30 skipped — 4 newly passing tests vs. Plan 02-01 baseline)"
  dart_analyze_errors: 0
  dart_analyze_warnings: 0_in_modified_files
completed: 2026-05-07
---

# Phase 2 Plan 02: Drift v1→v2 Migration Summary

Extended `block_list` with the four Phase 2 columns (`block_mode` + three nullable schedule columns), bumped `schemaVersion` 1→2 with `onUpgrade` `addColumn` migration, regenerated codegen, replaced the Wave 0 stubs in `migration_v1_to_v2_test.dart` and `cascade_delete_test.dart` with real assertions, and added one production fix not in the plan: `PRAGMA foreign_keys = ON` in `beforeOpen` — without which the cascade-delete contract from Phase 1 (`onDelete: KeyAction.cascade` on `daily_streak` / `pause_events` / `daily_checkins`) was silently inert because SQLite's default is OFF and Drift does not auto-enable.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 02-02-01 | Extend `BlockList` with 4 columns + regenerate Drift codegen | `254a4af` | `lib/data/database/tables/block_list_table.dart`, `lib/data/database/app_database.g.dart` |
| 02-02-02 | Bump `schemaVersion` 1→2 + `onUpgrade` `addColumn` migration; bump Phase 1 test assertion | `7a84d47` | `lib/data/database/app_database.dart`, `test/data/database/app_database_test.dart` |
| 02-02-03 | Generate v1 schema helpers; fill migration round-trip + cascade-delete tests; enable PRAGMA foreign_keys | `500f15e` | `test/generated_migrations/{schema.dart, schema_v1.dart}`, `test/data/database/migration_v1_to_v2_test.dart`, `test/data/repositories/cascade_delete_test.dart`, `lib/data/database/app_database.dart`, `analysis_options.yaml` |

## Files Modified / Created

**Created (2):**
- `test/generated_migrations/schema.dart` — `GeneratedHelper` with `versions = [1]` aggregator. Generated by `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`.
- `test/generated_migrations/schema_v1.dart` — `class DatabaseAtV1 extends GeneratedDatabase` with the verbatim Phase 1 schema (8 columns on `block_list`, no Phase 2 columns) for replay-from-v1 tests.

**Modified (7):**
- `lib/data/database/tables/block_list_table.dart` — appended 4 columns (`blockMode` text-with-default, three nullable int schedule columns) BEFORE `uniqueKeys`. No other declaration touched.
- `lib/data/database/app_database.dart` — `schemaVersion 1 → 2`; `onUpgrade` body fills with 4 `m.addColumn(blockList, blockList.<name>);` calls under `if (from < 2) { … }`; ADDED `beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON;'); }`.
- `lib/data/database/app_database.g.dart` — regenerated via `flutter pub run build_runner build --build-filter="lib/data/database/*.dart"`. Adds `BlockListData.blockMode/scheduleStartMinutes/scheduleEndMinutes/scheduleWeekdayMask` and the corresponding `BlockListCompanion` fields.
- `test/data/database/app_database_test.dart` — Phase 1 snapshot test `expect(db.schemaVersion, 1)` → `expect(db.schemaVersion, 2)`. Per plan, this is a single-line version-tracking edit, not a contract change.
- `test/data/database/migration_v1_to_v2_test.dart` — replaced stub with 3 real tests: `schemaVersion is 2`; `v1 → v2: existing v1 row gets block_mode=soft and null schedules`; `v2 createAll round-trip preserves schedule columns` (cross-midnight 1320→360 + Mon-Fri mask 0x1F).
- `test/data/repositories/cascade_delete_test.dart` — replaced stub with 1 real test: `deleting a block_list row removes child pause_events rows`. Uses typed `PauseEventsCompanion.insert(entryId, packageName, triggeredAt, outcome)` rather than the plan's example raw SQL (which used Phase-1-incorrect column names).
- `analysis_options.yaml` — added `test/generated_migrations/**` to `analyzer.exclude` (mirrors `**/*.g.dart` pattern; drift's `schema generate` output uses raw `TableInfo<Table, dynamic>` types that trigger `strict_raw_type` under `very_good_analysis 10.2.0`).

## REQ-ID Coverage

| REQ-ID | Demonstrated by |
|--------|-----------------|
| LIST-04 (entry editor save) | Schema columns landed; editor wiring is Plan 02-04's job |
| LIST-05 (cascade delete) | `cascade_delete_test.dart` passes — parent delete removes child `pause_events` row |
| LIST-08 (block-mode toggle, Apps only) | `block_list.block_mode` TEXT NOT NULL DEFAULT 'soft'; v1 row migrates with `'soft'`; `'hard'` round-trips; UI is Plan 02-04's job |
| LIST-09 (per-entry schedule) | three nullable INT columns (`schedule_start_minutes`, `schedule_end_minutes`, `schedule_weekday_mask`); v1 row migrates with NULLs; cross-midnight 1320→360 + 0x1F mask round-trips |

(LIST-04 and LIST-05 are also annotated by `requirements:` in the plan frontmatter; the schema columns + cascade contract are the Wave 1 deliverable, with the editor UI and repository wiring landing in Wave 2.)

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 2 — Missing critical functionality] Enabled `PRAGMA foreign_keys = ON`**
- **Found during:** Task 02-02-03 verification (cascade_delete_test failed with `Expected: empty / Actual: [PauseEvent…]`).
- **Issue:** RESEARCH §Cascade-delete behavior claims Drift auto-enables foreign keys: *"Cascade deletes work AS LONG AS SQLite foreign key enforcement is on. Drift turns this on by default via PRAGMA foreign_keys = ON in its connection setup."* This is incorrect — Drift does NOT auto-enable. SQLite's default is OFF (per SQLite docs), so cascades from `daily_streak` / `pause_events` / `daily_checkins` would be silently inert in production AND tests.
- **Fix:** Added `beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON;'); }` to the `MigrationStrategy`. One-line surgical addition — required for LIST-05 correctness in production, not just tests.
- **Files modified:** `lib/data/database/app_database.dart`
- **Commit:** `500f15e`
- **Verification:** cascade_delete_test now passes; all other tests still pass.

**2. [Rule 3 — Blocking issue] Resolved `isNull` symbol collision in migration test**
- **Found during:** Task 02-02-03 first compile of migration_v1_to_v2_test.dart.
- **Issue:** `package:drift/drift.dart` exports a column-side `isNull` matcher; `package:matcher/src/core_matchers.dart` (re-exported through `flutter_test`) exports a value-side `isNull`. Used together in a test file, the compiler can't disambiguate.
- **Fix:** `import 'package:drift/drift.dart' hide isNull;` — surgical, hides only the colliding symbol.
- **Files modified:** `test/data/database/migration_v1_to_v2_test.dart`
- **Commit:** `500f15e`

**3. [Rule 3 — Blocking issue] Excluded test/generated_migrations/** from analyzer**
- **Found during:** Post-Task-02-02-03 analyze run.
- **Issue:** drift_dev's `schema generate` output declares `class BlockList extends Table with TableInfo` (no type parameters), which trips `strict_raw_type` (warning under very_good_analysis 10.2.0). The file's `// ignore_for_file: type=lint,unused_import` directive does not silence warnings, only lints.
- **Fix:** Added `test/generated_migrations/**` to `analyzer.exclude` in `analysis_options.yaml` — matches the existing `**/*.g.dart` exclusion pattern.
- **Files modified:** `analysis_options.yaml`
- **Commit:** `500f15e`

### Removed-from-scope (Karpathy #2 — no speculative scope)

- **Did NOT add `migrateAndValidate(db, 2)` assertion.** I initially added one as a bonus on top of the plan's row-level assertion. It failed with `Unknown schema version 2. Known are 1.` because `GeneratedHelper.versions` is `[1]` only — generating it would require a v2 schema dump (`dart run drift_dev schema dump …`), which is the responsibility of the next migration plan (when v2→v3 lands). Removed the test rather than expanding scope.

### Auth gates

None.

### Architectural changes (Rule 4)

None.

### Out-of-scope, untouched

- `pigeons/`, `lib/platform/`, `android/app/src/main/kotlin/`, `MainActivity.kt` — sibling 02-03's territory. Not touched.
- The 18 info-level lints from `dart analyze` at HEAD are all in 02-01-stub `test/_fixtures/permission_status_mock.dart` and 02-03's `pigeons/*.dart` files. None in files I modified.

## Verification

- [x] `lib/data/database/tables/block_list_table.dart` declares `TextColumn get blockMode => text().withDefault(const Constant('soft'))()` plus three `IntColumn … integer().nullable()()` for schedule columns.
- [x] `lib/data/database/app_database.dart` declares `int get schemaVersion => 2;` and `onUpgrade` calls `m.addColumn(blockList, blockList.<col>)` exactly 4 times under an `if (from < 2)` guard.
- [x] `lib/data/database/app_database.dart` declares `beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON;'); }`. (Rule 2 addition; required for LIST-05.)
- [x] `test/data/database/app_database_test.dart` asserts `expect(db.schemaVersion, 2);` (was 1).
- [x] `test/generated_migrations/schema_v1.dart` declares `class DatabaseAtV1 extends GeneratedDatabase`.
- [x] `test/data/database/migration_v1_to_v2_test.dart` opens v1 schema via `verifier.schemaAt(1)`, inserts a v1-shape row, reopens via `AppDatabase(schema.newConnection())`, asserts `rows[0].blockMode == 'soft'` + three `isNull` schedule columns + preserved `displayName`/`packageName`. Plus a v2 createAll round-trip with cross-midnight schedule (1320→360, mask 0x1F).
- [x] `test/data/repositories/cascade_delete_test.dart` inserts a parent + child, deletes the parent via `(db.delete(db.blockList)..where((t) => t.id.equals(parentId))).go()`, asserts the child is empty post-delete.
- [x] `flutter test` exits 0: `+11 passing, ~30 skipped, 0 failures` (4 newly passing vs. Plan 02-01 baseline of `+6 ~32`).
- [x] `dart analyze lib/data/database/ test/data/database/ test/data/repositories/` → `No issues found!`
- [x] All `<acceptance_criteria>` in the plan tasks pass (literal greps + flutter test exit codes).

## TDD Gate Compliance

This plan is `type: execute` (not `type: tdd`), so the RED/GREEN/REFACTOR plan-level gate does not apply. Commits use the conventional types: `feat(02-02)` for code changes (Tasks 1+2) and `test(02-02)` for the test-fill task (Task 3, which also includes a one-line production fix bundled in the same commit because the failing test forced the fix).

## Self-Check: PASSED

**File existence (all 9 touched files):**
- ✓ FOUND: lib/data/database/tables/block_list_table.dart
- ✓ FOUND: lib/data/database/app_database.dart
- ✓ FOUND: lib/data/database/app_database.g.dart
- ✓ FOUND: test/data/database/app_database_test.dart
- ✓ FOUND: test/data/database/migration_v1_to_v2_test.dart
- ✓ FOUND: test/data/repositories/cascade_delete_test.dart
- ✓ FOUND: test/generated_migrations/schema.dart
- ✓ FOUND: test/generated_migrations/schema_v1.dart
- ✓ FOUND: analysis_options.yaml

**Commit existence:**
- ✓ FOUND: 254a4af (feat(02-02): extend block_list with block_mode + 3 schedule columns)
- ✓ FOUND: 7a84d47 (feat(02-02): bump Drift schemaVersion 1→2 with addColumn migration)
- ✓ FOUND: 500f15e (test(02-02): fill v1→v2 migration + cascade-delete tests; enable PRAGMA fkeys)

## Wave 2 Hand-off Notes

Plans 02-04 and 02-05 can now build on:

1. **`BlockListData` data class has `blockMode/scheduleStartMinutes/scheduleEndMinutes/scheduleWeekdayMask`** as fields — the editor screen's form state can read/write these typed values directly via Drift companions. No migration concern; the schema is at v2 and stable.
2. **Cascade delete is hot.** `(db.delete(db.blockList)..where(…)).go()` removes the parent AND all referencing children in `daily_streak` / `pause_events` / `daily_checkins`. No manual cleanup needed; Phase 1's FK declarations are now actually enforced (PRAGMA fix).
3. **No DAO yet.** Direct `db.into(db.blockList).insert(…)` and `db.select(db.blockList)` are the current API; Plan 02-04 may introduce a `BlockListDao` under `@DriftAccessor(tables: [BlockList])` and add it to `daos: [BlockListDao]` in `@DriftDatabase`. Per 02-PATTERNS.md §"DAOs: GAP" — keep the directory `lib/data/database/daos/` to mirror `tables/`.
4. **The `is_in_window_test.dart` truth-table (13 WIN-NN tests, currently `skip: 'pending Plan 02-04'`)** is the contract for the schedule active-window helper Plan 02-04 will implement. Storage-side `(start_minutes, end_minutes, weekday_mask)` triple is now in the table; the `is_in_window` helper consumes them.
5. **`schedule_*` columns are nullable AS A TRIPLE.** Convention from 02-CONTEXT.md: an entry has a schedule iff all three are non-null. The repository / form layer should enforce this — Drift won't.
6. **`block_mode` is a free TEXT column with no enum codec.** Validation (`'soft'` | `'hard'`) lives at the domain layer, not the schema. RESEARCH explicitly defers enum codecs.
7. **`beforeOpen` PRAGMA hook is a single point of contact.** If a future plan adds another PRAGMA (e.g. `synchronous = NORMAL` for performance), append to the same `beforeOpen` block; do not introduce a second.
