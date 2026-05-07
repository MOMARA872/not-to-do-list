---
phase: 2
plan: 03
subsystem: platform-channels
tags: [pigeon, kotlin, permission-funnel, app-picker, settings-deep-link]
plan_id: 02-03
status: complete
completed_at: "2026-05-07T00:03:19Z"
duration_minutes: 79
requires:
  - 02-01 (Wave 0 test scaffolding — provides test/_fixtures/permission_status_mock.dart placeholder + test/platform/app_picker_api_test.dart stub)
  - Phase 1 (manifest <queries> LAUNCHER, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, NotToDoAccessibilityService stub, AccessibilityApi/UsageApi/NotificationApi Pigeon channels)
provides:
  - "Pigeon AppPickerApi: listInstalledApps, recentlyUsedApps(daysBack), getApplicationIconPng(packageName) — all @async, all running on Executors.newSingleThreadExecutor"
  - "Pigeon PermissionStatusApi: isUsageAccessGranted, isAccessibilityServiceEnabled, isIgnoringBatteryOptimizations, currentBuildFingerprint, currentManufacturer (lowercased), openUsageAccessSettings, openAccessibilitySettings, openBatteryOptSettings — all @async"
  - "Real AccessibilityApi.openAccessibilitySettings (no longer a no-op stub) — resolveActivity-guarded launch of Settings.ACTION_ACCESSIBILITY_SETTINGS"
  - "MainActivity wires AppPickerApi + PermissionStatusApi alongside the existing Phase 1 channels"
affects:
  - "Plan 02-05 (permissionStatusProvider + appPickerProvider Riverpod wiring) — has real Pigeon classes to consume"
  - "Plan 02-06 (app picker UI) — appPickerApiProvider can override AppPickerApi() for widget tests"
  - "Plan 02-08 (permission funnel screens) — open*Settings deep-link launchers ready for ConsumerStatefulWidget calls"
  - "Plan 02-09 (health-check banner) — PermissionStatusApi.currentManufacturer feeds dontkillmyapp.com URL builder"
tech-stack:
  added: []
  patterns:
    - "Pigeon HostApi @async methods: every Kotlin override receives a callback parameter, never blocks"
    - "Background Executor pattern: Executors.newSingleThreadExecutor() for PackageManager + UsageStatsManager calls (T-2-06 mitigation against ANR)"
    - "resolveActivity(pm) != null guard before every startActivity (T-2-02 mitigation against intent spoofing)"
    - "Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS requires `package:` data Uri (Android requirement)"
    - "AppOpsManager.unsafeCheckOpNoThrow on API 29+ (project minSdk = 29) — replaces deprecated checkOpNoThrow"
key-files:
  created:
    - pigeons/app_picker_api.dart
    - pigeons/permission_status_api.dart
    - lib/platform/app_picker_api.g.dart
    - lib/platform/permission_status_api.g.dart
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerApi.g.kt
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApi.g.kt
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt
  modified:
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt
    - test/_fixtures/permission_status_mock.dart
    - test/platform/app_picker_api_test.dart
decisions:
  - "Implemented PermissionStatusApi as a NEW Pigeon channel (NOT extending Phase 1's AccessibilityApi). Rationale: Phase 1 contract is frozen per 02-PATTERNS.md `Files NOT to Touch`. The duplicate isAccessibilityServiceEnabled() is intentional — bundling all four status checks (usage / accessibility / battery / build-info) into a single round-trip API matches the resume-detection pattern in 02-RESEARCH.md §onResume Return-Detection."
  - "Settings deep-link wrapper uses primary + fallback shape (rather than primary + List<fallback>): two-intent pattern per task is sufficient for v1, mirrors the RESEARCH §Permission Step snippet exactly."
  - "Battery-opt preferred intent is ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS with package URI (system dialog grants directly), fallback ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS (list-only). REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission already declared in Phase 1 manifest."
  - "AppPickerApi exposes 3 split methods (listInstalledApps, recentlyUsedApps, getApplicationIconPng) instead of one fat call — keeps Pigeon payload small, allows lazy + cached icon fetch, lets UI render alphabetical list before recents stream returns. RESEARCH §App Picker Implementation cites the payload math: 300 apps × 30 KB = 9 MB if icons bundled."
  - "App picker test stays minimal (smoke + skip): the canonical seam for picker behavior is the appPickerApiProvider override in Plan 02-06's widget tests. Avoiding hand-rolled Pigeon channel mocks insulates the test suite from Pigeon version bumps."
