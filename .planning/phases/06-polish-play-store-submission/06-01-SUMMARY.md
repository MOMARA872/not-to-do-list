---
phase: "06-polish-play-store-submission"
plan: "01"
subsystem: "test-scaffold + pubspec + daos"
tags: ["wave-0", "red-tests", "pubspec", "daos", "privacy"]
dependency_graph:
  requires: []
  provides:
    - "19 Phase 6 RED test stubs (all markTestSkipped; flutter test exits 0)"
    - "4 new pubspec deps: archive ^4.0.9, flutter_file_dialog ^3.0.3, flutter_markdown_plus ^1.0.7, package_info_plus ^10.1.0"
    - "docs/PRIVACY.md stub bundled as asset"
    - "5/5 DAOs expose Future<List<XxxData>> getAll() for export reads"
    - "test/_fixtures/file_save_port_mock.dart placeholder for 06-04 wiring"
  affects:
    - "All Phase 6 plans (Wave 1+) depend on these RED stubs for GREEN flip"
tech_stack:
  added:
    - "archive ^4.0.9 (ZIP builder)"
    - "flutter_file_dialog ^3.0.3 (SAF save port)"
    - "flutter_markdown_plus ^1.0.7 (in-app Privacy Policy renderer)"
    - "package_info_plus ^10.1.0 (About tile version surface)"
    - "integration_test (SDK dep, for phase6_happy_path_test.dart)"
  patterns:
    - "markTestSkipped RED stub convention (mirrors Phase 4 04-01 + Phase 5 05-01)"
    - "Placeholder abstract class pattern for FileSavePort (activated in 06-04)"
key_files:
  created:
    - "docs/PRIVACY.md"
    - "test/features/settings/settings_screen_test.dart"
    - "test/features/settings/theme_mode_provider_test.dart"
    - "test/features/settings/theme_segmented_button_test.dart"
    - "test/features/settings/about_tile_test.dart"
    - "test/features/settings/export_controller_test.dart"
    - "test/features/settings/export_csv_format_test.dart"
    - "test/features/settings/export_json_envelope_test.dart"
    - "test/features/settings/file_save_port_test.dart"
    - "test/features/settings/reset_controller_test.dart"
    - "test/features/settings/reset_dialog_test.dart"
    - "test/features/settings/privacy_screen_test.dart"
    - "test/features/settings/disclosure_route_test.dart"
    - "test/features/settings/export_screen_test.dart"
    - "test/features/home/home_appbar_settings_action_test.dart"
    - "test/app/theme_rebuild_test.dart"
    - "test/policy/apk_telemetry_strings_test.dart"
    - "test/policy/privacy_policy_url_present_test.dart"
    - "integration_test/phase6_happy_path_test.dart"
    - "test/_fixtures/file_save_port_mock.dart"
  modified:
    - "pubspec.yaml (4 deps + integration_test + docs/PRIVACY.md asset)"
    - "pubspec.lock"
    - "lib/data/database/daos/daily_checkins_dao.dart (getAll())"
    - "lib/data/database/daos/daily_streak_dao.dart (getAll())"
    - "lib/data/database/daos/pause_event_dao.dart (getAll())"
    - "lib/data/database/daos/daily_usage_summary_dao.dart (getAll())"
decisions:
  - "Used integration_test: { sdk: flutter } in dev_dependencies to support phase6_happy_path_test.dart (no external package needed)"
  - "Used placeholder abstract class pattern for FileSavePort in test fixture (cleaner than commented import; 06-04 will remove the placeholder)"
  - "privacy_policy_url_present_test.dart: the docs/PRIVACY.md existence check passes NOW (not a RED stub); the settings-link test is still a RED stub for 06-06"
  - "Discovered accidental commit to main repo (not worktree) during Task 1 — fixed via git reset --hard on main and re-applied all changes to correct worktree path"
metrics:
  duration: "~25min"
  completed: "2026-05-24"
  tasks_completed: 2
  files_created: 20
  files_modified: 6
---

# Phase 6 Plan 01: Wave 0 RED Test Scaffold Summary

Wave 0 RED test scaffold for Phase 6 — all 19 failing test stubs, 4 pubspec deps, 4 DAO getAll() additions, docs/PRIVACY.md stub, and FileSavePort mock fixture.

## What Was Built

**Task 1: Pubspec deps + DAO getAll() + docs/PRIVACY.md stub** (commit `f5f40c2`)

