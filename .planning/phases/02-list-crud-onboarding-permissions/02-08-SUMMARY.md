---
phase: 2
plan: 08
plan_id: 02-08
subsystem: onboarding-wizard
wave: 3
status: complete
completed_at: "2026-05-05T00:00:00Z"
duration_minutes: 35
tags: [onboarding, permissions, play-06, accessibility-rationale, oem-fallback, widgets-binding-observer, funnel, riverpod, go-router, phase-2-wave-3]
requires:
  - 02-04 (BlockListRepository.insertMany — quick-add seed; BlockListSeed typedef shape)
  - 02-05 (permissionStatusApiProvider, onboardingCursorProvider, onboardingCompleteProvider, permissionHealthProvider, dontkillmyappUrl helper, OnboardingKeys, MockPermissionStatusApi fixture)
  - Phase 1 (PLAY-06 disclosure copy in docs/play-declaration.md §4 — verbatim source of truth)
provides:
  - "WelcomeScreen — Surface 1 single headline + privacy claim + Get Started CTA, routes to /onboarding/quick-add"
  - "QuickAddScreen — Surface 2 5-card unchecked-by-default picker (Instagram, TikTok, X, YouTube, Reddit); on Continue seeds via repo.insertMany(kind=0,...) then routes to /onboarding/permissions/usage-access"
  - "UsageAccessStep — Surface 3 Step 1 with WidgetsBindingObserver onResume auto-advance; routes to /onboarding/permissions/accessibility on grant"
  - "AccessibilityStep — Surface 3 Step 2 with PLAY-06 prominent disclosure (5 verbatim phrases) + onResume; routes to /onboarding/permissions/battery-opt on grant"
  - "BatteryOptStep — Surface 3 Step 3 funnel terminator; on grant OR explicit skip calls persistCurrentFingerprint() + markComplete() then go('/')"
  - "RationaleScreen — shared shell for the 3 permission steps (UI-SPEC Surface 3 component tree)"
  - "PermissionStepDots — 1-of-3 step indicator widget"
  - "OemFallbackPanel — reactive vendor-specific guidance + dontkillmyapp.com link for {xiaomi, huawei, samsung, oppo, realme, vivo, oneplus}"
affects:
  - "Plan 02-09 (GoRouter wiring + asset placeholders + health banner) — must register routes /onboarding/welcome, /onboarding/quick-add, /onboarding/permissions/usage-access, /onboarding/permissions/accessibility, /onboarding/permissions/battery-opt; must drop placeholder PNGs at assets/onboarding/{usage_access_step,accessibility_step,battery_opt_step}.png and assets/logos/{instagram,tiktok,x,youtube,reddit}.png — all referenced via Image.asset(...) with errorBuilder fallback so missing files render as a neutral icon stub"
tech-stack:
  added: []
  patterns:
    - "WidgetsBindingObserver lifecycle pair on every step screen — addObserver(this) in initState paired with removeObserver(this) in dispose (RESEARCH §Pitfall D); didChangeAppLifecycleState filters to AppLifecycleState.resumed and re-checks the permission status, advancing on grant"
    - "ConsumerStatefulWidget over ConsumerWidget for the 3 step screens — required to host the WidgetsBindingObserver mixin and own the local _showOemFallback / _manufacturer state"
    - "RationaleScreen takes typed slots (afterScreenshot / belowBody) so each step screen can inject its OEM panel without forking the layout"
    - "Image.asset with errorBuilder returning a neutral grey container so the step screens render even before Plan 02-09 lands the placeholder PNGs at assets/onboarding/*"
    - "PLAY-06 verbatim-phrase enforcement is a source-grep test (prominent_disclosure_test.dart) — the 5 phrases live in accessibility_step.dart and any paraphrase fails the test before it can ship"
    - "OEM fallback panel triggers reactively (RESEARCH §Permission Step Deep-Links): on Settings intent failure (caught with `on Object`) OR on AppLifecycleState.resumed if grant remains false. CONTEXT.md: never always-on — fast path stays uncluttered for non-aggressive OEMs"
