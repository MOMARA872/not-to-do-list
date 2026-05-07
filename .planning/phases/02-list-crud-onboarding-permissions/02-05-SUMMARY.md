---
phase: 2
plan: 05
subsystem: state-providers
tags: [riverpod, async-notifier, shared-preferences, fingerprint-detection, lru-cache, onboarding-cursor]
plan_id: 02-05
status: complete
completed_at: "2026-05-05T00:00:00Z"
duration_minutes: 25
requires:
  - 02-03 (Pigeon AppPickerApi + PermissionStatusApi classes — instantiated by the Wave 2 providers; mocktail fixture already imports the real class)
  - Phase 1 (flutter_riverpod 3.3.1 + shared_preferences 2.5.5 already in pubspec — no new deps)
provides:
  - "permissionStatusApiProvider — Provider<PermissionStatusApi> singleton wrapping the Pigeon channel; tests override with MockPermissionStatusApi"
  - "appPickerApiProvider — Provider<AppPickerApi> singleton; tests override with MockAppPickerApi (Plan 02-06 will add the mock)"
  - "permissionHealthProvider — AsyncNotifierProvider<PermissionHealthNotifier, PermissionHealth>; reads 3 perms + Build.FINGERPRINT, emits allHealthy bool, exposes refresh() + persistCurrentFingerprint()"
  - "onboardingCursorProvider — AsyncNotifierProvider<OnboardingCursorNotifier, int> backed by shared_preferences['onboarding_step']; methods set(int) + advance()"
  - "onboardingCompleteProvider — AsyncNotifierProvider<OnboardingCompleteNotifier, bool> backed by shared_preferences['onboarding_complete']; methods markComplete() + reset()"
  - "OnboardingKeys — abstract final class with const cursor / complete / lastKnownFingerprint keys (single source of truth)"
  - "dontkillmyappUrl(manufacturerLower) — pure function returning https://dontkillmyapp.com/<slug> for {xiaomi,huawei,samsung,oppo,vivo,oneplus} or null"
  - "AppIconLruCache + appIconCacheProvider + appIconBytesProvider — capacity-50 LinkedHashMap LRU, autoDispose, in-memory only"
  - "installedAppsProvider — autoDispose FutureProvider<List<InstalledApp>>"
  - "recentlyUsedAppsProvider — autoDispose family<int> over List<RecentApp>"
affects:
  - "Plan 02-06 (app picker UI) — consumes installedAppsProvider, recentlyUsedAppsProvider(7), appIconBytesProvider(packageName); must gate the Recently-Used section on PermissionStatusApi.isUsageAccessGranted() (T-2-03)"
  - "Plan 02-08 (onboarding wizard) — consumes onboardingCursorProvider for resume + onboardingCompleteProvider.markComplete() at funnel exit; should call permissionHealthProvider.persistCurrentFingerprint() at funnel exit so the OS-update flag clears"
  - "Plan 02-09 (health-check banner) — consumes permissionHealthProvider; must call refresh() in AppLifecycleState.resumed and on cold launch; uses dontkillmyappUrl(manufacturerLower) for the OEM-specific row"
tech-stack:
  added: []
  patterns:
    - "Hand-written AsyncNotifier (no riverpod_annotation codegen) — matches Phase 1 deviation due to pigeon 26.3.4 + analyzer pin conflict"
    - "shared_preferences as the single durable store for onboarding state and the fingerprint baseline; android:allowBackup=false (Phase 1) keeps it private"
    - "Compile-time const map for OEM slug resolution + hard-coded https:// host (T-2-04 mitigation against URL tampering)"
    - "First-install fingerprint baseline rule: storedFp == null branch records without flagging — only a true mismatch triggers fingerprintChanged"
    - "Capacity-bounded LinkedHashMap with move-to-end on get + while-evict on put — 7 lines, no external dep"
    - "Riverpod 3 family-typed classes (FutureProviderFamily) require explicit `import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;` for very_good_analysis specify_nonobvious_property_types"
