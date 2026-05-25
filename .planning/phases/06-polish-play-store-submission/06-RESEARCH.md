# Phase 6: Polish & Play Store Submission — Research

**Researched:** 2026-05-24
**Domain:** Settings hub + ZIP export over SAF + theme persistence + Play Store closed-track submission for an AccessibilityService-using on-device-only Android app
**Confidence:** HIGH (every recommendation cross-verified against current pub.dev + Google policy docs)

---

## Summary

Phase 6 is **not an engine phase**. It is final-mile UI + IA + submission. Every architectural decision is already locked in 06-CONTEXT.md (16 user decisions D-01..D-16); my job is to make the small set of "Claude's discretion" picks executable and to pre-research the Play Console funnel so the planner doesn't have to re-litigate it.

The four substantive technical questions worth researching are:

1. **ZIP-to-SAF bridge** — `file_picker.saveFile()` does **not** write bytes on Android (verified open issues #832, #882, #1885). The clean path is `flutter_file_dialog 3.0.3` (`saveFileToBytes` / `saveFile(SaveFileDialogParams(data: ...))` — backed by `ACTION_CREATE_DOCUMENT` natively on Android). Pair with `archive ^4.0.9` (`ZipEncoder().encode(Archive)` → `Uint8List`).
2. **In-app Privacy Policy render** — `flutter_markdown` is officially deprecated by Google (flutter/flutter#162966). The community continuation is `flutter_markdown_plus ^1.0.7` (Foresight Mobile). Both work for our static `PRIVACY.md`; the pre-rendered-string alternative skips one transitive dep at the cost of a build step. **Recommend `flutter_markdown_plus`** — the ~80 KB cost is below the noise floor, the build step is real ceremony, and it future-proofs PRIVACY.md edits.
3. **Theme persistence** — Hand-written `AsyncNotifier<ThemeMode>` that mirrors the existing `streakThresholdProvider` shape **exactly**. Plan must not introduce `riverpod_annotation`/`riverpod_generator` (Phase 1 dropped them for analyzer-pin incompatibility with `pigeon 26.3.4` — see pubspec.yaml lines 11–14).
4. **Play closed-track funnel + AccessibilityService Permission Declaration** — Locked by `docs/play-declaration.md`. The 2026-current form requires: usage justification (functionality), data-collection answer (no), and a **demonstration video** showing the in-app prominent disclosure. The video is the most-overlooked rejection cause — the planner must add a task to record one. Data Safety form requires a public Privacy Policy URL even for zero-collection apps (verified against current Google docs).

**Primary recommendation:** Plan 7–9 sequenced plans (Wave 0 test scaffold → theme provider → settings hub shell → export → reset → privacy/disclosure/about → invariants extension → exit-gate listing assets + Play funnel checklist). Decide Claude's-Discretion items in the first planning pass: ship inline Streak section (option a, recommended), use flutter_markdown_plus, put PRIVACY.md in `/docs/` with GitHub Pages "Deploy from a branch → /docs".

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Settings hub IA & entry (D-01..04)**
- **D-01 — Entry point:** AppBar gear icon on `HomeScreen`. No bottom nav, no drawer, no floating settings card.
- **D-02 — Architecture:** single scrollable `/settings` screen with sectioned ListView + M3 list tiles. Headers: Reminder / Appearance / Data / Privacy / About. Tile types: navigation (push), inline (theme `SegmentedButton`, Reminder time subtitle), action (Reset destructive).
- **D-03 — v1 Settings tiles (locked):** Reminder time, Appearance→Theme inline, Export data, Reset data, Privacy Policy, Accessibility disclosure, Version/About. Global Streak threshold tile is excluded (planner resolves per Claude's Discretion).
- **D-04 — Tile order:** Reminder → Appearance → Data (Export, Reset) → Privacy (Privacy Policy, Accessibility disclosure) → About.

**Theme switcher (D-05..08)**
- **D-05 — Widget:** M3 `SegmentedButton` 3-segment `[Light | Dark | System]` inline on Settings → Appearance row.
- **D-06 — Default:** `ThemeMode.system`.
- **D-07 — Persistence:** `shared_preferences` int key `theme_mode` (0=system, 1=light, 2=dark) + Riverpod `themeModeProvider` watched in `lib/app.dart`. Mirrors `reminder_hour_minute` int-pattern (Phase 5 D-09).
- **D-08 — dynamic_color interaction:** selector controls `ThemeMode` brightness ONLY; `DynamicColorBuilder` seed still wins for color on Android 12+.

**Export shape (D-09..12)**
- **D-09 — Packaging:** single `.zip` archive via one `ACTION_CREATE_DOCUMENT` pick. Filename: `not-to-do-list-export-YYYYMMDD-HHMM.zip` (local-time date).
- **D-10 — CSV layout:** one CSV per Drift table (5 files): `block_list.csv`, `daily_checkins.csv`, `daily_streak.csv`, `pause_events.csv`, `daily_usage_summary.csv`. Header row = Drift column names verbatim. Foreign keys via `entryId`.
- **D-11 — JSON schema:** envelope `{schemaVersion: 1, exportedAt: ISO-8601 UTC, appVersion: "1.0.0+1", tables: {...}}` as `data.json` inside the same ZIP.
- **D-12 — Timestamp format:** ISO-8601 UTC `2026-05-24T17:30:00Z` in both CSV string columns and JSON.

**Reset + Play submission (D-13..16)**
- **D-13 — Reset gate:** two-step `AlertDialog`. Body copy literal: `"This deletes every entry, streak day, pause event, and check-in. This cannot be undone."` Cancel default-focused. Calm tone, no scare copy.
- **D-14 — Reset scope:** wipe Drift + `shared_preferences` (incl. onboarding-complete flag) → route to `/onboarding/welcome`.
- **D-15 — Play release track:** Internal testing → Closed testing → STOP. v1 STOPS at closed-track PASS.
- **D-16 — Privacy Policy hosting:** `PRIVACY.md` in repo → GitHub Pages auto-publish + in-app render + extended absence-grep (firebase|crashlytics|analytics|FCM|RemoteConfig) across pubspec.lock + Dart + Kotlin + decoded APK.

**Carry-forward locks (from prior phases — do NOT renegotiate)**
- Phase 4 D-07 calm tone — Reset dialog, Privacy, Disclosure all stay calm.
- Phase 5 D-08 streak threshold — D-03 excludes the tile; Claude's discretion below.
- Phase 5 D-09 `shared_preferences` int-pattern — `theme_mode` mirrors `reminder_hour_minute`.
- PLAY-02..06 invariants in `test/policy/play_invariants_test.dart` are append-only (Phase 5 expanded to 10).
- Architecture stack: Material 3 + Drift + Riverpod 3.3 + Pigeon + GoRouter. No new architectural patterns.

### Claude's Discretion (planner resolves)

1. **Streak threshold Settings UI** — option (a) ship a minimal inline Streak section above Appearance (recommended; closes Phase 5 D-08 soft lock); option (b) defer to v1.x and document broken promise in 06-VERIFICATION.md. **Researcher recommends (a)** — provider already exists, UI is one inline row, Phase 5 already shipped the picker dialog in `reminder_settings_screen.dart` lines 47–53 that the new Settings tile can re-route to (or extract). See §Architecture Patterns → Streak Tile.
2. **`flutter_markdown_plus` vs pre-rendered string** for in-app Privacy Policy. **Researcher recommends `flutter_markdown_plus ^1.0.7`** — see §Standard Stack and §Don't Hand-Roll.
3. **`archive` package vs hand-rolled ZIP writer.** Pure-Dart `archive ^4.0.9` is the obvious choice. Locked here so it isn't re-litigated.
4. **`package_info_plus` for About tile.** Standard Flutter plugin. `^10.1.0` current.
5. **GitHub Pages repo layout.** **Researcher recommends `/docs/PRIVACY.md` on `main` branch + Settings → Pages → "Deploy from a branch" → "main / /docs"** — lowest-ceremony route. Settles in §Architecture Patterns.
6. **Internal testing tester list seeding** — single tester (developer's own Google account).
7. **Listing copy + screenshot capture** — Plan must create `docs/play-listing/` with all assets; real Pixel captures replace the 8 placeholders in `assets/onboarding/` + `assets/logos/` (per STATE.md deferred items 2026-05-22).

### Deferred Ideas (OUT OF SCOPE)

- Global Streak threshold Settings tile as a separate row (per D-03; planner picks inline-thin or formal defer per discretion #1).
- Per-entry streak threshold override UI (deferred to v1.x by Phase 5).
- Streak-aware notification copy / streak sharing / leaderboards / badges / gamification (explicit PROJECT.md anti-features).
- Color-seed picker (M2).
- Export user-format chooser (CSV-only / JSON-only / Both) (v1.x if asked).
- Type-to-confirm `RESET` text-entry (rejected — ceremonial).
- Hold-to-confirm 3s Reset (rejected — motor-accessibility).
- Drift-only reset (rejected — full clean slate wanted).
- Production / open-beta release track in v1 (v1 STOPS at closed-track).
- In-app Privacy Policy as sole source (Play requires public URL).
- Import / restore from export (v1.x; `schemaVersion: 1` reserves the field).
- App icon redesign / branding pass (Phase 6 uses existing icon).
- Translations / i18n (v1.x or M2).
- In-app feedback / contact form (no backend; off-by-design).
- Crash reporting / analytics opt-in (PROJECT.md anti-feature).
- Onboarding step for Theme selection (Phase 2 lock; default System).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SETT-01 | User can export all data as CSV and JSON to local storage via `ACTION_CREATE_DOCUMENT` | §Standard Stack (`archive` + `flutter_file_dialog`), §Architecture Patterns → Export flow, §Code Examples → Build ZIP / Save via SAF |
| SETT-02 | User can reset all data (delete every entry, streak day, pause event, check-in) | §Architecture Patterns → Reset transaction, §Code Examples → Drift transactional reset, §Common Pitfalls → Reset Race Conditions |
| SETT-04 | User can switch theme: Light / Dark / System | §Standard Stack (existing `shared_preferences` + `flutter_riverpod`), §Architecture Patterns → Theme provider, §Code Examples → AsyncNotifier theme |
| SETT-05 | Privacy Policy and Accessibility Service prominent-disclosure screens are linked from Settings | §Standard Stack (`flutter_markdown_plus`), §Architecture Patterns → Privacy SoT + GitHub Pages, §Code Examples → Render markdown, §Code Examples → Wrap accessibility_step |
| PLAY-08 | App passes closed-track Play review before any public release | §Play Console Closed-Track Funnel, §Architecture Patterns → Release-track strategy, §Common Pitfalls → AccessibilityService rejection patterns, §Validation Architecture → Decoded APK strings sweep |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Simplicity first:** No features beyond what was asked. No abstractions for single-use code. Settings hub uses 5 simple section headers + ~8 tiles; resist refactoring `ReminderSettingsScreen` (Phase 5 owns it).
- **Surgical changes:** Touch only what you must. Phase 6 must NOT modify `AppTheme.light/dark` (already accepts `ColorScheme? dynamic`); only adds `themeMode:` field to `MaterialApp.router`. Existing `HomeScreen.AppBar.actions` already has `IconButton(Icons.notifications_outlined)` (lines 53–62) — Phase 6 INSERTS a settings gear leftmost, does NOT replace the bell.
- **Goal-driven execution:** Every plan must have a verifiable goal. Reset = "tap Reset → DB has zero rows in all 5 tables AND `SharedPreferences.getKeys()` is empty AND router is at `/onboarding/welcome`." Export = "tap Export → write zip → read zip back → CSV+JSON content equals Drift state."
- **Multi-agent DAG:** Phase 6 qualifies as complex (multi-file: 8 plans likely, shared state: `shared_preferences` + Drift transactional reset, Play-policy sensitive: APK-grep + form text). Apply Opus-plan → Sonnet-impl → Codex-review → Opus-verify per CLAUDE.md.
- **Auto-approval gate:** STOP for explicit user approval before "ready to submit" in Play Console. The OEM-survival overnight pass + REL-05 pass are both prerequisites — the planner must encode them as blocking manual gates.

## Architectural Responsibility Map

Phase 6 is **mostly Flutter UI/Dart-business** with a thin **Android SAF bridge** and **OS-level Play Console submission** boundary. No new Pigeon channels, no new AccessibilityService surfaces, no new BroadcastReceivers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Settings hub UI + IA | Flutter / Dart | — | Pure widget composition; no platform call needed beyond existing routes |
| Theme persistence | Flutter / Dart | OS (`SharedPreferences`) | Riverpod owns reactive state; shared_preferences is the persistence sink (same as `reminder_hour_minute`) |
| Theme application | Flutter / Dart | — | `MaterialApp.router.themeMode` rebuilds widget tree; no platform involvement |
| Export → ZIP build | Flutter / Dart | — | `archive ^4.0.9` is pure-Dart; runs on the Dart isolate; small data volumes (v1 ~weeks of usage rows) make synchronous build fine |
| Export → save to SAF URI | Android (SAF) | Flutter plugin (`flutter_file_dialog`) | `ACTION_CREATE_DOCUMENT` is an OS intent; the plugin wraps the resulting URI and writes bytes. Flutter cannot call SAF directly — needs a plugin or hand-rolled MethodChannel |
| Reset → Drift wipe | Flutter / Dart | SQLite | Transaction is Dart-driven via Drift API; SQLite executes |
| Reset → SharedPreferences wipe | Flutter / Dart | OS | `SharedPreferences.getInstance().then((p) => p.clear())` |
| Reset → route to /onboarding/welcome | Flutter / Dart | — | `context.go('/onboarding/welcome')` — existing GoRouter; the redirect guard auto-routes when `onboarding_complete` is cleared (see §Common Pitfalls → GoRouter re-route race) |
| Privacy Policy render | Flutter / Dart | Asset bundle | `flutter_markdown_plus` reads `assets/PRIVACY.md` via `rootBundle.loadString` |
| Accessibility disclosure render | Flutter / Dart | — | Wraps existing `AccessibilityStep` (Phase 2) — reuse, don't re-author the 5 verbatim phrases |
| About tile (version + build) | Flutter / Dart | OS (`package_info_plus`) | Reads `BuildConfig.VERSION_NAME` / `VERSION_CODE` from Android side via the plugin |
| GitHub Pages publish | DevOps / GitHub | — | Repo settings change + folder layout; no app-side code |
| Play Console submission | DevOps / Play Console | — | Web-form manual flow; planner adds a runbook checklist |
| Absence-grep extension | Build / Test | — | Pure-Dart `flutter test` reading `pubspec.lock` + source dirs + decoded `classes*.dex` strings |

**Tier-correctness check:** Every capability lives in its natural tier. The only cross-tier handoff is Export's two-step "build bytes in Dart → ship to SAF via plugin," which is the canonical pattern.

## Standard Stack

### Core (new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `archive` | ^4.0.9 | Pure-Dart ZIP encode/decode (`ZipEncoder().encode(Archive)` → `List<int>` ; or `ZipFileEncoder` for file-path output) | De-facto Dart ZIP library; published 3 months ago (2026-02-17); pure-Dart; transitive deps only `path` + `posix` (lightweight); supports both file-path and stream/bytes targets — exact shape we need for SAF handoff [VERIFIED: pub.dev/packages/archive] |
| `flutter_file_dialog` | ^3.0.3 | SAF bridge: `saveFile(SaveFileDialogParams(data: bytes, fileName: ..., mimeTypesFilter: ['application/zip']))` — backed by `ACTION_CREATE_DOCUMENT` on Android | Only mainstream Flutter plugin whose Android `saveFile` actually accepts `Uint8List` bytes and writes via SAF. `file_picker.saveFile` is **broken on Android for bytes** (verified open issues miguelpruivo/flutter_file_picker#832, #882, #1885 — "saveFile() not working") [VERIFIED: pub.dev/packages/flutter_file_dialog; CITED: github.com/miguelpruivo/flutter_file_picker/issues/832] |
| `flutter_markdown_plus` | ^1.0.7 | Render bundled `assets/PRIVACY.md` via `Markdown(data: ...)` widget | Original `flutter_markdown` officially deprecated by Google (flutter/flutter#162966). Foresight Mobile took over with `flutter_markdown_plus`; published 4 months ago; GitHub-Flavored Markdown by default; transitive deps `markdown ^7.3.0` + `meta ^1.16.0` + `path ^1.9.1` — no firebase/analytics surface [VERIFIED: pub.dev/packages/flutter_markdown_plus; CITED: github.com/flutter/flutter/issues/162966; CITED: foresightmobile.com/blog/flutter-markdown-plus-google-handover] |
| `package_info_plus` | ^10.1.0 | About tile: `(await PackageInfo.fromPlatform()).version + buildNumber` | Standard Flutter Favorite-tier plugin; current 10.1.0 (published 33 days ago); reads Android `BuildConfig.VERSION_NAME` / `VERSION_CODE` — exactly what About tile needs; requires Java 17 + AGP ≥8.12.1 (we ship Java 17 already per `android/app/build.gradle.kts` lines 13–20) [VERIFIED: pub.dev/packages/package_info_plus] |

### Already in tree (no new install)

| Library | Existing pin | Reused for |
|---------|--------------|------------|
| `flutter_riverpod` | ^3.3.1 | `themeModeProvider` AsyncNotifier (mirror `streakThresholdProvider` shape) |
| `shared_preferences` | ^2.5.5 | `theme_mode` int key + `clear()` for reset |
| `go_router` | ^17.2.3 | New routes `/settings`, `/settings/export`, `/settings/privacy`, `/settings/disclosure` |
| `drift` + `drift_flutter` | ^2.33.0 / ^0.3.0 | Reset transaction + read all tables for CSV export |
| `intl` | ^0.20.2 | ISO-8601 UTC formatting for export timestamps; already in `reminder_settings_screen.dart` for time formatting |
| `dynamic_color` | ^1.7.0 | Already wired in `lib/app.dart`; D-08 lock — Phase 6 does not touch |

### Supporting (existing, used as-is)

| Library | Existing pin | Used for |
|---------|--------------|----------|
| `very_good_analysis` | ^10.2.0 | Lint passes; new files must satisfy |
| `mocktail` | ^1.0.5 | Test doubles for `flutter_file_dialog` (the SAF plugin call needs a mock so widget tests don't trigger system UI) |
| `flutter_test` (SDK) | — | Widget tests, golden tests, integration of SAF mock |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter_file_dialog` | `file_picker.saveFile` | **REJECTED.** Documented broken on Android with `bytes:` (issues #832, #882, #1885 above). Would require pre-writing to app-private file then a second pick — two intents, breaks the "one SAF pick" lock (D-09) [VERIFIED: github.com issues] |
| `flutter_file_dialog` | `file_saver` | Possible alt; but smaller community footprint than `flutter_file_dialog`; not Flutter Favorite; less verified for Android SAF specifically. `flutter_file_dialog` is the cleanest answer in 2026 [ASSUMED based on package adoption signals] |
| `flutter_file_dialog` | Hand-rolled Pigeon MethodChannel calling `ACTION_CREATE_DOCUMENT` | Possible — would be ~30 lines Kotlin + 15 lines Dart, fits the Phase 1 Pigeon-everywhere pattern. **Cost:** test scaffolding + maintenance burden for one feature. **Verdict:** plugin wins for v1; revisit if `flutter_file_dialog` later misbehaves on a target OEM (mark in Risks Tracked) |
| `flutter_markdown_plus` | Pre-rendered string constant via `tool/render_privacy.dart` build step | Saves ~80 KB + one transitive dep (`markdown ^7.3.0`); costs a build step + an out-of-band regen any time PRIVACY.md changes. **Recommend plugin** — calm-tone copy is stable but PRIVACY.md is a SoT and will get edits; one-step render beats one-step build-then-render |
| `flutter_markdown_plus` | Original `flutter_markdown` | **REJECTED.** Deprecated by Google upstream (flutter/flutter#162966) [VERIFIED] |
| `archive` package | Hand-rolled `dart:io` ZIP via stdlib | **REJECTED.** Dart core has no ZIP writer in stdlib; `archive` is the canonical answer |
| `archive` package | `flutter_archive` | `flutter_archive` is a plugin wrapping java.util.zip; adds Android-platform call surface for what `archive` does in pure Dart. Pure-Dart wins for testability + smaller surface |
| `AsyncNotifier<ThemeMode>` hand-written | `@riverpod` codegen | **REJECTED.** Phase 1 dropped `riverpod_annotation`/`riverpod_generator` due to analyzer-pin conflict with `pigeon 26.3.4` (`meta 1.17`). Reintroduction is explicitly deferred until ecosystem converges on analyzer 12+ (pubspec.yaml lines 11–14). Hand-written mirrors `streakThresholdProvider` (Phase 5) exactly |
| Drift `app_settings` table for theme | `shared_preferences` int | **REJECTED by D-07.** Schema migration + DAO + stream for a single int is overkill. shared_preferences `int` matches `reminder_hour_minute` pattern |

**Installation:**
```bash
flutter pub add archive flutter_file_dialog flutter_markdown_plus package_info_plus
```

**Version verification (perform in Wave 0):**
```bash
flutter pub deps -- --no-dev | grep -E "(archive|flutter_file_dialog|flutter_markdown_plus|package_info_plus|firebase|crashlytics|analytics|fcm|remoteconfig)" -i
```
- Confirms current versions resolved
- Confirms no transitive telemetry crept in via the new deps (extends the existing Phase 5 D-09-pattern absence sweep)

**Versions verified 2026-05-24:**
- `archive 4.0.9` (published 2026-02-17, ~3 months old — stable)
- `flutter_file_dialog 3.0.3` (published 2025-12-24, ~5 months old — stable, verified publisher)
- `flutter_markdown_plus 1.0.7` (published 2026-01-24, ~4 months old — actively maintained)
- `package_info_plus 10.1.0` (published 2026-04-21, ~33 days old — current)

## Architecture Patterns

### System Architecture Diagram

```
                    HomeScreen.AppBar.actions
                          │
                          ▼  (gear icon onPressed)
                    GoRouter '/settings'
                          │
                          ▼
                    SettingsScreen (5 sectioned tiles)
                ┌─────────┼─────────┬─────────┬─────────┐
                ▼         ▼         ▼         ▼         ▼
          /settings/  Appearance  Data:    /settings/  About tile
          reminder    SegmentedBtn Export, /privacy   (inline display)
          (Phase 5)   ┌─inline─┐  Reset    /disclosure
                      ▼              ┌─────┴─────┐
                  themeModeProvider  ▼           ▼
                  AsyncNotifier      ExportScreen ResetDialog
                      │              ▲           │
                      │ persist      │ build     │ Drift txn
                      ▼              │ ZIP       ▼ delete all 5
                  shared_preferences │           tables + clear
                  "theme_mode" int   │           prefs + go
                      │              │           '/onboarding/welcome'
                      │              ▼
                      ▼          flutter_file_dialog.saveFile
              MaterialApp.router │   (Android SAF
              .themeMode rebuilds│    ACTION_CREATE_DOCUMENT)
              widget tree        ▼
                              user-chosen URI
                              receives ZIP bytes

Cross-cutting:
  - GitHub Pages: /docs/PRIVACY.md → published at https://{user}.github.io/{repo}/PRIVACY
  - Settings/Privacy screen: rootBundle.loadString('assets/PRIVACY.md') → flutter_markdown_plus.Markdown
  - Settings/Disclosure: wraps existing lib/features/onboarding/pages/accessibility_step.dart
  - About tile: package_info_plus.PackageInfo.fromPlatform()
  - Pre-submit gate: test/policy/play_invariants_test.dart adds:
      - pubspec.lock telemetry-token absence
      - decoded APK classes*.dex strings absence
```

### Component Responsibilities

| Component | File | Responsibility |
|-----------|------|----------------|
| `SettingsScreen` | `lib/features/settings/pages/settings_screen.dart` (new) | Composes 5 sections + tile widgets; pure ConsumerWidget |
| `_SectionHeader` widget | `lib/features/settings/widgets/section_header.dart` (new) | M3 section label `Padding + Text(style: tt.labelSmall.copyWith(color: cs.primary, letterSpacing: 0.8))` |
| `ThemeTile` widget | `lib/features/settings/widgets/theme_tile.dart` (new) | ListTile containing `SegmentedButton<ThemeMode>`; reads + writes `themeModeProvider` |
| `themeModeProvider` | `lib/features/settings/providers/theme_mode_provider.dart` (new) | Hand-written `AsyncNotifier<ThemeMode>`; mirrors `streakThresholdProvider` shape |
| `ExportScreen` | `lib/features/settings/pages/export_screen.dart` (new) | Single action tile → triggers `ExportController.exportAll()` |
| `ExportController` | `lib/features/settings/services/export_controller.dart` (new) | Reads all 5 DAOs → builds 5 CSVs + 1 JSON → packs with `ZipEncoder` → calls `flutter_file_dialog.saveFile` |
| `ResetController` | `lib/features/settings/services/reset_controller.dart` (new) | Drift `transaction { delete().go() × 5 }` → `SharedPreferences.clear()` → invalidate Riverpod providers → `context.go('/onboarding/welcome')` |
| `PrivacyScreen` | `lib/features/settings/pages/privacy_screen.dart` (new) | `FutureBuilder<String>` over `rootBundle.loadString('assets/PRIVACY.md')` → `Markdown(data: ...)` |
| `AboutTile` widget | `lib/features/settings/widgets/about_tile.dart` (new) | `FutureBuilder<PackageInfo>` → renders `${pi.version} (${pi.buildNumber})` |
| `/settings/disclosure` route | `lib/core/router/app_router.dart` (edit) | Routes to a wrapper around `AccessibilityStep` — reuses the 5 verbatim phrases without duplication |
| AppBar gear icon | `lib/features/home/pages/home_screen.dart` (edit, surgical) | INSERT `IconButton(Icons.settings, onPressed: () => context.go('/settings'))` as **first** action; existing notifications icon stays as second |
| `MaterialApp.router` | `lib/app.dart` (edit, surgical) | ADD `themeMode: ref.watch(themeModeProvider).maybeWhen(data: (m) => m, orElse: () => ThemeMode.system)` |
| `OnboardingKeys.themeMode` | `lib/features/onboarding/storage_keys.dart` (edit) | ADD `static const String themeMode = 'theme_mode';` constant |
| Extended absence-grep | `test/policy/play_invariants_test.dart` (edit, append-only) | NEW test(s): pubspec.lock telemetry-token absence + decoded `classes*.dex` strings absence |

### Recommended Project Structure (Phase 6 additions)

```
lib/features/settings/
├── pages/
│   ├── settings_screen.dart          # Settings hub
│   ├── export_screen.dart            # Single-action export
│   └── privacy_screen.dart           # Markdown render
├── widgets/
│   ├── section_header.dart           # M3 section label
│   ├── theme_tile.dart               # SegmentedButton inline
│   └── about_tile.dart               # package_info_plus inline
├── providers/
│   └── theme_mode_provider.dart      # hand-written AsyncNotifier<ThemeMode>
└── services/
    ├── export_controller.dart        # Drift → CSV/JSON → ZIP → SAF
    └── reset_controller.dart         # Drift txn + prefs.clear + route

assets/
└── PRIVACY.md                        # bundled markdown source

docs/
├── play-declaration.md               # existing (Phase 1)
├── data-safety.md                    # existing (Phase 1)
├── play-listing/                     # NEW Phase 6
│   ├── short-description.txt         # 80 char
│   ├── full-description.txt          # 4000 char
│   ├── screenshots/                  # 2 phone screenshots, 1 feature graphic 1024x500
│   └── permission-declaration.md     # copy of play-declaration.md text shaped to the form
├── PRIVACY.md                        # Privacy Policy SoT — published via GitHub Pages
└── _config.yml                       # optional minimal Jekyll config (or omit and let GitHub default)
```

### Pattern 1: Hand-written `AsyncNotifier<ThemeMode>`

**What:** Mirror the existing `streakThresholdProvider` exactly — same file layout, same persistence pattern.
**When to use:** Anywhere a single shared_preferences int controls a Riverpod-watched piece of app state.
**Source:** existing `lib/features/streak/providers/streak_threshold_provider.dart`

```dart
// lib/features/settings/providers/theme_mode_provider.dart
//
// SETT-04 + D-07 lock: theme_mode int (0=system, 1=light, 2=dark)
// Hand-written AsyncNotifier — no riverpod_annotation codegen
// (Phase 1 dropped codegen due to pigeon 26.3.4 analyzer-pin conflict).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/onboarding/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThemeMode _decode(int raw) => switch (raw) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system, // 0 + any unknown → system (fail-safe)
    };

int _encode(ThemeMode m) => switch (m) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getInt(OnboardingKeys.themeMode) ?? 0);
  }

  Future<void> set(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(OnboardingKeys.themeMode, _encode(mode));
    state = AsyncValue.data(mode);
  }
}

final AsyncNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
```

**Wire-up in `lib/app.dart` (surgical, +1 import +1 line):**
```dart
// In NotToDoApp.build:
final themeAsync = ref.watch(themeModeProvider);
final themeMode = themeAsync.maybeWhen(
  data: (m) => m,
  orElse: () => ThemeMode.system, // safe default while async-loading
);
return MaterialApp.router(
  title: 'Not To-Do List',
  theme: AppTheme.light(dynamic: lightDynamic),
  darkTheme: AppTheme.dark(dynamic: darkDynamic),
  themeMode: themeMode,   // <-- ADD
  routerConfig: router,
);
```

### Pattern 2: Build ZIP entirely in memory, hand to SAF plugin

**What:** Use `archive` to build `Uint8List` ZIP bytes in the Dart isolate, then pass to `flutter_file_dialog.saveFile`.
**When to use:** Small-data exports (v1 expected size: <1 MB even for power users) where streaming complexity isn't worth it.
**Source:** `archive ^4.0.9` (`archive_io` library) + `flutter_file_dialog ^3.0.3`

```dart
// lib/features/settings/services/export_controller.dart (sketch)
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';

// (omit imports for DAOs — they live in lib/data/database/daos/)

class ExportController {
  ExportController(this._db, this._packageInfo);
  final AppDatabase _db;
  final PackageInfo _packageInfo;

  /// Returns saved path on success, null on user cancel.
  Future<String?> exportAll() async {
    // 1. Read all 5 tables (parallel)
    final futures = await Future.wait([
      _db.blockListDao.getAll(),
      _db.dailyCheckinsDao.getAll(),
      _db.dailyStreakDao.getAll(),
      _db.pauseEventDao.getAll(),
      _db.dailyUsageSummaryDao.getAll(),
    ]);
    // (Where `getAll()` returns List<RowData>. If a DAO lacks one, add a minimal getAll().)

    // 2. Build CSVs (header row = Drift column names verbatim per D-10)
    final csvBlockList = _toCsv('block_list', futures[0]);
    final csvCheckins = _toCsv('daily_checkins', futures[1]);
    final csvStreak = _toCsv('daily_streak', futures[2]);
    final csvPause = _toCsv('pause_events', futures[3]);
    final csvUsage = _toCsv('daily_usage_summary', futures[4]);

    // 3. Build data.json envelope (D-11)
    final envelope = {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(), // D-12 ISO-8601 UTC
      'appVersion': '${_packageInfo.version}+${_packageInfo.buildNumber}',
      'tables': {
        'block_list': futures[0].map((r) => r.toJson()).toList(),
        'daily_checkins': futures[1].map((r) => r.toJson()).toList(),
        'daily_streak': futures[2].map((r) => r.toJson()).toList(),
        'pause_events': futures[3].map((r) => r.toJson()).toList(),
        'daily_usage_summary': futures[4].map((r) => r.toJson()).toList(),
      },
    };
    final jsonBytes = utf8.encode(jsonEncode(envelope));

    // 4. Build ZIP in memory via Archive + ZipEncoder
    final archive = Archive()
      ..addFile(ArchiveFile('block_list.csv', csvBlockList.length, csvBlockList))
      ..addFile(ArchiveFile('daily_checkins.csv', csvCheckins.length, csvCheckins))
      ..addFile(ArchiveFile('daily_streak.csv', csvStreak.length, csvStreak))
      ..addFile(ArchiveFile('pause_events.csv', csvPause.length, csvPause))
      ..addFile(ArchiveFile('daily_usage_summary.csv', csvUsage.length, csvUsage))
      ..addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
    final zipBytes = ZipEncoder().encode(archive); // List<int>

    // 5. Build user-facing filename (D-09 local-time YYYYMMDD-HHMM)
    final now = DateTime.now();
    final stamp = DateFormat('yyyyMMdd-HHmm').format(now);
    final filename = 'not-to-do-list-export-$stamp.zip';

    // 6. Hand to SAF plugin
    final path = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: Uint8List.fromList(zipBytes),
        fileName: filename,
        mimeTypesFilter: <String>['application/zip'],
      ),
    );
    return path; // null on user cancel
  }

  List<int> _toCsv(String tableName, List<dynamic> rows) {
    // Header row = Drift column names verbatim (D-10).
    // Timestamps formatted as ISO-8601 UTC (D-12).
    // ... (implementation; ~30 lines using utf8.encode)
    throw UnimplementedError(); // planner authors the actual rows
  }
}
```

**Critical note on `mimeTypesFilter`:** `flutter_file_dialog`'s field is `mimeTypesFilter` not `mimeTypeFilter` (no 's') — verify against the package API at install time. The system picker uses the first entry as the suggested type.

### Pattern 3: Drift transactional reset with FK-aware order

**What:** Single Drift `transaction { delete().go() × 5 }` block; `PRAGMA foreign_keys = ON` already set in `beforeOpen` (verified `lib/data/database/app_database.dart` lines 50–52).
**When to use:** Wipe-everything reset; not for selective deletes.
**Source:** `drift ^2.33.0` + verified Drift docs

```dart
// lib/features/settings/services/reset_controller.dart (sketch)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResetController {
  ResetController(this._db, this._ref);
  final AppDatabase _db;
  final Ref _ref;

  Future<void> resetAll(BuildContext context) async {
    // 1. Drift wipe — single transaction. Delete child tables FIRST to avoid
    //    cascade re-fire complications (although CASCADE is enabled per
    //    Phase 1 lines 51–52, explicit child-first delete is idiomatic + safer).
    await _db.transaction(() async {
      await _db.delete(_db.dailyCheckins).go();
      await _db.delete(_db.pauseEvents).go();
      await _db.delete(_db.dailyStreak).go();
      await _db.delete(_db.dailyUsageSummary).go();
      await _db.delete(_db.blockList).go();
    });

    // 2. SharedPreferences wipe (per D-14, includes onboarding-complete flag).
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 3. Invalidate Riverpod providers that cached pref-derived state.
    //    Without this, the home screen could flash an inconsistent snapshot
    //    before the GoRouter redirect fires.
    _ref.invalidate(onboardingCompleteProvider);
    _ref.invalidate(themeModeProvider);
    _ref.invalidate(reminderTimeProvider);
    _ref.invalidate(streakThresholdProvider);
    _ref.invalidate(postNotificationsGrantedProvider);

    // 4. Route — the redirect guard at app_router.dart line 33 will
    //    confirm `onboardingCompleteProvider` is false and route to welcome.
    //    Explicit go() avoids the race window: invalidate is async-resolved,
    //    but go() forces immediate navigation.
    if (context.mounted) context.go('/onboarding/welcome');
  }
}
```

**FK delete order:** `daily_checkins`, `pause_events`, `daily_streak`, `daily_usage_summary` all FK-reference `block_list.id` per Phase 1 schema. Deleting child rows first is defensive. Even though `PRAGMA foreign_keys = ON` + cascade is enabled, explicit ordering eliminates any cascade-trigger-during-transaction nuance.

### Pattern 4: PRIVACY.md as SoT — bundle + GitHub Pages

**What:** Single `PRIVACY.md` source of truth lives at `/docs/PRIVACY.md` in the repo. Two consumers:
1. **Public URL** — GitHub Pages auto-publishes from `/docs/` on `main` branch. Configurable via: repo Settings → Pages → "Build and deployment" → Source: "Deploy from a branch" → Branch: "main" → Folder: "/docs". URL becomes `https://{username}.github.io/{repo-name}/PRIVACY` (note: no `.md` extension in published URL).
2. **In-app render** — Asset bundle entry `assets/PRIVACY.md` that points at the same file via a symlink or a pre-build copy step. Simpler: just declare `docs/PRIVACY.md` as an asset in `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - docs/PRIVACY.md
   ```
   Then in PrivacyScreen: `rootBundle.loadString('docs/PRIVACY.md')`.

**Privacy URL for Play Console Data Safety form:** `https://{username}.github.io/{repo-name}/PRIVACY`

**Recommended `/docs/_config.yml` (optional, suppresses default Jekyll theme noise):**
```yaml
# /docs/_config.yml (minimal — only if planner wants to suppress Jekyll defaults)
theme: null
plugins: []
```
This is **optional**; the default Jekyll auto-rendering of `.md` is acceptable for a Privacy Policy. If skipped, GitHub Pages still serves PRIVACY.md as styled HTML.

**Privacy Policy URL guarantee for Play:** Play Console rejects in-app-only privacy policies. The public URL is non-negotiable per Play policy (verified). Even zero-data-collection apps must supply the URL.

### Pattern 5: Wrap existing AccessibilityStep for Settings → Disclosure

**What:** Add `/settings/disclosure` route that reuses `AccessibilityStep` widget directly. No new copy.
**When to use:** Re-entry into prominent-disclosure copy from anywhere outside onboarding.
**Source:** `lib/features/onboarding/pages/accessibility_step.dart` (verified — contains all 5 verbatim phrases enforced by `prominent_disclosure_test.dart`)

```dart
// In app_router.dart routes list:
GoRoute(
  path: '/settings/disclosure',
  builder: (_, __) => const AccessibilityStep(),
),
```

**Subtle issue:** `AccessibilityStep` (verified lines 51–55, 81–85) calls `context.go('/onboarding/permissions/battery-opt')` on success and skip. When reached from Settings, this would jump to onboarding — wrong.

**Two options:**
1. **Recommended:** add an optional `bool fromSettings = false` constructor param to `AccessibilityStep`. When `true`, replace the post-success / post-skip navigation with `context.pop()`. Surgical change (~5 lines, two `if` branches).
2. **Alt:** create a thin `DisclosureScreen` wrapper that re-implements `RationaleScreen` with the same body but with `onSkip: () => context.pop()` and no `onPrimaryCta`. Duplicates the body Text widgets — risks divergence from the 5-verbatim-phrases grep, which would break the existing `prominent_disclosure_test.dart`.

**Pick option 1.** The phrase-grep test reads only the body Text widgets; the navigation branches are out of the grep scope. Option 1 keeps the SoT single.

### Pattern 6: GoRouter post-reset re-route — no `refreshListenable` needed

**What:** After `SharedPreferences.clear()` + provider invalidation, call `context.go('/onboarding/welcome')` directly. The existing redirect guard (verified `lib/core/router/app_router.dart` lines 26–43) reads `onboardingCompleteProvider.value` — once cleared + invalidated, the guard naturally permits the welcome route.
**When to use:** State-clearing flows where you can synchronously dispatch the desired route.
**Why no `refreshListenable`:** The router already re-evaluates redirect on every navigation. Explicit `go()` after invalidation is simpler than threading a Listenable.

### Anti-Patterns to Avoid

- **Reading `await SharedPreferences.getInstance()` from a `Provider` build method without `AsyncNotifier`.** Riverpod 3.3 patterns require `AsyncNotifier` for async-loaded persistent state. The hand-written `streakThresholdProvider` (Phase 5) is the project's canonical reference; don't deviate.
- **Modifying `AppTheme.light/dark` to accept a `ThemeMode` arg.** Phase 6 only affects `MaterialApp.router.themeMode`, never the ThemeData itself. Color seed continues to flow from `DynamicColorBuilder`.
- **Calling `db.delete(table).go()` per-row in a loop.** Drift's `delete(table).go()` with no where deletes all rows in one statement (verified). Loop is wasteful + non-transactional risk.
- **Calling `flutter_file_dialog.saveFile` without `mimeTypesFilter`.** Some OEM file pickers fall back to "any" file extension and the user can't visually identify the zip. Pass `['application/zip']` (note: **`mimeTypesFilter`** is the field name — verify the spelling against the package version at install).
- **Adding a `RefreshListenable` to GoRouter for the reset flow.** Unnecessary — explicit `context.go` after invalidate is simpler and avoids dragging the router into state-observation.
- **Re-rendering PRIVACY.md content inside `lib/features/settings/pages/privacy_screen.dart` as a Dart string constant.** Breaks SoT — every PRIVACY.md edit would require a Dart edit. Use asset bundle.
- **Letting the SAF mock-test path call real Android intents.** Wrap `FlutterFileDialog.saveFile` behind a `FileSavePort` interface that the widget tests stub via mocktail. This is the same Pigeon→port pattern Phase 3/4/5 used for `UsageApi` / `AccessibilityApi` / `NotificationApi`.

### Streak Threshold Tile (Claude's Discretion #1)

**Recommendation: ship option (a) — inline thin Streak section above Appearance.**

The Phase 5 `ReminderSettingsScreen` (verified `lib/features/reminder/pages/reminder_settings_screen.dart` lines 47–53) already contains a `ListTile` "Streak threshold" with subtitle `'Streak breaks after $thresholdValue min/day'` that opens `_ThresholdDialog` (Slider 1..60). The cleanest Phase 6 move:

**Option a.i (most surgical):** Add a "Streak" section header above "Appearance" in the new `SettingsScreen` containing exactly that tile, calling the same `streakThresholdProvider`. Visually:
```
Reminder
  Daily reminder ........... 10:00 PM >

Streak                       ← new section
  Streak threshold ......... 5 min/day >

Appearance
  Theme  [Light] [Dark] [System]
```

**Option a.ii (cleaner long-term):** Move the threshold tile **out of** `ReminderSettingsScreen` (which becomes a single-purpose reminder-time screen as its name implies) and **into** the new Settings hub. Phase 5 D-08 was a soft lock for "surfaced in Settings under `Streak`" — the actual Settings hub is Phase 6, so this completes the promise.

Both are valid. (a.ii) is the cleaner architecture but is more code motion; (a.i) is surgical. **Researcher recommends (a.i) for Phase 6** because (a.ii) costs ~50 lines of route + screen-rename plumbing for marginal cleanup. The planner can revisit in v1.x.

**If planner picks (b) defer:** 06-VERIFICATION.md must document the broken Phase 5 D-08 promise, and the Settings tile order stays `Reminder → Appearance → Data → Privacy → About` (no Streak section).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ZIP file write | `dart:io` byte concatenation | `archive: ^4.0.9` `ZipEncoder().encode(Archive)` | ZIP format is non-trivial (local file headers, central directory, CRC32). pure-Dart `archive` handles it correctly. |
| Android Storage Access Framework integration | Hand-rolled MethodChannel calling `ACTION_CREATE_DOCUMENT` | `flutter_file_dialog: ^3.0.3` `FlutterFileDialog.saveFile` | Plugin handles activity-result delivery, URI lifecycle, and the back-pressure of byte writes through `OutputStream`. ~30 lines Kotlin saved, edge cases (URI not writable, picker dismissed, content provider null) already handled. |
| Markdown rendering | Hand-rolled regex → `RichText` | `flutter_markdown_plus: ^1.0.7` `Markdown(data: ...)` | CommonMark + GFM has 20+ block types. A regex-based "good enough" renderer is two days of bugs. Plus actively maintained successor to deprecated upstream. |
| App version + build number reading | Hand-rolled MethodChannel reading `BuildConfig` | `package_info_plus: ^10.1.0` | Already a Flutter Favorite-tier plugin; zero reason to re-author. |
| CSV escaping | Manual string concatenation | Hand-write a single 15-line `_escape(String s)` that wraps fields containing `,`, `"`, or `\n` in quotes (RFC 4180) | This IS small enough to hand-roll once. The `csv` package is fine but `archive` already pulls `path` + `posix` — every additional dep extends absence-grep test runtime. v1's exported data has clean column shapes; a 15-line `_escape` suffices. |
| ThemeMode persistence | Custom Drift table | `shared_preferences` int with `AsyncNotifier` (D-07 lock) | Already the project's int-pattern via `reminder_hour_minute` / `streak_threshold_minutes`. |

**Key insight:** v1 is intentionally a thin app. Every dependency added needs to (1) solve a problem that's expensive to hand-roll, AND (2) pass the absence-grep transitive-dep audit. `archive`, `flutter_file_dialog`, `flutter_markdown_plus`, `package_info_plus` all clear both bars; CSV escaping doesn't clear bar #1.

## Runtime State Inventory

> Phase 6 has a reset flow that wipes state. This inventory documents what state exists and what the reset must clear.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data — Drift | 5 tables: `block_list`, `daily_checkins`, `daily_streak`, `pause_events`, `daily_usage_summary`. All FK-rooted at `block_list.id` with CASCADE delete configured (Phase 1) + `PRAGMA foreign_keys = ON` (verified `lib/data/database/app_database.dart` lines 51–52). | `ResetController` runs `transaction { delete(table).go() × 5 }` in child-first order. |
| Stored data — SharedPreferences | Verified keys in tree: `OnboardingKeys.cursor` (`onboarding_step`), `OnboardingKeys.complete` (`onboarding_complete`), `OnboardingKeys.lastKnownFingerprint` (`last_known_fingerprint`), `StreakKeys.streakThresholdMinutes`, reminder time int (`reminder_hour_minute`), post-notifications grant cache. Phase 6 ADDS `theme_mode` int. | `SharedPreferences.clear()` wipes ALL keys per D-14. No keys must be preserved (no FCM token — N/A; no device-id — N/A). |
| Live service config | Reminder alarm registered via `AlarmManager.setExactAndAllowWhileIdle()` (Phase 5 Plan 05-05). | **Open question for planner:** does Reset need to cancel the pending alarm? Per Phase 5, `BootReceiver` re-arms from `reminder_hour_minute` prefs; if prefs are cleared, next boot won't re-arm. But a pending pre-clear alarm could still fire. **Recommend:** add a single `NotificationApi.cancelDailyReminder()` call to `ResetController` after `prefs.clear()`. Verify the Pigeon method exists; if not, planner adds it. |
| OS-registered state | Three permissions in user-granted state: Usage Access, AccessibilityService, battery-opt exemption. POST_NOTIFICATIONS too if user granted. | **None — by design (D-14: "Permissions stay granted (system-level, not app data)").** After reset, the welcome funnel will re-detect them as granted via existing onResume auto-advance and fast-forward through the steps. |
| Secrets / env vars | None in v1. No FCM token, no API key, no signing material outside `~/.android/debug.keystore` (managed by Android Studio). Phase 6 introduces upload keystore for Play App Signing — managed by Google, not stored in app data. | None — Reset doesn't touch keystores. |
| Build artifacts | After version bump to `1.0.0+1`, the existing `build/app/outputs/` directory may contain a stale `0.1.0` APK. | `flutter clean` before the Play upload build. Document in 06-VERIFICATION.md runbook. |

**Bookkeeping artifact lock:** `STATE.md` "Active Todos" and "Files of Record" reference Phase 5 status. Phase 6 plans must NOT touch these until phase-exit (per existing per-phase pattern — see Phase 4 Plan 04-08, Phase 5 Plan 05-09 final bookkeeping tasks).

## Common Pitfalls

### Pitfall 1: Play Console rejects AccessibilityService declaration on first submission

**What goes wrong:** Closed-track review bounces with "your app's use of AccessibilityService doesn't fit our policy" or "missing in-app prominent disclosure" or "video doesn't demonstrate the disclosed use."

**Why it happens:** Three known patterns in 2026 enforcement (post Jan-28 + Apr-15 policy updates):
1. **Missing demo video.** The form requires a video URL even when `isAccessibilityTool="false"`. Showing only screenshots fails. The video must demonstrate: app open → user adds an entry → user opens a blocked app → pause screen appears.
2. **Declaration form copy doesn't match in-app disclosure.** Reviewer reads the form text, then opens the app, looks for the disclosure screen, and rejects on mismatch. Our SoT (`docs/play-declaration.md`) is good — but the planner must copy it **verbatim** into the form, not paraphrase.
3. **"In-app prominent disclosure" reachable from Settings ≠ shown before grant.** Phase 2 already nailed this (AccessibilityStep before the Settings deep-link). Phase 6 Settings → Disclosure is a SUPPLEMENTARY surface; PLAY-06 is already satisfied at onboarding. Don't let the planner accidentally remove the onboarding screen.

**How to avoid:** Add three tasks to the Play funnel plan:
- Record a 30–60 sec screencast on real Pixel: cold open → quick-add Instagram → tap Instagram → pause screen renders → record file uploaded to YouTube unlisted → URL pasted into form.
- Set Permission Declaration form text to byte-identical copy from `docs/play-declaration.md` sections 1–4.
- Verify AccessibilityStep is still reachable BEFORE the user is sent to Settings (existing Phase 2 flow — don't touch).

**Warning signs:** Form preview shows "(no video URL provided)" — that's a soft-reject before submission.

### Pitfall 2: Reset race — home screen flashes pre-reset state before route changes

**What goes wrong:** User taps Reset; the dialog closes; the home screen briefly shows the old entries list before `/onboarding/welcome` mounts.

**Why it happens:** Drift `delete().go()` is async; `prefs.clear()` is async; the StreamProvider over `watchAll()` re-emits an empty list (good), but the `onboardingCompleteProvider` value is cached in Riverpod until invalidated. The redirect guard doesn't re-fire until next navigation.

**How to avoid:** In `ResetController`, after `prefs.clear()`:
1. Invalidate all prefs-backed providers (themeModeProvider, onboardingCompleteProvider, reminderTimeProvider, streakThresholdProvider, postNotificationsGrantedProvider).
2. Immediately call `context.go('/onboarding/welcome')` (don't wait for redirect to re-evaluate).

This is the pattern Phase 6 Plan 4 (Reset) MUST follow.

**Warning signs:** Widget test where you tap Reset and then `pump()` once — you see an unexpected blockListRow widget.

### Pitfall 3: `flutter_file_dialog.saveFile` returns null on user cancel — must not be treated as error

**What goes wrong:** Planner writes `if (path == null) showSnackBar('Export failed')` — but user just hit Back, no error.

**How to avoid:** Treat `null` return as silent cancel. Only show SnackBar (`Export failed. Check available storage and try again.` per UI-SPEC) when an exception is thrown.

```dart
try {
  final path = await FlutterFileDialog.saveFile(params: params);
  if (path == null) return; // user cancelled — silent
  showSnackBar('Export saved');
} catch (e) {
  showSnackBar('Export failed. Check available storage and try again.');
}
```

### Pitfall 4: `archive` package's `Uint8List` vs `List<int>` typing

**What goes wrong:** `ZipEncoder().encode(archive)` returns `List<int>?` (nullable). `flutter_file_dialog` wants `Uint8List`.

**How to avoid:** Always wrap: `Uint8List.fromList(zipBytes ?? <int>[])` — and assert `zipBytes != null` first since a valid archive should always encode to non-null.

### Pitfall 5: APK decode strings sweep misses `classes2.dex` / `classes3.dex` (multidex)

**What goes wrong:** Test greps `classes.dex` only; if app crosses 64 K methods, R8 emits `classes2.dex` and the telemetry token could hide there.

**Why it happens:** Android supports multidex for apps over the 64 K-method ceiling. With Flutter + Drift + Riverpod + Pigeon we're likely under the limit, but R8 minification + obfuscation behavior is build-version-sensitive.

**How to avoid:** Sweep `classes*.dex` not `classes.dex`:
```bash
unzip -p build/app/outputs/apk/release/app-release.apk classes*.dex | strings | grep -iE '(firebase|crashlytics|analytics|fcm|remoteconfig)'
```
Expected output: **(empty)**. If non-empty, fail the test.

Note: `unzip -p` with a glob behaves correctly on macOS BSD `unzip` and Linux `unzip` (both 6.0+). On macOS the `strings` binary ships with the base system (Mach-O variant); on Linux it's `binutils`. Both accept stdin and produce comparable output for our absence-grep use.

### Pitfall 6: `flutter_markdown_plus` link-tap behavior

**What goes wrong:** Markdown link in PRIVACY.md (e.g., `mailto:` or external URL) — by default `flutter_markdown_plus` ignores taps; user reports "the link doesn't work."

**How to avoid:** For v1's privacy policy, **don't include external links** in PRIVACY.md (calm-tone + on-device + no-backend implies no external referrals anyway). If a link is needed, pass `onTapLink: (text, href, title) => launchUrl(Uri.parse(href!))` using the existing `url_launcher ^6.3.0` dep. Defer this only if the planner explicitly needs links.

### Pitfall 7: `package_info_plus` version-vs-buildNumber confusion

**What goes wrong:** Planner writes `'${pi.version}+${pi.buildNumber}'` and gets `"1.0.0+1+1"` instead of `"1.0.0+1"` because they confused the field semantics.

**Why it happens:** Flutter `pubspec.yaml`'s `version: 1.0.0+1` parses as `version = "1.0.0"`, `buildNumber = "1"`. The `+` is the *separator*, not part of either field.

**How to avoid:** About tile format per UI-SPEC: `"${pi.version} (${pi.buildNumber})"` → renders as `"1.0.0 (1)"`. Don't use `+` glue.

### Pitfall 8: GitHub Pages "Settings → Pages" requires Pages enabled at the org level

**What goes wrong:** Repo settings page doesn't have a "Pages" section.

**Why it happens:** On free GitHub Personal accounts, Pages is enabled by default. On Organizations or Enterprise, Pages may be disabled at org level.

**How to avoid:** Confirm the project's GitHub repo is under a Personal account (most solo dev case) or that the org has Pages enabled. If not, the planner falls back to publishing the Privacy Policy URL via any other static host that gives a public stable URL.

### Pitfall 9: Drift `getAll()` may not exist on every DAO

**What goes wrong:** ExportController assumes each DAO has `getAll()` returning `List<RowData>`. Existing DAOs may only expose narrower methods like `getCurrent(entryId)` or `watchAll()`.

**How to avoid:** Wave 0 audit task — read each DAO file, list its public methods, and the export plan adds `Future<List<TableRowData>> getAll()` where missing. Trivial additions (one line each).

**DAOs verified in tree (per `lib/data/database/app_database.dart` line 24):** `BlockListDao`, `DailyUsageSummaryDao`, `PauseEventDao`, `DailyCheckinsDao`, `DailyStreakDao`. Phase 2 already shipped `BlockListDao.watchAll()`; planner verifies the rest.

### Pitfall 10: Closed-track tester invitation timing

**What goes wrong:** Plan lists "add tester emails" as one task. In practice, testers must opt-in via a link Play Console emails them, and there's a 15-min–24-hour propagation delay before they can download the build.

**How to avoid:** Plan separates "configure testers" from "verify testers can download." The OEM-survival overnight gate (success criterion 5) requires real Xiaomi + Samsung devices running the closed-track APK — the planner sequences "submit closed → wait for review → wait for tester propagation → install on Samsung → run overnight → install on Xiaomi → run overnight" as the actual sequence.

## Code Examples

> All snippets are verified patterns. URLs for verification listed in §Sources.

### Example 1: Hand-written `AsyncNotifier<ThemeMode>` (full file)

See Pattern 1 above (full file body is reproduced there).

### Example 2: Build ZIP from `Archive` and write to SAF URI

```dart
// Source: archive ^4.0.9 + flutter_file_dialog ^3.0.3
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

Future<String?> exportZip(Map<String, List<int>> filesByName, String filename) async {
  final archive = Archive();
  for (final entry in filesByName.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  final zipBytes = ZipEncoder().encode(archive); // List<int>
  return FlutterFileDialog.saveFile(
    params: SaveFileDialogParams(
      data: Uint8List.fromList(zipBytes),
      fileName: filename,
      mimeTypesFilter: <String>['application/zip'],
    ),
  );
}
```

### Example 3: Drift transactional reset

```dart
// Source: drift ^2.33.0 — drift.simonbinder.eu/dart_api/writes/
await db.transaction(() async {
  await db.delete(db.dailyCheckins).go();
  await db.delete(db.pauseEvents).go();
  await db.delete(db.dailyStreak).go();
  await db.delete(db.dailyUsageSummary).go();
  await db.delete(db.blockList).go();
});
```

Per the Drift docs, `delete(table).go()` with **no where clause** deletes all rows. `transaction` wraps the calls so either all succeed or none do — important because a partial wipe would leave the user in an inconsistent state.

### Example 4: Render bundled markdown asset

```dart
// Source: flutter_markdown_plus ^1.0.7 + flutter rootBundle
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('docs/PRIVACY.md'),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return Markdown(data: snap.data!);
        },
      ),
    );
  }
}
```

### Example 5: About tile via package_info_plus

```dart
// Source: package_info_plus ^10.1.0
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutTile extends StatelessWidget {
  const AboutTile({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (ctx, snap) {
        final subtitle = snap.hasData ? '${snap.data!.version} (${snap.data!.buildNumber})' : '—';
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          subtitle: Text(subtitle),
        );
      },
    );
  }
}
```

### Example 6: APK absence-grep one-liner (extended invariant test)

```dart
// To append to test/policy/play_invariants_test.dart
test('PLAY-09: pubspec.lock contains no telemetry deps', () {
  final src = File('pubspec.lock').readAsStringSync().toLowerCase();
  for (final token in <String>[
    'firebase', 'crashlytics', 'analytics', 'fcm', 'remoteconfig',
  ]) {
    expect(
      src.contains(token),
      isFalse,
      reason: 'PLAY-09: pubspec.lock contains forbidden telemetry token "$token"',
    );
  }
});

test('PLAY-09: release APK classes*.dex strings contain no telemetry tokens', () {
  final apk = File('build/app/outputs/apk/release/app-release.apk');
  if (!apk.existsSync()) {
    // CI may not have built release yet; mark skip rather than fail.
    return; // (or markTestSkipped — gsd-planner picks)
  }
  // Shell out — Dart has no native zip-read + strings combinator.
  // Use Process.runSync so failure is surfaced as test failure.
  final result = Process.runSync('sh', <String>[
    '-c',
    "unzip -p '${apk.path}' 'classes*.dex' | strings | "
        "grep -iE '(firebase|crashlytics|analytics|fcm|remoteconfig)' | head -5",
  ]);
  expect(
    (result.stdout as String).trim(),
    isEmpty,
    reason: 'PLAY-09: release APK contains forbidden telemetry tokens:\n${result.stdout}',
  );
});
```

## Play Console Closed-Track Funnel

This section condenses the locked subflow from research into a runbook the planner converts to a single plan + checklist. Order matters; some screens block submit.

### Screens / forms required for first-time closed-track submission

| # | Screen / Form | Required? | Phase 6 specifics |
|---|---------------|-----------|-------------------|
| 1 | App access (test account creds) | If app gates content behind login | **N/A** — no auth in v1 |
| 2 | Ads (declaration) | **Yes** | "No, my app does not contain ads" |
| 3 | Content rating | **Yes** | Submit IARC questionnaire — "Reference, news, education" / "No violence" / etc. Likely "Everyone." |
| 4 | Target audience | **Yes** | "13+" or "18+" (adult self-control framing → 18+ safer; planner picks). |
| 5 | News app | **No** | "Not a news app" |
| 6 | COVID-19 contact tracing | **No** | "Not a contact tracing app" |
| 7 | Data Safety | **Yes (blocking)** | Per `docs/data-safety.md`: "No data collected." Privacy Policy URL: GitHub Pages URL. **Even zero-data apps must complete and supply URL.** [VERIFIED: Google docs] |
| 8 | Government apps | **No** | "Not a government app" |
| 9 | Financial features | **No** | "No financial features" |
| 10 | Health | **No** | "No health features" |
| 11 | Permission Declaration — AccessibilityService | **Yes (blocking)** | Copy verbatim from `docs/play-declaration.md`. Upload demo video URL. [CITED: support.google.com/googleplay/android-developer/answer/10964491] |
| 12 | App content (everything above) summary | **Yes** | Auto-aggregated; review for consistency |
| 13 | Store listing — Main store listing | **Yes** | Short description (80 char), full description (4000 char), graphics |
| 14 | Store listing — Graphics | **Yes** | 1 app icon (512×512 PNG, alpha) + 1 feature graphic (1024×500) + 2-8 phone screenshots |
| 15 | Pricing & distribution — Countries | **Yes** | Select countries; default "all available" |
| 16 | Pricing & distribution — Free or paid | **Yes** | Free |
| 17 | Closed testing — Create track | **Yes** | "Closed testing" → track name "Closed alpha" or similar |
| 18 | Closed testing — Tester list | **Yes** | Email list (5–20 testers); include developer's own Google account first |
| 19 | Closed testing — Release | **Yes** | Upload `.aab`, fill release notes, save → review → roll out |

### AccessibilityService Permission Declaration form fields (2026)

Per current Play Console support page (verified 2026-05-24):

For apps with `isAccessibilityTool="false"` (our case):

1. **Core feature description** — paste paragraph from `docs/play-declaration.md` §2.
2. **Usage justification** (radio): "App functionality" / "Analytics" / "Developer communications" / "Fraud prevention" / "Advertising or marketing" / "Personalization" / "Account management." → **Select "App functionality."**
3. **Data collection through accessibility** (yes/no): → **"No."**
4. **Data types collected** (if yes): N/A — we answered No.
5. **Demonstration video URL** (YouTube unlisted is acceptable): **REQUIRED.** Video must show: app open → quick-add demo entry → tap entry → pause screen renders → cooldown → close.

### Data Safety form (re-verified 2026-05-24)

Per current Play Console support page:

1. Section 1: "Does your app collect or share any of the required user data types?" → **No.**
2. Section 2: "Is all of the user data collected by your app encrypted in transit?" → **N/A.**
3. Section 3: "Do you provide a way for users to request that their data is deleted?" → **Yes.** (Settings → Reset all data, per SETT-02.)
4. **Privacy Policy URL field** — REQUIRED EVEN FOR ZERO-COLLECTION APPS. [VERIFIED]
5. Data Types — all 14 categories → "Not collected."

### Release-track strategy

Per D-15:
1. **Internal testing** (up to 100 testers, instant review, no policy review):
   - Add developer Google account as tester
   - Upload `.aab` (version 1.0.0+1)
   - Verify install on developer's own Pixel / Samsung
   - Shake out store listing copy + Data Safety entries before triggering policy review
2. **Closed testing** (triggers real Play policy review on AccessibilityService):
   - Promote the same build from Internal
   - Add 5–20 named testers
   - Submit for review
   - Wait 1–7 days for review verdict
3. **STOP at closed-track PASS** (per D-15 + ROADMAP Phase 6 success criterion 3).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter_markdown` (Google-maintained) | `flutter_markdown_plus` (Foresight Mobile-maintained) | Q1 2026 (Google deprecated) | Plans MUST use `_plus`. Direct dep on `flutter_markdown` would still build but signals stale knowledge. |
| `archive ^3.x` | `archive ^4.0.9` | 2026-02-17 release | API 4.x adds `OutputFileStream` + `OutputMemoryStream` for cleaner stream output. Existing `ZipEncoder().encode(archive)` shape unchanged. |
| `file_picker.saveFile` on Android | `flutter_file_dialog.saveFile` | ongoing — issues #832, #882, #1885 unresolved | Plans using `file_picker.saveFile` with bytes silently miswrite. |
| `package_info` | `package_info_plus ^10.1.0` | 2026-04-21 (current) | `_plus` is the supported, multi-platform-aware successor. |
| Hand-rolled MethodChannel for SAF | `flutter_file_dialog` plugin | n/a (always preferred) | Plugin handles activity-result race conditions Flutter alone can't. |
| Google Play "Internal track only" submission strategy | Internal → Closed → Production funnel | Play Console default since 2022 | Phase 6 stops at Closed per v1 stop-point. |

**Deprecated/outdated:**
- `flutter_markdown`: official deprecation per flutter/flutter#162966; use `flutter_markdown_plus`.
- `package_info`: replaced by `package_info_plus`.
- Reading `ApplicationInfo.flags` for telemetry detection: superseded by direct pubspec.lock + APK strings sweep (our absence-grep pattern).
- The old "isAccessibilityTool" trick to bypass declaration: hard policy-violation since Jan 28, 2026. Already locked out by Phase 1 manifest config.

## Assumptions Log

> Tracking all `[ASSUMED]` claims so the planner / discuss-phase can confirm before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `file_saver` package as `flutter_file_dialog` alternative has smaller community footprint | §Standard Stack → Alternatives | Low — `flutter_file_dialog` recommendation stands regardless; this is a footnote comparison |
| A2 | Drift `getAll()` may not exist on every DAO in tree | §Pitfall 9 | Low — Wave 0 audit verifies; if all DAOs already have it, that task collapses to a no-op |
| A3 | Plan should add `NotificationApi.cancelDailyReminder()` to ResetController | §Runtime State Inventory | Low — confirmed pattern in Phase 5 Plan 05-05; planner verifies Pigeon method exists, adds 5-line patch if not |
| A4 | Phase 6 needs zero new Pigeon channels | §Architectural Responsibility Map | Medium — confirmed by reading existing channels; if Reset's cancelDailyReminder turns out to need new Kotlin work, plan grows by 1 plan |
| A5 | The 4000-char full description copy is a planner-authored task; no existing draft | §Code Context (Specific Ideas) | Low — listing copy is a Plan deliverable; not a research gap |
| A6 | Phase 6 plans target ~8 plans total | §Summary | Low — orientation only; planner sizes |

## Open Questions

1. **Streak threshold tile placement (a.i vs a.ii vs b)** — researcher recommends (a.i); planner makes the final call when authoring 06-PLAN-01.
2. **Disclosure screen wrapping** — option 1 (add `fromSettings` param to `AccessibilityStep`) vs option 2 (DisclosureScreen wrapper). Researcher recommends option 1. Planner decides; if option 1 picked, the existing `prominent_disclosure_test.dart` source-grep continues passing without modification.
3. **CSV escaping** — hand-roll 15-line `_escape` (researcher rec.) vs add `csv` package dep. If planner picks csv package, the absence-grep transitive-dep audit needs re-running.
4. **Reset cancels pending alarm?** — recommended yes, via `NotificationApi.cancelDailyReminder()`. Verify Pigeon method exists; add if not. Plan deliverable.
5. **GitHub Pages publish layout** — researcher recommends `/docs/` folder on main. Planner confirms repo is on Personal GitHub account (or Pages-enabled org).
6. **Demo video URL** — required by Play form. Planner adds a recording task. Camera capture on real Pixel or Samsung Galaxy S20 Ultra; YouTube unlisted upload.
7. **Internal-testing tester list seeding** — planner picks: just developer email vs developer + 1-2 friends for sanity. Either works.

## Environment Availability

> Phase 6 has tooling dependencies (Play Console submission steps, decoded-APK strings sweep). Verified on this dev machine.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build APK, run tests | ✓ | 3.41.x (per project STACK lock) | — |
| Dart SDK | All Dart code | ✓ | 3.10+ (per package_info_plus 10.1.0 requirement) | — |
| Android SDK (compileSdk 36) | Build release APK | ✓ | 36 (per `android/app/build.gradle.kts` line 10) | — |
| Java 17 | Android build + package_info_plus 10.x | ✓ | per `build.gradle.kts` line 14 | — |
| `unzip` (BSD or InfoZip) | APK strings sweep (Pitfall 5 test) | ✓ (macOS ships BSD unzip) | — | n/a (universal) |
| `strings` (binutils or Mach-O) | APK strings sweep | ✓ (macOS ships Mach-O `strings`) | — | n/a (universal) |
| `sh` for `Process.runSync` test wrapper | APK strings sweep | ✓ (POSIX) | — | n/a |
| Google Play Console account | PLAY-08 submission | ✓ (assumed — solo dev has one to ship) | — | None — blocks PLAY-08 if missing. Planner verifies in first Play funnel plan. |
| `gh` CLI or browser access to GitHub repo Settings | GitHub Pages publish | Assumed ✓ | — | Manual via web UI |
| Real Xiaomi device | Success criterion 5 overnight | Status unknown; not on dev machine | — | **BLOCKING** — planner must surface as device-acquisition task |
| Real Samsung device | Success criterion 5 overnight | ✓ (Samsung Galaxy S20 Ultra 5G — used for REL-04 PASS, see STATE.md) | — | — |
| YouTube unlisted upload capability | Demo video URL for Permission Declaration | Assumed ✓ | — | Can host video elsewhere (Google Drive, Vimeo) |

**Missing dependencies with no fallback:**
- **Real Xiaomi device** — must be acquired or borrowed before Phase 6 success criterion 5 is met. CD-03 Option A path from Phase 4 used Samsung; Phase 6 needs both.

**Missing dependencies with fallback:**
- None — all software-side deps present.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + `mocktail ^1.0.5` |
| Config file | `analysis_options.yaml` (very_good_analysis ^10.2.0 — `pubspec.yaml`) |
| Quick run command | `flutter test test/features/settings/` (Phase 6 feature scope) |
| Full suite command | `flutter test` |
| Phase invariant suite | `flutter test test/policy/play_invariants_test.dart` |
| Release APK build | `flutter build apk --release` (output: `build/app/outputs/apk/release/app-release.apk`) |
| Phase gate | All of: `flutter test` exit 0 + APK build succeeds + `flutter pub deps` shows no telemetry tokens + APK strings sweep returns empty |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SETT-04 | Theme provider persists int + reloads on cold start | unit | `flutter test test/features/settings/providers/theme_mode_provider_test.dart -p chrome` | ❌ Wave 0 |
| SETT-04 | `MaterialApp.router.themeMode` rebuilds on provider change | widget | `flutter test test/app/theme_rebuild_test.dart` | ❌ Wave 0 |
| SETT-04 | SegmentedButton tap writes prefs + updates provider state | widget | `flutter test test/features/settings/widgets/theme_tile_test.dart` | ❌ Wave 0 |
| SETT-01 | Export builds ZIP whose contents round-trip equal Drift state | unit | `flutter test test/features/settings/services/export_controller_test.dart` | ❌ Wave 0 |
| SETT-01 | Export filename matches `not-to-do-list-export-YYYYMMDD-HHMM.zip` pattern | unit | (same file, separate `test()` block) | ❌ Wave 0 |
| SETT-01 | data.json envelope has `schemaVersion: 1` + `tables` keys + ISO-8601 UTC | unit | (same file) | ❌ Wave 0 |
| SETT-01 | Export → SAF returns null on user cancel without error | widget | `flutter test test/features/settings/pages/export_screen_test.dart` | ❌ Wave 0 |
| SETT-02 | Reset wipes all 5 Drift tables transactionally | unit | `flutter test test/features/settings/services/reset_controller_test.dart` | ❌ Wave 0 |
| SETT-02 | Reset clears all SharedPreferences keys (incl. onboarding flag) | unit | (same file) | ❌ Wave 0 |
| SETT-02 | Reset navigates to /onboarding/welcome | widget | `flutter test test/features/settings/pages/settings_reset_dialog_test.dart` | ❌ Wave 0 |
| SETT-02 | Reset AlertDialog cancel-default-focused; body copy verbatim | widget | (same file) | ❌ Wave 0 |
| SETT-05 | Privacy screen renders bundled markdown without exception | widget | `flutter test test/features/settings/pages/privacy_screen_test.dart` | ❌ Wave 0 |
| SETT-05 | /settings/disclosure route renders existing AccessibilityStep (5 phrases pass) | widget | `flutter test test/features/settings/pages/disclosure_route_test.dart` + existing `prominent_disclosure_test.dart` continues passing | ❌ Wave 0 (new); existing test stays |
| PLAY-08 | pubspec.lock contains no telemetry tokens (firebase/crashlytics/analytics/fcm/remoteconfig) | unit | `flutter test test/policy/play_invariants_test.dart` | ✓ (append-only extend) |
| PLAY-08 | Release APK classes*.dex strings contain no telemetry tokens | integration | (same file, separate `test()` — uses `Process.runSync('sh', ['-c', 'unzip -p ... | strings | grep ...'])`) | ✓ (append-only extend) |
| PLAY-08 | About tile shows "1.0.0 (1)" format | widget | `flutter test test/features/settings/widgets/about_tile_test.dart` | ❌ Wave 0 |
| PLAY-08 / success criterion 5 | Full happy-path overnight on real Xiaomi AND Samsung | manual | runbook in 06-VERIFICATION.md (BLOCKING gate) | ❌ Wave 0 (template) |

### Sampling Rate

- **Per task commit:** `flutter test test/features/settings/` (Phase 6 scope, fast)
- **Per wave merge:** `flutter test` (full suite, ~30s)
- **Phase gate before `/gsd-verify-work`:** Full suite green + `flutter build apk --release` succeeds + extended absence-grep tests green + manual REL-bookend overnight gate signed off

### Wave 0 Gaps

- [ ] `test/features/settings/providers/theme_mode_provider_test.dart` — covers SETT-04 persistence
- [ ] `test/app/theme_rebuild_test.dart` — covers SETT-04 widget rebuild on provider change
- [ ] `test/features/settings/widgets/theme_tile_test.dart` — covers SETT-04 SegmentedButton interaction
- [ ] `test/features/settings/services/export_controller_test.dart` — covers SETT-01 round-trip + filename + envelope
- [ ] `test/features/settings/pages/export_screen_test.dart` — covers SETT-01 SAF mock + cancel behavior
- [ ] `test/features/settings/services/reset_controller_test.dart` — covers SETT-02 transactional wipe + prefs clear
- [ ] `test/features/settings/pages/settings_reset_dialog_test.dart` — covers SETT-02 AlertDialog focus order + verbatim copy + navigation
- [ ] `test/features/settings/pages/privacy_screen_test.dart` — covers SETT-05 markdown render
- [ ] `test/features/settings/pages/disclosure_route_test.dart` — covers SETT-05 disclosure re-render from Settings
- [ ] `test/features/settings/widgets/about_tile_test.dart` — covers PLAY-08 version format
- [ ] `test/features/settings/pages/settings_screen_test.dart` — covers tile order D-04 + gear icon entry from Home
- [ ] Extend `test/policy/play_invariants_test.dart` (append-only) — add pubspec.lock telemetry-token absence + APK strings sweep
- [ ] `06-VERIFICATION.md` — overnight gate runbook template (Xiaomi + Samsung)
- [ ] `assets/PRIVACY.md` or `docs/PRIVACY.md` declared in `pubspec.yaml` assets — bundled
- [ ] `docs/play-listing/` skeleton — short-description.txt, full-description.txt, screenshots/

**Test framework install:** Already present (`flutter_test` SDK + `mocktail ^1.0.5`). No new test deps needed.

**FileSavePort interface (mocking SAF in widget tests):**
```dart
// lib/features/settings/services/file_save_port.dart
abstract class FileSavePort {
  Future<String?> saveZip({required Uint8List data, required String fileName});
}

class FlutterFileDialogSavePort implements FileSavePort {
  @override
  Future<String?> saveZip({required Uint8List data, required String fileName}) =>
      FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          data: data,
          fileName: fileName,
          mimeTypesFilter: const <String>['application/zip'],
        ),
      );
}

// Tests inject MockFileSavePort via Riverpod override.
```
This is the canonical Pigeon-port-mock pattern Phase 3/4/5 already established.

### Pre-Submit OEM-Survival Overnight Gate (Success Criterion 5)

This is the Phase 6 exit gate (REL bookend; not a new REL-XX requirement). Format mirrors Phase 4 REL-04 and Phase 5 REL-05.

**9-step protocol (template for 06-VERIFICATION.md):**
1. Install release APK on real Samsung Galaxy S20 Ultra (or equivalent OneUI 5+)
2. Cold-launch app, complete onboarding from `/onboarding/welcome`
3. Quick-add Instagram (and 1 habit entry)
4. Set daily reminder to a near-future time
5. Lock phone, leave on charger overnight (8+ hours)
6. Next morning: reminder fires within 5 min of scheduled time → notification tap deep-links to checkin
7. Open Instagram → pause screen renders within <1s
8. Streak rolls over for the new day; check-in submission idempotent
9. Repeat steps 1–8 on Xiaomi device

**Evidence pattern (per Phase 4 REL-04):** logcat snippets + screenshots saved under `.planning/phases/06-polish-play-store-submission/evidence/` with timestamp file names.

**STOP gate:** Type "PHASE-6 OEM PASS" to proceed to `/gsd-verify-work` → Play Console submit. Without this signal, the planner must not flip 06-VERIFICATION.md to `status: complete`.

## Security Domain

> Phase 6 is UI/IA + submission. The only new attack surface is the export flow (writes user data to user-chosen location) and the reset flow (data-loss flow).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | App is auth-free by PROJECT.md |
| V3 Session Management | no | No sessions |
| V4 Access Control | yes — implicit | Reset flow requires user-initiated tap + two-step confirmation (D-13). No remote API to require ACL |
| V5 Input Validation | yes — export | CSV field escaping (15-line `_escape`) prevents formula injection (`=cmd|...`-style cells) when user opens CSV in Excel. **Planner must add this:** prefix any field starting with `=`, `+`, `-`, `@` with a single quote (CSV injection mitigation, see OWASP) |
| V6 Cryptography | no — by design | All data is on-device. No transit. Drift uses default SQLite (no SQLCipher in v1 — out of scope) |
| V7 Errors & Logging | yes | Export / Reset must not log entry names or reasons to any log surface (calm tone + privacy stance) |
| V8 Data Protection | yes | Export writes user data; SAF URI handoff ensures user picks the destination — no app-private dump |

### Known Threat Patterns for Flutter on Android v1 (Phase 6)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CSV formula injection (export contains `=cmd|'...'!A1` in a reason field) | Tampering (downstream tool, not app) | Pre-quote fields starting with `= + - @` per OWASP CSV-Injection guidance |
| Export written to world-readable location (e.g., legacy `/sdcard/Download/`) | Information Disclosure | SAF-only handoff ensures user owns the chosen destination; do not fall back to `path_provider.getExternalStorageDirectory()` |
| Reset stuck mid-transaction (e.g., process killed) leaving DB partially wiped | Denial of Service (user state) | `transaction { ... }` ensures atomicity; on resume, partial state is impossible |
| Privacy screen renders user-controlled markdown (XSS-equivalent) | n/a — markdown is bundled, not user input | N/A in v1; defer to v1.x if user-supplied markdown ever ships |
| Demo video URL accidentally points to a non-existent / private YouTube video | n/a (Play review flag) | Planner adds verification step: "open the URL in incognito browser" before submitting Permission Declaration |
| Privacy Policy URL on GitHub Pages becomes 404 after repo rename | Information Disclosure (Play form mismatch) | Plan adds a manual test: `curl -sIL ${GITHUB_PAGES_URL} | head -1` returns `200 OK` before Play submit. Document in 06-VERIFICATION.md |

## Sources

### Primary (HIGH confidence)

- **pub.dev — archive** `https://pub.dev/packages/archive` — current 4.0.9 verified 2026-05-24; pure-Dart ZIP writer; addFile/addArchiveFile/ZipEncoder shapes
- **pub.dev — flutter_file_dialog** `https://pub.dev/packages/flutter_file_dialog` — current 3.0.3 verified; `SaveFileDialogParams(data: bytes)` on Android
- **pub.dev — flutter_markdown_plus** `https://pub.dev/packages/flutter_markdown_plus` — current 1.0.7 verified; Foresight Mobile maintains; GitHub-Flavored Markdown default
- **pub.dev — package_info_plus** `https://pub.dev/packages/package_info_plus` — current 10.1.0 verified; Java 17 + AGP ≥8.12.1
- **GitHub flutter/flutter#162966** `https://github.com/flutter/flutter/issues/162966` — confirms `flutter_markdown` deprecation
- **GitHub miguelpruivo/flutter_file_picker#832, #882, #1885** — confirm `file_picker.saveFile` broken on Android with bytes
- **Drift docs — writes** `https://drift.simonbinder.eu/dart_api/writes/` — `delete(table).go()` deletes all rows; transaction shape
- **Google Play Console — AccessibilityService Permission Declaration** `https://support.google.com/googleplay/android-developer/answer/10964491?hl=en` — current 2026 form fields, video required
- **Google Play Console — Data Safety form** `https://support.google.com/googleplay/android-developer/answer/10787469?hl=en` — Privacy Policy URL required even for zero-data apps
- **Google Play Console — Permission declarations** `https://support.google.com/googleplay/android-developer/answer/9214102?hl=en` — declaration submission flow
- **GitHub Docs — Pages publishing source** `https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site` — /docs folder configuration
- **archive 4.0.9 docs — ZipFileEncoder** `https://pub.dev/documentation/archive/latest/archive_io/ZipFileEncoder-class.html` — API surface verified

### Project-internal (HIGH — read in this session)

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/06-polish-play-store-submission/06-CONTEXT.md` — 16 locked decisions
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/06-polish-play-store-submission/06-UI-SPEC.md` — UI design contract
- `/Users/jintanakhomwong/projects/not-to-do-list/docs/play-declaration.md` — Permission Declaration SoT
- `/Users/jintanakhomwong/projects/not-to-do-list/docs/data-safety.md` — Data Safety form SoT
- `/Users/jintanakhomwong/projects/not-to-do-list/test/policy/play_invariants_test.dart` — 10 absence-grep invariants to extend
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/app.dart` — `MaterialApp.router` integration point
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/theme/app_theme.dart` — `AppTheme.light/dark` (DO NOT modify)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/router/app_router.dart` — GoRouter with redirect guard, lines 26–43
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/app_database.dart` — Drift DB + `PRAGMA foreign_keys = ON`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/streak/providers/streak_threshold_provider.dart` — canonical AsyncNotifier pattern
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/storage_keys.dart` — SharedPreferences key registry
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/pages/accessibility_step.dart` — verbatim disclosure phrases (re-used)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/reminder/pages/reminder_settings_screen.dart` — Streak threshold tile (Phase 5; relevant to Discretion #1)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/home/pages/home_screen.dart` — AppBar.actions insertion point
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/build.gradle.kts` — version + signing config
- `/Users/jintanakhomwong/projects/not-to-do-list/pubspec.yaml` — existing pin set
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` — SETT/PLAY traceability
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` — Phase 6 success criteria
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/STATE.md` — current state + open items
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/config.json` — workflow config (`nyquist_validation: true`)
- `/Users/jintanakhomwong/projects/not-to-do-list/CLAUDE.md` — project + user instructions

### Secondary (MEDIUM confidence — community blog / SO)

- **Foresight Mobile blog** `https://foresightmobile.com/blog/flutter-markdown-plus-google-handover` — flutter_markdown_plus takeover narrative
- **dev.to "Onboarding With Go Router"** `https://dev.to/kcl/onboarding-with-go-router-in-flutter-2jd6` — refreshListenable patterns
- **Medium @cryptax "Multidex trick to unpack Android/BianLian"** `https://cryptax.medium.com/multidex-trick-to-unpack-android-bianlian-ed52eb791e56` — classes*.dex sweep technique

### Tertiary (LOW confidence — flagged)

- None — every recommendation is HIGH/MEDIUM confidence and cross-referenced.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every package version verified on pub.dev 2026-05-24
- Architecture: HIGH — mirrors established project patterns (AsyncNotifier from Phase 5, Pigeon-port from Phases 3/4/5, transactional Drift writes from Phase 2 LIST-05)
- Pitfalls: HIGH — all 10 cross-checked against Google Play docs, package issue trackers, or existing project verification patterns
- Play Console funnel: HIGH — verified against current Google support pages 2026-05-24
- Validation Architecture: HIGH — extends existing `play_invariants_test.dart` pattern, all 17 test files mapped to specific commands

**Research date:** 2026-05-24
**Valid until:** 2026-06-24 (30 days; longer than fast-moving Flutter ecosystem norm because the locked stack — Flutter 3.41, Riverpod 3.3, Drift 2.33 — has multi-month stability windows)

## RESEARCH COMPLETE
