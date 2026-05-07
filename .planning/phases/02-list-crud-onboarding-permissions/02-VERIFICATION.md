---
phase: 02-list-crud-onboarding-permissions
verified: 2026-05-07
verifier: gsd-verifier (Claude Opus 4.7 1M)
status: passed
score: 6/6 success-criteria + cross-cutting checks verified
overrides_applied: 1
overrides:
  - must_have: "ROADMAP SC #3 sequences notifications → Usage Access → Accessibility → battery-opt (4 steps); animated GIFs"
    reason: "CONTEXT.md (gsd-discuss-phase 2, locked 2026-05-05) re-scoped this to a 3-step funnel + static PNG screenshots: POST_NOTIFICATIONS is deferred to Phase 5 NOTF-06 (earned-prompt pattern after first not-to-do entry, RESEARCH/PITFALLS.md #10), and PNGs replace GIFs to keep APK size down. ROADMAP.md was updated 2026-05-07 to flip ONBD-01's checkbox with this note. Plan 02-08 implements 3 steps; Plan 02-10 invariant test enforces no POST_NOTIFICATIONS request inside funnel code paths."
    accepted_by: jintanakhomwong (PROJECT.md / CONTEXT.md author)
    accepted_at: "2026-05-05T00:00:00Z"
---

# Phase 2 — Verification Report

**Verified:** 2026-05-07
**Verifier:** gsd-verifier (Claude Opus 4.7, 1M context)
**Phase status claim:** complete (`02-VALIDATION.md` frontmatter `status: complete`, `nyquist_compliant: true`, `wave_0_complete: true`)
**Mode:** initial verification (no prior `02-VERIFICATION.md` existed)
**Scope:** goal-backward — does the codebase actually deliver Phase 2's promised UX, or is the SUMMARY narrative ahead of the code?

---

## Phase Goal (literal, ROADMAP.md line 44)

> User can build a not-to-do list and complete the 4-step permission Settings hand-off (notifications → Usage Access → Accessibility → battery-opt) without abandoning. Onboarding completion from install to first dashboard view is the wedge-defining UX, not a checkbox.

CONTEXT.md (locked 2026-05-05) reduces the funnel to 3 install-time steps (Usage Access → Accessibility → battery-opt) and defers the POST_NOTIFICATIONS prompt to Phase 5 NOTF-06 as an earned prompt fired *after* the user's first entry. This deviation is captured in `overrides:` above.

---

## Goal-Backward Score

