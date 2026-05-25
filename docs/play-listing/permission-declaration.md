# Play Console Permission Declaration — AccessibilityService

This file contains the text for the Play Console "Use of the AccessibilityService API"
Permission Declaration form (sections 1–4). Copy each section into the corresponding
form field verbatim.

Source of truth: `docs/play-declaration.md` (Phase 1). This file reshapes sections 1–4
for direct paste into the Play Console form fields.

---

## 1. Core feature description

Not To-Do List helps adults stick to self-defined avoidance goals — apps and habits they
have explicitly chosen to use less or not at all. The user creates their own
"Not-To-Do List" and asks the app to interrupt those launches with a brief reflection
screen ("Do you really need it now?") with a cooldown timer (1 / 3 / 5 / 10 minutes).

The app is Android-only, account-free, fully on-device, free, and contains no telemetry,
no analytics, no advertising, and no backend.

---

## 2. Usage justification

**Category:** App functionality

Not To-Do List uses the AccessibilityService API for one purpose only: to detect when
the user has foregrounded an app on their own Not-To-Do List, so the app can immediately
display its reflection screen.

What the service does, mechanically:
- Listens only to `AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED` events.
- For each such event, reads `event.getPackageName()`.
- If the package name is in the user's Not-To-Do List (a list the user explicitly
  created), the service launches the app's own `PauseActivity` which displays the
  reflection screen.
- If the package name is not in the list, the event is ignored and discarded.

What the service NEVER does:
- Never calls `performAction()`, `performGlobalAction()`, or `dispatchGesture()`.
- Never reads on-screen text content; `canRetrieveWindowContent` is not set.
- Never intercepts key events; `flagRequestFilterKeyEvents` is not set.
- Never automates UI on the user's behalf in any form.
- Never sends any data off the device. The package name is read, matched in memory,
  and discarded; nothing is logged, stored long-term, transmitted, or shared.
- Never operates as an "accessibility tool"; `isAccessibilityTool="false"` is set.

The AccessibilityService API is the only Android API that delivers a synchronous,
sub-second signal when the foreground window changes. Android's `UsageStatsManager`
lags by a minimum of approximately 2.5 seconds and aggregates by interval — by the
time it reports that an app foregrounded, the user has already started using it. The
reflection-screen feature requires the real-time window-state signal.

---

## 3. Data collection through accessibility

**No.**

The AccessibilityService reads only `event.getPackageName()` from
`TYPE_WINDOW_STATE_CHANGED` events. This value is checked against the user's in-memory
list and immediately discarded — it is never logged, persisted, transmitted, or shared.
No other fields from any AccessibilityEvent are read. The service does not read on-screen
content, user-input data, text fields, clipboard data, or any other user data.

---

## 4. Demonstration video URL

**[TODO: insert YouTube unlisted URL after recording per 06-VERIFICATION.md]**

The video must show:
1. Cold launch of Not To-Do List from the home screen.
2. The in-app "Accessibility Service" prominent-disclosure screen appearing before the
   system Settings deep-link (PLAY-06 compliance — Phase 2).
3. The user tapping "I understand — open Settings" to proceed to Android Accessibility
   Settings.
4. The user enabling the Not To-Do List Accessibility Service.
5. The user opening Instagram (or another app on their Not-To-Do List).
6. The pause reflection screen ("Do you really need it now?") appearing within 1 second.
7. The user either starting the cooldown timer or choosing "Use anyway" to dismiss.

Recommended length: 30–60 seconds.
Upload as YouTube unlisted (not private — Play Console reviewers must be able to view it).
