# Phase 6: Polish & Play Store Submission - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-24
**Phase:** 6-polish-play-store-submission
**Areas discussed:** Settings hub IA & entry, Theme switcher UX (SETT-04), Export shape (SETT-01), Reset + Play submission gates (SETT-02 + PLAY-08 + SETT-05)

---

## Settings hub IA & entry

### Q1 — Entry point on Home

| Option | Description | Selected |
|--------|-------------|----------|
| AppBar gear icon, top-right (Recommended) | `HomeScreen.AppBar.actions` adds `IconButton(Icons.settings)` routing to `/settings`. Material 3 convention; zero competition with per-entry cards; no bottom nav. | ✓ |
| Floating Settings card above entries | Sits alongside `Avoided today` / `Total avoided` cards. Competes with Phase 3 dashboard cards for visual weight; violates Phase 4 calm-tone lock. | |
| Drawer (hamburger menu) | Standard MaterialApp drawer. More room for future groups but adds a top-level nav pattern v1 doesn't use elsewhere. | |

**User's choice:** AppBar gear icon, top-right (Recommended)
**Notes:** Single-pane Home preserved (Phase 2 lock).

### Q2 — Settings screen architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Sectioned ListView with M3 list tiles (Recommended) | Single scrollable `/settings` grouped under headers: `Reminder`, `Streak`, `Appearance`, `Data`, `Privacy`, `About`. Mixed tile types (nav / inline / action). | ✓ |
| Flat unsectioned list | One list, no headers. Loses structure as items grow. | |
| Tabbed Settings (General / Data / Privacy) | Overkill for ~8 items. | |

**User's choice:** Sectioned ListView with M3 list tiles (Recommended)

### Q3 — Which Settings tiles ship in v1 (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| Reminder time (re-uses existing `/settings/reminder`) | Existing screen behind nav tile. Subtitle: current time formatted. | ✓ |
| Streak threshold (global minutes/day) | Phase 5 D-08 lock — surfaces existing `streak_threshold_minutes` shared_pref. | |
| Appearance — Theme (Light/Dark/System) | SETT-04. Inline radio row, no push. | ✓ |
| Export data + Reset data + Privacy Policy + Accessibility disclosure + Version/About | Bundle: SETT-01 + SETT-02 + SETT-05 + Disclosure (re-use `accessibility_step.dart`) + `package_info_plus` About tile. | ✓ |

**User's choice:** Reminder + Appearance + Data/Privacy/Disclosure/About bundle. Streak threshold NOT selected.
**Notes:** Streak threshold tile excluded from v1 list. Phase 5 D-08 promised this; surfaced as Claude's Discretion in CONTEXT.md (planner decides: minimal inline row vs formal v1.x defer). If formally deferred, 06-VERIFICATION.md must document the broken Phase 5 D-08 promise.

### Q4 — Settings tile ordering top-down

| Option | Description | Selected |
|--------|-------------|----------|
| Reminder → Streak → Appearance → Data → Privacy → About (Recommended) | Most-touched at top (daily-use config). Destructive Data below behavioral config. Privacy + About at bottom. | ✓ |
| Privacy → Data → Appearance → Reminder → Streak → About | Privacy-forward; friendlier to Play reviewers but pushes daily-use below the fold. | |
| About → Privacy → Appearance → Reminder → Streak → Data | iOS-Settings style; unusual on Android. | |

**User's choice:** Reminder → Streak → Appearance → Data → Privacy → About (Recommended)
**Notes:** Streak section omitted since Streak threshold tile wasn't selected. Effective v1 order: Reminder → Appearance → Data → Privacy → About.

---

## Theme switcher UX (SETT-04)

### Q1 — Selector widget

| Option | Description | Selected |
|--------|-------------|----------|
| M3 SegmentedButton 3-segment inline (Recommended) | `[Light | Dark | System]` segmented row directly on Settings. Single tap. M3 standard for 2–4 mutually exclusive options. | ✓ |
| Radio ListTile rows inline | Verbose for 3-option choice. Adds visual height. | |
| Push to `/settings/appearance` subscreen | Overkill for one setting. | |

**User's choice:** M3 SegmentedButton 3-segment inline (Recommended)

### Q2 — Default on first install / post-reset

| Option | Description | Selected |
|--------|-------------|----------|
| System (follow device) (Recommended) | `ThemeMode.system`. Honors OS-level dark mode. Matches dynamic_color expectation. | ✓ |
| Light | Override device dark mode. Inconsistent with Android UX. | |
| Dark | Force dark by default. Disrespects user's system choice. | |

