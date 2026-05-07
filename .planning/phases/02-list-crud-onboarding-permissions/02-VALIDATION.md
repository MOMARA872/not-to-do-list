---
phase: 2
slug: list-crud-onboarding-permissions
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
verified: 2026-05-07
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Per-Task Verification Map populated by Plan 02-10 from each plan's
> automated verify commands and SUMMARY frontmatter.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK) + `mocktail 1.0.5` |
| **Config file** | None — Flutter convention (`test/` directory) |
| **Quick run command** | `flutter test test/<changed_subtree>` |
| **Full suite command** | `flutter test` |
| **Final test count** | 124 passing, 0 skipped |
| **Estimated runtime** | ~30 s (full suite, post-Phase 2 baseline 124 tests) |

---

## Sampling Rate

- **After every task commit:** Run the targeted test file(s) for the changed subtree.
- **After every plan wave:** Run `flutter test` (full suite).
- **Before `/gsd-verify-work`:** Full suite must be green; `dart analyze` clean.
- **Max feedback latency:** 60 s.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 02-01 | 0 | LIST-08, LIST-09 | fixture-capture | `dart run drift_dev schema dump …` (v1 export) | `drift_schemas/drift_schema_v1.json` | ✅ green |
| 02-01-02 | 02-01 | 0 | (multi) | fixture | `flutter analyze test/_fixtures/permission_status_mock.dart` | `test/_fixtures/permission_status_mock.dart` | ✅ green |
| 02-01-03 | 02-01 | 0 | (multi) | scaffold | `flutter test` (20 stub files exist + skip-marked) | 20 stub test files under `test/` | ✅ green |
| 02-02-01 | 02-02 | 1 | LIST-08, LIST-09 | unit | `flutter pub run build_runner build` + grep on table | `lib/data/database/tables/block_list_table.dart` | ✅ green |
| 02-02-02 | 02-02 | 1 | LIST-08, LIST-09 | unit | `flutter test test/data/database/app_database_test.dart` | `lib/data/database/app_database.dart` | ✅ green |
| 02-02-03 | 02-02 | 1 | LIST-05, LIST-08, LIST-09 | unit (migration + cascade) | `flutter test test/data/database/migration_v1_to_v2_test.dart test/data/repositories/cascade_delete_test.dart` | `test/data/database/migration_v1_to_v2_test.dart` + `test/data/repositories/cascade_delete_test.dart` + `test/generated_migrations/` | ✅ green |
| 02-03-01 | 02-03 | 1 | LIST-01 | codegen + grep | `dart run pigeon --input pigeons/app_picker_api.dart` | `pigeons/app_picker_api.dart` + `lib/platform/app_picker_api.g.dart` + Kotlin g.kt | ✅ green |
| 02-03-02 | 02-03 | 1 | (multi) | codegen + grep | `dart run pigeon --input pigeons/permission_status_api.dart` | `pigeons/permission_status_api.dart` + `lib/platform/permission_status_api.g.dart` + Kotlin g.kt | ✅ green |
| 02-03-03 | 02-03 | 1 | LIST-01, LIST-07, PLAY-04 | smoke (Kotlin compile) | `flutter build apk --debug` | `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt` | ✅ green |
| 02-03-04 | 02-03 | 1 | (multi) | smoke (Kotlin compile) | `flutter build apk --debug` | `…/PermissionStatusApiImpl.kt` | ✅ green |
| 02-03-05 | 02-03 | 1 | LIST-01 | unit | `flutter test test/platform/app_picker_api_test.dart` | `test/platform/app_picker_api_test.dart` | ✅ green |
| 02-04-01 | 02-04 | 2 | (multi) | unit | `flutter test test/data/database/app_database_test.dart` | `lib/data/database/daos/block_list_dao.dart` | ✅ green |
| 02-04-02 | 02-04 | 2 | LIST-02..09 | unit | `flutter test test/data/repositories/block_list_repo_test.dart` | `lib/data/repositories/block_list_repository.dart` + `lib/domain/providers/block_list_dao_provider.dart` + `lib/domain/providers/block_list_repo_provider.dart` | ✅ green |
| 02-04-03 | 02-04 | 2 | LIST-09 | unit (truth table 13 cases) | `flutter test test/domain/schedule/is_in_window_test.dart` | `lib/domain/schedule/schedule_window.dart` + `lib/domain/schedule/streak_day.dart` | ✅ green |
| 02-05-01 | 02-05 | 2 | REL-03 | unit | `flutter test test/features/health/dontkillmyapp_url_test.dart` | `lib/core/utils/dontkillmyapp_url.dart` | ✅ green |
| 02-05-02 | 02-05 | 2 | (multi) | analyze | `dart analyze lib/features/onboarding/providers/` | `lib/features/onboarding/providers/onboarding_complete_provider.dart` + `lib/features/onboarding/providers/onboarding_cursor_provider.dart` | ✅ green |
| 02-05-03 | 02-05 | 2 | REL-02, ONBD-06, ONBD-07 | unit | `flutter test test/features/health/permission_health_provider_test.dart test/features/health/fingerprint_test.dart` | `lib/features/health/permission_health_provider.dart` | ✅ green |
| 02-05-04 | 02-05 | 2 | LIST-01 | analyze | `dart analyze lib/features/list/providers/` | `lib/features/list/providers/app_icon_cache_provider.dart` + `lib/features/list/providers/installed_apps_provider.dart` + `lib/features/list/providers/recently_used_apps_provider.dart` | ✅ green |
| 02-06-01 | 02-06 | 3 | (theme) | smoke | `flutter pub get` + `flutter test` | `pubspec.yaml` (dynamic_color, url_launcher) + `lib/core/theme/app_theme.dart` | ✅ green |
| 02-06-02 | 02-06 | 3 | LIST-01, LIST-07 | widget | `flutter test test/features/list/add_app_picker_test.dart test/features/list/add_app_picker_search_test.dart` | `lib/features/list/pages/add_app_picker_screen.dart` + `lib/features/list/widgets/app_icon.dart` + `lib/features/list/controllers/app_picker_controller.dart` | ✅ green |
| 02-06-03 | 02-06 | 3 | LIST-02..05, LIST-08, LIST-09 | widget | `flutter test test/features/list/edit_entry_screen_test.dart test/features/list/schedule_editor_test.dart` | `lib/features/list/pages/add_habit_screen.dart` + `lib/features/list/pages/edit_entry_screen.dart` + `lib/features/list/widgets/block_mode_segmented.dart` + `lib/features/list/widgets/schedule_editor.dart` | ✅ green |
| 02-07-01 | 02-07 | 3 | LIST-04, LIST-05, LIST-06 | analyze + widget | `dart analyze lib/features/home/` | `lib/features/home/widgets/block_list_row.dart` + `lib/features/home/widgets/empty_home_state.dart` | ✅ green |
| 02-07-02 | 02-07 | 3 | LIST-06 | widget | `flutter test test/features/home/home_screen_unified_list_test.dart` | `lib/features/home/pages/home_screen.dart` | ✅ green |
| 02-08-01 | 02-08 | 3 | ONBD-01, LIST-07 | widget | `flutter test test/features/onboarding/welcome_screen_test.dart test/features/onboarding/quick_add_screen_test.dart test/features/onboarding/quick_add_test.dart` | `lib/features/onboarding/pages/welcome_screen.dart` + `lib/features/onboarding/pages/quick_add_screen.dart` | ✅ green |
| 02-08-02 | 02-08 | 3 | ONBD-04, REL-03 | widget | `flutter test test/features/onboarding/oem_fallback_test.dart` | `lib/features/onboarding/widgets/rationale_screen.dart` + `lib/features/onboarding/widgets/permission_step_dots.dart` + `lib/features/onboarding/widgets/oem_fallback_panel.dart` | ✅ green |
| 02-08-03 | 02-08 | 3 | ONBD-02, ONBD-03, ONBD-05, PLAY-06 | widget + grep | `flutter test test/features/onboarding/permission_funnel_test.dart test/features/onboarding/permission_resume_detection_test.dart test/features/onboarding/prominent_disclosure_test.dart test/features/onboarding/funnel_flow_test.dart` | `lib/features/onboarding/pages/usage_access_step.dart` + `…/accessibility_step.dart` + `…/battery_opt_step.dart` | ✅ green |
| 02-09-01 | 02-09 | 4 | REL-02, REL-03, ONBD-06 | widget | `flutter test test/features/home/health_banner_test.dart` | `lib/features/health/widgets/health_check_banner.dart` + `lib/features/health/widgets/_health_lifecycle_observer.dart` | ✅ green |
| 02-09-02 | 02-09 | 4 | (router glue) | smoke | `flutter test` + `flutter build apk --debug` | `lib/core/router/app_router.dart` (9 GoRoutes + redirect) + `lib/app.dart` (DynamicColorBuilder + HealthLifecycleObserver) | ✅ green |
| 02-09-03 | 02-09 | 4 | (assets) | smoke | `flutter build apk --debug` | `assets/onboarding/{usage_access_step,accessibility_step,battery_opt_step}.png` + `assets/logos/{instagram,tiktok,x,youtube,reddit}.png` + 2 READMEs | ✅ green |
| 02-09-04 | 02-09 | 4 | (manual) | manual UAT | (manual checklist 13 items on Pixel emulator stock Android 16) | (n/a) | ✅ signed off 2026-05-07 |
| 02-10-01 | 02-10 | 6 | PLAY-02..06 + v1 scope | invariant | `flutter test test/policy/play_invariants_test.dart` | `test/policy/play_invariants_test.dart` (8 tests) | ✅ green |
| 02-10-02 | 02-10 | 6 | (gate) | aggregate | `flutter test && dart analyze && flutter build apk --debug` + manifest grep | `.planning/phases/02-list-crud-onboarding-permissions/02-VALIDATION.md` (this file) | ✅ green |
| 02-10-03 | 02-10 | 6 | (exit checkpoint) | human-verify | (developer review of test count + manifest audit + git log) | (n/a) | ✅ signed off 2026-05-07 (UAT) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The following test files were stubbed in Wave 0 of the planner output (one
empty assertion per REQ-ID was sufficient — assertions land in subsequent
waves). All have been filled in by their owning plan:

