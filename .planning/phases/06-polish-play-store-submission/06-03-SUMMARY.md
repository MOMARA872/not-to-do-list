---
phase: "06-polish-play-store-submission"
plan: "03"
subsystem: "settings-hub-ui + home-appbar + router"
tags: ["wave-2", "settings", "ui", "router", "SETT-04", "SETT-05", "PLAY-08"]
dependency_graph:
  requires:
    - "06-01 (RED test stubs + pubspec deps)"
    - "06-02 (themeModeProvider + MaterialApp.router wire-up)"
  provides:
    - "SettingsScreen ConsumerWidget with 6 sections + 8 tiles in D-04 + Claude a.i order"
    - "SectionHeader / ThemeTile / AboutTile / StreakThresholdTile widgets"
    - "4 new GoRouter routes: /settings /settings/export /settings/privacy /settings/disclosure"
    - "ExportScreen + PrivacyScreen placeholders (bodies land in 06-04 / 06-06)"
    - "HomeScreen AppBar gear icon (Settings gear first action, notifications second)"
    - "Phase 5 D-08 inline Streak section closure (Claude's Discretion option a.i)"
  affects:
    - "06-04 (ExportScreen body + FileSavePort wiring)"
    - "06-05 (ResetController wiring + reset dialog body copy)"
    - "06-06 (PrivacyScreen body + AccessibilityStep.fromSettings param)"
tech_stack:
  added: []
  patterns:
    - "ConsumerWidget + ListView + SectionHeader sectioned layout"
    - "SegmentedButton<ThemeMode> inline settings tile (no subscreen push)"
    - "FutureBuilder<PackageInfo> display tile with em-dash placeholder"
    - "Streak threshold tile re-uses Phase 5 _ThresholdDialog Slider UI inline"
    - "drainStreamTimers pattern for home widget tests with Drift StreamProvider"
    - "tester.view.physicalSize override to force full ListView render in tests"
key_files:
  created:
    - "lib/features/settings/widgets/section_header.dart"
    - "lib/features/settings/widgets/theme_tile.dart"
    - "lib/features/settings/widgets/about_tile.dart"
    - "lib/features/settings/widgets/streak_threshold_tile.dart"
    - "lib/features/settings/pages/settings_screen.dart"
    - "lib/features/settings/pages/export_screen.dart"
    - "lib/features/settings/pages/privacy_screen.dart"
  modified:
    - "lib/core/router/app_router.dart (4 new GoRoute entries added)"
    - "lib/features/home/pages/home_screen.dart (gear icon inserted as first AppBar action)"
    - "test/features/settings/theme_segmented_button_test.dart (RED→GREEN: 3 tests)"
    - "test/features/settings/about_tile_test.dart (RED→GREEN: 1 test)"
    - "test/features/settings/settings_screen_test.dart (RED→GREEN: 3 tests)"
    - "test/features/home/home_appbar_settings_action_test.dart (RED→GREEN: 3 tests)"
decisions:
  - "Removed all // ignore: lines_longer_than_80_chars from app_router.dart — lint disabled in very_good_analysis 10.2.0; unnecessary_ignore errors found and cleaned"
  - "Used tester.view.physicalSize = Size(1080, 4000) in settings_screen_test to force full ListView render (lazy ListView only renders visible items by default)"
  - "Used drainStreamTimers pattern in home_appbar_settings_action_test to resolve pending Drift stream timer after widget disposal"
  - "_showResetDialog made async (Future<void>) to avoid discarded_futures lint from showDialog call"
metrics:
  duration: "~18min"
  completed: "2026-05-24"
  tasks_completed: 3
  files_created: 7
  files_modified: 6
---

# Phase 6 Plan 03: Settings Hub UI + HomeScreen Gear + Router Summary

Settings hub UI with 6 sectioned ListView + 8 tiles in D-04 order, inline SegmentedButton theme tile, FutureBuilder About tile, Phase 5 D-08 Streak threshold inline section, 4 new GoRouter routes, and HomeScreen AppBar gear icon — closes SETT-04 UI and PLAY-08 AppBar requirement.

## What Was Built

**Task 1: SectionHeader + ThemeTile + AboutTile + StreakThresholdTile widgets** (commit `77ab6c9`)