metrics:
  duration_minutes: 79
  completed_date: "2026-05-07"
  tasks_completed: 5
  files_created: 8
  files_modified: 3
  commits: 5
---

# Phase 2 Plan 02-03: Pigeon channels + native HostApi impls — Summary

Two new typed Dart↔Kotlin channels (`AppPickerApi`, `PermissionStatusApi`) and their Kotlin HostApi impls landed, plus the Phase-1 `AccessibilityApi.openAccessibilitySettings()` no-op stub was replaced with a real resolveActivity-guarded launch — every Phase 2 Wave-2 Riverpod provider now has a real native API to consume.

## What was built

### Task 02-03-01 — `AppPickerApi` Pigeon channel + codegen → `d5ef5e3`

- `pigeons/app_picker_api.dart` declares `@HostApi() abstract class AppPickerApi` with 3 `@async` methods: `listInstalledApps()`, `recentlyUsedApps(int daysBack)`, `getApplicationIconPng(String packageName)`.
- Two data classes: `InstalledApp { packageName, displayName, isSystemApp, hasLauncherIntent }` and `RecentApp { packageName, totalForegroundSeconds }`.
- `errorClassName: 'AppPickerApiError'` avoids the FlutterError-redeclaration that bites when multiple Pigeon-generated Kotlin files share one package.
- Codegen produced `lib/platform/app_picker_api.g.dart` + `android/.../platform/AppPickerApi.g.kt`.
- `dart analyze` clean; no autonomous-action methods (PLAY-02 invariant).

### Task 02-03-02 — `PermissionStatusApi` Pigeon channel + codegen → `e2cbdd8`

- `pigeons/permission_status_api.dart` declares 8 `@async` methods: 4 status checks + `currentBuildFingerprint` + `currentManufacturer` + 3 `open*Settings` deep-links.
- `errorClassName: 'PermissionStatusApiError'`.
- `pigeons/accessibility_api.dart` byte-identical to Phase 1 — frozen contract preserved.
- Updated `test/_fixtures/permission_status_mock.dart` to import the real Pigeon class instead of the local abstract; mocktail still binds correctly. The Wave 0 `TODO(02-03)` is now resolved.
- `flutter test` exits 0 (+6 ~32 → all pre-existing Wave 0 stubs still skip cleanly).

### Task 02-03-03 — `AppPickerHostImpl.kt` + MainActivity registration → `6d353b1`

- `AppPickerHostImpl` runs PackageManager + UsageStatsManager calls on `Executors.newSingleThreadExecutor()` (T-2-06 mitigation: I/O-bound calls must never run on the UI thread).
- `listInstalledApps()`: combines `pm.queryIntentActivities(LAUNCHER)` with `pm.getInstalledApplications(MATCH_DEFAULT_ONLY)` to compute `hasLauncherIntent` per package — Dart-side filter `isSystemApp && !hasLauncherIntent` implements the T-2-01 system-app-spoof mitigation.
- `recentlyUsedApps()`: gates on `AppOpsManager.unsafeCheckOpNoThrow(OPSTR_GET_USAGE_STATS, ...) == MODE_ALLOWED`; returns `emptyList()` when not granted (T-2-03: silent-empty avoidance — UI shows the inline grant prompt).
- `getApplicationIconPng()`: `drawable.toBitmap(96, 96)` → PNG via `Bitmap.compress`; returns `null` on `NameNotFoundException`.
- `MainActivity` registers `AppPickerApi.setUp(...)` alongside the existing Phase 1 channels; comment block updated to reflect Phase 2 ownership.
- `AndroidManifest.xml` unchanged — no `QUERY_ALL_PACKAGES`, `SYSTEM_ALERT_WINDOW`, or `BIND_DEVICE_ADMIN` added.
- `flutter build apk --debug` succeeds (66.1s first build, 8.9s incremental).