- [x] `test/data/database/migration_v1_to_v2_test.dart` — Drift v1→v2 round-trip (LIST-08, LIST-09 schema) [Plan 02-02]
- [x] `test/data/repositories/block_list_repo_test.dart` — CRUD + cascade delete (LIST-02..06) [Plan 02-04]
- [x] `test/features/list/add_app_picker_test.dart` — picker integration (LIST-01, LIST-07) [Plan 02-06]
- [x] `test/features/list/add_app_picker_search_test.dart` — search-first behavior [Plan 02-06]
- [x] `test/features/list/edit_entry_screen_test.dart` — segmented Soft/Hard control + delete (LIST-04, LIST-05, LIST-08) [Plan 02-06]
- [x] `test/features/list/schedule_editor_test.dart` — schedule editor UI (LIST-09) [Plan 02-06]
- [x] `test/domain/schedule/is_in_window_test.dart` — pure-Dart window evaluation (LIST-09 logic) [Plan 02-04]
- [x] `test/features/onboarding/welcome_screen_test.dart` — single-CTA welcome (ONBD-01) [Plan 02-08]
- [x] `test/features/onboarding/quick_add_screen_test.dart` — 5-card unchecked-by-default picker (ONBD-02, LIST-07) [Plan 02-08]
- [x] `test/features/onboarding/permission_funnel_test.dart` — 3-step ordered funnel (ONBD-03) [Plan 02-08]
- [x] `test/features/onboarding/permission_resume_detection_test.dart` — auto-advance on resumed (ONBD-05) [Plan 02-08]
- [x] `test/features/onboarding/oem_fallback_test.dart` — `Build.MANUFACTURER`-keyed reactive guidance (ONBD-04) [Plan 02-08]
- [x] `test/features/onboarding/prominent_disclosure_test.dart` — copy parity with `docs/play-declaration.md` (PLAY-06) [Plan 02-08]
- [x] `test/features/health/permission_health_provider_test.dart` — self-healing health check (REL-02, REL-03, ONBD-07) [Plan 02-05]
- [x] `test/features/home/health_banner_test.dart` — banner copy "Tracking is offline — tap to fix" [Plan 02-09]
- [x] `test/features/home/home_screen_unified_list_test.dart` — Apps + Habits unified list sorted by recent activity (LIST-06) [Plan 02-07]

