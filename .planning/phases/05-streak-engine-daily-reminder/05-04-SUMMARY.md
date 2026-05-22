---
phase: 05-streak-engine-daily-reminder
plan: "04"
subsystem: platform-permissions
tags: [pigeon, kotlin, permission, notification, riverpod, boot-monotonic, clock-tamper]
dependency_graph:
  requires:
    - phase: 05-03
      provides: StreakRolloverService (uses bootMonotonicNanos mock — now replaced by real impl)
  provides:
    - PermissionStatusApi extended with 5 new @async methods (Dart + Kotlin)
    - PermissionStatusApiImpl.kt implementing isPostNotificationsGranted, postNotificationsRationaleState, requestPostNotifications, bootMonotonicNanos, openAppNotificationSettings
    - notificationApiProvider (Provider<NotificationApi>) for Riverpod DI
    - postNotificationsGrantedProvider (AsyncNotifierProvider<bool>) for UI gating
    - PermissionStatusApiImpl.weakRef companion for Plan 05-05 Activity wiring
  affects: [05-05-NotificationApiImpl-wiring, 05-07-reminder-off-banner, 05-08-earned-prompt]
tech_stack:
  added: []
  patterns: [pigeon-codegen-extend, weak-ref-activity-registry, three-state-permission-rationale, pre-dialog-non-blocking-return]
key_files:
  created:
    - lib/domain/providers/notification_api_provider.dart
    - lib/features/onboarding/providers/post_notifications_provider.dart
  modified:
    - pigeons/permission_status_api.dart
    - lib/platform/permission_status_api.g.dart
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApi.g.kt
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt
key_decisions:
  - "PermissionStatusApiImpl.weakRef companion object (not MainActivity.weakRef) — Plan 05-05 sets it without this plan touching MainActivity.kt, preserving phase boundary"
  - "requestPostNotifications returns PRE-dialog granted state immediately (non-blocking); re-poll on AppLifecycleState.resumed is Plan 05-08's responsibility (T-05-16 accept disposition)"
  - "Three-state postNotificationsRationaleState computed from SharedPreferences flags (requested-at-least-once + rationale-visible) written inside requestPostNotifications — avoids needing a persistent Activity for shouldShowRequestPermissionRationale at query time"
  - "bootMonotonicNanos maps Pigeon int → Kotlin Long (SystemClock.elapsedRealtimeNanos) — Plan 05-03 bootNanosProvider stub now wired to a real implementable surface"
requirements_completed: [STRK-06, NOTF-06, NOTF-07, REL-05]
duration: "~15 minutes"
completed: "2026-05-22T20:25:00Z"
tasks_completed: 1
files_changed: 6
---

# Phase 5 Plan 04: Extend PermissionStatusApi (POST_NOTIFICATIONS three-state + boot-monotonic clock) + Riverpod providers Summary

Pigeon `PermissionStatusApi` extended from 8 to 13 @async methods; Kotlin impl ships `isPostNotificationsGranted` (TIRAMISU-aware ContextCompat check), `postNotificationsRationaleState` (three-state grantable/rationale/permanently_denied via SharedPreferences tracking), `requestPostNotifications` (PRE-dialog non-blocking return documented with T-05-16 cross-ref), `bootMonotonicNanos` (SystemClock.elapsedRealtimeNanos), and `openAppNotificationSettings` (launchSettingsOrFallback T-2-02 pattern); two Riverpod providers delivered for Plans 05-07/08 consumption.

## Performance

- **Duration:** ~15 minutes
- **Started:** 2026-05-22T20:10:00Z
- **Completed:** 2026-05-22T20:25:00Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments

- Pigeon `PermissionStatusApi` extended with 5 new @async methods; `dart run pigeon` regenerated both Dart + Kotlin codegen cleanly
- `PermissionStatusApiImpl.kt` implements all 5 methods: TIRAMISU SDK guard in `isPostNotificationsGranted`; SharedPreferences two-flag three-state in `postNotificationsRationaleState`; PRE-dialog non-blocking return + Activity weakRef launch in `requestPostNotifications`; `SystemClock.elapsedRealtimeNanos()` in `bootMonotonicNanos`; `launchSettingsOrFallback` T-2-02 pattern in `openAppNotificationSettings`
- T-05-16 (requestPostNotifications semantic gap) documented in both Pigeon source doc-comment and Kotlin KDoc — Plans 05-07/08 can safely consume with the re-poll contract understood
- `notificationApiProvider` and `postNotificationsGrantedProvider` delivered; downstream plans can DI without MainActivity coupling

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend Pigeon PermissionStatusApi + Kotlin impl + Riverpod providers; regenerate codegen** - `9901383` (feat)

