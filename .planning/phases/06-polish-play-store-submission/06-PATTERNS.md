# Phase 6: Polish & Play Store Submission - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 17 (12 new Dart files + 4 edits + 1 test extension; plus asset/gradle/docs edits)
**Analogs found:** 16 / 17 (1 file — `flutter_file_dialog` port — has no in-tree analog; uses Pigeon-port pattern from Phase 1)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/features/settings/providers/theme_mode_provider.dart` | Riverpod AsyncNotifier (persistent state) | shared_preferences read/write → AsyncValue<ThemeMode> | `lib/features/streak/providers/streak_threshold_provider.dart` | exact (mirror) |
| `lib/features/settings/pages/settings_screen.dart` | M3 sectioned ListView Screen (ConsumerWidget) | reactive read of providers | `lib/features/reminder/pages/reminder_settings_screen.dart` | exact (same role) |
| `lib/features/settings/pages/export_screen.dart` | Single-action Screen (ConsumerWidget) | trigger controller, SnackBar feedback | `lib/features/reminder/pages/reminder_settings_screen.dart` (Scaffold/ListView shell) | role-match |
| `lib/features/settings/pages/privacy_screen.dart` | FutureBuilder Markdown Screen | `rootBundle.loadString` → render | None in tree (new pattern); shell mirrors `reminder_settings_screen.dart` | role-match |
| `lib/features/settings/widgets/section_header.dart` | M3 section label widget | static text | `lib/features/list/widgets/block_mode_segmented.dart` (small stateless widget shape) | partial |
| `lib/features/settings/widgets/theme_tile.dart` | Inline `SegmentedButton<ThemeMode>` ListTile | read+write `themeModeProvider` | `lib/features/list/widgets/block_mode_segmented.dart` | exact (M3 SegmentedButton) |
| `lib/features/settings/widgets/about_tile.dart` | Display ListTile with `package_info_plus` | FutureBuilder | `lib/features/pause/widgets/done_confirmation_card.dart` (small stateless tile) | partial |
| `lib/features/settings/services/export_controller.dart` | Service / controller (data → bytes → SAF) | DAOs.getAll → CSV/JSON → ZIP → port.save | None (new flow); composes existing DAO pattern + new `FileSavePort` (Pigeon-port style) | role-match |
| `lib/features/settings/services/reset_controller.dart` | Service / controller (mutating transaction) | Drift txn → prefs.clear → invalidate → `context.go` | `lib/features/reminder/providers/reminder_providers.dart` `.set()` (atomic side-effect sequence) | role-match |
| `lib/features/settings/services/file_save_port.dart` | Port interface (test seam over plugin) | Uint8List in → URI string out | `lib/platform/notification_api.g.dart` Pigeon-port convention | role-match |
| `lib/core/router/app_router.dart` (edit) | GoRoute registration | declarative route table | Existing `/settings/reminder` entry at line 58 | exact (append) |
| `lib/app.dart` (edit) | `MaterialApp.router` field add | `ref.watch(themeModeProvider)` → `themeMode:` | Existing watch pattern at lines 13–22 | exact (surgical add) |
| `lib/features/home/pages/home_screen.dart` (edit) | AppBar `actions` widget add | `IconButton` → `context.go('/settings')` | Existing notifications `IconButton` at lines 54–61 | exact (clone-and-prepend) |
| `lib/features/onboarding/storage_keys.dart` (edit) | shared_preferences key constant add | static const | Existing `cursor` / `complete` constants at lines 6–9 | exact (append) |
| `lib/features/onboarding/pages/accessibility_step.dart` (edit) | Constructor param + nav-branch fork | `bool fromSettings = false` → `context.pop()` vs `context.go(...)` | `lib/features/pause/pages/pause_screen.dart` `blockMode` param (route-time switch) | role-match |
| `test/policy/play_invariants_test.dart` (edit) | Absence-grep invariant tests (append-only) | File.readAsStringSync + RegExp + Process.runSync (APK) | Existing 10 invariants in same file + `test/policy/phase_5_invariants_test.dart` telemetry test | exact (mirror group) |
| `pubspec.yaml` (edit) | dep add | declarative | Existing deps lines 17–29 | exact (append) |
| `android/app/build.gradle.kts` (edit) | version bump | Gradle DSL | Existing `defaultConfig` lines 21–28 | exact (already references flutter.versionName) |
| `assets/PRIVACY.md` + `docs/PRIVACY.md` | Asset + docs source | static markdown | New SoT pattern (mirrors `docs/play-declaration.md` SoT) | role-match |
| `docs/play-listing/` (new directory tree) | Static listing assets | text files + images | New (no in-tree analog) | none |

---

## Pattern Assignments

### `lib/features/settings/providers/theme_mode_provider.dart` (Riverpod AsyncNotifier)

**Analog:** `lib/features/streak/providers/streak_threshold_provider.dart` (full file, 52 lines)

**Why this analog:** Both wrap a single shared_preferences int behind a hand-written `AsyncNotifier<T>`. Same file shape, same encoder/decoder helper convention, same `.set(value)` mutation method, same `AsyncNotifierProvider<NotifierClass, T>` final binding at the bottom. Phase 5 D-09 explicitly locks `theme_mode` to mirror this pattern.

**Imports pattern** (lines 1–3):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/streak/storage/streak_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
```
For Phase 6: import `OnboardingKeys` instead (or new `SettingsKeys` — planner picks; CONTEXT D-07 says add `theme_mode` to existing `storage_keys.dart`, i.e., reuse `OnboardingKeys`). Also import `package:flutter/material.dart` for `ThemeMode`.

**Pure helper for encode/decode** (lines 22–25 — `clampStreakThreshold`):
```dart
/// Pure helper — exposed for unit tests.
/// Clamps [raw] to the valid [1, 60] range (T-05-36 mitigation — defense
/// in depth at the provider boundary, even if the picker UI is bypassed).
int clampStreakThreshold(int raw) => raw.clamp(1, 60);
```
For Phase 6: write pure top-level `_decode(int) → ThemeMode` and `_encode(ThemeMode) → int` helpers above the class (RESEARCH §Pattern 1 shows the exact `switch (raw)` body — `0/_ → system, 1 → light, 2 → dark`).

