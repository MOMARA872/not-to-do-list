---
phase: 2
plan: 09
plan_id: 02-09
subsystem: app-shell
wave: 5
status: complete-pending-manual-uat
completed_at: "2026-05-07T03:30:00Z"
duration_minutes: 35
tags: [flutter, riverpod, go-router, dynamic-color, widgets-binding-observer, health-banner, onboarding-gate, asset-placeholders, phase-2-wave-5]
requires:
  - 02-05 (permissionHealthProvider, onboardingCompleteProvider, dontkillmyappUrl)
  - 02-06 (AppTheme.light({ColorScheme? dynamic}), Add-App / Add-Habit / Edit-Entry screens; dynamic_color + url_launcher in pubspec)
  - 02-07 (HomeScreen ConsumerWidget; private _homeEntriesProvider intentionally private)
  - 02-08 (Welcome / QuickAdd / 3 permission step screens; BatteryOptStep already calls persistCurrentFingerprint+markComplete+go('/'))
provides:
  - "HealthCheckBanner — Surface 11 amber banner with literal copy 'Tracking is offline — tap to fix'; expandable detail rows + dontkillmyapp.com OEM link; tap resets onboardingCompleteProvider then routes to FIRST failing permission step (usage > a11y > battery)."
  - "HealthLifecycleObserver — top-level WidgetsBindingObserver pair driving permissionHealthProvider.refresh() on every AppLifecycleState.resumed (T-2-03 + T-2-06)."
  - "appRouterProvider — 9 GoRoutes (/, welcome, quick-add, 3 permission steps, /list/add-app, /list/add-habit, /list/edit/:id) + redirect callback gating on onboardingCompleteProvider (T-2-10)."
  - "NotToDoApp — MaterialApp.router wrapped in DynamicColorBuilder + HealthLifecycleObserver; uses harmonized scheme on Android 12+, falls back to ColorScheme.fromSeed(0xFF2D6A4F) otherwise."
  - "8 placeholder PNGs (1×1 transparent) at the paths Plan 02-08's RationaleScreen + QuickAddScreen reference via Image.asset() with errorBuilder fallback."
  - "assets/onboarding/README.md + assets/logos/README.md — document deferral to Phase 6 PLAY-08 closed-track submission (real Pixel-stock-Android-16 captures)."
affects:
  - "Plan 02-10 (Phase 2 exit gate / policy-test sweep) — should exercise the redirect via integration tests if it lands one; final flutter test count is 116 passing + 1 skipped (the orphan health/banner_test.dart Wave 0 stub never landed a file)."
  - "Phase 4 (launch interception) — banner re-evaluation pattern proven; will reuse HealthLifecycleObserver as the cross-feature lifecycle hook."
  - "Phase 6 PLAY-08 — must replace 3 onboarding screenshot PNGs with real captures BEFORE closed-track submission. Tracked in assets/onboarding/README.md."
tech-stack:
  added: []
  patterns:
    - "DynamicColorBuilder wrapping MaterialApp.router — passes harmonized lightDynamic/darkDynamic ColorSchemes through AppTheme.light(dynamic:) / .dark(dynamic:); falls back to seed-derived scheme when null."
    - "Top-level WidgetsBindingObserver mounted via HealthLifecycleObserver wrapping the router — ONE observer drives all surfaces' permission refresh on resume. Pattern reusable for any future 'cross-feature lifecycle hook' (e.g. Phase 4's blocked-app detector wake-up)."
    - "GoRouter redirect callback that ref.read()s an AsyncNotifierProvider via .value (Riverpod 3.x; AsyncValue.valueOrNull is a Riverpod 2.x API per Plan 02-05 deviation)."
    - "Banner-driven re-entry into the funnel — _tapToFix awaits onboardingCompleteProvider.notifier.reset() BEFORE context.go() so BatteryOpt's _completeOnboarding re-fires after user fixes the issue (T-2-10 mitigation)."
    - "Const-keyed amber color tokens NOT M3 ColorScheme seed — Surface 11 fixes amber bg/fg quartet for both brightness modes; banner color is intentionally NOT colorScheme.error."
    - "1×1 transparent PNG placeholder format — RationaleScreen's errorBuilder still fires for missing files but a present-but-blank image lets layout reserve space correctly while waiting for Phase 6 captures."
