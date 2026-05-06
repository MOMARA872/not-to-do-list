---
phase: 2
plan: 01
subsystem: test-scaffold
wave: 0
status: complete
tags: [test-stubs, drift-schema, mocktail-fixture, phase-2-wave-0]
requires:
  - Phase 1 closed (Drift v1 schema, very_good_analysis, mocktail 1.0.5 in pubspec)
provides:
  - 20 stub test files locking the Phase 2 testable surface area
  - test/_fixtures/permission_status_mock.dart (shared MockPermissionStatusApi + builder)
  - drift_schemas/drift_schema_v1.json (v1 schema export for v1→v2 migration replay)
affects:
  - test/ (new subtree: data/repositories/, domain/schedule/, features/, platform/, _fixtures/)
  - drift_schemas/ (new top-level dir)
tech-stack:
  added: []
  patterns:
    - "test stub convention: group('<Subject> (<REQ-ID>)', () { test('TODO: …', () {}, skip: 'Wave 0 stub — see Plan 02-NN'); })"
    - "WIN-NN truth-table style for is_in_window_test.dart (13 stubs anchor the contract early)"
    - "verbatim PLAY-06 phrase comment block in prominent_disclosure_test.dart for cross-file copy enforcement"
key-files:
  created:
    - drift_schemas/drift_schema_v1.json
    - test/_fixtures/permission_status_mock.dart
    - test/data/database/migration_v1_to_v2_test.dart
    - test/data/repositories/block_list_repo_test.dart
    - test/data/repositories/cascade_delete_test.dart
    - test/domain/schedule/is_in_window_test.dart
    - test/features/list/add_app_picker_test.dart
    - test/features/list/add_app_picker_search_test.dart
    - test/features/list/edit_entry_screen_test.dart
    - test/features/list/schedule_editor_test.dart
    - test/features/onboarding/welcome_screen_test.dart
    - test/features/onboarding/quick_add_screen_test.dart
    - test/features/onboarding/permission_funnel_test.dart
    - test/features/onboarding/permission_resume_detection_test.dart
    - test/features/onboarding/oem_fallback_test.dart
    - test/features/onboarding/prominent_disclosure_test.dart
    - test/features/health/permission_health_provider_test.dart
    - test/features/health/dontkillmyapp_url_test.dart
    - test/features/health/fingerprint_test.dart
    - test/features/home/health_banner_test.dart
    - test/features/home/home_screen_unified_list_test.dart
    - test/platform/app_picker_api_test.dart
  modified: []
decisions:
  - "Stub bodies use skip: parameter (not markTestSkipped()) so flutter test exits 0 with skipped count surfaced explicitly."
  - "PermissionStatusApi forward-declared as a local abstract in the fixture file with TODO(02-03) marker — the Pigeon codegen lands in Plan 02-03; Wave 0 keeps the suite green by avoiding a forward import of an as-yet-uncreated file."
  - "Net file count = 20 stubs (16 from VALIDATION.md + 4 from PATTERNS.md File Inventory: cascade_delete, dontkillmyapp_url, fingerprint, app_picker_api). Plan body explicitly directed using the VALIDATION.md names verbatim (rather than the older drafts in the plan's files_modified frontmatter list); union-with-PATTERNS extras."
  - "is_in_window_test.dart contains exactly 13 WIN-NN stubs as the truth-table contract for Plan 02-04. Names follow the format 'WIN-NN: <intent>' verbatim per the plan."
  - "prominent_disclosure_test.dart includes a comment block enumerating the 5 verbatim PLAY-06 phrases (from docs/play-declaration.md §4) so Plan 02-08's executor sees the phrase contract on the test side too."
  - "Each test file's group declaration includes a (REQ-ID) annotation in the group name, matching the Phase 1 convention from blocked_app_detector_provider_test.dart line 11."
metrics:
  duration_minutes: ~25
  tasks_completed: 3
  test_files_created: 20
  test_fixtures_created: 1
  schema_fixtures_created: 1
  total_files_created: 22
  flutter_test_result: "All tests passed (+6 passing ~32 skipped)"
  dart_analyze_errors: 0
  dart_analyze_warnings: 0
completed: 2026-05-06
---

# Phase 2 Plan 01: Wave 0 test scaffolding Summary

