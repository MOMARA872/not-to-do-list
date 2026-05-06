---
phase: 2
slug: list-crud-onboarding-permissions
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-05
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Detailed per-task verification map is filled by `gsd-planner` from the
> Phase 2 research artifact (`02-RESEARCH.md` § Validation Architecture).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK) + `mocktail 1.0.5` |
| **Config file** | None — Flutter convention (`test/` directory) |
| **Quick run command** | `flutter test test/<changed_subtree>` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 s (full suite, post-Phase 1 baseline ~84 tests) |

---

## Sampling Rate

- **After every task commit:** Run the targeted test file(s) for the changed subtree.
- **After every plan wave:** Run `flutter test` (full suite).
- **Before `/gsd-verify-work`:** Full suite must be green; `dart analyze` clean.
- **Max feedback latency:** 60 s.

---

## Per-Task Verification Map

> **TO BE FILLED BY THE PLANNER.** The planner emits one row per task across
> all PLAN.md files. Each row maps `{Task ID, Plan, Wave, REQ-ID, test type,
> automated command, file existence}`. The 19-row "Phase Requirements → Test
> Map" table inside `02-RESEARCH.md` is the seed; the planner expands it to
> per-task granularity (multiple tasks per REQ-ID where appropriate).

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| _(filled by planner)_ | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The following test files MUST be stubbed in Wave 0 of the planner output (one
empty assertion per REQ-ID is sufficient — assertions land in subsequent waves):

- [ ] `test/data/database/migration_v1_to_v2_test.dart` — Drift v1→v2 round-trip (LIST-08, LIST-09 schema)
- [ ] `test/data/repositories/block_list_repo_test.dart` — CRUD + cascade delete (LIST-02..06)
- [ ] `test/features/list/add_app_picker_test.dart` — picker integration (LIST-01, LIST-07)
- [ ] `test/features/list/add_app_picker_search_test.dart` — search-first behavior
- [ ] `test/features/list/edit_entry_screen_test.dart` — segmented Soft/Hard control + delete (LIST-04, LIST-05, LIST-08)
- [ ] `test/features/list/schedule_editor_test.dart` — schedule editor UI (LIST-09)
- [ ] `test/domain/schedule/is_in_window_test.dart` — pure-Dart window evaluation (LIST-09 logic)
- [ ] `test/features/onboarding/welcome_screen_test.dart` — single-CTA welcome (ONBD-01)
- [ ] `test/features/onboarding/quick_add_screen_test.dart` — 5-card unchecked-by-default picker (ONBD-02, LIST-07)
- [ ] `test/features/onboarding/permission_funnel_test.dart` — 3-step ordered funnel (ONBD-03)
- [ ] `test/features/onboarding/permission_resume_detection_test.dart` — auto-advance on resumed (ONBD-05)
- [ ] `test/features/onboarding/oem_fallback_test.dart` — `Build.MANUFACTURER`-keyed reactive guidance (ONBD-04)
- [ ] `test/features/onboarding/prominent_disclosure_test.dart` — copy parity with `docs/play-declaration.md` (PLAY-06)
- [ ] `test/features/health/permission_health_provider_test.dart` — self-healing health check (REL-02, REL-03, ONBD-07)
- [ ] `test/features/home/health_banner_test.dart` — banner copy "Tracking is offline — tap to fix"
- [ ] `test/features/home/home_screen_unified_list_test.dart` — Apps + Habits unified list sorted by recent activity (LIST-06)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| OEM ComponentName fallback resolves on real Xiaomi/Samsung device | ONBD-04 | ROM-version-dependent; emulators do not reproduce vendor Settings apps | Install on real device, run permission funnel, verify each fallback intent either resolves OR falls through cleanly to dontkillmyapp.com link |
| `Build.FINGERPRINT` change re-verification on OS update | ONBD-07 | Cannot synthesize an OS update in tests | Manual smoke after next OTA — open app, verify health-check banner re-appears if any permission was silently revoked |

---

## Validation Sign-Off

- [ ] All Phase 2 tasks have `<automated>` verify command OR are listed under Manual-Only above
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all 16 test files listed above
- [ ] No `flutter test --watch` or watch-mode flags in plans
- [ ] Feedback latency < 60 s for the quick command
- [ ] `nyquist_compliant: true` set in frontmatter once planner fills the per-task map

**Approval:** pending — planner fills per-task map, then verifier flips `nyquist_compliant: true`.