key-files:
  created:
    - lib/domain/providers/permission_status_api_provider.dart
    - lib/domain/providers/app_picker_api_provider.dart
    - lib/features/onboarding/storage_keys.dart
    - lib/features/onboarding/providers/onboarding_complete_provider.dart
    - lib/features/onboarding/providers/onboarding_cursor_provider.dart
    - lib/features/health/permission_health_provider.dart
    - lib/features/list/providers/installed_apps_provider.dart
    - lib/features/list/providers/recently_used_apps_provider.dart
    - lib/features/list/providers/app_icon_cache_provider.dart
    - lib/core/utils/dontkillmyapp_url.dart
    - .planning/phases/02-list-crud-onboarding-permissions/deferred-items.md
  modified:
    - test/features/health/dontkillmyapp_url_test.dart
    - test/features/health/fingerprint_test.dart
    - test/features/health/permission_health_provider_test.dart
decisions:
  - "Kept the Pigeon-API providers under lib/domain/providers/ (alongside database_provider.dart and blocked_app_detector_provider.dart) instead of feature-namespaced subdirs. The plan body's <action> places them there; this also matches the cross-feature semantics — both AppPickerApi and PermissionStatusApi are consumed by health, list, and onboarding features."
  - "Did NOT modify test/_fixtures/permission_status_mock.dart even though it has 11 very_good_analysis infos (8 unnecessary_lambdas false-positives on mocktail's canonical idiom + 3 line-length). Owned by Plan 02-03; CLAUDE.md surgical-changes rule says don't 'improve' adjacent code. Logged in deferred-items.md."
  - "Used `package:flutter_riverpod/misc.dart` for FutureProviderFamily — the only public export path for the family-typed class. Without the explicit type annotation, very_good_analysis fires specify_nonobvious_property_types."
  - "Test file added file-level `// ignore_for_file: unnecessary_lambdas` because mocktail's `when(() => mock.method())` idiom triggers the lint. Same idiom is used in test/_fixtures/permission_status_mock.dart but the fixture is owned by Plan 02-03 and not modified by this plan."
metrics:
  duration_minutes: 25
  completed_date: "2026-05-05"
  tasks_completed: 4
  files_created: 11
  files_modified: 3
  commits: 4
requirements_completed:
  - REL-02
  - REL-03
  - ONBD-03
  - ONBD-05
  - ONBD-06
  - ONBD-07
  - LIST-07
---

# Phase 2 Plan 02-05: Permission status, health-check provider, picker providers, onboarding cursor — Summary

The Riverpod state layer for Phase 2 is now in place: every Wave 3 surface (the picker UI in 02-06, the onboarding wizard in 02-08, the health banner in 02-09) has typed, hand-written providers to consume. The four runtime providers — `permissionHealthProvider`, `onboardingCursorProvider`, `onboardingCompleteProvider`, and the picker trio — all build on the two new platform-API providers (`permissionStatusApiProvider`, `appPickerApiProvider`), which simply construct the Pigeon classes from Plan 02-03. The `dontkillmyappUrl` helper and `OnboardingKeys` constants give the banner and resume logic the literal strings they need without anyone hand-rolling them.

## What was built

### Task 02-05-01 — Pigeon-API providers + storage keys + dontkillmyapp helper → `b76e6f7`

- `lib/domain/providers/permission_status_api_provider.dart`: `final Provider<PermissionStatusApi> permissionStatusApiProvider`. Hand-written, no codegen.
- `lib/domain/providers/app_picker_api_provider.dart`: `final Provider<AppPickerApi> appPickerApiProvider`.
- `lib/features/onboarding/storage_keys.dart`: `abstract final class OnboardingKeys` with three const string keys (`cursor`, `complete`, `lastKnownFingerprint`).
- `lib/core/utils/dontkillmyapp_url.dart`: const `_oemSlugs` map for the 6 known aggressive vendors (`xiaomi`/`huawei`/`samsung`/`oppo`/`vivo`/`oneplus`), pure function `String? dontkillmyappUrl(String manufacturerLower)` returning `https://dontkillmyapp.com/<slug>` or null. T-2-04 mitigation: host hard-coded to `https://`, slug map-resolved (never user-interpolated).
- `test/features/health/dontkillmyapp_url_test.dart`: Wave 0 stub replaced; 9 assertions including `expect(url!.startsWith('https://'), isTrue)` for every recognized OEM (no http leak).

