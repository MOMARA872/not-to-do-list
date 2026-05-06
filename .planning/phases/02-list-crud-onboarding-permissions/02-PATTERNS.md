# Phase 2 — Pattern Map

**Mapped:** 2026-05-05
**Inputs:** 02-CONTEXT.md, 02-RESEARCH.md, 02-UI-SPEC.md
**Phase 1 codebase scanned:** lib/, pigeons/, android/app/src/main/, test/

This document is consumed by `gsd-planner`. Every Phase 2 file is mapped to its closest Phase 1 analog with verbatim excerpts the executor must imitate. Where Phase 1 has no analog (e.g., DAOs, repositories, screens beyond the placeholder), the cell is marked **GAP** and falls back to the snippets in 02-RESEARCH.md.

---

## File Inventory

Legend:
- **W**: Wave (0 = tests fixtures, 1 = schema/channels, 2 = repos/providers, 3 = UI surfaces).
- **N/M**: New file or Modified.
- **GAP** in *Closest analog*: no Phase 1 file plays this role; executor pattern-matches against the snippet in 02-RESEARCH.md instead of an in-tree file.

### Wave 0 — Tests, Fixtures, Static Assets

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `test/data/database/migration_v1_to_v2_test.dart` | N | test (Drift in-memory + raw SQL) | 0 | `test/data/database/app_database_test.dart` | Same framework (`flutter_test`), same fixture (`AppDatabase(NativeDatabase.memory())`), same group/test/setUp/tearDown structure |
| `test/data/repositories/block_list_repo_test.dart` | N | test (Drift unit) | 0 | `test/data/database/app_database_test.dart` | Drift in-memory pattern; uses `BlockListCompanion.insert(...)` already exercised in Phase 1 |
| `test/data/repositories/cascade_delete_test.dart` | N | test (Drift FK cascade) | 0 | `test/data/database/app_database_test.dart` | Same in-memory DB harness; tests the existing `onDelete: KeyAction.cascade` declarations from Phase 1 sibling tables |
| `test/domain/schedule/schedule_window_test.dart` | N | test (pure-Dart truth table) | 0 | `test/domain/providers/blocked_app_detector_provider_test.dart` | Same `group(...) { test(...) }` layout; pure Dart, no Riverpod / no Drift |
| `test/features/list/add_app_picker_test.dart` | N | test (widget + mocked Pigeon) | 0 | `test/domain/providers/blocked_app_detector_provider_test.dart` | Provider-override pattern (`ProviderContainer(overrides: [...])`) for swapping the Pigeon API |
| `test/features/list/edit_screen_test.dart` | N | test (widget) | 0 | GAP — no widget tests in Phase 1 | Use `flutter_test` `pumpWidget` + `mocktail`; pattern from RESEARCH §Validation Architecture |
| `test/features/home/home_screen_test.dart` | N | test (widget) | 0 | GAP — Phase 1 only has unit-level tests | Same as above |
| `test/features/onboarding/quick_add_test.dart` | N | test (widget + repo verify) | 0 | `test/domain/providers/blocked_app_detector_provider_test.dart` | Provider override + container teardown pattern |
| `test/features/onboarding/funnel_flow_test.dart` | N | test (widget + lifecycle pump) | 0 | GAP | RESEARCH §Validation Architecture: pumps `AppLifecycleState.resumed` |
| `test/features/onboarding/oem_fallback_test.dart` | N | test (mock Pigeon) | 0 | `test/domain/providers/blocked_app_detector_provider_test.dart` | Override pattern again |
| `test/features/onboarding/play06_disclosure_test.dart` | N | test (verbatim string assert) | 0 | `test/domain/providers/blocked_app_detector_provider_test.dart` (the absence-grep test inside it) | Phase 1 already uses regex/string asserts on source content for PLAY policy enforcement |
| `test/features/health/banner_test.dart` | N | test (widget) | 0 | GAP | — |
| `test/features/health/fingerprint_test.dart` | N | test (unit) | 0 | `test/domain/providers/blocked_app_detector_provider_test.dart` | Provider override pattern + `SharedPreferences.setMockInitialValues` |
| `test/features/health/dontkillmyapp_url_test.dart` | N | test (pure-Dart) | 0 | `test/domain/providers/blocked_app_detector_provider_test.dart` | Pure data table test |
| `test/platform/app_picker_api_test.dart` | N | test (Pigeon channel mock) | 0 | GAP | — |
| `test/_fixtures/permission_status_mock.dart` | N | test fixture (mocktail) | 0 | GAP — no `_fixtures/` subtree exists in Phase 1 | Single mock implementation reused across funnel/banner tests |
| `assets/onboarding/usage_access_step.png` | N | static asset (PNG) | 0 | GAP — no `assets/` directory exists in Phase 1 | New top-level `assets/` tree; `pubspec.yaml` `flutter:` block must declare it |
| `assets/onboarding/accessibility_step.png` | N | static asset | 0 | GAP | — |
| `assets/onboarding/battery_opt_step.png` | N | static asset | 0 | GAP | — |
| `assets/logos/instagram.png` (+ tiktok, x, youtube, reddit) | N | static asset | 0 | GAP | — (see OQ-2 — executor may swap to runtime `getApplicationIcon` if licensing is ambiguous) |

