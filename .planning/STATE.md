---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-05-07T02:31:42.783Z"
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 15
  completed_plans: 13
  percent: 87
---

# Project State: Not To-Do List

**Initialized:** 2026-04-27
**Last updated:** 2026-05-05

## Project Reference

- **Core Value:** When a user opens an app on their not-to-do list, the pause screen + cooldown timer creates a deliberate moment of reflection that helps them choose deliberately — and the streak counter rewards every day they succeed.
- **Wedge:** Phase 4 (Pause UX) — user-defined avoidance + reason-aware soft-block + cooldown timer.
- **Stack:** Flutter 3.41 + Dart 3.x, Riverpod 3.3, Drift 2.32, Pigeon-typed Kotlin channels, Android-only (minSdk 29 / targetSdk 36), 100% on-device.
- **Timeline:** 6–12 weeks to v1, solo full-time.

## Current Position

Phase: 02 (list-crud-onboarding-permissions) — EXECUTING
Plan: 02-09 next (Wave 5 — router rewire + DynamicColorBuilder + HealthCheckBanner). Wave 4 closed: 02-07 HomeScreen + 02-08 onboarding wizard + 02-06 list-CRUD UI all green.

- **Milestone:** v1
- **Phase:** Phase 1 — Foundation & Play Declaration (✅ COMPLETE)
- **Plan:** Phase 2 Plan 02-07 complete — HomeScreen Surface 4 (unified Apps + Habits ListView via private autoDispose StreamProvider over `blockListRepoProvider.watchAll()`) + 64 dp `BlockListRow` (AppIcon for apps, `Icons.spa_outlined` for habits, em-dash trailing streak placeholder, no swipe / no long-press) + Surface 12 `EmptyHomeState` with locked verbatim copy ("Nothing on your list yet." + "Add an app or habit you want to avoid to get started.") + two `FloatingActionButton.extended` (`+ Add habit` surface/primary, `+ Add app` primary/onPrimary). Phase 1 `EmptyHomeScreen` preserved byte-identical (no orphan deletes). 10 widget tests pass; full project suite stays green at 110 passing, 2 sibling-stub skipped. Commits 63c3218, 6d93b65.
- **Status:** Executing Phase 02
- **Progress:** [█████████░] 87%

```
[██████████████████░░] 93%
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
| Phase 2 P07 | 104 | 2 tasks | 4 files |

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
- 2026-05-05: Phase 2 Plan 02-07 complete (Wave 4 — HomeScreen unified list) — Surface 4 ships: `HomeScreen` `ConsumerWidget` consuming `blockListRepoProvider.watchAll()` via a private autoDispose `StreamProvider<List<BlockListData>>`; `BlockListRow` 64 dp ListTile (AppIcon for kind=0+packageName!=null, `Icons.spa_outlined` for kind=1; em-dash trailing streak placeholder for Phase 5; tap routes to `/list/edit/{id}`; no swipe / no long-press); `EmptyHomeState` Surface 12 with locked verbatim copy; two `FloatingActionButton.extended` (`+ Add habit` surface/primary, `+ Add app` primary/onPrimary) routing to `/list/add-habit` / `/list/add-app`. Auto-fixed deviations: comment grep collision in row file; 80-char lint in empty-state; `StreamBuilder` swapped for autoDispose `StreamProvider` to fix Drift's pending-timer leak in widget tests; `tester.runAsync` for the 1.1 s sort-test gaps; explicit `StreamProvider<…>` type to satisfy `specify_nonobvious_property_types`; `drainStreamTimers(tester)` helper drains Drift's `markAsClosed` microtask between tests. Phase 1 `EmptyHomeScreen` preserved byte-identical (Karpathy §3). Commits 63c3218, 6d93b65. Tests: +10 widget tests in `home_screen_unified_list_test.dart`; `flutter test` exits 0 (110 passing, 2 sibling-stub skipped); `dart analyze lib/features/home/ test/features/home/` clean.

### Next Session

- Execute Plan 02-09 (Wave 5): rewire `app_router.dart` to point `/` at `HomeScreen` + register `/list/add-app`, `/list/add-habit`, `/list/edit/:id`; mount the `HealthCheckBanner` (Surface 11) — 02-07 SUMMARY documents two integration shapes (ShellRoute vs HomeScreen.body Column rewrite); wire `DynamicColorBuilder` into `AppTheme.light()` / `dark()` (the optional named arg already lands a harmonised scheme).
- Plan 02-10 (Wave 5/6): final DI/main wiring + onboarding-completion gating router redirects, plus Phase 2 exit-gate harness.
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