- `lib/features/settings/widgets/section_header.dart`: pure `StatelessWidget` with `EdgeInsets.fromLTRB(16, 16, 16, 4)` + `labelSmall.copyWith(color: primary, letterSpacing: 0.8)` per UI-SPEC
- `lib/features/settings/widgets/theme_tile.dart`: `ConsumerWidget` with `SegmentedButton<ThemeMode>` 3-segment (Light/Dark/System), label-only (no icons), reads/writes `themeModeProvider` directly
- `lib/features/settings/widgets/about_tile.dart`: `StatelessWidget` with `FutureBuilder<PackageInfo>`, em-dash placeholder while loading, `'${version} (${buildNumber})'` format (no `+` glue, Pitfall 7 compliance)
- `lib/features/settings/widgets/streak_threshold_tile.dart`: `ConsumerWidget` reading `streakThresholdProvider`, opens `AlertDialog` with `Slider(min:1, max:60, divisions:59)` — mirrors Phase 5 `_ThresholdDialog` body, closes D-08 soft-lock
- `theme_segmented_button_test.dart`: 3 tests GREEN (3 segments rendered, tap writes provider, selected set size 1)
- `about_tile_test.dart`: 1 test GREEN (version format "1.0.0 (1)" not "1.0.0+1")

**Task 2: SettingsScreen + GoRouter routes + placeholder screens** (commit `787e80b`)