### Task 02-05-02 — Onboarding cursor + complete providers → `bc852d9`

- `lib/features/onboarding/providers/onboarding_complete_provider.dart`: `OnboardingCompleteNotifier extends AsyncNotifier<bool>` reading/writing `shared_preferences['onboarding_complete']` (default false). Methods `markComplete()` (sets true + emits AsyncValue.data(true)) and `reset()` (sets false + emits AsyncValue.data(false)).
- `lib/features/onboarding/providers/onboarding_cursor_provider.dart`: `OnboardingCursorNotifier extends AsyncNotifier<int>` reading/writing `shared_preferences['onboarding_step']` (default 0). Methods `set(int)` and `advance()` (increments by 1).
- Both providers MUST be hand-written per Phase 1 deviation; verified no `@riverpod` annotation, no `part '...'` directive.

### Task 02-05-03 — `permissionHealthProvider` AsyncNotifier + Build.FINGERPRINT detection → `61c6143`

- `lib/features/health/permission_health_provider.dart`:
  - `class PermissionHealth { usageAccess, accessibilityService, batteryOptExempt, fingerprintChanged }` with `bool get allHealthy => usageAccess && accessibilityService && batteryOptExempt && !fingerprintChanged;` (REL-02).
  - `PermissionHealthNotifier extends AsyncNotifier<PermissionHealth>` with `_evaluate()` that reads all 3 perms + compares `currentBuildFingerprint()` to `shared_preferences['last_known_fingerprint']`.
  - **First-install rule (RESEARCH lines 568-576):** if `storedFp == null`, baseline is recorded WITHOUT flagging `fingerprintChanged=true`. Only a strict `storedFp != currentFp` triggers the flag. Verified by `fingerprint_test.dart` "first install" case.
  - `refresh()` to reset state to loading then re-evaluate (Plan 02-09 will hook this into `AppLifecycleState.resumed`).
  - `persistCurrentFingerprint()` to clear the OS-update flag after the user re-verifies (called by Plan 02-08 funnel completion + Plan 02-09 banner re-entry).
- `test/features/health/permission_health_provider_test.dart`: 3 assertions — fresh-install allHealthy + baseline persisted; one revoked perm → allHealthy=false; refresh recomputes after permission change.
- `test/features/health/fingerprint_test.dart`: 3 assertions — first-install no-flag; OS-update mismatch flags + forces allHealthy=false; persistCurrentFingerprint clears the flag and updates the stored value.

### Task 02-05-04 — Picker support providers (LIST-07) → `01be242`