Stubbed all 16 Phase 2 test files from `02-VALIDATION.md` plus 4 extras from `02-PATTERNS.md` File Inventory, captured the Drift v1 schema as a JSON fixture, and added the shared mocktail `Mock<PermissionStatusApi>` fixture — locking the Phase 2 testable surface area before any production code lands. Every Phase 2 REQ-ID (LIST-01..09, ONBD-01..07, PLAY-06, REL-02, REL-03) is now anchored by at least one stubbed test file.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 02-01-01 | Capture Drift v1 schema fixture | `7bb8eba` | `drift_schemas/drift_schema_v1.json` |
| 02-01-02 | Shared mocktail fixture for PermissionStatusApi | `f835841` | `test/_fixtures/permission_status_mock.dart` |
| 02-01-03 | Stub 20 Phase 2 test files | `1e9c76e` | 20 files under `test/` (see frontmatter `key-files.created`) |

## Files Created

**Schema fixture (1):**
- `drift_schemas/drift_schema_v1.json` — 17.5 KB, captured via `dart run drift_dev schema dump`. Contains the unmodified Phase 1 `block_list` table shape (8 columns, no `block_mode`, no `schedule_*`).

**Test fixtures (1):**
- `test/_fixtures/permission_status_mock.dart` — Mocktail `Mock<PermissionStatusApi>` + `buildMockPermissionStatusApi(...)` helper. Forward-declares an abstract `PermissionStatusApi` locally so Wave 0 compiles before the Pigeon codegen lands in Plan 02-03. `TODO(02-03)` marker points the next executor at swapping the abstract for the real generated import.

**Test stubs from VALIDATION.md (16):**
1. `test/data/database/migration_v1_to_v2_test.dart` — `group('AppDatabase v1 → v2 migration (LIST-08, LIST-09)', …)`
2. `test/data/repositories/block_list_repo_test.dart` — `group('BlockListRepository (LIST-02, LIST-03, LIST-04, LIST-08, LIST-09)', …)`
3. `test/features/list/add_app_picker_test.dart` — `group('AddAppPickerScreen (LIST-01, LIST-07)', …)`
4. `test/features/list/add_app_picker_search_test.dart` — `group('AddAppPickerScreen search (LIST-01)', …)`
5. `test/features/list/edit_entry_screen_test.dart` — `group('EditEntryScreen (LIST-04, LIST-05, LIST-08, LIST-09)', …)`
6. `test/features/list/schedule_editor_test.dart` — `group('ScheduleEditor (LIST-09)', …)`
7. `test/domain/schedule/is_in_window_test.dart` — `group('isInScheduleWindow (LIST-09)', …)` with **13 WIN-NN stubs** (WIN-01 through WIN-13)
8. `test/features/onboarding/welcome_screen_test.dart` — `group('WelcomeScreen (ONBD-01)', …)`
9. `test/features/onboarding/quick_add_screen_test.dart` — `group('QuickAddScreen (LIST-07, ONBD-02)', …)`
10. `test/features/onboarding/permission_funnel_test.dart` — `group('Permission funnel flow (ONBD-01, ONBD-02, ONBD-03, ONBD-05)', …)`
11. `test/features/onboarding/permission_resume_detection_test.dart` — `group('Permission resume detection (ONBD-03)', …)`
12. `test/features/onboarding/oem_fallback_test.dart` — `group('OEM reactive fallback (ONBD-04)', …)`
13. `test/features/onboarding/prominent_disclosure_test.dart` — `group('PLAY-06 prominent disclosure (PLAY-06)', …)` with **5-phrase verbatim comment block**
14. `test/features/health/permission_health_provider_test.dart` — `group('permissionHealthProvider (REL-02, REL-03, ONBD-07)', …)`
15. `test/features/home/health_banner_test.dart` — `group('HealthCheckBanner (ONBD-06, REL-02)', …)`
16. `test/features/home/home_screen_unified_list_test.dart` — `group('HomeScreen unified list (LIST-06)', …)`

**Test stubs from PATTERNS.md File Inventory (4 extras):**
17. `test/data/repositories/cascade_delete_test.dart` — `group('BlockList cascade delete (LIST-05)', …)`
18. `test/features/health/dontkillmyapp_url_test.dart` — `group('dontkillmyappUrl (REL-03)', …)`
19. `test/features/health/fingerprint_test.dart` — `group('Build.FINGERPRINT change detection (ONBD-07)', …)`
20. `test/platform/app_picker_api_test.dart` — `group('AppPickerApi Pigeon channel (LIST-01)', …)`

## REQ-ID Coverage Verification

All 19 Phase 2 REQ-IDs have at least one stub file in `test/` whose group declaration carries the REQ-ID annotation:

| REQ-ID | Files referencing |
|--------|-------------------|
| LIST-01 | add_app_picker_test, add_app_picker_search_test, app_picker_api_test |
| LIST-02 | block_list_repo_test |
| LIST-03 | block_list_repo_test |
| LIST-04 | block_list_repo_test, edit_entry_screen_test |
| LIST-05 | edit_entry_screen_test, cascade_delete_test |
| LIST-06 | home_screen_unified_list_test |
| LIST-07 | add_app_picker_test, quick_add_screen_test |
| LIST-08 | migration_v1_to_v2_test, block_list_repo_test, edit_entry_screen_test |
| LIST-09 | migration_v1_to_v2_test, block_list_repo_test, edit_entry_screen_test, schedule_editor_test, is_in_window_test |
| ONBD-01 | welcome_screen_test, permission_funnel_test |
| ONBD-02 | quick_add_screen_test, permission_funnel_test |
| ONBD-03 | permission_funnel_test, permission_resume_detection_test |
| ONBD-04 | oem_fallback_test |
| ONBD-05 | permission_funnel_test |
| ONBD-06 | health_banner_test |
| ONBD-07 | permission_health_provider_test, fingerprint_test |
| PLAY-06 | prominent_disclosure_test (+5-phrase comment block) |
| REL-02 | permission_health_provider_test, health_banner_test |
| REL-03 | permission_health_provider_test, dontkillmyapp_url_test |

## Decisions Made

