# Phase 1: Foundation & Play Declaration — Research

**Researched:** 2026-04-26
**Domain:** Flutter Android scaffolding, Drift schema, Pigeon contracts, AndroidManifest skeleton, Play Console declaration drafting
**Confidence:** HIGH (all primary claims verified against the project's own research bundle, official docs, and pub.dev). MEDIUM on the `flutter_accessibility_service` integration surface (well-known library but used here only as a *future* implementation seam — Phase 1 does not pull it in).

> **Note for the planner:** A `<phase_requirements>` section is included near the top. Every requirement ID listed there must appear as a checkable success criterion in PLAN.md. Honor `<user_constraints>` verbatim — none of those decisions are negotiable in Phase 1.

---

<phase_requirements>
## Phase Requirements

| ID | Description (from REQUIREMENTS.md) | Research Support (this doc) |
|----|-------------------------------------|------------------------------|
| **PLAY-01** | Accessibility service manifest sets `isAccessibilityTool="false"` | §5 `notTodo_a11y_config.xml` content + §4 manifest service entry |
| **PLAY-02** | Service never calls `performAction`, `performGlobalAction`, or `dispatchGesture` | §6 abstraction interface design (no such methods on `BlockedAppDetector`); §8 declaration copy literally promises this; §10 verification grep |
| **PLAY-03** | Accessibility event types are scoped to `typeWindowStateChanged` only | §5 config XML uses single event type, no others; §10 verification grep |
| **PLAY-04** | App-picker enumerates installed apps via `<queries>` element + LAUNCHER intent filter (NOT `QUERY_ALL_PACKAGES`) | §4 manifest `<queries>` block; §10 grep verifies absence of `QUERY_ALL_PACKAGES` |
| **PLAY-05** | Manifest does NOT include `SYSTEM_ALERT_WINDOW`; pause UI is a `FlutterActivity` | §4 manifest deliberately omits `SYSTEM_ALERT_WINDOW`; §10 grep verifies absence; PauseActivity declaration is stubbed (Phase 4 fills body) |
| **PLAY-07** | Play Console Permission Declaration mirrors the literal mechanical text in `docs/play-declaration.md` | §8 verbatim declaration copy in this doc, ready to paste into `docs/play-declaration.md` |
| **PLAY-09** | Data Safety form matches actual code (no telemetry declared and none in code) | §9 data-safety.md skeleton; §10 dependency-tree grep verifies no FCM/analytics in pubspec |
| **REL-05** | AccessibilityService is architected as a swappable provider behind a Riverpod abstraction so a UsageStats-polling fallback can ship without rework if Play rejects the service | §6 `BlockedAppDetector` interface + Riverpod provider switch |
| **SETT-03** | No data leaves the device — no backend, no telemetry, no FCM, no analytics | §1 `pubspec.yaml` deliberately excludes any network/analytics SDK; §9 data-safety draft; §10 verification grep |
</phase_requirements>

---

<user_constraints>
## User Constraints (from CONTEXT.md)

> **No CONTEXT.md exists for Phase 1** (no `/gsd-discuss-phase` was run). The constraints below are
> sourced directly from PROJECT.md, REQUIREMENTS.md, ROADMAP.md success criteria, and
> CLAUDE.md — and are equally binding. The planner MUST honor them verbatim.

### Locked Decisions (from PROJECT.md, ROADMAP.md, STATE.md, CLAUDE.md)

- **Platform:** Android-only for v1. NO iOS scaffolding generated.
- **Framework:** Flutter 3.41.x stable (Dart 3.x).
- **State management:** Riverpod 3.3.1 with code-gen (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` + `build_runner`).
- **Local DB:** Drift 2.32.1 (SQLite). NOT Hive, Isar, sqflite, or ObjectBox.
- **Routing:** `go_router ^14.x`.
- **Platform channels:** Pigeon 26.x — typed code-gen. NOT hand-rolled MethodChannel.
- **Pause UI mechanism:** `FlutterActivity` (named `PauseActivity`). NOT `SYSTEM_ALERT_WINDOW` overlay. The `flutter_overlay_window` package is NOT to be added in Phase 1; the architecture has been re-decided in `research/ARCHITECTURE.md` against overlays even though `research/STACK.md` originally listed the package.
- **AccessibilityService stance:** `isAccessibilityTool="false"` (we are not assistive tech). Service NEVER calls `performAction` / `performGlobalAction` / `dispatchGesture`. Event types scoped to `typeWindowStateChanged` only.
- **Service is a passive trigger; DB is source of truth** — service does not write to SQLite directly. Single writer = Dart.
- **min/target/compile SDK:** minSdk **29** (Android 10), targetSdk **36** (Android 16), compileSdk **36**.
- **AGP:** 8.11.1+. **Java:** 17. **Kotlin:** Flutter 3.41 template default (currently KGP 2.x, no manual override).
- **Permissions:** `SCHEDULE_EXACT_ALARM` (NOT `USE_EXACT_ALARM`); `<queries>` element + LAUNCHER intent filter (NOT `QUERY_ALL_PACKAGES`); explicitly NO `SYSTEM_ALERT_WINDOW`.
- **Backup:** `android:allowBackup="false"` (privacy stance).
- **Privacy:** 100% on-device. NO telemetry, FCM, Firebase Analytics, Crashlytics, Amplitude, Mixpanel, Segment, Sentry-with-auto-init, or any SDK that ships data off-device.
- **GSD workflow:** Per `./CLAUDE.md` — file-changing tools are gated through GSD commands; do not bypass.

### Claude's Discretion

- **Internal `lib/` folder layout** within the layered + feature-first hybrid documented in `research/ARCHITECTURE.md` (§7 below codifies the exact tree).
- **Drift table column nullability and indices** within the success-criteria-mandated table set (§2).
- **Which lint preset:** `very_good_analysis ^7.0.0` is recommended; `flutter_lints` acceptable. Pick one.
- **Initial empty home screen styling** — minimal, theme-aware, no animation.
- **Whether to ship `flutter_native_splash` / `flutter_launcher_icons` config now or defer to Phase 6** — recommend defer (out of Phase 1 success criteria).

### Deferred Ideas (OUT OF SCOPE for Phase 1)

- AccessibilityService **implementation** (declaration only in Phase 1; Kotlin body is Phase 4).
- UsageStatsManager bridge implementation (Pigeon **interface** only in Phase 1; Kotlin body is Phase 3).
- Pause screen UI (Phase 4).
- Onboarding screens (Phase 2).
- List CRUD UI (Phase 2).
- Streak engine (Phase 5).
- Notifications scheduling logic (Phase 5).
- `flutter_overlay_window` — not added to pubspec at all (architecture decision rejects it).
- `flutter_accessibility_service` — not added in Phase 1 (Phase 4 will decide between the package and a hand-rolled Kotlin service).
- iOS folder, iOS-related Flutter plugins, iOS Pigeon outputs.
- Test on real Xiaomi/Samsung hardware (Phase 4+ exit gate).
</user_constraints>

---

## Summary

Phase 1 is pure-Dart-and-manifest scaffolding with one declaration-copy artifact. The phase ends with a runnable Flutter app that boots to an empty home screen, has a working Drift schema with five tables and round-trip migration tests, has `pigeons/*.dart` interfaces compiled to Dart and Kotlin stubs, has a `BlockedAppDetector` Riverpod provider abstraction with no implementations yet, has an AndroidManifest declaring all required permissions and the `<queries>` element (and explicitly omitting `SYSTEM_ALERT_WINDOW` and `QUERY_ALL_PACKAGES`), has `accessibilityservice/notTodo_a11y_config.xml` with the policy-correct attributes, and has `docs/play-declaration.md` and `docs/data-safety.md` committed as the canonical source of all permission justification copy.

**Primary recommendation:** Build the artifacts in this order — (1) `flutter create` with explicit Android-only platforms, (2) trim `pubspec.yaml` and add ONLY the Phase 1 deps (Drift, Riverpod, go_router, Pigeon as dev_dep), (3) gradle settings (compileSdk/minSdk/targetSdk + Java 17), (4) Drift schema + migrations + round-trip test, (5) Pigeon interface files + codegen, (6) `BlockedAppDetector` abstraction, (7) AndroidManifest + a11y config XML, (8) `docs/play-declaration.md` and `docs/data-safety.md`, (9) verification grep checks. Phase exit only when all ten verification commands in §10 pass.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Drift schema (`block_list`, `daily_streak`, `pause_events`, `daily_checkins`, `daily_usage_summary`) | Database / Storage (Drift SQLite) | — | Single writer = Dart per ARCHITECTURE.md; AccessibilityService never writes DB. |
| Pigeon interface contracts (`usage_api.dart`, `accessibility_api.dart`, `notification_api.dart`) | Frontend Server (Dart-side declaration) → API/Backend (Kotlin host impl, deferred) | Database (none — channels are stateless) | Pigeon `@HostApi` declares Dart→Kotlin sync calls, mirrors REST controller contract pattern. |
| Riverpod state-management scaffolding | Browser/Client (Flutter UI process) | — | All UI state lives in the Flutter process; native side is event source only. |
| AndroidManifest + a11y config XML | API/Backend (Android system-level declaration) | — | Manifest registers OS-managed components (services, activities, receivers); not browser-tier. |
| `BlockedAppDetector` swappable provider | Browser/Client (Riverpod-managed) | API/Backend (concrete implementations later call native APIs) | Abstraction lives in Dart; concrete impls (Phase 4: a11y; fallback: UsageStats polling) bridge to platform. |
| `docs/play-declaration.md`, `docs/data-safety.md` | Documentation / Compliance | — | Single source of truth for Play Console form text; manifest comments and in-app disclosure (Phase 2) reference this file. |

**Why this matters for Phase 1:** All five capabilities are owned by the Flutter process or the Android manifest. There is no API tier, no backend, no CDN, no external service. The "primary tier" column should answer the planner's "where does this code live?" — and for Phase 1 the answer is always Dart or `android/app/src/main/`.

---

## 1. Flutter Project Scaffolding

### `flutter create` invocation

> **Environment availability gate:** `flutter`, `dart`, `java`, `adb`, and Android SDK CLI tools are **NOT** installed on the developer machine (verified via `which flutter dart java adb gradle sdkmanager` — all returned "not found" except `/usr/bin/java`, which itself reports "Unable to locate a Java Runtime"). The plan MUST include a Wave 0 step to install Flutter SDK 3.41.x, Android Studio (or Android command-line tools + platform-tools + platform-36 + build-tools-36 + emulator), and a JDK 17. Without this, none of the verification commands in §10 can run. See §11 (Environment Availability).

```bash
# From the project root (which currently contains only CLAUDE.md and .planning/)
flutter create \
  --org com.nottodo \
  --project-name not_to_do_list \
  --platforms=android \
  --android-language=kotlin \
  --description "Not To-Do List — mindful avoidance for self-disciplined adults" \
  .
```

| Flag | Value | Why |
|------|-------|-----|
| `--org` | `com.nottodo` | Reverse-DNS namespace; produces `applicationId="com.nottodo.not_to_do_list"`. The literal applicationId must NOT change after Phase 1 — Play Console upload key is bound to it. [VERIFIED: Flutter docs] |
| `--project-name` | `not_to_do_list` | snake_case required by Dart. The Flutter `MaterialApp` title can use any display name. |
| `--platforms=android` | Android-only | Suppresses generation of `ios/`, `macos/`, `windows/`, `linux/`, `web/` folders. Critical for Phase 1's Android-only constraint. [VERIFIED: `flutter create --help`] |
| `--android-language=kotlin` | Kotlin (default but explicit) | Native MainActivity / services / Pigeon outputs will be Kotlin. |
| `.` | Generate into current dir | Project root is `/Users/jintanakhomwong/projects/not-to-do-list`. The current `.planning/` and `CLAUDE.md` files coexist with what `flutter create` generates. |

**Post-`flutter create` cleanup:**
1. Delete `test/widget_test.dart` (auto-generated counter app test) — replaced by Drift round-trip test.
2. Delete the counter-app demo body of `lib/main.dart` and `MyHomePage` widget — replace with empty home screen.
3. Confirm no `ios/`, `macos/`, `linux/`, `windows/`, `web/` directories were created. If any exist, delete them.

### `pubspec.yaml` for Phase 1 (Android-only, minimal)

Phase 1 deliberately excludes runtime dependencies that are not used until later phases. This keeps the dep tree audit (§10) clean and prevents accidental telemetry SDK pull-ins.

```yaml
name: not_to_do_list
description: "Not To-Do List — mindful avoidance for self-disciplined adults"
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.5.0
  flutter: ^3.41.0

dependencies:
  flutter:
    sdk: flutter

  # State management (Phase 1 needs the abstraction provider; concrete impls land in Phase 4)
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^3.3.1

  # Routing — minimal nav for Phase 1 (just the empty home), but locked in early
  go_router: ^14.0.0

  # DB — the load-bearing dep for Phase 1
  drift: ^2.32.1
  drift_flutter: ^0.2.0
  path_provider: ^2.1.0
  path: ^1.9.0

  # Misc
  shared_preferences: ^2.3.0
  intl: ^0.20.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Pigeon — interface generation. Dev-only because the .dart files in `pigeons/`
  # are NOT shipped; only their codegen output is.
  pigeon: ^26.3.4

  # Code-gen
  build_runner: ^2.4.0
  riverpod_generator: ^3.3.0
  drift_dev: ^2.32.1
  custom_lint: ^0.7.0
  riverpod_lint: ^3.0.0

  # Lint preset
  very_good_analysis: ^7.0.0

  # Test doubles
  mocktail: ^1.0.0
```

**Deliberately NOT in Phase 1's `pubspec.yaml`** (deferred to later phases as listed):
- `flutter_local_notifications`, `timezone` → Phase 5
- `permission_handler`, `app_settings` → Phase 2
- `app_usage` → Phase 3
- `flutter_accessibility_service` → Phase 4 (or hand-rolled Kotlin)
- `flutter_overlay_window` → never (architecture rejected overlays)
- Anything Firebase / Crashlytics / Amplitude / Sentry / Mixpanel → never in v1

[VERIFIED: pub.dev versions checked 2026-04-26: drift 2.32.1 (36 days old), flutter_riverpod 3.3.1 (49 days old), pigeon 26.3.4 (19 days old)]

### Gradle settings (Android-only)

`flutter create` produces `android/app/build.gradle.kts` with placeholder values. Replace with the locked numbers:

`android/app/build.gradle.kts` (excerpt):
```kotlin
android {
    namespace = "com.nottodo.not_to_do_list"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.nottodo.not_to_do_list"
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Phase 1 uses debug signing; Phase 6 wires release signing for Play submission.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
```

`android/settings.gradle.kts` — Flutter 3.41 template default already declares AGP `8.11.1` and Kotlin via the Flutter Gradle plugin; no override needed for Phase 1. [CITED: STACK.md HIGH-confidence claim, cross-checked against Flutter 3.41 release notes which document AGP/KGP bumps in PR #176858 — exact pin not quoted in release notes; trust template default.]

`android/gradle.properties` — leave Flutter template defaults; the only Phase-1-relevant fact is that `org.gradle.jvmargs` will be set automatically.

**Confidence:** HIGH for SDK numbers (matches Google's Aug-2026 mandate per STACK.md). MEDIUM for the exact Kotlin Gradle Plugin pin — Flutter template owns it.

---

## 2. Drift Schema

The five tables required by the success criteria, plus a `MyDatabase` class skeleton, schema version 1, and a round-trip test.

### File layout

```
lib/
└── data/
    └── database/
        ├── app_database.dart           # @DriftDatabase + MyDatabase class
        ├── app_database.g.dart         # generated by drift_dev (gitignored if you wish)
        └── tables/
            ├── block_list_table.dart
            ├── daily_streak_table.dart
            ├── pause_events_table.dart
            ├── daily_checkins_table.dart
            └── daily_usage_summary_table.dart
```

### `lib/data/database/tables/block_list_table.dart`

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
  IntColumn get streakBreakThresholdMinutes => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        // Same package can appear at most once for an app entry.
        // Habits (packageName null) skip uniqueness via partial index in raw SQL if needed.
        {kind, packageName},
      ];
}
```

### `lib/data/database/tables/daily_streak_table.dart`

```dart
import 'package:drift/drift.dart';
import 'block_list_table.dart';

/// One row per (entry, day). Lazy-evaluated on app open per STRK-05.
class DailyStreak extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer().references(BlockList, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get day => dateTime()(); // anchored to home-tz LocalDate at 00:00
  IntColumn get status => integer()(); // 0 success, 1 broken, 2 incomplete-data, 3 pending
  IntColumn get source => integer()(); // 0 system-confirmed, 1 self-reported-only
  IntColumn get usageMinutesObserved => integer().withDefault(const Constant(0))();
  DateTimeColumn get evaluatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {entryId, day}, // one streak row per entry per day
      ];
}
```

### `lib/data/database/tables/pause_events_table.dart`

```dart
import 'package:drift/drift.dart';
import 'block_list_table.dart';

/// One row per pause-screen interaction. Single writer = Dart (PauseActivity).
class PauseEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer().references(BlockList, #id, onDelete: KeyAction.cascade)();
  TextColumn get packageName => text()();
  DateTimeColumn get triggeredAt => dateTime()();
  IntColumn get cooldownChosenSeconds => integer().nullable()(); // null = user hit Cancel before picking
  IntColumn get outcome => integer()(); // 0 cooldown-completed, 1 cancel, 2 use-anyway

  // Indexed by (entryId, triggeredAt) for fast per-entry timeline queries.
}
```

### `lib/data/database/tables/daily_checkins_table.dart`

```dart
import 'package:drift/drift.dart';
import 'block_list_table.dart';

/// One self-report check-in per entry per day (STRK-03).
class DailyCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer().references(BlockList, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get day => dateTime()();
  BoolColumn get avoided => boolean()();
  DateTimeColumn get answeredAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {entryId, day},
      ];
}
```

### `lib/data/database/tables/daily_usage_summary_table.dart`

```dart
import 'package:drift/drift.dart';

/// Pre-aggregated per-package per-day totals (DASH-04). Read by monthly view.
/// Written by the usage-aggregation worker (Phase 3); read-only in Phase 1.
class DailyUsageSummary extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get foregroundSeconds => integer()();
  IntColumn get launchCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get aggregatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {packageName, day},
      ];
}
```

### `lib/data/database/app_database.dart`

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/block_list_table.dart';
import 'tables/daily_checkins_table.dart';
import 'tables/daily_streak_table.dart';
import 'tables/daily_usage_summary_table.dart';
import 'tables/pause_events_table.dart';

part 'app_database.g.dart';

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

  /// Phase 1 = schema 1. Each later phase that adds a table or column bumps this
  /// and supplies a migration step in `migration` below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // No upgrades yet — schema is at version 1.
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'not_to_do_list');
  }
}
```

### Build-runner config

```bash
# After editing any table or @DriftDatabase annotation:
dart run build_runner build --delete-conflicting-outputs

# Or watch mode during development:
dart run build_runner watch --delete-conflicting-outputs
```

[CITED: drift.simonbinder.eu/setup — verified 2026-04-26]

### Round-trip test (`test/data/database/app_database_test.dart`)

```dart
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
      final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
      ).get();
      final names = tables.map((r) => r.read<String>('name')).toSet();
      expect(names, containsAll(<String>{
        'block_list',
        'daily_streak',
        'pause_events',
        'daily_checkins',
        'daily_usage_summary',
      }));
    });

    test('block_list insert + select round-trips', () async {
      await db.into(db.blockList).insert(BlockListCompanion.insert(
            kind: 0,
            packageName: const Value('com.instagram.android'),
            displayName: 'Instagram',
            reasonNote: const Value('Doomscrolling at night.'),
            createdAt: DateTime.utc(2026, 4, 27, 12),
            updatedAt: DateTime.utc(2026, 4, 27, 12),
          ));
      final rows = await db.select(db.blockList).get();
      expect(rows, hasLength(1));
      expect(rows.first.packageName, 'com.instagram.android');
    });

    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
    });
  });
}
```

---

## 3. Pigeon Channel Definitions (Phase 1: Skeletons Only)

Phase 1 ships **interface contracts only** — no Kotlin implementations. The codegen produces:
- Dart abstract classes that future Dart code calls.
- Kotlin abstract classes that future Phase 3/4/5 Kotlin code implements.
- Throwing stubs in `MainActivity.kt` so `flutter analyze` and `flutter build` succeed.

### `pigeons/usage_api.dart`

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/platform/usage_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.nottodo.not_to_do_list.platform',
  ),
  dartPackageName: 'not_to_do_list',
))
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
  /// Returns daily-bucketed per-package foreground time over [startEpochMs, endEpochMs].
  @async
  List<UsagePackageStat> queryRange(int startEpochMs, int endEpochMs);
}
```

### `pigeons/accessibility_api.dart`

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/platform/accessibility_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.nottodo.not_to_do_list.platform',
  ),
  dartPackageName: 'not_to_do_list',
))
@HostApi()
abstract class AccessibilityApi {
  /// True iff our specific service appears in
  /// AccessibilityManager.getEnabledAccessibilityServiceList().
  /// NOTE: this only reports state. The API explicitly does NOT expose
  /// performAction / performGlobalAction / dispatchGesture per PLAY-02.
  @async
  bool isServiceEnabled();

  /// Open Settings.ACTION_ACCESSIBILITY_SETTINGS deep-link (Phase 2 will use this).
  void openAccessibilitySettings();
}
```

### `pigeons/notification_api.dart`

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/platform/notification_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.nottodo.not_to_do_list.platform',
  ),
  dartPackageName: 'not_to_do_list',
))
@HostApi()
abstract class NotificationApi {
  /// Phase 5 will implement. Schedules a daily reminder at the next occurrence of
  /// [hour]:[minute] in the device's home timezone via setExactAndAllowWhileIdle.
  @async
  void scheduleDailyReminder(int hour, int minute);

  @async
  void cancelDailyReminder();
}
```

### Codegen command

Pigeon 26.x reads `@ConfigurePigeon(PigeonOptions(...))` from each input file rather than taking CLI flags. [VERIFIED: pigeon 26.3.4 docs] Run once per input file (or write a tiny shell script):

```bash
flutter pub get
dart run pigeon --input pigeons/usage_api.dart
dart run pigeon --input pigeons/accessibility_api.dart
dart run pigeon --input pigeons/notification_api.dart
```

Recommended: commit a `tool/pigeon.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
for f in pigeons/*.dart; do
  echo "Generating $f..."
  dart run pigeon --input "$f"
done
echo "Done. Run 'dart format lib/platform/' to format generated Dart."
```

### Outputs

| Source | Output |
|--------|--------|
| `pigeons/usage_api.dart` | `lib/platform/usage_api.g.dart` + `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt` |
| `pigeons/accessibility_api.dart` | `lib/platform/accessibility_api.g.dart` + `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApi.g.kt` |
| `pigeons/notification_api.dart` | `lib/platform/notification_api.g.dart` + `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApi.g.kt` |

### `MainActivity.kt` — Phase 1 stub registration

`android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt`:

```kotlin
package com.nottodo.not_to_do_list

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.nottodo.not_to_do_list.platform.UsageApi
import com.nottodo.not_to_do_list.platform.AccessibilityApi
import com.nottodo.not_to_do_list.platform.NotificationApi
import com.nottodo.not_to_do_list.platform.UsagePackageStat

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
                callback(Result.success(false)) // safe stub: "off" until Phase 4 implements it
            }
            override fun openAccessibilitySettings() {
                // no-op stub; Phase 2 implements
            }
        })

        NotificationApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : NotificationApi {
            override fun scheduleDailyReminder(hour: Long, minute: Long, callback: (Result<Unit>) -> Unit) {
                callback(Result.failure(NotImplementedError("NotificationApi: implemented in Phase 5")))
            }
            override fun cancelDailyReminder(callback: (Result<Unit>) -> Unit) {
                callback(Result.success(Unit))
            }
        })
    }
}
```

**Confidence:** HIGH on Pigeon API surface (verified pub.dev 26.3.4 + ConfigurePigeon docs). The exact generated method signatures (`Long` vs `Int` for epoch-ms, callback vs suspend) depend on Pigeon 26.x conventions — the planner should run codegen first, then mirror the resulting signature exactly. Treat the stub `MainActivity.kt` above as illustrative; planner should regenerate after the actual codegen output to avoid signature drift.

---

## 4. AndroidManifest Skeleton

`android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">

    <!-- ===== Permissions ===== -->

    <!-- Screen-time data source (Phase 3). Special permission, granted in Settings. -->
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
                     tools:ignore="ProtectedPermissions" />

    <!-- AccessibilityService binding (Phase 4). Granted in Settings. -->
    <uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE"
                     tools:ignore="ProtectedPermissions" />

    <!-- Daily reminder (Phase 5) and runtime prompt on Android 13+. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Re-arm daily reminder after reboot (Phase 5, NOTF-05). -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <!-- User-perceived precise time for daily reminder (Phase 5).
         Use SCHEDULE_EXACT_ALARM (user prompt), NOT USE_EXACT_ALARM (alarm/calendar class). -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />

    <!-- Foreground service that keeps the AccessibilityService in the Active bucket (Phase 4, REL-01). -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

    <!-- Battery-optimization exemption prompt (Phase 2, ONBD-01 step 4). -->
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

    <!--
        DELIBERATELY NOT DECLARED — verified by §10 grep checks:
        - SYSTEM_ALERT_WINDOW           (PLAY-05: pause UI is FlutterActivity, not overlay)
        - QUERY_ALL_PACKAGES            (PLAY-04: <queries> + LAUNCHER intent filter is sufficient)
        - USE_EXACT_ALARM               (alarm/calendar-class only; we use SCHEDULE_EXACT_ALARM)
    -->

    <!-- ===== Package visibility (PLAY-04, Android 11+) =====
         Required for the app picker (Phase 2, LIST-01) to enumerate launchable apps
         without QUERY_ALL_PACKAGES.
    -->
    <queries>
        <intent>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent>
    </queries>

    <application
        android:label="Not To-Do List"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:fullBackupContent="false"
        android:dataExtractionRules="@xml/data_extraction_rules"
        tools:replace="android:allowBackup">

        <!-- Main entry: empty home screen in Phase 1; full UI in Phase 2+. -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!--
            PauseActivity (Phase 4 implementation). Declared in Phase 1 so the manifest is
            structurally complete; the Kotlin class can be a no-op stub that finish()es.
            singleInstance + excludeFromRecents required so each blocked-app launch starts a
            fresh PauseActivity that doesn't appear in the Recents list (PAUS-01, PAUS-08).
        -->
        <activity
            android:name=".PauseActivity"
            android:exported="false"
            android:launchMode="singleInstance"
            android:excludeFromRecents="true"
            android:taskAffinity=""
            android:showOnLockScreen="true"
            android:theme="@style/LaunchTheme" />

        <!--
            STUB ONLY (PLAY-01, PLAY-03). The Kotlin service body is implemented in Phase 4.
            The manifest entry must already be policy-correct in Phase 1 because the
            <meta-data> XML it points to is the literal source of the declaration form copy
            and is what reviewers grep.

            isAccessibilityTool is set on the SERVICE config XML, not here.
            permission="android.permission.BIND_ACCESSIBILITY_SERVICE" is mandatory.
        -->
        <service
            android:name=".service.NotToDoAccessibilityService"
            android:exported="false"
            android:label="@string/a11y_service_label"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/notTodo_a11y_config" />
        </service>

        <!-- Flutter standard meta-data (auto-inserted by `flutter create`; preserve it). -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### Required string resource

`android/app/src/main/res/values/strings.xml`:
```xml
<resources>
    <string name="app_name">Not To-Do List</string>
    <string name="a11y_service_label">Not To-Do List</string>
    <string name="a11y_service_description">Reads the foreground app\'s package name and shows your reflection screen when you open an app on your Not-To-Do list. Never automates clicks, gestures, or any UI action on your behalf.</string>
</resources>
```
The description string is referenced by the a11y config XML (§5).

### Required `data_extraction_rules.xml`

`android/app/src/main/res/xml/data_extraction_rules.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <!-- Privacy: NO data is included in cloud or device-to-device transfers. -->
    <cloud-backup>
        <exclude domain="root" />
        <exclude domain="file" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="root" />
        <exclude domain="file" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
    </device-transfer>
</data-extraction-rules>
```
[CITED: Android docs — required when targeting Android 12+ to be explicit about Auto Backup; aligns with `allowBackup="false"`.]

**Confidence:** HIGH on the manifest content. The PauseActivity attribute `android:showOnLockScreen` is the modern declarative form; Phase 4's Kotlin code will additionally call `setShowWhenLocked(true)` + `setTurnScreenOn(true)` per PAUS-08 — but the manifest attribute is sufficient for Phase 1's declaration-completeness goal.

---

## 5. `accessibilityservice/notTodo_a11y_config.xml`

`android/app/src/main/res/xml/notTodo_a11y_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!--
    Phase 1 configuration. Policy-correct attributes only. Phase 4 implements the
    matching Kotlin service body (which MUST honor PLAY-02: never call performAction,
    performGlobalAction, or dispatchGesture).

    EXPLICITLY OMITTED (do NOT add):
      - canPerformGestures      → would imply autonomous action (PLAY-02 violation)
      - canRetrieveWindowContent → would imply reading screen text (privacy red flag)
      - flagRequestFilterKeyEvents → would imply intercepting keystrokes
-->
<accessibility-service
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:notificationTimeout="100"
    android:isAccessibilityTool="false"
    android:accessibilityFlags="flagDefault"
    android:description="@string/a11y_service_description" />
```

| Attribute | Value | Why |
|-----------|-------|-----|
| `accessibilityEventTypes` | `typeWindowStateChanged` (single, no other types) | PLAY-03; subscribing to `typeAllMask` is an automatic Play review red flag |
| `accessibilityFeedbackType` | `feedbackGeneric` | Required attribute; "generic" = "we provide no audio/haptic feedback to the user" |
| `notificationTimeout` | `100` | Standard 100ms debounce inside the system; further app-side debouncing happens in the Phase 4 Kotlin code (800ms per ARCHITECTURE.md) |
| `isAccessibilityTool` | `false` | PLAY-01; we are NOT assistive tech |
| `accessibilityFlags` | `flagDefault` only | Setting `flagRequestFilterKeyEvents` or any other privileged flag is a red flag |
| `description` | `@string/a11y_service_description` | Plain-language description shown in Settings. Mirror of `docs/play-declaration.md` mechanical text |

[VERIFIED: developer.android.com/reference/android/accessibilityservice/AccessibilityServiceInfo — all attribute names confirmed]

---

## 6. Riverpod Swappable AccessibilityService Provider Abstraction

This is REL-05's load-bearing artifact. Phase 1 ships **the abstraction and the Riverpod selector only** — both concrete implementations are stubs that throw `UnimplementedError`. Phase 4 fills `AccessibilityBlockedAppDetector`; the kill-switch fallback `UsageStatsPollingBlockedAppDetector` is filled if Play rejects the service.

### `lib/domain/blocked_app_detector.dart`

```dart
/// The single seam between "what the rest of the app needs to know about
/// blocked-app launches" and "how Android tells us about them."
///
/// REL-05 / PLAY-02: This interface deliberately exposes ONLY the read-side
/// (a stream of detected events). It does not expose performAction / dispatchGesture
/// / performGlobalAction. The Phase 4 a11y implementation honors that promise; the
/// fallback polling implementation cannot violate it because UsageStatsManager has no
/// such APIs in the first place.
abstract class BlockedAppDetector {
  /// Cold-start: load the in-memory block list from the database.
  /// Called by the Riverpod provider on first read.
  Future<void> initialize(Set<String> blockedPackageNames);

  /// Notify the detector that the user-defined block list changed.
  /// (Phase 4: a11y impl forwards this via LocalBroadcast to the native service.)
  Future<void> updateBlockList(Set<String> blockedPackageNames);

  /// Stream of blocked-app launches. Emits a `BlockedAppDetection` for every
  /// in-list foregrounding event. May be empty for hours at a time.
  Stream<BlockedAppDetection> get detections;

  /// Whether the detector is currently armed (a11y permission granted, polling running, etc.).
  /// The `health-check` UI in Phase 2 reads this.
  Future<bool> get isHealthy;

  /// Free resources (called when Riverpod tears down the provider).
  Future<void> dispose();
}

class BlockedAppDetection {
  const BlockedAppDetection({
    required this.packageName,
    required this.detectedAt,
    required this.source,
  });
  final String packageName;
  final DateTime detectedAt;
  final BlockedAppDetectionSource source;
}

enum BlockedAppDetectionSource {
  /// Fired by AccessibilityService TYPE_WINDOW_STATE_CHANGED (Phase 4).
  accessibilityService,

  /// Fired by UsageStatsManager polling (kill-switch fallback).
  usageStatsPolling,
}
```

### Concrete implementations — Phase 1 stubs only

`lib/data/detectors/accessibility_blocked_app_detector.dart`:
```dart
import 'package:not_to_do_list/domain/blocked_app_detector.dart';

/// Phase 4 fills the body. Phase 1 ships an UnimplementedError stub so the
/// provider switch (below) compiles and `flutter analyze` passes.
class AccessibilityBlockedAppDetector implements BlockedAppDetector {
  @override
  Future<void> initialize(Set<String> blockedPackageNames) async {
    throw UnimplementedError('Phase 4 will implement.');
  }

  @override
  Future<void> updateBlockList(Set<String> blockedPackageNames) async {
    throw UnimplementedError('Phase 4 will implement.');
  }

  @override
  Stream<BlockedAppDetection> get detections =>
      const Stream<BlockedAppDetection>.empty();

  @override
  Future<bool> get isHealthy async => false;

  @override
  Future<void> dispose() async {}
}
```

`lib/data/detectors/usage_stats_polling_blocked_app_detector.dart`:
```dart
import 'package:not_to_do_list/domain/blocked_app_detector.dart';

/// Kill-switch fallback per STACK.md "Stack patterns by variant: if Play review rejects".
/// Phase 1 ships the stub; this implementation lights up only if Play rejects PLAY-08.
class UsageStatsPollingBlockedAppDetector implements BlockedAppDetector {
  @override
  Future<void> initialize(Set<String> blockedPackageNames) async {
    throw UnimplementedError('Activated only as kill-switch fallback.');
  }

  @override
  Future<void> updateBlockList(Set<String> blockedPackageNames) async {
    throw UnimplementedError('Activated only as kill-switch fallback.');
  }

  @override
  Stream<BlockedAppDetection> get detections =>
      const Stream<BlockedAppDetection>.empty();

  @override
  Future<bool> get isHealthy async => false;

  @override
  Future<void> dispose() async {}
}
```

### Riverpod selector

`lib/domain/providers/blocked_app_detector_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:not_to_do_list/domain/blocked_app_detector.dart';
import 'package:not_to_do_list/data/detectors/accessibility_blocked_app_detector.dart';
import 'package:not_to_do_list/data/detectors/usage_stats_polling_blocked_app_detector.dart';

part 'blocked_app_detector_provider.g.dart';

/// Compile-time-or-shared_preferences flag that decides which detector ships.
/// In Phase 1 this is a constant `true`; in Phase 6 we may flip it to a settings toggle.
@riverpod
bool useAccessibilityService(UseAccessibilityServiceRef ref) => true;

/// The single Riverpod entry point. The rest of the app depends ONLY on this.
/// Swapping the implementation requires changing one line in this file.
@riverpod
BlockedAppDetector blockedAppDetector(BlockedAppDetectorRef ref) {
  final useA11y = ref.watch(useAccessibilityServiceProvider);
  if (useA11y) {
    return AccessibilityBlockedAppDetector();
  } else {
    return UsageStatsPollingBlockedAppDetector();
  }
}
```

This exact pattern — a single provider that reads a flag and instantiates one of two implementations — is REL-05's contract. Any Phase 4+ code that wants to know "did the user just open a blocked app?" reads `ref.watch(blockedAppDetectorProvider).detections` and is agnostic to whether the source is a11y events or UsageStats polling.

[CITED: STACK.md "Risk mitigation: build a fallback from day one"; ROADMAP.md Phase 1 success criterion #4; REQUIREMENTS.md REL-05.]

---

## 7. Folder Structure

The exact tree to create. `*` indicates files generated by codegen — should not be hand-edited.

```
not-to-do-list/
├── CLAUDE.md                                    (already exists)
├── .planning/                                   (already exists)
├── README.md                                    (optional in Phase 1)
├── pubspec.yaml
├── analysis_options.yaml                        (extends very_good_analysis)
│
├── pigeons/                                     (NEW — input files for Pigeon codegen)
│   ├── usage_api.dart
│   ├── accessibility_api.dart
│   └── notification_api.dart
│
├── docs/                                        (NEW — Play Console source-of-truth)
│   ├── play-declaration.md
│   └── data-safety.md
│
├── tool/
│   └── pigeon.sh                                (helper script for codegen)
│
├── lib/
│   ├── main.dart                                (entrypoint; ProviderScope + MaterialApp)
│   ├── app.dart                                 (MaterialApp + GoRouter wiring)
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart                   (Light + Dark ThemeData; ThemeMode.system)
│   │   └── router/
│   │       └── app_router.dart                  (GoRouter with single '/' route to HomeScreen)
│   │
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   ├── app_database.g.dart              (* generated)
│   │   │   └── tables/
│   │   │       ├── block_list_table.dart
│   │   │       ├── daily_streak_table.dart
│   │   │       ├── pause_events_table.dart
│   │   │       ├── daily_checkins_table.dart
│   │   │       └── daily_usage_summary_table.dart
│   │   ├── detectors/
│   │   │   ├── accessibility_blocked_app_detector.dart      (Phase 1 stub)
│   │   │   └── usage_stats_polling_blocked_app_detector.dart (Phase 1 stub)
│   │   └── repositories/                        (placeholder dir; Phase 2 fills it)
│   │       └── .gitkeep
│   │
│   ├── domain/
│   │   ├── blocked_app_detector.dart            (REL-05 interface)
│   │   ├── entities/                            (placeholder; Phase 2 fills)
│   │   │   └── .gitkeep
│   │   ├── use_cases/                           (placeholder; Phase 2 fills)
│   │   │   └── .gitkeep
│   │   └── providers/
│   │       ├── blocked_app_detector_provider.dart
│   │       ├── blocked_app_detector_provider.g.dart    (* generated)
│   │       └── database_provider.dart           (singleton AppDatabase)
│   │
│   ├── platform/                                (* all generated by Pigeon)
│   │   ├── usage_api.g.dart
│   │   ├── accessibility_api.g.dart
│   │   └── notification_api.g.dart
│   │
│   └── features/
│       ├── home/
│       │   ├── pages/
│       │   │   └── home_screen.dart             (empty list scaffold)
│       │   └── controllers/
│       │       └── .gitkeep                     (Phase 2 fills)
│       └── onboarding/                          (placeholder; Phase 2 fills)
│           └── .gitkeep
│
├── test/
│   ├── data/
│   │   └── database/
│   │       └── app_database_test.dart           (round-trip test)
│   └── domain/
│       └── providers/
│           └── blocked_app_detector_provider_test.dart  (verifies switch behavior)
│
└── android/
    ├── app/
    │   ├── build.gradle.kts                     (compileSdk/min/target = 36/29/36, Java 17)
    │   └── src/
    │       └── main/
    │           ├── AndroidManifest.xml
    │           ├── kotlin/com/nottodo/not_to_do_list/
    │           │   ├── MainActivity.kt          (Pigeon stub registrations)
    │           │   ├── PauseActivity.kt         (FlutterActivity stub for Phase 4)
    │           │   ├── service/
    │           │   │   └── NotToDoAccessibilityService.kt   (Kotlin stub: empty onAccessibilityEvent override; Phase 4 fills body)
    │           │   └── platform/
    │           │       ├── UsageApi.g.kt        (* generated)
    │           │       ├── AccessibilityApi.g.kt(* generated)
    │           │       └── NotificationApi.g.kt (* generated)
    │           └── res/
    │               ├── values/
    │               │   └── strings.xml
    │               └── xml/
    │                   ├── notTodo_a11y_config.xml
    │                   └── data_extraction_rules.xml
    └── settings.gradle.kts                      (Flutter template default)
```

**Why placeholder dirs use `.gitkeep`:** Phase 2's planner can target `lib/features/onboarding/` and `lib/data/repositories/` as known-good destinations without re-discovering the layout.

**Why `lib/platform/` exists separately from `lib/data/`:** Pigeon outputs are pure-generated FFI shims; mixing them with hand-written repository code makes regeneration a regrep nightmare.

**Why `pigeons/` is at the project root, not inside `lib/`:** Pigeon explicitly requires input files to live OUTSIDE `lib/` because they include `@ConfigurePigeon(...)` annotations that should not ship in the runtime bundle. [VERIFIED: pub.dev/packages/pigeon — "Create a '.dart' file outside the 'lib' directory"]

---

## 8. `docs/play-declaration.md` Content

This is the literal mechanical text that lands in `docs/play-declaration.md` and is the single source of truth for: (a) the Play Console Permission Declaration form, (b) the `<string name="a11y_service_description">` resource, (c) the in-app prominent disclosure screen (Phase 2, PLAY-06), (d) the Privacy Policy section on accessibility use (Phase 6).

> **Drafting note for the planner:** Copy this content verbatim into `docs/play-declaration.md`. The Phase 1 task is to commit this file, NOT to edit the prose. Edits to this file later require a new GSD discuss → research → plan cycle because the manifest, in-app copy, and Play Console submission all key off it.

```markdown
# Play Console Permission Declaration — Not To-Do List

**Source of truth for:**
- Google Play Console "Use of the AccessibilityService API" Permission Declaration form
- `android/app/src/main/res/xml/notTodo_a11y_config.xml` `android:description`
- `android/app/src/main/res/values/strings.xml` `a11y_service_description`
- In-app Accessibility Service prominent-disclosure screen (Phase 2, PLAY-06)
- Privacy Policy → Accessibility Use section (Phase 6)
- Data Safety form cross-reference (`docs/data-safety.md`)

**Last updated:** 2026-04-27 (Phase 1 commit)
**Policy version this matches:** Use of the AccessibilityService API, post Jan-28-2026 + Apr-15-2026 Play Console policy.

---

## 1. App description and core function

Not To-Do List helps adults stick to self-defined avoidance goals — apps and habits they have explicitly chosen to use less or not at all. The user creates their own "Not-To-Do List" and asks the app to interrupt those launches with a brief reflection screen ("Do you really need it now?") with a cooldown timer (1 / 3 / 5 / 10 minutes).

The app is Android-only, account-free, fully on-device, free, and contains no telemetry, no analytics, no advertising, and no backend.

## 2. Why Not To-Do List uses the AccessibilityService API

Not To-Do List uses the AccessibilityService API for one purpose only: to detect when the user has foregrounded an app on their own Not-To-Do List, so the app can immediately display its reflection screen.

**What the service does, mechanically:**
- Listens only to `AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED` events.
- For each such event, reads `event.getPackageName()`.
- If the package name is in the user's Not-To-Do List (a list the user explicitly created), the service launches the app's own `PauseActivity` (a standard Android Activity) which displays the reflection screen.
- If the package name is not in the list, the event is ignored and discarded.

**What the service NEVER does:**
- Never calls `performAction()`.
- Never calls `performGlobalAction()`.
- Never calls `dispatchGesture()`.
- Never reads on-screen text content; the service does not set `canRetrieveWindowContent`.
- Never intercepts key events; the service does not set `flagRequestFilterKeyEvents`.
- Never performs gestures; the service does not set `canPerformGestures`.
- Never automates UI on the user's behalf, in any form.
- Never sends any data off the device. The package name is read, matched in memory, and discarded; nothing is logged, stored long-term, transmitted, or shared.
- Never operates as an "accessibility tool"; `isAccessibilityTool="false"` is set in the service configuration. We are not assistive technology.

The user remains in full control at every moment. They can dismiss the reflection screen at any time, choose "Use anyway" to bypass it, or wait for the cooldown to expire. They can disable the AccessibilityService from the system Settings at any time; the app continues to function (without launch interception) using only their daily self-report check-ins.

## 3. Why no narrower API works

Android's `UsageStatsManager` provides historical aggregate usage data (per-app foreground time bucketed by day or hour), but does NOT provide a real-time signal when an app foregrounds. Its data lags by a minimum of approximately 2.5 seconds and aggregates by interval. By the time `UsageStatsManager` reports that Instagram has been foregrounded, the user has already started scrolling — the entire reflective intervention has been bypassed.

The deprecated `getRunningTasks()` API was restricted in API level 21 and now only returns the caller's own tasks; it cannot be used to detect another app's foregrounding.

The AccessibilityService API is the only Android API that delivers a synchronous, sub-second signal when the foreground window changes, which is mandatory for the reflection-screen feature to be useful at all.

## 4. Disclosure and consent

The user is shown a dedicated full-screen "Accessibility Service" disclosure inside the app, separate from the Privacy Policy and any Terms of Service, before the system Settings deep-link. The disclosure:

- Describes in plain language exactly what data is accessed (the package name of the foreground app, only when a window-state-changed event fires).
- Describes what the service does (compares the package name to the user's Not-To-Do List; shows the reflection screen if it matches).
- Describes what the service never does (the list in section 2 above).
- States that no data leaves the device.
- Requires an explicit user tap ("I understand — open Settings") to proceed to the system Settings page where the user must manually enable the service.

The user can revoke the AccessibilityService permission at any time via the system Settings. The app monitors the enabled-services list on every foreground and shows an in-app banner ("Tracking offline — fix") when the service is no longer enabled.

## 5. Data Safety form alignment

This declaration is consistent with `docs/data-safety.md` and the Play Console Data Safety form:
- Data collected: NONE.
- Data shared: NONE.
- Data is processed: ONLY ON THE USER'S DEVICE.
- Encryption in transit: NOT APPLICABLE (no transmission).
- Data deletion: USER CAN RESET ALL DATA FROM IN-APP SETTINGS.

The Data Safety form is verifiable against the dependency tree: the project ships no Firebase, no FCM, no Crashlytics, no Google Analytics, no Amplitude, no Mixpanel, no Segment, no Sentry, and no other third-party SDK that transmits data. See the dependency-tree audit in `docs/data-safety.md`.

## 6. Manifest and configuration cross-reference

| Claim above | Verified by |
|-------------|-------------|
| `isAccessibilityTool="false"` | `android/app/src/main/res/xml/notTodo_a11y_config.xml` |
| `accessibilityEventTypes="typeWindowStateChanged"` only | same file |
| `canPerformGestures` not set | same file (attribute is absent) |
| `canRetrieveWindowContent` not set | same file (attribute is absent) |
| `flagRequestFilterKeyEvents` not set | same file (attribute is absent inside `accessibilityFlags`) |
| Service never calls `performAction` / `performGlobalAction` / `dispatchGesture` | source code in `android/app/src/main/kotlin/.../service/NotToDoAccessibilityService.kt` (Phase 4) |
| No `SYSTEM_ALERT_WINDOW` | `AndroidManifest.xml` (permission absent) |
| No `QUERY_ALL_PACKAGES` | `AndroidManifest.xml` uses `<queries>` + LAUNCHER intent filter instead |
| No telemetry / FCM / analytics | `pubspec.yaml` dependency tree |
```

---

## 9. `docs/data-safety.md` Content

```markdown
# Play Console Data Safety Form — Not To-Do List

**Source of truth for:** the Play Console Data Safety form (PLAY-09).
**Last updated:** 2026-04-27 (Phase 1 commit)

---

## Section 1. Data collection and sharing

| Question | Answer |
|----------|--------|
| Does your app collect or share any of the required user data types? | **No.** |
| Is all of the user data collected by your app encrypted in transit? | **N/A** — no data is collected or transmitted. |
| Do you provide a way for users to request that their data is deleted? | **Yes** — Settings → "Reset all data" deletes every entry, streak day, pause event, and check-in (SETT-02, Phase 6). |

## Section 2. Data types — declaration

For every Play Data Safety data category, the answer is **NOT COLLECTED**:

- Personal info: NOT COLLECTED
- Financial info: NOT COLLECTED
- Health and fitness: NOT COLLECTED
- Messages: NOT COLLECTED
- Photos and videos: NOT COLLECTED
- Audio files: NOT COLLECTED
- Files and docs: NOT COLLECTED
- Calendar: NOT COLLECTED
- Contacts: NOT COLLECTED
- App activity: NOT COLLECTED *(see note below)*
- Web browsing: NOT COLLECTED
- App info and performance: NOT COLLECTED
- Device or other identifiers: NOT COLLECTED

**Note on "App activity":** The user's Not-To-Do List, screen-time aggregates, daily check-ins, streak history, and pause-event log are stored exclusively in a SQLite database on the user's device. They are never transmitted off-device. Per the Play Data Safety policy, "data that stays on the user's device" is not "collected" for the purposes of this form.

## Section 3. Verification — actual code matches declaration

The Data Safety form's "no telemetry" claim is verifiable against the dependency tree.

**Dependency-tree audit command:**
```bash
flutter pub deps | grep -iE "firebase|fcm|analytics|crashlytics|amplitude|mixpanel|segment|sentry|datadog|appsflyer|adjust"
```
Expected output: **(empty)**.

**Network-permission audit:** the `INTERNET` permission is **not** declared in `AndroidManifest.xml`. The app cannot make any network request. (If a future phase adds a feature that requires network — e.g., M2 Supabase sync — this section MUST be updated and the Data Safety form re-submitted.)

**Build artifact audit:** the release APK can be inspected with `apkanalyzer` to verify no Google Play Services, Firebase, or analytics libraries are present (Phase 6 verification).

## Section 4. User controls

| Control | Implementation Phase |
|---------|----------------------|
| View all data the app stores | Daily / Weekly / Monthly dashboard (Phase 3) |
| Export all data (CSV + JSON) | SETT-01 (Phase 6) |
| Delete all data | SETT-02 (Phase 6) |
| Disable any single permission at any time | All four permissions are user-revocable from system Settings; app degrades gracefully (REL-02) |

## Section 5. Cross-reference

This document is consistent with `docs/play-declaration.md` (Section 5: Data Safety form alignment).

If any future change requires telemetry, FCM, analytics, or any off-device transmission, this document and the Play Console Data Safety form MUST be updated in the same commit as the dependency-tree change.
```

---

## 10. Verification Approach

The phase exits cleanly when ALL of the following commands produce the expected output. Each is a standalone test the planner should map to a verification task.

### V1. `flutter analyze` clean
```bash
flutter analyze
```
**Expected:** `No issues found!`

### V2. `flutter test` passes (Drift round-trip + provider switch tests)
```bash
flutter test
```
**Expected:** `All tests passed!` Specifically:
- `test/data/database/app_database_test.dart` — schema v1 round-trip.
- `test/domain/providers/blocked_app_detector_provider_test.dart` — toggling `useAccessibilityServiceProvider` returns the right concrete type.

### V3. `flutter build apk --debug` succeeds
```bash
flutter build apk --debug
```
**Expected:** Built `build/app/outputs/flutter-apk/app-debug.apk`. (No release build required in Phase 1; Phase 6 wires release signing.)

### V4. Drift schema migrations apply cleanly
Covered by V2 (the round-trip test calls `m.createAll()` via `setUp`). Additionally, run a single sanity command to ensure codegen output is current:
```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code lib/
```
**Expected:** Exit code 0 — generated files match committed sources.

### V5. Manifest grep — `QUERY_ALL_PACKAGES` MUST be absent
```bash
! grep -q "QUERY_ALL_PACKAGES" android/app/src/main/AndroidManifest.xml
```
**Expected:** Exit code 0 (the `!` inverts a successful grep into a failure; if `QUERY_ALL_PACKAGES` IS present, this command exits non-zero).

### V6. Manifest grep — `SYSTEM_ALERT_WINDOW` MUST be absent
```bash
! grep -q "SYSTEM_ALERT_WINDOW" android/app/src/main/AndroidManifest.xml
```
**Expected:** Exit code 0.

### V7. Manifest grep — `USE_EXACT_ALARM` MUST be absent (we use `SCHEDULE_EXACT_ALARM`)
```bash
! grep -q "USE_EXACT_ALARM" android/app/src/main/AndroidManifest.xml
```
**Expected:** Exit code 0.

### V8. A11y config grep — `isAccessibilityTool="false"` MUST be present
```bash
grep -q 'isAccessibilityTool="false"' android/app/src/main/res/xml/notTodo_a11y_config.xml
```
**Expected:** Exit code 0.

### V9. A11y config grep — privileged flags MUST be absent
```bash
! grep -qE "canPerformGestures|canRetrieveWindowContent|flagRequestFilterKeyEvents" android/app/src/main/res/xml/notTodo_a11y_config.xml
```
**Expected:** Exit code 0. (None of these tokens may appear.)

### V10. Dependency tree audit — no telemetry SDKs
```bash
flutter pub deps | grep -iE "firebase|fcm|analytics|crashlytics|amplitude|mixpanel|segment|sentry|datadog|appsflyer|adjust" || echo "OK: no telemetry deps"
```
**Expected:** `OK: no telemetry deps`.

### V11. Manifest grep — `<queries>` + LAUNCHER intent filter MUST be present
```bash
grep -q "<queries>" android/app/src/main/AndroidManifest.xml \
  && grep -A2 "<queries>" android/app/src/main/AndroidManifest.xml | grep -q "android.intent.category.LAUNCHER"
```
**Expected:** Exit code 0.

### V12. Manifest grep — `allowBackup="false"` MUST be present
```bash
grep -q 'android:allowBackup="false"' android/app/src/main/AndroidManifest.xml
```
**Expected:** Exit code 0.

### V13. Docs presence — declaration files MUST exist and be non-empty
```bash
test -s docs/play-declaration.md && test -s docs/data-safety.md
```
**Expected:** Exit code 0.

### V14. Source-tree presence — required files MUST exist
```bash
for f in \
  pigeons/usage_api.dart \
  pigeons/accessibility_api.dart \
  pigeons/notification_api.dart \
  lib/data/database/app_database.dart \
  lib/domain/blocked_app_detector.dart \
  lib/domain/providers/blocked_app_detector_provider.dart \
  android/app/src/main/AndroidManifest.xml \
  android/app/src/main/res/xml/notTodo_a11y_config.xml; do
  test -f "$f" || { echo "MISSING: $f"; exit 1; }
done
echo "OK: all required files present"
```
**Expected:** `OK: all required files present`.

---

## 11. Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK 3.41.x | All build/test/analyze commands | ✗ | — | None — install required |
| Dart SDK ^3.5.0 | bundled with Flutter | ✗ | — | Comes with Flutter |
| JDK 17 | Gradle, AGP 8.11.1+ | ✗ | `/usr/bin/java` reports "Unable to locate a Java Runtime" | None — install Temurin/Zulu/Oracle JDK 17 |
| Android SDK platform-36 + build-tools-36 | `flutter build apk` | ✗ | ANDROID_HOME unset | None — install via Android Studio or `cmdline-tools` |
| Android platform-tools (`adb`) | Device-side verification (deferred to Phase 4) | ✗ | — | Not needed for Phase 1 verification commands V1–V14 (all are static-analysis or unit-test) |
| Gradle | Bundled with Flutter project (gradle wrapper) | ✓ (after `flutter create` runs) | Wrapper-pinned by Flutter 3.41 template | — |
| Android Studio (recommended IDE) | Native debugging (Phase 4+) | ✗ | — | VS Code is installed; sufficient for Phase 1 |

**Missing dependencies with no fallback (BLOCKERS for Phase 1):**
- Flutter SDK 3.41.x
- JDK 17
- Android SDK platform-36 + build-tools-36

**Missing dependencies with fallback:**
- Android Studio is recommended but not strictly required for Phase 1; VS Code + the Dart and Flutter extensions are sufficient. Phase 4 will require Android Studio for AccessibilityService debugging.

**Implication for the planner:** Wave 0 of the plan MUST include a "Prepare developer environment" task that:
1. Installs Flutter SDK 3.41.x (e.g., via `fvm` or direct git clone of the stable channel).
2. Installs JDK 17 (Homebrew is available — `brew install --cask temurin@17`).
3. Installs Android SDK command-line tools, then accepts licenses, then installs `platforms;android-36`, `build-tools;36.0.0`, `platform-tools`.
4. Sets `JAVA_HOME` and `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) shell exports.
5. Runs `flutter doctor` and confirms zero red Xs in the Android section.

Without this Wave 0 step, none of the §10 verification commands can be executed and the phase cannot exit.

---

## Validation Architecture

(Section 12 — heading normalized to satisfy GSD validation-strategy detector grep.)

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter SDK) + `test` (^1.x via flutter_test) |
| Config file | `test/` directory at project root; no separate config file |
| Quick run command | `flutter test test/data/database/app_database_test.dart -r expanded` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PLAY-01 | A11y config sets `isAccessibilityTool="false"` | static (manifest grep) | `grep -q 'isAccessibilityTool="false"' android/app/src/main/res/xml/notTodo_a11y_config.xml` | ❌ Wave 0 — XML created in plan |
| PLAY-02 | Service abstraction surface excludes performAction/dispatchGesture/performGlobalAction | static (Dart analyze) — interface has no such methods | `flutter analyze` + visual inspection of `BlockedAppDetector` | ❌ Wave 0 — interface created in plan |
| PLAY-03 | Event types scoped to `typeWindowStateChanged` only | static (XML grep) | `grep -q 'accessibilityEventTypes="typeWindowStateChanged"' android/app/src/main/res/xml/notTodo_a11y_config.xml && ! grep -qE 'typeAllMask\|typeViewClicked\|typeViewFocused' android/app/src/main/res/xml/notTodo_a11y_config.xml` | ❌ Wave 0 |
| PLAY-04 | `<queries>` + LAUNCHER intent filter present, `QUERY_ALL_PACKAGES` absent | static (manifest grep) | V5 + V11 above | ❌ Wave 0 |
| PLAY-05 | `SYSTEM_ALERT_WINDOW` absent; PauseActivity declared as FlutterActivity | static (manifest grep) + visual inspection | V6 above + `grep -q '<activity\\s\\+android:name=".PauseActivity"' android/app/src/main/AndroidManifest.xml` | ❌ Wave 0 |
| PLAY-07 | `docs/play-declaration.md` exists and is non-empty | static (file presence) | `test -s docs/play-declaration.md` | ❌ Wave 0 |
| PLAY-09 | No telemetry/FCM/analytics SDKs in dep tree; `docs/data-safety.md` exists | static (deps grep + file presence) | V10 + `test -s docs/data-safety.md` | ❌ Wave 0 |
| REL-05 | `BlockedAppDetector` interface + Riverpod selector exists; switching the flag changes the concrete type | unit | `flutter test test/domain/providers/blocked_app_detector_provider_test.dart` | ❌ Wave 0 — file created in plan |
| SETT-03 | No data leaves device — verified via no INTERNET permission and no network SDKs | static (manifest grep) | `! grep -q 'android.permission.INTERNET' android/app/src/main/AndroidManifest.xml && [V10]` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter analyze && flutter test` (~30s).
- **Per wave merge:** Full suite + all 14 verification commands (V1–V14) (~3 minutes).
- **Phase gate:** All 14 verification commands pass + `flutter build apk --debug` succeeds + `docs/play-declaration.md` and `docs/data-safety.md` reviewed by user.

### Wave 0 Gaps
- [ ] `test/data/database/app_database_test.dart` — covers Drift schema v1 round-trip (success criterion #1).
- [ ] `test/domain/providers/blocked_app_detector_provider_test.dart` — covers REL-05.
- [ ] `analysis_options.yaml` — extends `very_good_analysis` (or `flutter_lints`).
- [ ] Framework install: see §11. Without Flutter + JDK 17 + Android SDK, no test can run.
- [ ] `tool/pigeon.sh` — codegen helper script.

---

## 13. Architecture Patterns (Phase-1-Specific Slice of `research/ARCHITECTURE.md`)

### Pattern: Native-owned event source, Dart-owned UI state

The PauseActivity manifest entry, the AccessibilityService manifest entry, and the `BlockedAppDetector` Riverpod abstraction all encode the same architectural commitment: **the native side is the event source; the Dart side is the UI and the system of record.**

In Phase 1 this manifests as:
- The Pigeon `accessibility_api.dart` HostApi exposes `isServiceEnabled()` (read state) and `openAccessibilitySettings()` (deep-link to Settings) — but NOT `triggerPauseScreen()` or anything action-shaped. The action is the Phase 4 service itself launching `PauseActivity` via Intent extras.
- The Riverpod `blockedAppDetectorProvider` exposes a `Stream<BlockedAppDetection>` — read-only from the rest of the app's perspective.
- The Drift database has a single writer (Dart). The AccessibilityService never opens the database in Phase 4; it reads its in-memory `Set<String>` block list, refreshed via LocalBroadcast.

### Pattern: Pigeon for synchronous Dart→Native calls

All three Pigeon interfaces are `@HostApi` (Dart calls Kotlin). No `@FlutterApi` (Kotlin calls Dart) interfaces exist in Phase 1 because — per the architecture — Native→Dart pokes happen via LocalBroadcast (not EventChannel) and via Intent.startActivity (which is what triggers PauseActivity in Phase 4).

### Anti-Pattern: AccessibilityService writing directly to SQLite

This is the most important anti-pattern Phase 1 must lock out structurally. The Phase 1 `NotToDoAccessibilityService.kt` stub MUST NOT have a database connection imported or initialized. The Phase 4 implementation MUST keep this property. Verification: search the Kotlin source tree for `Drift`, `SQLDelight`, `Room`, `SQLiteOpenHelper`, or any `.db` file path in `service/` — all should be absent.

---

## 14. Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SQLite schema management | Hand-written `CREATE TABLE` strings + manual migration logic | Drift (`@DriftDatabase`, `MigrationStrategy`) | Drift catches column-name typos at compile time; auto-generates query helpers; reactive streams free. |
| Dart↔Kotlin type marshalling | `MethodChannel` with string keys + `Map<String, Any?>` | Pigeon | Type-safe at compile time; eliminates `MissingPluginException` class of bugs. |
| Riverpod-style provider DI | Service-locator singletons + manual lifecycle | `flutter_riverpod` 3.3.1 with code-gen | Compile-time safety; AsyncValue handles loading/error states cleanly; lock-in matches CLAUDE.md. |
| Persisting one-line settings (reminder time, onboarding-complete flag) | A `settings` table in Drift | `shared_preferences ^2.3.0` | Schema overkill for a flat key-value store of ≤10 settings. |
| Routing | Hand-rolled `Navigator.push` strings | `go_router ^14.x` | Standard Riverpod companion; declarative route table; deep-linking (Phase 5 NOTF-03) becomes trivial. |
| Accessibility-Settings deep-link | Hand-rolled `Intent` construction in Kotlin | (Phase 2) `app_settings` package | Maintained, OEM-aware fallbacks. (Not a Phase 1 dep — listed for the planner's future reference.) |

**Key insight:** Phase 1's biggest hand-roll temptation is to "just use `SqfliteDatabase` since it's simpler" or "just use `MethodChannel` since we only have three calls." Both temptations cost weeks downstream when the schema needs a migration or the channel argument shape changes. Lock the codegen tools in Phase 1.

---

## 15. Common Pitfalls (Phase-1-Specific Slice of `research/PITFALLS.md`)

### Pitfall A: Manifest declared but a11y config XML not policy-correct

**What goes wrong:** Developer adds the `<service>` entry but forgets the `<meta-data>` pointing to the config XML, OR the config XML has a stray `canPerformGestures="true"` from a copied-pasted Stack Overflow snippet.

**Why it happens:** Most Android tutorials show maximally-permissive a11y configs because they're written for screen-reader use cases.

**How to avoid:** Verification commands V8 and V9 catch both. Lock them into the per-task commit gate.

**Warning signs:** Play closed-track submission auto-flagged by policy bot; reviewer asks for video showing the a11y feature.

---

### Pitfall B: `flutter create` regenerates `MainActivity.kt` and wipes the Pigeon stub registrations

**What goes wrong:** A future task runs `flutter create .` again to "refresh" something, and the hand-written Pigeon registrations are overwritten.

**Why it happens:** `flutter create` is idempotent for *most* files but rewrites `MainActivity.kt` if it sees an unfamiliar shape.

**How to avoid:** Never re-run `flutter create` after Phase 1's initial scaffolding. Verification command V14 will catch the regression because the file content will lack the Pigeon imports.

**Warning signs:** `flutter analyze` suddenly complains about un-registered Pigeon APIs; runtime `MissingPluginException` for `usage_api`.

---

### Pitfall C: Drift codegen output drifts from sources without `--delete-conflicting-outputs`

**What goes wrong:** A column rename ships, but the cached `.g.dart` file has the old name, causing confusing "type 'String' is not a subtype of 'int'" runtime errors.

**Why it happens:** `build_runner` defaults to incremental builds and sometimes mis-detects what to invalidate.

**How to avoid:** Always pass `--delete-conflicting-outputs` after schema edits. Verification V4 catches stale codegen.

**Warning signs:** Tests pass locally (where someone ran codegen manually) but fail in clean checkouts.

---

### Pitfall D: Pigeon input file accidentally placed inside `lib/`

**What goes wrong:** Developer creates `lib/pigeons/usage_api.dart` instead of `pigeons/usage_api.dart`, the `@ConfigurePigeon` annotation gets shipped in the runtime bundle, the app size grows, and `flutter analyze` may complain.

**Why it happens:** Habit ("everything Dart goes in lib").

**How to avoid:** §7 folder structure is authoritative. Verification V14 requires `pigeons/` at the project root.

---

### Pitfall E: AGP/Kotlin/Gradle pin drifts from Flutter template defaults

**What goes wrong:** Developer manually pins KGP to a version that doesn't match the Flutter 3.41 template, causing cryptic "Unsupported Kotlin plugin version" errors at build time.

**Why it happens:** Reading old StackOverflow answers from 2024.

**How to avoid:** Do NOT manually edit `android/settings.gradle.kts` or `android/build.gradle.kts` plugin block. The Flutter 3.41 template owns the AGP/KGP/Gradle pins.

---

### Pitfall F: `applicationId` accidentally tied to a placeholder org

**What goes wrong:** `flutter create` was run without `--org com.nottodo`, producing `applicationId="com.example.not_to_do_list"`. This applicationId is then committed and the dev later tries to change it. Play Console upload key is bound to the applicationId — changing it after the first upload is painful.

**How to avoid:** §1 explicitly invokes `--org com.nottodo`. Verification: `grep -q 'applicationId = "com.nottodo.not_to_do_list"' android/app/build.gradle.kts`.

---

## 16. Code Examples

Cross-reference table — for each Phase 1 artifact, here's where the verbatim code lives in this doc:

| Artifact | Section in this doc |
|----------|---------------------|
| `pubspec.yaml` (Phase 1) | §1 |
| `android/app/build.gradle.kts` excerpt | §1 |
| `lib/data/database/app_database.dart` | §2 |
| All five Drift table definitions | §2 |
| Round-trip test | §2 |
| `pigeons/usage_api.dart` | §3 |
| `pigeons/accessibility_api.dart` | §3 |
| `pigeons/notification_api.dart` | §3 |
| `MainActivity.kt` Pigeon stub registrations | §3 |
| `AndroidManifest.xml` (full) | §4 |
| `data_extraction_rules.xml` | §4 |
| `strings.xml` | §4 |
| `notTodo_a11y_config.xml` (full) | §5 |
| `BlockedAppDetector` interface | §6 |
| Concrete detector stubs (a11y + UsageStats polling) | §6 |
| Riverpod `blockedAppDetectorProvider` | §6 |
| `docs/play-declaration.md` (full content) | §8 |
| `docs/data-safety.md` (full content) | §9 |
| Verification commands V1–V14 | §10 |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled MethodChannel with string keys | Pigeon-typed `@HostApi` | 2022–2024 (Pigeon graduated to flutter.dev verified publisher) | Build-time type safety; lock in for Phase 1. |
| `SYSTEM_ALERT_WINDOW` overlay for pause UIs | Activity-launch from AccessibilityService | Android 12+ overlay restrictions (Dec 2021) and Play policy tightening (Jan 2026) | Architectural decision in `research/ARCHITECTURE.md` overrides PROJECT.md's original "overlay" framing. |
| Hive / Isar / sqflite for Flutter local DB | Drift 2.32+ | Isar abandonment (2024–2025) | Drift is the only major Flutter DB still actively maintained AND relational AND reactive. |
| `QUERY_ALL_PACKAGES` for app picker | `<queries>` element + LAUNCHER intent filter | Android 11+ (API 30, 2020) | Required policy lane; PLAY-04 verifiable. |
| `USE_EXACT_ALARM` (no user prompt) | `SCHEDULE_EXACT_ALARM` (with user prompt) | Android 13+ Play Console scrutiny | We are not "alarm/calendar class"; user prompt is the right lane for our daily reminder. |
| Provider / Bloc / GetX | Riverpod 3.x with code-gen | Riverpod 3.0 GA (mid-2025) and ecosystem consolidation | Less boilerplate; compile-time safety; matches CLAUDE.md. |

**Deprecated / outdated (do NOT use):**
- `getRunningTasks()` — deprecated since API 21 (2014); returns only the caller's own tasks.
- `system_alert_window` package — degrades to notification bubble on Android 11+.
- Isar — original author abandoned the project.
- `flutter_app_lock` — locks your own app, doesn't intercept others.

---

## Assumptions Log

> Per the meta-instructions: every claim tagged `[ASSUMED]` in this research goes here so the
> planner and discuss-phase can flag them for user confirmation before they become locked
> decisions.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact Pigeon 26.x generated method signature uses `Long` for epoch-milliseconds (we wrote it as `int` in the Dart interface and `Long` in the Kotlin stub). The generator MAY produce different naming. | §3 (Pigeon stub `MainActivity.kt`) | Compile error in `MainActivity.kt` until the developer regenerates and matches the actual signature. Low risk; trivial to fix. Mitigation: planner should run codegen before hand-writing the stub. |
| A2 | `flutter_riverpod 3.3.1` exposes the `@riverpod` annotation with the same `*.g.dart` generated-file convention as 2.x. | §6 (Riverpod selector) | The generator path or method-name shape may differ. Mitigation: planner runs `dart run build_runner build` once and reads the actual generated file. |
| A3 | The Flutter 3.41 template's bundled AGP is exactly 8.11.1 and KGP is 2.x. STACK.md says "AGP 8.11.1+, Java 17, Kotlin version" without quoting an exact KGP version, and the Flutter 3.41 release notes only document "Bump AGP, KGP, Gradle Templates" without quoting numbers. | §1 (Gradle settings) | If the template ships a different AGP, our explicit `JavaVersion.VERSION_17` block is fine but the mandate to "match template default" may be wrong. Mitigation: trust the template defaults; only override `compileSdk`/`min`/`target`/`Java`. |
| A4 | `<queries>` element with `<intent><action MAIN /><category LAUNCHER /></intent>` is sufficient on Android 11+ to enumerate launchable apps via `PackageManager.queryIntentActivities()`. | §4 (manifest queries block) | If a specific OEM/Android-version combo requires additional `<package>` tags, the Phase 2 app picker (LIST-01) may return an empty list. Mitigation: developer.android.com/training/package-visibility/use-cases confirms LAUNCHER-filter is the canonical pattern for app pickers. |
| A5 | The `applicationId` `com.nottodo.not_to_do_list` is unique on Play Store (no clash with an existing publisher). | §1 (`flutter create --org`) | If clashed, Play upload fails with "package name already taken." Mitigation: developer should verify on Play Console before first internal upload. Phase 1 does NOT upload to Play. |
| A6 | `drift_flutter ^0.2.0` is API-compatible with `drift ^2.32.1`. STACK.md lists this pairing but the drift docs themselves use `^0.3.1-wip` for the latest Flutter helper. Choosing between the two is a minor compatibility decision. | §1 (`pubspec.yaml`) | Mismatch causes a `flutter pub get` error. Trivial to bump. Mitigation: planner runs `flutter pub get` first; `drift_flutter`'s actual version constraint resolves automatically. |
| A7 | The AccessibilityService manifest entry is allowed to coexist with a Phase 1 stub Kotlin class that has an empty `onAccessibilityEvent` override. Some OEMs may auto-disable a service that does literally nothing. | §4 (manifest service entry) | If users grant the service in Phase 1 (they shouldn't — it's not in the onboarding flow yet), some OEMs may silently disable it overnight. Phase 1 success criteria do NOT require the service to be granted; it's manifest-only. Mitigation: Phase 1 onboarding does not deep-link to a11y settings. |
| A8 | The verification commands in §10 run inside `bash`/`zsh` on macOS (the developer's platform). Some grep/test invocations may behave differently on `dash`/`sh`. | §10 | Trivial; rewrite `!` as `if grep -q ...; then exit 1; fi` if needed. |

---

## Open Questions

1. **Should the Phase 1 `NotToDoAccessibilityService.kt` stub class actually exist, or is the manifest entry referencing a class that does not yet compile?**
   - What we know: ARCHITECTURE.md says "AccessibilityService is a passive trigger; Phase 4 implements." Manifest entry must point to a real class for `flutter build apk` to succeed.
   - What's unclear: whether Phase 1 ships an empty `onAccessibilityEvent` override (recommended) or whether the manifest entry is commented out and re-enabled in Phase 4.
   - Recommendation: ship the empty stub in Phase 1. Reasoning: keeping the manifest entry live makes verification commands V8/V9 meaningful (the `<meta-data>` pointer is exercised), and an empty override compiles cleanly. The only risk (A7 above) is that an over-eager beta tester enables it before Phase 4 — Phase 1's onboarding has no deep-link, so this requires intentional user action.

2. **Should `lib/main.dart`'s empty home screen include a placeholder `BlockedAppDetector` subscription (just `ref.watch(blockedAppDetectorProvider)` to confirm the provider compiles), or stay completely passive?**
   - Recommendation: completely passive. The provider is exercised by the unit test in `test/domain/providers/blocked_app_detector_provider_test.dart`. Phase 2 will be the first place the home screen actually uses the provider.

3. **Should `analysis_options.yaml` extend `very_good_analysis` or `flutter_lints`?**
   - What's unclear: STACK.md prefers `very_good_analysis ^7.0.0`; CLAUDE.md says "Pick one and stick with it."
   - Recommendation: `very_good_analysis ^7.0.0`. Stricter preset surfaces issues earlier in a six-week budget.

4. **What versionName/versionCode should Phase 1 ship?**
   - Recommendation: `0.1.0+1` (versionName 0.1.0, versionCode 1). Phase 6 will own bumping for first Play submission.

---

## Don't Hand-Roll

> Compact summary; full table is §14.

- **Schema management** → Drift, not raw SQL.
- **Dart↔Kotlin marshalling** → Pigeon, not MethodChannel.
- **State management** → Riverpod, not service-locator singletons.
- **Routing** → go_router, not Navigator.push strings.
- **One-line settings** → shared_preferences, not a Drift table.

---

## Sources

### Primary (HIGH confidence)
- **Project research bundle** (verified 2026-04-26):
  - `.planning/research/STACK.md` — stack pins, Play policy lane, version compatibility table.
  - `.planning/research/ARCHITECTURE.md` — Pigeon + native-event-source + activity-launch decisions, anti-patterns.
  - `.planning/research/PITFALLS.md` — the ten critical pitfalls + Phase 1 alignment.
  - `.planning/research/SUMMARY.md` — executive summary cross-confirming above.
  - `.planning/research/FEATURES.md` — anti-feature lockdowns.
  - `.planning/REQUIREMENTS.md` — REQ-ID mapping (PLAY-01..09, REL-05, SETT-03).
  - `.planning/ROADMAP.md` — Phase 1 success criteria.
  - `./CLAUDE.md` — project-level locked decisions.
- **pub.dev** (verified 2026-04-26):
  - https://pub.dev/packages/drift — 2.32.1, 36 days old.
  - https://pub.dev/packages/flutter_riverpod — 3.3.1, 49 days old.
  - https://pub.dev/packages/pigeon — 26.3.4, 19 days old, verified flutter.dev publisher.
- **Official Android docs** (verified 2026-04-26):
  - https://developer.android.com/guide/topics/manifest/queries-element — `<queries>` element semantics.
  - https://developer.android.com/reference/android/accessibilityservice/AccessibilityServiceInfo — every a11y config attribute used in §5.
  - https://developer.android.com/guide/topics/ui/accessibility/service — service lifecycle.
- **Official Flutter docs:**
  - https://drift.simonbinder.eu/setup/ — canonical Drift setup pattern verified directly.
  - https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632 — Flutter 3.41 release.

### Secondary (MEDIUM confidence)
- https://support.google.com/googleplay/android-developer/answer/10964491 — Use of the AccessibilityService API (Play policy).
- https://support.google.com/googleplay/android-developer/answer/11926878 — targetSdk requirements (targetSdk 36 by Aug 31, 2026).
- https://support.google.com/googleplay/android-developer/answer/16558241 — Permissions and APIs that Access Sensitive Information.
- https://github.com/flutter/packages/tree/main/packages/pigeon — Pigeon repository (CLI flag conventions).

### Tertiary (LOW confidence — needs validation when planner executes)
- Exact Pigeon-26.x generated Kotlin signature for `Long` epoch-ms parameters (planner verifies by running codegen).
- Exact Flutter 3.41 template KGP pin (planner verifies via `cat android/settings.gradle.kts` after `flutter create`).
- Whether `drift_flutter ^0.2.0` resolves cleanly with `drift ^2.32.1` (planner verifies via `flutter pub get`).

---

## Project Constraints (from CLAUDE.md)

Per `./CLAUDE.md`, the following directives are binding for Phase 1 plans (the planner must verify compliance):

1. **GSD workflow enforcement.** Before using Edit/Write/file-changing tools, work flows through a GSD command. Phase 1 is invoked via `/gsd-plan-phase 1` → `/gsd-execute-phase`; no direct repo edits outside that path.
2. **Tech stack pins** — exactly mirror CLAUDE.md "Technology Stack" table (Flutter 3.41.x, Riverpod 3.3.1, Drift 2.32.x, Pigeon 26.x, minSdk 29 / targetSdk 36).
3. **Privacy non-negotiable** — 100% on-device, no telemetry, no FCM, no analytics. Verified by §10 V10.
4. **Permission pins** — `SCHEDULE_EXACT_ALARM` (not `USE_EXACT_ALARM`); `<queries>` + LAUNCHER (not `QUERY_ALL_PACKAGES`); `isAccessibilityTool="false"`.
5. **Anti-features locked** — no overlay-based pause UI; service is a passive trigger.
6. **Free / OSS only** — no paid SDKs.
7. **Conventions section in CLAUDE.md is empty** — Phase 1 may *populate* conventions discovered during execution (handed back via `/gsd-transition`); Phase 1 does not invent conventions ahead of need.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every pin verified against pub.dev with publish dates 19–49 days old.
- Architecture: HIGH — directly inherited from `research/ARCHITECTURE.md` which is itself HIGH-confidence and project-specific.
- Pitfalls: HIGH — distilled from `research/PITFALLS.md` with Phase 1 mappings.
- Pigeon CLI conventions: MEDIUM — Pigeon 26.x uses `@ConfigurePigeon` annotations rather than CLI flags; documented but not exhaustively tested with the exact options used here. Mitigation: tracked in Assumptions A1.
- Environment availability: HIGH (Wave 0 install steps are unavoidable; verified `which` and `JAVA_HOME` empty).

**Research date:** 2026-04-26
**Valid until:** 2026-05-26 (30 days — stable libraries; Drift, Riverpod, Pigeon, Flutter all on slow major-version cadences). Re-verify if Phase 1 has not exited within 30 days.