- `lib/features/list/providers/installed_apps_provider.dart`: `FutureProvider.autoDispose<List<InstalledApp>>` over `AppPickerApi.listInstalledApps()`. Auto-disposes when the picker closes; refetches on next open.
- `lib/features/list/providers/recently_used_apps_provider.dart`: `FutureProvider.autoDispose.family<List<RecentApp>, int>` taking `daysBack` (typically 7). Returns empty list if Usage Access not granted (Plan 02-03's silent-empty contract — caller MUST gate on `isUsageAccessGranted()` to surface the inline grant prompt; T-2-03 mitigation).
- `lib/features/list/providers/app_icon_cache_provider.dart`:
  - `class AppIconLruCache { capacity = 50 }` with `LinkedHashMap<String, Uint8List>` backing store. `get` does move-to-end via `_store.remove(key)` + `_store[key] = v`. `put` runs `while (_store.length > capacity)` evicting `_store.keys.first`.
  - `appIconCacheProvider`: `Provider.autoDispose<AppIconLruCache>` so the cache drops when the picker closes.
  - `appIconBytesProvider`: `FutureProvider.autoDispose.family<Uint8List?, String>` that consults the cache, calls `getApplicationIconPng(packageName)` on miss, and `cache.put`s a non-null result.

## Public provider names Wave 3 will consume

For Plan 02-06 (picker UI):

```dart
// Riverpod imports
import 'package:not_to_do_list/domain/providers/app_picker_api_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/list/providers/installed_apps_provider.dart';
import 'package:not_to_do_list/features/list/providers/recently_used_apps_provider.dart';
import 'package:not_to_do_list/features/list/providers/app_icon_cache_provider.dart';

// Use:
ref.watch(installedAppsProvider)                   // AsyncValue<List<InstalledApp>>
ref.watch(recentlyUsedAppsProvider(7))             // AsyncValue<List<RecentApp>>; gate on isUsageAccessGranted() FIRST
ref.watch(appIconBytesProvider(packageName))       // AsyncValue<Uint8List?>
```

For Plan 02-08 (onboarding wizard):

```dart
import 'package:not_to_do_list/features/onboarding/providers/onboarding_cursor_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_complete_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';

// Use:
ref.watch(onboardingCursorProvider)                                 // AsyncValue<int> 0..4
ref.read(onboardingCursorProvider.notifier).set(2)                  // jump to a step
ref.read(onboardingCursorProvider.notifier).advance()               // current+1
ref.read(onboardingCompleteProvider.notifier).markComplete()        // funnel done
ref.read(permissionHealthProvider.notifier).persistCurrentFingerprint()  // CALL AT FUNNEL EXIT
ref.read(permissionStatusApiProvider).openUsageAccessSettings()     // deep-link launchers
```

For Plan 02-09 (health banner):

```dart
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/core/utils/dontkillmyapp_url.dart';

// Use:
ref.watch(permissionHealthProvider).when(
  data: (h) => h.allHealthy ? const SizedBox.shrink() : HealthBanner(...),
  loading: () => const SizedBox.shrink(),
  error: (e, _) => HealthBanner.error(),
);
ref.read(permissionHealthProvider.notifier).refresh()       // call on AppLifecycleState.resumed + cold launch
final mfr = await ref.read(permissionStatusApiProvider).currentManufacturer();
final url = dontkillmyappUrl(mfr);                          // null for non-aggressive OEMs
```

## Verification

- [x] `permissionHealthProvider._evaluate` reads from `PermissionStatusApi`, never directly from native code.
- [x] First-install fingerprint baseline does NOT flag `fingerprintChanged=true` (verified by `fingerprint_test.dart` "first install" case).
- [x] OS-update fingerprint mismatch DOES flag `fingerprintChanged=true` and forces `allHealthy=false` (verified by `fingerprint_test.dart` "OS update" case).
- [x] Icon cache is capacity-bounded (50) and uses `Provider.autoDispose` so it clears between picker sessions.
- [x] All providers hand-written; no `@riverpod` codegen, no `part '...'` directive.
- [x] `dontkillmyappUrl` returns only https URLs; no http leaks (verified by "every URL is https" test loop over all 6 OEMs).
- [x] `flutter test` exits 0 — 48 passing, 13 still-Wave-0-stubbed (owned by 02-06/08/09).
- [x] `dart analyze` clean for all files this plan owns; pre-existing infos in Plan 02-03 outputs logged in deferred-items.md.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Riverpod 3.x `valueOrNull` getter doesn't exist on `AsyncValue<int>`**
- **Found during:** Task 02-05-02 dart analyze
- **Issue:** Plan body's `OnboardingCursorNotifier.advance()` snippet used `state.valueOrNull ?? 0`, which is a Riverpod 2.x API. In Riverpod 3.x (3.2.1 transitive, used by `flutter_riverpod 3.3.1`) the getter is `state.value` (returns `T?`).
- **Fix:** `state.valueOrNull` → `state.value` (one-line change in `onboarding_cursor_provider.dart`). Behaviorally identical.
- **Files modified:** lib/features/onboarding/providers/onboarding_cursor_provider.dart
- **Commit:** `bc852d9`

**2. [Rule 3 - Blocking] Riverpod 3.x family-typed class only exported from `misc.dart`**
- **Found during:** Task 02-05-04 dart analyze
- **Issue:** very_good_analysis `specify_nonobvious_property_types` requires explicit type annotations on the provider top-level vars. `FutureProviderFamily<V, A>` is the runtime type but it's `@publicInMisc`-annotated and only re-exported from `package:flutter_riverpod/misc.dart`, not the default `flutter_riverpod.dart` barrel.
- **Fix:** Added `import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;` to `recently_used_apps_provider.dart` and `app_icon_cache_provider.dart`. Used `FutureProvider<T>` (no AutoDispose-prefixed variant exists in Riverpod 3 — `isAutoDispose` is a flag on the base type) for the non-family one.
- **Files modified:** lib/features/list/providers/recently_used_apps_provider.dart, lib/features/list/providers/app_icon_cache_provider.dart
- **Commit:** `01be242`

**3. [Rule 3 - Blocking] Plan body's `recentlyUsedAppsProvider` declaration uses invalid Dart**
- **Found during:** Task 02-05-04
- **Issue:** Plan body Step 2 wrote `final FutureProvider.autoDispose.family<List<RecentApp>, int> recentlyUsedAppsProvider = FutureProvider.autoDispose.family<List<RecentApp>, int>(...)` — `FutureProvider.autoDispose.family<...>` cannot appear as a type annotation. The plan's own Note explicitly addresses this and provides the corrected form.
- **Fix:** Used the corrected form from the plan's Note, then added the explicit `FutureProviderFamily<V, A>` type annotation to satisfy the analyzer.
- **Files modified:** lib/features/list/providers/recently_used_apps_provider.dart
- **Commit:** `01be242`

**4. [Rule 1 - Bug] very_good_analysis `unnecessary_lambdas` misfires on mocktail idiom**
- **Found during:** Task 02-05-03 dart analyze
- **Issue:** mocktail's canonical `when(() => mock.method())` is a 0-arg closure that returns a method invocation; it is NOT convertible to a tearoff (it's already short, but the lint sees `() => mock.foo()` and suggests `mock.foo`, which would be wrong). 5 infos triggered in `permission_health_provider_test.dart`.
- **Fix:** Added file-level `// ignore_for_file: unnecessary_lambdas` with a one-line comment explaining the misfire.
- **Files modified:** test/features/health/permission_health_provider_test.dart
- **Commit:** `61c6143`