### Wave 1 — Schema + Channels (data + platform layer)

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `lib/data/database/tables/block_list_table.dart` | M | Drift table | 1 | self (Phase 1 file) | Phase 2 ADDS 4 columns; rest of file is unchanged |
| `lib/data/database/app_database.dart` | M | Drift DB declaration | 1 | self (Phase 1 file) | Phase 2 bumps `schemaVersion` 1→2 and fills `onUpgrade` |
| `pigeons/app_picker_api.dart` | N | Pigeon HostApi definition | 1 | `pigeons/usage_api.dart` | Same `@ConfigurePigeon` shape, same `errorClassName` rationale, same `@async` method style — explicit comment "see usage_api.dart for the FlutterError-redeclaration rationale" already exists in `accessibility_api.dart` and `notification_api.dart` |
| `pigeons/permission_status_api.dart` | N | Pigeon HostApi definition | 1 | `pigeons/accessibility_api.dart` | Same shape (single-class `@HostApi()` no data class needed), same `// ignore_for_file: one_member_abstracts` precedent, same Kotlin output path layout |
| `lib/platform/app_picker_api.g.dart` | N (generated) | Pigeon Dart output | 1 | `lib/platform/usage_api.g.dart` | Pigeon-generated; do not hand-edit. `flutter pub run pigeon` regenerates it from the `.dart` definition |
| `lib/platform/permission_status_api.g.dart` | N (generated) | Pigeon Dart output | 1 | `lib/platform/accessibility_api.g.dart` | Same |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerApi.g.kt` | N (generated) | Pigeon Kotlin output | 1 | `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt` | Same |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApi.g.kt` | N (generated) | Pigeon Kotlin output | 1 | `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApi.g.kt` | Same |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt` | N | HostApi Kotlin impl | 1 | GAP — Phase 1 stubs everything inline in `MainActivity.configureFlutterEngine` | Phase 2 first dedicated impl class. Snippet template is in 02-RESEARCH.md §App Picker Implementation |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt` | N | HostApi Kotlin impl | 1 | GAP | Same |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` | M | Flutter engine wiring | 1 | self (Phase 1 file) | Phase 2 adds two more `setUp(...)` calls (AppPickerApi, PermissionStatusApi) following the existing 3-channel pattern |
| `android/app/src/main/AndroidManifest.xml` | M (light) | manifest | 1 | self (Phase 1 file) | Phase 2 adds NO new permissions — `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` and `<queries>` LAUNCHER are already declared. Wave 1 verifies, does not extend |
| `pubspec.yaml` | M | manifest | 1 | self | Adds `dynamic_color: ^1.7.0` and `url_launcher: ^6.3.0` to `dependencies`; declares `assets/onboarding/`, `assets/logos/` under `flutter:` |

### Wave 2 — DAOs, Repositories, Domain Helpers, Riverpod Providers

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `lib/data/database/daos/block_list_dao.dart` | N | Drift DAO | 2 | GAP — no DAOs in Phase 1 | Phase 1 keeps everything on `AppDatabase`. Use Drift `@DriftAccessor` pattern; snippet template in RESEARCH §Riverpod Provider Wiring |
| `lib/data/repositories/block_list_repository.dart` | N | repository (CRUD + insertMany) | 2 | GAP — `lib/data/repositories/.gitkeep` only | Pattern: thin domain-language wrapper over the DAO. RESEARCH §Riverpod Provider Wiring describes shape |
| `lib/domain/schedule/schedule_window.dart` | N | pure-Dart helper | 2 | `lib/domain/blocked_app_detector.dart` | Sibling under `lib/domain/`; pure-Dart contract; no Riverpod / no Flutter dep |
| `lib/domain/schedule/streak_day.dart` | N | pure-Dart helper | 2 | `lib/domain/blocked_app_detector.dart` | Same as above (04:00 streak day shift utility, see RESEARCH §Schedule Active-Window Evaluation footnote) |
| `lib/domain/providers/block_list_dao_provider.dart` | N | Riverpod provider | 2 | `lib/domain/providers/database_provider.dart` | Hand-written `Provider<T>` (no `@riverpod` codegen); reads `databaseProvider` |
| `lib/domain/providers/block_list_repo_provider.dart` | N | Riverpod provider | 2 | `lib/domain/providers/database_provider.dart` | Same |
| `lib/domain/providers/permission_status_api_provider.dart` | N | Riverpod provider | 2 | `lib/domain/providers/blocked_app_detector_provider.dart` | Hand-written single-instance provider |
| `lib/domain/providers/app_picker_api_provider.dart` | N | Riverpod provider | 2 | `lib/domain/providers/blocked_app_detector_provider.dart` | Same |
| `lib/features/onboarding/providers/onboarding_complete_provider.dart` | N | Riverpod provider (`shared_preferences`-backed) | 2 | `lib/domain/providers/database_provider.dart` | Hand-written `Provider<T>` with `ref.onDispose` if needed |
| `lib/features/onboarding/providers/onboarding_cursor_provider.dart` | N | Riverpod state notifier (int 0..3) | 2 | GAP — no `StateNotifier`/`AsyncNotifier` in Phase 1 | Pattern: hand-written `NotifierProvider`/`AsyncNotifierProvider` per RESEARCH §Self-Healing Health Check Architecture (uses the `AsyncNotifier` shape verbatim) |
| `lib/features/health/permission_health_provider.dart` | N | Riverpod `AsyncNotifierProvider` | 2 | GAP | RESEARCH §Self-Healing Health Check Architecture has the verbatim shape |
| `lib/core/utils/dontkillmyapp_url.dart` | N | pure-Dart helper | 2 | `lib/domain/blocked_app_detector.dart` | Pure-function pattern; const map + `String?` accessor (RESEARCH §dontkillmyapp.com URL pattern) |

### Wave 3 — UI Surfaces (router, theme, screens, widgets)

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `lib/core/router/app_router.dart` | M | GoRouter declaration | 3 | self (Phase 1 file) | Existing single-route file extended to ~9 routes + `redirect:` callback (RESEARCH §GoRouter redirect) |
| `lib/core/theme/app_theme.dart` | M | ThemeData declaration | 3 | self (Phase 1 file) | Phase 1 ships bare-bones M3; Phase 2 wires `dynamic_color` (`DynamicColorBuilder`) + UI-SPEC §Color seed (`ColorScheme.fromSeed`) |
| `lib/features/onboarding/pages/welcome_screen.dart` | N | screen (Stateless) | 3 | `lib/features/home/pages/empty_home_screen.dart` | Same `Scaffold` shell, same plain `StatelessWidget` style; UI-SPEC Surface 1 dictates layout |
| `lib/features/onboarding/pages/quick_add_screen.dart` | N | screen (Consumer + state) | 3 | `lib/features/home/pages/empty_home_screen.dart` | Scaffold shell extended; UI-SPEC Surface 2 dictates layout |
| `lib/features/onboarding/pages/usage_access_step.dart` | N | screen (`ConsumerStatefulWidget` + `WidgetsBindingObserver`) | 3 | GAP | RESEARCH §onResume Return-Detection Pattern is the verbatim template |
| `lib/features/onboarding/pages/accessibility_step.dart` | N | screen (same lifecycle pattern + PLAY-06 disclosure copy) | 3 | GAP | Same |
| `lib/features/onboarding/pages/battery_opt_step.dart` | N | screen (same lifecycle pattern) | 3 | GAP | Same |
| `lib/features/onboarding/widgets/oem_fallback_panel.dart` | N | widget (reactive OEM hint) | 3 | GAP | — |
| `lib/features/home/pages/home_screen.dart` | N | screen (replaces `EmptyHomeScreen`) | 3 | `lib/features/home/pages/empty_home_screen.dart` | Direct evolution of placeholder — keep `Scaffold` + `AppBar('Not To-Do List')` |
| `lib/features/home/widgets/block_list_row.dart` | N | widget (compact 64 dp `ListTile` row) | 3 | GAP | UI-SPEC Surface 4 dictates layout |
| `lib/features/list/pages/add_app_picker_screen.dart` | N | screen | 3 | GAP | UI-SPEC Surface 5 |
| `lib/features/list/pages/add_habit_screen.dart` | N | screen | 3 | GAP | UI-SPEC Surface 6 |
| `lib/features/list/pages/edit_entry_screen.dart` | N | screen | 3 | GAP | UI-SPEC Surface 7 |
| `lib/features/list/widgets/block_mode_segmented.dart` | N | widget | 3 | GAP | UI-SPEC Surface 8 |
| `lib/features/list/widgets/schedule_editor.dart` | N | widget | 3 | GAP | UI-SPEC Surface 9 |
| `lib/features/list/widgets/app_icon.dart` | N | widget (Image.memory + LRU lookup) | 3 | GAP | — |
| `lib/features/health/widgets/health_check_banner.dart` | N | widget (top-of-`Scaffold.body` `MaterialBanner`) | 3 | GAP | UI-SPEC Surface 11 |
| `lib/features/list/controllers/app_picker_controller.dart` | N | Riverpod state notifier (search debounce, filter) | 3 | GAP | — |
| `lib/features/list/controllers/edit_entry_controller.dart` | N | Riverpod state notifier (form state) | 3 | GAP | — |
| `lib/app.dart` | M (light) | top-level `MaterialApp.router` | 3 | self (Phase 1 file) | Phase 2 may pivot ThemeData to use `DynamicColorBuilder`; route config still consumes `appRouterProvider` |

---

## Per-File Pattern Excerpts

### `lib/data/database/tables/block_list_table.dart` (MODIFY)

- **Wave:** 1
- **Role:** Drift table
- **Analog:** self — Phase 1 file extended in place

**Pattern excerpt** (verbatim from current file, lines 1-23):
```dart
import 'package:drift/drift.dart';

