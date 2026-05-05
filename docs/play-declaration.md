# Play Console Permission Declaration — Not To-Do List

**Source of truth for:**
- Google Play Console "Use of the AccessibilityService API" Permission Declaration form
- `android/app/src/main/res/xml/not_todo_a11y_config.xml` `android:description`
- `android/app/src/main/res/values/strings.xml` `a11y_service_description`
- In-app Accessibility Service prominent-disclosure screen (Phase 2, PLAY-06)
- Privacy Policy → Accessibility Use section (Phase 6)
- Data Safety form cross-reference (`docs/data-safety.md`)

**Last updated:** 2026-04-27 (Phase 1 commit)
**Policy version this matches:** Use of the AccessibilityService API, post Jan-28-2026 + Apr-15-2026 Play Console policy.

---

## 1. App description and core function

Not To-Do List helps adults stick to self-defined avoidance goals — apps and habits they have explicitly chosen to use less or not at all. The user creates their own "Not-To-Do List" and asks the app to interrupt those launches with a brief reflection screen ("Do you really need it now?") with a cooldown timer (1 / 3 / 5 / 10 minutes).

The app is Android-only, account-free, fully on-device, free, and contains no telemetry, no analytics, no advertising, and no backend.

## 2. Why Not To-Do List uses the AccessibilityService API

Not To-Do List uses the AccessibilityService API for one purpose only: to detect when the user has foregrounded an app on their own Not-To-Do List, so the app can immediately display its reflection screen.

**What the service does, mechanically:**
- Listens only to `AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED` events.
- For each such event, reads `event.getPackageName()`.
- If the package name is in the user's Not-To-Do List (a list the user explicitly created), the service launches the app's own `PauseActivity` (a standard Android Activity) which displays the reflection screen.
- If the package name is not in the list, the event is ignored and discarded.

**What the service NEVER does:**
- Never calls `performAction()`.
- Never calls `performGlobalAction()`.
- Never calls `dispatchGesture()`.
- Never reads on-screen text content; the service does not set `canRetrieveWindowContent`.
- Never intercepts key events; the service does not set `flagRequestFilterKeyEvents`.
- Never performs gestures; the service does not set `canPerformGestures`.
- Never automates UI on the user's behalf, in any form.
- Never sends any data off the device. The package name is read, matched in memory, and discarded; nothing is logged, stored long-term, transmitted, or shared.
- Never operates as an "accessibility tool"; `isAccessibilityTool="false"` is set in the service configuration. We are not assistive technology.

The user remains in full control at every moment. They can dismiss the reflection screen at any time, choose "Use anyway" to bypass it, or wait for the cooldown to expire. They can disable the AccessibilityService from the system Settings at any time; the app continues to function (without launch interception) using only their daily self-report check-ins.

## 3. Why no narrower API works

Android's `UsageStatsManager` provides historical aggregate usage data (per-app foreground time bucketed by day or hour), but does NOT provide a real-time signal when an app foregrounds. Its data lags by a minimum of approximately 2.5 seconds and aggregates by interval. By the time `UsageStatsManager` reports that Instagram has been foregrounded, the user has already started scrolling — the entire reflective intervention has been bypassed.

The deprecated `getRunningTasks()` API was restricted in API level 21 and now only returns the caller's own tasks; it cannot be used to detect another app's foregrounding.

The AccessibilityService API is the only Android API that delivers a synchronous, sub-second signal when the foreground window changes, which is mandatory for the reflection-screen feature to be useful at all.

## 4. Disclosure and consent

The user is shown a dedicated full-screen "Accessibility Service" disclosure inside the app, separate from the Privacy Policy and any Terms of Service, before the system Settings deep-link. The disclosure:

- Describes in plain language exactly what data is accessed (the package name of the foreground app, only when a window-state-changed event fires).
- Describes what the service does (compares the package name to the user's Not-To-Do List; shows the reflection screen if it matches).
- Describes what the service never does (the list in section 2 above).
- States that no data leaves the device.
- Requires an explicit user tap ("I understand — open Settings") to proceed to the system Settings page where the user must manually enable the service.

The user can revoke the AccessibilityService permission at any time via the system Settings. The app monitors the enabled-services list on every foreground and shows an in-app banner ("Tracking offline — fix") when the service is no longer enabled.

## 5. Data Safety form alignment

This declaration is consistent with `docs/data-safety.md` and the Play Console Data Safety form:
- Data collected: NONE.
- Data shared: NONE.
- Data is processed: ONLY ON THE USER'S DEVICE.
- Encryption in transit: NOT APPLICABLE (no transmission).
- Data deletion: USER CAN RESET ALL DATA FROM IN-APP SETTINGS.

The Data Safety form is verifiable against the dependency tree: the project ships no Firebase, no FCM, no Crashlytics, no Google Analytics, no Amplitude, no Mixpanel, no Segment, no Sentry, and no other third-party SDK that transmits data. See the dependency-tree audit in `docs/data-safety.md`.

## 6. Manifest and configuration cross-reference

| Claim above | Verified by |
|-------------|-------------|
| `isAccessibilityTool="false"` | `android/app/src/main/res/xml/not_todo_a11y_config.xml` |
| `accessibilityEventTypes="typeWindowStateChanged"` only | same file |
| `canPerformGestures` not set | same file (attribute is absent) |
| `canRetrieveWindowContent` not set | same file (attribute is absent) |
| `flagRequestFilterKeyEvents` not set | same file (attribute is absent inside `accessibilityFlags`) |
| Service never calls `performAction` / `performGlobalAction` / `dispatchGesture` | source code in `android/app/src/main/kotlin/.../service/NotToDoAccessibilityService.kt` (Phase 4) |
| No `SYSTEM_ALERT_WINDOW` | `AndroidManifest.xml` (permission absent) |
| No `QUERY_ALL_PACKAGES` | `AndroidManifest.xml` uses `<queries>` + LAUNCHER intent filter instead |
| No telemetry / FCM / analytics | `pubspec.yaml` dependency tree |