**AsyncNotifier class shape** (lines 28–45):
```dart
class StreakThresholdNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StreakKeys.streakThresholdMinutes) ?? 5;
  }

  Future<void> set(int minutes) async {
    final clamped = clampStreakThreshold(minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StreakKeys.streakThresholdMinutes, clamped);
    state = AsyncValue.data(clamped);
  }
}
```
For Phase 6: identical shape. `build()` reads `prefs.getInt(OnboardingKeys.themeMode) ?? 0` and runs through `_decode`. `set(ThemeMode mode)` writes via `_encode` then sets `state = AsyncValue.data(mode)`. No `ref.read(api).cancelXxx()` side effects — theme is a pure-Flutter rebuild trigger.

**Provider final-binding** (lines 47–51):
```dart
final AsyncNotifierProvider<StreakThresholdNotifier, int>
    streakThresholdProvider =
    AsyncNotifierProvider<StreakThresholdNotifier, int>(
  StreakThresholdNotifier.new,
);
```
For Phase 6: rename to `themeModeProvider` over `<ThemeModeNotifier, ThemeMode>`.

**Conventions to mirror:**
- Hand-written AsyncNotifier — NO `@riverpod` codegen (Phase 1 dropped it; see pubspec.yaml lines 10–14).
- Default value inline via `?? 0` (no separate "DEFAULT_THEME_MODE" constant).
- Encode/decode as pure top-level functions, NOT class methods — supports direct unit testing without instantiating the notifier.
- Doc-comment header references CONTEXT decision number (D-07) and the SoT lock (Phase 1 codegen deviation).

**Differences from analog (what's new this phase):**
- Returns `ThemeMode` (enum) instead of `int`; encode/decode bridges to the stored int form.
- No `ref.read(notificationApiProvider)` side-effect call inside `.set()` — pure prefs write.
- No clamp (`ThemeMode` is an enum; unknown ints fail-safe to `system` in `_decode`).

---

### `lib/features/settings/pages/settings_screen.dart` (M3 sectioned ListView Screen)

**Analog:** `lib/features/reminder/pages/reminder_settings_screen.dart` (full file, 135 lines — the class body lines 14–57)

**Why this analog:** Same role (`/settings/...` ConsumerWidget that hosts ListTiles + dialogs), same Scaffold/AppBar/ListView shape, same `ref.watch(...).maybeWhen(data, orElse)` reading pattern, same locale-aware `DateFormat` subtitle for the reminder tile. Phase 6 expands from 2 tiles to ~8 tiles plus section headers.

**Imports pattern** (lines 1–5):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:not_to_do_list/features/reminder/providers/reminder_providers.dart';
import 'package:not_to_do_list/features/streak/providers/streak_threshold_provider.dart';
```
For Phase 6 SettingsScreen: add `package:go_router/go_router.dart` (for `context.go`), `package:not_to_do_list/features/settings/providers/theme_mode_provider.dart`, plus widget imports for `SectionHeader`, `ThemeTile`, `AboutTile`.

**ConsumerWidget + Scaffold + ListView core pattern** (lines 14–56):
```dart
class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(reminderTimeProvider);
    final thresholdAsync = ref.watch(streakThresholdProvider);

    final hm = reminderAsync.maybeWhen(data: (v) => v, orElse: () => 1260);
    final thresholdValue =
        thresholdAsync.maybeWhen(data: (v) => v, orElse: () => 5);

    final reminderDisplay = DateFormat.jm().format(
      DateTime(2000, 1, 1, hm ~/ 60, hm % 60),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily reminder'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Daily reminder'),
            subtitle: Text(reminderDisplay),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTime(context, ref, hm),
          ),
          // ... more tiles
        ],
      ),
    );
  }
```

**`AlertDialog` action pattern via private dialog widget** (lines 107–134):
```dart
return AlertDialog(
  title: const Text('Streak threshold'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [/* ... */],
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Cancel'),
    ),
    FilledButton(
      onPressed: () => Navigator.of(context).pop(_value),
      child: const Text('OK'),
    ),
  ],
);
```
For Phase 6 Reset dialog: same `AlertDialog` shape with `TextButton(Cancel)` listed FIRST (default-focused per D-13) and `FilledButton(Reset)` SECOND using `FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError)` for destructive accent. UI-SPEC literal body copy: `"This deletes every entry, streak day, pause event, and check-in. This cannot be undone."`

**Conventions to mirror:**
- `ConsumerWidget` (NOT `ConsumerStatefulWidget`) — no per-screen local state.
- `AppBar(centerTitle: false)` — back arrow auto-supplied by GoRouter.
- `ref.watch(provider).maybeWhen(data: (v) => v, orElse: () => DEFAULT)` for safe-default async reads.
- Each tile: `ListTile(leading: Icon(*_outlined), title, subtitle, trailing: chevron_right OR inline widget, onTap)`.
- Helper methods on the ConsumerWidget (`_pickTime`, `_showThresholdPicker`) take `(BuildContext, WidgetRef, currentValue)` — NOT instance state.
- Private dialog widgets prefixed with `_` (e.g., `_ThresholdDialog`, future `_ResetConfirmDialog`).

**Differences from analog (what's new this phase):**
- 5 section headers (`Reminder`, `Appearance`, `Data`, `Privacy`, `About`) via new `_SectionHeader` widget — analog has no sections.
- 7+ tiles vs. 2.
- Mix of navigation tiles (`context.go(...)`), inline tile (Theme `SegmentedButton`), action tile (Reset → AlertDialog), display tile (About).
- Reset tile uses `iconColor: cs.error` + `textColor: cs.error` for destructive color cue.

---

### `lib/features/settings/pages/export_screen.dart` (Single-action Screen)

**Analog:** `lib/features/reminder/pages/reminder_settings_screen.dart` (Scaffold/AppBar/ListView shell) + `lib/features/onboarding/pages/post_notifications_earned_step.dart` lines 72–83 (button-triggered async action with `_onContinue`)

**Why this analog:** Same Scaffold + AppBar + body, single primary action that triggers a controller, awaits result, shows SnackBar feedback.

**Async action handler pattern** (`post_notifications_earned_step.dart` lines 72–83):
```dart
Future<void> _onContinue() async {
  final api = ref.read(permissionStatusApiProvider);
  await api.requestPostNotifications();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(StreakKeys.earnedPromptShown, true);
  if (!mounted) return;
  unawaited(
    ref.read(postNotificationsGrantedProvider.notifier).refresh(),
  );
  if (!mounted) return;
  context.go('/');
}
```

**Conventions to mirror:**
- `ref.read(...)` for one-shot calls (NEVER `ref.watch` for side-effect-only providers).
- `if (!mounted) return;` guard after EVERY `await` before touching `context`.
- `unawaited(...)` wrapper for fire-and-forget refresh calls when subsequent code does not depend on them.
- Use SnackBar (via `ScaffoldMessenger.of(context).showSnackBar(...)`) for export feedback per UI-SPEC copy: `"Export saved"` / `"Export failed. Check available storage and try again."`
- Handle `null` return from `FlutterFileDialog.saveFile` as silent cancel (no SnackBar) — per RESEARCH Pitfall 3.

**Differences from analog (what's new this phase):**
- Triggers `ExportController.exportAll()` (new service) instead of permission API call.
- Wraps action in `try { ... } catch (e) { showSnackBar(failure) }` because SAF I/O can throw, while `requestPostNotifications` cannot.
- Returns to Settings on success, NOT to `/`.

---

### `lib/features/settings/pages/privacy_screen.dart` (Markdown FutureBuilder Screen)

**Analog:** Shell from `lib/features/reminder/pages/reminder_settings_screen.dart` lines 31–34. Markdown render itself is new — closest existing FutureBuilder shape in `lib/features/settings/widgets/about_tile.dart` (also new, this phase).

**Why this analog:** Same Scaffold/AppBar shell. RESEARCH §Code Examples → Example 4 (lines 770–793) shows the verified `flutter_markdown_plus` + `rootBundle.loadString('docs/PRIVACY.md')` pattern. There is no in-tree analog for markdown rendering.

**Reference shape from RESEARCH §Example 4:**
```dart
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