/// One row per user-listed not-to-do entry (app or habit).
/// kind: 0 = app (system-tracked), 1 = habit (self-report only).
class BlockList extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kind => integer()(); // 0 app, 1 habit
  TextColumn get packageName => text().nullable()(); // null for habits
  TextColumn get displayName => text()();
  TextColumn get reasonNote => text().withDefault(const Constant(''))();
  IntColumn get streakBreakThresholdMinutes =>
      integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {kind, packageName},
      ];
}
```

**Required divergence in Phase 2** (verbatim from RESEARCH §Drift v2 Migration):
```dart
  // Phase 2 additions
  TextColumn get blockMode =>
      text().withDefault(const Constant('soft'))();
  IntColumn get scheduleStartMinutes => integer().nullable()();
  IntColumn get scheduleEndMinutes => integer().nullable()();
  IntColumn get scheduleWeekdayMask => integer().nullable()();
```

Style notes the executor MUST preserve:
- Use `withDefault(const Constant(...))` style — not paraphrased.
- `blockMode` as `TextColumn`, not an enum-typed converter (RESEARCH §Drift v2 Migration explicitly avoids enum codecs for v1; validation lives at domain layer).
- The three nullable schedule columns use `integer().nullable()()` — same style as `packageName` (line 8) which uses `text().nullable()()`. No defaults on nullable columns.
- Do NOT touch `uniqueKeys`. Do NOT add a non-launchable system-app filter here — that is a Kotlin-side concern.

---

### `lib/data/database/app_database.dart` (MODIFY)

- **Wave:** 1
- **Role:** Drift DB declaration + migration strategy
- **Analog:** self

**Pattern excerpt** (verbatim, lines 9-36):
```dart
@DriftDatabase(
  tables: [
    BlockList,
    DailyStreak,
    PauseEvents,
    DailyCheckins,
    DailyUsageSummary,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// Phase 1 = schema 1. Each later phase that adds a table or column bumps
  /// this and supplies a migration step in `migration` below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // No upgrades yet — schema is at version 1.
        },
      );
```

**Required divergence in Phase 2:**
```dart
  @override
  int get schemaVersion => 2; // bumped from 1

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(blockList, blockList.blockMode);
            await m.addColumn(blockList, blockList.scheduleStartMinutes);
            await m.addColumn(blockList, blockList.scheduleEndMinutes);
            await m.addColumn(blockList, blockList.scheduleWeekdayMask);
          }
        },
      );
```

Style notes:
- Keep the `_openConnection()` static factory and the optional `QueryExecutor` ctor argument — required by tests (`AppDatabase(NativeDatabase.memory())` in `test/data/database/app_database_test.dart:11`).
- Do NOT wholesale-rewrite. The `@DriftDatabase` block, `_openConnection`, and the constructor are unchanged.
- The DAO list MAY grow later if Wave 2 adds `daos: [BlockListDao]`; do not pre-empt unless Wave 2 actually creates the DAO.

---

### `pigeons/app_picker_api.dart` (NEW)

- **Wave:** 1
- **Role:** Pigeon HostApi definition (input, not generated)
- **Analog:** `pigeons/usage_api.dart`

**Pattern excerpt** (verbatim from `pigeons/usage_api.dart` lines 1-40):
```dart
// Pigeon HostApi inputs require `abstract class` even for single-method APIs.
// ignore_for_file: one_member_abstracts

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/usage_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt',
    // Each Pigeon Kotlin output declares a `FlutterError` class at file level.
    // When all 3 share a single Kotlin package, kotlinc fails with
    // "Redeclaration: FlutterError". `errorClassName` gives each output a
    // unique class name, fixing the clash without splitting packages.
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
      errorClassName: 'UsageApiError',
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
class UsagePackageStat {
  UsagePackageStat({
    required this.packageName,
    required this.foregroundSeconds,
    required this.launchCount,
  });
  final String packageName;
  final int foregroundSeconds;
  final int launchCount;
}

@HostApi()
abstract class UsageApi {
  /// Phase 3 will implement this. Phase 1 ships interface only.
  /// Returns daily-bucketed per-package foreground time over
  /// [startEpochMs, endEpochMs].
  @async
  List<UsagePackageStat> queryRange(int startEpochMs, int endEpochMs);
}
```

**Required divergence in Phase 2** — match the four-method shape from RESEARCH §App Picker Implementation. Required deviations:
- `errorClassName: 'AppPickerApiError'` — UNIQUE, NOT `'UsageApiError'` (the comment block above explains why each must be unique).
- `dartOut`/`kotlinOut` paths point at `app_picker_api.g.dart` / `AppPickerApi.g.kt`.
- Two data classes (`InstalledApp`, `RecentApp`), one `Uint8List?` return, three `@async` methods.
- Comment about `ignore_for_file: one_member_abstracts` is NOT needed if there are multiple methods — drop it.

---

### `pigeons/permission_status_api.dart` (NEW)

- **Wave:** 1
- **Role:** Pigeon HostApi definition
- **Analog:** `pigeons/accessibility_api.dart`

**Pattern excerpt** (verbatim from `pigeons/accessibility_api.dart` lines 1-29):
```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/accessibility_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApi.g.kt',
    // See usage_api.dart for the FlutterError-redeclaration rationale.
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
      errorClassName: 'AccessibilityApiError',
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
@HostApi()
abstract class AccessibilityApi {
  /// True iff our specific service appears in
  /// AccessibilityManager.getEnabledAccessibilityServiceList().
  /// NOTE: this only reports state. The API explicitly does NOT expose
  /// autonomous-action APIs per PLAY-02.
  @async
  bool isServiceEnabled();

  /// Open Settings.ACTION_ACCESSIBILITY_SETTINGS deep-link (Phase 2 will use
  /// this).
  void openAccessibilitySettings();
}
```

**Required divergence in Phase 2:**
- `errorClassName: 'PermissionStatusApiError'`.
- Methods per RESEARCH §Status check helpers: `isUsageAccessGranted`, `isAccessibilityServiceEnabled` (DUPLICATES the existing `AccessibilityApi` — the RESEARCH note 02-RESEARCH.md:466 says "the cleanest addition is a NEW PermissionStatusApi for the other three, leaving the Phase 1 contract untouched"; planner decides whether to drop the dup or keep both for the bundled-resume convenience), `isIgnoringBatteryOptimizations`, `currentBuildFingerprint` (`String`), `currentManufacturer` (`String`).
- Add `@async void openUsageAccessSettings()`, `@async void openAccessibilitySettings()`, `@async void openBatteryOptSettings()` on the same channel — RESEARCH §Code Examples Example 4 implies these are deep-link launchers on the same impl class.
- The "see usage_api.dart for the FlutterError-redeclaration rationale" comment MUST be retained verbatim.
- DO NOT add any autonomous-action methods (PLAY-02 invariant — see `test/domain/providers/blocked_app_detector_provider_test.dart` lines 40-67 for the test harness that greps for `performAction`/`performGlobalAction`/`dispatchGesture`; that test file may need to be extended to also cover the new API source files).

---

### `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` (MODIFY)

- **Wave:** 1
- **Role:** Flutter engine wiring (HostApi `setUp`)
- **Analog:** self

**Pattern excerpt** (verbatim, lines 1-52):
```kotlin
package com.nottodo.not_to_do_list

