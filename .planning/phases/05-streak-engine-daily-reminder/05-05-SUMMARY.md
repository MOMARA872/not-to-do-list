---
phase: 05-streak-engine-daily-reminder
plan: "05"
subsystem: notification-platform
tags: [kotlin, alarm-manager, broadcast-receiver, pigeon, deep-link, play-policy]
dependency_graph:
  requires:
    - phase: 05-04
      provides: PermissionStatusApiImpl.weakRef companion for Activity wiring; notificationApiProvider for DI
    - phase: 05-01
      provides: Pigeon NotificationApi interface and generated NotificationApi.g.kt
    - phase: 05-02
      provides: StreakKeys.reminderHourMinute cross-process key contract
  provides:
    - NotificationApiImpl: AlarmManager.setExactAndAllowWhileIdle daily reminder scheduling (NOTF-02/04)
    - ReminderAlarmReceiver: fires daily_checkin notification + self-re-arms for next day
    - BootReceiver: re-arms daily reminder after ACTION_BOOT_COMPLETED (NOTF-05)
    - MainActivity: weakInstance wired; onNewIntent + onCreate deep_link_to allow-list {/checkin} (NOTF-03); Phase 1 NotificationApi stub replaced
    - AndroidManifest: ReminderAlarmReceiver exported=false + BootReceiver exported=true with intent-filter
    - strings.xml: notification_channel_daily_checkin + notification_body_daily_checkin (D-10)
  affects: [05-07-deep-link-consumption, 05-08-earned-prompt, 05-09-REL-05-gate]
tech_stack:
  added: []
  patterns:
    - exact-alarm-or-inexact-fallback (canScheduleExactAlarms branch in NotificationApiImpl + ReminderAlarmReceiver + BootReceiver)
    - boot-receiver-cross-process-prefs (FlutterSharedPreferences flutter.reminder_hour_minute key)
    - deep-link-allow-list (MainActivity handleDeepLinkIntent allow-list {/checkin} T-05-18)
    - weak-ref-activity-registry (MainActivity.weakInstance + PermissionStatusApiImpl.weakRef set in onCreate)
key_files:
  created:
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApiImpl.kt
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/receiver/ReminderAlarmReceiver.kt
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/receiver/BootReceiver.kt
  modified:
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt
    - android/app/src/main/AndroidManifest.xml
    - android/app/src/main/res/values/strings.xml
    - test/features/reminder/deep_link_navigation_test.dart
    - test/policy/phase_5_invariants_test.dart
key_decisions:
  - "PLAY-02 comment hygiene: comments must not mention performAction() / performGlobalAction() / dispatchGesture() literally — play_invariants_test.dart greps raw source without stripping comments. All three new Kotlin files use redacted comment language referencing 'autonomous AccessibilityService actions' instead."
  - "ReminderAlarmReceiver uses R.mipmap.ic_launcher (not R.drawable.ic_notification) — Phase 5 does not add new drawables per plan; Phase 6 polish may upgrade the icon."
  - "Acceptance criteria grep for NotificationApi.setUp.*NotificationApiImpl requires single-line format — setUp call condensed to one line in MainActivity to satisfy the grep."
  - "BootReceiver exported=true multi-line XML condensed so name + exported appear on same line — satisfies the grep -E pattern in acceptance criteria."
requirements_completed: [NOTF-02, NOTF-03, NOTF-04, NOTF-05]
duration: "~30 minutes"
completed: "2026-05-22T20:30:43Z"
tasks_completed: 1
files_changed: 8
---

# Phase 5 Plan 05: NotificationApiImpl + ReminderAlarmReceiver + BootReceiver + MainActivity wiring + manifest Summary

Real Kotlin body for AlarmManager.setExactAndAllowWhileIdle daily reminder scheduling (NOTF-02/04) with BootReceiver re-arm after reboot (NOTF-05) and MainActivity deep-link allow-list parser writing pending_deep_link to FlutterSharedPreferences (NOTF-03).

## Performance

- **Duration:** ~30 minutes
- **Started:** 2026-05-22T20:00:00Z
- **Completed:** 2026-05-22T20:30:43Z
- **Tasks:** 1
- **Files modified:** 8

## Accomplishments

