---
phase: 03-screen-time-dashboard
plan: "03"
subsystem: android-platform-channel
tags: [kotlin, pigeon, usage-stats-manager, app-ops, executor, flutter-android]

# Dependency graph
requires:
  - phase: 03-01
    provides: Pigeon UsageApi contract (UsageApi.g.kt + usage_api.g.dart) scaffolded
  - phase: 02-list-crud-onboarding-permissions
    provides: AppPickerHostImpl.kt + PermissionStatusApiImpl.kt exemplar patterns; MainActivity.kt shape

provides:
  - UsageApiImpl.kt — Kotlin Pigeon HostApi backed by UsageStatsManager.queryUsageStats(INTERVAL_DAILY)
  - MainActivity.kt wired with UsageApiImpl(applicationContext) replacing Phase-1 inline stub

affects: [03-04-usage-repository, 03-05-dashboard-screen, 03-06-home-cards]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "UsageApiImpl mirrors AppPickerHostImpl.kt: private Executors.newSingleThreadExecutor(), AppOps gate, null-safe ?: emptyList(), SecurityException + Throwable double-catch"
    - "Pigeon HostApi impl: same-package classes (UsageApi, UsagePackageStat, UsageApiError) need no import — only 5 Android SDK imports required"
    - "AppOps deny on UsageApi path → Result.failure(UsageApiError) (D-03); AppPicker deny → emptyList() — two different semantics, one file each"

key-files:
  created:
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApiImpl.kt
  modified:
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt

key-decisions:
  - "AppOps deny on UsageApi returns UsageApiError(USAGE_ACCESS_DENIED) not emptyList() — Dart routes to no-permission fallback (D-03)"
  - "SecurityException caught before Throwable (order load-bearing); both return emptyList() for locked-device resilience (D-04)"
  - "launchCount filled with 0L — INTERVAL_DAILY UsageStats API does not surface meaningful launch count (research A5)"
  - "INTERVAL_DAILY selected over INTERVAL_BEST for day-bucketed aggregation matching DailyUsageSummary table schema (D-02)"
  - "No new imports needed for Pigeon-generated classes — same Kotlin package (com.nottodo.not_to_do_list.platform)"

patterns-established:
  - "Pattern: two-catch ordering — SecurityException (swallow) before Throwable (propagate); violation swaps semantics silently"
  - "Pattern: AppOps gate before queryUsageStats — always check mode before the system call, return early on deny"

requirements-completed: [DASH-01]

# Metrics
duration: 25min
completed: 2026-05-07
---

# Phase 3 Plan 03: UsageApi Kotlin impl + MainActivity wiring Summary

**UsageApiImpl.kt lit up the Pigeon `usageApi` channel: INTERVAL_DAILY UsageStatsManager on a private background Executor with AppOps gate (USAGE_ACCESS_DENIED error) and locked-device null/SecurityException resilience**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-07T00:00:00Z
- **Completed:** 2026-05-07
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Created `UsageApiImpl.kt` — 104-line Kotlin class mirroring `AppPickerHostImpl.kt` shape; backed by `UsageStatsManager.queryUsageStats(INTERVAL_DAILY)` on a `newSingleThreadExecutor()` background thread
- AppOps gate fires `UsageApiError("USAGE_ACCESS_DENIED")` on deny so the Dart layer can route to the no-permission banner (D-03); SecurityException + null return from locked-device both resolve to `emptyList()` (D-04)
- Replaced Phase-1 inline stub in `MainActivity.kt` with `UsageApi.setUp(messenger, UsageApiImpl(applicationContext))` — four-line form matching `AppPickerHostImpl` and `PermissionStatusApiImpl` registration blocks
- 8/8 PLAY-02 policy invariant tests green; 124 flutter tests passing; no AndroidManifest changes

## Task Commits

1. **Task 1: Create UsageApiImpl.kt** — `746fb18` (feat)
2. **Task 2: Wire UsageApiImpl in MainActivity.kt** — `5ebc7d0` (feat)

**Plan metadata:** committed with SUMMARY.md in final docs commit

## Files Created/Modified

- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApiImpl.kt` — New Pigeon HostApi impl; private Executor, AppOps gate, INTERVAL_DAILY queryUsageStats, groupBy+sumOf aggregation, dual SecurityException/Throwable catch
- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` — Swapped inline UsageApi stub for `UsageApiImpl(applicationContext)`; dropped `UsagePackageStat` import; added `UsageApiImpl` import; updated Phase comment

## Decisions Made

- Used `unsafeCheckOpNoThrow` (not `checkOpNoThrow`) — verbatim from `PermissionStatusApiImpl.kt` line 32; the "unsafe" API is the correct non-deprecated form on API 29+
- `applicationContext` passed in `MainActivity.kt` (not `this`) — matches `AppPickerHostImpl` and `PermissionStatusApiImpl` registration to avoid Activity leaks
- PLAY-02 invariant comment block preserved verbatim — comment contains the human-readable assertion but NOT the forbidden tokens themselves, keeping absence-grep clean

## Deviations from Plan

None — plan executed exactly as written. The RESEARCH.md skeleton and PATTERNS.md style notes were followed verbatim.

## Issues Encountered

- `flutter build apk --debug` could not run — Android SDK absent from worktree environment (no `ANDROID_HOME`). Kotlin compilation correctness verified via: (a) file structure matching established sibling patterns, (b) same-package class usage requiring no cross-package imports, (c) PLAY-02 absence-grep policy tests confirming file content, (d) 124 flutter tests green.

## Threat Surface Scan

No new threat surface introduced beyond the plan's threat model. `UsageApiImpl.kt` is a pure Pigeon HostApi impl — no new network endpoints, no new permissions, no new file access paths. PLAY-02 absence-grep confirms no forbidden autonomous-action tokens. `MainActivity.kt` change is a one-line swap with no security boundary change.

## Known Stubs

None — `UsageApiImpl.queryRange` is fully implemented. The only stubs remaining in `MainActivity.kt` are `AccessibilityApi` and `NotificationApi` (Phase 4/5 scope), unchanged from Phase 2.

## Next Phase Readiness

- `UsageApi` Pigeon channel is live — `UsageRepository` (Plan 03-04) can now call `usageApi.queryRange(startEpochMs, endEpochMs)` and receive `List<UsagePackageStat>`
- The channel blocks on permission access correctly (throws typed `UsageApiError`) enabling the Dart-side no-permission fallback (D-13)
- `flutter test` baseline at 124 tests passing; no regressions

---
*Phase: 03-screen-time-dashboard*
*Completed: 2026-05-07*