import com.nottodo.not_to_do_list.platform.AccessibilityApi
import com.nottodo.not_to_do_list.platform.NotificationApi
import com.nottodo.not_to_do_list.platform.UsageApi
import com.nottodo.not_to_do_list.platform.UsagePackageStat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Phase 1 wires UNIMPLEMENTED stubs so the app compiles and runs.
        // Phase 3/4/5 will replace each setUp() with a real implementation.

        UsageApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : UsageApi {
            override fun queryRange(
                startEpochMs: Long,
                endEpochMs: Long,
                callback: (Result<List<UsagePackageStat>>) -> Unit
            ) {
                callback(Result.failure(NotImplementedError("UsageApi: implemented in Phase 3")))
            }
        })

        AccessibilityApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : AccessibilityApi {
            override fun isServiceEnabled(callback: (Result<Boolean>) -> Unit) {
                // Safe stub: report "off" until Phase 4 wires the real check.
                callback(Result.success(false))
            }

            override fun openAccessibilitySettings() {
                // No-op stub; Phase 2 deep-links to system settings.
            }
        })

        NotificationApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : NotificationApi {
            override fun scheduleDailyReminder(
                hour: Long,
                minute: Long,
                callback: (Result<Unit>) -> Unit
            ) {
                callback(Result.failure(NotImplementedError("NotificationApi: implemented in Phase 5")))
            }

            override fun cancelDailyReminder(callback: (Result<Unit>) -> Unit) {
                callback(Result.success(Unit))
            }
        })
    }
}
```

**Required divergence in Phase 2:**
- The inline `object : AccessibilityApi { ... openAccessibilitySettings() ... }` block becomes a real `Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)` launch via `resolveActivity` guard. The "// No-op stub; Phase 2 deep-links to system settings." comment is the in-tree sign-off that Phase 2 OWNS this method.
- Add two new `setUp` calls — `AppPickerApi.setUp(...)` and `PermissionStatusApi.setUp(...)`. Bind them to dedicated impl classes (`AppPickerHostImpl(this)`, `PermissionStatusApiImpl(this)`) rather than inlining — they are too big.
- Keep the `UsageApi` and `NotificationApi` stubs unchanged (Phase 3/5 owns them).
- The "Phase 1 wires UNIMPLEMENTED stubs..." comment must be UPDATED to reflect Phase 2's claim on `AppPickerApi`, `PermissionStatusApi`, and `AccessibilityApi.openAccessibilitySettings`.

---

### `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt` (NEW)

- **Wave:** 1
- **Role:** Native Kotlin HostApi implementation
- **Analog:** GAP — Phase 1 only ships generated `.g.kt` and inline `object : ...` impls in MainActivity

**Pattern excerpt** — see RESEARCH §App Picker Implementation (Kotlin side — system-app + launcher filter, lines 244-267). Verbatim:
```kotlin
override fun listInstalledApps(callback: (Result<List<InstalledApp>>) -> Unit) {
  executor.execute {
    val pm = context.packageManager
    val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
    val launchablePackages = pm
      .queryIntentActivities(launcherIntent, 0)
      .map { it.activityInfo.packageName }
      .toSet()
    val all = pm.getInstalledApplications(PackageManager.MATCH_DEFAULT_ONLY)
      .map { ai ->
        InstalledApp(
          packageName = ai.packageName,
          displayName = pm.getApplicationLabel(ai).toString(),
          isSystemApp = (ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0,
          hasLauncherIntent = ai.packageName in launchablePackages,
        )
      }
      .sortedBy { it.displayName.lowercase() }
    callback(Result.success(all))
  }
}
```

**Required divergence:** None — this is the canonical pattern. Concrete obligations:
- The class MUST own a `private val executor = Executors.newSingleThreadExecutor()` field — never run on the main thread (RESEARCH §App Picker Implementation, plus PITFALLS).
- The package declaration MUST be `package com.nottodo.not_to_do_list.platform` (matches the `kotlinOptions.package` in `pigeons/app_picker_api.dart`).
- For `recentlyUsedApps`, gate on `AppOpsManager.unsafeCheckOpNoThrow(OPSTR_GET_USAGE_STATS, …) == MODE_ALLOWED` and return `emptyList()` (NOT throw) when not granted — see RESEARCH §Pitfall A.
- For `getApplicationIconPng`, encode at 96×96 PNG via `androidx.core.graphics.drawable.toBitmap` (RESEARCH §Icon encoding).

---

### `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt` (NEW)

- **Wave:** 1
- **Role:** Native Kotlin HostApi implementation
- **Analog:** GAP — same as AppPickerHostImpl

**Pattern excerpt** — see RESEARCH §Status check helpers + Code Examples Example 4 (lines 470-498 + 1027-1042). Verbatim:
```kotlin
fun isUsageAccessGranted(): Boolean {
  val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
  val mode = appOps.unsafeCheckOpNoThrow(            // unsafe* on API 29+
    AppOpsManager.OPSTR_GET_USAGE_STATS,
    Process.myUid(),
    context.packageName,
  )
  return mode == AppOpsManager.MODE_ALLOWED
}

fun isAccessibilityServiceEnabled(): Boolean {
  val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
  val target = ComponentName(context, NotToDoAccessibilityService::class.java).flattenToString()
  return am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
    .any { it.id == target || it.resolveInfo.serviceInfo.let { si ->
        ComponentName(si.packageName, si.name).flattenToString() == target } }
}

fun isIgnoringBatteryOptimizations(): Boolean {
  val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
  return pm.isIgnoringBatteryOptimizations(context.packageName)
}
```

And the `resolveActivity`-guarded deep-link launcher template:
```kotlin
override fun openUsageAccessSettings(callback: (Result<Unit>) -> Unit) {
  val pm = context.packageManager
  val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  if (intent.resolveActivity(pm) != null) {
    context.startActivity(intent); callback(Result.success(Unit)); return
  }
  // Fallback: app-details settings (always resolves on stock Android)
  val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
    .setData(Uri.parse("package:${context.packageName}"))
    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  if (fallback.resolveActivity(pm) != null) {
    context.startActivity(fallback); callback(Result.success(Unit)); return
  }
  callback(Result.failure(Exception("No Settings activity resolves on this device")))
}
```

**Required divergence:** None — this is canonical. Note:
- `currentBuildFingerprint()` returns `android.os.Build.FINGERPRINT`.
- `currentManufacturer()` returns `android.os.Build.MANUFACTURER.lowercase()` (the lowercase normalization is REQUIRED — Dart-side `oemSlugs` map keys are lowercase).
- The accessibility check (RESEARCH lines 481-487) compares full `ComponentName.flattenToString()` — DO NOT match by package name alone. Same component-matching the Phase 1 manifest declares: `.service.NotToDoAccessibilityService`.

---

### `lib/domain/providers/database_provider.dart` (REUSE — DO NOT MODIFY)

- **Wave:** N/A (reused as-is)
- **Role:** Riverpod provider
- **Analog:** self

**Pattern excerpt** (verbatim, lines 1-14):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

/// Singleton [AppDatabase] for the app lifetime.
///
/// Phase 1 uses a plain Riverpod [Provider] (not `@riverpod` codegen) because
/// `riverpod_generator` was dropped in Plan 01-01 due to an analyzer-version
/// conflict with `pigeon 26.3.4` + Flutter 3.41 (see 01-01-SUMMARY.md). The DB
/// is closed when the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

**Required divergence:** none — it is the canonical Phase 2 hand-written provider template. Every NEW Phase 2 Riverpod provider follows this style: `final fooProvider = Provider<Foo>((ref) { ... });` — NO `@riverpod` annotation, NO codegen.

---

### `lib/domain/providers/block_list_dao_provider.dart` (NEW)

- **Wave:** 2
- **Role:** Riverpod provider
- **Analog:** `lib/domain/providers/database_provider.dart`

**Pattern excerpt** (verbatim from analog, lines 10-14):
```dart
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

**Required divergence:** consume `databaseProvider`, do NOT instantiate `AppDatabase` again:
```dart
final blockListDaoProvider = Provider<BlockListDao>((ref) {
  return BlockListDao(ref.watch(databaseProvider));
});
```

Style mandates:
- Single hand-written `Provider<T>` per file (mirrors Phase 1 `database_provider.dart` and `blocked_app_detector_provider.dart`).
- No `riverpod_annotation` import. No `part 'foo.g.dart';`.

---

### `lib/domain/providers/permission_status_api_provider.dart` + `app_picker_api_provider.dart` (NEW)

- **Wave:** 2
- **Role:** Riverpod provider (Pigeon `@HostApi` instance)
- **Analog:** `lib/domain/providers/blocked_app_detector_provider.dart`

**Pattern excerpt** (verbatim from analog, lines 14-29):
```dart
final Provider<bool> useAccessibilityServiceProvider = Provider<bool>(
  (ref) => true,
);

/// The single Riverpod entry point. The rest of the app depends ONLY on this.
/// Swapping the implementation requires changing one line in this file.
final Provider<BlockedAppDetector> blockedAppDetectorProvider =
    Provider<BlockedAppDetector>((ref) {
      final useA11y = ref.watch(useAccessibilityServiceProvider);
      if (useA11y) {
        return AccessibilityBlockedAppDetector();
      } else {
        return UsageStatsPollingBlockedAppDetector();
      }
    });
```

**Required divergence:** Phase 2 doesn't need a flag-driven swap. The provider is a flat singleton:
```dart
final permissionStatusApiProvider =
    Provider<PermissionStatusApi>((ref) => PermissionStatusApi());
```

Style mandates:
- Match the existing all-caps `Provider<T>` annotation form so the analyzer-strict rules from `very_good_analysis 10.2.0` are happy.
- The Pigeon-generated class `PermissionStatusApi` is the constructor target — same way Phase 1 would consume `UsageApi()` if it were wired.
- Tests override via `ProviderContainer(overrides: [permissionStatusApiProvider.overrideWith((ref) => mockPermissionStatusApi)])` — verbatim style from `test/domain/providers/blocked_app_detector_provider_test.dart` lines 25-28.

---

### `lib/features/health/permission_health_provider.dart` (NEW)

- **Wave:** 2
- **Role:** Riverpod `AsyncNotifierProvider`
- **Analog:** GAP

**Pattern excerpt** — verbatim from RESEARCH §Self-Healing Health Check Architecture (lines 517-565):
```dart
class PermissionHealth {
  const PermissionHealth({
    required this.usageAccess,
    required this.accessibilityService,
    required this.batteryOptExempt,
    required this.fingerprintChanged,
  });
  final bool usageAccess;
  final bool accessibilityService;
  final bool batteryOptExempt;
  final bool fingerprintChanged;

  bool get allHealthy =>
      usageAccess && accessibilityService && batteryOptExempt && !fingerprintChanged;
}

final permissionHealthProvider =
    AsyncNotifierProvider<PermissionHealthNotifier, PermissionHealth>(
  PermissionHealthNotifier.new,
);

class PermissionHealthNotifier extends AsyncNotifier<PermissionHealth> {
  @override
  Future<PermissionHealth> build() => _evaluate();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _evaluate());
  }

  Future<PermissionHealth> _evaluate() async { ... }
}
```

**Required divergence in Phase 2:** none — this is the canonical shape. Consume `permissionStatusApiProvider` inside `_evaluate()` via `ref.read(permissionStatusApiProvider)`. First-install fingerprint baseline IS REQUIRED (RESEARCH lines 568-576).

---

### `lib/domain/schedule/schedule_window.dart` (NEW)

- **Wave:** 2
- **Role:** pure-Dart helper
- **Analog:** `lib/domain/blocked_app_detector.dart` (sibling under `lib/domain/`)

**Pattern excerpt** — verbatim from RESEARCH §Schedule Active-Window Evaluation (lines 728-757). Style mandates from analog:
- File-level docstring explaining the contract (similar to `blocked_app_detector.dart` which begins with `/// The single seam between …`).
- Pure-Dart, no Flutter / no Riverpod imports.
- Single top-level function, NOT a class — RESEARCH spec is functional.
- The file MUST also export `int streakDayFor(DateTime now)` per RESEARCH lines 762-764 (or live in a sibling `streak_day.dart`).

---

### `lib/core/router/app_router.dart` (MODIFY)

- **Wave:** 3
- **Role:** GoRouter declaration
- **Analog:** self

**Pattern excerpt** (verbatim, lines 1-19):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/home/pages/empty_home_screen.dart';

/// GoRouter provider — hand-written (no `@riverpod` codegen) because Plan 01-01
/// dropped `riverpod_annotation`/`riverpod_generator` due to analyzer-pin
/// incompatibility with `pigeon 26.3.4` + Flutter 3.41 (`meta 1.17`).
/// See `.planning/phases/01-foundation-play-declaration/01-01-SUMMARY.md`.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const EmptyHomeScreen(),
      ),
    ],
  ),
);
```

**Required divergence in Phase 2** — extend (not replace) per RESEARCH §GoRouter redirect (lines 829-849):
- Replace import `empty_home_screen.dart` → `home_screen.dart` once HomeScreen exists.
- Add a `redirect: (ctx, state) { ... }` callback that consults `onboardingCompleteProvider` via `ref.read`.
- Add 8 routes: `/onboarding/welcome`, `/onboarding/quick-add`, `/onboarding/permissions/usage-access`, `/onboarding/permissions/accessibility`, `/onboarding/permissions/battery-opt`, `/list/add-app`, `/list/add-habit`, `/list/edit/:id`.
- KEEP the docstring about "no `@riverpod` codegen" verbatim — it documents the project-wide invariant.
- Keep `final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(` shape — do NOT switch to `@riverpod` annotation.

---

### `lib/core/theme/app_theme.dart` (MODIFY)

- **Wave:** 3
- **Role:** ThemeData declaration
- **Analog:** self

**Pattern excerpt** (verbatim, lines 1-13):
```dart
import 'package:flutter/material.dart';

abstract class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
  );
}
```

**Required divergence:** wire `dynamic_color` `DynamicColorBuilder` (UI-SPEC §Color requires Material You). Static fallback uses `ColorScheme.fromSeed(seedColor: Color(0xFF...green...))` (UI-SPEC Surface 1 mentions deep forest green). Keep the `abstract class AppTheme` + `static final ThemeData` shape; Phase 2 does NOT pivot to a class instance / Riverpod theme provider.

---

### `lib/features/home/pages/home_screen.dart` (NEW — replaces empty_home_screen.dart conceptually)

- **Wave:** 3
- **Role:** screen (Stateless / Consumer)
- **Analog:** `lib/features/home/pages/empty_home_screen.dart`

**Pattern excerpt** (verbatim, lines 1-13):
```dart
import 'package:flutter/material.dart';