key-files:
  created:
    - lib/features/onboarding/pages/welcome_screen.dart
    - lib/features/onboarding/pages/quick_add_screen.dart
    - lib/features/onboarding/pages/usage_access_step.dart
    - lib/features/onboarding/pages/accessibility_step.dart
    - lib/features/onboarding/pages/battery_opt_step.dart
    - lib/features/onboarding/widgets/permission_step_dots.dart
    - lib/features/onboarding/widgets/rationale_screen.dart
    - lib/features/onboarding/widgets/oem_fallback_panel.dart
    - test/features/onboarding/quick_add_test.dart
    - test/features/onboarding/funnel_flow_test.dart
  modified:
    - test/features/onboarding/welcome_screen_test.dart
    - test/features/onboarding/quick_add_screen_test.dart
    - test/features/onboarding/oem_fallback_test.dart
    - test/features/onboarding/permission_funnel_test.dart
    - test/features/onboarding/permission_resume_detection_test.dart
    - test/features/onboarding/prominent_disclosure_test.dart
decisions:
  - "BatteryOpt skip still completes onboarding. CONTEXT.md is explicit: 1-tap skip + footer note; the home health-banner (Plan 02-09) is the rebound surface. NOT routing skip to a 'are you sure?' dialog matches REL-02."
  - "BatteryOpt skip persists fingerprint baseline BEFORE marking complete (same as grant path). Plan 02-05 contract: skipping the step means the user has seen the install-time funnel; recording fingerprint avoids spurious fingerprintChanged=true on first cold launch even when skipping."
  - "OEM fallback uses .toLowerCase() on the manufacturer string returned by the Pigeon API before keying the panel. Defensive: PermissionStatusApiImpl.kt already lowercases server-side, but the UI doesn't trust that — T-2-04 mitigation."
  - "Skip button placement matches UI-SPEC Surface 3 verbatim: AppBar action TextButton, NOT a floating second CTA. Footer note remains a Text widget below the primary CTA explaining the consequence."
  - "quick_add_test.dart and quick_add_screen_test.dart kept as separate files per plan files_modified frontmatter, with complementary scope: quick_add_screen_test.dart covers UI shape (5-cards / unchecked / toggle / 0-vs-5 navigation), quick_add_test.dart covers data-layer wiring (insertMany kind=0 + exact packageName/displayName mapping)."
  - "Lifecycle-pairing test asserts no exceptions surface on mount→unmount cycle for all 3 steps. A direct WidgetsBinding.instance.observers.length probe was rejected because PluginUtilities and other framework observers register transiently in tests; the indirect 'no exception thrown' invariant is the same CLAUDE.md-aligned strong contract Phase 1 used."
metrics:
  duration_minutes: 35
  completed_date: "2026-05-05"
  tasks_completed: 3
  files_created: 10
  files_modified: 6
  commits: 3
  flutter_test_result: "All tests passed (89 passing total; 31 net new tests added by this plan; 5 still-skipped Wave-0 stubs belong to other Wave-3/4 plans)"
  dart_analyze_errors: 0
requirements_completed:
  - LIST-07
  - ONBD-01
  - ONBD-02
  - ONBD-03
  - ONBD-04
  - ONBD-05
  - PLAY-06
---

# Phase 2 Plan 02-08: Onboarding wizard (Welcome + Quick-add + 3-step funnel + OEM-reactive + PLAY-06) — Summary

The full install-time onboarding flow is now wired end-to-end: `Welcome → Quick-add → Usage Access → Accessibility (PLAY-06) → Battery-opt → /`. Every step screen mixes `WidgetsBindingObserver` with paired add/remove observer calls and re-checks its permission on `AppLifecycleState.resumed`, so the user grants in Settings, taps back, and the funnel auto-advances. The Accessibility step carries all 5 verbatim PLAY-06 phrases from `docs/play-declaration.md §4`, enforced by a source-grep test. The OEM fallback panel surfaces only when reactively triggered (intent failed OR resume-without-grant) and only when the manufacturer is one of the 7 recognized aggressive vendors. The funnel terminator (BatteryOpt) persists the `Build.FINGERPRINT` baseline and marks onboarding complete on either grant OR explicit skip, so the home health-banner (Plan 02-09) won't immediately fire `fingerprintChanged=true`.

## What was built

### Task 02-08-01 — Welcome + Quick-add screens + tests → `74ccb2f`

