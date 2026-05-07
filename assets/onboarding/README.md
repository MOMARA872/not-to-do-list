# Onboarding screenshot assets

These 3 PNGs are **PLACEHOLDERS** that ship in Phase 2.

Replace each with a real captured Settings screenshot from a Pixel device
running stock Android 16 BEFORE Phase 6 PLAY-08 closed-track submission.

| File | Captures the Settings screen the user lands on after tapping the step's CTA |
|------|-----------------------------------------------------------------------------|
| `usage_access_step.png` | `Settings.ACTION_USAGE_ACCESS_SETTINGS` — Apps with usage access list |
| `accessibility_step.png` | `Settings.ACTION_ACCESSIBILITY_SETTINGS` — Accessibility services list |
| `battery_opt_step.png` | `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` confirmation dialog |

Capture instructions:
1. Boot a Pixel emulator or physical device running stock Android 16.
2. Trigger each `Intent` from the in-app onboarding flow.
3. `adb shell screencap -p > <name>.png`.
4. Crop to 9:16 portrait, max 1080×1920 logical px.
5. Replace the placeholder PNG with the new asset.

License: All Settings screenshots are factual representations of the
Android user interface; no third-party trademark concern. (Brand logos
in `../logos/` are a separate question — see 02-PATTERNS.md Open Pattern
Risk #5.)

Phase 2 placeholder format: 1×1 transparent PNG. Plan 02-08's
`RationaleScreen` widget uses an `errorBuilder` that renders a neutral
surfaceContainer placeholder if asset load fails; a 1×1 transparent PNG
renders cleanly via `Image.asset` without error so layout reserves
space correctly.

Tracked replacement task: Phase 6 PLAY-08 closed-track submission.