**User's choice:** System (follow device) (Recommended)

### Q3 — Persistence + provider shape

| Option | Description | Selected |
|--------|-------------|----------|
| shared_preferences `theme_mode` int + Riverpod `themeModeProvider` watched in `app.dart` (Recommended) | Mirrors `reminder_hour_minute` int-pattern (Phase 5 D-09). Survives app restart; fast cold-start read. | ✓ |
| Drift `app_settings` key-value table | Heavier; overkill for one int. | |
| In-memory only | Resets on restart — unacceptable. | |

**User's choice:** shared_preferences `theme_mode` int + Riverpod `themeModeProvider` (Recommended)

### Q4 — Interaction with `dynamic_color` (Material You)

| Option | Description | Selected |
|--------|-------------|----------|
| Theme selector controls brightness only; dynamic_color seed still wins (Recommended) | User picks brightness; color seed still from `DynamicColorBuilder` with existing `seedColor` fallback. | ✓ |
| Theme selector forces app theme + ignores dynamic_color entirely | More predictable but loses Material You. | |
| Add color-seed picker too | Out of scope. | |

**User's choice:** Theme selector controls brightness only; dynamic_color seed still wins (Recommended)

---

## Export shape (SETT-01)

### Q1 — Packaging

| Option | Description | Selected |
|--------|-------------|----------|
| Single `.zip` archive via one `ACTION_CREATE_DOCUMENT` pick (Recommended) | `not-to-do-list-export-YYYYMMDD-HHMM.zip` with CSV + JSON inside. One tap, atomic. Pure-Dart `archive` package (~50 KB). | ✓ |
| Two separate file picks | More friction; two SAF intents; breaks pairing. | |
| User chooses format on Export screen | More UI for power users; default "give me everything" is enough. | |

**User's choice:** Single `.zip` archive via one `ACTION_CREATE_DOCUMENT` pick (Recommended)

### Q2 — CSV layout

| Option | Description | Selected |
|--------|-------------|----------|
| One CSV per Drift table (5 files) (Recommended) | `block_list.csv`, `daily_checkins.csv`, `daily_streak.csv`, `pause_events.csv`, `daily_usage_summary.csv`. Header = Drift columns verbatim. Round-trippable. | ✓ |
| Single denormalized CSV | Lossy for timeseries. | |
| CSV-per-table + joined `summary.csv` | Adds derived aggregation logic + tests for marginal value. | |

**User's choice:** One CSV per Drift table (5 files) (Recommended)

### Q3 — JSON schema

| Option | Description | Selected |
|--------|-------------|----------|
| Envelope `{schemaVersion: 1, exportedAt, appVersion, tables: {...}}` (Recommended) | Versioned, future-proof for M2 import-restore. Single `data.json` inside ZIP. | ✓ |
| Flat array of mixed-type records | Smaller but loses schema clarity. | |
| One JSON file per table | Duplicates index; envelope is cleaner. | |

**User's choice:** Envelope `{schemaVersion: 1, exportedAt, appVersion, tables: {...}}` (Recommended)

### Q4 — Timestamp format + filename

| Option | Description | Selected |
|--------|-------------|----------|
| ISO-8601 UTC + filename `not-to-do-list-export-YYYYMMDD-HHMM.zip` (Recommended) | UTC avoids tz ambiguity; filename has local-time date for user clarity. | ✓ |
| Epoch millis | Unreadable in Excel without conversion. | |
| Local-time ISO without `Z` suffix | Loses timezone info; dangerous for re-import. | |

**User's choice:** ISO-8601 UTC + filename `not-to-do-list-export-YYYYMMDD-HHMM.zip` (Recommended)

---

## Reset + Play submission gates (SETT-02 + PLAY-08 + SETT-05)

### Q1 — Reset confirmation gate

| Option | Description | Selected |
|--------|-------------|----------|
| Two-step: tap Reset → `AlertDialog` with destructive button + body listing what gets deleted (Recommended) | Body: "This deletes every entry, streak day, pause event, and check-in. This cannot be undone." Cancel default-focused. Calm tone. | ✓ |
| Type-to-confirm `RESET` | Ceremonial / punitive for a self-control reset flow. | |
| Hold-to-confirm 3s | Obscure; motor-accessibility concerns. | |

**User's choice:** Two-step `AlertDialog` (Recommended)

### Q2 — Post-reset destination + scope