- `lib/features/onboarding/pages/welcome_screen.dart`: `Scaffold` with centered `Build your Not-To-Do list` (displaySmall) + `We never see your data.` (bodyLarge / onSurfaceVariant) + full-width `FilledButton('Get Started')` routing to `/onboarding/quick-add`. `Semantics(header: true)` on the headline.
- `lib/features/onboarding/pages/quick_add_screen.dart`: `ConsumerStatefulWidget` with a private `_curated` const list of 5 entries — `Instagram` (com.instagram.android), `TikTok` (com.zhiliaoapp.musically), `X` (com.twitter.android), `YouTube` (com.google.android.youtube), `Reddit` (com.reddit.frontpage). `Set<String> _selected` initializes empty (all unchecked). Continue button always works; on tap, if any selected it calls `repo.insertMany([(kind: 0, packageName: pkg, displayName: name), ...])` then routes to `/onboarding/permissions/usage-access`.
- Tests: `welcome_screen_test.dart` (2 cases — render shape + Get Started routing), `quick_add_screen_test.dart` (5 cases — 5-card render / unchecked-by-default / toggle / 0-selected nav-only / 5-selected insertMany), `quick_add_test.dart` (2 cases — 3-selected kind=0 contract + all-5 packageName mapping).

### Task 02-08-02 — RationaleScreen + step dots + OemFallbackPanel + tests → `59f290c`

- `lib/features/onboarding/widgets/permission_step_dots.dart`: 1-indexed step dot row; active dot uses `cs.primary`, inactive uses `cs.outlineVariant`. Each dot wrapped in `Semantics(label: 'Step $n of $totalSteps', value: 'current step' if active)`.
- `lib/features/onboarding/widgets/rationale_screen.dart`: Stateless shell. `AppBar(title + Skip TextButton action)` → `SingleChildScrollView` → `PermissionStepDots(currentStep: stepIndex)` → `ClipRRect(Image.asset(screenshotAsset, errorBuilder: → neutral grey container))` → optional `afterScreenshot` slot → `DefaultTextStyle.merge(body)` → optional `belowBody` slot (for OEM panel) → primary `FilledButton(primaryCtaLabel)` → centered `footerNote` text.
- `lib/features/onboarding/widgets/oem_fallback_panel.dart`: Const map `_oemInstructions` keyed on lowercased manufacturer covering `xiaomi/huawei/samsung/oppo/realme/vivo/oneplus`. Falls back to a generic `"Open your phone's Settings → Battery → Battery optimization (or similar)"` for unknown OEMs (e.g. pixel). Renders `TextButton.icon('Step-by-step guide for your phone')` with `launchUrl(Uri.parse(dontkillmyappUrl(...)), externalApplication)` ONLY when `dontkillmyappUrl(...)` returns non-null. T-2-04 mitigation: slug map-resolved, host hard-coded `https://` inside `dontkillmyappUrl`.
- Tests: `oem_fallback_test.dart` (4 cases — xiaomi-specific copy + link / samsung-specific copy + link / pixel generic copy + NO link / 6-vendor link presence loop).

### Task 02-08-03 — 3 permission step screens with onResume + PLAY-06 + tests → `7c6ca3b`

- `lib/features/onboarding/pages/usage_access_step.dart`: `ConsumerStatefulWidget with WidgetsBindingObserver`. `initState` adds the observer + kicks `unawaited(_checkAndMaybeAdvance())`. `dispose` removes the observer. `didChangeAppLifecycleState` filters to `resumed` + `unawaited(_checkAndMaybeAdvance(fromResume: true))`. `_checkAndMaybeAdvance` reads `permissionStatusApiProvider.isUsageAccessGranted()`; on true, sets cursor=2 + routes to accessibility step; on false-from-resume, sets `_showOemFallback=true` with the lowercased manufacturer. `_openSettings` calls `api.openUsageAccessSettings()` inside try/`on Object` — failure surfaces the OEM panel inline. `_skip` advances cursor + routes.
- `lib/features/onboarding/pages/accessibility_step.dart`: same skeleton as Usage Access, but the body region is a 3-paragraph `Column` containing the 5 PLAY-06 verbatim phrases:
  1. `"package name"` — paragraph 1
  2. `"only when a window-state-changed event fires"` — paragraph 1
  3. `"never reads your screen"` — paragraph 2
  4. `"never sends anything off your device"` — paragraph 2
  5. `"disable this at any time"` — paragraph 3
  Headline: `Pause before you open blocked apps`. CTA: `I understand — open Settings`. Routes to `/onboarding/permissions/battery-opt` on grant.
