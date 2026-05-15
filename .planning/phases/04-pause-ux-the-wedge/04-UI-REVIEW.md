# Phase 04 — UI Review: Pause UX (the wedge)

**Audited:** 2026-05-15
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md for Phase 4)
**Screenshots:** Not captured — no dev server detected (Flutter Android app, no web build running)
**Code audit scope:** All files in `lib/features/pause/`, `lib/core/theme/app_theme.dart`, `lib/app.dart`, `lib/core/router/app_router.dart`, `android/.../PauseActivity.kt`

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | D-08 fixed-copy contract honored; "✓ Cooldown complete" lacks typographic emphasis; straight ASCII quotes instead of curly |
| 2. Visuals | 2/4 | Duplicate "X:XX remaining" caption rendered in two locations simultaneously; D-01 dynamicColor=false violated on Android 12+ |
| 3. Color | 3/4 | No hardcoded colors in pause feature; two semantic colors correctly used; D-01 forest-green seed lost to Android 12+ Material You on real devices |
| 4. Typography | 3/4 | Four distinct M3 text styles used appropriately; DoneConfirmationCard has no explicit text style (defaults to bodyMedium — too small for a completion moment) |
| 5. Spacing | 4/4 | All spacing values are multiples of 4 (4/8/16/20/24/32); consistent M3 scale throughout; no arbitrary pixel values |
| 6. Experience Design | 3/4 | Loading and error states for entry lookup handled; no accessibility semantics on icon characters; no disabled state on Cancel while DB write is in-flight |

**Overall: 18/24**

---

## Top 3 Priority Fixes

1. **Duplicate "X:XX remaining" caption** — When a cooldown chip is tapped, the text "X:XX remaining" appears twice: once inside the top-pinned `CooldownProgressBar` (at the top of the screen, above `SafeArea`) and once inline below the chip row in `pause_screen.dart`. The user sees two identical countdown captions in different screen positions. Fix: strip the `Text` from `CooldownProgressBar` (keep only `LinearProgressIndicator`), leaving the caption solely in `pause_screen.dart:114-118` where D-05 specifies "below the selected chip."

2. **D-01 dynamicColor=false violated on Android 12+ devices** — The locked design decision `D-01` states "M3 `dynamicColor: false` (consistent identity)." The implementation in `lib/app.dart:14-20` uses `DynamicColorBuilder` and passes `lightDynamic` / `darkDynamic` directly to `AppTheme.light(dynamic: lightDynamic)`. On any Android 12+ device where `lightDynamic != null`, the forest-green seed (`0xFF2D6A4F`) is entirely replaced by the system wallpaper palette. Every pause-screen color token (`surfaceContainerHighest`, `FilledButton` primary, `LinearProgressIndicator` track) changes to arbitrary wallpaper-derived colors. The calm/mindful forest-green identity that is the rationale for D-01 does not survive on the majority of real target devices. Fix: pass `null` instead of `lightDynamic`/`darkDynamic` to enforce the seed, or add an explicit `null`-coalescing override in `AppTheme.light` to always use the seed.

3. **DoneConfirmationCard text has no explicit style — inherits bodyMedium** — The completion card (`lib/features/pause/widgets/done_confirmation_card.dart:18`) renders `Text('✓ Cooldown complete')` with no `style` parameter. Inside a `Card`, Flutter's default is `bodyMedium` (approximately 14sp). This is the same text scale used for secondary body copy throughout the app — making the completion moment feel as visually light as a label. The ✓ symbol is also not semantically labeled for screen readers. Fix: apply `theme.textTheme.titleLarge` (or at minimum `titleMedium`) to give the completion moment appropriate visual weight, and wrap in `Semantics(label: 'Cooldown complete')` to announce it correctly.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**WARNING: Good contract adherence with two minor issues.**

The D-08 fixed-copy contract is faithfully implemented. All eight locked strings are present:

- `'Cooldown:'` — `lib/features/pause/widgets/cooldown_chip_row.dart:37`
- `'1m'`, `'3m'`, `'5m'`, `'10m'` — `lib/features/pause/widgets/cooldown_chip_row.dart:25-28`
- `'X:XX remaining'` format — `lib/features/pause/pages/pause_screen.dart:158` and `lib/features/pause/widgets/cooldown_progress_bar.dart:47`
- `'Cancel'` — `lib/features/pause/pages/pause_screen.dart:128`
- `'Use anyway'` — `lib/features/pause/pages/pause_screen.dart:136`
- `'✓ Cooldown complete'` — `lib/features/pause/widgets/done_confirmation_card.dart:18`

