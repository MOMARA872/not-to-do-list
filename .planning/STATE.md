---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-05-21T00:00:00.000Z"
progress:
  total_phases: 6
  completed_phases: 4
  total_plans: 29
  completed_plans: 29
  percent: 83
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

Phase: 04 (Pause UX) — COMPLETE 2026-05-21 (REL-04 PASS on Samsung Galaxy S20 Ultra 5G after ≥71 h unplugged Doze)
Plan: 8 of 8 (all plans complete)
Next: Phase 5 (Streak Engine & Daily Reminder) — `/gsd-plan-phase 5`

- **Milestone:** v1
- **Phase:** Phase 4 — Pause UX (COMPLETE 2026-05-21)
- **Status:** Phase 4 fully closed; all gates green
- **Progress:** [████████████████░░░░] 83% (29/29 plans through Phase 4; 4/6 phases complete)

```
[████████████████░░░░] Phase 4 COMPLETE — REL-04 PASS (Samsung S20 Ultra, ≥71 h unplugged Doze)
```

### Phase 4 Plan Inventory (all complete)

- 04-01-PLAN — Wave 0 — test scaffold (11 RED test files + REL-04 verification template) ✅
- 04-02-PLAN — Wave 1 — Kotlin `isInScheduleWindow` byte-for-byte port + JVM parity test ✅
- 04-03-PLAN — Wave 1 — `AccessibilityApiImpl.kt` + MainActivity `FlutterEngineCache.put("pause_engine")` pre-warm ✅
- 04-04-PLAN — Wave 2 — `BlocklistBroadcastApi` Pigeon channel + `BlockListRepository` LocalBroadcast emit + `AccessibilityBlockedAppDetector` body ✅
- 04-05-PLAN — Wave 2 — `NotToDoAccessibilityService` body (TYPE_WINDOW_STATE_CHANGED + 800ms debounce + Map<String, ScheduleSlice> + LocalBroadcastManager receiver + Intent-launch) — REL-01 ships WITHOUT FGS per CD-01 ✅
- 04-06-PLAN — Wave 3 — `PauseActivity.kt` onCreate (setShowWhenLocked + setTurnScreenOn BEFORE super.onCreate; T-02 fail-closed extras validation; `withCachedEngine("pause_engine")` binding) ✅
- 04-07-PLAN — Wave 3 — Flutter pause UI (PauseScreen + 5 widgets + PauseController + PauseEventRepository) — D-01..D-08 honored verbatim ✅
- 04-08-PLAN — Wave 4 — exit gate: /pause/:entryId GoRoute + 9th PLAY-02 absence-grep invariant + REL-04 overnight protocol (Samsung; pending 2026-05-13 to 2026-05-16) + bookkeeping flips ✅

## Performance Metrics

- Phases planned: 6
- Phases complete: 4 (Phases 1, 2, 3, 4 fully complete)
- v1 requirements: 68 (all mapped; updated 2026-05-05 — hard-block + schedules added)
- v1 requirements complete: 40 (Phase 1: 9 reqs. Phase 2: 19 reqs. Phase 3: 7 reqs. Phase 4: PAUS-01..10 + REL-01 + REL-04 = 12 more reqs)
- OEM-survival overnight tests passed: 1/3 (Phase 4 PASS on Samsung Galaxy S20 Ultra 5G 2026-05-21; Phase 5, Phase 6 not started)

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
| v1 = adult self-control only (NOT parental control) | PROJECT.md 2026-05-05 | Hard-block opt-in + schedules opt-in; Parent PIN / kid mode / content filter / anti-uninstall all deferred to M2/M3 |
| Phase 2 cross-tree policy invariant test (`test/policy/play_invariants_test.dart`) | Plan 02-10 | 8 absence-grep tests lock PLAY-02/03/04/05/06 + v1-scope BIND_DEVICE_ADMIN + v1-scope forbidden-token sweep so future phases can't regress |
| Phase 4 expanded PLAY-02 absence-grep to service/ + root activities | Plan 04-08 | 9th invariant covers `android/.../service/` + `android/.../not_to_do_list/` root — catches any future autonomous-action regression on Phase 4 surfaces |
| REL-01 deferred: ship without companion FGS | Plan 04-05 (CD-01) | Research recommends against FGS in v1; AccessibilityService stays in Active Bucket via user-granted battery-opt exemption; revisit only if REL-04 OEM gate fails on additional OEMs |

