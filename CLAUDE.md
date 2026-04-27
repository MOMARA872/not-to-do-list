<!-- GSD:project-start source:PROJECT.md -->
## Project

**Not To-Do List**

A mindfulness-based Android app that helps adults stick to user-defined avoidance goals — apps and habits they explicitly want to NOT do. Combines a "Not-To-Do List" with screen-time tracking and a soft-block-with-timer pause screen ("Do you really need it now?") that interrupts the impulse moment without forcing a hard block. v1 ships as a standalone, on-device, account-free Android app for self-disciplined adults.

**Core Value:** When a user opens an app on their not-to-do list, the pause screen + cooldown timer creates a deliberate moment of reflection that helps them choose deliberately — and the streak counter rewards every day they succeed.

### Constraints

- **Tech stack**: Flutter (Dart) UI + native Android channels for `UsageStatsManager` and `AccessibilityService` — Flutter chosen so the eventual iOS port can reuse the UI layer.
- **Platform**: Android-only for v1 — iOS deferred to skip Apple Developer cost ($99/yr) and Family Controls entitlement complexity.
- **Backend**: None in v1 — fully local-first to ship lean and validate the wedge before adding sync.
- **Budget**: Free / OSS only — no paid APIs, no Apple costs, no managed services. Excludes content-categorization APIs entirely from v1.
- **Timeline**: 6–12 weeks to v1, solo full-time — forces ruthless scope discipline.
- **Privacy**: 100% on-device data residency in v1 — non-negotiable trust commitment.
- **Permissions**: `PACKAGE_USAGE_STATS` + Accessibility Service — justification copy must be transparent enough to pass Play Store review.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## TL;DR Recommendation
| Layer | Pick | Version |
|---|---|---|
| Framework | Flutter | 3.41.x stable (Dart 3.x) |
| State management | Riverpod (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`) | ^3.3.1 |
| Local DB | Drift (SQLite) | ^2.32.x |
| Local notifications | `flutter_local_notifications` + `timezone` | ^21.0.0 / ^0.11.0 |
| Permissions UX | `permission_handler` + `app_settings` | ^12.0.1 / latest |
| Per-app screen time | `app_usage` (with hand-rolled `MethodChannel` fallback for events) | ^4.1.0 |
| App-launch detection | `flutter_accessibility_service` | ^1.0.0 |
| Pause overlay | `flutter_overlay_window` | ^0.5.0 |
| **min/target SDK** | **minSdk 29 (Android 10), targetSdk 36 (Android 16)** | — |
## Recommended Stack
### Core Technologies
| Technology | Version | Purpose | Why Recommended |
|---|---|---|---|
| **Flutter** | 3.41.x (stable, Q1 2026) | UI + Dart runtime, with platform channels for native Android calls | Required by PROJECT.md (chosen for future iOS port). Flutter 3.41 is the current stable, requires AGP 8.11.1+, Java 17, compileSdk 35+. **Confidence: HIGH** ([Flutter 3.41 release](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632)) |
| **Riverpod** (`flutter_riverpod` + code generation) | ^3.3.1 | State management, dependency injection, caching, async lifecycle | In 2026 Riverpod 3.x is the de-facto Flutter state management default. Less boilerplate than Bloc — important for solo dev with 6–12 week budget. Compile-time safety, AsyncValue handles loading/error states for UsageStats queries cleanly, supports code generation via `@riverpod` annotation. Bloc would add 30–40% boilerplate without paying off at this scope. **Confidence: HIGH** ([flutter_riverpod 3.3.1](https://pub.dev/packages/flutter_riverpod)) |
| **Drift** (SQLite) | ^2.32.1 | On-device persistence: not-to-do entries, daily check-ins, streak history, daily usage aggregates | Drift is the only major Flutter DB in 2026 that is **(a) actively maintained**, **(b) typed/relational**, **(c) with built-in isolate threading**, and **(d) reactive (auto-updating streams)**. Our schema is relational (lists → entries → daily_usage_rows → check_ins) and we run aggregation queries (weekly/monthly rollups) — that's SQL territory, not key-value. Drift compiles SQL at build time, catches typos, and generates Dart classes. **Confidence: HIGH** ([drift 2.32.1](https://pub.dev/packages/drift)) |
| **`flutter_local_notifications`** | ^21.0.0 | Daily reminder push at user-chosen time; survives reboot via `RECEIVE_BOOT_COMPLETED` + `BootReceiver` | Flutter Favorite, verified publisher, current stable 21.0.0 (May 2025). Supports `AndroidScheduleMode.exactAllowWhileIdle` for hitting the user's chosen time even in Doze. Pair with `timezone` package for DST correctness on daily repeat. **Confidence: HIGH** ([flutter_local_notifications 21.0.0](https://pub.dev/packages/flutter_local_notifications)) |
| **`timezone`** | ^0.11.0 | IANA timezone-aware `TZDateTime` for daily reminder scheduling | Required peer dependency of flutter_local_notifications when scheduling repeating notifications. Without it, DST transitions cause the daily reminder to drift by an hour twice a year. **Confidence: HIGH** ([timezone 0.11.0](https://pub.dev/packages/timezone)) |
### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---|---|---|---|
| **`app_usage`** | ^4.1.0 | Calls `UsageStatsManager.queryUsageStats()` and returns per-app foreground time over a date range | **Primary screen-time data source.** Verified publisher (cachet.dk), Android-only, published 41 days ago. Returns daily-precision aggregates — adequate for our daily/weekly/monthly dashboard. **Confidence: HIGH** ([app_usage 4.1.0](https://pub.dev/packages/app_usage)) |
| **`usage_stats`** (alternate, pick one) | ^1.3.1 | Same purpose as app_usage, plus `queryEvents` (per-event timestamps, API 28+) | **Use only if you need event-level data** (e.g. minute-resolution usage on the blocked-app streak detection logic). Last published ~13 months ago, "unverified uploader." Slightly higher capability, lower confidence in maintenance. **Confidence: MEDIUM** ([usage_stats 1.3.1](https://pub.dev/packages/usage_stats)) |
| **`flutter_accessibility_service`** | ^1.0.0 | Streams `AccessibilityEvent`s including `packageName` of the foregrounded app | **Primary app-launch detection.** Verified publisher (iheb.tech), MIT, published 12 months ago. Provides `accessStream` of events — filter `TYPE_WINDOW_STATE_CHANGED` events whose `packageName` matches a not-to-do entry, then pop the pause screen via `flutter_overlay_window`. **Confidence: MEDIUM** — package quality is HIGH; *Play Store acceptance* is MEDIUM (see [Play Store strategy](#play-store-permission-justification-strategy)). ([flutter_accessibility_service 1.0.0](https://pub.dev/packages/flutter_accessibility_service)) |
| **`flutter_overlay_window`** | ^0.5.0 | Renders a Flutter widget tree as a `SYSTEM_ALERT_WINDOW` overlay on top of the offending app | **Pause-screen surface.** Same publisher as flutter_accessibility_service (iheb.tech), so the two compose well. Supports full-screen overlay, click-through modes, dynamic resize, and message-passing between overlay engine and main isolate (so the cooldown timer can talk to the main app). 0.5.0 is the latest as of 12 months ago. **Confidence: MEDIUM**. ([flutter_overlay_window 0.5.0](https://pub.dev/packages/flutter_overlay_window)) |
| **`permission_handler`** | ^12.0.1 | Runtime checks for `POST_NOTIFICATIONS`, `SYSTEM_ALERT_WINDOW`, etc. | Standard. `PACKAGE_USAGE_STATS` and AccessibilityService are *not* runtime permissions — they require deep-linking the user to system settings, which is what `app_settings` covers. **Confidence: HIGH** ([permission_handler 12.0.1](https://pub.dev/packages/permission_handler)) |
| **`app_settings`** | latest | Deep-link to `Settings.ACTION_USAGE_ACCESS_SETTINGS` and `Settings.ACTION_ACCESSIBILITY_SETTINGS` | Required because the two key permissions can't be requested via dialogs. The onboarding flow needs guided "tap here to enable Usage Access" UX. |
| **`shared_preferences`** | ^2.x | One-line settings (selected reminder time, onboarding-complete flag, last-streak-checked date) | Don't put this in Drift — schema overkill for a flat key-value store of ~10 settings. |
| **`go_router`** | ^14.x | Declarative routing | Standard companion to Riverpod. Solo-dev friendly. Nothing exotic about our nav graph (3–5 screens). |
| **`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` + `build_runner`** | ^3.3.1 / latest | Code-gen for Riverpod providers | Use code-gen flavor — it eliminates the family/autoDispose flag combinatorics that the legacy syntax forces. |
| **`drift_dev` + `build_runner`** | latest | Code-gen for Drift schemas/queries | Required for Drift's typed query generation. |
| **`logger`** or **`logging`** | latest | On-device debug logging during dev | Use freely in dev; gate behind `kDebugMode` for release. **Do not** log usage data — privacy stance forbids it. |
### Development Tools
| Tool | Purpose | Notes |
|---|---|---|
| Android Studio (Ladybug or newer) | Native Android debugger, AVD manager, Logcat | Required for debugging the AccessibilityService — Flutter DevTools can't see native service crashes. |
| `flutter_launcher_icons` | Generate adaptive icons | Standard. |
| `flutter_native_splash` | Splash screen | Standard. |
| `very_good_analysis` (or `flutter_lints`) | Stricter lint preset | `very_good_analysis` is the de facto strict preset in 2026; `flutter_lints` is the official baseline. Pick one and stick with it. |
| `mockito` or `mocktail` | Test doubles | `mocktail` preferred — no code-gen, plays nicer with Riverpod. |
| `integration_test` (Flutter SDK) | E2E tests | Skip in v1 unless time permits — solo dev, 6–12 weeks; unit tests of streak/usage logic deliver more ROI. |
## Installation
## Min/Target SDK
| Setting | Value | Reason |
|---|---|---|
| `minSdkVersion` | **29 (Android 10)** | PROJECT.md targets Android 10+. API 29 covers ~95%+ of active Android devices in 2026 ([apilevels.com](https://apilevels.com/)). Going lower (API 26/24) gains <2% of users and forces conditional code paths for foreground-service types, scoped storage, and `usesPermissionFlags`. Going higher (API 31/33) excludes a meaningful Android-10/11 install base — the demographic of "self-disciplined adults with older flagship devices" overlaps non-trivially with that. **Confidence: HIGH** |
| `targetSdkVersion` | **36 (Android 16)** | Google Play **mandates** targetSdk 36 for new apps submitted from Aug 31, 2026 onwards (and 35 from Aug 31, 2025 — already in effect). Targeting 36 from day one avoids a forced bump mid-validation. **Confidence: HIGH** ([targetSdk requirements](https://support.google.com/googleplay/android-developer/answer/11926878)) |
| `compileSdkVersion` | **36** | Match targetSdk. Required by `flutter_local_notifications` (≥35) and `permission_handler` (≥35). |
## Play Store Permission Justification Strategy
### What Google's policy actually says (as of Jan 28, 2026 and the April 15, 2026 update)
### Where our use falls
- We watch for `TYPE_WINDOW_STATE_CHANGED` events.
- If `event.packageName` is in the user's not-to-do list, we display the pause screen.
- The user — not the app — decides what happens next (start cooldown, dismiss, etc.).
- The app never clicks, types, navigates, or executes any UI action on the user's behalf. We *never* call `performAction()`, `performGlobalAction()`, or `dispatchGesture()`.
### Justification copy for the Play Console declaration form
### What the in-app disclosure must look like (per policy)
- **Inside the app**, not only on the Play listing.
- Shown **before** the user is sent to Settings — not after.
- Plain-language: "this app needs to read which app you've just opened so it can show your reflection screen."
- Separate UI — not buried in the privacy policy.
- Requires an explicit tap (e.g. "I understand — open Settings") to proceed.
### Risk mitigation: build a fallback from day one
- The dashboard, streak, daily check-in, and notification all run from `UsageStatsManager` data alone.
- The pause screen becomes opt-in only, gated behind a clearer "advanced — requires Accessibility" toggle.
- Worst case, ship v1 without launch interception and rely on `UsageStatsManager` polling (1–5 min) plus a daily "you went over" notification. Still validates the wedge.
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|---|---|---|
| **Drift** | **Hive** | Use only if your data is genuinely flat key-value with zero relations. We have entries → usage rows → check-ins, so SQL pays off. Hive is also community-maintained (the original author abandoned it) — same maintenance footing as Drift, but less powerful. ([Hive vs Drift comparison](https://medium.com/@flutter-app/hive-vs-isar-vs-drift-best-offline-db-for-flutter-c6f73cf1241e)) |
| **Drift** | **Isar** | **Do not use for new projects.** The original author abandoned Isar; community fork exists but the project is unsupported by its creator. Marketing claims of "fastest" are stale benchmarks. **Confidence: HIGH that this is the wrong choice in 2026.** |
| **Drift** | **sqflite** | Use only if you need bare-metal SQLite with no codegen. `sqflite` is fine but you write SQL strings by hand — every query is a typo away from a runtime crash. Drift gives you the same SQLite under the hood with type-checking and reactive streams. |
| **Drift** | **ObjectBox** | Faster on raw write throughput but not OSS in the way Drift is — has a commercial sync product that nudges you toward licensed pieces over time. Free tier is fine; just unnecessary complexity for our scale. |
| **Riverpod** | **Bloc** | Use Bloc only if you (a) are on a team that already knows it, or (b) need the explicit event-sourcing audit trail for regulated apps. Solo + 6–12 weeks + consumer wellness app: Bloc's boilerplate is dead weight. |
| **Riverpod** | **Provider** | Provider is the simpler ancestor. Fine for a 2-screen prototype, but Riverpod 3.x is strictly a superset with compile-time safety, and the boilerplate overhead is now negligible thanks to code generation. No reason to pick Provider for a new 2026 project. |
| **Riverpod** | **GetX** | **Avoid.** Tightly couples state, routing, and DI; encourages anti-patterns; smaller maintenance team; community sentiment in 2026 has shifted strongly away. |
| **`app_usage`** | **`usage_stats`** | Use `usage_stats` if you need `queryEvents` (per-event timestamps, API 28+) instead of daily aggregates. Last published 13 months ago and "unverified uploader" — adopt only if `app_usage` truly can't deliver event-level data you need. |
| **`app_usage`** | **Hand-rolled MethodChannel** | Drop to a custom MethodChannel **only** if you find a `UsageStatsManager` capability the package doesn't expose (e.g., `queryAndAggregateUsageStats`, `queryUsageStatsForUser`, network usage). Worth doing if you need it; not worth doing speculatively. Add ~40 lines of Kotlin and 20 lines of Dart per method — not a big lift. |
| **`flutter_accessibility_service`** | **Hand-rolled `AccessibilityService` + MethodChannel** | Worth considering only if the package becomes unmaintained (last update was 12 months ago — watch this). The native side is ~150 lines of Kotlin. **Do not** drop the package speculatively; the package's overlay-event integration with `flutter_overlay_window` is non-trivial to replicate. |
| **`flutter_overlay_window`** | **`system_alert_window`** | `system_alert_window` is older and on Android 11+ degrades to a notification bubble (per its own docs), which breaks our pause-screen UX. `flutter_overlay_window` keeps the full-screen overlay across versions. |
| **`flutter_overlay_window`** | **Launch a full Flutter Activity instead of an overlay** | Cleaner from a Play-policy perspective (no SYSTEM_ALERT_WINDOW), but the launching activity sits *behind* the foreground app on modern Android — you'd need to bring it to foreground from the AccessibilityService, which the 2026 policy may flag. Net: overlay is the cleaner trade. |
| **`flutter_local_notifications` exact-alarm** | **`workmanager` periodic task firing a notification** | WorkManager periodics run on a 15-min minimum interval and Doze-throttle aggressively. Daily reminder at user-chosen time needs exact alarm. Use WorkManager *additionally* for the once-daily streak-rollover job (non-critical timing). |
## What NOT to Use
| Avoid | Why | Use Instead |
|---|---|---|
| **Isar** | Author abandoned the project; community fork exists but lacks roadmap clarity. Performance benchmarks are years old. ([discussion](https://medium.com/@flutter-app/hive-vs-isar-vs-drift-best-offline-db-for-flutter-c6f73cf1241e)) | Drift |
| **GetX** | Conflates state/routing/DI; smaller maintenance team; pattern hostility from 2026 community | Riverpod + go_router |
| **`isAccessibilityTool="true"` flag** | Reserved for genuine assistive tech (screen readers etc.). Setting it on a habit app is a Play policy violation. | Submit a non-accessibility-tool declaration with a clear non-autonomous justification. |
| **`USE_EXACT_ALARM` permission** | Reserved for alarm/calendar-class apps. Triggers store auditing. | `SCHEDULE_EXACT_ALARM` (user prompts to grant; appropriate for daily reminder). |
| **`PerformAction` / `PerformGlobalAction` / `DispatchGesture` from AccessibilityService** | Crosses the line from "rule-based" to "autonomous," which the Jan-28-2026 policy prohibits. | Display the pause screen; let the user act. |
| **`flutter_app_lock`** | Solves a different problem — locks *your own* app on cold start / pause. Doesn't intercept other apps. | `flutter_accessibility_service` + `flutter_overlay_window` |
| **`screen_time` / `screen_time_tracker` / `usage_tracker`** packages | Niche, low-download, semi-maintained pub.dev packages. Only adopt if `app_usage` hits a wall. | `app_usage` (verified publisher, 1.45k weekly downloads, 41-day publish age) |
| **`firebase_messaging` / FCM** for the daily reminder | We have **no backend** in v1 by constraint. FCM also adds Google service account dependencies that conflict with the privacy stance. | `flutter_local_notifications` (purely client-side) |
| **Setting `minSdk` < 24** | Loses Java 8 desugaring, loses NotificationChannel native support, fragments testing matrix, gains <2% device coverage in 2026 | minSdk 29 (Android 10) per project constraint |
| **`getRunningTasks()`** | Deprecated since API 21. Returns only the caller's own tasks on modern Android. | UsageStatsManager (history) + AccessibilityService (real-time) |
## Stack Patterns by Variant
- Ship v1 in "self-report + UsageStats polling" mode: poll `UsageStatsManager` every 60 seconds via a foreground service of type `dataSync`; if a not-to-do app's usage in the last hour exceeds a threshold, fire a "you went over" local notification.
- Pause screen becomes a manual "I'm about to open X — start cooldown" button on the home screen.
- Wedge still validates: streak, daily check-in, dashboard all unaffected.
- Cut: monthly view (keep daily + weekly only).
- Cut: cooldown timer presets (offer just one default of 1 minute).
- Keep: not-to-do list, pause screen, daily reminder, streak. These four are the wedge.
- Drop `minSdk` to 28. `app_usage` works (its floor is API 21). `flutter_accessibility_service` works. `flutter_overlay_window` works. Flutter 3.41 supports it. Zero blockers — but you lose ~1.5% of users by *not* dropping the floor, so don't do this without a real reason.
## Version Compatibility
| Package A | Compatible With | Notes |
|---|---|---|
| `flutter_local_notifications ^21.0.0` | Flutter ≥ 3.38.1, AGP ≥ 8.11.1, compileSdk ≥ 35, Java 17 | Flutter 3.41 ships with the right AGP — no manual upgrade needed for greenfield projects. |
| `permission_handler ^12.0.1` | compileSdk ≥ 35, Java 17 | |
| `flutter_riverpod ^3.3.1` | `riverpod_annotation ^3.3.1`, `riverpod_generator ^3.3.0` | Pin all three to the same minor. |
| `drift ^2.32.1` | `drift_dev ^2.32.1`, `sqlite3_flutter_libs ^0.5.x` | drift_dev version must match drift version's minor. |
| `flutter_accessibility_service ^1.0.0` | `flutter_overlay_window ^0.5.0` | Same publisher (iheb.tech) — they're designed to compose. |
| `app_usage ^4.1.0` | minSdk ≥ 21 | Plenty of headroom below our minSdk 29. |
## Sources
- **pub.dev package listings** (verified 2026-04-26):
- **Google Play policies**:
- **Comparisons**:
- **Flutter SDK**:
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