No puppet-voice copy detected. The empty-reason path (`AppNameHero`) correctly renders only the display name with a trailing period — no "Pause and reflect" or injected commentary (D-03). The with-reason path (`ReasonHero`) renders the user's verbatim text wrapped in quote characters.

**Minor issues:**

1. **Straight quotes instead of curly quotes in ReasonHero.** `reason_hero.dart:24` uses `'"$reasonText"'` — ASCII straight double-quotes (`"..."`) rather than Unicode curly/smart quotes (`"..."`). D-02 specifies "quote glyphs." The M3 italic serif card is the visual hero; ASCII straight quotes weaken the intended typographic effect. Replace with `'“$reasonText”'` (left/right double quotation marks).

2. **"✓ Cooldown complete" copy is correct per D-07, but the ✓ character has no screen-reader semantic.** The Unicode CHECK MARK (U+2713) is read by TalkBack as "check mark" which is acceptable, but there is no `Semantics` wrapper to control the announcement. This is a copy/accessibility boundary issue.

No generic labels found. No "Submit", "OK", "Click Here", or "No data" patterns. No error state user-facing copy issues. The loading spinner has no label text — this is acceptable since the entry loads in under one frame on real devices.

---

### Pillar 2: Visuals (2/4)

**WARNING: Two structural visual defects identified.**

**BLOCKER-class defect: Duplicate "X:XX remaining" caption.**

`CooldownProgressBar` (`lib/features/pause/widgets/cooldown_progress_bar.dart:29-38`) renders a `Column` containing:
- `LinearProgressIndicator` (correct — the pinned top bar)
- `SizedBox(height: 4)`
- `Text('$minutes:${...} remaining', style: bodySmall)` (this is the extra caption)

This widget is placed via `Positioned(top: 0, left: 0, right: 0)` in a `Stack` (`pause_screen.dart:74-82`). The `Positioned` widget has no `bottom` constraint, so the Column sits fully in the absolute top of the screen — the caption renders below the `LinearProgressIndicator` at the very top of the screen, outside `SafeArea`.

Separately, `pause_screen.dart:114-118` renders an identical caption inline:
```dart
if (session.cooldownChosenSeconds != null)
  Text(
    _formatRemaining(session.remainingMs ?? 0),
    style: Theme.of(context).textTheme.bodySmall,
  ),
```

When a chip is selected: two "X:XX remaining" captions appear simultaneously — one at the top of the screen (potentially obscured by status bar) and one below the chip row. The misleading comment at `pause_screen.dart:111-113` says "The top-pinned bar handles the LinearProgressIndicator; the caption is shown below the chip row" — this comment is incorrect; the top bar renders both. Neither the test suite nor the UAT caught this because manual testers may not have noticed the duplicated text in different positions.

**WARNING: D-01 dynamicColor=false violated — visual identity not enforced on Android 12+.**

D-01 decision lock: "forest-green seed `0xFF2D6A4F`, Material 3 `dynamicColor: false`." But `lib/app.dart` wraps the entire app in `DynamicColorBuilder` and passes `lightDynamic` directly to `AppTheme`. On any Android 12+ device with a non-green wallpaper (the majority of real users), the pause screen renders in the system's Material You palette, not the calm forest-green identity. The `surfaceContainerHighest` card color, `LinearProgressIndicator` progress color, `FilledButton` fill, and `TextButton` foreground all change to arbitrary wallpaper-derived tones.

Note: this is a pre-existing Phase 2 decision that Phase 4 inherited. Phase 4's implementation `pause_screen.dart` correctly makes no color overrides and relies on the theme. The violation is in `lib/app.dart` and `lib/core/theme/app_theme.dart`. However, Phase 4's D-01 explicitly locked "dynamicColor: false" and the implementation never enforced this.

**Remaining visual positives:**
- Clear focal point: reason quote-card (with-reason path) or large display-name text (empty-reason path) is visually the heaviest element.
- Asymmetric button hierarchy correctly implemented: `FilledButton` for Cancel, `TextButton` for Use anyway (`pause_screen.dart:126-138`).
- `LinearProgressIndicator` pinned to top edge via `Positioned(top:0)` — correct positioning.
- `SegmentedButton` with `emptySelectionAllowed: true` and no default selection — correct implementation.
- `DoneConfirmationCard` is fullscreen (`pause_screen.dart:52-54`), giving the completion moment visual weight.

---

### Pillar 3: Color (3/4)

