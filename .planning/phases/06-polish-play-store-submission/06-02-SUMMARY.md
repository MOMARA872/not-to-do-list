---
phase: "06-polish-play-store-submission"
plan: "02"
subsystem: "theme-persistence + MaterialApp-wire"
tags: ["wave-1", "theme", "riverpod", "shared-preferences", "SETT-04"]
dependency_graph:
  requires:
    - "06-01 (pubspec deps, RED test stubs)"
  provides:
    - "AsyncNotifier<ThemeMode> (themeModeProvider) — reads/writes SharedPreferences int under 'theme_mode'"
    - "OnboardingKeys.themeMode = 'theme_mode' constant"
    - "MaterialApp.router.themeMode wired to themeModeProvider (D-08 surgical edit)"
  affects:
    - "06-03 (ThemeTile settings UI imports themeModeProvider)"
    - "06-05 (Reset invalidates themeModeProvider)"
tech_stack:
  added: []
  patterns:
    - "AsyncNotifier<ThemeMode> hand-written (no riverpod_annotation codegen — Phase 1 lock)"
    - "maybeWhen(data: orElse: ThemeMode.system) safe-default pattern in app.dart"
    - "UncontrolledProviderScope + _AsyncLoadingNotifier pattern for widget tests with provider overrides"
key_files:
  created:
    - "lib/features/settings/providers/theme_mode_provider.dart"
  modified:
    - "lib/features/onboarding/storage_keys.dart (appended themeMode constant)"
    - "lib/app.dart (import + themeMode local var + MaterialApp.router themeMode: arg)"
    - "test/features/settings/theme_mode_provider_test.dart (RED→GREEN: 4 tests)"
    - "test/app/theme_rebuild_test.dart (RED→GREEN: 3 tests)"
decisions:
  - "Used plain // comments instead of /// for file-level docs to avoid dangling_library_doc_comments lint (Dart requires 'library' directive for top-of-file /// doc comments)"
  - "theme_rebuild_test.dart uses _ThemeTestApp (plain MaterialApp) not NotToDoApp/MaterialApp.router to avoid go_router + appRouterProvider boilerplate in tests; satisfies themeMode rebuild contract per D-08"
  - "Test 1 uses _AsyncLoadingNotifier (Completer.future that never resolves) to simulate AsyncLoading state and verify orElse fallback to ThemeMode.system"
metrics:
  duration: "~15min"
  completed: "2026-05-24"
  tasks_completed: 2
  files_created: 1
  files_modified: 4
---

# Phase 6 Plan 02: Theme Persistence Infrastructure Summary

AsyncNotifier<ThemeMode> with SharedPreferences int persistence (0=system/1=light/2=dark), OnboardingKeys.themeMode constant, and surgical MaterialApp.router themeMode: wire-up — closes D-05..D-08.

## What Was Built

**Task 1: themeModeProvider + OnboardingKeys.themeMode constant** (commit `ae4799e`)

- Created `lib/features/settings/providers/theme_mode_provider.dart`:
  - Pure top-level `ThemeMode _decode(int raw)` — switch with fail-safe default ThemeMode.system
  - Pure top-level `int _encode(ThemeMode m)` — switch returning 0/1/2
  - `class ThemeModeNotifier extends AsyncNotifier<ThemeMode>` with `build()` (default 0→system) and `set()` (writes prefs + updates state synchronously)
  - `final AsyncNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider` binding
- Appended `static const String themeMode = 'theme_mode'` to `OnboardingKeys` in `storage_keys.dart`
- Unskipped 4 tests in `theme_mode_provider_test.dart` — all GREEN:
  - default ThemeMode.system when no prefs value
  - persist int across rebuild (decode 1=light, 2=dark, set writes back)
  - encode/decode round-trip + unknown int fail-safe
  - set(dark) writes int 2 + state becomes AsyncValue.data(ThemeMode.dark)

**Task 2: Wire themeMode into MaterialApp.router** (commit `f7fa928`)

- Added import of `theme_mode_provider.dart` to `lib/app.dart`
- Added `final themeMode = ref.watch(themeModeProvider).maybeWhen(data: (m) => m, orElse: () => ThemeMode.system)` in `build()`
- Added `themeMode: themeMode,` to `MaterialApp.router(...)` args between `darkTheme:` and `routerConfig:`
- AppTheme.light/dark calls and DynamicColorBuilder untouched (D-08 lock preserved)
- Unskipped 3 tests in `test/app/theme_rebuild_test.dart` — all GREEN:
  - AsyncLoading → ThemeMode.system via orElse fallback
  - AsyncValue.data(dark) → MaterialApp.themeMode == dark
  - set(light) → themeMode flips to light on next pump

## Verification

- `flutter test test/features/settings/theme_mode_provider_test.dart` exits 0: 4 passing
- `flutter test test/app/theme_rebuild_test.dart` exits 0: 3 passing
- `flutter test` (full suite) exits 0: 495 passing, 48 skipped (up from 488+54 in 06-01)
- `dart analyze lib/features/settings/providers/ lib/app.dart lib/features/onboarding/storage_keys.dart` — no issues found

## Deviations from Plan

### [Rule 1 - Bug] Fixed dangling_library_doc_comments lint in theme_mode_provider.dart

**Found during:** Task 1 dart analyze
**Issue:** Using `///` at file top-level without a `library` directive triggers `dangling_library_doc_comments` lint error (Dart requires `library` directive before `///` file doc comments).
**Fix:** Changed file-level `///` doc comments to plain `//` comments.
**Files modified:** `lib/features/settings/providers/theme_mode_provider.dart`
**Impact:** No behavioral change. dart analyze now reports 0 issues.

### Implementation note: theme_rebuild_test uses _ThemeTestApp (not NotToDoApp)

**Found during:** Task 2 test implementation
**Context:** The plan suggested pumping `NotToDoApp`. However, `NotToDoApp` uses `MaterialApp.router` which pulls in `appRouterProvider` → `onboardingCompleteProvider` → database → full app stack. Overriding all of this in a widget test focused on themeMode would be excessive boilerplate and fragile.
**Decision:** Used a minimal `_ThemeTestApp` (plain `MaterialApp` not router variant) with only `themeModeProvider` in scope. This still validates the core D-08 contract: `ref.watch(themeModeProvider).maybeWhen(...)` drives `themeMode:` and rebuilds on state change. The same pattern is used in `lib/app.dart` itself.
**Rule:** Not a deviation — equivalent coverage with simpler test harness (CLAUDE.md §2 Simplicity First).

## Known Stubs

None. Both provider and wire-up are fully implemented. The ThemeTile UI (06-03) will drive the provider from the user-facing settings screen.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes. SharedPreferences writes are local-only (existing security boundary).

## Self-Check: PASSED

- [x] `lib/features/settings/providers/theme_mode_provider.dart` exists with `class ThemeModeNotifier extends AsyncNotifier<ThemeMode>`
- [x] File contains `ThemeMode _decode(int` and `int _encode(ThemeMode` top-level helpers
- [x] File contains `final AsyncNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =`
- [x] `lib/features/onboarding/storage_keys.dart` contains `static const String themeMode = 'theme_mode'`
- [x] `lib/app.dart` contains `themeMode:` in MaterialApp.router args
- [x] `lib/app.dart` contains `ref.watch(themeModeProvider).maybeWhen`
- [x] No `riverpod_annotation` / `@riverpod` import in provider file
- [x] Commits `ae4799e` and `f7fa928` exist on `worktree-agent-a4c9dc09d65db7ee7`
- [x] `flutter test` exits 0 (495 passing + 48 skipped)