**Plus 4 additional stubs from PATTERNS.md File Inventory:**

- [x] `test/data/repositories/cascade_delete_test.dart` — Drift FK cascade [Plan 02-02]
- [x] `test/features/health/dontkillmyapp_url_test.dart` — pure-Dart helper [Plan 02-05]
- [x] `test/features/health/fingerprint_test.dart` — fingerprint baseline [Plan 02-05]
- [x] `test/platform/app_picker_api_test.dart` — Pigeon channel exists/instantiable [Plan 02-03; placeholder skip removed by Plan 02-10]

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Status |
|----------|-------------|------------|--------|
| OEM ComponentName fallback resolves on real Xiaomi/Samsung device | ONBD-04 | ROM-version-dependent; emulators do not reproduce vendor Settings apps | DEFERRED to Phase 4 (real-device test) |
| `Build.FINGERPRINT` change re-verification on OS update | ONBD-07 | Cannot synthesize an OS update in tests | DEFERRED to post-OTA smoke |
| 13-step install-time UAT walkthrough on Pixel emulator (Plan 02-09-04) | (cross-cutting) | End-to-end human verification of the funnel | ✅ SIGNED OFF 2026-05-07 (Pixel emulator stock Android 16) |

---

## Validation Sign-Off

- [x] All Phase 2 tasks have `<automated>` verify command OR are listed under Manual-Only above
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all 16 test files listed above (plus 4 PATTERNS extras)
- [x] No `flutter test --watch` or watch-mode flags in plans
- [x] Feedback latency < 60 s for the quick command
- [x] `nyquist_compliant: true` set in frontmatter (planner filled the per-task map; Plan 02-10 verified)
- [x] `flutter test` exits 0 — 124 passing, 0 skipped
- [x] `dart analyze` exits 0 — 0 errors, 0 warnings (18 pre-existing infos in pigeons/* + permission_status_mock.dart per deferred-items.md)
- [x] `flutter build apk --debug` exits 0 — `Built build/app/outputs/flutter-apk/app-debug.apk`
- [x] AndroidManifest.xml does NOT declare `QUERY_ALL_PACKAGES`, `SYSTEM_ALERT_WINDOW`, or `BIND_DEVICE_ADMIN`
- [x] PLAY-02/03/04/05/06 + v1-scope cross-tree absence-grep policy test green (`test/policy/play_invariants_test.dart` — 8 tests)
- [x] Manual UAT (Plan 02-09-04) signed off 2026-05-07

**Approval:** ✅ COMPLETE — Phase 2 ships clean. Verified by Plan 02-10 on 2026-05-07.