- Added 4 new dependencies to `pubspec.yaml`: `archive: ^4.0.9`, `flutter_file_dialog: ^3.0.3`, `flutter_markdown_plus: ^1.0.7`, `package_info_plus: ^10.1.0`
- Registered `docs/PRIVACY.md` as a bundled Flutter asset in `pubspec.yaml`
- Created `docs/PRIVACY.md` stub (calm tone, zero-collection, on-device only, no external links per Pitfall 6)
- Added `Future<List<DailyCheckin>> getAll()` to `DailyCheckinsDao`
- Added `Future<List<DailyStreakData>> getAll()` to `DailyStreakDao`
- Added `Future<List<PauseEvent>> getAll()` to `PauseEventDao`
- Added `Future<List<DailyUsageSummaryData>> getAll()` to `DailyUsageSummaryDao`
- `flutter pub get` resolves all 4 new deps; `flutter pub deps --no-dev | grep -iE '(firebase|crashlytics|analytics|fcm|remoteconfig)'` returns no matches

**Task 2: 19 RED test stubs + FileSavePort mock fixture** (commit `9e318e1`)

- Created all 19 Phase 6 test files at the paths specified in the plan
- Each file uses `markTestSkipped('RED stub — Phase 6 Wave 0; implementation in 06-XX')` to keep `flutter test` exit code 0
- `privacy_policy_url_present_test.dart` has one test that PASSES NOW (docs/PRIVACY.md exists), one still skipped (settings link — 06-06)
- Created `test/_fixtures/file_save_port_mock.dart` with placeholder abstract class + `MockFileSavePort extends Mock implements FileSavePort`
- Added `integration_test: { sdk: flutter }` to dev_dependencies for `phase6_happy_path_test.dart`
- Full suite: 488 passing / 54 skipped / 0 failures (Phase 5 baseline was 487 passing / 5 skipped)

## Verification

- `flutter pub get` exits 0
- `dart analyze pubspec.yaml lib/data/database/daos/ docs/` — 2 pre-existing infos in daily_streak_dao.dart (lines 127/145 pre-Phase-6), no new errors
- `flutter test test/features/settings/ test/features/home/home_appbar_settings_action_test.dart test/app/theme_rebuild_test.dart test/policy/apk_telemetry_strings_test.dart test/policy/privacy_policy_url_present_test.dart` exits 0 (all skipped + 1 passing)
- `flutter test` (full suite) exits 0: 488 passing, 54 skipped
- No telemetry transitive deps found

## Deviations from Plan

### Deviation (worktree path error — self-corrected)

**Found during:** Task 1 implementation
**Issue:** Initial Task 1 changes were applied to the main repo at `/Users/jintanakhomwong/projects/not-to-do-list/` instead of the worktree at `/Users/jintanakhomwong/projects/not-to-do-list/.claude/worktrees/agent-ae2ea34d732b6b04c/`. This resulted in an accidental commit to the `main` branch.
**Fix:** Reset `main` with `git reset --hard HEAD~1` to undo the erroneous commit, then re-applied all Task 1 changes to the correct worktree directory.
**Impact:** No net change to plan output; worktree branch received the correct commit.

### Missing `integration_test` SDK dep (Rule 3 - Blocking)

**Found during:** Task 2 (writing `phase6_happy_path_test.dart`)
**Issue:** The plan required `integration_test/phase6_happy_path_test.dart` which imports `package:integration_test/integration_test.dart`. This package was not in pubspec.yaml.
**Fix:** Added `integration_test: { sdk: flutter }` to dev_dependencies.
**Files modified:** `pubspec.yaml`, `pubspec.lock`
**Impact:** None — this is an SDK package with zero external dependencies.

## Known Stubs

All 19 test files are intentional stubs (per Wave 0 plan design). The stub in `test/_fixtures/file_save_port_mock.dart` uses a placeholder `abstract class FileSavePort` marked `@Deprecated('placeholder — superseded by file_save_port.dart in 06-04')`. This is intentional and documented for 06-04 to wire the real interface.

## Threat Flags

None. This plan adds test scaffolding, pubspec deps, DAO read methods, and a static Markdown stub. No new network endpoints, auth paths, file access patterns (beyond the bundled asset declaration), or schema changes at trust boundaries.

## Self-Check: PASSED

- [x] `docs/PRIVACY.md` exists and starts with `# Privacy Policy`
- [x] `pubspec.yaml` contains `archive: ^4.0.9`
- [x] `pubspec.yaml` `flutter.assets:` contains `- docs/PRIVACY.md`
- [x] 4 DAO files contain `Future<List<` (getAll added)
- [x] 19 test files exist at required paths
- [x] `test/_fixtures/file_save_port_mock.dart` exists with `MockFileSavePort`
- [x] Commits `f5f40c2` and `9e318e1` exist on `worktree-agent-ae2ea34d732b6b04c`
- [x] `flutter test` exits 0 (488 passing + 54 skipped)