key-files:
  created:
    - lib/features/health/widgets/health_check_banner.dart
    - lib/features/health/widgets/_health_lifecycle_observer.dart
    - assets/onboarding/usage_access_step.png
    - assets/onboarding/accessibility_step.png
    - assets/onboarding/battery_opt_step.png
    - assets/onboarding/README.md
    - assets/logos/instagram.png
    - assets/logos/tiktok.png
    - assets/logos/x.png
    - assets/logos/youtube.png
    - assets/logos/reddit.png
    - assets/logos/README.md
  modified:
    - lib/core/router/app_router.dart
    - lib/app.dart
    - lib/features/home/pages/home_screen.dart
    - test/features/home/health_banner_test.dart
key-decisions:
  - "Took Option B for banner integration (edit HomeScreen.body) rather than Option A (ShellRoute). Plan body's Step 3 explicitly mandates editing HomeScreen and the acceptance grep requires literal 'HealthCheckBanner(' in home_screen.dart. The integration_decision in the prompt allowed Option B if 'plan body explicitly mandates it'. Trade-off: HomeScreen now imports the health feature; in exchange the route table stays flat (9 GoRoutes, no ShellRoute)."
  - "Used the SINGLE Wave 0 stub at test/features/home/health_banner_test.dart for ALL 6 banner test cases. The plan body and frontmatter named three potential paths (test/features/health/health_banner_test.dart, test/features/health/banner_test.dart, test/features/home/health_banner_test.dart) but only the home/ one was actually created in Wave 0; the plan body explicitly directs the executor to update existing stubs rather than create new file paths."
  - "Routed banner-tap with fingerprintChanged=true (but all 3 perms granted) to /onboarding/permissions/usage-access — re-walks the user from the top of the funnel after an OS update, since the BatteryOpt step is the one that calls persistCurrentFingerprint(). No alternative is meaningfully simpler."
  - "Inlined the manufacturer.toLowerCase() in HealthCheckBanner._OemLink instead of trusting the Pigeon-side lowercasing — same defensive double-cast Plan 02-08's OemFallbackPanel uses (T-2-04 mitigation)."
  - "Did NOT auto-execute the manual UAT (Task 02-09-04). Per prompt: 'Other checkpoints (e.g., manual UAT) — pause and return CHECKPOINT REACHED.' The 13-step walkthrough requires a Pixel emulator + human. Reported as deferred-to-developer with the build/test verification automation already complete."
patterns-established:
  - "Banner re-evaluation cycle: HealthLifecycleObserver.didChangeAppLifecycleState (resume) → permissionHealthProvider.notifier.refresh() → AsyncNotifier emits new PermissionHealth → HomeScreen's healthAsync rebuild → AnimatedSwitcher cross-fades banner in/out. Closed loop, NO manual user action required."
  - "Onboarding-gate redirect: ref.read(onboardingCompleteProvider).value ?? false in GoRouter.redirect runs on EVERY navigation, so even direct route URLs are caught (T-2-10)."
  - "Asset placeholder strategy: 1×1 transparent PNGs + co-located README documenting Phase 6 replacement procedure. Reusable for any deferred-asset slot (Phase 5 streak heatmap, Phase 6 store screenshots)."
requirements_completed:
  - REL-02
  - REL-03
  - ONBD-05
  - ONBD-06
  - ONBD-07
  - PLAY-06
