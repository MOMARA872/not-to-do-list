---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-05-07T00:49:27.732Z"
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 15
  completed_plans: 12
  percent: 80
---

# Project State: Not To-Do List

**Initialized:** 2026-04-27
**Last updated:** 2026-05-07

## Project Reference

- **Core Value:** When a user opens an app on their not-to-do list, the pause screen + cooldown timer creates a deliberate moment of reflection that helps them choose deliberately — and the streak counter rewards every day they succeed.
- **Wedge:** Phase 4 (Pause UX) — user-defined avoidance + reason-aware soft-block + cooldown timer.
- **Stack:** Flutter 3.41 + Dart 3.x, Riverpod 3.3, Drift 2.32, Pigeon-typed Kotlin channels, Android-only (minSdk 29 / targetSdk 36), 100% on-device.
- **Timeline:** 6–12 weeks to v1, solo full-time.

## Current Position

Phase: 02 (list-crud-onboarding-permissions) — EXECUTING
Plan: 4 of 10 next (Plans 02-01, 02-02, 02-03 ✅ complete; Wave 0 + Wave 1 schema/channels landed)

- **Milestone:** v1
- **Phase:** Phase 1 — Foundation & Play Declaration (✅ COMPLETE)
- **Plan:** Phase 2 Plan 02-03 complete — Pigeon `AppPickerApi` (3 @async methods) and `PermissionStatusApi` (8 @async methods) channels defined + Kotlin HostApi impls landed; `MainActivity` registers both new channels alongside Phase 1's three; `AccessibilityApi.openAccessibilitySettings` no-op stub replaced with real `resolveActivity`-guarded launch (d5ef5e3, e2cbdd8, 6d353b1, 06d9e5b, fea309b). Plan 02-02 also landed in parallel (Drift v1→v2 migration: `block_mode` + 3 schedule columns, 254a4af, 7a84d47, 500f15e). Wave 1 closed.
- **Status:** Executing Phase 02
- **Progress:** [██████░░░░] 60%

```
[██████████░░░░░░░░░░] 53%
```

## Performance Metrics

- Phases planned: 6
- Phases complete: 1
- v1 requirements: 63 (all mapped)
- v1 requirements complete: 8 (PLAY-01, PLAY-02, PLAY-03, PLAY-04, PLAY-05, PLAY-07, PLAY-09, SETT-03 — Phase 1 closed; REL-05 abstraction shipped, full satisfaction in Phase 4)
- OEM-survival overnight tests passed: 0/3 (Phase 4, Phase 5, Phase 6)

## Accumulated Context

### Key Decisions (from PROJECT.md + research)

