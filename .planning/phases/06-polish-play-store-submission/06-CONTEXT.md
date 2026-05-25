# Phase 6: Polish & Play Store Submission - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning
**Source:** /gsd-discuss-phase 6 (interactive — 4 of 4 gray areas discussed; 16 sub-questions)

<domain>
## Phase Boundary

Phase 6 is the **final-mile polish + Play Store closed-track submission** of v1. It delivers the Settings hub (the user's single management surface), wires the four remaining SETT-* requirements (Export, Reset, Theme, Privacy/Disclosure links), and walks the closed-track submission funnel through Play Console without rejection on AccessibilityService declaration, `<queries>` policy, or Data Safety mismatch.

Concrete deliverables (SETT-01, SETT-02, SETT-04, SETT-05, PLAY-08):

1. **Settings hub** — new `/settings` GoRoute with sectioned ListView (Material 3 list tiles), entered via an `AppBar` gear icon on `HomeScreen`. Tile order (top-down): **Reminder → Appearance → Data → Privacy → About**. The Reminder tile re-uses the existing `/settings/reminder` screen (Phase 5 Plan 05-08); every other tile is new. Calm tone carry-forward from Phase 4 D-07.

2. **Theme switcher (SETT-04)** — inline M3 `SegmentedButton` `[Light | Dark | System]` rendered directly on the Settings → Appearance row (no subscreen push). Default = `ThemeMode.system`. Selector controls **brightness only**; the existing `DynamicColorBuilder` (Material You) seed in `app.dart` still wins for color when available, with the existing static `seedColor` fallback. Persisted as a single int (0=system, 1=light, 2=dark) under `shared_preferences` key `theme_mode` (mirrors `reminder_hour_minute` pattern from Phase 5 D-09); exposed via Riverpod `themeModeProvider` watched by `MaterialApp.router` in `lib/app.dart`.

3. **Export data (SETT-01)** — single `ACTION_CREATE_DOCUMENT` pick writes one `.zip` archive named `not-to-do-list-export-YYYYMMDD-HHMM.zip` (local-time date for human clarity). Archive contents: five per-table CSVs (`block_list.csv`, `daily_checkins.csv`, `daily_streak.csv`, `pause_events.csv`, `daily_usage_summary.csv`) — header row = Drift column names verbatim, foreign keys via `entryId` — plus one `data.json` envelope `{schemaVersion: 1, exportedAt, appVersion, tables: {block_list: [...], ...}}`. All timestamps ISO-8601 UTC (`2026-05-24T17:30:00Z`) in both CSV string columns and JSON. Uses pure-Dart `archive` package (~50 KB).

4. **Reset all data (SETT-02)** — two-step destructive confirmation: tap Reset → M3 `AlertDialog` listing what gets deleted ("This deletes every entry, streak day, pause event, and check-in. This cannot be undone."), Cancel default-focused, calm tone (no scare copy). Scope: wipe Drift (every entry, streak day, pause event, check-in, daily usage summary row) AND wipe `shared_preferences` (incl. the onboarding-complete flag) → route to `/onboarding/welcome` for a true clean-slate re-walk. Permissions stay granted (system-level, not app data). Cascades follow LIST-05 pattern (deletion already cascades streak history + pause-event log per Phase 2 Plan 02-04).

5. **Privacy Policy + Accessibility disclosure (SETT-05)** — single source of truth = `PRIVACY.md` in repo, auto-published to GitHub Pages (public URL declared in Play Console Data Safety form). In-app Privacy screen renders the same Markdown (via `flutter_markdown` or pre-rendered string constant). Accessibility disclosure tile re-uses the existing `accessibility_step.dart` copy from Phase 2 Plan 02-08 (the five verbatim phrases enforced by source-grep test) — no new copy; same screen, reachable from both onboarding and Settings.

6. **Data Safety zero-collection proof** — extend `test/policy/play_invariants_test.dart` with new absence-grep invariants for `firebase`, `crashlytics`, `analytics`, `FCM`, `RemoteConfig` across `pubspec.lock`, Dart sources, Kotlin sources, AND decoded release APK (`unzip -p app-release.apk classes.dex | strings | grep`). Pre-submit gate. Locks Phase 6 as the "no telemetry by structural enforcement" phase.

7. **Play Console closed-track submission (PLAY-08)** — release-track strategy: **Internal testing (up to 100 testers, instant review)** dry-run first to shake out config + Data Safety + listing copy with solo developer; then **Closed testing** (5–20 named testers) which triggers the real Play policy review on AccessibilityService declaration. v1 STOPS at closed-track PASS. Open beta / production is post-validation (M2 / v1.1 territory). Real-device screenshot capture replaces the 8 placeholder PNGs in `assets/onboarding/` + `assets/logos/`. Play App Signing (default). First version: `1.0.0+1`.

**Exit gate (success criterion 5):** Full happy-path overnight on a real Xiaomi AND a real Samsung device — onboarding → list add → blocked-app launch → pause → cooldown → streak roll-over → reminder fire. This is the **REL bookend** to Phase 4 REL-04 (Samsung PASS 2026-05-21) and Phase 5 REL-05 (pending overnight gate); Phase 6 does NOT introduce a new REL-XX requirement but the OEM-survival end-to-end run is the prerequisite to typing "ready to submit" in Play Console.

</domain>

<decisions>
## Implementation Decisions

### Settings hub IA & entry (D-01..04)

- **D-01 — Entry point: AppBar gear icon on `HomeScreen`.** `IconButton(Icons.settings)` added to `HomeScreen.AppBar.actions` routing to `/settings`. No bottom nav (Phase 2 lock — Home stays single-pane). No drawer (no precedent elsewhere in app). No floating Settings card (would compete with Phase 3 dashboard cards for visual weight; violates Phase 4 calm-tone lock).

- **D-02 — Architecture: single scrollable `/settings` screen with sectioned ListView + M3 list tiles.** Headers: `Reminder`, `Appearance`, `Data`, `Privacy`, `About`. Tile types: navigation (push subscreen), inline (theme segmented button, Reminder time subtitle), action (Reset destructive). No tabs (overkill for ~7 tiles), no flat-unsectioned (loses structure for future items).

- **D-03 — v1 Settings tiles (locked):** Reminder time (re-uses `/settings/reminder` from Phase 5 Plan 05-08), Appearance → Theme (Light/Dark/System inline), Export data (push to `/settings/export`), Reset data (destructive action), Privacy Policy (push to `/settings/privacy`), Accessibility disclosure (push to `/settings/disclosure` reusing `accessibility_step.dart` copy), Version/About (tile shows `package_info_plus` version + build). **NOT shipping in v1:** global Streak threshold tile — see Deferred Ideas (Phase 5 D-08 lock for the streak threshold setting carries forward as a Claude's-Discretion question that the planner must resolve — see Claude's Discretion below).

- **D-04 — Tile order (top-down):** Reminder → Appearance → Data (Export, Reset) → Privacy (Privacy Policy, Accessibility disclosure) → About. Most-touched daily-use config at top; destructive Data block below behavioral config; Privacy + About at bottom matches Play-policy-favored layout.

### Theme switcher (D-05..08)

- **D-05 — Selector widget: M3 `SegmentedButton` 3-segment inline `[Light | Dark | System]`.** Rendered directly on the Settings → Appearance row, no subscreen push. Single tap to switch. NOT radio rows (verbose for 3 options), NOT a separate `/settings/appearance` push (overkill for one setting).

- **D-06 — Default: `ThemeMode.system`** (follow device). Honors user's OS-level dark-mode setting. Matches dynamic_color expectation — when Material You is available, both seed and brightness track device.

- **D-07 — Persistence: shared_preferences `theme_mode` int (0=system, 1=light, 2=dark) + Riverpod `themeModeProvider` watched in `app.dart`.** Mirrors `reminder_hour_minute` int-pattern from Phase 5 D-09. `MaterialApp.router` reads `ref.watch(themeModeProvider)` and passes to its `themeMode:` field. Survives app restart; fast read on cold start. NOT Drift `app_settings` table (heavier — schema migration + DAO + stream for a single int).

- **D-08 — Dynamic_color interaction: theme selector controls brightness ONLY; `dynamic_color` seed still wins when available.** User picks Light / Dark / System; color seed continues to come from `DynamicColorBuilder` (Android 12+) with the existing static `seedColor` fallback. Cleanest split — SETT-04 spec only requires brightness, not color customization. No color-seed picker (M2 territory).

### Export shape (D-09..12)

- **D-09 — Packaging: single `.zip` archive via one `ACTION_CREATE_DOCUMENT` pick.** Filename: `not-to-do-list-export-YYYYMMDD-HHMM.zip` (local-time date for human clarity). User picks one location; app writes atomically. Uses pure-Dart `archive` package (~50 KB). NOT two separate file picks (more friction, two SAF intents, breaks pairing). NOT user-chooses-format (more UI, no real value — default "give me everything" is the right product call).

- **D-10 — CSV layout: one CSV per Drift table (5 files): `block_list.csv`, `daily_checkins.csv`, `daily_streak.csv`, `pause_events.csv`, `daily_usage_summary.csv`.** Header row = Drift column names verbatim. Foreign keys via `entryId`. Round-trippable, schema-mirrored, opens cleanly in Excel/Sheets. Zero transformation logic. NOT denormalized single CSV (lossy for timeseries). NOT CSV-per-table + `summary.csv` (adds derived aggregation logic + tests for marginal value).

- **D-11 — JSON schema: envelope `{schemaVersion: 1, exportedAt: ISO-8601 UTC, appVersion: "1.0.0+1", tables: {block_list: [...], daily_checkins: [...], daily_streak: [...], pause_events: [...], daily_usage_summary: [...]}}`.** Single `data.json` file inside the ZIP next to the CSVs. Versioned via `schemaVersion: 1` — future-proof for M2 import-restore. Self-describing. NOT flat mixed-type array (loses schema clarity). NOT one JSON file per table (duplicates index; envelope is cleaner).

- **D-12 — Timestamp format: ISO-8601 UTC `2026-05-24T17:30:00Z`** in both CSV string columns and JSON. Filename uses local-time date for user clarity, but all content timestamps are UTC. NOT epoch millis (unreadable in Excel). NOT local-time ISO without `Z` (dangerous for re-import + DST analysis).

### Reset all data + Play submission (D-13..16)

- **D-13 — Reset gate: two-step `AlertDialog`.** Tap Reset on Settings → AlertDialog with destructive button + body listing what gets deleted: literal copy `"This deletes every entry, streak day, pause event, and check-in. This cannot be undone."` Cancel button default-focused. Calm tone, no scare copy ("Are you sure???"). NOT type-to-confirm `RESET` (ceremonial / punitive for a self-control reset flow). NOT hold-to-confirm 3s (obscure interaction; motor-accessibility concerns).

- **D-14 — Post-reset scope + destination: wipe Drift + shared_preferences (incl. onboarding-complete flag) → route to `/onboarding/welcome`.** True clean slate — re-enter the funnel like first install. Permissions stay granted (system-level, not app-data). User re-runs quick-add. NOT Drift-only wipe (confusing — user expects "reset" = fresh start). NOT hybrid (resets visible config but skips re-onboarding — half-measure).

- **D-15 — Play release track strategy: Internal testing → Closed testing → stop.** Internal first (up to 100 testers, instant review) — solo-developer dry-run to shake out config + Data Safety + listing copy. Then Closed testing (5–20 named testers) — triggers the real Play policy review on AccessibilityService declaration. v1 STOPS at closed-track PASS per PLAY-08. NOT Internal → Closed → Open beta (open beta conflicts with v1 "validate the wedge with 100 users" goal — better to control the funnel via closed). NOT closed-only (loses the dry-run for listing/Data Safety mistakes).

- **D-16 — Privacy Policy hosting + Data Safety verification: static `PRIVACY.md` on GitHub Pages + in-app screen renders the same Markdown + APK-grep absence test.** Single source of truth: `PRIVACY.md` in repo → GitHub Pages auto-publish to public URL (Play Console Data Safety requires a public URL — in-app alone fails policy). In-app Privacy screen renders the same Markdown via `flutter_markdown` (or pre-rendered string constant — planner's call). Data Safety verification: extend `test/policy/play_invariants_test.dart` with absence-grep for `firebase`, `crashlytics`, `analytics`, `FCM`, `RemoteConfig` across `pubspec.lock` + Dart sources + Kotlin sources + decoded release APK (`unzip -p app-release.apk classes.dex | strings | grep`). Pre-submit gate. SETT-05 requires in-app linkage — user must reach Privacy + Disclosure from Settings without leaving the app, hence both surfaces.

### Claude's Discretion (research / planner)

- **Streak threshold Settings UI.** Phase 5 D-08 promised "Single `streak_threshold_minutes` setting (default 5 per STRK-02), surfaced in Settings under `Streak`." Phase 5 shipped the provider (`lib/features/streak/providers/streak_threshold_provider.dart`) but not a Settings UI. Phase 6 user-selection excluded the Streak threshold tile from the v1 Settings list (D-03). The planner must decide: (a) close the Phase 5 D-08 promise by adding a minimal inline Streak section above Appearance with a number-field or slider — cost is small, honors Phase 5 lock; or (b) defer to v1.x and document the broken promise in 06-VERIFICATION.md + flip Phase 5's D-08 to deferred. Recommendation: (a) — Phase 5 D-08 is a soft lock and the field already exists, the UI is a single inline row. Surface this in the planner's first task.
- **`flutter_markdown` vs pre-rendered string constant for in-app Privacy Policy.** Both are fine. `flutter_markdown` adds ~80 KB and one transitive dep; pre-rendered constant requires a build step to re-stamp the in-app copy when `PRIVACY.md` changes. Planner picks based on dep-weight preference.
- **`archive` package vs hand-rolled ZIP writer.** Pure-Dart `archive` is the obvious choice (verified, small, widely used). Mention in planner so it isn't re-litigated.
- **`package_info_plus` for version surfacing in About tile.** Standard Flutter plugin. No alternatives worth comparing.
- **GitHub Pages setup mechanics.** Out of code scope but the planner should include a Plan task that writes `docs/PRIVACY.md` (or just `PRIVACY.md` at repo root) and a one-line README note on enabling GitHub Pages. The planner picks repo layout.
- **Internal testing tester list seeding.** Planner adds a checklist task to add the developer's own Google account as Internal tester (instant). No code.
- **Listing copy + screenshot capture.** Planner generates a `docs/play-listing/` directory with: short description (80 char), full description (4000 char), 2 phone screenshots (real Pixel captures replacing placeholders in `assets/onboarding/` + `assets/logos/`), one feature graphic (1024x500). Copy must be calm-tone consistent.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project & roadmap

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/PROJECT.md` — v1 product scope (adult self-control, on-device only, no telemetry, no FCM, calm tone, no gamification, Play Store rejection risk for AccessibilityService)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` § Phase 6 — goal + 5 success criteria + final-mile + closed-track gate
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` § SETT-01, SETT-02, SETT-04, SETT-05, PLAY-08 — 5 requirements scoped to this phase

### Play Store policy + Data Safety (locked since Phase 1)

- `/Users/jintanakhomwong/projects/not-to-do-list/docs/play-declaration.md` — literal mechanical AccessibilityService declaration copy, single source of truth for Play Console Permission Declaration form (PLAY-07)
- `/Users/jintanakhomwong/projects/not-to-do-list/docs/data-safety.md` — Data Safety form draft (zero data collected) that Phase 6 reconciles against actual code via absence-grep extensions
- `/Users/jintanakhomwong/projects/not-to-do-list/test/policy/play_invariants_test.dart` — 10 cross-tree absence-grep invariants (PLAY-02..06 + BIND_DEVICE_ADMIN + forbidden-token sweep + receiver scope). Phase 6 extends with `firebase` / `crashlytics` / `analytics` / `FCM` / `RemoteConfig` absence-grep across pubspec.lock + Dart + Kotlin + decoded APK

### Phase 5 carry-forward (Settings pattern + shared_preferences keys + calm tone)

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/05-streak-engine-daily-reminder/05-CONTEXT.md` — Phase 5 D-08 streak threshold lock (Settings → Streak section promised but UI not shipped; Phase 6 closes the loop per Claude's Discretion above), D-09 `shared_preferences` int-pattern reused for `theme_mode`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/reminder/pages/` — `ReminderSettingsScreen` from Phase 5 Plan 05-08; Phase 6 Settings tile re-uses route `/settings/reminder`, subtitle shows current time
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/streak/providers/streak_threshold_provider.dart` — Phase 5 provider, no UI yet; Phase 6 planner decides whether to surface (see Claude's Discretion)

### Phase 4 carry-forward (calm tone lock)

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/04-pause-ux-the-wedge/04-CONTEXT.md` § D-07 — calm UI, no judgment copy, no scare copy. Phase 6 reset dialog + privacy + disclosure all stay equally calm.

### Phase 2 carry-forward (Accessibility disclosure copy + onboarding routes)

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/02-list-crud-onboarding-permissions/02-CONTEXT.md` — onboarding 3-step funnel structure; Phase 6 reset routes to `/onboarding/welcome` to re-walk
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/widgets/accessibility_step.dart` — 5 verbatim disclosure phrases enforced by source-grep test; Phase 6 Settings → Accessibility disclosure re-uses this screen wholesale
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/storage_keys.dart` — `shared_preferences` key pattern; Phase 6 adds `theme_mode` here

### Phase 3 carry-forward (HealthCheckBanner calm tone)

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/03-screen-time-dashboard/03-CONTEXT.md` § D-13 — `HealthCheckBanner` calm-tone copy pattern; Phase 6 reset/export confirmation copy follows the same calm-tone register

### Existing scaffold (theme, router, dependencies)

- `/Users/jintanakhomwong/projects/not-to-do-list/lib/app.dart` — `MaterialApp.router` with `DynamicColorBuilder` + `AppTheme.light/dark`. Phase 6 adds `themeMode: ref.watch(themeModeProvider)` and a `homeWithSettingsAction` AppBar gear.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/theme/app_theme.dart` — `AppTheme.light({ColorScheme? dynamic})` and `AppTheme.dark({ColorScheme? dynamic})` with `seedColor` fallback. Phase 6 does NOT modify this file — theme switcher only affects `ThemeMode`, not `ThemeData`.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/router/app_router.dart` — Phase 6 adds `/settings`, `/settings/export`, `/settings/privacy`, `/settings/disclosure` (the disclosure route can wrap `accessibility_step.dart` directly). Tile destination for Reminder is the existing `/settings/reminder`.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/home/` — `HomeScreen` gains `AppBar.actions: [IconButton(Icons.settings)]`. Cards order: tracking-offline banner (Phase 2) > reminder-off banner (Phase 5) > Avoided today (Phase 3) > Total avoided (Phase 3) > entries list (Phase 2). Settings gear is a passive AppBar entry — does not affect card stack.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/app_database.dart` — Phase 6 Reset uses a single Drift transaction to `delete().go()` every table (block_list, daily_checkins, daily_streak, pause_events, daily_usage_summary) in foreign-key-safe order.
- `/Users/jintanakhomwong/projects/not-to-do-list/pubspec.yaml` — Phase 6 adds `archive: ^3.x` (ZIP writer), `package_info_plus: ^x` (version surface), optionally `flutter_markdown: ^x` (in-app Privacy Policy renderer — planner decides)
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/build.gradle.kts` — Phase 6 sets version `1.0.0+1` for first Play submission; ensures release-mode signing config + Play App Signing default

### Pre-submit gates

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/05-streak-engine-daily-reminder/05-VERIFICATION.md` — REL-05 overnight gate (pending; Samsung). Phase 6 cannot click "submit for review" in Play Console until REL-05 PASSes AND a Phase 6 full happy-path overnight on a real Xiaomi AND a real Samsung device PASSes (per ROADMAP Phase 6 success criterion 5).
- `/Users/jintanakhomwong/projects/not-to-do-list/assets/onboarding/`, `/Users/jintanakhomwong/projects/not-to-do-list/assets/logos/` — 8 placeholder PNGs await real Pixel captures before Phase 6 PLAY-08 submission (per STATE.md "Deferred items still open" 2026-05-22)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`AppTheme.light` / `AppTheme.dark`** (`lib/core/theme/app_theme.dart`) — already accept `ColorScheme? dynamic` from `DynamicColorBuilder`. Phase 6 wires `ThemeMode` selection on top without modifying `ThemeData`.
- **`accessibility_step.dart`** (`lib/features/onboarding/widgets/accessibility_step.dart`) — already enforces 5 verbatim disclosure phrases via source-grep test. Phase 6 Settings → Accessibility disclosure simply reaches this same screen via a new `/settings/disclosure` GoRoute that wraps it.
- **`ReminderSettingsScreen`** (`lib/features/reminder/pages/`) — Phase 5 Plan 05-08 already shipped at `/settings/reminder`. Phase 6 Settings hub tile simply pushes to it; subtitle shows current `reminder_hour_minute` formatted.
- **`storage_keys.dart`** (`lib/features/onboarding/`) — `shared_preferences` key registry. Phase 6 adds `theme_mode` constant.
- **Drift `AppDatabase`** (`lib/data/database/app_database.dart`) — Reset uses `transaction { delete(block_list).go(); delete(daily_checkins).go(); delete(daily_streak).go(); delete(pause_events).go(); delete(daily_usage_summary).go(); }`. FK cascade pattern already exercised in Phase 2 LIST-05.
- **`test/policy/play_invariants_test.dart`** — 10 absence-grep invariants. Phase 6 extends with `firebase|crashlytics|analytics|FCM|RemoteConfig` set + a decoded-APK strings check.

### Established Patterns

- **Calm tone + no gamification + no scare copy** — Phase 4 D-07 + Phase 5 D-05/D-10 lock. Reset dialog copy stays informative not punitive; Privacy + Disclosure stay plain-language.
- **Material 3 + Drift + Riverpod 3.3 + Pigeon + GoRouter** stack carries through Phase 6 with zero new architectural patterns. Phase 6 is a UI/IA + submission phase, not an engine phase.
- **shared_preferences int-pattern** — Phase 5 D-09 stores `reminder_hour_minute` as int. Phase 6 mirrors with `theme_mode` int (0=system, 1=light, 2=dark).
- **Per-phase absence-grep extension** — Phase 2 added 8 invariants; Phase 4 expanded to 9 (service/ + root); Phase 5 expanded to 10 (receiver/); Phase 6 expands further for telemetry tokens. Pattern is established.
- **Lazy-on-open evaluations** (Phase 3 D-14, Phase 5 D-05) — Theme selection takes effect immediately via Riverpod rebuild of `MaterialApp.router`. No cold-start re-evaluation needed.
- **Pre-rendered single-source-of-truth copy** — `docs/play-declaration.md` (PLAY-07) is the SoT for Accessibility disclosure (re-rendered in `accessibility_step.dart` + Play Console form). Phase 6 mirrors with `PRIVACY.md` as SoT for Privacy Policy (rendered to GitHub Pages + in-app screen).

### Integration Points

- **`HomeScreen.AppBar.actions`** — Phase 6 inserts a single `IconButton(icon: Icons.settings)` routing to `/settings`. Existing Phase 2 + 5 banner stack above the entries list is untouched.
- **`MaterialApp.router`** (`lib/app.dart`) — Phase 6 adds `themeMode: ref.watch(themeModeProvider)`. `DynamicColorBuilder` + `AppTheme.light/dark` calls stay intact.
- **`/settings` GoRoute** — new top-level route in `lib/core/router/app_router.dart`. Adds 4 sub-routes: `/settings/export`, `/settings/privacy`, `/settings/disclosure`. Existing `/settings/reminder` (Phase 5) becomes a child of the new hub by reference, not by code refactor (the route stays where it is; the Settings hub just pushes to it).
- **`AndroidManifest.xml`** — no new permissions needed (Storage Access Framework `ACTION_CREATE_DOCUMENT` is intent-based, not perm-based). No manifest additions Phase 6 needs to absence-grep-whitelist.
- **`pubspec.yaml`** — adds `archive`, `package_info_plus`, optionally `flutter_markdown`. Must extend Phase 5's absence-grep telemetry check to confirm no transitive `firebase` / `analytics` deps creep in.
- **`android/app/build.gradle.kts`** — set `versionName "1.0.0"` and `versionCode 1`. Release signing config + Play App Signing default.

</code_context>

<specifics>
## Specific Ideas

- **Settings entry:** `IconButton(icon: Icon(Icons.settings))` in `HomeScreen.AppBar.actions`, routes to `/settings`.
- **Settings hub tile order (locked):** Reminder → Appearance → Data (Export, Reset) → Privacy (Privacy Policy, Accessibility disclosure) → About.
- **Settings hub tile types (locked):** navigation (push), inline (theme `SegmentedButton`), action (Reset with `AlertDialog`).
- **Theme selector widget:** M3 `SegmentedButton<ThemeMode>` 3-segment `[Light | Dark | System]` rendered inline on Settings → Appearance row. Default: `ThemeMode.system`.
- **Theme persistence:** `shared_preferences` key `theme_mode` int (0=system, 1=light, 2=dark). Riverpod `themeModeProvider` watched in `lib/app.dart`.
- **Theme interaction with dynamic_color:** selector controls `themeMode:` brightness only; `DynamicColorBuilder` seed still wins for color.
- **Export packaging:** single `.zip` via one `ACTION_CREATE_DOCUMENT` pick.
- **Export filename:** `not-to-do-list-export-YYYYMMDD-HHMM.zip` (local-time date).
- **Export CSV files (5):** `block_list.csv`, `daily_checkins.csv`, `daily_streak.csv`, `pause_events.csv`, `daily_usage_summary.csv` — header row = Drift column names verbatim.
- **Export JSON envelope:** `{schemaVersion: 1, exportedAt: ISO-8601 UTC, appVersion: "1.0.0+1", tables: {block_list: [...], daily_checkins: [...], daily_streak: [...], pause_events: [...], daily_usage_summary: [...]}}` as `data.json`.
- **Export timestamps:** ISO-8601 UTC `2026-05-24T17:30:00Z` in both CSV string columns and JSON.
- **Reset dialog body copy (literal):** `"This deletes every entry, streak day, pause event, and check-in. This cannot be undone."`
- **Reset dialog buttons:** `Cancel` (default-focused) + `Reset` (destructive M3 `FilledButton.tonal` red).
- **Reset scope:** Drift `transaction { delete every table }` + `shared_preferences.clear()` + route to `/onboarding/welcome`.
- **Privacy Policy SoT:** `PRIVACY.md` at repo root → GitHub Pages auto-publish.
- **Privacy Policy in-app render:** `flutter_markdown` reading bundled `assets/PRIVACY.md` (planner picks `flutter_markdown` vs pre-rendered string constant).
- **Accessibility disclosure in-app:** `/settings/disclosure` GoRoute wraps existing `accessibility_step.dart` — no copy duplication.
- **About tile:** uses `package_info_plus` to render `version + build` (e.g., `"1.0.0 (1)"`).
- **Data Safety absence-grep tokens (extension to `test/policy/play_invariants_test.dart`):** `firebase`, `crashlytics`, `analytics`, `FCM`, `RemoteConfig` (case-insensitive).
- **Data Safety APK-grep gate:** `unzip -p build/app/outputs/apk/release/app-release.apk classes.dex | strings | grep -iE '(firebase|crashlytics|analytics|fcm|remoteconfig)'` must return no matches.
- **Play release track plan:** Internal testing first (instant, developer-only) → Closed testing (named tester list 5–20 people) → STOP. v1 PLAY-08 satisfied at closed-track PASS.
- **Play app signing:** default Play App Signing (Google manages the upload key).
- **First version:** `versionName "1.0.0"`, `versionCode 1`.
- **Listing assets:** `docs/play-listing/short-description.txt` (80 char), `docs/play-listing/full-description.txt` (4000 char), 2 phone screenshots (real captures replacing 8 placeholders in `assets/onboarding/` + `assets/logos/`), 1 feature graphic (1024x500).
- **Full happy-path overnight exit gate (Phase 6 success criterion 5):** onboarding → list add → blocked-app launch → pause → cooldown → streak roll-over → reminder fire, on real Xiaomi AND real Samsung device. Prerequisite to Play Console submit.

</specifics>

<deferred>
## Deferred Ideas

- **Global Streak threshold Settings tile (numeric slider/field)** — user-excluded from v1 Settings list (D-03). Phase 5 D-08 promised this; the planner decides per Claude's Discretion above whether to ship a thin inline row in Phase 6 or formally defer to v1.x. If deferred, 06-VERIFICATION.md must document the broken Phase 5 D-08 promise and the Settings tile order becomes Reminder → Appearance → Data → Privacy → About (no Streak section).
- **Per-entry streak threshold override UI** — Phase 5 deferred to v1.x; remains deferred.
- **Streak-aware notification copy / streak sharing / leaderboards / badges / gamification** — explicit PROJECT.md anti-features, never v1.
- **Color-seed picker (Material You custom seed override)** — out of SETT-04 scope; brightness only. M2 if at all.
- **Export user-format chooser (CSV-only / JSON-only / Both)** — single ZIP default is enough; chooser deferred to v1.x if power users ask.
- **Type-to-confirm `RESET` text-entry** — rejected as ceremonial for a self-control reset flow.
- **Hold-to-confirm 3s Reset button** — rejected for motor-accessibility concerns.
- **Drift-only reset (keep shared_preferences)** — rejected; full clean slate is the cleaner mental model.
- **Production / open-beta release track in v1** — v1 STOPS at closed-track PASS. Open beta = post-validation (v1.x or M2).
- **In-app Privacy Policy as the sole source (no public URL)** — Play Console requires a public URL; rejected by policy.
- **`flutter_markdown` vs pre-rendered string for Privacy** — planner picks per dep-weight preference; either is fine.
- **Import / restore from export** — out of scope for v1; export-only. Schema versioning (`schemaVersion: 1`) reserves the field for future import code.
- **App icon redesign / branding pass** — out of Phase 6 scope as a new visual-direction task; Phase 6 uses existing icon + 8 placeholder PNGs (which must be replaced with real captures before submit, per STATE.md deferred items).
- **Translations / i18n** — v1 is English-only; i18n is v1.x or M2.
- **In-app feedback / contact form** — privacy + on-device only + no backend = no in-app contact form in v1.
- **Crash reporting / analytics opt-in** — explicit PROJECT.md anti-feature.
- **Onboarding step for Theme selection** — Phase 2 lock; Theme default is System; user changes in Settings.

</deferred>

---

*Phase: 06-polish-play-store-submission*
*Context gathered: 2026-05-24 via /gsd-discuss-phase 6*