- `lib/features/settings/pages/settings_screen.dart`: `ConsumerWidget` with 6 `SectionHeader` + 8 tiles in exact order: Reminder / Streak / Appearance / Data / Privacy / About
  - Reminder tile: `DateFormat.jm()` subtitle from `reminderTimeProvider`
  - Streak section: inline `StreakThresholdTile()` (Claude's Discretion option a.i, closes Phase 5 D-08)
  - Appearance section: inline `ThemeTile()`
  - Data section: Export navigation tile + Reset tile with `cs.error` color cue
  - Privacy section: Privacy Policy + Accessibility disclosure tiles
  - About section: inline `AboutTile()`
  - `_showResetDialog`: placeholder `AlertDialog` with `TODO(06-05)` marker for ResetController wiring
- `lib/features/settings/pages/export_screen.dart`: placeholder with `TODO(06-04)` comment
- `lib/features/settings/pages/privacy_screen.dart`: placeholder with `TODO(06-06)` comment
- `lib/core/router/app_router.dart`: 4 new routes appended after `/settings/reminder`:
  - `/settings` → `SettingsScreen()`
  - `/settings/export` → `ExportScreen()`
  - `/settings/privacy` → `PrivacyScreen()`
  - `/settings/disclosure` → `AccessibilityStep()` (TODO(06-06) for `fromSettings: true` param)
- `settings_screen_test.dart`: 3 tests GREEN (6 headers in order, settings reachable, Phase 5 D-08 Streak section above Appearance)

**Task 3: HomeScreen AppBar gear icon insertion** (commit `ec595b7`)

- `lib/features/home/pages/home_screen.dart`: `Semantics(label: 'Settings', child: IconButton(icon: Icon(Icons.settings), tooltip: 'Settings', onPressed: () => context.go('/settings')))` inserted as FIRST action; existing notifications IconButton preserved as SECOND
- `home_appbar_settings_action_test.dart`: 3 tests GREEN (icon + tooltip present, tap routes to /settings, notifications button preserved)

## Verification

- `flutter test test/features/settings/ test/features/home/` exits 0: 44 passing, 31 skipped (all RED stubs for 06-04/06-05/06-06)
- `flutter test` (full suite) exits 0: 505 passing, 38 skipped — no regressions vs. 06-02 baseline (495 passing + 48 skipped; +10 passing, -10 skipped from new GREEN flips)
- `dart analyze lib/features/settings/ lib/features/home/pages/home_screen.dart lib/core/router/app_router.dart` — no issues found

## Deviations from Plan

### [Rule 1 - Bug] Fixed unnecessary_ignore lint in app_router.dart

**Found during:** Task 2 dart analyze
**Issue:** I added `// ignore: lines_longer_than_80_chars` comments above router entries following the existing convention in the file. However, the `very_good_analysis 10.2.0` analysis_options.yaml does NOT enable `lines_longer_than_80_chars` lint (only older versions like 10.1.0 did). This means all existing and new `// ignore:` comments triggered `unnecessary_ignore` warnings, and the `document_ignores` rule required explanation comments above each ignore.
**Fix:** Removed ALL `// ignore: lines_longer_than_80_chars` comments from `app_router.dart` (both pre-existing and new). Lines that are long remain as-is since the lint is inactive.
**Files modified:** `lib/core/router/app_router.dart`
**Impact:** No behavioral change. dart analyze now reports 0 issues.

### [Rule 1 - Bug] Fixed discarded_futures lint in settings_screen.dart

**Found during:** Task 2 dart analyze
**Issue:** `_showResetDialog` used `showDialog<void>(...)` without `await` in a non-async `void` method, triggering `discarded_futures` lint.
**Fix:** Changed method signature to `Future<void> _showResetDialog(...)` async and added `await` before `showDialog`.
**Files modified:** `lib/features/settings/pages/settings_screen.dart`
**Impact:** No behavioral change.

### [Rule 3 - Blocking] Test fix: tester.view.physicalSize for full ListView render

**Found during:** Task 2 settings_screen_test.dart
**Issue:** First test run found only 5 `SectionHeader` widgets (expected 6). The `ListView` uses lazy rendering — not all items visible at once in default 800x600 test viewport.
**Fix:** Added `tester.view.physicalSize = const Size(1080, 4000)` + `tester.view.devicePixelRatio = 1.0` at the start of tests that need all ListView items, with tearDown resets.
**Files modified:** `test/features/settings/settings_screen_test.dart`
**Impact:** Tests now reliably find all 6 SectionHeaders.

### [Rule 3 - Blocking] Test fix: drainStreamTimers for Drift stream disposal

**Found during:** Task 3 home_appbar_settings_action_test.dart
**Issue:** Tests failed with "A Timer is still pending even after the widget tree was disposed" from Drift's `StreamQueryStore.markAsClosed` scheduling a microtask on dispose. Existing `home_screen_unified_list_test.dart` already had this pattern but the new test missed it.
**Fix:** Added `drainStreamTimers(tester)` helper (identical to existing pattern) called at the end of each testWidgets block.
**Files modified:** `test/features/home/home_appbar_settings_action_test.dart`
**Impact:** Tests now pass cleanly without pending timer warnings.

## Known Stubs

- `lib/features/settings/pages/export_screen.dart`: placeholder body (`CircularProgressIndicator`) — full ExportScreen implementation lands in Plan 06-04
- `lib/features/settings/pages/privacy_screen.dart`: placeholder body (`CircularProgressIndicator`) — full PrivacyScreen with `flutter_markdown_plus` lands in Plan 06-06
- `lib/core/router/app_router.dart` line for `/settings/disclosure`: registered with `const AccessibilityStep()` — the `fromSettings: true` constructor param lands in Plan 06-06
- `_showResetDialog` in `settings_screen.dart`: placeholder `AlertDialog` body with `TODO(06-05): body copy literal` marker — ResetController wiring + D-13 verbatim body copy lands in Plan 06-05

## Threat Flags

None. No new network endpoints, auth paths, or schema changes. All navigation is in-app GoRouter. The Settings hub only wires existing providers and placeholder screens.

## Self-Check: PASSED

- [x] `lib/features/settings/widgets/section_header.dart` contains `EdgeInsets.fromLTRB(16, 16, 16, 4)` and `labelSmall`
- [x] `lib/features/settings/widgets/theme_tile.dart` contains `SegmentedButton<ThemeMode>` AND `ButtonSegment<ThemeMode>(value: ThemeMode.light` AND `ref.read(themeModeProvider.notifier).set(`
- [x] `lib/features/settings/widgets/about_tile.dart` contains `FutureBuilder<PackageInfo>` AND `'${snap.data!.version} (${snap.data!.buildNumber})'`
- [x] `lib/features/settings/widgets/streak_threshold_tile.dart` contains `streakThresholdProvider` AND `Slider(`
- [x] `lib/features/settings/pages/settings_screen.dart` contains exactly 6 `SectionHeader(label:` instances (Reminder, Streak, Appearance, Data, Privacy, About)
- [x] `settings_screen.dart` contains `context.go('/settings/reminder')`, `context.go('/settings/export')`, `context.go('/settings/privacy')`, `context.go('/settings/disclosure')`
- [x] `settings_screen.dart` contains `cs.error`
- [x] `lib/core/router/app_router.dart` contains GoRoute paths `/settings`, `/settings/export`, `/settings/privacy`, `/settings/disclosure`
- [x] `lib/features/home/pages/home_screen.dart` contains `Icons.settings` AND `tooltip: 'Settings'` AND `context.go('/settings')`
- [x] `Icons.notifications_outlined` preserved in `home_screen.dart`
- [x] Commits `77ab6c9`, `787e80b`, `ec595b7` exist on `worktree-agent-a2314b37e5b7d0411`
- [x] `flutter test` exits 0 (505 passing + 38 skipped)
