---
phase: 03-screen-time-dashboard
plan: 02
subsystem: database
tags: [drift, sqlite, dao, upsert, reactive-streams, build_runner]

# Dependency graph
requires:
  - phase: 03-01
    provides: Wave 0 test stubs (daily_usage_summary_dao_test.dart template)
  - phase: 01-foundation-play-declaration
    provides: daily_usage_summary table (DailyUsageSummary Drift table, schemaVersion 2)
  - phase: 02-list-crud-onboarding-permissions
    provides: BlockListDao pattern, AppDatabase wiring, app_database.g.dart shape
provides:
  - DailyUsageSummaryDao with upsertDay (idempotent D-14), getTodayFor (D-12 staleness), watchRange (DASH-02/03/04)
  - AppDatabase.dailyUsageSummaryDao accessor (codegen)
  - 4 passing DAO tests in test/data/database/daos/daily_usage_summary_dao_test.dart
affects:
  - 03-03 (UsageRepository depends on DailyUsageSummaryDao)
  - 03-04 (UsageRepository.refreshIfStale uses upsertDay)
  - 03-05 (dashboardRowsProvider uses watchRange)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DoUpdate with explicit target: [packageName, day] to target secondary unique key instead of PK (Pitfall #5 guard)"
    - "DriftAccessor with 3-method minimal surface: upsertDay / getTodayFor / watchRange"

key-files:
  created:
    - lib/data/database/daos/daily_usage_summary_dao.dart
    - lib/data/database/daos/daily_usage_summary_dao.g.dart
    - test/data/database/daos/daily_usage_summary_dao_test.dart
  modified:
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart

key-decisions:
  - "DoUpdate with target: [packageName, day] — insertOnConflictUpdate targets PK by default in Drift; secondary unique keys require explicit DoUpdate.target (discovered at test time)"
  - "schemaVersion stays at 2 — no schema change; Plan 03-02 only adds a DAO, never touches table definitions"
  - "3 methods only — upsertDay, getTodayFor, watchRange — per Karpathy Simplicity First; no getAll/insertOne/deleteAll"

patterns-established:
  - "DAO upsert targeting secondary unique key: use DoUpdate((_) => companion, target: [t.col1, t.col2]) not insertOnConflictUpdate()"

requirements-completed:
  - DASH-02
  - DASH-03
  - DASH-04

# Metrics
duration: 14min
completed: 2026-05-07
---

# Phase 3 Plan 02: DailyUsageSummaryDao + AppDatabase Registration Summary

**Typed Drift DAO over `daily_usage_summary` with idempotent upsert using DoUpdate(target:[packageName, day]) to correctly resolve the secondary unique key instead of the PK**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-05-07T19:22:00Z
- **Completed:** 2026-05-07T19:36:00Z
- **Tasks:** 2
- **Files modified:** 5 (2 hand-written + 2 generated + 1 test)

## Accomplishments

- `DailyUsageSummaryDao` ships with exactly 3 methods: `upsertDay`, `getTodayFor`, `watchRange`
- `upsertDay` correctly targets `(packageName, day)` unique key via `DoUpdate(target: [...])` — plain `insertOnConflictUpdate` would have targeted the PK and thrown `UNIQUE constraint failed` on second call
- `AppDatabase.daos` expanded to `[BlockListDao, DailyUsageSummaryDao]`; `schemaVersion` stays at 2; migration block unchanged
- `build_runner` regenerated `app_database.g.dart` (new `dailyUsageSummaryDao` accessor) and created `daily_usage_summary_dao.g.dart` (`_$DailyUsageSummaryDaoMixin`)
- 4 new DAO tests pass; total suite 128 (124 Phase 2 baseline + 4 new); 8/8 policy invariants green

## Task Commits

Each task was committed atomically:

1. **Task 03-02-01: Create DailyUsageSummaryDao** - `9cf9c72` (feat)
2. **Task 03-02-02: Register on AppDatabase + build_runner + tests** - `2a11be8` (feat)

**Plan metadata:** (SUMMARY commit follows)

## Files Created/Modified

- `lib/data/database/daos/daily_usage_summary_dao.dart` — Drift DAO with upsertDay/getTodayFor/watchRange; DoUpdate targeting secondary unique key
- `lib/data/database/daos/daily_usage_summary_dao.g.dart` — Generated `_$DailyUsageSummaryDaoMixin` + `DailyUsageSummaryDaoManager`
- `lib/data/database/app_database.dart` — Added import + `DailyUsageSummaryDao` to `daos: [...]`; schemaVersion unchanged
- `lib/data/database/app_database.g.dart` — Regenerated; new `dailyUsageSummaryDao` late final accessor on `_$AppDatabase`
- `test/data/database/daos/daily_usage_summary_dao_test.dart` — 4 passing tests (upsert insert, upsert overwrite D-14, watchRange desc DASH-02/03, getTodayFor null)

## Decisions Made

- Used `DoUpdate((_) => companion, target: [dailyUsageSummary.packageName, dailyUsageSummary.day])` instead of `insertOnConflictUpdate()` — Drift's `insertOnConflictUpdate` only resolves conflicts on the primary key by default; the `(packageName, day)` constraint is a secondary unique key and requires an explicit `DoUpdate.target`. Discovered when the upsert-overwrite test threw `UNIQUE constraint failed`.
- `schemaVersion` kept at 2 — verified by grep on `app_database.dart` line `int get schemaVersion => 2;`
- Wave 0 stubs for the DAO test were not yet present (Plan 03-01 runs in a parallel wave), so the test file was created fresh in this plan with 4 real assertions rather than flipping skip flags.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed insertOnConflictUpdate targeting PK instead of (packageName, day) unique key**

- **Found during:** Task 03-02-01 (verification run of `upsertDay overwrites on conflict` test)
- **Issue:** The plan specified `insertOnConflictUpdate()` verbatim from the RESEARCH skeleton. At test time, Drift's implementation targets the primary key (`id`) for conflict detection, not the `(packageName, day)` unique key. The second `upsertDay` call threw `SqliteException(2067): UNIQUE constraint failed: daily_usage_summary.package_name, daily_usage_summary.day` instead of overwriting.
- **Fix:** Replaced `into(dailyUsageSummary).insertOnConflictUpdate(companion)` with `into(dailyUsageSummary).insert(companion, onConflict: DoUpdate((_) => companion, target: [dailyUsageSummary.packageName, dailyUsageSummary.day]))`. This targets the secondary unique key directly per the Drift docs warning (InsertStatement.dart line 188-191).
- **Files modified:** `lib/data/database/daos/daily_usage_summary_dao.dart`
- **Verification:** `upsertDay overwrites on (packageName, day) conflict (D-14)` test passes; UNIQUE row count = 1 confirmed.
- **Committed in:** `9cf9c72` (Task 03-02-01 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Fix is load-bearing for correctness (D-14 idempotent upsert). The plan's RESEARCH skeleton used `insertOnConflictUpdate` which is the correct *semantic* intent but incorrect *API* for secondary unique keys in Drift 2.33. No scope creep — the fix stays within the 3-method surface.

**Note on Wave 0 stubs:** Plan 03-01 (Wave 0 stubs) was not yet committed when this plan executed in the parallel worktree. The test file `test/data/database/daos/daily_usage_summary_dao_test.dart` was created fresh with 4 real assertions (not "flip skip to passing" as described). The end state is equivalent — 4 passing tests exist.

## Issues Encountered

- Drift 2.33's `insertOnConflictUpdate` defaults to the PK as conflict target. The RESEARCH.md skeleton used this API. Detected at test-time (Rule 1). Fixed inline. Documented in Decisions.
- An accidental `git commit` fired in the main repo directory (`/Users/jintanakhomwong/projects/not-to-do-list`) on `main` branch instead of the worktree branch. Reverted immediately with `git reset --hard` before any push. All subsequent commits were verified on `worktree-agent-ab8219f8f0c717a25`.

## Known Stubs

None — no placeholder text, hardcoded empty values, or TODO markers in the files created/modified by this plan.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. DAO is on-device SQLite only; all queries are Drift typed companions/select builders (no string-interpolated SQL).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `DailyUsageSummaryDao` and its accessor are available for `usageRepositoryProvider` (Plan 03-04) and `dashboardRowsProvider` (Plan 03-05)
- `AppDatabase.dailyUsageSummaryDao` accessor is generated and stable
- `schemaVersion` stays at 2 — Plan 03-03 (Kotlin Pigeon impl) and beyond do not need a schema bump

---
*Phase: 03-screen-time-dashboard*
*Completed: 2026-05-07*