**Plan metadata:** (committed with SUMMARY.md below)

## Files Created/Modified

- `pigeons/permission_status_api.dart` — 5 new @async methods appended (8→13); T-05-16 cross-ref doc-comment on requestPostNotifications
- `lib/platform/permission_status_api.g.dart` — Regenerated Dart bindings (11 new method references)
- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApi.g.kt` — Regenerated Kotlin abstract interface (16 new method references)
- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt` — 5 new override methods + companion object (PREFS keys + weakRef registry)
- `lib/domain/providers/notification_api_provider.dart` — New: `Provider<NotificationApi> notificationApiProvider`
- `lib/features/onboarding/providers/post_notifications_provider.dart` — New: `AsyncNotifierProvider<PostNotificationsGrantedNotifier, bool> postNotificationsGrantedProvider`

## Decisions Made

- **PermissionStatusApiImpl.weakRef companion object (not MainActivity.weakRef):** Keeps the Activity registry inside the platform package. Plan 05-05 sets `PermissionStatusApiImpl.weakRef = WeakReference(this)` in `configureFlutterEngine` — no need for a cross-package import or touching MainActivity in this plan.
- **PRE-dialog return semantic (T-05-16 accepted):** The non-blocking return is documented in both Pigeon source and Kotlin KDoc with an explicit caller contract. Plan 05-08 owns the WidgetsBindingObserver re-poll on `AppLifecycleState.resumed`.
- **Three-state via SharedPreferences flags:** `postNotificationsRationaleState` reads `post_notifications_requested_at_least_once` + `post_notifications_rationale_visible` (both written by `requestPostNotifications` before launching the dialog) instead of calling `shouldShowRequestPermissionRationale` at query time — avoids needing a live Activity reference in the query path.

## Deviations from Plan

None — plan executed exactly as written. The `PermissionStatusApiImpl.weakRef` placement (companion object on impl class vs `MainActivity.weakRef`) is a minor elaboration of the plan's "use a static `MainActivity.weakRef`" guidance, implemented in the platform package to avoid a cross-package dependency that Plan 05-05 would have to unwind. Plan 05-05 sets this ref in `configureFlutterEngine` exactly as specified.

## Known Stubs

**`PermissionStatusApiImpl.weakRef` is null until Plan 05-05 wires it:** `requestPostNotifications` will not launch the system dialog (activity?.requestPermissions call is no-op with null ref) but will still write the SharedPreferences flags and return the current granted state. This does NOT prevent the plan's goal — the Pigeon contract is wired and the Riverpod providers are fully functional. Plan 05-05 resolves this by setting `PermissionStatusApiImpl.weakRef = WeakReference(this)` in `configureFlutterEngine`.

## Threat Flags

No new network endpoints, auth paths, or file access patterns beyond the declared threat model. All five methods operate within the existing Kotlin ↔ Android system services boundary. T-05-16 is accepted with documented mitigation (Plan 05-08 WidgetsBindingObserver re-poll). T-05-14/15 mitigated by launchSettingsOrFallback pattern reuse.

## Self-Check: PASSED

- `pigeons/permission_status_api.dart` — FOUND
- `lib/platform/permission_status_api.g.dart` — FOUND
- `android/.../PermissionStatusApi.g.kt` — FOUND
- `android/.../PermissionStatusApiImpl.kt` — FOUND
- `lib/domain/providers/notification_api_provider.dart` — FOUND
- `lib/features/onboarding/providers/post_notifications_provider.dart` — FOUND
- Commit 9901383 — FOUND
- `grep -c '@async' pigeons/permission_status_api.dart` = 13 (was 8, +5)
- `flutter analyze lib/platform/ lib/domain/providers/notification_api_provider.dart lib/features/onboarding/providers/post_notifications_provider.dart` = 0 errors
- `./gradlew :app:compileDebugKotlin` = BUILD SUCCESSFUL
- `flutter test test/policy/play_invariants_test.dart` = 9/9 PASS
- `flutter test test/policy/phase_5_invariants_test.dart` = green (skips expected for Plans 05-05 items)
- `flutter test test/domain/streak/streak_rollover_service_test.dart` = 23/23 PASS
- `grep -c 'PRE-dialog' PermissionStatusApiImpl.kt` = 4
- `grep -c 'PRE-dialog' pigeons/permission_status_api.dart` = 1
- `grep -c 'T-05-16' pigeons/permission_status_api.dart` = 1
- PLAY-02 forbidden tokens in PermissionStatusApiImpl.kt = 0
