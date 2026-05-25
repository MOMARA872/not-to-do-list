# Screenshot Capture Checklist — Play Console

Capture the following assets before submitting to Play Console.
All screenshots must be captured in portrait orientation.

---

## Phone Screenshots (minimum 2 required)

**Specifications:**
- Minimum size: 320px on the short side
- Maximum size: 3840px on the long side
- Recommended: 1080x1920 or higher
- Format: JPEG or 24-bit PNG (no alpha)
- Orientation: portrait

### Screenshot 1 — Home screen

**File:** `screenshot-home.png`

Capture the HomeScreen showing:
- At least 2–3 not-to-do entries in the list (e.g., Instagram, TikTok, Reddit)
- StreakBadge visible for at least one entry (showing a streak count)
- The "Avoided today" summary card at the top
- The Settings gear icon in the AppBar (top left)
- The notification bell icon in the AppBar (top right)

Capture on Pixel emulator or physical Pixel device running stock Android 16, portrait.

### Screenshot 2 — Pause screen

**File:** `screenshot-pause.png`

Capture the PauseScreen showing:
- The reflection prompt at the top ("Do you really need it now?" or similar)
- An entry name visible (e.g., "Instagram")
- The cooldown timer selector (1 / 3 / 5 / 10 min options)
- The "Use anyway" button (for soft-block entries) or the cooldown start button

Capture on Pixel emulator or physical Pixel device running stock Android 16, portrait.
Trigger the pause screen by opening a listed app from an emulator with the
AccessibilityService enabled, OR by navigating directly in the app for a staged capture.

---

## Feature Graphic (1 required)

**Specifications:**
- Size: exactly 1024x500 px
- Format: JPEG or 24-bit PNG (no alpha)
- Orientation: landscape

**File:** `feature-graphic-1024x500.png`

Suggested composition:
- App name "Not To-Do List" in a calm, readable font
- A subtle visual representation of the pause concept (pause symbol, reflection moment)
- The tagline: "A moment of pause before the scroll" or similar calm-tone copy
- Background: use the app's Material 3 surface color (no aggressive contrast)
- No text smaller than ~18pt (readability at Play Store thumbnail size)

---

## Upload checklist

Before uploading to Play Console:

- [ ] screenshot-home.png — 1080x1920 or larger, portrait
- [ ] screenshot-pause.png — 1080x1920 or larger, portrait
- [ ] feature-graphic-1024x500.png — exactly 1024x500

See `docs/play-listing/README.md` for the field-to-file mapping.