**WARNING: No hardcoded colors in pause feature; design system used correctly at the implementation level. D-01 identity enforcement is the concern.**

Hardcoded color audit across all pause feature files: zero occurrences of `Color(0x`, `Colors.`, or hex literals. All color usage is through `theme.colorScheme.*`:

- `theme.colorScheme.surfaceContainerHighest` — used in `ReasonHero` (`reason_hero.dart:20`) and `DoneConfirmationCard` (`done_confirmation_card.dart:15`) for the card fill. Correct: a contained surface that reads as secondary background.
- `LinearProgressIndicator` — uses theme's `ColorScheme.primary` by default. On the forest-green seed, this is a deep green, which is appropriate.
- `FilledButton` (Cancel) — uses `ColorScheme.primary` fill. Correct for primary action emphasis.
- `TextButton` (Use anyway) — uses `ColorScheme.primary` text. Correct for de-emphasized action.

The only color concern is the dynamic color issue documented in Pillar 2: on Android 12+ devices, all `colorScheme.*` values are system-derived rather than forest-green-derived, undermining the calm/mindful brand identity.

Health check banner hardcoded colors (pre-existing from Phase 2): `lib/features/health/widgets/health_check_banner.dart:29-32` contains four hardcoded hex values (`_amberBgLight`, `_amberFgLight`, `_amberBgDark`, `_amberFgDark`). These are not in the pause feature scope but are present in the app that renders around the pause screen. Pre-existing; not a Phase 4 introduction.

---

### Pillar 4: Typography (3/4)

**WARNING: Four text styles used appropriately, but completion card lacks explicit style.**

Text styles used in the pause feature:

| Element | Style | File |
|---------|-------|------|
| Reason quote-card | `headlineSmall` + `FontStyle.italic` | `reason_hero.dart:25-26` |
| App display name (empty reason) | `displayMedium` | `app_name_hero.dart:18` |
| "Cooldown:" label | `titleMedium` | `cooldown_chip_row.dart:37` |
| "X:XX remaining" caption | `bodySmall` | `pause_screen.dart:117`, `cooldown_progress_bar.dart:35` |
| Button labels (Cancel, Use anyway) | Inherited from M3 `FilledButton`/`TextButton` defaults (labelLarge) | — |
| "✓ Cooldown complete" | **No style — inherits bodyMedium** | `done_confirmation_card.dart:18` |
| Chip labels (1m/3m/5m/10m) | Inherited from M3 `SegmentedButton` defaults (labelLarge) | — |

The hierarchy is meaningful: `displayMedium` (largest, empty-reason hero) > `headlineSmall` (with-reason hero) > `titleMedium` (section label) > `bodySmall` (countdown caption). This respects the D-02/D-03 intention that the hero is the "heaviest element on the screen."

The `labelSmall` override in `app_theme.dart:31` (14sp instead of M3 default 11sp) is correct per Phase 2 contract and applies globally.

**Defect:** `DoneConfirmationCard` at `done_confirmation_card.dart:18` uses `Text('✓ Cooldown complete')` with no `style`. Inside a `Card`, Flutter defaults to `bodyMedium` (~14sp, regular weight). The completion moment is the last thing the user sees — it should be at minimum `titleMedium` (16sp, medium weight) to feel like a resolved state rather than label copy.

No typography issues with fonts: the app uses system fonts (no custom font imports in the pause feature), which is consistent with M3 defaults.

---

### Pillar 5: Spacing (4/4)

**Good: All spacing follows a consistent 4-base grid with no arbitrary values.**

Spacing values identified across all pause feature files:

| Value | Usage | File |
|-------|-------|------|
| 4px | Between progress bar and its caption | `cooldown_progress_bar.dart:32` |
| 8px | After chip row header "Cooldown:"; after chip row | `cooldown_chip_row.dart:38`, `pause_screen.dart:109` |
| 16px | Horizontal button gap (Cancel / Use anyway); bottom screen padding | `pause_screen.dart:132`, `pause_screen.dart:142` |
| 20px | ReasonHero card vertical inner padding | `reason_hero.dart:22` |
| 24px | Screen horizontal margin; before button row; ReasonHero card horizontal inner padding | `pause_screen.dart:88`, `pause_screen.dart:120`, `reason_hero.dart:22` |
| 32px | DoneConfirmationCard horizontal inner padding | `done_confirmation_card.dart:17` |

All values are multiples of 4 — consistent with M3's 4dp base grid. The `Spacer` usage between hero and chip row is appropriate for distributing vertical space on different screen heights. No arbitrary pixel values (e.g., `SizedBox(height: 13)`) found.