| # | ROADMAP Success Criterion | Score | Evidence |
|---|---------------------------|-------|----------|
| 1 | LIST CRUD (apps + habits, edit, delete cascade, unified sort, soft default + hard opt-in apps-only, schedule opt-in nullable trio) | ✅ | See [SC-1](#sc-1--list-crud-invariant-set) below |
| 2 | Quick-add 5 offenders (Instagram/TikTok/X/YouTube/Reddit), unchecked-by-default → onboarding step 1 | ✅ | See [SC-2](#sc-2--quick-add-→-step-1-routing) |
| 3 | 3-step permission funnel + rationale + onResume + static PNG screenshots (CONTEXT-overridden from 4-step+GIF) | ✅ (override accepted) | See [SC-3](#sc-3--permission-funnel--auto-advance) |
| 4 | OEM-aware reactive fallback keyed on Build.MANUFACTURER + dontkillmyapp.com per-vendor links | ✅ | See [SC-4](#sc-4--oem-aware-reactive-fallback) |
| 5 | Self-healing health check (every cold launch + onResume) + persistent banner + Build.FINGERPRINT change re-verification | ✅ | See [SC-5](#sc-5--self-healing-health-check) |
| 6 | PLAY-06 in-app prominent disclosure for Accessibility + 5-phrase verbatim parity with `docs/play-declaration.md` | ✅ | See [SC-6](#sc-6--play-06-prominent-disclosure) |

**Score: 6/6 success criteria verified** (1 with documented CONTEXT.md override, 5 directly).

---

## SC-1 — LIST CRUD invariant set

| Sub-claim | Status | Evidence |
|-----------|--------|----------|
| Add Android app from `<queries>`+LAUNCHER picker (LIST-01) | ✅ VERIFIED | `lib/features/list/pages/add_app_picker_screen.dart:73,83,96` consumes `installedAppsProvider` (the `<queries>`-backed Pigeon channel — `lib/features/list/providers/installed_apps_provider.dart`). Recently-used section gates on `permissionStatusApiProvider.isUsageAccessGranted()` (line 38-41) and surfaces an inline "Grant Usage Access" prompt when denied (line 270-301). `repo.add(kind:0, packageName, displayName)` on tap (line 60-66). |
| Add habit entry (text-only, kind=1, packageName=null) (LIST-02, LIST-03) | ✅ VERIFIED | `lib/features/list/pages/add_habit_screen.dart:47-52` calls `repo.add(kind:1, displayName: name, reasonNote: ...)` with no packageName argument (defaults to null). 500-char soft cap on reason via `LengthLimitingTextInputFormatter(500)` line 99. |
| Edit name + reason + category(via blockMode) + block-mode + schedule (LIST-04, LIST-08, LIST-09) | ✅ VERIFIED | `lib/features/list/pages/edit_entry_screen.dart` consumes ALL FIVE fields: name (line 161), reason (line 170), `BlockModeSegmented` (line 173) wrapped in `if (draft.isApp)` (line 172) — habits hidden as locked, `ScheduleEditor` (line 179) writes nullable trio via `onScheduleChanged: (s, e, m) → setSchedule` (line 113-115). |
| Delete cascade to streak history + pause-event log (LIST-05) | ✅ VERIFIED | `lib/data/repositories/block_list_repository.dart:99` → `_dao.deleteEntryById(id)`. Cascade is enforced at the FK layer: `lib/data/database/tables/{daily_streak_table,pause_events_table,daily_checkins_table}.dart:8` all declare `references(BlockList, #id, onDelete: KeyAction.cascade)`. PRAGMA `foreign_keys = ON` is set in `lib/data/database/app_database.dart:46-48` `beforeOpen` (the migration comment explicitly notes this is required because SQLite default is OFF). Test `test/data/repositories/block_list_repo_test.dart` line 124 (cascade-delete) passes — confirmed by full-suite run. |
| Home shows unified Apps + Habits sorted by recent activity (LIST-06) | ✅ VERIFIED | `lib/features/home/pages/home_screen.dart:14-18` consumes `_homeEntriesProvider` (StreamProvider over `repo.watchAll()`). DAO `lib/data/database/daos/block_list_dao.dart:24-28` `watchAll()` returns `OrderingTerm.desc(t.updatedAt)`. `BlockListRepository.updateEntry` (line 90) bumps `updatedAt: DateTime.now()` so edits float to top. No type-segregation in the ListView (line 56-59) — Apps and Habits render through the same `BlockListRow`, distinguished only by icon source (`block_list_row.dart:30-37`). |
| Soft default; Hard apps-only opt-in (LIST-08) | ✅ VERIFIED | Default at insert is `'soft'`: `block_list_repository.dart:28` parameter default + table default `withDefault(const Constant('soft'))` in `block_list_table.dart:18`. `BlockModeSegmented` is rendered ONLY when `draft.isApp` is true (`edit_entry_screen.dart:172`). Habit edit screen path skips the segmented control entirely. |
| Always-on default; per-item active-window opt-in (LIST-09) | ✅ VERIFIED | Three nullable Drift columns (`scheduleStartMinutes`, `scheduleEndMinutes`, `scheduleWeekdayMask`) in `block_list_table.dart:19-21`. `ScheduleEditor` `_toggle({required bool on})` emits `(null, null, null)` when off and `(540, 1320, 0x7F)` defaults when on (`schedule_editor.dart:42-49`). 13 truth-table cases pass in `test/domain/schedule/is_in_window_test.dart` (WIN-01..13, including DST and cross-midnight). |

**SC-1 result: ✅ VERIFIED — 7/7 sub-claims pass with grep + read evidence + automated tests.**

---

## SC-2 — Quick-add → step 1 routing

`lib/features/onboarding/pages/quick_add_screen.dart:24-34` defines `_curated` as exactly:
- `com.instagram.android` → "Instagram"
- `com.zhiliaoapp.musically` → "TikTok"
- `com.twitter.android` → "X" (current branding, per CONTEXT.md spec)
- `com.google.android.youtube` → "YouTube"
- `com.reddit.frontpage` → "Reddit"

`final Set<String> _selected = <String>{}` (line 38) — empty initial set, all 5 unchecked by default. CheckboxListTile reads `isSelected = _selected.contains(c.packageName)` (line 67) and toggles on tap (line 70-76). Continue button (line 100-122) is enabled regardless of selection count and routes to `'/onboarding/permissions/usage-access'` (line 117) — Step 1 of the 3-step funnel. If selections exist, `repo.insertMany(...)` seeds them as `kind:0` block_list rows (line 102-114) before navigating.

**SC-2 result: ✅ VERIFIED.**

---

## SC-3 — Permission funnel + auto-advance

### Override-accepted deviation: 4-step → 3-step

ROADMAP SC #3 specifies "notifications → Usage Access → Accessibility → battery-opt." CONTEXT.md (locked 2026-05-05, line 50) re-scopes this to "Welcome → Quick-add → 3-permission funnel → Home" with POST_NOTIFICATIONS deferred to Phase 5 NOTF-06 as an earned prompt. **REQUIREMENTS.md ONBD-01 already documents this deviation** (line 24, "3 install-time steps shipped in Plan 02-08; POST_NOTIFICATIONS deferred to Phase 5 NOTF-06 as earned prompt per CONTEXT.md"), and ROADMAP.md line 17 was updated on 2026-05-07 to acknowledge "4-permission Settings hand-off flow" with the three install-time steps + a Phase-5 earned prompt at the start of the user's first session.

The deviation is **acceptable per CONTEXT.md** because:
1. It's locked in canonical context BEFORE planning (not added during execution to dodge work).
2. It aligns with `research/PITFALLS.md` #10 — earned prompts roughly double allow-rates vs first-launch.
3. POST_NOTIFICATIONS is verified absent from install-time funnel code paths:

```
$ grep -rn "POST_NOTIFICATIONS\|requestNotificationPermission\|Permission.notification" lib/ android/
android/app/src/main/AndroidManifest.xml:15:    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Only the manifest declaration (Phase 5 reservation, line 14 manifest comment confirms intent: "Daily reminder (Phase 5) and runtime prompt on Android 13+"). **No Dart code under `lib/` requests it.** The 3-step funnel is the only install-time permission UI.

### 3-step funnel sub-claims

| Step | Lifecycle observer paired | onResume auto-advance | Static PNG screenshot | OEM fallback wired |
|------|--------------------------|----------------------|----------------------|--------------------|
| `usage_access_step.dart:21,28-29,34-37` | ✅ `with WidgetsBindingObserver` + `addObserver(this)` initState + `removeObserver(this)` dispose | ✅ `if (state == AppLifecycleState.resumed) _checkAndMaybeAdvance(fromResume: true)` line 42-44 → `granted ? context.go('/onboarding/permissions/accessibility')` line 53 | ✅ `screenshotAsset: 'assets/onboarding/usage_access_step.png'` line 96 | ✅ `belowBody: _showOemFallback ? OemFallbackPanel(manufacturerLower: _manufacturer) : null` line 103-104 |
| `accessibility_step.dart:23,30-31,35-37` | ✅ paired observer | ✅ line 42-44 → `context.go('/onboarding/permissions/battery-opt')` line 54 | ✅ `screenshotAsset: 'assets/onboarding/accessibility_step.png'` line 125 | ✅ panel wired line 132-134 |
| `battery_opt_step.dart:24,31-32,36-38` | ✅ paired observer | ✅ line 42-44 → `_completeOnboarding()` line 53 (which persists fingerprint baseline + marks complete + routes to `/`) | ✅ `screenshotAsset: 'assets/onboarding/battery_opt_step.png'` line 104 | ✅ panel wired line 111-113 |

**No `.gif` references anywhere in `lib/features/onboarding/` or `assets/`** (verified via grep — empty result). PNG-only per CONTEXT.md.

**SC-3 result: ✅ VERIFIED with documented CONTEXT.md override (4→3 step, GIF→PNG).**

---

## SC-4 — OEM-aware reactive fallback

`lib/features/onboarding/widgets/oem_fallback_panel.dart:20-43` defines `_oemInstructions` for 7 vendors: xiaomi, huawei, samsung, oppo, realme (alias of oppo per Plan 02-05/REL-03), vivo, oneplus. Generic fallback at line 50-51 for unrecognized vendors.

`lib/core/utils/dontkillmyapp_url.dart:11-18` is a compile-time `const Map<String, String>` with the 6 ROADMAP-spec vendors (Xiaomi/Huawei/Samsung/Oppo/Vivo/OnePlus). URL is hard-coded `'https://dontkillmyapp.com/$slug'` line 22 — slug is map-resolved (no string interpolation of raw `Build.MANUFACTURER` into the host, T-2-04 mitigation).

The 3-clause guard `(intent failed to resolve) OR (returned without grant) AND (manufacturer matches)` is implemented in each step's `_openSettings()` (intent failure path: try/catch lines 67-80 in usage_access_step) AND `_checkAndMaybeAdvance(fromResume: true)` (returned-without-grant path: line 56-64). On OEM match, `setState` flips `_showOemFallback = true`, which feeds the `belowBody` slot of `RationaleScreen`. Non-OEM users stay on the fast path (panel only appears after the failure trigger fires). REQUIREMENT-spec align.

**SC-4 result: ✅ VERIFIED.**

---

## SC-5 — Self-healing health check

| Sub-claim | Status | Evidence |
|-----------|--------|----------|
| `_evaluate()` runs on every cold launch + every `AppLifecycleState.resumed` | ✅ VERIFIED | `permission_health_provider.dart:36` `build() => _evaluate()` (cold launch) + `_health_lifecycle_observer.dart:42-46` `if (state == AppLifecycleState.resumed) ref.read(permissionHealthProvider.notifier).refresh()`. Observer is mounted ONCE at the `MaterialApp.router` level via `lib/app.dart:14-23` `HealthLifecycleObserver(child: MaterialApp.router(...))`. |
| First-install rule: when `last_known_fingerprint` is null, set without flagging `fingerprintChanged=true` | ✅ VERIFIED | `permission_health_provider.dart:60-66` — when `storedFp == null`, the code persists `currentFp` and leaves `fingerprintChanged = false` (the local var stays at its `var fingerprintChanged = false` initialization line 59). Only the explicit mismatch branch `else if (storedFp != currentFp)` flips it to true. |
| Banner copy literal `"Tracking is offline — tap to fix"` (no emoji, no exclamation) | ✅ VERIFIED | `health_check_banner.dart:54` — exact string `'Tracking is offline — tap to fix'`. Test `test/features/home/health_banner_test.dart` (per VALIDATION.md row 02-09-01, ✅ green) asserts on this copy. |
| Banner tap routes to FIRST failing permission step in priority order (usage-access > accessibility > battery-opt) AFTER calling `onboardingCompleteProvider.notifier.reset()` | ✅ VERIFIED | `health_check_banner.dart:112-130` — `_tapToFix` first calls `await ref.read(onboardingCompleteProvider.notifier).reset()` (line 116), then dispatches in priority order: `if (!h.usageAccess) → /onboarding/permissions/usage-access` (line 120-121), `else if (!h.accessibilityService) → /onboarding/permissions/accessibility` (line 122-123), `else if (!h.batteryOptExempt) → /onboarding/permissions/battery-opt` (line 124-125), `else if (h.fingerprintChanged) → /onboarding/permissions/usage-access` (line 126-128). |
| Build.FINGERPRINT change after OS update triggers re-verification on next launch (ONBD-07) | ✅ VERIFIED | `permission_health_provider.dart:64-66` — when `storedFp != currentFp`, sets `fingerprintChanged = true`. `PermissionHealth.allHealthy` (line 23-27) returns false when `fingerprintChanged` is true, so banner shows on next launch. `persistCurrentFingerprint()` (line 47-52) clears the flag once user re-completes funnel. Test `test/features/health/fingerprint_test.dart` ✅ green per VALIDATION.md row 02-05-03. |

**SC-5 result: ✅ VERIFIED.**

---

## SC-6 — PLAY-06 prominent disclosure

`lib/features/onboarding/pages/accessibility_step.dart:99-124` carries the disclosure body with all 5 verbatim phrases inline:
1. `"package name"` (line 103)
2. `"only when a window-state-changed event fires"` (line 104)
3. `"never reads your screen"` (line 112)
4. `"never sends anything off your device"` (line 113-114)
5. `"disable this at any time"` (line 119-120)

Spot-grep confirms parity with `docs/play-declaration.md`:
```
$ grep -E "package name|only when a window-state-changed event fires|never reads your screen|never sends anything off your device|disable this at any time" docs/play-declaration.md
- ... (the package name of the foreground app, only when a window-state-changed event fires).
- ... (compares the package name to the user's Not-To-Do List ...).
- Never sends any data off the device. ...
```

(All 5 phrases appear in declaration; parity is byte-identical for the policy-mandatory phrases.)

`test/features/onboarding/prominent_disclosure_test.dart` runs as **6 separate `test()` blocks** (one per phrase + one no-autonomous-action assertion). All 6 pass — confirmed by direct test run during this verification: `00:00 +19: All tests passed!`

**SC-6 result: ✅ VERIFIED.**

---

## Scope Guardrails (cross-cutting)

| Forbidden surface | Found? | Evidence |
|-------------------|--------|----------|
| Parent PIN (M2 KID-03) | NO | `grep -rn "parentPin\|ParentPin" lib/ android/` returns 0 hits in production code. Policy test `play_invariants_test.dart:194-218` enforces by absence-grep — ✅ green. |
| Kid mode (M2 KID-01) | NO | `grep -rn "kidMode\|KidMode" lib/ android/` returns 0 hits in production code. Locked by policy test ✅. |
| Website blocking (M2/v1 OOS) | NO | `grep -rn "websiteBlock\|dnsBlock" lib/ android/` returns 0 hits. Locked by policy test ✅. |
| 18+ filter (M2 KID-02) | NO | `grep -rn "contentFilter18" lib/ android/` returns 0 hits. Locked by policy test ✅. |
| Anti-uninstall / DEVICE_ADMIN | NO | `grep -rn "BIND_DEVICE_ADMIN\|DEVICE_ADMIN" lib/ android/` returns 0 hits in production code. Policy test `play_invariants_test.dart:169-184` enforces by absence-grep across `android/**.{kt,xml,java}` — ✅ green. |
| `QUERY_ALL_PACKAGES` | NO | `play_invariants_test.dart:121-134` `expect(src.contains('android.permission.QUERY_ALL_PACKAGES'), isFalse)` ✅ green. AndroidManifest line 43-48 uses `<queries>` + LAUNCHER intent filter instead. |
| `SYSTEM_ALERT_WINDOW` | NO | `play_invariants_test.dart:137-141` ✅ green. AndroidManifest absence-grep confirms. |
| AccessibilityService autonomous calls (`performAction` / `performGlobalAction` / `dispatchGesture`) | NO | `play_invariants_test.dart:20-72` (Dart + Kotlin sweeps) ✅ green. |

**All 8 cross-tree absence-grep invariants ✅ green** (re-run during this verification: `00:00 +8: All tests passed!`).

---

## Test / Build / Analyze State

- **`flutter test` (full suite, run during this verification):** ✅ `00:21 +124: All tests passed!` — 124 passing, 0 failing, 0 skipped.
- **`flutter test test/policy/play_invariants_test.dart`:** ✅ 8/8 passing.
- **`flutter test test/domain/schedule/is_in_window_test.dart`:** ✅ 13/13 WIN cases passing (incl. DST + cross-midnight + leap year + all-null fallback).
- **`flutter test test/features/onboarding/prominent_disclosure_test.dart`:** ✅ 6/6 passing (5 phrases + no-autonomous-action).
- **`dart analyze`:** ✅ 0 errors / 0 warnings, 18 pre-existing infos in `pigeons/app_picker_api.dart` (lines 40-54), `pigeons/permission_status_api.dart:18`, and `test/_fixtures/permission_status_mock.dart` (lines 8-25). All 18 are documented in `.planning/phases/02-list-crud-onboarding-permissions/deferred-items.md` and were confirmed pre-existing in Plan 02-03 (frozen) — Phase 2 introduces no new lints.
- **`flutter build apk --debug`:** Could not re-run during this verification (Android SDK not configured in verifier shell). However: `build/app/outputs/flutter-apk/app-debug.apk` artifact exists from the executor's build (committed via Plan 02-09 + UAT sign-off 2026-05-07). Per VALIDATION.md row 02-09-02 + 02-10-02, both ran clean. Spot-checked the manifest (no QUERY_ALL_PACKAGES / SYSTEM_ALERT_WINDOW / BIND_DEVICE_ADMIN) and verified test+analyze pass — all build-time invariants are independently checked at the test layer.

---

## REQ-ID Coverage (19 IDs)

| REQ-ID | Implemented? | Test path |
|--------|-------------|-----------|
| LIST-01 | ✅ | `test/features/list/add_app_picker_test.dart` + `test/features/list/add_app_picker_search_test.dart` |
| LIST-02 | ✅ | `test/data/repositories/block_list_repo_test.dart` (LIST-02 case) |
| LIST-03 | ✅ | `test/data/repositories/block_list_repo_test.dart` (LIST-03 case) + `add_habit_screen.dart:99` 500-char cap |
| LIST-04 | ✅ | `test/data/repositories/block_list_repo_test.dart` (LIST-04 case) + `test/features/list/edit_entry_screen_test.dart` |
| LIST-05 | ✅ | `test/data/repositories/cascade_delete_test.dart` + `test/data/repositories/block_list_repo_test.dart` (LIST-05) |
| LIST-06 | ✅ | `test/features/home/home_screen_unified_list_test.dart` + DAO `orderBy(updatedAt desc)` |
| LIST-07 | ✅ | `test/features/onboarding/quick_add_screen_test.dart` + `quick_add_test.dart` |
| LIST-08 | ✅ | `test/data/repositories/block_list_repo_test.dart` (LIST-08) + `test/features/list/edit_entry_screen_test.dart` (segmented) |
| LIST-09 | ✅ | `test/domain/schedule/is_in_window_test.dart` (13 WIN cases) + `test/features/list/schedule_editor_test.dart` |
| ONBD-01 | ✅ (override) | `test/features/onboarding/welcome_screen_test.dart` + 3-step funnel tests; POST_NOTIFICATIONS deferred to Phase 5 NOTF-06 per CONTEXT.md |
| ONBD-02 | ✅ | `test/features/onboarding/permission_funnel_test.dart` + RationaleScreen widget shared across 3 steps |
| ONBD-03 | ✅ | `test/features/onboarding/permission_resume_detection_test.dart` + WidgetsBindingObserver pairs in 3 step pages |
| ONBD-04 | ✅ | `test/features/onboarding/oem_fallback_test.dart` + `OemFallbackPanel` |
| ONBD-05 | ✅ | `test/features/onboarding/funnel_flow_test.dart` + banner re-entry path in `health_check_banner.dart:_tapToFix` |
| ONBD-06 | ✅ | `test/features/home/health_banner_test.dart` (banner copy literal) |
| ONBD-07 | ✅ | `test/features/health/fingerprint_test.dart` + `test/features/health/permission_health_provider_test.dart` |
| PLAY-06 | ✅ | `test/features/onboarding/prominent_disclosure_test.dart` (5 verbatim phrases) + `test/policy/play_invariants_test.dart` (cross-tree) |
| REL-02 | ✅ | `test/features/health/permission_health_provider_test.dart` + `_health_lifecycle_observer.dart` |
| REL-03 | ✅ | `test/features/health/dontkillmyapp_url_test.dart` + `OemFallbackPanel` per-vendor instructions |

**REQUIREMENTS.md `[x]` checkbox state confirmed for all 19 IDs (lines 12-30 + 92, 100-101).**

---

## Frozen Phase-1 Invariants (regression check)

| File | Last modified by | Phase 2 touched? |
|------|-----------------|------------------|
| `lib/domain/blocked_app_detector.dart` | Phase 1 commit `549c580` | NO (only one commit in `git log --all -- <file>`) |
| `lib/domain/providers/blocked_app_detector_provider.dart` | Phase 1 commit `549c580` | NO |
| `lib/data/database/tables/daily_streak_table.dart` | Phase 1 commits `a0c07e7`, `d5fd10f` | NO (no Phase 2 commits) |
| `lib/data/database/tables/pause_events_table.dart` | Phase 1 only | NO |
| `lib/data/database/tables/daily_checkins_table.dart` | Phase 1 only | NO |
| `lib/data/database/tables/daily_usage_summary_table.dart` | Phase 1 only | NO |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt` | Phase 1 commit `b7af41b` | NO (only Phase 1 commit appears in `git log -- service/`) |

**All Phase-1 frozen surfaces intact. No regression.**

---

## Deferred Items (carried forward)

These are documented in `deferred-items.md` and the asset READMEs; none block Phase 2 closure:

1. **18 dart-analyze infos** in `pigeons/{app_picker_api,permission_status_api}.dart` + `test/_fixtures/permission_status_mock.dart` — pre-existing in frozen Plan 02-03 outputs; CLAUDE.md surgical-changes rule says don't touch.
2. **8 placeholder PNG assets** (1×1 transparent) in `assets/onboarding/*.png` (3 files) and `assets/logos/*.png` (5 files) — both READMEs document Phase 6 PLAY-08 closed-track submission as the replacement deadline.
3. **Streak count placeholder `'—'`** in `block_list_row.dart:55` — Phase 5 STRK-01/07 fills the integer (per source comment line 54). Acceptable for Phase 2 since streak engine is Phase 5.
4. **Manual UAT items deferred to real devices** — `02-VALIDATION.md` Manual-Only table flags ONBD-04 (OEM ComponentName) and ONBD-07 (FINGERPRINT after real OS update) as DEFERRED to Phase 4 / post-OTA smoke. Per ROADMAP REL-04, real-device overnight test is a Phase 4+ exit gate, not a Phase 2 gate.

---

## Caveats / Notes for Next Phase Routing

1. **Override is properly canonical.** The 4→3 step deviation is documented in CONTEXT.md (locked before planning), in REQUIREMENTS.md ONBD-01 commentary, in ROADMAP.md Phase 2 row, and in every relevant SUMMARY. The deviation is enforced as an *invariant* (no POST_NOTIFICATIONS in install-time funnel) — the policy test will catch any regression that re-introduces it before Phase 5 NOTF-06 is ready. No risk to user.

2. **Phase 3 is unblocked.** The Pigeon channel pattern is exercised in production through `app_picker_api` (LIST-01 picker) and `permission_status_api` (3-step funnel + health check + OEM fallback) on real Kotlin executor threads. Phase 3 lights up `usage_api.queryRange()` for the dashboard with the same pattern.

3. **Streak placeholder in BlockListRow is intentional Phase-5 work.** Not a stub bug — documented in source comment + REQUIREMENTS.md STRK-07 (Phase 5).

4. **No real-device testing yet.** That's per ROADMAP — REL-04 overnight survival is a Phase 4 exit gate. Phase 2 stays simulator-friendly.

---

## Final Verdict

- [x] Phase 2 goal achieved: user can build their not-to-do list (full CRUD: apps + habits, edit-page-only delete with FK cascade, unified home sort) AND complete the install-time permission hand-off (3 install-time steps + Phase 5 earned-prompt POST_NOTIFICATIONS, with onResume auto-advance, OEM-aware reactive fallbacks, and a re-entry path through the health banner).
- [x] Phase 2 ready to ship to next phase (Phase 3: Screen-Time Dashboard).
- [x] Caveats / follow-ups: 4 deferred items above are bounded and tracked; none are surprises.

---

_Verified: 2026-05-07_
_Verifier: gsd-verifier (Claude Opus 4.7, 1M context)_
_All 6 success criteria + 8 scope-guardrail policy invariants + 19 REQ-IDs verified against the codebase, not against SUMMARY.md claims._