1. **20 files, not 16.** Plan body explicitly says: "Discard the names I drafted above; create the 16 files with the exact paths from VALIDATION.md … VALIDATION.md's 16 are the MINIMUM; PATTERNS.md adds 4 more. Net: create 20 stub files." Followed exactly.
2. **Stub style.** All 20 stubs use `test('TODO: …', () {}, skip: 'Wave 0 stub — see Plan 02-NN')` — explicit `skip:` parameter, never `markTestSkipped()`. Plan template directly mandates this.
3. **WIN-NN exception.** `is_in_window_test.dart` ships **13 stubbed tests** (the canonical truth-table from 02-RESEARCH.md §Schedule Active-Window Evaluation), not 1. Plan body called this exception out: "the truth-table is the contract."
4. **PLAY-06 phrase enforcement.** `prominent_disclosure_test.dart` carries a comment block enumerating the 5 verbatim PLAY-06 phrases from `docs/play-declaration.md` §4 ("package name", "only when a window-state-changed event fires", "never reads your screen", "never sends anything off your device", "disable this at any time"). Plan body explicitly required this comment-block contract.
5. **Pigeon-codegen forward-reference.** `permission_status_mock.dart` forward-declares a local abstract `PermissionStatusApi` rather than importing `package:not_to_do_list/platform/permission_status_api.g.dart` (which doesn't exist until Plan 02-03). The `TODO(02-03)` comment is in the file body. This keeps Wave 0 compile-clean.
6. **Trailing-comma fix on `is_in_window_test.dart`.** Initial write produced 12 single-line `}, skip: 'pending Plan 02-04');` closures that triggered `require_trailing_commas` info-lints. Added trailing commas + reran `dart format` to bring the file to phase-1 style. Karpathy guideline #3 ("match existing style"). Net effect: 0 lint hints on this file post-fix.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 — Blocking] Plan frontmatter `files_modified` list mismatched the plan body's task instructions**
- **Found during:** Reading the plan
- **Issue:** The plan's frontmatter `files_modified` listed 14 older test-file names + the fixture + schema (16 entries). The plan body's Task 02-01-03 explicitly overrode that list with the verbatim VALIDATION.md 16 + 4 PATTERNS.md extras. The plan body even contains the line: "Adjust the `files_modified` list at the top of this plan accordingly when finalizing."
- **Resolution:** Followed the plan body (the more specific instruction) verbatim. Net: 22 files created (20 stubs + 1 fixture + 1 schema). Did NOT edit the plan file itself — the plan stays as-shipped; this SUMMARY documents the executor's reading.
- **Files affected:** all 20 stubs + fixture + schema
- **Commits:** 7bb8eba, f835841, 1e9c76e

**2. [Rule 1 — Style match] Trailing-comma lints on is_in_window_test.dart**
- **Found during:** Task 02-01-03 verification (`dart analyze test/`)
- **Issue:** Initial write of the 12 single-line WIN tests (`}, skip: 'pending Plan 02-04');`) triggered `require_trailing_commas` info-lints from `very_good_analysis 10.2.0`. Phase 1 test files comply with this lint.
- **Resolution:** Surgical `replace_all` to add trailing comma + `dart format` to reflow into multi-line `test(\n  '…',\n  () { … },\n  skip: '…',\n);` style.
- **Verification:** `dart analyze test/domain/schedule/is_in_window_test.dart` reports `No issues found!`
- **Commit:** 1e9c76e (folded into the same task commit since it landed before the commit boundary)

### Auth gates

None — pure-Dart Wave 0 work, no platform calls.

### Architectural changes (Rule 4)

None.

## Plan Verification

- [x] `drift_schemas/drift_schema_v1.json` captured before any v2 column lands; `block_list_table.dart` byte-identical to Phase 1 (`git diff` returns empty)
- [x] All 20 test files compile and `flutter test` exits 0 (`+6 ~32 — All tests passed!`)
- [x] `test/_fixtures/permission_status_mock.dart` ready for Plan 02-05 / 02-08 to import (analyzes clean — 0 errors, 0 warnings; info-lints come from the verbatim plan-mandated content)
- [x] `dart analyze test/` reports 0 errors, 0 warnings
- [x] Plan's `must_haves.truths` all satisfied:
  - Every Phase 2 REQ-ID has ≥1 stub file with `(REQ-ID)` group annotation ✓
  - v1 Drift schema captured under `drift_schemas/` ✓
  - `flutter test` runs to completion, suite exits 0 ✓
- [ ] **Per-Task Verification Map** in `02-VALIDATION.md` is filled by Plan 02-10 (final phase gate), not by this plan — Wave 0 itself does not flip `nyquist_compliant: true`. (Per the plan's Verification section: "Per-Task Verification Map … updated by Plan 02-10 (final phase gate) — Wave 0 itself does not flip nyquist_compliant: true.")

## TDD Gate Compliance

This plan is `type: execute` (not `type: tdd`), so the RED/GREEN/REFACTOR plan-level gate does not apply. However, all 3 tasks land as `test()` commits (matching the test-stub work product), correctly typed per the commit-protocol contract.

## Self-Check: PASSED

**File existence (all 22 created files):**
- ✓ FOUND: drift_schemas/drift_schema_v1.json
- ✓ FOUND: test/_fixtures/permission_status_mock.dart
- ✓ FOUND: test/data/database/migration_v1_to_v2_test.dart
- ✓ FOUND: test/data/repositories/block_list_repo_test.dart
- ✓ FOUND: test/data/repositories/cascade_delete_test.dart
- ✓ FOUND: test/domain/schedule/is_in_window_test.dart
- ✓ FOUND: test/features/list/add_app_picker_test.dart
- ✓ FOUND: test/features/list/add_app_picker_search_test.dart
- ✓ FOUND: test/features/list/edit_entry_screen_test.dart
- ✓ FOUND: test/features/list/schedule_editor_test.dart
- ✓ FOUND: test/features/onboarding/welcome_screen_test.dart
- ✓ FOUND: test/features/onboarding/quick_add_screen_test.dart
- ✓ FOUND: test/features/onboarding/permission_funnel_test.dart
- ✓ FOUND: test/features/onboarding/permission_resume_detection_test.dart
- ✓ FOUND: test/features/onboarding/oem_fallback_test.dart
- ✓ FOUND: test/features/onboarding/prominent_disclosure_test.dart
- ✓ FOUND: test/features/health/permission_health_provider_test.dart
- ✓ FOUND: test/features/health/dontkillmyapp_url_test.dart
- ✓ FOUND: test/features/health/fingerprint_test.dart
- ✓ FOUND: test/features/home/health_banner_test.dart
- ✓ FOUND: test/features/home/home_screen_unified_list_test.dart
- ✓ FOUND: test/platform/app_picker_api_test.dart

**Commit existence:**
- ✓ FOUND: 7bb8eba (test(02-01): capture Drift v1 schema fixture)
- ✓ FOUND: f835841 (test(02-01): add shared mocktail fixture for PermissionStatusApi)
- ✓ FOUND: 1e9c76e (test(02-01): stub 20 Phase 2 test files)

## Ready for Wave 1

Wave 0 lock-in is complete. The next plan(s) (Plan 02-02 onward) can now proceed against a known test surface:

- **Plan 02-02** (Drift v2 migration) replays `drift_schemas/drift_schema_v1.json` against the in-memory DB, applies the migration, and asserts the v2 columns (`block_mode`, `schedule_*`) land as specified. The fixture is byte-pinned now — any Wave 1 edit to `block_list_table.dart` will produce a v2 schema export that diffs cleanly against this v1 baseline.
- **Plan 02-03** (Pigeon channels) generates `lib/platform/permission_status_api.g.dart` and `lib/platform/app_picker_api.g.dart`. After this lands, the `TODO(02-03)` marker in `test/_fixtures/permission_status_mock.dart` becomes actionable: swap the local abstract for the generated import.
- **Plans 02-04 through 02-09** fill in the assertion bodies of the 20 stub files, removing the `skip:` markers as each REQ-ID's behavior lands.
- **Plan 02-10** (phase exit gate) flips `nyquist_compliant: true` in `02-VALIDATION.md` after the Per-Task Verification Map is populated and every stub is filled in.