**Conventions to mirror:**
- `StatelessWidget` (no provider read needed; markdown is static).
- `Scaffold(appBar: AppBar(title: Text('Privacy Policy')))` — same `centerTitle: false` (inherited theme).
- `FutureBuilder<String>` with `CircularProgressIndicator` placeholder.
- Asset path `docs/PRIVACY.md` (RESEARCH §Pattern 4 — declare in `pubspec.yaml` `flutter.assets`).

**Differences from analog (what's new this phase):**
- First Markdown render in the codebase — introduces `flutter_markdown_plus` dependency.
- Asset list in `pubspec.yaml` gains `docs/PRIVACY.md` entry (existing assets are `assets/onboarding/` and `assets/logos/` — see pubspec.yaml lines 42–44).

---

### `lib/features/settings/widgets/section_header.dart` (M3 section label)

**Analog:** `lib/features/list/widgets/block_mode_segmented.dart` (small stateless widget structure)

**Why this analog:** Both are small `StatelessWidget` returning a `Padding + Text(style: theme.textTheme.X.copyWith(...))` composition. Same project convention for label-style widgets.

**Imports/class shape** (lines 1–18):
```dart
import 'package:flutter/material.dart';

class BlockModeSegmented extends StatelessWidget {
  const BlockModeSegmented({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Block mode', style: theme.textTheme.titleMedium),
        // ...
```

**Conventions to mirror:**
- Pure `StatelessWidget` with `const` constructor and `required` named fields.
- `final theme = Theme.of(context);` once at top of `build`.
- Style from `theme.textTheme.X.copyWith(color: theme.colorScheme.Y)` — no hard-coded sizes/colors.

**Phase 6 specifics from UI-SPEC §Spacing + §Typography:**
- `Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 4), child: Text(label, style: tt.labelSmall.copyWith(color: cs.primary, letterSpacing: 0.8)))`
- Single required field: `final String label;`
- `labelSmall` is pinned to 14sp project-wide (Phase 2 lock — see `AppTheme._textTheme`).

**Differences from analog:**
- No `ValueChanged` callback (static label).
- Uses `labelSmall` (Android-Settings convention) vs. `titleMedium` in block_mode_segmented.

---

### `lib/features/settings/widgets/theme_tile.dart` (Inline `SegmentedButton<ThemeMode>` ListTile)

**Analog:** `lib/features/list/widgets/block_mode_segmented.dart` lines 25–32 (M3 SegmentedButton usage) + `lib/features/reminder/pages/reminder_settings_screen.dart` lines 39–53 (ListTile + provider read)

**Why this analog:** `block_mode_segmented.dart` is the only existing 3-segment `SegmentedButton` in tree; it shows the exact `segments: const <ButtonSegment<X>>[...]`, `selected: <X>{value}`, `onSelectionChanged: (sel) => onChanged(sel.first)` triad. Phase 6 reuses this shape with `ThemeMode` instead of `String`.

**SegmentedButton pattern from analog** (lines 25–32):
```dart
SegmentedButton<String>(
  segments: const <ButtonSegment<String>>[
    ButtonSegment<String>(value: 'soft', label: Text('Soft')),
    ButtonSegment<String>(value: 'hard', label: Text('Hard')),
  ],
  selected: <String>{value},
  onSelectionChanged: (sel) => onChanged(sel.first),
),
```

**For Phase 6 `ThemeTile`** — convert to `ConsumerWidget` so it can `ref.watch(themeModeProvider)` directly (saves passing value+callback through parent):
```dart
SegmentedButton<ThemeMode>(
  segments: const <ButtonSegment<ThemeMode>>[
    ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('Light')),
    ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('Dark')),
    ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('System')),
  ],
  selected: <ThemeMode>{currentMode},
  onSelectionChanged: (sel) =>
      ref.read(themeModeProvider.notifier).set(sel.first),
),
```

**Conventions to mirror:**
- `ButtonSegment<T>(value, label: Text(...))` — never use `icon:` (calm-tone, label-only per UI-SPEC).
- `selected: <T>{value}` set literal of size 1 (single-select).
- `onSelectionChanged: (sel) => callback(sel.first)` — `.first` is safe because single-select guarantees size 1.
- Wrap inside a `ListTile(title: Text('Theme'), trailing: SegmentedButton<...>(...))` per UI-SPEC §Component Inventory.

**Differences from analog:**
- 3 segments (vs. 2).
- `ConsumerWidget` (vs. `StatelessWidget`) — reads/writes provider directly.
- No subtitle prose row (block_mode_segmented has a 2-line description below; Theme tile uses inline segmented button only).

---

### `lib/features/settings/widgets/about_tile.dart` (Display ListTile with `package_info_plus`)

**Analog:** RESEARCH §Code Examples → Example 5 (lines 797–819) is the verified reference; no in-tree FutureBuilder<PackageInfo> exists yet.

**Reference shape from RESEARCH §Example 5:**
```dart
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

**Conventions to mirror:**
- `StatelessWidget` (FutureBuilder owns the async).
- Em-dash `—` placeholder while loading (matches the home empty-state em-dash convention — see `home_screen_unified_list_test.dart` line 5 reference).
- Format: `"${version} (${buildNumber})"` — RESEARCH Pitfall 7 explicitly warns against `+` glue which would produce `"1.0.0+1+1"`.

**Differences from analog (what's new this phase):**
- First use of `package_info_plus` in the codebase.
- No `onTap` (display-only tile).

---

### `lib/features/settings/services/export_controller.dart` (Service / controller)

**Analog (composition of two):**
1. **DAO read pattern:** `lib/data/database/daos/block_list_dao.dart` lines 26–30 (`getAll() → Future<List<BlockListData>>`). Pause/Streak/Checkins/UsageSummary DAOs need `getAll()` added (per RESEARCH Pitfall 9 — only BlockListDao has it today).
2. **Atomic side-effect controller:** `lib/features/reminder/providers/reminder_providers.dart` lines 24–31 (sequenced `prefs.set → api.cancel → api.schedule → state =`).

**Why this analog:** The export flow is "read 5 DAOs → build bytes → hand to port". The closest existing pattern is `ReminderTimeNotifier.set()` which sequences prefs + api calls. Export is read-only (no state writes) but follows the same async-sequencing discipline.

**DAO getAll() reference** (`block_list_dao.dart` lines 25–30):
```dart
/// All entries sorted by `updatedAt` desc.
Future<List<BlockListData>> getAll() {
  return (select(blockList)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .get();
}
```
For Phase 6: Wave 0 audit task adds `Future<List<XxxData>> getAll()` to each of the 4 remaining DAOs (`PauseEventDao`, `DailyStreakDao`, `DailyCheckinsDao`, `DailyUsageSummaryDao`). Plain `select(xxx).get()` — no ordering required for export.

**ZIP build + SAF handoff sketch (from RESEARCH §Pattern 2 + §Example 2, verified):**
```dart
Future<String?> exportAll() async {
  // 1. Parallel reads
  final futures = await Future.wait([
    _db.blockListDao.getAll(),
    _db.dailyCheckinsDao.getAll(),
    _db.dailyStreakDao.getAll(),
    _db.pauseEventDao.getAll(),
    _db.dailyUsageSummaryDao.getAll(),
  ]);
  // 2..3. CSV (one per table, header row = Drift column names verbatim) + data.json envelope
  // 4. Archive() ..addFile(...) × 6 → ZipEncoder().encode(archive)
  // 5. Filename: 'not-to-do-list-export-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.zip'
  // 6. await _saver.save(Uint8List.fromList(zipBytes), filename, 'application/zip')
}
```

**Conventions to mirror:**
- Constructor takes dependencies (`AppDatabase`, `PackageInfo`, `FileSavePort`) — testable via mocktail-stubbed port.
- All timestamps formatted via `DateTime.toUtc().toIso8601String()` (D-12: `2026-05-24T17:30:00Z`).
- Filename uses LOCAL time (`DateFormat('yyyyMMdd-HHmm').format(DateTime.now())`) per D-09.
- CSV escaping: hand-roll a 15-line `_escape(String) → String` (RFC 4180) per RESEARCH §Don't Hand-Roll exception.
- `Future.wait([...])` for parallel DAO reads.

**Differences from analog (what's new this phase):**
- First service to build composite output (5 CSVs + JSON envelope + ZIP).
- First use of `archive` + `flutter_file_dialog`.
- Behind a `FileSavePort` interface so widget tests stub the SAF call (RESEARCH §Anti-Patterns "Letting the SAF mock-test path call real Android intents").

---

### `lib/features/settings/services/reset_controller.dart` (Mutating service)

**Analog:** `lib/features/reminder/providers/reminder_providers.dart` lines 24–31 (atomic side-effect chain) + `lib/data/database/app_database.dart` lines 36–53 (`MigrationStrategy` shows the Drift transactional pattern).

**Why this analog:** Reset is a 4-step atomic sequence (Drift txn → prefs.clear → invalidate providers → route). The `ReminderTimeNotifier.set()` analog is the closest in-tree example of a sequenced side-effect chain with deterministic ordering.

**Atomic chain reference** (`reminder_providers.dart` lines 24–31):
```dart
Future<void> set(int hm) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(StreakKeys.reminderHourMinute, hm);
  final api = ref.read(notificationApiProvider);
  await api.cancelDailyReminder();
  await api.scheduleDailyReminder(hm ~/ 60, hm % 60);
  state = AsyncValue.data(hm);
}
```

**Drift transaction reference (Phase 1 `app_database.dart` confirms `PRAGMA foreign_keys = ON` at lines 50–52):**
```dart
beforeOpen: (details) async {
  await customStatement('PRAGMA foreign_keys = ON;');
},
```

**Phase 6 transaction body (from RESEARCH §Pattern 3 + §Example 3, verified):**
```dart
await _db.transaction(() async {
  await _db.delete(_db.dailyCheckins).go();   // child tables first
  await _db.delete(_db.pauseEvents).go();
  await _db.delete(_db.dailyStreak).go();
  await _db.delete(_db.dailyUsageSummary).go();
  await _db.delete(_db.blockList).go();       // parent last
});
```

**Post-transaction sequence (from RESEARCH §Pattern 3 + Pitfall 2):**
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.clear();
_ref.invalidate(onboardingCompleteProvider);
_ref.invalidate(themeModeProvider);
_ref.invalidate(reminderTimeProvider);
_ref.invalidate(streakThresholdProvider);
_ref.invalidate(postNotificationsGrantedProvider);
if (context.mounted) context.go('/onboarding/welcome');
```

**Conventions to mirror:**
- Constructor takes `(AppDatabase, Ref)` — `Ref` enables provider invalidation.
- Wrap multi-statement DB mutations in `_db.transaction(() async { ... })` (verified pattern from Drift docs).
- Delete child tables BEFORE parent (defensive, even though CASCADE is enabled — RESEARCH §Pattern 3).
- `prefs.clear()` (NOT per-key remove) — D-14 wants every prefs key gone, including future-added ones.
- Invalidate every prefs-backed AsyncNotifier explicitly (RESEARCH §Pitfall 2 — prevents pre-redirect flash).
- `if (context.mounted) context.go(...)` guard — same pattern as `accessibility_step.dart` lines 50, 54, 58.
- Explicit `context.go('/onboarding/welcome')` instead of relying on `refreshListenable` (RESEARCH §Pattern 6).

**Differences from analog (what's new this phase):**
- Multi-step Drift transaction (vs. single prefs write in `ReminderTimeNotifier`).
- Touches `BuildContext` for navigation (Reminder notifier does not).
- Open question per RESEARCH Runtime State Inventory: also call `NotificationApi.cancelDailyReminder()` to kill pending pre-clear alarm — planner verifies the Pigeon method exists.

---

### `lib/features/settings/services/file_save_port.dart` (Port interface)

**Analog:** `lib/platform/notification_api.g.dart` (Pigeon-generated `NotificationApi` interface) + `lib/domain/providers/notification_api_provider.dart` (Riverpod-wrapped provider over the Pigeon port)

**Why this analog:** Phase 1's project convention is that EVERY platform-side call sits behind a Riverpod-injectable interface so tests can stub it via mocktail. RESEARCH §Anti-Patterns explicitly calls this out: "Wrap `FlutterFileDialog.saveFile` behind a `FileSavePort` interface that the widget tests stub via mocktail. This is the same Pigeon→port pattern Phase 3/4/5 used for `UsageApi` / `AccessibilityApi` / `NotificationApi`."

**Note:** Unlike `NotificationApi`, `FileSavePort` is NOT a Pigeon-generated file because `flutter_file_dialog` is a Dart plugin, not a custom MethodChannel. The port is a thin hand-written abstract class that delegates to `FlutterFileDialog.saveFile`.

**Pattern to follow:**
```dart
// lib/features/settings/services/file_save_port.dart
abstract class FileSavePort {
  /// Returns the saved URI/path, or null on user cancel.
  /// Throws on I/O failure.
  Future<String?> save({
    required Uint8List bytes,
    required String fileName,
    required List<String> mimeTypes,
  });
}

class FlutterFileDialogSavePort implements FileSavePort { /* delegates to FlutterFileDialog.saveFile */ }
```

**Riverpod binding** (mirror `lib/domain/providers/notification_api_provider.dart`):
```dart
final fileSavePortProvider = Provider<FileSavePort>((ref) {
  return FlutterFileDialogSavePort();
});
```

**Conventions to mirror:**
- Abstract base class with one async method per platform op.
- Concrete implementation in same file (or sibling) — `XxxImpl` naming.
- `Provider<Interface>` final binding in a `_provider.dart` file under `domain/providers/` OR colocated under `features/settings/services/`.
- Test override: `fileSavePortProvider.overrideWithValue(MockFileSavePort())` per Phase 1 mocktail convention.

**Differences from analog:**
- Not Pigeon-generated (plugin already wraps the MethodChannel).
- Single-method port (vs. multi-method `NotificationApi`).
- Lives under `features/settings/` (vs. `lib/platform/`) because it's not a generated Pigeon stub.

---

### `lib/core/router/app_router.dart` (edit — append GoRoute entries)

**Analog:** Existing entries in same file lines 46–60.

**Existing pattern** (lines 58–60):
```dart
// ignore: lines_longer_than_80_chars
GoRoute(path: '/settings/reminder', builder: (_, __) => const ReminderSettingsScreen()),
```

**For Phase 6 — append 4 new entries:**
```dart
GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
GoRoute(path: '/settings/export', builder: (_, __) => const ExportScreen()),
GoRoute(path: '/settings/privacy', builder: (_, __) => const PrivacyScreen()),
GoRoute(path: '/settings/disclosure',
    builder: (_, __) => const AccessibilityStep(fromSettings: true)),
```

**Conventions to mirror:**
- One-liner `GoRoute(path, builder: (_, __) => const ScreenName())` per route.
- `// ignore: lines_longer_than_80_chars` comment ABOVE the line when the route literal pushes past 80 chars (existing pattern at lines 57, 59).
- All routes registered in the single `routes:` list (no nested `GoRoute(routes: [...])` sub-trees — Phase 6 stays flat per UI-SPEC §Route Inventory).
- Imports at top of file — add `package:not_to_do_list/features/settings/pages/settings_screen.dart`, `export_screen.dart`, `privacy_screen.dart`.

**No redirect-guard changes needed** — the existing guard at lines 26–43 only gates `onboarding` vs. non-onboarding. `/settings/*` routes are non-onboarding and become accessible once `onboardingCompleteProvider` is true (Phase 2 normal user state). Reset flow's `context.go('/onboarding/welcome')` works because the guard re-evaluates after `prefs.clear()` + invalidate (RESEARCH §Pattern 6).

**Differences from analog:**
- 4 new routes append-only.
- `/settings/disclosure` passes `fromSettings: true` constructor param (NEW pattern — see next section).

---

### `lib/app.dart` (edit — wire `themeMode:` field)

**Analog:** Existing watch pattern at lines 13–22.

**Existing pattern:**
```dart
final router = ref.watch(appRouterProvider);
return DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    return HealthLifecycleObserver(
      child: MaterialApp.router(
        title: 'Not To-Do List',
        theme: AppTheme.light(dynamic: lightDynamic),
        darkTheme: AppTheme.dark(dynamic: darkDynamic),
        routerConfig: router,
      ),
    );
  },
);
```

**Surgical edit (RESEARCH §Pattern 1 verified):**
- Add: `import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';`
- Add inside `build`: `final themeMode = ref.watch(themeModeProvider).maybeWhen(data: (m) => m, orElse: () => ThemeMode.system);`
- Add to `MaterialApp.router`: `themeMode: themeMode,`

**Conventions to mirror:**
- `ref.watch(provider).maybeWhen(data: (v) => v, orElse: () => DEFAULT)` — same async-default pattern used in `reminder_settings_screen.dart` lines 22–24.
- `ThemeMode.system` is the safe default during async-load (matches D-06 default).
- Do NOT modify `AppTheme.light/dark` calls (D-08: selector controls brightness only; dynamic_color seed still wins).

**Differences from analog:** None — pure additive change.

---

### `lib/features/home/pages/home_screen.dart` (edit — insert Settings gear AppBar action)

**Analog:** Existing notifications `IconButton` at lines 54–61 (same file).

**Existing pattern** (lines 53–62):
```dart
actions: [
  Semantics(
    label: 'Daily reminder settings',
    child: IconButton(
      icon: const Icon(Icons.notifications_outlined),
      tooltip: 'Daily reminder',
      onPressed: () => context.go('/settings/reminder'),
    ),
  ),
],
```

**For Phase 6 — INSERT new IconButton as FIRST action (per UI-SPEC §Screen-Level Layout Specs):**
```dart
actions: [
  Semantics(
    label: 'Settings',
    child: IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () => context.go('/settings'),
    ),
  ),
  Semantics(
    label: 'Daily reminder settings',
    child: IconButton(
      icon: const Icon(Icons.notifications_outlined),
      tooltip: 'Daily reminder',
      onPressed: () => context.go('/settings/reminder'),
    ),
  ),
],
```

**Conventions to mirror:**
- Wrap every `IconButton` in `Semantics(label: ...)` (existing convention in same file).
- `tooltip: '...'` on every `IconButton` (UI-SPEC §Accessibility).
- `Icons.*_outlined` style preferred (UI-SPEC §Screen-Level — "Both icons use Icons.*_outlined style for visual consistency"). `Icons.settings` and `Icons.settings_outlined` both exist; UI-SPEC uses `Icons.settings` so keep that.

**Differences from analog:** Insert (not replace) — preserves Phase 5 reminder shortcut.

---

### `lib/features/onboarding/storage_keys.dart` (edit — append theme_mode constant)

**Analog:** Existing constants in same file at lines 6–13.

**Existing pattern:**
```dart
abstract final class OnboardingKeys {
  /// Resume cursor for the install-time funnel. Stored as int 0..3.
  static const String cursor = 'onboarding_step';

  /// Sticky bool: true once the user has completed the install-time funnel.
  static const String complete = 'onboarding_complete';

  /// Build.FINGERPRINT recorded on first install + after every re-verify.
  /// Used by `PermissionHealthNotifier` to detect OS upgrades (ONBD-07).
  static const String lastKnownFingerprint = 'last_known_fingerprint';
}
```

**For Phase 6 — append (per CONTEXT D-07 / Code Insights → Reusable Assets):**
```dart
  /// Phase 6 SETT-04: theme mode int (0=system, 1=light, 2=dark).
  /// Read/written by `themeModeProvider`. Mirrors the
  /// `reminder_hour_minute` int-pattern (Phase 5 D-09).
  static const String themeMode = 'theme_mode';
```

**Conventions to mirror:**
- Doc-comment with phase + REQ-ID prefix (`/// Phase 6 SETT-04:`).
- Reference the consumer (`themeModeProvider`) and the analog pattern (`reminder_hour_minute`).
- snake_case prefs key value.
- camelCase Dart const name.

**Differences from analog:** Append only.

**Open planner question:** CONTEXT/RESEARCH both reference `OnboardingKeys.themeMode`. The "theme" is conceptually a settings key, not an onboarding key, so the class name fits awkwardly. Acceptable for v1 (lock per CONTEXT Code Insights line 149); planner may revisit by extracting `SettingsKeys` later.

---

### `lib/features/onboarding/pages/accessibility_step.dart` (edit — add `fromSettings` param)

**Analog (for the param-switch pattern):** `lib/features/pause/pages/pause_screen.dart` lines 24–37 (constructor with multiple required params + nav-mode switch on `blockMode`).

**Why this analog:** Same single-class-multiple-entry-points pattern. PauseScreen branches on `blockMode == 'soft'` for the "Use anyway" button (line 131). AccessibilityStep will branch on `fromSettings` for the post-success / post-skip navigation target.

**Existing constructor** (lines 15–19):
```dart
class AccessibilityStep extends ConsumerStatefulWidget {
  const AccessibilityStep({super.key});
  // ...
}
```

**For Phase 6 — surgical 4-line addition (per RESEARCH §Pattern 5):**
```dart
class AccessibilityStep extends ConsumerStatefulWidget {
  const AccessibilityStep({super.key, this.fromSettings = false});
  final bool fromSettings;
  // ...
}
```

**Branch the two `context.go(...)` calls** at lines 54 and 84:
```dart
// Current line 54:
context.go('/onboarding/permissions/battery-opt');
// Becomes:
if (widget.fromSettings) {
  context.pop();
} else {
  context.go('/onboarding/permissions/battery-opt');
}
```
Same change at line 84 (`_skip` method).

**Conventions to mirror:**
- Default value `false` (preserves all existing call-site behavior — only the new `/settings/disclosure` route passes `true`).
- Access via `widget.fromSettings` inside `_AccessibilityStepState`.
- Do NOT touch the body Column lines 99–124 — the 5 verbatim phrases are grepped by `prominent_disclosure_test.dart` (CONTEXT line 22) AND by `play_invariants_test.dart` PLAY-06 test (lines 210–231 of `test/policy/play_invariants_test.dart`).

**Differences from analog:**
- Boolean nav-mode flag (vs. PauseScreen's String `blockMode` taking 2 values).
- Mutates an existing screen (vs. PauseScreen being a new screen in Phase 4).

**Critical:** Plan must run `flutter test test/policy/play_invariants_test.dart` AND `prominent_disclosure_test.dart` after this edit to confirm grep still passes.

---

### `test/policy/play_invariants_test.dart` (edit — append PLAY-09 telemetry invariants)

**Analog:** Same file, all 10 existing `test(...)` blocks (lines 19–284) + `test/policy/phase_5_invariants_test.dart` lines 80–127 (the precedent zero-FCM grep test).

**Why this analog:** Phase 2/4/5 established the pattern of appending per-phase invariants to this single file. Phase 5 already added the receiver-scope test (lines 121–137). Phase 6 appends the telemetry-token sweep.

**Existing pattern — pubspec/source grep** (`phase_5_invariants_test.dart` lines 80–127):
```dart
test(
  'no FCM / firebase_messaging imports under lib/',
  () {
    final libDir = Directory('lib');
    // ...
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'),
        );

    for (final file in dartFiles) {
      final src = file.readAsStringSync();
      final codeOnly = src
          .split('\n')
          .where((line) => !RegExp(r'^\s*//').hasMatch(line))
          .join('\n');
      expect(
        codeOnly.contains('firebase_messaging'),
        isFalse,
        reason: 'zero-telemetry: ${file.path} must not import firebase_messaging ...',
      );
    }
  },
);
```

**Phase 6 new tests (per RESEARCH §Example 6, verified — append inside the existing `group('Phase 2 cross-tree policy invariants', ...)`):**

```dart
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
  if (!apk.existsSync()) return; // CI may not have built release yet
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

**Conventions to mirror:**
- One `test(...)` block per invariant (per-rule failure pinpoints).
- Comment-line stripping (`grep -v '^//' analog`) BEFORE token checks — see existing lines 102–108 and 132 ("Nyquist absence-grep rule").
- File existence check guards (lines 53, 89, 138–142) — handle "phase not yet implemented" gracefully via `return;`.
- `reason:` argument on every `expect` referencing the REQ-ID (e.g., `'PLAY-09: ...'`).
- Sweep `classes*.dex` (glob) NOT `classes.dex` — RESEARCH Pitfall 5.

**Differences from analog:**
- Adds Process.runSync shell-out (no precedent in this file) — necessary because Dart has no native ZIP-read + strings combinator.
- Skips gracefully when release APK not built (vs. existing tests that hard-fail on missing input).
- New REQ-ID prefix `PLAY-09` (extends Phase 1's PLAY-02..06 sequence).

---

### `pubspec.yaml` (edit — append 4 dependencies)

**Analog:** Existing dependency block lines 17–29.

**Existing pattern:**
```yaml
dependencies:
  drift: ^2.33.0
  drift_flutter: ^0.3.0
  dynamic_color: ^1.7.0
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.3.1
  go_router: ^17.2.3
  intl: ^0.20.2
  path: ^1.9.1
  path_provider: ^2.1.5
  shared_preferences: ^2.5.5
  url_launcher: ^6.3.0
```

**For Phase 6 — append (per RESEARCH §Standard Stack, verified 2026-05-24):**
```yaml
  archive: ^4.0.9
  flutter_file_dialog: ^3.0.3
  flutter_markdown_plus: ^1.0.7
  package_info_plus: ^10.1.0
```

**Asset block extend (lines 41–44) — add `docs/PRIVACY.md`:**
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/onboarding/
    - assets/logos/
    - docs/PRIVACY.md
```

**Version bump (line 4):**
```yaml
version: 1.0.0+1
```

**Conventions to mirror:**
- Alphabetical-ish ordering within `dependencies:` (rough; the existing list is alphabetical from `drift` to `url_launcher`).
- Caret pin `^X.Y.Z` (matches every existing dep).
- Asset directory entries end with `/`; single-file entries do not.

**Differences from analog:** Append + version bump.

---

### `android/app/build.gradle.kts` (edit — verify version flow + release signing)

**Analog:** Existing `defaultConfig` at lines 21–28 (already references `flutter.versionCode` / `flutter.versionName`, so the version bump in pubspec.yaml flows through automatically).

**Existing pattern (lines 21–28):**
```kotlin
defaultConfig {
    applicationId = "com.nottodo.not_to_do_list"
    minSdk = 29
    targetSdk = 36
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

**Phase 6 implications:**
- pubspec.yaml `version: 1.0.0+1` → `flutter.versionName = "1.0.0"`, `flutter.versionCode = 1` (RESEARCH Pitfall 7 confirms the `+` is the SEPARATOR).
- No `build.gradle.kts` source change needed for the version itself.
- Release `signingConfig` lines 31–34 currently use the debug key with a TODO; for Play App Signing (default) this is fine — Play manages the upload key.

**Differences from analog:** Possibly no code edit at all. Planner may want a one-line comment update to remove the TODO or document that Play App Signing is in use.

---

### `assets/PRIVACY.md` + `docs/PRIVACY.md` (new SoT files)

**Analog (for SoT-with-two-consumers convention):** `docs/play-declaration.md` (existing — single-source-of-truth for AccessibilityService disclosure, consumed by both the Play Console form copy AND grepped by `play_invariants_test.dart` PLAY-06 test).

**Why this analog:** Phase 1 already established the "doc-as-SoT, code mirrors it" pattern. Phase 6 mirrors with PRIVACY.md.

**RESEARCH §Pattern 4 lock:** Single file at `/docs/PRIVACY.md` (NOT `/assets/`). pubspec.yaml registers it as an asset (`docs/PRIVACY.md` under `flutter.assets:`) so `rootBundle.loadString('docs/PRIVACY.md')` works in-app. GitHub Pages publishes from `/docs/` on `main` (Settings → Pages → "Deploy from a branch → main / /docs").

**Conventions to mirror:**
- Plain CommonMark + GFM (no Jekyll front-matter required — RESEARCH §Pattern 4 makes `_config.yml` optional).
- Calm tone (Phase 4 D-07 lock carries forward).
- No external links (RESEARCH Pitfall 6 — link-tap unhandled by default; defer until needed).
- Content states: "zero data collection, on-device only, no telemetry, no network calls beyond app launch."

**Differences from analog:**
- Dual purpose (public URL + bundled asset) vs. `play-declaration.md` which is purely a planner-reference document.

---

### `docs/play-listing/` (new directory tree)

**Analog:** None in tree (first Play-listing scaffold).

**Recommended structure (from RESEARCH §Architecture Patterns → Recommended Project Structure):**
```
docs/play-listing/
├── short-description.txt         # 80 char
├── full-description.txt          # 4000 char
├── permission-declaration.md     # copy of play-declaration.md text shaped for the form
└── screenshots/                  # 2 phone screenshots, 1 feature graphic 1024x500
```

**Conventions to mirror:**
- Text files NOT markdown (Play Console form accepts plain text).
- Filename convention matches Play Console field names.
- `permission-declaration.md` mirrors the SoT `docs/play-declaration.md` — RESEARCH §Pitfall 1 warns reviewers cross-check form vs. in-app copy. Plan must keep these in sync.

**Differences from analog:** Entirely new directory.

---

## Shared Patterns

### Hand-written `AsyncNotifier` (no codegen)

**Source:** `lib/features/streak/providers/streak_threshold_provider.dart` (full file), `lib/features/reminder/providers/reminder_providers.dart` (full file), `lib/features/onboarding/providers/onboarding_complete_provider.dart` (full file)

**Apply to:** All new Riverpod providers in Phase 6 (specifically `themeModeProvider`).

**Why:** Phase 1 dropped `riverpod_annotation`/`riverpod_generator` due to analyzer-pin conflict with `pigeon 26.3.4` (pubspec.yaml lines 10–14). This is a project-wide lock until the ecosystem converges on analyzer 12+.

```dart
class XxxNotifier extends AsyncNotifier<T> {
  @override
  Future<T> build() async { /* read from prefs */ }
  Future<void> set(T value) async {
    /* write to prefs, then: */
    state = AsyncValue.data(value);
  }
}

final AsyncNotifierProvider<XxxNotifier, T> xxxProvider =
    AsyncNotifierProvider<XxxNotifier, T>(XxxNotifier.new);
```

---

### `ref.watch(provider).maybeWhen(data: (v) => v, orElse: () => DEFAULT)`

**Source:** `lib/features/reminder/pages/reminder_settings_screen.dart` lines 22–24

**Apply to:** Every `ConsumerWidget` that reads an `AsyncNotifierProvider` and needs a safe default during async-load (`SettingsScreen`, `ThemeTile`, `app.dart`).

```dart
final hm = reminderAsync.maybeWhen(data: (v) => v, orElse: () => 1260);
```

---

### `if (!mounted) return;` / `if (context.mounted)` guard after `await`

**Source:** `lib/features/onboarding/pages/accessibility_step.dart` lines 50, 54, 58, 60, 73, 78, 83 (StatefulWidget context: `!mounted`); `lib/features/onboarding/pages/post_notifications_earned_step.dart` lines 59, 63, 67, 77, 81 (same)

**Apply to:** Every `await` in `ExportController`, `ResetController`, `_pickTime`-style helpers, and any `ConsumerWidget` action handlers before they touch `BuildContext`.

---

### Phase-incremental absence-grep policy invariants

**Source:** `test/policy/play_invariants_test.dart` (10 invariants, lines 19–284) + `test/policy/phase_5_invariants_test.dart` (telemetry sweep precedent)

**Apply to:** Phase 6 PLAY-09 telemetry token sweep across `pubspec.lock` + `lib/**/*.dart` + decoded release APK `classes*.dex` strings.

**Common idiom:**
1. `Directory('path').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))`
2. Strip comment lines: `src.split('\n').where((line) => !RegExp(r'^\s*//').hasMatch(line)).join('\n')`
3. `expect(codeOnly.contains(forbiddenToken), isFalse, reason: 'PHASE-REQ-ID: ...')`
4. Graceful skip when phase-dependent path absent (`if (!dir.existsSync()) return;`).

---

### Pigeon-port abstraction for platform plugins (test-stubbing seam)

**Source:** `lib/platform/notification_api.g.dart` (interface), `lib/domain/providers/notification_api_provider.dart` (Riverpod binding), test fixtures under `test/_fixtures/` (mocktail mocks)

**Apply to:** `FileSavePort` wrapping `FlutterFileDialog.saveFile`. Same pattern even though `FlutterFileDialog` is a plugin (not Pigeon-generated) — the port is a thin hand-written adapter that allows widget tests to stub the SAF call without triggering real Android intents (RESEARCH §Anti-Patterns).

---

### Calm tone / no scare copy / no exclamation marks

**Source:** Phase 4 D-07 lock; reinforced by Phase 5 D-05/D-10; copy contracts in UI-SPEC §Copywriting Contract

**Apply to:** Reset AlertDialog body, Privacy screen, Disclosure screen, Export tile copy, About tile, all SnackBars. Specifically:
- Reset dialog body (LITERAL, verbatim): `"This deletes every entry, streak day, pause event, and check-in. This cannot be undone."`
- Export success: `"Export saved"` (NOT `"Export saved!"`)
- Export error: `"Export failed. Check available storage and try again."`

---

### Drift transaction with FK-aware delete order

**Source:** `lib/data/database/app_database.dart` lines 50–52 (`PRAGMA foreign_keys = ON;`), Phase 2 LIST-05 cascade pattern (per CONTEXT lines 20, 150)

**Apply to:** `ResetController.resetAll()`. Wrap all five `db.delete(table).go()` calls in `db.transaction(() async { ... })`. Delete child tables first (`daily_checkins`, `pause_events`, `daily_streak`, `daily_usage_summary`), parent last (`block_list`).

---

## No Analog Found

| File | Role | Data Flow | Reason / Fallback |
|---|---|---|---|
| `lib/features/settings/services/file_save_port.dart` | Port for `flutter_file_dialog` SAF call | `Uint8List` → URI string | No prior plugin-port abstraction in tree (Pigeon `*_api.g.dart` ports are generated, not hand-written). Pattern is derived from RESEARCH §Anti-Patterns and Pigeon-port convention. Plan should add a fixture under `test/_fixtures/` named `file_save_port_mock.dart` mirroring `test/_fixtures/permission_status_mock.dart`. |
| `docs/play-listing/` | Static Play Console listing assets | text + images | No precedent. Plan must write a brief README inside the directory documenting which file maps to which Play Console field. |

---

## Metadata

**Analog search scope:**
- `lib/features/` (12 subfeatures: checkin, dashboard, health, home, list, onboarding, pause, reminder, streak)
- `lib/core/` (router, theme, utils)
- `lib/data/` (database, detectors, repositories)
- `lib/domain/providers/` (Riverpod provider conventions)
- `lib/platform/` (Pigeon-port convention)
- `test/policy/` (invariant test pattern)
- `test/_fixtures/` (mock convention)

**Files scanned (read in full or targeted):** 23
- Provider analogs: `streak_threshold_provider.dart`, `reminder_providers.dart`, `onboarding_complete_provider.dart`, `post_notifications_provider.dart`, `database_provider.dart`
- Screen analogs: `reminder_settings_screen.dart`, `home_screen.dart`, `accessibility_step.dart`, `post_notifications_earned_step.dart`, `pause_screen.dart`, `welcome_screen.dart` (via list), `rationale_screen.dart`
- Widget analogs: `block_mode_segmented.dart`, `done_confirmation_card.dart`
- Router/app shell: `app_router.dart`, `app.dart`
- Storage: `storage_keys.dart`, `streak_keys.dart`
- Data: `app_database.dart`, `block_list_dao.dart`, `daily_streak_dao.dart`, `daily_checkins_dao.dart`, `daily_usage_summary_dao.dart`, `pause_event_dao.dart`, `block_list_table.dart`
- Tests: `play_invariants_test.dart`, `phase_5_invariants_test.dart`, `home_screen_unified_list_test.dart`
- Build: `pubspec.yaml`, `android/app/build.gradle.kts`

**Pattern extraction date:** 2026-05-24

---

## PATTERN MAPPING COMPLETE