class EmptyHomeScreen extends StatelessWidget {
  const EmptyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not To-Do List')),
      body: const Center(child: Text('Your not-to-do list is empty.')),
    );
  }
}
```

**Required divergence in Phase 2:**
- Becomes `class HomeScreen extends ConsumerWidget` — `ConsumerWidget` is the project's Riverpod-aware base (see `lib/app.dart` line 6 — `class NotToDoApp extends ConsumerWidget`).
- Body wraps a `Column` with `HealthCheckBanner` (mounted from `permissionHealthProvider`) above a `ListView.builder` of `BlockListRow` widgets.
- The empty-state `Center(...)` text is preserved as a fallback when the list is empty (UI-SPEC Surface 12).
- Two FAB-equivalents: `+ Add app`, `+ Add habit` — UI-SPEC §Surface 4.
- Keep `appBar: AppBar(title: const Text('Not To-Do List'))` exactly — branding is locked.
- Whether to KEEP `empty_home_screen.dart` as a separate widget or DELETE is a CONTEXT.md/Karpathy "surgical-changes" judgment: prefer to keep the file and re-purpose `EmptyHomeScreen` as the empty-state widget surface, but planner can delete if cleaner. Either way, `app_router.dart` import line MUST update.

---

### `lib/features/onboarding/pages/usage_access_step.dart` (NEW)

- **Wave:** 3
- **Role:** screen (`ConsumerStatefulWidget` + `WidgetsBindingObserver`)
- **Analog:** GAP — Phase 1 has no lifecycle-aware screens

**Pattern excerpt** — verbatim from RESEARCH §onResume Return-Detection Pattern (lines 400-435):
```dart
class _UsageAccessStepState extends ConsumerState<UsageAccessStep>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold-mount check — if already granted (e.g., re-entry after grant), advance immediately.
    _checkAndMaybeAdvance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndMaybeAdvance();
    }
  }

  Future<void> _checkAndMaybeAdvance() async {
    final granted = await ref
        .read(permissionStatusApiProvider)
        .isUsageAccessGranted();
    if (!mounted) return;
    if (granted) {
      ref.read(onboardingCursorProvider.notifier).advance();
      context.go('/onboarding/permissions/accessibility');
    }
  }
}
```

**Required divergence:** none on the lifecycle skeleton. Per-step diffs:
- `accessibility_step.dart` checks `isAccessibilityServiceEnabled()` and routes to `/onboarding/permissions/battery-opt`. PLAY-06 disclosure copy MUST appear in the rationale block (verbatim phrases from RESEARCH §PLAY-06 Prominent Disclosure: "package name … only when a window-state-changed event fires", "never reads your screen", "never sends anything off your device", "disable this at any time").
- `battery_opt_step.dart` checks `isIgnoringBatteryOptimizations()`, advances to `/`, and on advance: persists `onboardingCompleteProvider = true` AND records `last_known_fingerprint`.
- `addObserver(this)` / `removeObserver(this)` pairing is MANDATORY (RESEARCH §Pitfall D).

---

### `test/data/database/migration_v1_to_v2_test.dart` (NEW)

- **Wave:** 0
- **Role:** test (Drift in-memory + raw SQL)
- **Analog:** `test/data/database/app_database_test.dart`

**Pattern excerpt** (verbatim from analog, lines 1-58):
```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