- `lib/features/onboarding/pages/battery_opt_step.dart`: same skeleton; `_completeOnboarding` calls `permissionHealthProvider.notifier.persistCurrentFingerprint()` first then `onboardingCompleteProvider.notifier.markComplete()` then `context.go('/')`. **Skip on this step ALSO calls `_completeOnboarding`** — funnel is 1-tap-skippable per CONTEXT.md, the home health-banner takes over from there.
- Tests:
  - `permission_funnel_test.dart` (9 cases) — mount-with-grant auto-advance, mount-without-grant stays, skip routing, PLAY-06 disclosure render, BatteryOpt grant-path persists fingerprint+complete+routes-home, BatteryOpt skip-path persists fingerprint+complete+routes-home, lifecycle observer pairing for all 3 steps.
  - `permission_resume_detection_test.dart` (3 cases) — resume-with-flipped-grant auto-advances, resume-without-grant surfaces OEM fallback, spurious resume is idempotent.
  - `prominent_disclosure_test.dart` (6 cases) — 5 verbatim phrase grep tests + 1 "no autonomous-action methods" absence test (`performAction|performGlobalAction|dispatchGesture`).
  - `funnel_flow_test.dart` (2 cases) — sequenced skip-through (Step 1 → 2 → 3 → / + complete=true) + sequenced grant-through (3 successive resumed events with each permission granted).

## Public surface Wave 5 (Plan 02-09) will consume

```dart
// Routes to register on the GoRouter (path → builder):
// /onboarding/welcome             → const WelcomeScreen()
// /onboarding/quick-add           → const QuickAddScreen()
// /onboarding/permissions/usage-access  → const UsageAccessStep()
// /onboarding/permissions/accessibility → const AccessibilityStep()
// /onboarding/permissions/battery-opt   → const BatteryOptStep()

// Routing imports for Plan 02-09:
import 'package:not_to_do_list/features/onboarding/pages/welcome_screen.dart';
import 'package:not_to_do_list/features/onboarding/pages/quick_add_screen.dart';
import 'package:not_to_do_list/features/onboarding/pages/usage_access_step.dart';
import 'package:not_to_do_list/features/onboarding/pages/accessibility_step.dart';
import 'package:not_to_do_list/features/onboarding/pages/battery_opt_step.dart';
```

### Asset placeholders Plan 02-09 must drop

All referenced via `Image.asset(...)` with `errorBuilder`, so missing files render a neutral grey stub. Drop these to make the screenshots land:

- `assets/onboarding/usage_access_step.png`
- `assets/onboarding/accessibility_step.png`
- `assets/onboarding/battery_opt_step.png`
- `assets/logos/instagram.png`
- `assets/logos/tiktok.png`
- `assets/logos/x.png`
- `assets/logos/youtube.png`
- `assets/logos/reddit.png`

### Exit hooks called by BatteryOptStep

```dart
await ref.read(permissionHealthProvider.notifier).persistCurrentFingerprint();
await ref.read(onboardingCompleteProvider.notifier).markComplete();
context.go('/');
```

Both grant and skip paths call this. Plan 02-09's home shell can read `onboardingCompleteProvider` to gate the welcome redirect, and `permissionHealthProvider` to render the health banner.

## Verification

- [x] Welcome → Quick-add → 3-step funnel → Home wires correctly via `context.go` (verified by `funnel_flow_test.dart` sequenced skip + grant runs).
- [x] All 5 quick-add packages match the locked CONTEXT.md set verbatim (verified by `quick_add_test.dart`).
- [x] All 3 permission steps use the `WidgetsBindingObserver` lifecycle pair (Pitfall D) — verified by automated grep on each file's source AND by a mount→unmount cycle test asserting no exceptions surface.
- [x] PLAY-06 disclosure contains the 5 verbatim phrases — `prominent_disclosure_test.dart` source-greps `accessibility_step.dart` for each phrase.
- [x] OEM fallback panel renders only when reactively triggered (`permission_resume_detection_test.dart` — pixel-default mounts without panel; xiaomi shows panel after resume-without-grant).
- [x] BatteryOpt step persists fingerprint baseline AND marks onboarding complete on grant OR skip (`permission_funnel_test.dart` — both paths assert `prefs.getString('last_known_fingerprint')` and `prefs.getBool('onboarding_complete')`).
- [x] No autonomous-action methods (`performAction`/`performGlobalAction`/`dispatchGesture`) in `accessibility_step.dart` — verified by `prominent_disclosure_test.dart` absence-grep.
- [x] `flutter test` exits 0 — 89 passing project-wide.
- [x] `dart analyze` clean for all files this plan owns.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] very_good_analysis `always_put_required_named_parameters_first` rejects `super.key` before required params**