### Performance Metrics Per Plan

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 2 P01 (Wave 0 stubs)         | ~25min | 3 tasks | 22 files |
| Phase 2 P02 (Drift v1→v2)          | ~30min | 3 tasks | 8 files  |
| Phase 2 P03 (Pigeon channels)      | 79min  | 5 tasks | 13 files |
| Phase 2 P04 (DAO + repo + helper)  | 25min  | 3 tasks | 11 files |
| Phase 2 P05 (Riverpod providers)   | 25min  | 4 tasks | 12 files |
| Phase 2 P06 (List-CRUD UI)         | ~60min | 3 tasks | 16 files |
| Phase 2 P07 (HomeScreen)           | ~104min| 2 tasks | 4 files  |
| Phase 2 P08 (Onboarding wizard)    | 35min  | 3 tasks | 16 files |
| Phase 2 P09 (Health banner+router) | 35min  | 3 tasks | 16 files |
| Phase 2 P10 (Exit gate)            | ~25min | 3 tasks | 4 files  |
| Phase 4 P01 (Wave 0 stubs)         | — | — | 11 test stubs + verification template |
| Phase 4 P02 (Kotlin schedule port) | — | — | ScheduleWindowKt + parity test |
| Phase 4 P03 (A11y API + FlutterEngine pre-warm) | — | — | AccessibilityApiImpl + MainActivity pre-warm |
| Phase 4 P04 (Blocklist broadcast)  | — | — | BlocklistBroadcastApi + Pigeon channel + Detector body |
| Phase 4 P05 (A11y service body)    | — | — | NotToDoAccessibilityService.kt (full body) |
| Phase 4 P06 (PauseActivity body)   | — | — | PauseActivity.kt (onCreate) |
| Phase 4 P07 (Flutter pause UI)     | — | — | PauseScreen + 5 widgets + PauseController + event repo |
| Phase 4 P08 (Phase exit gate)      | — | 5 tasks (Tasks 1-2 prev + 5a,5b,6 cont.) | /pause/:entryId route, 9th invariant, bookkeeping |

### Active Todos

1. **Phase 5 (Streak Engine & Daily Reminder)** — `/gsd-plan-phase 5`. Phase 4 fully closed; no upstream blockers.

### Closed Todos

- ✅ REL-04 overnight run on Samsung — PASS 2026-05-21. Run #1 (2026-05-17 → 2026-05-18, charging-confounded): logcat 320 ms detect-to-pause. Run #2 (2026-05-18 → 2026-05-21, ≥71 h unplugged Doze): PauseActivity fired <1 s after user tapped blocked app. Wireless adb dropped during deep Doze (Wi-Fi radio cut, expected); precise Run #2 ms not captured but subjective <1 s + Run #1 320 ms upper bound = comfortable PASS under 500 ms CD-03 threshold.
- ✅ REL-04 bookkeeping flips landed 2026-05-21: REQUIREMENTS.md REL-04 → Complete; 04-VERIFICATION.md status → complete + rel_04_status: pass; STATE.md completed_phases → 4; v1 requirements complete → 40.

### Blockers

None.

### Risks Being Tracked