void main() {
  group('AppDatabase schema v1 round-trip', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('all 5 tables exist after onCreate', () async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            'ORDER BY name;',
          )
          .get();
      ...
    });

    test('block_list insert + select round-trips', () async {
      await db.into(db.blockList).insert(
            BlockListCompanion.insert(
              kind: 0,
              packageName: const Value('com.instagram.android'),
              displayName: 'Instagram',
              reasonNote: const Value('Doomscrolling at night.'),
              createdAt: DateTime.utc(2026, 4, 27, 12),
              updatedAt: DateTime.utc(2026, 4, 27, 12),
            ),
          );
      ...
    });

    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
    });
  });
}
```

**Required divergence in Phase 2:**
- Group name → `'AppDatabase v1 → v2 migration'`.
- The `'schemaVersion is 1'` test becomes `'schemaVersion is 2'`.
- Add the v1→v2 round-trip: insert a v1-shape row via raw `customStatement` (RESEARCH lines 680-685), assert `blockMode == 'soft'`, schedule columns null (RESEARCH lines 689-692).
- Use `dart run drift_dev schema dump` once at Wave 0 to capture a v1 fixture, then `verifySelf` for the migration assertion (RESEARCH line 697).
- Keep `setUp` / `tearDown` lifecycle pattern — IDENTICAL.
- Use `BlockListCompanion.insert(...)` with `Value(...)` wrappers — IDENTICAL.

---

### `test/domain/schedule/schedule_window_test.dart` (NEW)

- **Wave:** 0
- **Role:** test (pure-Dart truth table)
- **Analog:** `test/domain/providers/blocked_app_detector_provider_test.dart`

**Pattern excerpt** (verbatim from analog, lines 10-21):
```dart
void main() {
  group('blockedAppDetectorProvider (REL-05)', () {
    test('default flag (true) returns AccessibilityBlockedAppDetector', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final detector = container.read(blockedAppDetectorProvider);

      expect(detector, isA<AccessibilityBlockedAppDetector>());
      expect(detector, isA<BlockedAppDetector>());
    });
```

**Required divergence:** drop the `ProviderContainer` (pure function — no Riverpod). One `group('isInScheduleWindow', () { ... })` with 13 `test(...)` cases per RESEARCH §Test matrix table (WIN-01 through WIN-13). Style mandates:
- One assertion per test, named after the WIN-NN ID — easy to grep when a regression bisects.
- WIN-10/WIN-11 must NOT assert truth; only `expect(() => isInScheduleWindow(...), returnsNormally)` per RESEARCH line 784.

---

### `test/domain/providers/blocked_app_detector_provider_test.dart` (REUSE — and the PLAY-02 absence-grep test it contains is the template for play06_disclosure_test.dart)

- **Wave:** N/A (reused as-is, possibly EXTENDED in Wave 0 to cover the new API source files)
- **Role:** Phase-1 source-file regex assertion test — model for PLAY-02/06-style enforcement
- **Analog:** self

**Pattern excerpt** (verbatim, lines 40-67):
```dart
group('PLAY-02 enforcement-by-absence in BlockedAppDetector', () {
  test('blocked_app_detector.dart declares no autonomous-action methods', () {
    final source = File(
      'lib/domain/blocked_app_detector.dart',
    ).readAsStringSync();

    expect(
      RegExp(r'\bperformAction\s*\(').hasMatch(source),
      isFalse,
      reason:
          'BlockedAppDetector must not declare performAction (PLAY-02)',
    );
    ...
  });
});
```

**Required divergence:** `play06_disclosure_test.dart` reads the rationale-screen widget file (`lib/features/onboarding/pages/accessibility_step.dart`) and asserts each PLAY-06 phrase (`"package name"`, `"only when a window-state-changed event fires"`, `"never reads your screen"`, `"never sends anything off your device"`, `"disable this at any time"`) appears in the source via `RegExp(...).hasMatch(source)` — exact same idiom. Phase 2 may also EXTEND the existing `blocked_app_detector_provider_test.dart` PLAY-02 group to also scan `lib/platform/permission_status_api.g.dart` (new file) for the forbidden tokens.

---

### `pubspec.yaml` (MODIFY)

- **Wave:** 1
- **Role:** project manifest
- **Analog:** self

**Pattern excerpt** (verbatim, lines 1-40):
```yaml
name: not_to_do_list
description: "Not To-Do List — mindful avoidance for self-disciplined adults"
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.5.0
  flutter: ^3.41.0

# Phase 1 dep notes (2026-05-04):
# - riverpod_annotation/_generator dropped — they pin analyzer minors that
#   conflict with pigeon 26.3.4 + Flutter 3.41 (meta 1.17). Providers in this
#   phase are hand-written. Reintroduce when ecosystem converges on analyzer 12+.
# - custom_lint/riverpod_lint dropped for the same reason. Lint enforcement
#   is still active via very_good_analysis.

dependencies:
  drift: ^2.33.0
  drift_flutter: ^0.3.0
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.3.1
  go_router: ^17.2.3
  intl: ^0.20.2
  path: ^1.9.1
  path_provider: ^2.1.5
  shared_preferences: ^2.5.5

dev_dependencies:
  build_runner: ^2.4.0
  drift_dev: ^2.33.0
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.5
  pigeon: ^26.3.4
  very_good_analysis: ^10.2.0

flutter:
  uses-material-design: true
```

**Required divergence in Phase 2:**
- Add to `dependencies`: `dynamic_color: ^1.7.0`, `url_launcher: ^6.3.0` (RESEARCH §Standard Stack).
- Under `flutter:`, add an `assets:` block declaring `assets/onboarding/` and `assets/logos/` directories.
- DO NOT add: `permission_handler`, `app_settings`, `app_usage`, `flutter_accessibility_service`, `flutter_overlay_window`, `flutter_local_notifications`, `firebase_*`, `sentry_*`, anything in the OOS list (RESEARCH §Out-of-Scope Guardrails).
- Preserve the "Phase 1 dep notes" comment block — it documents an invariant.

---

## Naming + Style Conventions Detected

### Riverpod provider naming
- **All providers are hand-written `final fooProvider = Provider<T>((ref) { ... })`** — NO `@riverpod` annotation, NO `part 'foo.g.dart';`. Pattern enforced project-wide; the docstring in `database_provider.dart` lines 6-9 and `app_router.dart` lines 5-8 spells out WHY (analyzer-pin incompatibility with pigeon 26.3.4).
- Provider variable name = **camelCase + `Provider` suffix**: `databaseProvider`, `useAccessibilityServiceProvider`, `blockedAppDetectorProvider`, `appRouterProvider`. Phase 2 must continue: `blockListDaoProvider`, `permissionHealthProvider`, `appPickerApiProvider`.
- Type annotation is **explicit and goes BEFORE** the variable: `final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(...)`. This is a `very_good_analysis` style; do not drop the redundant-looking generic.
- Tests override providers via `ProviderContainer(overrides: [provider.overrideWith((ref) => fake)])` and `addTearDown(container.dispose)` (see `test/domain/providers/blocked_app_detector_provider_test.dart` lines 24-30).

### Drift table → DAO → repo layering
- **Tables** under `lib/data/database/tables/{snake_case}_table.dart`. One class per file. Each table file imports `package:drift/drift.dart` and (if foreign-keyed) `package:not_to_do_list/data/database/tables/block_list_table.dart`.
- **Class name**: PascalCase, **no `Table` suffix** (so the generated companion is `BlockListData`/`BlockListCompanion`, not `BlockListTableData`).
- **Database** at `lib/data/database/app_database.dart` with the `@DriftDatabase(tables: [...])` annotation and `_$AppDatabase` mixin.
- **Default values** use `withDefault(const Constant(...))` — never plain Dart literals.
- **Foreign keys** use `references(BlockList, #id, onDelete: KeyAction.cascade)` (see `daily_streak_table.dart:8`, `pause_events_table.dart:8`, `daily_checkins_table.dart:8`).
- **Unique keys** declared via the `uniqueKeys` getter override.
- **DAOs**: GAP — Phase 1 didn't add any. Phase 2 may add them under `lib/data/database/daos/{name}_dao.dart` with the `@DriftAccessor(tables: [BlockList])` annotation; the `@DriftDatabase` annotation on `app_database.dart` then extends to `daos: [BlockListDao]`. Keep the directory name `daos/` to mirror the existing `tables/` sibling.
- **Repositories** under `lib/data/repositories/{name}_repository.dart`. Phase 1 placeholder is just `.gitkeep`; Phase 2 fills it. Repos consume DAOs via constructor injection (matches `BlockedAppDetector` interface pattern in `lib/domain/`).

### Pigeon channel naming
- **Input** at `pigeons/{snake_case}_api.dart` (e.g., `usage_api.dart`, `accessibility_api.dart`, `notification_api.dart`).
- **Dart output** at `lib/platform/{snake_case}_api.g.dart`.
- **Kotlin output** at `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/{PascalCase}Api.g.kt` (note the case shift — `usage_api.dart` → `UsageApi.g.kt`).
- **Kotlin package**: `com.nottodo.not_to_do_list.platform` (every Pigeon API uses the same package).
- **Error class names MUST be unique per file**: `errorClassName: 'UsageApiError'`, `'AccessibilityApiError'`, `'NotificationApiError'`. The comment "// See usage_api.dart for the FlutterError-redeclaration rationale." appears in every sibling file and MUST be reproduced when adding new APIs.
- **`@async` everywhere** for methods that read state — even simple booleans.
- **`one_member_abstracts`** ignore directive at the top of single-method APIs: `// ignore_for_file: one_member_abstracts` (see `usage_api.dart:2`).
- **Kotlin impl class naming**: `{PascalCase}Impl` (e.g., `AppPickerHostImpl`, `PermissionStatusApiImpl`) — established by RESEARCH §App Picker Implementation, not by Phase 1 (which inlines impls in `MainActivity`).
- **Wiring** in `MainActivity.configureFlutterEngine`: `XxxApi.setUp(flutterEngine.dartExecutor.binaryMessenger, impl)`.

### Test file colocation
- Tests under `test/{lib-relative-path}/{name}_test.dart`. Phase 1 examples: `test/data/database/app_database_test.dart`, `test/domain/providers/blocked_app_detector_provider_test.dart`. Phase 2 follows: `test/data/database/migration_v1_to_v2_test.dart`, `test/data/repositories/block_list_repo_test.dart`, etc.
- **Test framework**: `flutter_test` + `mocktail 1.0.5`. NO `mockito`, NO `riverpod_test`.
- **Test structure**: `void main() { group('Subject (REQ-ID)', () { test('...', () { ... }); }); }` — see `blocked_app_detector_provider_test.dart` line 11: `group('blockedAppDetectorProvider (REL-05)', () { ... })`. Phase 2 MUST keep the `(REQ-ID)` annotation in the group name.
- **Drift in-memory fixture**: `AppDatabase(NativeDatabase.memory())` — see `app_database_test.dart:11`.
- **Source-file regex assertion** is an established Phase 1 pattern for policy invariants (PLAY-02 absence-grep). Phase 2 reuses for PLAY-06 verbatim phrases.

### Onboarding-specific conventions (Phase 2 establishes)
- **Step screens** are `ConsumerStatefulWidget` (NOT `ConsumerWidget`) — they need `WidgetsBindingObserver` mixin.
- **`addObserver` in `initState` paired with `removeObserver` in `dispose`** — RESEARCH §Pitfall D.
- **`shared_preferences` keys** are bare lowercase strings: `'onboarding_step'` (int), `'onboarding_complete'` (bool), `'last_known_fingerprint'` (String). Centralize in a `lib/features/onboarding/storage_keys.dart` const class if convenient.
- **OEM detection** lives Dart-side (`Build.MANUFACTURER` returned by Pigeon, `.toLowerCase()` matched against the locked `oemSlugs` map in RESEARCH §dontkillmyapp.com URL pattern).

### Asset declarations
- **Top-level `assets/` directory** does NOT yet exist in Phase 1. Phase 2 creates it.
- **Subdirectories** keyed by purpose: `assets/onboarding/`, `assets/logos/`.
- **`pubspec.yaml`** registers them under `flutter:` → `assets:` — directory-level entries (trailing slash) auto-include all files; saves listing each PNG.
- **Image format**: PNG only (per CONTEXT.md "Static screenshot PNGs … no animated GIFs"). Lossless; alpha-aware.

---

## Files NOT to Touch (Phase 1 invariants)

| File | Reason |
|------|--------|
| `lib/domain/blocked_app_detector.dart` | Frozen interface until Phase 4 lights it up. PLAY-02 absence-grep test (`blocked_app_detector_provider_test.dart:42`) reads this file at runtime — modifying it can break the regex assertions. |
| `lib/data/detectors/accessibility_blocked_app_detector.dart` | Phase 4 fills the body. Phase 2 leaves the `UnimplementedError` stubs untouched. |
| `lib/data/detectors/usage_stats_polling_blocked_app_detector.dart` | Kill-switch fallback; Phase 4/PLAY-08 territory. Phase 2 does not modify. |
| `lib/domain/providers/blocked_app_detector_provider.dart` | "DO NOT MODIFY — Phase 4 wedge" (RESEARCH line 795-796). |
| `lib/data/database/tables/daily_streak_table.dart` | Phase 5 territory. Phase 2 only extends `block_list_table.dart`. |
| `lib/data/database/tables/pause_events_table.dart` | Phase 4/5 territory. |
| `lib/data/database/tables/daily_checkins_table.dart` | Phase 5 territory. |
| `lib/data/database/tables/daily_usage_summary_table.dart` | Phase 3 territory. |
| `lib/data/database/app_database.g.dart` | Generated by `build_runner` (`drift_dev`). NEVER hand-edit; regenerate via `flutter pub run build_runner build --delete-conflicting-outputs` after table edits. |
| `lib/platform/usage_api.g.dart` | Generated by Pigeon; do not edit. |
| `lib/platform/accessibility_api.g.dart` | Generated by Pigeon; do not edit. |
| `lib/platform/notification_api.g.dart` | Generated by Pigeon; do not edit. |
| `pigeons/usage_api.dart` | Phase 3 territory (the comment "Phase 3 will implement this. Phase 1 ships interface only." stays). Phase 2 does NOT add picker methods to this file — they go in a NEW `app_picker_api.dart`. |
| `pigeons/accessibility_api.dart` | Phase 1 contract is fixed (RESEARCH line 466 — "leaving the Phase 1 contract untouched"). |
| `pigeons/notification_api.dart` | Phase 5 territory. |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApi.g.kt` | Pigeon-generated. |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt` | Pigeon-generated. |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApi.g.kt` | Pigeon-generated. |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt` | Stub; Phase 4 owns the body. The manifest entry stays correct because Phase 1 made it correct. |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt` | AccessibilityService stub; Phase 4 lights it up. PLAY-03 invariant: do NOT add `canRetrieveWindowContent` / text-content reading. |
| `android/app/src/main/AndroidManifest.xml` | Modify only if absolutely necessary. The `<queries>` LAUNCHER block, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission, and `<service>` block are ALL pre-wired. Phase 2 should NOT add new permissions. RESEARCH §Out-of-Scope Guardrails forbids `QUERY_ALL_PACKAGES`, `SYSTEM_ALERT_WINDOW`, `BIND_DEVICE_ADMIN`. |
| `docs/play-declaration.md` | Phase 6 PLAY-08 territory. Phase 2 only READS for PLAY-06 disclosure phrases. |
| `test/data/database/app_database_test.dart` | Phase 1 test for schema v1. Phase 2 ADDS a new migration test file — it does NOT modify this one (the `'schemaVersion is 1'` assertion is a snapshot-of-Phase-1 artefact; Phase 2's new test asserts `schemaVersion is 2`). |

---

## Excluded — Out-of-v1-Scope Patterns Encountered During Scan

The following analog files / themes surfaced during the codebase scan and are EXCLUDED from Phase 2 per the v1-scope guardrails (CONTEXT.md `<v1_scope_carryforward>`):

| Encountered | Why excluded |
|-------------|--------------|
| `BIND_DEVICE_ADMIN` patterns | Anti-uninstall is OUT OF v1. None present in Phase 1; Phase 2 must NOT introduce any reference. |
| Parent-PIN / kid-mode UI shells | None exist in Phase 1 features tree; Phase 2 must not seed them. The `permissionHealthProvider` and onboarding cursor are NOT auth-gated. |
| Website / DNS / VPN blocking | No DNS/VPN code paths in Phase 1; Phase 2 must not introduce. AccessibilityService stays `typeWindowStateChanged`-only (PLAY-03). |
| Content-type filter (18+, gambling) | No third-party categorization SDK in Phase 1; Phase 2 must not add. |
| `QUERY_ALL_PACKAGES` permission | Manifest scan (`AndroidManifest.xml` lines 1-119) confirmed absent; the `<queries>` + LAUNCHER intent filter (lines 43-48) is the policy-correct alternative. |
| `SYSTEM_ALERT_WINDOW` overlay | Manifest scan confirmed absent. Phase 2 banner is a Material widget at top of `Scaffold.body`, NOT an overlay. |
| Telemetry / analytics / FCM | `pubspec.yaml` scan confirmed zero `firebase_*`, `sentry_*`, `mixpanel_*`, `amplitude_*`. Phase 2 adds two scoped deps (`dynamic_color`, `url_launcher`); both are local-only. |

---

## Open Pattern Risks

| # | Risk | Mitigation in plan |
|---|------|---------------------|
| 1 | `onboardingCompleteProvider` may already exist somewhere I missed (`test/_fixtures/onboardingCompleteOverrides`?). I confirmed via directory scan that `lib/` and `test/` do NOT contain a definition of that name. RESEARCH §Riverpod Provider Wiring (line 823) and §Open Questions §1 flag this as `[ASSUMED]`. | Plan Wave 0 task: `grep -rn "onboardingComplete" lib/ test/` before creating new provider; if found, REUSE the existing one rather than duplicate. |
| 2 | Drift v1 schema fixture for migration test must be captured via `dart run drift_dev schema dump` BEFORE the table edit lands — otherwise the v1 fixture is no longer reproducible. | Plan Wave 0 sequencing: schema dump → write migration test → edit table → verify upgrade → write app_database.dart migration step. |
| 3 | UI-SPEC Surface 11 banner mentions `MaterialBanner` semantics but UI-SPEC Surface 11 also says "non-modal single-line at top of `Scaffold.body`" — this can be satisfied by a custom `Container`/`Card` not the `MaterialBanner` widget. Either is fine, but planner picks one and notes. | Defer to UI-SPEC Surface 11 widget choice; planner picks `MaterialBanner` if compatible with the "subdued amber single-line" aesthetic, custom `Card` otherwise. |
| 4 | Phase 1 has NO widget tests. Wave 0 must establish the widget-test harness; the scaffolding has no in-tree analog. | Reference RESEARCH §Validation Architecture for the `pumpWidget` + `mocktail` pattern; treat first widget test as the template that subsequent ones imitate. |
| 5 | `assets/logos/` license question (UI-SPEC OQ-2). RESEARCH recommends runtime `getApplicationIcon` + generic-icon fallback. | Plan should record the chosen approach explicitly; default to runtime-fetch + generic-icon (no committed brand PNGs) to avoid trademark exposure. |

---

## PATTERN MAPPING COMPLETE