| Option | Description | Selected |
|--------|-------------|----------|
| Wipe Drift + shared_preferences (incl. onboarding-complete) → route to `/onboarding/welcome` (Recommended) | True clean slate. Permissions stay granted (system-level). | ✓ |
| Wipe Drift only, keep shared_preferences → empty Home | Confusing — user expects "reset" = fresh start. | |
| Wipe Drift + reminder/theme prefs but keep onboarding-complete → empty Home | Half-measure. | |

**User's choice:** Wipe Drift + shared_preferences → route to `/onboarding/welcome` (Recommended)

### Q3 — Play release track strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Internal testing → Closed testing → stop (Recommended) | Internal first (up to 100 testers, instant) shakes out config + Data Safety + listing copy. Closed (5–20 named) triggers real Play policy review on AccessibilityService declaration. v1 stops here. | ✓ |
| Internal → Closed → Open beta | Open beta conflicts with v1 "validate the wedge with 100 users" goal. | |
| Closed only (skip internal) | Loses the dry-run for listing/Data Safety mistakes. | |

**User's choice:** Internal testing → Closed testing → stop (Recommended)

### Q4 — Privacy Policy hosting + Data Safety verification

| Option | Description | Selected |
|--------|-------------|----------|
| Static PRIVACY.md on GitHub Pages + in-app screen + APK-grep test (Recommended) | Single source of truth: `PRIVACY.md` → GitHub Pages public URL. In-app screen renders same Markdown. Extend `test/policy/play_invariants_test.dart` with absence-grep for `firebase`/`crashlytics`/`analytics`/`FCM`/`RemoteConfig` across pubspec.lock + Dart + Kotlin + decoded APK. | ✓ |
| In-app screen only (no public URL) | Play Console requires a public URL — rejected by policy. | |
| Hosted URL only (no in-app screen) | SETT-05 requires in-app linkage. | |

**User's choice:** Static PRIVACY.md on GitHub Pages + in-app screen + APK-grep test (Recommended)

---

## Claude's Discretion

- **Streak threshold Settings UI** — Phase 5 D-08 promised a Settings → Streak section with a global `streak_threshold_minutes` field; Phase 5 shipped the provider but not the UI; user excluded the tile in Q3 of Settings IA discussion. Planner decides: (a) close the Phase 5 D-08 promise with a minimal inline Streak section row in Phase 6, or (b) formally defer to v1.x and document the broken promise in 06-VERIFICATION.md. Recommendation in CONTEXT.md is (a).
- **`flutter_markdown` vs pre-rendered string constant** for in-app Privacy Policy renderer — both fine; planner picks based on dep-weight preference.
- **`archive` package vs hand-rolled ZIP writer** — pure-Dart `archive` is the obvious choice; mention so it isn't re-litigated.
- **`package_info_plus` for About tile** — standard plugin; no alternatives.
- **GitHub Pages setup mechanics** — out of code scope but planner adds a checklist task.
- **Internal testing tester list seeding** — planner adds checklist task to add developer's Google account.
- **Listing copy + screenshot capture (`docs/play-listing/`)** — planner generates the directory with short desc (80c), full desc (4000c), 2 phone screenshots (real Pixel captures replacing 8 placeholders), 1 feature graphic (1024x500).

## Deferred Ideas

- Global Streak threshold Settings tile (numeric slider/field) — pending Claude's Discretion above
- Per-entry streak threshold override UI — Phase 5 deferred to v1.x; remains deferred
- Color-seed picker (Material You custom seed override) — out of SETT-04 scope; M2 if at all
- Export user-format chooser (CSV-only / JSON-only / Both) — single ZIP default is enough; v1.x if power users ask
- Type-to-confirm `RESET` text-entry — rejected as ceremonial
- Hold-to-confirm 3s Reset button — rejected for motor-accessibility
- Drift-only reset (keep shared_preferences) — rejected; full clean slate cleaner
- Production / open-beta release track in v1 — v1 STOPS at closed-track PASS
- In-app Privacy Policy as sole source (no public URL) — rejected by policy
- Import / restore from export — out of scope for v1; export-only
- App icon redesign / branding pass — uses existing icon + replaces 8 placeholder PNGs only
- Translations / i18n — v1 English-only; v1.x or M2
- In-app feedback / contact form — privacy + on-device + no backend = none in v1
- Crash reporting / analytics opt-in — explicit PROJECT.md anti-feature
- Onboarding step for Theme selection — Phase 2 lock; default System
- Streak-aware notification copy / streak sharing / leaderboards / badges / gamification — explicit PROJECT.md anti-features