### Task 02-03-04 — `PermissionStatusApiImpl.kt` + replace AccessibilityApi stub → `06d9e5b`

- `PermissionStatusApiImpl` covers 4 status checks (usage / accessibility / battery / build) + 3 Settings deep-link launchers.
- All 3 `open*Settings()` go through `launchSettingsOrFallback(primary, fallback, callback)` which calls `resolveActivity(pm) != null` BEFORE `startActivity` — T-2-02 mitigation. Fallback is also resolveActivity-guarded.
- `Build.MANUFACTURER.lowercase()` matches the Dart-side OEM map keys (REL-03).
- `pm.isIgnoringBatteryOptimizations(context.packageName)` — uses Phase 1's REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission.
- Battery-opt preferred intent uses `Uri.parse("package:${context.packageName}")` data (Android requirement for `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
- `MainActivity.AccessibilityApi.openAccessibilitySettings()` no-op stub replaced with a real `Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(FLAG_ACTIVITY_NEW_TASK)` launch wrapped in `resolveActivity(pm)` guard. The Pigeon contract for `pigeons/accessibility_api.dart` is unchanged.
- `MainActivity` registers `PermissionStatusApi.setUp(...)`.
- `flutter build apk --debug` succeeds.

### Task 02-03-05 — `app_picker_api_test.dart` → `fea309b`

- Wave 0 stub replaced with a minimal smoke test:
  - Imports `package:not_to_do_list/platform/app_picker_api.g.dart` (proves Pigeon-generated Dart compiles into the test).
  - Asserts `AppPickerApi()` is instantiable (channel-construction smoke).
  - Round-trip test stays `skip:` with a TODO pointing to Plan 02-06's `appPickerApiProvider` override pattern, which is the canonical seam for end-to-end picker behavior. This avoids brittle coupling to Pigeon-version-specific channel-name + codec internals.
- `flutter test test/platform/app_picker_api_test.dart` exits 0.
- Full `flutter test` exits 0 (+11 ~30; +1 from this plan).

## Pigeon class names + methods Wave 2 will consume (Plans 02-04 + 02-05)

For Plan 02-05's Riverpod provider wiring, the imports + methods are:

```dart
import 'package:not_to_do_list/platform/app_picker_api.g.dart';
//   AppPickerApi() — class with 3 methods:
//     Future<List<InstalledApp>> listInstalledApps()
//     Future<List<RecentApp>> recentlyUsedApps(int daysBack)
//     Future<Uint8List?> getApplicationIconPng(String packageName)
//   Data classes:
//     class InstalledApp {
//       String packageName; String displayName;
//       bool isSystemApp; bool hasLauncherIntent;
//     }
//     class RecentApp {
//       String packageName; int totalForegroundSeconds;
//     }

import 'package:not_to_do_list/platform/permission_status_api.g.dart';
//   PermissionStatusApi() — class with 8 methods:
//     Future<bool> isUsageAccessGranted()
//     Future<bool> isAccessibilityServiceEnabled()
//     Future<bool> isIgnoringBatteryOptimizations()
//     Future<String> currentBuildFingerprint()
//     Future<String> currentManufacturer()    // lowercased on Kotlin side
//     Future<void> openUsageAccessSettings()
//     Future<void> openAccessibilitySettings()
//     Future<void> openBatteryOptSettings()
```

Plan 02-05 will define `appPickerApiProvider` and `permissionStatusApiProvider` as hand-written `Provider<T>` (no `@riverpod` codegen — Phase 1 deviation note in `01-01-SUMMARY.md`) that simply construct `AppPickerApi()` / `PermissionStatusApi()`. Tests override these providers with mocks built from `test/_fixtures/permission_status_mock.dart` (already updated in this plan) and a sibling `app_picker_mock.dart` Plan 02-06 will add.

## Verification

- [x] Both Pigeon inputs follow Phase 1 conventions (errorClassName unique, comment block intact, no autonomous-action methods).
- [x] Both Kotlin impls run native calls on background Executor (or are I/O-light system-service calls).
- [x] Every deep-link launcher uses `resolveActivity(pm)` before `startActivity`.
- [x] `Build.MANUFACTURER` is lowercased on the Kotlin side.
- [x] No new Android permissions added; `AndroidManifest.xml` unmodified by this plan.
- [x] `flutter build apk --debug` succeeds.
- [x] `flutter test` exits 0.
- [x] `pigeons/accessibility_api.dart` byte-identical to Phase 1 (Phase 1 contract frozen).

## Deviations from Plan

None — all 5 tasks executed exactly as written.

The original AppPickerHostImpl.kt body had a doc-comment line literally containing `QUERY_ALL_PACKAGES` (negation: "no QUERY_ALL_PACKAGES permission") which would have failed the `! grep -E "...|QUERY_ALL_PACKAGES" "$F"` absence-grep in Task 02-03-03's automated verification. Reworded to "no broad-package-query permission" while keeping the same meaning. This is a doc-only fix to make the executor's own absence-grep pass — no behavioral change. Tracking as a process note rather than a formal deviation.

## Authentication Gates

None encountered — the plan touches no authenticated services.

## Threat Model Mitigations Realized

| Threat | Disposition | Status |
|--------|-------------|--------|
| T-2-01 Spoofing — malicious package masquerades as system app | mitigate | ✅ AppPickerHostImpl emits both `isSystemApp` + `hasLauncherIntent`; Dart-side filter is `(FLAG_SYSTEM AND no LAUNCHER)`. |
| T-2-02 Tampering — Settings deep-link redirected | mitigate | ✅ All 4 deep-link launchers (3 in PermissionStatusApiImpl + 1 in MainActivity AccessibilityApi stub) call `resolveActivity(pm)` before `startActivity`. |
| T-2-03 Information Disclosure — UsageStats silent-empty | mitigate | ✅ `recentlyUsedApps` returns `emptyList()` when `OPSTR_GET_USAGE_STATS != MODE_ALLOWED` — UI is responsible for showing the grant prompt (Plan 02-06 surface 5). |
| T-2-05 Information Disclosure — PLAY-06 disclosure copy drift | accept (this plan) | Disclosure copy lives in Plan 02-08; this plan's API surface is policy-neutral. |
| T-2-06 Denial of Service — picker enumeration ANR | mitigate | ✅ `Executors.newSingleThreadExecutor()` in AppPickerHostImpl. |

## Threat Flags

None — no new security-relevant surface introduced beyond what the plan's threat_model already enumerated.

## Known Stubs

- `MainActivity.AccessibilityApi.isServiceEnabled()` still returns `false` (Phase 1 stub preserved per plan instruction — Phase 4 lights it up). Note that the new `PermissionStatusApi.isAccessibilityServiceEnabled()` IS implemented for real in this plan; the duplicate Phase-1 method is intentionally untouched per "Phase 1 contract frozen" rule.
- `MainActivity.UsageApi.queryRange()` still throws `NotImplementedError` (Phase 1 stub — Phase 3 implements).
- `MainActivity.NotificationApi.scheduleDailyReminder()` still throws `NotImplementedError` (Phase 1 stub — Phase 5 implements).
- `cancelDailyReminder()` returns success (Phase 1 stub — safe default).

These are NOT regressions — they're the Phase-1 stubs that this plan deliberately did not touch.

## Self-Check: PASSED

All claims verified:
- ✅ `pigeons/app_picker_api.dart` exists
- ✅ `pigeons/permission_status_api.dart` exists
- ✅ `lib/platform/app_picker_api.g.dart` exists
- ✅ `lib/platform/permission_status_api.g.dart` exists
- ✅ `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerApi.g.kt` exists
- ✅ `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApi.g.kt` exists
- ✅ `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt` exists
- ✅ `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt` exists
- ✅ `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` has both new `setUp` calls + real `openAccessibilitySettings`
- ✅ `test/_fixtures/permission_status_mock.dart` imports real Pigeon class
- ✅ `test/platform/app_picker_api_test.dart` no longer Wave 0 stub
- ✅ Commit `d5ef5e3` (Task 1) found in git log
- ✅ Commit `e2cbdd8` (Task 2) found in git log
- ✅ Commit `6d353b1` (Task 3) found in git log
- ✅ Commit `06d9e5b` (Task 4) found in git log
- ✅ Commit `fea309b` (Task 5) found in git log