### Path discrepancy with prompt's `<verification>` block

The prompt's `<verification>` block named these paths:
- `lib/features/health/providers/permission_health_provider.dart` (with `providers/` subdir)
- `lib/features/list/providers/app_picker_provider.dart`

The plan body's `<action>`, `files_modified` frontmatter, and `<automated>` checks all specified:
- `lib/features/health/permission_health_provider.dart` (no subdir)
- `lib/domain/providers/app_picker_api_provider.dart` (alongside the other Pigeon-API provider, `database_provider.dart`, and `blocked_app_detector_provider.dart`)

I followed the plan body — that's the canonical contract per the executor's `<load_plan>` step, and it places the Pigeon-API providers consistently with Phase 1's `database_provider.dart`. The provider name is `appPickerApiProvider`, matching the variable name the plan body's Step 2 declares.

### Out-of-scope items deferred

11 pre-existing `dart analyze` infos in Plan 02-03 outputs (`pigeons/*.dart`, `test/_fixtures/permission_status_mock.dart`) are documented in `.planning/phases/02-list-crud-onboarding-permissions/deferred-items.md`. Per CLAUDE.md surgical-changes rule, I did not touch them.

## Authentication Gates

None encountered — this plan is pure Dart code touching no authenticated services.

## Threat Model Mitigations Realized