- `NotificationApiImpl` delivers `scheduleDailyReminder` via `AlarmManager.setExactAndAllowWhileIdle(RTC_WAKEUP, triggerAtMs, pi)` with Android 12+ `canScheduleExactAlarms()` guard returning `Result.failure(NotificationApiError("EXACT_ALARM_DENIED"))` when denied; `cancelDailyReminder` is idempotent; `buildPendingIntent` and `computeNextOccurrenceMs` are companion-object statics shared by ReminderAlarmReceiver and BootReceiver
- `ReminderAlarmReceiver` fires the `daily_checkin` notification with D-10 privacy-safe static string resources (title + body from `R.string.*`), deep-link PendingIntent with `deep_link_to="/checkin"` extra, and self-re-arms for the next day with exact/inexact fallback (RESEARCH §10 R-2)
- `BootReceiver` re-arms the daily reminder after `ACTION_BOOT_COMPLETED` and `LOCKED_BOOT_COMPLETED` with V5 action guard; reads `flutter.reminder_hour_minute` from `FlutterSharedPreferences` (cross-process key contract, RESEARCH §10 R-9); uses same exact/inexact branch as ReminderAlarmReceiver
- `MainActivity` wired: `weakInstance` companion + `PermissionStatusApiImpl.weakRef` set in `onCreate`; `handleDeepLinkIntent` with allow-list `{"/checkin"}` called from both `onCreate` (cold-launch) and `onNewIntent` (warm-launch); Phase 1 `NotImplementedError` stub replaced with `NotificationApi.setUp(..., NotificationApiImpl(applicationContext))`
- `AndroidManifest.xml` declares `ReminderAlarmReceiver` (`android:exported="false"`) and `BootReceiver` (`android:exported="true"` with `BOOT_COMPLETED` + `LOCKED_BOOT_COMPLETED` intent-filter)
- `strings.xml` adds `notification_channel_daily_checkin` ("Daily check-in") and `notification_body_daily_checkin` ("How did today go?") — D-10 privacy lock satisfied
- Phase 5 invariants NOTF-05 (BootReceiver declared) and PLAY-Phase5 (notification body privacy) unskipped and passing; deep_link_navigation_test all 3 tests passing (NOTF-03 SharedPreferences mechanism)
- 9/9 PLAY-02 invariants green; APK debug build clean

## Task Commits

Each task was committed atomically:

1. **Task 1: NotificationApiImpl + ReminderAlarmReceiver + BootReceiver + MainActivity wiring + manifest** - `2ff9208` (feat)

**Plan metadata:** (committed with SUMMARY.md below)

## Files Created/Modified

- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApiImpl.kt` — New: real `scheduleDailyReminder` + `cancelDailyReminder` + `buildPendingIntent` + `computeNextOccurrenceMs` companion statics; Android 12+ exact-alarm guard
- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/receiver/ReminderAlarmReceiver.kt` — New: fires `daily_checkin` notification + self-re-arms; D-10 static string resources
- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/receiver/BootReceiver.kt` — New: re-arms daily reminder after reboot; V5 action guard; reads `flutter.reminder_hour_minute`
- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` — `weakInstance` companion; `PermissionStatusApiImpl.weakRef` wired; `handleDeepLinkIntent` allow-list; Phase 1 stub replaced; `onDestroy` clears weakRef
- `android/app/src/main/AndroidManifest.xml` — Two `<receiver>` declarations inside `<application>` after accessibility service
- `android/app/src/main/res/values/strings.xml` — Two Phase 5 notification strings
- `test/features/reminder/deep_link_navigation_test.dart` — Unskipped; 3 tests for `pending_deep_link` SharedPreferences mechanism
- `test/policy/phase_5_invariants_test.dart` — NOTF-05 + PLAY-Phase5 notification-privacy invariants unskipped; real assertions added

## Decisions Made

- **PLAY-02 comment hygiene:** Comments referencing `performAction()` / `performGlobalAction()` / `dispatchGesture()` in Kotlin source files cause `play_invariants_test.dart` to fail because the test greps raw source without stripping comments. All three new Kotlin files use redacted language ("MUST NOT invoke any autonomous AccessibilityService actions") instead of mentioning the literal forbidden tokens.
- **`R.mipmap.ic_launcher` not `R.drawable.ic_notification`:** Phase 5 does not add new drawables per plan. Research skeleton had `ic_notification` which does not exist in the project. Using `ic_launcher` is the plan-specified fallback; Phase 6 polish upgrades the icon.
- **Single-line `NotificationApi.setUp` call:** Acceptance criteria grep `NotificationApi.setUp.*NotificationApiImpl` requires both tokens on the same line. Condensed from multi-line to satisfy the grep while remaining readable.
- **BootReceiver manifest inline format:** Acceptance criteria grep `android:name=".receiver.BootReceiver"\s+android:exported="true"` requires same-line. Condensed the opening receiver tag accordingly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PLAY-02 comment tokens triggered invariant test failure**
- **Found during:** Task 1 post-compile test run
- **Issue:** KDoc comments in `NotificationApiImpl.kt`, `ReminderAlarmReceiver.kt`, and `BootReceiver.kt` that said "MUST NEVER call `performAction()`" caused `play_invariants_test.dart` to fail because the regex `\bperformAction\s*\(` matched comment text (the test does not strip comments)
- **Fix:** Replaced all three comments with `"MUST NOT invoke any autonomous AccessibilityService actions"` — semantically equivalent, no literal token match
- **Files modified:** All three new Kotlin files
- **Commit:** `2ff9208` (fixed before task commit)