metrics:
  duration_minutes: 35
  completed_date: "2026-05-07"
  tasks_completed: 3  # Task 4 (manual UAT) is human-verify; deferred.
  files_created: 12
  files_modified: 4
  commits: 4  # 3 task commits + 1 style fixup for acceptance-grep alignment
  flutter_test_result: "116 passing, 1 skipped (the orphan test/features/home/health_banner_test.dart was filled in by this plan; the 1 skipped test is the welcome_screen Wave 0 stub which Plan 02-08 already replaced — current skip count is the residue of an unfilled placeholder elsewhere)."
  dart_analyze_errors: 0
  dart_analyze_warnings: 0
  dart_analyze_info_pre_existing: 18 (pigeons/*.dart + test/_fixtures/permission_status_mock.dart — Plan 02-03/02-05 deferred-items)
  flutter_build_apk_debug_result: "Built build/app/outputs/flutter-apk/app-debug.apk"
---

# Phase 2 Plan 09: Health-check banner + router wiring + DynamicColorBuilder + asset placeholders — Summary

The Wave-3 surfaces (the picker, the wizard, the home list) and the Wave-2
state providers are now stitched into a runnable end-to-end app. The
9-route GoRouter has the onboarding-gate redirect; the MaterialApp.router
is wrapped in `DynamicColorBuilder` so Android 12+ gets the harmonized
scheme; a single top-level `HealthLifecycleObserver` triggers
`permissionHealthProvider.refresh()` on every `AppLifecycleState.resumed`;
the home screen's body slots the amber `HealthCheckBanner` above the list
inside an `AnimatedSwitcher` (visible iff `!allHealthy`); banner-tap
resets `onboardingCompleteProvider` BEFORE routing to the first failing
step (T-2-10); and the 8 placeholder PNGs + 2 READMEs ship for Phase 6
replacement. `flutter test` passes 116. `flutter build apk --debug`
succeeds.

## Performance

- **Duration:** ~35 min (active execution; one rate-limit retry from a
  prior agent killed at the start consumed no commits)
- **Tasks completed:** 3/4 (Task 4 is `checkpoint:human-verify` — see
  Wave 6 hand-off)
- **Files created:** 12 (2 widgets + 8 PNGs + 2 READMEs)
- **Files modified:** 4 (router, app, home_screen, test stub)
- **Commits:** 3 atomic per-task commits

## Tasks Completed

| Task     | Name                                                                          | Commit    |
| -------- | ----------------------------------------------------------------------------- | --------- |
| 02-09-01 | HealthCheckBanner + HealthLifecycleObserver + HomeScreen body integration     | `4698eb7` |
| 02-09-02 | 9-route GoRouter + onboarding-gate redirect + DynamicColorBuilder wrapper     | `904f4fd` |
| 02-09-03 | 8 placeholder PNGs + 2 READMEs                                                | `365dfc6` |
| 02-09-04 | Manual UAT smoke test                                                         | DEFERRED  |

**Style fixup:** `99fbdb8` (style) — single-line each `GoRoute` so the plan's `grep -c "GoRoute(path:"` acceptance check returns 9 (the multi-line formatter-friendly layout was returning 1).

## Files Created / Modified

### Created (12)

- **`lib/features/health/widgets/health_check_banner.dart`** — Surface 11.
  Stateful Material+InkWell with a Row containing
  `Icons.warning_amber_outlined` + literal `'Tracking is offline — tap to
  fix'` + an expand IconButton. Expanded body conditionally renders 3
  detail strings keyed off the `PermissionHealth` flags + an `_OemLink`
  child that resolves the manufacturer asynchronously and only renders if
  `dontkillmyappUrl(...)` returns non-null. `_tapToFix()` awaits
  `onboardingCompleteProvider.notifier.reset()` THEN `context.go()` to
  the first failing permission step (priority: usage-access >
  accessibility > battery-opt; fingerprintChanged falls through to
  usage-access).
- **`lib/features/health/widgets/_health_lifecycle_observer.dart`** —
  ConsumerStatefulWidget with `WidgetsBindingObserver` mixin. `initState`
  pairs `WidgetsBinding.instance.addObserver(this)` with `dispose`'s
  `removeObserver(this)` (Pitfall D). `didChangeAppLifecycleState` filters
  to `AppLifecycleState.resumed` then calls
  `unawaited(ref.read(permissionHealthProvider.notifier).refresh())`.
- **`assets/onboarding/{usage_access_step,accessibility_step,battery_opt_step}.png`**
  — 8-byte PNG header verified for each (`89 50 4e 47 0d 0a 1a 0a`).
- **`assets/onboarding/README.md`** — documents the Pixel-stock-Android-16
  capture procedure deferred to Phase 6 PLAY-08.
- **`assets/logos/{instagram,tiktok,x,youtube,reddit}.png`** — 1×1
  transparent PNGs.
- **`assets/logos/README.md`** — documents the runtime PackageManager
  fallback strategy as preferred over licensing brand assets.

### Modified (4)

- **`lib/core/router/app_router.dart`** — Phase 1 single-route stub
  replaced with 9 GoRoutes + a redirect callback. The `// hand-written
  (no @riverpod codegen) because…` comment block is preserved verbatim
  per Plan 01-01 deviation. `EditEntryScreen` is constructed via
  `EditEntryScreen(id: id)` to match Plan 02-06's actual constructor
  signature (the plan body's snippet showed `entryId:` which doesn't
  match the existing screen).
- **`lib/app.dart`** — Wraps `MaterialApp.router` in `DynamicColorBuilder`
  AND `HealthLifecycleObserver`. `theme` and `darkTheme` now pass the
  builder's `lightDynamic` / `darkDynamic` schemes through `AppTheme.light(dynamic:)` / `.dark(dynamic:)`.
- **`lib/features/home/pages/home_screen.dart`** — Body is now a `Column`
  with the banner (inside an `AnimatedSwitcher`) above the list. The
  banner condition is `healthAsync.maybeWhen(data: (h) => h.allHealthy ?
  SizedBox.shrink() : HealthCheckBanner(health: h), orElse:
  SizedBox.shrink())`. The list itself is unchanged.
- **`test/features/home/health_banner_test.dart`** — Wave 0 stub replaced
  with 6 widget tests: visibility, expand toggle reveals matching detail,
  tap routes to usage-access (priority 1), tap routes to accessibility
  (when usage granted), tap routes to battery-opt (when usage+a11y
  granted), and fingerprintChanged forces banner copy + routes to
  usage-access (ONBD-07).

## REQ-ID Coverage

| REQ-ID  | Demonstrated by                                                                                                                                                |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| REL-02  | `HealthCheckBanner` mounted via `HomeScreen` `AnimatedSwitcher`; visibility gated on `!h.allHealthy`. Re-evaluated by `HealthLifecycleObserver` on resume.     |
| REL-03  | `_OemLink` resolves manufacturer via `permissionStatusApiProvider.currentManufacturer()`, calls `dontkillmyappUrl(mfrLower)`, renders `Step-by-step guide` button only on a recognized OEM. |
| ONBD-05 | Banner-driven re-entry: `_tapToFix` awaits `onboardingCompleteProvider.notifier.reset()` BEFORE `context.go(...)` so the funnel re-fires `_completeOnboarding` after the fix. |
| ONBD-06 | Banner copy is the literal `'Tracking is offline — tap to fix'`. Single line. No emoji. No exclamation. Verified by widget test.                              |
| ONBD-07 | `permissionHealthProvider`'s `fingerprintChanged` propagates to `allHealthy=false`; banner shows even with all 3 perms granted; tap routes to usage-access (re-walk). |
| PLAY-06 | Already complete in 02-08; this plan only wires the routes. Banner-driven re-entry that lands on `/onboarding/permissions/accessibility` exposes the same PLAY-06-compliant disclosure. |

## Threat Model Mitigations Realized

| Threat | Disposition | Status |
|--------|-------------|--------|
| T-2-03 Information Disclosure — banner masks revoked permission | mitigate | `HealthLifecycleObserver` calls `permissionHealthProvider.notifier.refresh()` on EVERY `AppLifecycleState.resumed`. Refresh re-reads the 3 permission signals via the Pigeon channel and updates state; the AnimatedSwitcher re-evaluates banner visibility on the next frame. |
| T-2-04 Tampering — dontkillmyapp.com URL tampered | mitigate | `_OemLink` calls `dontkillmyappUrl(snap.data!.toLowerCase())`; the helper resolves a const map (Plan 02-05) — manufacturer is never interpolated into the URL host. The `.toLowerCase()` is a defensive double-cast (Pigeon side already lowercases). |
| T-2-06 DoS — banner refresh floods Pigeon channel | accept | Per plan: 3 small Pigeon round-trips on each user-initiated foreground event. Naturally rate-limited by the lifecycle. No throttling added. |
| T-2-10 Spoofing — onboarding redirect bypass | mitigate | `appRouterProvider` redirect callback runs on every navigation; reads `onboardingCompleteProvider.value` and gates non-onboarding routes when false. Banner-driven re-entry resets the gate before navigating so the BatteryOpt step's `_completeOnboarding` re-fires. |

## Threat Flags

None — no new security-relevant surface beyond the plan's threat_model.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Riverpod 3.x AsyncValue has no `valueOrNull` getter**

- **Found during:** Task 02-09-02 dart analyze.
- **Issue:** Plan body's redirect snippet used `ref.read(onboardingCompleteProvider).valueOrNull ?? false`; Riverpod 3.x exposes the same value via `.value` (returns `T?`). Same deviation Plan 02-05 hit on `OnboardingCursorNotifier.advance()`.
- **Fix:** `valueOrNull` → `value`. Behaviorally identical.
- **Files modified:** `lib/core/router/app_router.dart`
- **Commit:** `904f4fd`

**2. [Rule 3 - Blocking] Plan body's `EditEntryScreen(entryId: id)` doesn't match the actual constructor**

- **Found during:** Task 02-09-02 first analyze.
- **Issue:** Plan 02-06's `EditEntryScreen` constructor takes `id`, not `entryId` (verified via grep). The plan body's snippet would compile-fail.
- **Fix:** `EditEntryScreen(entryId: id)` → `EditEntryScreen(id: id)`.
- **Files modified:** `lib/core/router/app_router.dart`
- **Commit:** `904f4fd`

**3. [Rule 1 - Bug] very_good_analysis `discarded_futures` on `refresh()` call inside the lifecycle handler**

- **Found during:** Task 02-09-01 dart analyze.
- **Issue:** `didChangeAppLifecycleState` is a non-async void method; calling `ref.read(...).refresh()` (which returns `Future<void>`) without `unawaited` triggers `discarded_futures`. Same Dart pattern Plan 02-08 hit.
- **Fix:** Added `import 'dart:async';` and wrapped the call with `unawaited(...)`.
- **Files modified:** `lib/features/health/widgets/_health_lifecycle_observer.dart`
- **Commit:** `4698eb7`

**4. [Rule 1 - Bug] very_good_analysis `avoid_types_on_closure_parameters` on `DynamicColorBuilder.builder` lambda**

- **Found during:** Task 02-09-02 dart analyze.
- **Issue:** Plan body's snippet typed the closure params as `(ColorScheme? lightDynamic, ColorScheme? darkDynamic)`; very_good_analysis prefers inference here.
- **Fix:** `(lightDynamic, darkDynamic)` — types still flow from `DynamicColorBuilder`'s public signature.
- **Files modified:** `lib/app.dart`
- **Commit:** `904f4fd`

**5. [Rule 1 - Bug] `comment_references` + `unnecessary_ignore` + `missing_whitespace_between_adjacent_strings` cleanup**

- **Found during:** Task 02-09-01 final analyze sweep.
- **Issue:** Initial draft of `_health_lifecycle_observer.dart` had several `[ClassName]` comment references that didn't import the referenced types; test file's `ignore_for_file: unnecessary_lambdas` was unused (no mocktail in this test); two adjacent string literals in test names were missing trailing whitespace.
- **Fix:** Replaced doc-comment references with backtick code spans; removed the unused ignore; added trailing whitespace to one test name + reformatted another.
- **Files modified:** `lib/features/health/widgets/_health_lifecycle_observer.dart`, `test/features/home/health_banner_test.dart`
- **Commit:** `4698eb7`

### Out-of-scope items

The 18 pre-existing dart analyze infos in `pigeons/*.dart` + `test/_fixtures/permission_status_mock.dart` (Plans 02-03 / 02-05 deferred-items) remain as-is. CLAUDE.md surgical-changes rule.

### Manual UAT (Task 02-09-04) deferred

The 13-step manual UAT walkthrough requires a Pixel emulator running stock Android 16 + a human to step through the funnel. Per the prompt's auto-mode override, "Other checkpoints (e.g., manual UAT) — pause and return CHECKPOINT REACHED." The automation portion of Task 4 (`flutter build apk --debug`) was verified — APK builds successfully. The 13 manual steps are documented in the plan body for the developer to run before merging this plan into the Phase 2 release.

## Authentication Gates

None encountered — this plan is pure Dart code touching no authenticated services.

## Wave 6 Hand-off Notes (for Plan 02-10 phase exit gate)

- **`flutter test` count:** 116 passing, 1 skipped. The 1 skipped test
  is a Wave 0 stub elsewhere in the suite (NOT health/banner — that one
  was filled in by this plan); Plan 02-10's policy-test sweep should
  identify and either fill or remove it.
- **`dart analyze` state:** 18 pre-existing infos in `pigeons/*.dart` +
  `test/_fixtures/permission_status_mock.dart`. Documented in
  `.planning/phases/02-list-crud-onboarding-permissions/deferred-items.md`.
  Zero errors, zero warnings, zero infos in any 02-09-owned file.
- **`flutter build apk --debug`:** succeeds (`Built
  build/app/outputs/flutter-apk/app-debug.apk`).
- **Tests this plan added that 02-10's policy sweep should be aware of:**
  - `test/features/home/health_banner_test.dart` — 6 widget tests
    covering visibility, expand toggle, priority routing, reset-then-go
    ordering, and ONBD-07 fingerprintChanged path. Uses
    `permissionStatusApiProvider.overrideWithValue(MockPermissionStatusApi)`
    + the in-process GoRouter harness.
- **Tests still skipped (Wave-0 orphans this plan did NOT touch):** none
  in `test/features/health/` (only 3 tests there, all from Plan 02-05;
  none skipped). The 1 remaining skip is in `test/features/onboarding/`
  per the test runner output — Plan 02-08 left a `welcome_screen_test`
  shape that retains a non-implemented case.
- **Manual UAT:** the 13-step walkthrough in 02-09-PLAN.md Task 4 needs
  a developer with a Pixel emulator. Acceptance is recorded in the PR
  commit message ("Phase 2 manual UAT passed: <date>
  <emulator-version>") per the plan body. 02-10's exit gate should NOT
  proceed without this developer sign-off.
- **Post-banner-fix re-walk pattern:** if the user lands on
  `/onboarding/permissions/usage-access` from the banner with
  `fingerprintChanged=true` AND all 3 perms still granted, the
  UsageAccess step's `_checkAndMaybeAdvance` will see grant=true on
  mount and immediately auto-advance to the accessibility step, which
  also auto-advances, which routes to BatteryOpt, which calls
  `persistCurrentFingerprint()` → `markComplete()`. End result: the
  fingerprint baseline is reset and the banner clears on the next
  resume tick. This is the intended ONBD-07 closed loop.

## Stable surfaces 02-10 can rely on

- `appRouterProvider` is the single GoRouter mount point. Override
  `onboardingCompleteProvider` in tests to flip the redirect.
- `HealthCheckBanner` is a public `ConsumerStatefulWidget` with
  `required PermissionHealth health`; it does NOT subscribe to the
  provider itself — that's the parent's responsibility.
- `HealthLifecycleObserver` is mounted ONCE at the app root. Tests can
  drive `didChangeAppLifecycleState(AppLifecycleState.resumed)` directly
  to exercise the refresh path.
- `AppTheme.light({ColorScheme? dynamic})` / `.dark({ColorScheme?
  dynamic})` accept null and fall back to the seeded scheme — Android
  10/11 path is the default in widget tests.

## Known Stubs

None introduced by this plan in code. The 8 placeholder PNGs are
documented stubs (Phase 6 PLAY-08 replacement); they are not "fake data
wired to UI" — they are decorative screenshots with `errorBuilder`
fallbacks already in place from Plan 02-08. The em-dash trailing column
on `BlockListRow` (from Plan 02-07) remains a Phase 5 Streak slot
placeholder, unchanged by this plan.

## TDD Gate Compliance

This plan is `type: execute`, not `type: tdd`. Per-task commits use
conventional types: 2× `feat(02-09)` for the production-code tasks +
1× `chore(02-09)` for assets. Test edits ship inside Task 1's `feat`
commit because the Wave 0 stub was previously a single skipped test —
the production-code commit and the test-replacement are atomic.

## Self-Check: PASSED

**File existence:**
- ✓ FOUND: lib/features/health/widgets/health_check_banner.dart
- ✓ FOUND: lib/features/health/widgets/_health_lifecycle_observer.dart
- ✓ MODIFIED: lib/features/home/pages/home_screen.dart (now contains `HealthCheckBanner(`)
- ✓ MODIFIED: lib/core/router/app_router.dart (9 `GoRoute(` entries; redirect callback present; hand-written-no-codegen comment preserved)
- ✓ MODIFIED: lib/app.dart (`DynamicColorBuilder(`, `HealthLifecycleObserver(`, `AppTheme.light(dynamic: lightDynamic)`, `AppTheme.dark(dynamic: darkDynamic)` all present)
- ✓ FOUND: assets/onboarding/{usage_access_step,accessibility_step,battery_opt_step}.png (8-byte PNG header verified)
- ✓ FOUND: assets/logos/{instagram,tiktok,x,youtube,reddit}.png (8-byte PNG header verified)
- ✓ FOUND: assets/onboarding/README.md (contains literal `PLACEHOLDERS`)
- ✓ FOUND: assets/logos/README.md (contains literal `PLACEHOLDERS`)

**Acceptance grep coverage (verified post-commit):**
- ✓ `'Tracking is offline — tap to fix'` in health_check_banner.dart
- ✓ `Color(0xFFFFF3CD)`, `Color(0xFF856404)`, `Color(0xFF3D2E00)`, `Color(0xFFFFD966)` in health_check_banner.dart
- ✓ `'Usage Access is off — screen-time tracking is paused.'`, `'Accessibility Service is off — app blocking is paused.'`, `'Battery optimization is on — tracking may stop overnight.'` in health_check_banner.dart
- ✓ `'Step-by-step guide for your phone'` in health_check_banner.dart
- ✓ NO `colorScheme.error` in health_check_banner.dart
- ✓ `addObserver(this)` AND `removeObserver(this)` in _health_lifecycle_observer.dart
- ✓ `HealthCheckBanner(` in home_screen.dart
- ✓ 9 `GoRoute(path:` entries in app_router.dart (verified via `grep -c`)
- ✓ `final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(` in app_router.dart
- ✓ `goingToOnboarding` and `onboardingCompleteProvider` in redirect callback
- ✓ "no `@riverpod` codegen" comment block preserved in app_router.dart
- ✓ `DynamicColorBuilder(` AND `HealthLifecycleObserver(` in app.dart
- ✓ `AppTheme.light(dynamic: lightDynamic)` AND `AppTheme.dark(dynamic: darkDynamic)` in app.dart

**Commit existence:**
- ✓ FOUND: 4698eb7 — feat(02-09): add HealthCheckBanner + lifecycle observer; mount above home list
- ✓ FOUND: 904f4fd — feat(02-09): wire 9-route GoRouter + onboarding-gate redirect; wrap MaterialApp in DynamicColorBuilder + HealthLifecycleObserver
- ✓ FOUND: 365dfc6 — chore(02-09): add 8 placeholder PNGs (1×1 transparent) + 2 READMEs
- ✓ FOUND: 99fbdb8 — style(02-09): single-line each GoRoute so acceptance grep counts 9

**Test status:** `flutter test` exits 0 — 116 passing, 1 skipped (Wave 0 orphan in `test/features/onboarding/` not owned by this plan).

**Build status:** `flutter build apk --debug` exits 0 — `Built build/app/outputs/flutter-apk/app-debug.apk`.

**Threat-model deltas:** none. No new security-relevant surface beyond the plan's threat_model.

---

*Phase: 02-list-crud-onboarding-permissions*
*Plan: 02-09*
*Status: code complete; manual UAT (Task 02-09-04) deferred to developer with Pixel emulator before Phase 2 exit gate (02-10)*
*Completed: 2026-05-07*
