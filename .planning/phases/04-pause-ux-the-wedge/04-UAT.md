---
status: partial
phase: 04-pause-ux-the-wedge
source: [04-01-SUMMARY.md, 04-02-SUMMARY.md, 04-03-SUMMARY.md, 04-04-SUMMARY.md, 04-05-SUMMARY.md, 04-06-SUMMARY.md, 04-07-SUMMARY.md, 04-08-SUMMARY.md]
started: 2026-05-15T13:39:00-07:00
updated: 2026-05-17T00:00:00-07:00
---

## Current Test

number: 16
name: REL-04 Overnight Survival
expected: |
  On a Samsung-class device, after ≥8h idle (overnight, screen off, no foreground use), opening a blocked app still triggers pause within <500ms (REL-04 OEM-survival protocol).
awaiting: physical-device overnight run (S20 Ultra, debug APK installed, force-idle Doze, morning stopwatch measurement)

## Tests

### 1. Open Blocked App Triggers Pause Screen
expected: With at least one app on the not-to-do list and Accessibility Service granted, opening that app brings the Pause screen to the foreground within ~1 second. The blocked app is interrupted before user can interact with it.
result: pass

### 2. Reason Hero Renders for Entry With Reason
expected: When the not-to-do entry has a reason note, the Pause screen shows the reason as an italic/serif quote-card hero at the top (ReasonHero).
result: pass

### 3. App-Name Hero Renders for Empty Reason
expected: When the not-to-do entry has no reason note, the Pause screen shows the app display name (with trailing period) in DisplayMedium as the hero (AppNameHero) instead of the reason card.
result: pass

### 4. Cooldown Chips Visible
expected: Pause screen shows a Material 3 SegmentedButton row with four chips labeled 1m / 3m / 5m / 10m, no default selection.
result: pass

### 5. Tap Chip Starts Cooldown Countdown
expected: Tapping a cooldown chip (e.g. 1m) starts a countdown: LinearProgressIndicator advances and an X:XX caption ticks down. Chip row becomes locked to the selected duration.
result: pass

### 6. Cooldown Complete Confirmation Card
expected: When the chosen cooldown elapses, screen shows "✓ Cooldown complete" Card briefly (~1.5s), then pause screen closes (returns to launcher).
result: pass

### 7. Cancel Button Closes Pause
expected: Tapping Cancel closes the pause screen immediately, returns to launcher. A pause_events row with outcome=1 (cancel) is recorded.
result: pass

### 8. Use-Anyway Button on Soft Block
expected: On a soft-blocked entry, "Use anyway" button is visible alongside Cancel (asymmetric layout). Tapping it closes pause and returns to the blocked app. A pause_events row with outcome=2 is recorded. Button is tappable immediately (no cooldown gate).
result: pass

### 9. Hard Block Omits Use-Anyway
expected: On a hard-blocked entry (blockMode=hard), the "Use anyway" button is entirely absent from the screen — only Cancel is shown.
result: pass

### 10. Schedule Window Gate Honored
expected: With an entry that has a schedule window, opening the blocked app OUTSIDE the scheduled window does NOT trigger the pause screen. INSIDE the window, pause fires normally.
result: pass

### 11. Pause Appears Over Lock Screen
expected: With the device locked, opening (or triggering) a blocked app turns the screen on and shows the Pause screen above the lock screen — no need to unlock first.
result: pass

### 12. Pause Cold-Start Feels Fast
expected: Pause activity appears with no perceptible lag from blocked-app launch (target <300ms via pre-warmed FlutterEngine cache key "pause_engine"). No white-flash or engine-init stutter.
result: pass

### 13. Blocklist Edits Propagate to Service
expected: Add a new entry from the app, return to launcher, open the newly-blocked app — pause fires for it without restarting the service. Removing an entry stops it from triggering pause on next launch.
result: pass

### 14. 800ms Debounce on Same Package
expected: After closing pause, immediately re-entering the same blocked app within 800ms does NOT re-trigger another pause screen. After 800ms, re-entry triggers pause again.
result: pass

### 15. Health Banner Reflects Accessibility State
expected: With Accessibility Service ENABLED in system settings, the in-app health banner shows the service as granted/healthy. Disable the service in settings, return to app — banner flips to warning state.
result: pass

### 16. REL-04 Overnight Survival
expected: On a Samsung-class device, after ≥8h idle (overnight, screen off, no foreground use), opening a blocked app still triggers pause within <500ms (REL-04 OEM-survival protocol).
result: [pending]
note: "Reverted from premature pass on 2026-05-17 — overnight run not executed; VERIFICATION.md still shows rel_04_status: pending_overnight_run. Awaiting S20 Ultra USB-debug authorization + morning stopwatch measurement (physical device required)."

## Summary

total: 16
passed: 15
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps

[none yet]
