---
phase: 03
plan: 04
subsystem: dashboard-data
tags: [repository, riverpod, drift, dashboard, wave-2]
dependency_graph:
  requires:
    - 03-02  # DailyUsageSummaryDao
    - 03-03  # UsageApi Pigeon channel
  provides:
    - UsageRepository with refreshIfStale + watchRange (DASH-04 seam)
    - DashboardRange enum + localMidnight + resolveRange helpers
    - DashRow, AvoidedTodaySummary, CumulativeTotalsSummary DTOs
    - 7 hand-written Riverpod providers (usageApi/Dao/Repo/dashboardRange/dashboardRows/avoidedToday/cumulativeTotals)
  affects:
    - 03-05  # Dashboard UI consumes dashboardRowsProvider
    - 03-06  # Home cards consume avoidedTodayProvider + cumulativeTotalsProvider
tech_stack:
  added: []
  patterns:
    - "Repository pattern mirroring BlockListRepository: DAO injection + refreshIfStale + watchRange"
    - "Hand-written Riverpod providers (StateProvider from legacy, StreamProviderFamily from misc)"
    - "Drift 2.33 reactive seam: db.tableUpdates(TableUpdateQuery.onAllTables([...])) replacing research-documented allTablesUpdates"
    - "async* generator pattern for StreamProvider combining Pigeon refresh + Drift stream"
key_files:
  created:
    - lib/domain/dashboard/dashboard_range.dart
    - lib/features/dashboard/models/dash_row.dart
    - lib/features/dashboard/models/avoided_today_summary.dart
    - lib/features/dashboard/models/cumulative_totals_summary.dart
    - lib/data/repositories/usage_repository.dart
    - lib/domain/providers/usage_api_provider.dart
    - lib/domain/providers/usage_dao_provider.dart
    - lib/domain/providers/usage_repo_provider.dart
    - lib/features/dashboard/providers/dashboard_range_provider.dart
    - lib/features/dashboard/providers/dashboard_rows_provider.dart
    - lib/features/dashboard/providers/avoided_today_provider.dart
    - lib/features/dashboard/providers/cumulative_totals_provider.dart
  modified:
    - test/domain/dashboard/dashboard_range_test.dart  # Wave 0 stubs -> 4 passing tests
    - test/data/repositories/usage_repository_test.dart  # Wave 0 stubs -> 6 passing tests
decisions:
  - "Drift 2.33 reactive API is tableUpdates(TableUpdateQuery.onAllTables([...])), not allTablesUpdates([...]) from RESEARCH.md — semantically identical; no behavioral change"
  - "StateProvider from flutter_riverpod/legacy.dart — Riverpod 3.x removed it from main export; legacy.dart is the correct import for session-only simple state"
  - "StreamProviderFamily from flutter_riverpod/misc.dart — needed for dashboardRowsProvider type annotation"
  - "import 'package:drift/drift.dart' in dashboard_rows_provider.dart — required to bring ComparableExpr extension into scope for isBetweenValues on DateTimeColumn"
  - "A6 simplification: avoidedTodayProvider uses daily-total threshold for all entries including scheduled; Phase 5 STRK-09 adds window-aware accounting"
metrics:
  duration: "~25 minutes"
  completed: "2026-05-07"
  tasks_completed: 3
  files_created: 12
  files_modified: 2
---

# Phase 03 Plan 04: Wave 2 — UsageRepository + DashboardRange + 7 Riverpod Providers Summary

Hand-written repository seam, domain helpers, 3 DTOs, and 7 Riverpod providers wiring the Pigeon channel + Drift cache to reactive streams for the dashboard UI (Wave 3).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 03-04-01 | DashboardRange enum + 3 DTO models + flip Wave 0 range test | 1469cec | dashboard_range.dart, dash_row.dart, avoided_today_summary.dart, cumulative_totals_summary.dart, dashboard_range_test.dart |
| 03-04-02 | UsageRepository + flip Wave 0 repo test | 0053cab | usage_repository.dart, usage_repository_test.dart |
| 03-04-03 | 7 hand-written Riverpod providers | 2cd2a9a | usage_api_provider.dart, usage_dao_provider.dart, usage_repo_provider.dart, dashboard_range_provider.dart, dashboard_rows_provider.dart, avoided_today_provider.dart, cumulative_totals_provider.dart |

## Verification

- `flutter test` exits 0: 138 passed, 20 skipped (Wave 0 stubs for later plans)
- `flutter test test/data/repositories/usage_repository_test.dart` — 6 passed
- `flutter test test/domain/dashboard/dashboard_range_test.dart` — 4 passed
- `flutter test test/policy/play_invariants_test.dart` — 8/8 green
- `dart analyze` — 0 errors, 0 warnings (2 pre-existing issues in unchanged files)
- `dashboardRowsProvider` is `StreamProvider.autoDispose.family<List<DashRow>, DashboardRange>` (verified by grep)
- `avoidedTodayProvider` docstring contains both `A6 simplification` and `Phase 5 STRK-09` literals
- schemaVersion still at 2; no Pigeon regeneration; no new deps in pubspec.yaml

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Drift 2.33 reactive API name mismatch**
- **Found during:** Task 03-04-03
- **Issue:** RESEARCH.md documented `db.allTablesUpdates([...])` but Drift 2.33's actual API is `db.tableUpdates(TableUpdateQuery.onAllTables([...]))`. The `allTablesUpdates` method does not exist on `AppDatabase`.
- **Fix:** Used `db.tableUpdates(TableUpdateQuery.onAllTables([...]))` in all three reactive providers. Added `import 'package:drift/drift.dart' show TableUpdateQuery;` to providers needing it.
- **Files modified:** dashboard_rows_provider.dart, avoided_today_provider.dart, cumulative_totals_provider.dart
- **Commit:** 2cd2a9a

**2. [Rule 1 - Bug] Riverpod 3.x StateProvider / StreamProviderFamily import paths**
- **Found during:** Task 03-04-03
- **Issue:** `StateProvider` was removed from `flutter_riverpod`'s main export in Riverpod 3.x; it lives in `flutter_riverpod/legacy.dart`. `StreamProviderFamily` lives in `flutter_riverpod/misc.dart`.
- **Fix:** `dashboard_range_provider.dart` imports `flutter_riverpod/legacy.dart show StateProvider`. `dashboard_rows_provider.dart` imports `flutter_riverpod/misc.dart show StreamProviderFamily`.
- **Files modified:** dashboard_range_provider.dart, dashboard_rows_provider.dart
- **Commit:** 2cd2a9a

**3. [Rule 1 - Bug] ComparableExpr extension not in scope**
- **Found during:** Task 03-04-03
- **Issue:** `isBetweenValues` on `GeneratedColumn<DateTime>` requires the `ComparableExpr` extension from `drift/drift.dart` to be directly imported. The `show TableUpdateQuery` import was insufficient.
- **Fix:** Changed `dashboard_rows_provider.dart` to `import 'package:drift/drift.dart';` (full import) instead of `show TableUpdateQuery`.
- **Files modified:** dashboard_rows_provider.dart
- **Commit:** 2cd2a9a

## Known Stubs

None — all provider implementations are complete. The providers will emit empty/zero data (e.g., `avoidedTodayProvider` emits `{total: 0, succeeded: 0, pending: 0, failed: 0}`) when tables are empty, which is the expected and correct Phase 3 state per D-11.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary violations. All 14 files are pure Dart. Cumulative-totals SQL is hardcoded literal (no string interpolation). All providers use `.autoDispose` to prevent resource leaks.

## Self-Check