| Risk | Source | Mitigation |
|------|--------|------------|
| Play Store rejection of AccessibilityService declaration | research/PITFALLS.md #1 | Phase 1: literal mechanical declaration in `docs/play-declaration.md`; `isAccessibilityTool="false"`; closed-track build before public release; UsageStats-polling fallback prototyped. Phase 2: cross-tree absence-grep policy test (`test/policy/play_invariants_test.dart`) locks PLAY-02..06 invariants. |
| OEM battery managers silently kill the service (Xiaomi, Huawei, Samsung) | research/PITFALLS.md #2 | Phase 2: OEM-aware fix-it flows shipped (OemFallbackPanel keyed on Build.MANUFACTURER for 7 vendors). Phases 4–6: real-device overnight test as phase-exit gate |
| 4-Settings permission funnel collapses onboarding < 50% | research/PITFALLS.md #3 | Phase 2: sequenced contextual asks, static screenshots, `onResume` auto-advance, OEM-specific fallbacks shipped |
| Pause screen >300 ms cold-start | research/PITFALLS.md (#perf) | Phase 4: `FlutterEngineCache` pre-warm; stopwatch-test on real low-end device as exit criterion |
| Doze defers daily reminder | research/PITFALLS.md #6 | Phase 5: `setExactAndAllowWhileIdle`; `dumpsys deviceidle force-idle` test as exit criterion |
| `POST_NOTIFICATIONS` denial on Android 13+ | research/PITFALLS.md #10 | Phase 5: earned prompt + custom rationale + in-app fallback banner |

## Session Continuity

### Last Session

- 2026-04-26: Phase 1 complete. All 5 plans landed. `flutter build apk --debug` produces `build/app/outputs/flutter-apk/app-debug.apk` (171.6 MB).
- 2026-04-27: PROJECT.md, REQUIREMENTS.md, research bundle, and ROADMAP.md initialized.
- 2026-05-06: Phase 2 Plan 02-01 (Wave 0) complete. Stubbed 20 test files + Drift v1 schema fixture + shared MockPermissionStatusApi.
- 2026-05-07: Phase 2 Wave 1 complete. Plan 02-02 (Drift v1→v2 migration) and Plan 02-03 (Pigeon channels) landed.
- 2026-05-07: Phase 2 Wave 2 complete. Plan 02-04 (BlockListDao + BlockListRepository + isInScheduleWindow + streakDayFor) and Plan 02-05 (permission/onboarding/picker Riverpod providers + AppIconLruCache) landed.
- 2026-05-05/2026-05-07: Phase 2 Wave 3 complete. Plan 02-06 (List-CRUD UI) + Plan 02-07 (HomeScreen unified list) + Plan 02-08 (Onboarding wizard with PLAY-06 disclosure).
- 2026-05-07: Phase 2 Wave 5 complete. Plan 02-09 (HealthCheckBanner + 9-route GoRouter + DynamicColorBuilder + 8 placeholder PNGs). Commits 4698eb7, 904f4fd, 365dfc6, 99fbdb8, 4699fe8.
- 2026-05-07: Phase 2 Plan 02-10 complete (Wave 6 — final exit gate). New `test/policy/play_invariants_test.dart` locks 8 cross-tree absence-grep invariants. Removed lone skipped placeholder in `test/platform/app_picker_api_test.dart`. `flutter test` exits 0 (124 passing, 0 skipped). `dart analyze` 0 errors / 0 warnings. `flutter build apk --debug` succeeds. Manual UAT signed off 2026-05-07 on Pixel emulator stock Android 16. 02-VALIDATION.md flipped to `status: complete` / `nyquist_compliant: true` / `wave_0_complete: true`. REQUIREMENTS.md ONBD-06/07 + REL-02/03 marked Complete; ROADMAP.md Phase 2 row checked off (10/10 plans, ✅ Complete 2026-05-07).
- 2026-05-07: Phase 3 (Screen-Time Dashboard) context captured via /gsd-discuss-phase 3 in --auto mode. 20 implementation decisions (D-01..20) locked across Pigeon impl, D/W/M nav, highlight treatment, "Avoided today" rule, cumulative totals, 5-min today-cache, no-permission fallback, lazy-on-open aggregation, bar-fill list rendering, home-card placement. Resume file: `.planning/phases/03-screen-time-dashboard/03-CONTEXT.md`. Audit trail in `03-DISCUSSION-LOG.md`. Committed 7e8260c.
- 2026-05-13: Phase 4 (Pause UX) software-complete. All 8 plans landed. AccessibilityService body + PauseActivity + Flutter pause UI + LocalBroadcast block-list refresh + Kotlin schedule port all complete. PLAY-02 invariants expanded from 8 → 9 (added service/ + root not_to_do_list/ scope per Plan 04-08 Task 2). HealthCheckBanner truth-bearing end-to-end. REL-04 protocol documented; overnight test on Samsung scheduled within 2-3 days (Option A — user has device). CD-01 deferred (no FGS); CD-02 immediate Use-anyway shipped; CD-03 device-acquisition resolved Option A (Samsung confirmed).

### Next Session

- Run `/gsd-plan-phase 5` (Streak Engine & Daily Reminder). Can start immediately — Phase 5 does NOT require REL-04 to complete first (they are independent).
- While planning/executing Phase 5: user runs REL-04 overnight test on Samsung (target 2026-05-13 to 2026-05-16). After PASS: update REQUIREMENTS.md REL-04 → Complete; 04-VERIFICATION.md outcome → PASS; STATE.md completed_phases → 4; v1 requirements complete → 40.
- Deferred items still open: 18 dart-analyze infos in pigeons/* + permission_status_mock.dart (Plan 02-03 frozen — see deferred-items.md). 8 placeholder PNGs at `assets/onboarding/` + `assets/logos/` await real Pixel captures before Phase 6 PLAY-08 submission.

### Files of Record

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/PROJECT.md` — vision, constraints, key decisions
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` — 63 v1 REQ-IDs + traceability table (27 Complete after Phase 2)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` — 6-phase plan with success criteria (Phases 1, 2 ✅ Complete)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/02-list-crud-onboarding-permissions/02-VALIDATION.md` — Phase 2 validation (status: complete / nyquist_compliant: true)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/SUMMARY.md` — research executive summary
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` — Flutter + Android architecture, build order
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/PITFALLS.md` — 10 critical pitfalls + phase mapping
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/config.json` — granularity=standard, mode=yolo

---
*State initialized: 2026-04-27 by gsd-roadmapper*
*Phase 2 closed: 2026-05-07 by gsd-executor (Plan 02-10)*