- **Found during:** Task 02-08-02 dart analyze
- **Issue:** Plan body's snippet for `RationaleScreen({super.key, required this.headline, ...})` triggers 8 lint infos because the linter wants required-named params before optional-named (and `super.key` is treated as optional-named).
- **Fix:** Reordered to `({required this.headline, ..., super.key, this.afterScreenshot, this.belowBody})`. Same surgical fix applied to `PermissionStepDots` and `OemFallbackPanel`.
- **Files modified:** `lib/features/onboarding/widgets/{rationale_screen,permission_step_dots,oem_fallback_panel}.dart`
- **Commit:** `59f290c`

**2. [Rule 1 - Bug] `discarded_futures` lint on `_checkAndMaybeAdvance()` calls in `initState` and `didChangeAppLifecycleState`**

- **Found during:** Task 02-08-03 dart analyze
- **Issue:** Plan body's snippet calls `_checkAndMaybeAdvance()` (a Future-returning method) without awaiting it from inside non-async `initState` and `didChangeAppLifecycleState`. Both call sites are intentional fire-and-forget (the lifecycle methods can't be async), but the linter flags them.
- **Fix:** Added `import 'dart:async';` to each step file and wrapped the calls with `unawaited(...)`. This is the canonical Dart pattern for explicit fire-and-forget.
- **Files modified:** `lib/features/onboarding/pages/{usage_access,accessibility,battery_opt}_step.dart`
- **Commit:** `7c6ca3b`

**3. [Rule 1 - Bug] `prefer_single_quotes` on OnePlus instructions**

- **Found during:** Task 02-08-02 dart analyze
- **Issue:** Plan body's snippet used double-quoted string for `'oneplus':` because of the `Don't` apostrophe; very_good_analysis still flagged the leading double-quoted half.
- **Fix:** Split the string concatenation across two parts — single-quoted for the part without an apostrophe, double-quoted only for the part containing the apostrophe.
- **Files modified:** `lib/features/onboarding/widgets/oem_fallback_panel.dart`
- **Commit:** `59f290c`

**4. [Rule 1 - Bug] `unnecessary_ignore` and minor line-length lint cleanup in tests**

- **Found during:** Task 02-08-01 / 02-08-03 dart analyze
- **Issue:** Some test files added `// ignore_for_file: unnecessary_lambdas` defensively (the Plan 02-05 fixture pattern) but the actual mocktail idiom in our tests didn't trigger the lint, so the ignore was itself flagged. A handful of test lines exceeded 80 chars.
- **Fix:** Removed the unused ignore comments where mocktail wasn't actually used; broke long lines. Files that DO use `when(() => mock.method())` (the canonical mocktail idiom) keep the ignore comment.
- **Files modified:** `test/features/onboarding/{quick_add_screen,quick_add,permission_funnel}_test.dart`
- **Commits:** `74ccb2f`, `7c6ca3b`

**5. [Rule 1 - Bug] `use_build_context_synchronously` after `await repo.insertMany(...)`**

- **Found during:** Task 02-08-01 dart analyze
- **Issue:** Plan body's snippet used `if (!mounted) return;` after the await but very_good_analysis specifically wants `if (!context.mounted) return;` for `BuildContext` use, since the State's `mounted` doesn't tell the linter that `context` is still safe.
- **Fix:** `if (!mounted) return;` → `if (!context.mounted) return;` in the QuickAddScreen Continue handler. Behaviorally identical — same lifecycle check, just typed correctly.
- **Files modified:** `lib/features/onboarding/pages/quick_add_screen.dart`
- **Commit:** `74ccb2f`

### Out-of-scope items deferred

None this plan. Untracked files in `lib/features/list/{controllers,pages,widgets}/` belong to the parallel sibling plan 02-06 (already partially merged via `2bc7809`); per scope-boundary rule I did not stage them.

## Authentication Gates

None encountered — this plan is pure Dart UI code with mocked permission API.