The `ConstrainedBox(maxWidth: 360)` on `ReasonHero` (`reason_hero.dart:17`) provides a sensible reading-width cap that prevents the quote card from spanning the full width of large screens. This is good UX for text legibility.

---

### Pillar 6: Experience Design (3/4)

**WARNING: Core states are handled; gaps in accessibility semantics and write-in-progress feedback.**

**Covered states:**

- **Loading:** `pause_screen.dart:58` — `entryAsync.when(loading: () => CircularProgressIndicator())`. The BlockList entry is loaded asynchronously on screen mount; a spinner is shown during the wait. This is the correct pattern.
- **Error / entry deleted:** `pause_screen.dart:59-63` — `error: (_, __) { unawaited(SystemNavigator.pop()); return SizedBox.shrink(); }`. Fail-closed behavior: if the entry was deleted between Intent build and Flutter mount, the screen silently dismisses without writing a row. Correct.
- **Hard-block omission:** `pause_screen.dart:131` — `if (blockMode == 'soft')` guard removes `Use anyway` from widget tree entirely for hard entries. Verified in tests.
- **Race condition guard (double-write):** `pause_controller.dart:84` — `if (state.isComplete) return;` prevents double DB writes when timer drain races with user tap.
- **PauseActivity fail-closed:** `android/.../PauseActivity.kt:46-53` — invalid Intent extras cause `finish()` before engine bind. T-02 correct.

**Gaps:**

1. **No accessibility semantics on the ✓ checkmark or CooldownProgressBar.** The `LinearProgressIndicator` has no `semanticsLabel`. TalkBack on Android would announce its value numerically but has no label explaining "cooldown progress." The `✓ Cooldown complete` text has no wrapping `Semantics` node. For a self-control app used by adults who may rely on accessibility features, this is a gap.

2. **No disabled state on Cancel while DB write is in-flight.** After the user taps Cancel (or Use anyway), `PauseController._writeOutcomeAndClose` executes `await repo.insertOutcome(...)` then `await Future.delayed(1500ms)`. During this window, the screen still shows the main UI (not `DoneConfirmationCard` for cancel — only outcome 0 triggers it). The Cancel button remains tappable. `state.isComplete` guard prevents double-writes, but the user gets no visual feedback that their tap was registered. A brief disabled state or immediate navigation would clarify the intent.

3. **CooldownProgressBar rendered at `Positioned(top:0)` without `SafeArea` protection.** The progress bar renders at the absolute top of the screen, which on Android includes the status bar area. On devices where the status bar overlaps the content area, the `LinearProgressIndicator` may be partially obscured. The main content area is correctly wrapped in `SafeArea` (`pause_screen.dart:85`), but the `Positioned` bar is not. This is a cosmetic edge case on older OEMs with opaque status bars.

4. **No haptic feedback on chip selection or button press.** D-04 describes the chip tap as "one mindful tap is the minimum activation cost." No `HapticFeedback.lightImpact()` or similar is called on chip selection. This is a nice-to-have for a self-control interaction point, not a blocker.

---

## Files Audited

**Flutter Dart (pause feature):**
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/pages/pause_screen.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/widgets/reason_hero.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/widgets/app_name_hero.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/widgets/cooldown_chip_row.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/widgets/cooldown_progress_bar.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/widgets/done_confirmation_card.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/controllers/pause_controller.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/providers/pause_providers.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/models/pause_session.dart`

**Flutter Dart (shared infrastructure):**
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/theme/app_theme.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/app.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/router/app_router.dart`

**Android Kotlin:**
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt`

**Tests (for intent verification):**
- `/Users/jintanakhomwong/projects/not-to-do-list/test/features/pause/pause_screen_test.dart`
- `/Users/jintanakhomwong/projects/not-to-do-list/test/features/pause/widgets/cooldown_progress_bar_test.dart`

**Planning artifacts (for design contract):**
- `.planning/phases/04-pause-ux-the-wedge/04-CONTEXT.md` (D-01..D-16)
- `.planning/phases/04-pause-ux-the-wedge/04-PLAN-OVERVIEW.md`
- `.planning/phases/04-pause-ux-the-wedge/04-07-SUMMARY.md`
- `.planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md`
- `.planning/phases/04-pause-ux-the-wedge/04-UAT.md`

---

## Registry Safety

No `components.json` found — shadcn not initialized. Registry audit skipped entirely.

---

## UI REVIEW COMPLETE