| Decision | Source | Rationale |
|----------|--------|-----------|
| Android-only for v1 | PROJECT.md | Avoid Apple $99/yr + Family Controls entitlement; ship faster |
| Flutter (not RN, not native) | PROJECT.md | Reusable UI for future iOS port; native channels for platform APIs |
| No backend in v1 | PROJECT.md | Privacy + zero sign-up friction; aligns with free/OSS budget |
| Pause UI is FlutterActivity, NOT `SYSTEM_ALERT_WINDOW` | research/ARCHITECTURE.md | Play policy + Android 12+ overlay restrictions + flutter_overlay_window hosting complexity |
| AccessibilityService is a passive trigger; DB is source of truth | research/ARCHITECTURE.md | Sidesteps flutter#76988 background-isolate-EventChannel footgun; service can die without losing state |
| Pigeon-typed channels for all Dart↔Kotlin calls | research/ARCHITECTURE.md | Catches type mismatches at build time; eliminates `MissingPluginException` class of bugs |
| AlarmManager for user-perceived precise time; WorkManager for Doze-tolerant rollover | research/ARCHITECTURE.md | Canonical split — never both for the same job |
| `isAccessibilityTool="false"` | research/PITFALLS.md (#1) | We are NOT assistive tech; required for Play declaration to pass |
| Streak roll-over lazy-evaluated on every app open | research/PITFALLS.md (#6) | Robust against Doze, reboots, offline; "fire at 00:00" is fragile |
| AccessibilityService swappable behind Riverpod abstraction | research/PITFALLS.md (#1) | UsageStats-polling fallback ships without rework if Play rejects the service |
| Earned `POST_NOTIFICATIONS` prompt (after first not-to-do added) | research/PITFALLS.md (#10) | Roughly doubles allow rates vs first-launch prompt |
| Phase 2 P04 | 25min | 3 tasks | 11 files |
| Phase 2 P08 (Onboarding wizard) | 35min | 3 tasks | 16 files (10 created + 6 modified) |

### Active Todos

None — awaiting `/gsd-plan-phase 1`.

### Blockers

None.

### Risks Being Tracked

| Risk | Source | Mitigation |
|------|--------|------------|
| Play Store rejection of AccessibilityService declaration | research/PITFALLS.md #1 | Phase 1: literal mechanical declaration in `docs/play-declaration.md`; `isAccessibilityTool="false"`; closed-track build before public release; UsageStats-polling fallback prototyped |
| OEM battery managers silently kill the service (Xiaomi, Huawei, Samsung) | research/PITFALLS.md #2 | Phase 2: OEM-aware fix-it flows; Phases 4–6: real-device overnight test as phase-exit gate |
| 4-Settings permission funnel collapses onboarding < 50% | research/PITFALLS.md #3 | Phase 2: sequenced contextual asks, animated GIFs, `onResume` auto-advance, OEM-specific fallbacks |
| Pause screen >300 ms cold-start | research/PITFALLS.md (#perf) | Phase 4: `FlutterEngineCache` pre-warm; stopwatch-test on real low-end device as exit criterion |
| Doze defers daily reminder | research/PITFALLS.md #6 | Phase 5: `setExactAndAllowWhileIdle`; `dumpsys deviceidle force-idle` test as exit criterion |
| `POST_NOTIFICATIONS` denial on Android 13+ | research/PITFALLS.md #10 | Phase 5: earned prompt + custom rationale + in-app fallback banner |

## Session Continuity

### Last Session

- 2026-04-26: Phase 1 complete. All 5 plans (01-01 toolchain, 01-02 manifest+a11y+Play docs, 01-03 Drift schema, 01-04 Pigeon stubs+BlockedAppDetector, 01-05 empty home scaffold + V1-V14 phase exit gate) landed. `flutter build apk --debug` produces `build/app/outputs/flutter-apk/app-debug.apk` (171.6 MB).
- 2026-04-27: PROJECT.md, REQUIREMENTS.md, research bundle, and ROADMAP.md initialized.
- 2026-05-06: Phase 2 Plan 02-01 (Wave 0) complete. Stubbed 20 test files (16 from VALIDATION.md + 4 from PATTERNS.md File Inventory), captured Drift v1 schema fixture at `drift_schemas/drift_schema_v1.json` (8 columns, no v2 cols), and added shared `MockPermissionStatusApi` fixture at `test/_fixtures/permission_status_mock.dart`. `flutter test` passes (+6 ~32). Test surface for Phase 2 is locked.
- 2026-05-07: Phase 2 Wave 1 complete. Plan 02-02 (Drift v1→v2 migration: `block_mode` text + 3 nullable schedule columns; addColumn migration; PRAGMA foreign_keys=ON; cascade-delete tests; 254a4af, 7a84d47, 500f15e) and Plan 02-03 (Pigeon `AppPickerApi` + `PermissionStatusApi` channels with Kotlin HostApi impls; `MainActivity` registers both new channels; `AccessibilityApi.openAccessibilitySettings` real launch with `resolveActivity` guard; d5ef5e3, e2cbdd8, 6d353b1, 06d9e5b, fea309b) landed in parallel. `flutter build apk --debug` succeeds; `flutter test` exits 0 (+11 ~30).
- 2026-05-05: Phase 2 Plan 02-08 complete (Wave 3) — Onboarding wizard: WelcomeScreen + QuickAddScreen (5 unchecked-by-default cards) + 3-step permission funnel (Usage Access → Accessibility[PLAY-06] → Battery-opt) with WidgetsBindingObserver onResume auto-advance + reactive OemFallbackPanel for {xiaomi/huawei/samsung/oppo/realme/vivo/oneplus}. PLAY-06 disclosure carries the 5 verbatim phrases enforced by source-grep test. BatteryOpt terminator persists fingerprint baseline + marks complete on grant OR skip. Commits 74ccb2f, 59f290c, 7c6ca3b. `flutter test` exits 0 (89 passing).
- 2026-05-07: Phase 2 Plan 02-06 complete (Wave 3 — list CRUD + theme) — AppTheme seeded with `Color(0xFF2D6A4F)` for both light/dark, ready for 02-09's DynamicColorBuilder wiring; `dynamic_color` + `url_launcher` deps added; `assets/onboarding/` + `assets/logos/` declared. Three list-CRUD surfaces shipped: AddAppPickerScreen (search-first, 150ms debounce on display name only, already-blocked greyed-out, "Show all" toggle, recently-used gated on `isUsageAccessGranted()`); AddHabitScreen (kind=1, packageName=null, 500-char counter visible at length≥400); EditEntryScreen (kind-aware app-bar; Soft/Hard segmented hidden for habits per LIST-08; ScheduleEditor with atomic null/non-null trio, cross-midnight + 04:00 streak annotations; bottom-of-page destructive Delete with NO AlertDialog per Surface 10). Sub-widgets: AppIcon, BlockModeSegmented, ScheduleEditor; controllers: AppPickerController (debounce + show-all toggle), EditEntryController (AsyncNotifier-family hydrating from blockListRepoProvider). Commits 8b8e537, 2bc7809, 1d083eb, de5a907. Tests: +18 widget tests (4 picker + 4 search + 5 edit-screen + 6 schedule-editor); `flutter test` exits 0 (100 passing, 3 sibling-plan stubs).

### Next Session

- Execute Wave 2 plans (02-04, 02-05): DAO + repository wiring, `BlockListRepository`, schedule-window helpers, Riverpod providers (`appPickerApiProvider`, `permissionStatusApiProvider`, `blockListRepoProvider`).
- Phase 2 is the first phase where the home screen subscribes to `blockedAppDetectorProvider` (RESEARCH §6 Open Question #2 unblocks here).
- First real-device overnight test is still the Phase 4 exit gate — Phase 2/3 stay simulator-friendly.

### Files of Record

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/PROJECT.md` — vision, constraints, key decisions
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` — 63 v1 REQ-IDs + traceability table
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` — 6-phase plan with success criteria
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/SUMMARY.md` — research executive summary
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` — Flutter + Android architecture, build order
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/PITFALLS.md` — 10 critical pitfalls + phase mapping
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/config.json` — granularity=standard, mode=yolo

---
*State initialized: 2026-04-27 by gsd-roadmapper*