## Threat Model Mitigations Realized

| Threat | Disposition | Status |
|--------|-------------|--------|
| T-2-02 Tampering — Settings deep-link redirected to non-Settings activity | mitigate | All deep-links route through `permissionStatusApiProvider.openXxxSettings()` from Plan 02-03, which uses `resolveActivity`-guarded launches on the Kotlin side. This plan never constructs intents directly. |
| T-2-03 Information Disclosure — skip-without-grant masks unhealthy install state | mitigate | BatteryOpt skip routes through `_completeOnboarding()` which calls `persistCurrentFingerprint()` THEN `markComplete()`. Plan 02-09's `permissionHealthProvider` re-evaluates on app resume; if anything is ungranted, the banner appears on home immediately. |
| T-2-04 Tampering — OEM fallback URL tampered via interpolation | mitigate | `dontkillmyappUrl` (Plan 02-05) is a const map; manufacturerLower is a key, never interpolated into URL host. URL built via `'https://dontkillmyapp.com/$slug'` where slug is map-resolved. The OEM panel additionally `.toLowerCase()`s the manufacturer string in the UI as a defensive double-cast. |
| T-2-05 Information Disclosure — PLAY-06 disclosure copy drifts from `docs/play-declaration.md` | mitigate | `prominent_disclosure_test.dart` reads `accessibility_step.dart` as a string and asserts each of the 5 verbatim phrases is present. A future paraphrase fails the test before it can ship. |
| T-2-09 Repudiation — user denies they consented to AccessibilityService grant | accept (per plan) | Android Settings provides the canonical grant ledger (Settings → Accessibility lists every enabled service). This plan introduces no new grant-tracking surface. |

## Threat Flags

None — no new security-relevant surface beyond the plan's threat_model.

## Known Stubs

None introduced by this plan. Asset placeholders (`assets/onboarding/*.png`, `assets/logos/*.png`) are referenced by `Image.asset(...)` calls but are not stubs in the sense of "fake data wired to UI" — they are decorative screenshots with `errorBuilder` fallback. Plan 02-09 owns landing the actual files.

## Self-Check: PASSED

All claims verified:
- [x] `lib/features/onboarding/pages/welcome_screen.dart` exists, contains literal `'Build your Not-To-Do list'`, `'We never see your data.'`, `'Get Started'`
- [x] `lib/features/onboarding/pages/quick_add_screen.dart` exists, contains all 5 package names (`com.instagram.android`, `com.zhiliaoapp.musically`, `com.twitter.android`, `com.google.android.youtube`, `com.reddit.frontpage`)
- [x] `lib/features/onboarding/pages/{usage_access,accessibility,battery_opt}_step.dart` all contain literal `WidgetsBindingObserver`, `addObserver(this)`, `removeObserver(this)`, `AppLifecycleState.resumed`
- [x] `accessibility_step.dart` contains all 5 PLAY-06 verbatim phrases
- [x] `accessibility_step.dart` contains zero occurrences of `performAction(`, `performGlobalAction(`, `dispatchGesture(`
- [x] `battery_opt_step.dart` contains literal `persistCurrentFingerprint` AND `markComplete`
- [x] `lib/features/onboarding/widgets/{permission_step_dots,rationale_screen,oem_fallback_panel}.dart` all exist
- [x] `oem_fallback_panel.dart` contains all 6 OEM keys (`xiaomi`, `huawei`, `samsung`, `oppo`, `vivo`, `oneplus`) plus the `realme` alias
- [x] `oem_fallback_panel.dart` imports `package:url_launcher/url_launcher.dart` and `package:not_to_do_list/core/utils/dontkillmyapp_url.dart`
- [x] All Wave 0 stub tests filled in: `welcome_screen_test`, `quick_add_screen_test`, `oem_fallback_test`, `permission_funnel_test`, `permission_resume_detection_test`, `prominent_disclosure_test` (6 stubs replaced)
- [x] New test files created: `quick_add_test.dart`, `funnel_flow_test.dart`
- [x] `flutter test` exits 0 — 89 passing total
- [x] `dart analyze` clean on all owned files (no errors, warnings, or infos)
- [x] Commit `74ccb2f` (Task 1) found in git log
- [x] Commit `59f290c` (Task 2) found in git log
- [x] Commit `7c6ca3b` (Task 3) found in git log