| Threat | Disposition | Status |
|--------|-------------|--------|
| T-2-03 Information Disclosure — silent-revoked permission masked as healthy | mitigate | Refreshable AsyncNotifier ships in this plan (`permissionHealthProvider.notifier.refresh()`); Plan 02-09 wires the lifecycle/cold-launch trigger. |
| T-2-04 Tampering — `dontkillmyappUrl` produces tampered URL | mitigate | Compile-time const slug map in `dontkillmyapp_url.dart`; host hard-coded `https://`; test asserts every recognized-OEM URL starts with `https://` and rejects unknown / wrong-case manufacturers. |
| T-2-07 Information Disclosure — fingerprint baseline backed up via adb | mitigate | `last_known_fingerprint` lives in shared_preferences which Phase 1 covered with `android:allowBackup="false"`. No new disk surface added — icon cache is in-memory only. |
| T-2-08 Tampering — fresh-install fingerprint baseline freezes stale state | accept (per plan) | Confirmed: first call to `_evaluate()` writes baseline AND returns the current grant state; subsequent grants flow through `refresh()`. |

## Threat Flags

None — no new security-relevant surface beyond the plan's threat_model.

## Known Stubs

None introduced. All providers are fully wired:
- `permissionHealthProvider` is **functional**, not stubbed; Plan 02-09 just hooks `refresh()` to `AppLifecycleState`.
- `onboardingCursorProvider` and `onboardingCompleteProvider` are **functional**, not stubbed; Plan 02-08 widget tests will exercise them.
- `installedAppsProvider`, `recentlyUsedAppsProvider`, and `appIconBytesProvider` are **functional**, not stubbed; Plan 02-06 widget tests will override `appPickerApiProvider` with a mock.

## Self-Check: PASSED

All claims verified:
- ✅ `lib/domain/providers/permission_status_api_provider.dart` exists
- ✅ `lib/domain/providers/app_picker_api_provider.dart` exists
- ✅ `lib/features/onboarding/storage_keys.dart` exists with `cursor`, `complete`, `lastKnownFingerprint`
- ✅ `lib/features/onboarding/providers/onboarding_complete_provider.dart` exists
- ✅ `lib/features/onboarding/providers/onboarding_cursor_provider.dart` exists
- ✅ `lib/features/health/permission_health_provider.dart` exists with `class PermissionHealth`, `if (storedFp == null)`, `persistCurrentFingerprint`, `OnboardingKeys.lastKnownFingerprint`
- ✅ `lib/features/list/providers/installed_apps_provider.dart` exists
- ✅ `lib/features/list/providers/recently_used_apps_provider.dart` exists
- ✅ `lib/features/list/providers/app_icon_cache_provider.dart` exists with `class AppIconLruCache`, `capacity = 50`, `LinkedHashMap<String, Uint8List>`, `while (_store.length > capacity)`
- ✅ `lib/core/utils/dontkillmyapp_url.dart` exists with `https://dontkillmyapp.com/$slug`, no `http://` literal
- ✅ Wave 0 test stubs filled in: `dontkillmyapp_url_test.dart` (9 tests), `fingerprint_test.dart` (3 tests), `permission_health_provider_test.dart` (3 tests) — 15 new assertions, 0 skipped
- ✅ `flutter test` exits 0 (48 passing, 13 still-Wave-0-stubbed for 02-06/08/09)
- ✅ `dart analyze` clean for all files this plan owns
- ✅ Commit `b76e6f7` (Task 1) found in git log
- ✅ Commit `bc852d9` (Task 2) found in git log
- ✅ Commit `61c6143` (Task 3) found in git log
- ✅ Commit `01be242` (Task 4) found in git log