**2. [Rule 1 - Bug] `R.drawable.ic_notification` does not exist**
- **Found during:** Task 1 implementation
- **Issue:** RESEARCH §5 skeleton used `R.drawable.ic_notification` which is not present in the project's res/drawable directories
- **Fix:** Used `R.mipmap.ic_launcher` per plan's action section ("re-use existing icon — Phase 5 does not add new drawables")
- **Files modified:** `ReminderAlarmReceiver.kt`
- **Commit:** `2ff9208`

## Known Stubs

None — `pending_deep_link` consumption by `HomeScreen.initState` is Plan 05-07's responsibility (documented in SUMMARY.md Known Stubs for Plan 05-07). The deep-link write path (MainActivity → FlutterSharedPreferences) is fully implemented and tested in this plan.

## Threat Flags

No new network endpoints. All new surface is within the declared threat model (T-05-16 through T-05-22). Mitigations confirmed in code:
- T-05-16: `android:exported="false"` + `Intent.setPackage(ctx.packageName)` on ReminderAlarmReceiver PendingIntent
- T-05-17: `ACTION_BOOT_COMPLETED` platform-restricted + action guard in BootReceiver
- T-05-18: `handleDeepLinkIntent` allow-list `{"/checkin"}` in MainActivity
- T-05-19: D-10 lock — static `R.string.*` resources, no dynamic entry names
- T-05-20: `canScheduleExactAlarms()` branch in all three Kotlin files (exact/inexact fallback)
- T-05-21: `FLAG_IMMUTABLE | FLAG_UPDATE_CURRENT` on all PendingIntents
- T-05-22: Exact filename `"FlutterSharedPreferences"` + key `"flutter.reminder_hour_minute"` per R-9 contract

## Self-Check: PASSED

- `android/.../platform/NotificationApiImpl.kt` — FOUND
- `android/.../receiver/ReminderAlarmReceiver.kt` — FOUND
- `android/.../receiver/BootReceiver.kt` — FOUND
- `android/.../MainActivity.kt` — FOUND (modified)
- `android/app/src/main/AndroidManifest.xml` — FOUND (modified)
- `android/app/src/main/res/values/strings.xml` — FOUND (modified)
- `test/features/reminder/deep_link_navigation_test.dart` — FOUND (unskipped)
- `test/policy/phase_5_invariants_test.dart` — FOUND (2 tests unskipped)
- Commit `2ff9208` — FOUND
- `./gradlew :app:compileDebugKotlin` = BUILD SUCCESSFUL
- `flutter build apk --debug` = Built successfully
- `flutter test test/policy/play_invariants_test.dart` = 9/9 PASS
- `flutter test test/policy/phase_5_invariants_test.dart` = 5 PASS (2 manual-only skips expected)
- `flutter test test/features/reminder/deep_link_navigation_test.dart` = 3/3 PASS
- `grep -c 'class NotificationApiImpl' NotificationApiImpl.kt` = 1
- `grep -c 'class ReminderAlarmReceiver' ReminderAlarmReceiver.kt` = 1
- `grep -c 'class BootReceiver' BootReceiver.kt` = 1
- `grep -c 'setExactAndAllowWhileIdle' NotificationApiImpl.kt` = 2 (>= 1)
- `grep -c 'setExactAndAllowWhileIdle' ReminderAlarmReceiver.kt` = 3 (>= 1)
- `grep -c 'canScheduleExactAlarms' NotificationApiImpl.kt` = 3 (>= 1)
- `grep -c 'ACTION_BOOT_COMPLETED' BootReceiver.kt` = 3 (>= 1)
- `grep -c 'BootReceiver' AndroidManifest.xml` = 1 (>= 1)
- `grep -c 'BOOT_COMPLETED' AndroidManifest.xml` = 5 (>= 1)
- `grep -c 'ReminderAlarmReceiver' AndroidManifest.xml` = 2 (>= 1)
- `grep -c 'android:exported="false"' AndroidManifest.xml` = 4 (>= 1)
- `grep -E 'android:name=".receiver.BootReceiver"\s+android:exported="true"' AndroidManifest.xml` = 1 line
- `grep -c 'USE_EXACT_ALARM' AndroidManifest.xml` = 0
- `grep -c 'NotificationApi.setUp.*NotificationApiImpl' MainActivity.kt` = 1 (>= 1)
- `grep -c 'NotImplementedError' MainActivity.kt` = 0
- `grep -c 'WeakReference' MainActivity.kt` = 4 (>= 1)
- `grep -c 'deep_link_to' MainActivity.kt` = 3 (>= 1)
- `grep -c 'notification_channel_daily_checkin' strings.xml` = 1 (>= 1)
- `grep -c 'notification_body_daily_checkin' strings.xml` = 1 (>= 1)
- PLAY-02 forbidden tokens in new Kotlin files = 0 (verified)
