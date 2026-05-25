---
phase: 06-polish-play-store-submission
plan: "07"
subsystem: policy-tests
tags: [play-store, telemetry, testing, policy, version-bump]
dependency_graph:
  requires: [06-04, 06-05, 06-06]
  provides: [PLAY-09-telemetry-invariants, privacy-linkage-assertion, version-1.0.0+1]
  affects: [test/policy/, pubspec.yaml, android/app/build.gradle.kts]
tech_stack:
  added: []
  patterns:
    - PLAY-09 absence-grep (pubspec.lock + lib/ Dart + android/ Kotlin + APK classes*.dex)
    - Process.runSync unzip+strings APK sweep (multidex-safe classes*.dex glob)
key_files:
  created: []
  modified:
    - test/policy/play_invariants_test.dart
    - test/policy/apk_telemetry_strings_test.dart
    - test/policy/privacy_policy_url_present_test.dart
    - pubspec.yaml
    - android/app/build.gradle.kts
decisions:
  - "Append PLAY-09 tests inside existing group in play_invariants_test.dart (append-only per Phase 2/4/5 pattern)"
  - "APK sweep uses single-quoted classes*.dex glob so shell expands it — multidex-safe per RESEARCH Pitfall 5"
  - "privacy_policy_url_present_test.dart asserts in-app /settings/privacy route only; public GitHub Pages URL deferred to 06-08"
  - "version bump: 0.1.0+1 → 1.0.0+1 (first Play Console submission per D-15/D-16)"
  - "build.gradle.kts versionCode/versionName lines left unchanged — flutter.versionCode/versionName already flow from pubspec.yaml"
metrics:
  duration: "~12 minutes"
  completed: "2026-05-24"
---

# Phase 6 Plan 07: Pre-Submit Policy Gate Summary

Wave 4 pre-submit policy gate. Locked PLAY-09 zero-telemetry promise across 4 structural layers (pubspec.lock + Dart sources + Kotlin sources + APK classes*.dex), asserted Privacy Policy in-app linkage, and stamped first Play Console submission version 1.0.0+1.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend play_invariants_test.dart + activate apk/privacy tests | a46ff10 | test/policy/play_invariants_test.dart, test/policy/apk_telemetry_strings_test.dart, test/policy/privacy_policy_url_present_test.dart |
| 2 | Version bump pubspec.yaml + Play App Signing comment | e9cc723 | pubspec.yaml, android/app/build.gradle.kts |

## What Was Built

### Task 1: Test Activations

**`test/policy/play_invariants_test.dart`** (extended, append-only):
- Added `PLAY-09: pubspec.lock contains no telemetry deps` — reads pubspec.lock as lowercase string, asserts none of 5 tokens (firebase, crashlytics, analytics, fcm, remoteconfig) appear
- Added `PLAY-09: lib/ Dart sources contain no telemetry imports` — walks lib/**/*.dart (excluding .g.dart), comment-strips each file, asserts no token appears (case-insensitive)
- Added `PLAY-09: android/ Kotlin sources contain no telemetry imports` — walks android/**/*.kt, strips // and * comment lines, asserts no token appears (case-insensitive)
- All 10 existing PLAY-02..06 + Phase 5 receiver-scope invariants preserved (append-only)

**`test/policy/apk_telemetry_strings_test.dart`** (activated from RED stub):
- Replaced markTestSkipped with Process.runSync shell-out
- `unzip -p 'build/app/outputs/apk/release/app-release.apk' 'classes*.dex' | strings | grep -iE '(firebase|crashlytics|analytics|fcm|remoteconfig)' | head -5`
- Graceful early return when APK absent (CI build skip)
- Uses single-quoted `classes*.dex` glob for multidex safety (RESEARCH Pitfall 5)

**`test/policy/privacy_policy_url_present_test.dart`** (activated from RED stub):
- First test (`docs/PRIVACY.md exists and is non-empty`) was already REAL from 06-01 stub — kept as-is
- Activated second test: asserts `settings_screen.dart` source contains `/settings/privacy` literal (Privacy Policy tile route)
- Does NOT yet assert public GitHub Pages URL — that lands in 06-08

### Task 2: Version Bump + Annotation

**`pubspec.yaml`**:
- `version: 0.1.0+1` → `version: 1.0.0+1`
- Resolves to flutter.versionName = "1.0.0", flutter.versionCode = 1 via Flutter Gradle plugin
- `flutter pub get` succeeded; pubspec.lock refreshed (no dependency changes — project version metadata only)

**`android/app/build.gradle.kts`**:
- Added comment-only annotation above release signingConfig: `// Play App Signing (default) — Google manages the upload keystore per Phase 6 D-15. Debug key here is for local debug builds only; release builds uploaded via Play Console use App Signing.`
- `versionCode = flutter.versionCode` line unchanged
- `versionName = flutter.versionName` line unchanged

## Verification Results

```
flutter test test/policy/ → 26 passing, 2 skipped (manual-only NOTF-02/NOTF-04), 0 failures
flutter test test/policy/play_invariants_test.dart → 13 passing
flutter test test/policy/apk_telemetry_strings_test.dart → 1 passing (APK absent → graceful skip-via-return)
flutter test test/policy/privacy_policy_url_present_test.dart → 2 passing
dart analyze test/policy/ → 0 errors, 0 warnings (17 pre-existing info-level line-length notices matching pattern in phase_5_invariants_test.dart which has 22)
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

- `test/policy/privacy_policy_url_present_test.dart`: Does NOT yet assert a public GitHub Pages URL for the Privacy Policy. This is intentional per plan spec — "full public-URL test lands in 06-08 once the listing + URL is written." Not a blocker for this plan's goal.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced.

## Self-Check: PASSED

Files exist:
- FOUND: test/policy/play_invariants_test.dart
- FOUND: test/policy/apk_telemetry_strings_test.dart
- FOUND: test/policy/privacy_policy_url_present_test.dart
- FOUND: pubspec.yaml (contains `version: 1.0.0+1`)
- FOUND: android/app/build.gradle.kts (contains `Play App Signing`)

Commits exist:
- FOUND: a46ff10 (test(06-07): extend PLAY-09 telemetry absence invariants)
- FOUND: e9cc723 (feat(06-07): bump pubspec version to 1.0.0+1)
