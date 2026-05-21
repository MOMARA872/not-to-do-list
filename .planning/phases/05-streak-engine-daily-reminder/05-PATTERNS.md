# Phase 5: Streak Engine & Daily Reminder — Pattern Map

**Mapped:** 2026-05-21
**Files to be created or modified:** 38 (29 new + 9 modified)
**Analogs found:** 35 / 38 (3 are new-to-codebase platform pieces; see "New Patterns Introduced by Phase 5")

This file tells `gsd-planner` exactly which existing file each Phase 5 file copies its skeleton from. Every line uses absolute paths anchored at `/Users/jintanakhomwong/projects/not-to-do-list/`. All copy-style decisions in `05-UI-SPEC.md` and all algorithm rules in `05-RESEARCH.md §4–§6` are already locked — the planner's job is to instantiate the analogs verbatim, not to redesign.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/data/database/daos/daily_checkins_dao.dart` (new) | DAO | CRUD (upsert + query by (entry, day)) | `lib/data/database/daos/daily_usage_summary_dao.dart` | exact |
| `lib/data/database/daos/daily_streak_dao.dart` (new) | DAO | CRUD (upsert + watchRange) | `lib/data/database/daos/daily_usage_summary_dao.dart` | exact |
| `lib/data/database/app_database.dart` (modify) | DB registration | config | self — modify `@DriftDatabase` declaration | exact |
| `lib/features/streak/storage/streak_keys.dart` (new) | constants | config | `lib/features/onboarding/storage_keys.dart` | exact |
| `lib/domain/streak/streak_rollover_service.dart` (new) | service | batch transform (lazy on resume) | `lib/data/repositories/pause_event_repository.dart` + `lib/features/health/permission_health_provider.dart` + `lib/features/dashboard/providers/avoided_today_provider.dart` | role-match (composite) |
| `lib/features/streak/providers/streak_providers.dart` (new) | Riverpod providers | request-response | `lib/features/pause/providers/pause_providers.dart` | exact |
| `lib/features/streak/widgets/streak_badge.dart` (new) | widget | render | `lib/features/home/widgets/block_list_row.dart` (`trailing` slot) | exact (host) |
| `lib/features/home/widgets/block_list_row.dart` (modify) | widget | render | self — replace `trailing: Text('—', …)` placeholder | exact |
| `lib/features/streak/widgets/streak_history_section.dart` (new) | widget | render (GridView) | `lib/features/dashboard/pages/dashboard_screen.dart` (RefreshIndicator + grid pattern), `lib/features/list/widgets/schedule_editor.dart` (Wrap of FilterChip) | role-match |
| `lib/features/streak/widgets/day_dot.dart` (new) | widget | render | self — 4-state Container with `BoxDecoration(shape: BoxShape.circle, …)` per UI-SPEC §Color | new |
| `lib/features/list/pages/edit_entry_screen.dart` (modify) | screen | render | self — insert `StreakHistorySection` between `ScheduleEditor` and `FilledButton('Save changes')` | exact |
| `lib/features/checkin/pages/checkin_screen.dart` (new) | screen | request-response (single-tx write) | `lib/features/list/pages/edit_entry_screen.dart` + `lib/features/pause/pages/pause_screen.dart` | role-match (composite) |
| `lib/features/checkin/providers/checkin_providers.dart` (new) | Riverpod providers | request-response | `lib/features/pause/providers/pause_providers.dart` | exact |
| `lib/features/checkin/controllers/checkin_controller.dart` (new) | Notifier (single Drift txn) | event-driven | `lib/features/pause/controllers/pause_controller.dart` | exact |
| `lib/features/reminder/pages/reminder_settings_screen.dart` (new) | screen | request-response (showTimePicker) | `lib/features/list/widgets/schedule_editor.dart` (showTimePicker pattern), `lib/features/list/pages/edit_entry_screen.dart` (Scaffold + AppBar) | role-match |
| `lib/features/reminder/providers/reminder_providers.dart` (new) | Riverpod providers | request-response | `lib/features/onboarding/providers/onboarding_cursor_provider.dart` (AsyncNotifier over a single prefs int) | exact |
| `lib/features/reminder/widgets/reminder_off_banner.dart` (new) | widget | render (tap → settings) | `lib/features/health/widgets/health_check_banner.dart` | exact |
| `lib/features/home/pages/home_screen.dart` (modify) | screen | render | self — add 2nd `AnimatedSwitcher` below the existing `HealthCheckBanner`, gated on `postNotificationsGrantedProvider` | exact |
| `lib/features/onboarding/pages/post_notifications_earned_step.dart` (new) | screen | request-response (system dialog) | `lib/features/onboarding/pages/usage_access_step.dart` + `lib/features/onboarding/widgets/rationale_screen.dart` | exact |
| `lib/features/onboarding/providers/post_notifications_provider.dart` (new) | Riverpod provider | request-response | `lib/features/health/permission_health_provider.dart` (subset — 1 signal) | role-match |
| `lib/core/router/app_router.dart` (modify) | routing | config | self — add 2 `GoRoute` entries (`/checkin`, `/settings/reminder`) | exact |
| `pigeons/permission_status_api.dart` (modify) | Pigeon API | config | self — add 4 `@async` methods (mirror existing surface) | exact |
| `pigeons/notification_api.dart` (modify) | Pigeon API | config | self — signature already final per §5 RESEARCH; no change unless adding `openAppNotificationSettings()` | exact |
| `lib/domain/providers/notification_api_provider.dart` (new) | Riverpod provider | DI | `lib/domain/providers/permission_status_api_provider.dart` | exact |
| `lib/domain/providers/database_provider.dart` consumers (modify) | DI | DI | self — add `dailyCheckinsDaoProvider` + `dailyStreakDaoProvider` (mirror `usage_dao_provider.dart`) | exact |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApiImpl.kt` (new) | Kotlin Pigeon impl | platform | `android/.../platform/PermissionStatusApiImpl.kt` (Settings deep-link pattern), `android/.../platform/BlocklistBroadcastApiImpl.kt` (LocalBroadcast pattern) | role-match (composite) |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt` (modify) | Kotlin Pigeon impl | platform | self — add 4 methods (mirror existing 7) | exact |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/receiver/ReminderAlarmReceiver.kt` (new) | BroadcastReceiver | event-driven | NONE in codebase — new pattern (see "New Patterns") |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/receiver/BootReceiver.kt` (new) | BroadcastReceiver | event-driven | NONE in codebase — new pattern (see "New Patterns") |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` (modify) | Activity | platform wiring + onNewIntent | self — replace `NotificationApi` anonymous stub with `NotificationApiImpl(applicationContext)`; add `onNewIntent` parsing the `deep_link_to` extra | exact |
| `android/app/src/main/AndroidManifest.xml` (modify) | manifest | config | self — add 2 `<receiver>` blocks; perms already declared | exact |
| `test/data/dao/daily_streak_dao_test.dart` (new) | unit test | DAO test | `test/data/repositories/pause_event_repository_test.dart` | exact |
| `test/data/dao/daily_checkins_dao_test.dart` (new) | unit test | DAO test | `test/data/repositories/pause_event_repository_test.dart` | exact |
| `test/domain/streak/streak_rollover_service_test.dart` (new) | unit test | service test | `test/data/repositories/pause_event_repository_test.dart` (in-memory Drift) + `test/_fixtures/permission_status_mock.dart` (mocked clock api) | role-match |
| `test/domain/streak/streak_rollover_dst_test.dart` (new) | unit test | DST edge | `test/domain/schedule/schedule_window_parity_test.dart` (DST tuples GROUP 5) | exact (DST tuple pattern) |
| `test/features/streak/streak_badge_test.dart` (new) | widget test | render | `test/features/home/health_banner_test.dart` | exact |
| `test/features/streak/streak_history_section_test.dart` (new) | widget test | render | `test/features/home/health_banner_test.dart` | exact |
| `test/features/checkin/checkin_screen_test.dart` (new) | widget test | render + tx | `test/features/pause/pause_screen_test.dart` | exact |
| `test/features/reminder/reminder_settings_test.dart` (new) | widget test | render + tap | `test/features/home/health_banner_test.dart` + `test/features/list/schedule_editor_test.dart` | role-match |
| `test/features/reminder/deep_link_navigation_test.dart` (new) | widget test | router | `test/features/home/health_banner_test.dart` (router scaffolding) | role-match |
| `test/features/onboarding/post_notifications_earned_test.dart` (new) | widget test | render | `test/features/home/health_banner_test.dart` | exact |
| `test/features/home/reminder_off_banner_test.dart` (new) | widget test | render | `test/features/home/health_banner_test.dart` | exact |
| `test/policy/phase_5_invariants_test.dart` (new) | policy absence-grep | invariant | `test/policy/phase_4_invariants_test.dart` | exact |
| `test/policy/play_invariants_test.dart` (modify) | policy absence-grep | invariant | self — add Phase 5 sub-tests (no `USE_EXACT_ALARM`, no FCM, etc.) | exact |
| `test/_fixtures/streak_fixture.dart` (new) | test fixture | data | `test/_fixtures/permission_status_mock.dart` + `test/_fixtures/usage_summary_fixture.dart` | role-match |
| `android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/StreakDayAnchoringTest.kt` (new) | JVM unit test | Kotlin parity | `android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindowTest.kt` | exact |
| `.planning/phases/05-streak-engine-daily-reminder/05-VERIFICATION.md` (new) | manual gate doc | doc | `.planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md` (REL-04 9-step) — referenced; not read in detail by mapper | exact |

---

## Pattern Assignments — DAOs

### `lib/data/database/daos/daily_checkins_dao.dart` (DAO, CRUD)

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/daos/daily_usage_summary_dao.dart`

**Why this analog:** Identical shape — typed Drift accessor with `upsertDay` (idempotent by composite unique key `(packageName, day)`) and a `getTodayFor` lookup. Phase 5 needs the same shape keyed on `(entryId, day)`.

**Imports + accessor preamble pattern** (analog lines 1-17):
```dart
import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/tables/daily_usage_summary_table.dart';

part 'daily_usage_summary_dao.g.dart';

/// Drift DAO for the [DailyUsageSummary] table — typed CRUD over Phase 1's
/// pre-aggregated daily totals.
/// Hand-written (no @riverpod codegen). The `_$DailyUsageSummaryDaoMixin`
/// is generated by drift_dev via `dart run build_runner build`.
@DriftAccessor(tables: [DailyUsageSummary])
class DailyUsageSummaryDao extends DatabaseAccessor<AppDatabase>
    with _$DailyUsageSummaryDaoMixin {
  DailyUsageSummaryDao(super.attachedDatabase);
```

**Upsert pattern using non-PK composite unique key** (analog lines 27-48):
```dart
Future<void> upsertDay({
  required String packageName,
  required DateTime day,
  required int foregroundSeconds,
  required int launchCount,
  required DateTime aggregatedAt,
}) {
  final companion = DailyUsageSummaryCompanion.insert(
    packageName: packageName,
    day: day,
    foregroundSeconds: foregroundSeconds,
    launchCount: Value(launchCount),
    aggregatedAt: aggregatedAt,
  );
  return into(dailyUsageSummary).insert(
    companion,
    onConflict: DoUpdate(
      (_) => companion,
      target: [dailyUsageSummary.packageName, dailyUsageSummary.day],
    ),
  );
}
```

**Replication notes for `daily_checkins_dao.dart`:**
- Swap target columns to `[dailyCheckins.entryId, dailyCheckins.day]` (matches unique key in `daily_checkins_table.dart`).
- Methods needed: `upsert({entryId, day, avoided, answeredAt})`, `getFor(entryId, day) → DailyCheckinData?`, `watchForRange(entryId, startDay, endDay)` (only if streak history needs it — STRK history reads from `daily_streak`, not `daily_checkins`, so a simple `getFor` may suffice).

**Replication notes for `daily_streak_dao.dart`:**
- Target columns `[dailyStreak.entryId, dailyStreak.day]`.
- Methods needed: `upsert({entryId, day, status, source, usageMinutesObserved, evaluatedAt})`, `upsertIfAbsent(...)` (today's `status=3 pending`, do not overwrite an existing row — emulate with a `getFor` + conditional insert), `watchHistoryFor(entryId, days: 30)` (mirrors `watchRange` from analog lines 71-79), `getCurrentStreakFor(entryId) → int` + `getLongestStreakFor(entryId) → int` (custom SQL — see `lib/features/dashboard/providers/avoided_today_provider.dart` lines 39-50 for `customSelect` precedent).

**Database registration** (modify `lib/data/database/app_database.dart` line 22):
Change:
```dart
daos: [BlockListDao, DailyUsageSummaryDao, PauseEventDao],
```
to:
```dart
daos: [BlockListDao, DailyUsageSummaryDao, PauseEventDao, DailyCheckinsDao, DailyStreakDao],
```
No `schemaVersion` bump (D-08 / RESEARCH §4 lock — tables already exist from Phase 1).

---

## Pattern Assignments — Domain / Services

### `lib/features/streak/storage/streak_keys.dart` (constants)

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/storage_keys.dart`

**Pattern to copy verbatim** (entire 14-line file):
```dart
/// Centralized `SharedPreferences` keys for Phase 2 onboarding + health-check
/// state. Single source of truth so the cursor, completion flag, and the
/// fingerprint baseline stay in lockstep across providers + tests.
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

**Replication for `StreakKeys`:**
```dart
abstract final class StreakKeys {
  static const String streakThresholdMinutes = 'streak_threshold_minutes'; // default 5
  static const String reminderHourMinute = 'reminder_hour_minute';         // default 1260 = 21*60
  static const String lastWallClockMs = 'streak_last_wall_clock_ms';
  static const String lastBootMonotonicNs = 'streak_last_boot_monotonic_ns';
  static const String lastEvaluatedStreakDay = 'streak_last_evaluated_day_ms';
  static const String earnedPromptShown = 'post_notifications_earned_prompt_shown';
}
```
**Critical:** the Kotlin `BootReceiver` and `ReminderAlarmReceiver` read `flutter.reminder_hour_minute` via the `FlutterSharedPreferences` file (see RESEARCH §10 R-9). Key MUST be exactly `reminder_hour_minute`.

---

### `lib/domain/streak/streak_rollover_service.dart` (service, lazy-on-resume)

**Primary analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/health/permission_health_provider.dart` — hand-written `AsyncNotifier` pattern + `refresh()` invoked from `AppLifecycleState.resumed` mirrors STRK-05 exactly.

**Composite analog (for the algorithm shell):** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/dashboard/providers/avoided_today_provider.dart` — reactive multi-table join (block_list × daily_usage_summary × daily_checkins) in a stream — the streak engine joins the same three tables plus `pause_events`.

**Hand-written AsyncNotifier shell** (from `permission_health_provider.dart` lines 34-74):
```dart
class PermissionHealthNotifier extends AsyncNotifier<PermissionHealth> {
  @override
  Future<PermissionHealth> build() => _evaluate();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _evaluate());
  }

  Future<PermissionHealth> _evaluate() async {
    final api = ref.read(permissionStatusApiProvider);
    final prefs = await SharedPreferences.getInstance();
    final storedFp = prefs.getString(OnboardingKeys.lastKnownFingerprint);
    final currentFp = await api.currentBuildFingerprint();
    // ... read / write / branch ...
    return PermissionHealth(...);
  }
}
```

**Multi-table join pattern** (from `avoided_today_provider.dart` lines 44-90):
```dart
final entries = await db.select(db.blockList).get();
final usageToday = await (db.select(db.dailyUsageSummary)
      ..where((t) => t.day.equals(today)))
    .get();
final checkinsToday = await (db.select(db.dailyCheckins)
      ..where((t) => t.day.equals(today)))
    .get();

for (final e in entries) {
  if (e.kind == 0) {
    final pkg = e.packageName ?? '';
    var seconds = 0;
    for (final u in usageToday) {
      if (u.packageName == pkg) seconds = u.foregroundSeconds;
    }
    final thresholdSec = e.streakBreakThresholdMinutes * 60;
    if (seconds <= thresholdSec) { succeeded++; } else { failed++; }
  } else {
    // Habit branch — check-in only
  }
}
```

**Replication notes:**
- Method `rollover()` (called from `WidgetsBindingObserver.didChangeAppLifecycleState` resumed branch — see `lib/features/health/widgets/_health_lifecycle_observer.dart` lines 42-52) implements RESEARCH §4 algorithm verbatim:
  1. read clocks (wall via `DateTime.now()`, boot-monotonic via new Pigeon `bootMonotonicNanos()`)
  2. compute `divergenceMs = (wallDelta - bootDeltaMs).abs()` — if > 24h → `clockTampered = true`
  3. `streakDayFor(DateTime.now())` (lib/domain/schedule/streak_day.dart — pure-Dart helper already exists, lines 1-18)
  4. for each (entry, day) between `lastEvaluatedDay+1` and `today-1`: run `_resolveDay(...)` per the 2x2 matrix and call `dailyStreakDao.upsert(...)`
  5. write today's row `status=3 pending` via `upsertIfAbsent`
  6. persist `(lastWallMs, lastBootNs, lastEvaluatedDay)` to prefs
- Use `DateTime(cursor.year, cursor.month, cursor.day + 1)` for day-step — NOT `cursor.add(Duration(days: 1))` — DST safety per RESEARCH §4 DST table.
- Backfill cap: if `lastEvaluatedDay < today - 30` → backfill stops at 30 days, write `status=2 incomplete-data` for the gap (RESEARCH §10 R-7).
- Trigger from `_health_lifecycle_observer.dart` mirror — add `unawaited(ref.read(streakRolloverServiceProvider).rollover())` to the resumed branch alongside the existing two `unawaited(...)` calls.

---

## Pattern Assignments — Riverpod Providers

### `lib/features/streak/providers/streak_providers.dart` (Riverpod providers, request-response)

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/pause/providers/pause_providers.dart`

**Hand-written family + repo provider pattern** (analog lines 14-37):
```dart
/// Provider for the D-13 single-writer seam.
final Provider<PauseEventRepository> pauseEventRepositoryProvider =
    Provider<PauseEventRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PauseEventRepository(db.pauseEventDao);
});

/// Family provider for a BlockList row lookup by entryId.
final FutureProviderFamily<BlockListData?, int> blockListEntryProvider =
    FutureProvider.autoDispose.family<BlockListData?, int>((ref, id) {
  final repo = ref.read(blockListRepoProvider);
  return repo.getById(id);
});
```

**Replication for the providers RESEARCH §8 requires:**
```dart
final Provider<DailyCheckinsDao> dailyCheckinsDaoProvider = ...
final Provider<DailyStreakDao> dailyStreakDaoProvider = ...
final AsyncNotifierProvider<StreakRolloverService, void> streakRolloverServiceProvider = ...

// STRK-07 — Home badge per entry
final FutureProviderFamily<StreakBadgeData, int> streakBadgeProvider =
    FutureProvider.autoDispose.family<StreakBadgeData, int>((ref, entryId) async {
      final dao = ref.read(dailyStreakDaoProvider);
      final current = await dao.getCurrentStreakFor(entryId);
      final longest = await dao.getLongestStreakFor(entryId);
      return StreakBadgeData(current: current, longest: longest);
    });

// D-16 — Streak history GridView (30 days)
final FutureProviderFamily<List<DailyStreakData>, int> streakHistoryProvider =
    FutureProvider.autoDispose.family<List<DailyStreakData>, int>((ref, entryId) async {
      final dao = ref.read(dailyStreakDaoProvider);
      return dao.watchHistoryFor(entryId, days: 30).first;
    });
```
- All providers `autoDispose` (matches `blockListEntryProvider` analog line 33 + `_homeEntriesProvider` in home_screen.dart line 17).
- Tests override via `.overrideWithValue(...)` — see `test/features/home/health_banner_test.dart` lines 57-58 for the pattern.

---

### `lib/features/reminder/providers/reminder_providers.dart` (Riverpod provider, request-response)

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/providers/onboarding_cursor_provider.dart`

**Pattern to copy** (entire 33-line file):
```dart
class OnboardingCursorNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(OnboardingKeys.cursor) ?? 0;
  }

  Future<void> set(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(OnboardingKeys.cursor, step);
    state = AsyncValue.data(step);
  }
}

final AsyncNotifierProvider<OnboardingCursorNotifier, int>
    onboardingCursorProvider =
    AsyncNotifierProvider<OnboardingCursorNotifier, int>(
  OnboardingCursorNotifier.new,
);
```

**Replication notes:** `ReminderTimeNotifier extends AsyncNotifier<int>` (hour*60+minute), default 1260. `set(int hm)` writes to `prefs[reminder_hour_minute]` AND calls `ref.read(notificationApiProvider).scheduleDailyReminder(hm ~/ 60, hm % 60)` to re-arm the alarm in the same atomic step (D-09 + NOTF-02).

---

### `lib/domain/providers/notification_api_provider.dart` (DI provider)

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/providers/permission_status_api_provider.dart`

**Pattern to copy** (entire 14-line file):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';

final Provider<PermissionStatusApi> permissionStatusApiProvider =
    Provider<PermissionStatusApi>((ref) => PermissionStatusApi());
```
Swap `PermissionStatusApi` → `NotificationApi`, import path → `'package:not_to_do_list/platform/notification_api.g.dart'`. Tests override via `notificationApiProvider.overrideWith((ref) => MockNotificationApi())` — see `test/_fixtures/permission_status_mock.dart` for the mock-factory pattern.

---

### `lib/features/onboarding/providers/post_notifications_provider.dart` (Riverpod provider)

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/health/permission_health_provider.dart` — subset (1 signal instead of 4).

**Replication notes:**
```dart
class PostNotificationsGrantedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final api = ref.read(permissionStatusApiProvider);
    return api.isPostNotificationsGranted(); // NEW Pigeon method
  }
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await build());
  }
}
```
- Re-evaluated on `AppLifecycleState.resumed` — extend `lib/features/health/widgets/_health_lifecycle_observer.dart` lines 42-52 with a third `unawaited(ref.read(postNotificationsGrantedProvider.notifier).refresh())` call.
- NOTF-07 banner watches this provider directly.

---

## Pattern Assignments — Widgets / Screens

### `lib/features/reminder/widgets/reminder_off_banner.dart` (widget, render)

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/health/widgets/health_check_banner.dart` (entire 165-line file is the pattern, but simpler — no expand toggle per UI-SPEC §Screen 5).

**Color tokens + Material+InkWell scaffold** (analog lines 28-101):
```dart
// UI-SPEC Surface 11: fixed amber tokens, NOT M3 ColorScheme seed.
static const Color _amberBgLight = Color(0xFFFFF3CD);
static const Color _amberFgLight = Color(0xFF856404);
static const Color _amberBgDark = Color(0xFF3D2E00);
static const Color _amberFgDark = Color(0xFFFFD966);

@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? _amberBgDark : _amberBgLight;
  final fg = isDark ? _amberFgDark : _amberFgLight;
  return Material(
    color: bg,
    child: InkWell(
      onTap: _tapToFix,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined, size: 16, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tracking is offline — tap to fix',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg, fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            // (analog has expand toggle — Phase 5 omits it per UI-SPEC §Screen 5)
          ],
        ),
      ),
    ),
  );
}
```

**Replication notes:**
- Swap icon `Icons.warning_amber_outlined` → `Icons.notifications_off_outlined` (UI-SPEC §Screen 5 line 292).
- Swap copy → `'Reminder is off — tap to fix'` (UI-SPEC copy lock).
- Tap behavior: branch on `await ref.read(permissionStatusApiProvider).postNotificationsRationaleState()` per RESEARCH §6 three-state table. If `'permanently_denied'` → `url_launcher.launchUrl(Uri.parse('package:com.nottodo.not_to_do_list'))` against `ACTION_APP_NOTIFICATION_SETTINGS` (use Pigeon helper `openAppNotificationSettings()` if added; otherwise reuse `url_launcher` like analog `_OemLink` lines 142-159). Otherwise → `context.go('/onboarding/permissions/notifications')`.
- No expand button, no dismiss button (UI-SPEC §Screen 5 lines 299, 305).

**Home screen integration** (modify `lib/features/home/pages/home_screen.dart` lines 42-51):
```dart
// Current
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: healthAsync.maybeWhen(
    data: (h) => h.allHealthy ? const SizedBox.shrink() : HealthCheckBanner(health: h),
    orElse: () => const SizedBox.shrink(),
  ),
),
```
Add directly below (D-12 stack order: tracking-offline ABOVE reminder-off):
```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: postNotificationsAsync.maybeWhen(
    data: (granted) => granted ? const SizedBox.shrink() : const ReminderOffBanner(),
    orElse: () => const SizedBox.shrink(),
  ),
),
```

---

### `lib/features/streak/widgets/streak_badge.dart` (widget)

**Host analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/home/widgets/block_list_row.dart` lines 52-57 — the `trailing` slot currently renders a `'—'` placeholder. Replace with `StreakBadge(entryId: entry.id)`.

**Pattern:**
```dart
class StreakBadge extends ConsumerWidget {
  const StreakBadge({required this.entryId, super.key});
  final int entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final badgeAsync = ref.watch(streakBadgeProvider(entryId));
    return badgeAsync.maybeWhen(
      data: (d) => Text(
        '🔥 ${d.current} · best ${d.longest}', // UI-SPEC copy lock
        style: tt.labelSmall?.copyWith(
          color: d.current > 0 ? cs.onSurface : cs.onSurfaceVariant,
        ),
      ),
      orElse: () => Text('—', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}
```
- `labelSmall` is pinned to 14sp/w400 in AppTheme (UI-SPEC §Typography line 76).
- D-05 strikethrough on break-detection day: render `🔥 ` then `Text.rich` with two TextSpan children — prior count with `TextDecoration.lineThrough`, then ` → 0 · best M` plain.

---

### `lib/features/streak/widgets/day_dot.dart` + `streak_history_section.dart`

**Color tokens locked by UI-SPEC §Color 4-State Day-Status table (lines 109-115):**
```dart
// green ✓
const Color(0xFF2E7D32); // light  / 0xFF66BB6A dark
// blue ○
const Color(0xFF1565C0); // light  / 0xFF64B5F6 dark
// red ×
const Color(0xFFC62828); // light  / 0xFFEF9A9A dark
// grey —
const Color(0xFF757575); // light  / 0xFF9E9E9E dark
```

**Grid scaffold analog:** `lib/features/list/widgets/schedule_editor.dart` lines 151-161 (Wrap of FilterChip → mirror as GridView for 30 day cells). UI-SPEC §Screen 3 spec lines 215-230 has the exact GridView config:
```dart
GridView.count(
  physics: const NeverScrollableScrollPhysics(),
  shrinkWrap: true,
  crossAxisCount: 7,
  childAspectRatio: 1.0,
  mainAxisSpacing: 4,
  crossAxisSpacing: 4,
  children: [...30 DayDot widgets],
)
```

**DayDot internal shape** (UI-SPEC §Screen 3 lines 237-243):
```dart
Container(
  width: 24, height: 24, alignment: Alignment.center,
  child: Container(
    width: 8, height: 8,
    decoration: BoxDecoration(shape: BoxShape.circle, color: _resolveColor(state, isDark)),
  ),
)
```
Wrap the grey state in `Tooltip(message: 'Tracking was off this day', child: _DayDot(...))` — UI-SPEC line 232 calls this mandatory.
Add `Semantics(label: '{date} — {state}')` per UI-SPEC §Accessibility lines 385-389.

---

### `lib/features/checkin/pages/checkin_screen.dart` (screen)

**Analog (Scaffold + Save flow):** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/list/pages/edit_entry_screen.dart` lines 41-66, 151-208.

**`_save` error-handling pattern** (analog lines 41-66):
```dart
Future<void> _save() async {
  final notifier = ref.read(editEntryControllerProvider(widget.id).notifier);
  try {
    notifier..setName(name)..setReason(_reasonController.text);
    await notifier.save();
  } on Object {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Something went wrong — changes weren't saved. Try again."),
      ),
    );
    return;
  }
  if (!mounted) return;
  context.go('/');
}
```

**Replication:** swap copy to UI-SPEC line 336 — `"Something went wrong — your check-in wasn't saved. Try again."`. `_save` writes via a single Drift transaction (RESEARCH §7 lines 674-693):
```dart
await ref.read(appDatabaseProvider).transaction(() async {
  final dao = ref.read(dailyCheckinsDaoProvider);
  for (final entry in answers.entries) {
    await dao.upsert(entryId: entry.key, day: today, avoided: entry.value, answeredAt: now);
  }
});
await ref.read(streakRolloverServiceProvider).rollover(); // refresh badges
if (context.mounted) context.go('/');
```

**SegmentedButton (Yes/No) pattern:** mirror `lib/features/dashboard/widgets/dashboard_segmented.dart` lines 21-37 — use `SegmentedButton<bool>` with two `ButtonSegment<bool>(value: true, label: Text('Yes'))` / `(value: false, label: Text('No'))`. Set `selected: currentAnswer != null ? {currentAnswer} : <bool>{}` for tri-state (unselected = nothing answered yet). UI-SPEC §Screen 1 lines 159-166.

---

### `lib/features/reminder/pages/reminder_settings_screen.dart`

**`showTimePicker` analog:** `lib/features/list/widgets/schedule_editor.dart` lines 49-61:
```dart
Future<void> _pickStart() async {
  final start = widget.startMinutes ?? _defaultStart;
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60),
  );
  if (picked == null) return;
  widget.onChanged(picked.hour * 60 + picked.minute, ...);
}
```

**Replication for Reminder Settings (UI-SPEC §Screen 4 lines 251-272):**
```dart
ListTile(
  leading: const Icon(Icons.notifications_outlined),
  title: const Text('Daily reminder'),
  subtitle: Text(DateFormat.jm().format(/* TimeOfDay → DateTime */)),
  trailing: const Icon(Icons.chevron_right),
  onTap: () async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hm ~/ 60, minute: hm % 60),
    );
    if (picked == null) return;
    await ref.read(reminderTimeProvider.notifier)
        .set(picked.hour * 60 + picked.minute);
  },
)
```
The provider's `set(...)` cancels + re-schedules the alarm (Pigeon `NotificationApi`) — no confirmation dialog (UI-SPEC line 270: "the time picker IS the confirmation").

---

### `lib/features/onboarding/pages/post_notifications_earned_step.dart`

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/pages/usage_access_step.dart` — `ConsumerStatefulWidget` + `WidgetsBindingObserver` + `_checkAndMaybeAdvance` on resumed pattern.

**Pattern (analog lines 20-86):**
```dart
class _UsageAccessStepState extends ConsumerState<UsageAccessStep>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkAndMaybeAdvance());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkAndMaybeAdvance(fromResume: true));
    }
  }

  Future<void> _checkAndMaybeAdvance({bool fromResume = false}) async {
    final api = ref.read(permissionStatusApiProvider);
    final granted = await api.isUsageAccessGranted();
    if (!mounted) return;
    if (granted) {
      // ... advance ...
    }
  }
}
```

**Replication notes:** swap `isUsageAccessGranted()` → `isPostNotificationsGranted()`. On grant: pop and continue. Use `RationaleScreen` shell from `lib/features/onboarding/widgets/rationale_screen.dart` (analog lines 1-118) with:
- `headline: 'Daily reminders keep your streak honest'`
- `body: 'Get a daily reminder to confirm your not-to-do list. Without notifications, you'll need to open the app to record each day.'` (RESEARCH §6 line 621)
- `primaryCtaLabel: 'Continue'`
- `onPrimaryCta: () => api.requestPostNotifications()` (NEW Pigeon method)
- Trigger fire-once from `BlockListRepository.add()` post-write hook OR a Riverpod listener on `_homeEntriesProvider` that fires when count transitions 0→1 (RESEARCH §6 lines 583-585). Use `StreakKeys.earnedPromptShown` to suppress re-fire.

---

### `lib/features/list/pages/edit_entry_screen.dart` (modify — insert section)

**Insertion point:** After `ScheduleEditor` (line 179-184), before `const SizedBox(height: 32)` (line 185).

**Add:**
```dart
const SizedBox(height: 24),
const Divider(),
const SizedBox(height: 16),
StreakHistorySection(entryId: draft.id),
const SizedBox(height: 16),
```

---

### Router modifications (`lib/core/router/app_router.dart`)

**Pattern:** lines 34-44 — existing `GoRoute` entries.

**Add two routes after `/dashboard` (line 44):**
```dart
GoRoute(path: '/checkin', builder: (_, __) => const CheckinScreen()),
GoRoute(path: '/settings/reminder', builder: (_, __) => const ReminderSettingsScreen()),
GoRoute(
  path: '/onboarding/permissions/notifications',
  builder: (_, __) => const PostNotificationsEarnedStep(),
),
```

**Redirect rule consideration:** the existing redirect (lines 23-33) gates `/checkin` behind onboarding completion — desired behavior (Home is the only entry to `/checkin`).

---

## Pattern Assignments — Pigeon API Extensions

### `pigeons/permission_status_api.dart` (modify)

**Pattern:** existing 57-line file. Add 4 `@async` declarations following the existing surface:

```dart
@async
bool isPostNotificationsGranted();

@async
String postNotificationsRationaleState(); // "grantable" | "rationale" | "permanently_denied"

@async
bool requestPostNotifications(); // launches system dialog, returns post-result granted state

@async
int bootMonotonicNanos(); // SystemClock.elapsedRealtimeNanos() — STRK-06 clock-tamper
```

Optionally add:
```dart
@async
void openAppNotificationSettings(); // ACTION_APP_NOTIFICATION_SETTINGS deep-link
```
Mirror the existing `openUsageAccessSettings()` / `openAccessibilitySettings()` shape (analog lines 44-50).

**Regenerate:** `dart run pigeon --input pigeons/permission_status_api.dart` (build_runner / pigeon docs).

---

### `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt` (modify)

**Analog (self):** existing 131-line file. Add 4 new method implementations following the existing pattern (analog lines 29-65 for simple system-service reads).

**Pattern from `isUsageAccessGranted`** (analog lines 29-41):
```kotlin
override fun isUsageAccessGranted(callback: (Result<Boolean>) -> Unit) {
    try {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(...)
        callback(Result.success(mode == AppOpsManager.MODE_ALLOWED))
    } catch (e: Throwable) {
        callback(Result.failure(e))
    }
}
```

**Replication for new methods:**
```kotlin
override fun isPostNotificationsGranted(callback: (Result<Boolean>) -> Unit) {
    try {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            callback(Result.success(true)); return // Auto-granted on Android < 13
        }
        val granted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
        callback(Result.success(granted))
    } catch (e: Throwable) {
        callback(Result.failure(e))
    }
}

override fun bootMonotonicNanos(callback: (Result<Long>) -> Unit) {
    try {
        callback(Result.success(SystemClock.elapsedRealtimeNanos()))
    } catch (e: Throwable) {
        callback(Result.failure(e))
    }
}
```
- `postNotificationsRationaleState()` requires an `Activity` reference, not `Context`. Pass the `MainActivity` via constructor (mirror the pattern that may need touching `MainActivity.configureFlutterEngine` to pass `this` instead of `applicationContext` for this impl — analog `MainActivity.kt` line 55 currently passes `applicationContext`). Consider splitting: keep status checks on `applicationContext`; route `requestPostNotifications` through a different surface using `ActivityResultContracts.RequestPermission`.

---

## Pattern Assignments — Tests

### `test/data/dao/daily_streak_dao_test.dart` + `daily_checkins_dao_test.dart`

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/test/data/repositories/pause_event_repository_test.dart`

**In-memory Drift setup** (analog lines 14-39):
```dart
late AppDatabase db;
late PauseEventRepository repo;
late int blockListEntryId;

setUp(() async {
  db = AppDatabase(NativeDatabase.memory());
  final dao = PauseEventDao(db);
  repo = PauseEventRepository(dao);

  // Insert a FK target row into block_list.
  blockListEntryId = await db.into(db.blockList).insert(
        BlockListCompanion.insert(
          kind: 0,
          packageName: const Value('com.instagram.android'),
          displayName: 'Instagram',
          createdAt: DateTime.utc(2026, 5, 10, 9),
          updatedAt: DateTime.utc(2026, 5, 10, 9),
        ),
      );
});

tearDown(() async { await db.close(); });
```

**Insert + query pattern** (analog lines 41-77):
```dart
test('upsertOutcome with outcome=0 writes a cooldown-completed row', () async {
  final id = await repo.insertOutcome(entryId: ..., outcome: 0, ...);
  expect(id, isPositive);
  final rows = await db.select(db.pauseEvents).get();
  expect(rows, hasLength(1));
  expect(rows.first.outcome, 0);
});
```

**Replication notes:**
- `daily_streak_dao_test.dart` must cover STRK-01: `upsert(entryId=A, day=D)` + second `upsert(entryId=A, day=D)` → 1 row (composite unique constraint honored). Repeat for `(entryId=B, day=D)` → 2 rows (different entries).
- `daily_checkins_dao_test.dart` covers STRK-03: same upsert idempotency, plus boolean `avoided` round-trip.
- Use `DateTime.utc(...)` and `Value(...)` per analog.

---

### `test/domain/streak/streak_rollover_service_test.dart`

**Analog (composite):** `test/data/repositories/pause_event_repository_test.dart` (in-memory Drift) + `test/_fixtures/permission_status_mock.dart` (mock the Pigeon API for `bootMonotonicNanos`).

**Mock factory pattern** (analog `permission_status_mock.dart` lines 10-27):
```dart
MockPermissionStatusApi buildMockPermissionStatusApi({
  bool usageAccess = false,
  // ...
  String fingerprint = 'fp-test',
}) {
  final m = MockPermissionStatusApi();
  when(() => m.isUsageAccessGranted()).thenAnswer((_) async => usageAccess);
  when(() => m.isAccessibilityServiceEnabled()).thenAnswer((_) async => accessibility);
  // ...
  return m;
}
```

**Replication for `test/_fixtures/streak_fixture.dart`:**
```dart
MockPermissionStatusApi buildClockMockApi({
  int bootMonotonicNanos = 0,
}) {
  final m = MockPermissionStatusApi();
  when(() => m.bootMonotonicNanos()).thenAnswer((_) async => bootMonotonicNanos);
  return m;
}
```

**Test coverage** (RESEARCH §9 Wave 0):
- `test_breaks_when_usage_exceeds_threshold` → seed `daily_usage_summary.foregroundSeconds = 6 * 60` against threshold 5min → assert streak `status=1`.
- `test_source_resolution_matrix` → drive the 2x2 matrix from RESEARCH §4 `_resolveDay`; one test per cell.
- `test_clock_tamper_flags_status_2` → mock `bootMonotonicNanos()` to return a value that disagrees with `DateTime.now()` by > 24h → assert all written rows have `status=2`.
- `test_scheduled_window_anchoring` → seed entry with `scheduleStartMinutes=22*60, scheduleEndMinutes=6*60` (cross-midnight) → usage on the start day → streak row keyed on start day.

---

### `test/domain/streak/streak_rollover_dst_test.dart`

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/test/domain/schedule/schedule_window_parity_test.dart` — DST GROUP 5 (lines 436-448).

**DST tuple pattern** (analog lines 436-447):
```dart
// Spring forward 2026-03-08 (Sunday)
_Tuple(now: DateTime(2026, 3, 8, 1, 30), ..., expected: true, label: 'dst/spring-forward'),
// Fall back 2025-11-02 (Sunday)
_Tuple(now: DateTime(2025, 11, 2, 0, 30), ..., expected: true, label: 'dst/fall-back'),
```

**Replication notes:** seed `lastEvaluatedDay` 1 day before each DST date; call `rollover()`; assert the `cursor` walk lands on exactly the right calendar day (23h day for spring, 25h day for fall) — STRK-08 invariant. Use `DateTime(y, m, d + 1)` for cursor stepping (NOT `add(Duration)` — the test asserts the helper used the constructor form).

---

### `test/features/streak/streak_badge_test.dart`, `streak_history_section_test.dart`, `test/features/home/reminder_off_banner_test.dart`, `test/features/onboarding/post_notifications_earned_test.dart`

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/test/features/home/health_banner_test.dart`

**Router scaffold + ProviderScope override pattern** (analog lines 27-65):
```dart
Future<GoRouter> _pumpBanner(
  WidgetTester tester, {
  required PermissionHealth health,
  required MockPermissionStatusApi api,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => Scaffold(body: HealthCheckBanner(health: health))),
      GoRoute(path: '/onboarding/permissions/usage-access', builder: (_, __) => const Scaffold(body: Text('USAGE-ROUTE'))),
      // ...
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [permissionStatusApiProvider.overrideWithValue(api)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
```

**Verbatim-copy assertion pattern** (analog lines 89-93):
```dart
expect(find.text('Tracking is offline — tap to fix'), findsOneWidget);
```

**Replication notes:**
- `reminder_off_banner_test.dart` → expect `'Reminder is off — tap to fix'` (UI-SPEC copy lock).
- `streak_badge_test.dart` → expect `'🔥 3 · best 12'` (mock `streakBadgeProvider` to return `(3, 12)`).
- `streak_history_section_test.dart` → mock `streakHistoryProvider` to return a list of 30 `DailyStreakData` with mixed states; expect exactly N green/blue/red/grey dots; tap a grey one and `expect(find.byTooltip('Tracking was off this day'), findsOneWidget)`.

---

### `test/features/checkin/checkin_screen_test.dart`

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/test/features/pause/pause_screen_test.dart` — `Scaffold` + `Notifier` + child widgets harness pattern.

**Replication notes:** seed `pendingCheckinsTodayProvider` with 3 entries via override; tap `Yes` on 2, `No` on 1; tap `Save check-in`; expect Drift transaction wrote 3 rows. Idempotent re-mount: with same providers, expect already-answered `SegmentedButton.selected` reflects stored answer and is disabled. (UI-SPEC §Screen 1 idempotency lock line 177-178.)

---

### `test/policy/phase_5_invariants_test.dart`

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/test/policy/phase_4_invariants_test.dart`

**Pattern (entire file is the pattern):**
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5 source-policy invariants', () {
    test('NOTF-05: BootReceiver declared with BOOT_COMPLETED intent-filter', () {
      final src = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(src.contains('android:name=".receiver.BootReceiver"'), isTrue);
      expect(src.contains('android.intent.action.BOOT_COMPLETED'), isTrue);
    });
    test('PLAY: no USE_EXACT_ALARM permission (use SCHEDULE_EXACT_ALARM only)', () {
      final src = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(src.contains('USE_EXACT_ALARM'), isFalse);
    });
    test('no FCM / firebase imports', () {
      for (final entity in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
        final src = entity.readAsStringSync();
        expect(src.contains('firebase_messaging'), isFalse);
        expect(src.contains('FirebaseMessaging'), isFalse);
      }
    });
    test('STRK-05: no WorkManager periodic for streak rollover', () {
      for (final entity in Directory('android/app/src/main/kotlin').listSync(recursive: true).whereType<File>()) {
        if (!entity.path.endsWith('.kt')) continue;
        final src = entity.readAsStringSync();
        // Allow PeriodicWorkRequest elsewhere; forbid it ONLY in streak/ paths.
        if (entity.path.contains('streak')) {
          expect(src.contains('PeriodicWorkRequest'), isFalse);
        }
      }
    });
  });
}
```
- Mirrors the Phase 4 test structure exactly (PAUS-01, PAUS-08, T-02, T-03, REL-01).
- Also extend `test/policy/play_invariants_test.dart` (analog file) — add a new top-level test "PLAY-Phase5: no USE_EXACT_ALARM" and "PLAY-Phase5: notification body must not contain entry names" (V8 ASVS data-protection lock).

---

### `android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/StreakDayAnchoringTest.kt`

**Analog:** `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindowTest.kt`

**Pattern (lines 8-47):**
```kotlin
class ScheduleWindowTest {
    private val kMon = 0x01; private val kTue = 0x02; /* … */

    private fun ms(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance(TimeZone.getDefault())
        cal.set(year, month - 1, day, hour, minute, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    @Test fun allNullsReturnFalse() {
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), null, null, null))
    }
}
```

**Replication notes:** Phase 5's parity oracle covers `streakDayFor`-equivalent Kotlin logic IF the streak engine ever runs Kotlin-side. Per RESEARCH §2 the streak engine is Dart-only — but the cross-midnight day-anchoring (RESEARCH §4 STRK-09) is shared truth. Keep the Kotlin test as a guard: if a future Plan introduces a Kotlin streak path, the parity test prevents drift. Tuple set: cross-midnight 22:00 → 06:00, start day = Mon, test points at 23:00 Mon, 03:00 Tue → both should "belong to Mon's streak row" per D-08-domain.

---

## Shared Patterns (apply to multiple Phase 5 files)

### Hand-written Riverpod (no codegen)

**Source:** `lib/features/health/permission_health_provider.dart` lines 34-80, `lib/features/onboarding/providers/onboarding_cursor_provider.dart` lines 10-33, `lib/features/pause/providers/pause_providers.dart` lines 14-37, `lib/core/router/app_router.dart` lines 17-19 (the doc comment locks this).

**Apply to:** all Phase 5 providers (streak, checkin, reminder, post_notifications, notification_api).

**Rule:** Use `Provider<T>(...)`, `FutureProvider.autoDispose.family<T, K>((ref, k) { ... })`, `AsyncNotifierProvider<N, S>(N.new)`. NO `@riverpod` annotations. NO `*.g.dart` from riverpod_generator. (Drift `.g.dart` files are fine and still required for DAOs.)

---

### `WidgetsBindingObserver` for lazy-on-resume

**Source:** `lib/features/health/widgets/_health_lifecycle_observer.dart` lines 26-52, `lib/features/onboarding/pages/usage_access_step.dart` lines 20-44, `lib/features/dashboard/pages/dashboard_screen.dart` lines 30-55.

**Apply to:**
- streak rollover trigger (extend `HealthLifecycleObserver` with a third `unawaited(ref.read(streakRolloverServiceProvider).rollover())`)
- post-notifications status refresh on Settings round-trip
- reminder-off banner re-evaluate on resume

**Rule:** `addObserver` in `initState` MUST pair with `removeObserver` in `dispose`. Idempotent `refresh()` — multiple spurious resumes (lock-screen) must be no-op (`5-min soft-cache` D-12 pattern from Phase 3).

---

### Pigeon try/catch surface

**Source:** `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApiImpl.kt` lines 29-65.

**Apply to:** `NotificationApiImpl.kt` (new), `PermissionStatusApiImpl.kt` (modified — 4 new methods).

**Rule:** every Pigeon method wraps its body in `try { … callback(Result.success(…)) } catch (e: Throwable) { callback(Result.failure(e)) }`. Dart side surfaces failures via `try/catch` in the calling `await` site (e.g., `_openSettings()` in `usage_access_step.dart` lines 67-80 catches `on Object`).

---

### Settings deep-link with resolveActivity guard

**Source:** `android/.../PermissionStatusApiImpl.kt` lines 104-129 `launchSettingsOrFallback(...)`.

**Apply to:** `openAppNotificationSettings()` in NotificationApiImpl OR PermissionStatusApiImpl (T-2-02 mitigation pattern).

**Rule:** `intent.resolveActivity(pm) != null` guard before `startActivity`. Fallback to `ACTION_APPLICATION_DETAILS_SETTINGS` with `package:com.nottodo.not_to_do_list` Uri if the primary action doesn't resolve.

---

### Verbatim copy assertion in widget tests

**Source:** `test/features/home/health_banner_test.dart` lines 89-92, 119, 156-157, 224-227.

**Apply to:** every Phase 5 widget test that asserts a UI-SPEC copy-lock string.

**Rule:** `expect(find.text('exact UI-SPEC string'), findsOneWidget)`. Pull the string from the UI-SPEC §Copywriting Contract (lines 314-337). NEVER paraphrase — the test is the lock that prevents drift.

---

### Material+InkWell amber-banner identity

**Source:** `lib/features/health/widgets/health_check_banner.dart` lines 28-101.

**Apply to:** `reminder_off_banner.dart` (NOTF-07).

**Rule:** identical token list (`0xFFFFF3CD / 0xFF856404 / 0xFF3D2E00 / 0xFFFFD966`); `bodyMedium` w500 foreground text; 16px horizontal / 8px vertical padding; ALWAYS wrap in `Material(color: bg)` to get Ink ripple on top of explicit color (do NOT use `Container(color: bg)` — Ink ink-painting requires a `Material` ancestor to clip).

---

## New Patterns Introduced by Phase 5

These have NO analog in the existing codebase and the planner must consult RESEARCH §5 + Android docs directly:

### `ReminderAlarmReceiver` (Kotlin `BroadcastReceiver`)

**Why new:** no `BroadcastReceiver` exists in Phase 1-4 (the AccessibilityService is a `Service`, the broadcaster is just `LocalBroadcastManager.sendBroadcast`).

**Source for the pattern:** RESEARCH §5 lines 459-518 (full skeleton given).

**Critical specifics:**
- `setExactAndAllowWhileIdle` is one-shot: receiver MUST re-arm itself at the end of `onReceive` (RESEARCH §5 lines 471-484).
- Android 12+ `canScheduleExactAlarms()` check before re-arming — fall back to `setAndAllowWhileIdle` on revoke (R-2 in RESEARCH §10).
- Notification channel created in-line (`NotificationChannel(CHANNEL_ID, "Daily check-in", IMPORTANCE_DEFAULT)`); creating an existing channel is a no-op.
- `PendingIntent.FLAG_IMMUTABLE or FLAG_UPDATE_CURRENT` — required since Android 12.
- Notification copy: `setContentTitle("Daily check-in") .setContentText("How did today go?")` — UI-SPEC copy lock lines 333-334.
- Deep-link via `Intent(ctx, MainActivity::class.java).putExtra("deep_link_to", "/checkin")`.

### `BootReceiver` (Kotlin `BroadcastReceiver` for `BOOT_COMPLETED`)

**Why new:** no boot-listener exists.

**Source:** RESEARCH §5 lines 524-541 (full skeleton).

**Critical specifics:**
- Must read `flutter.reminder_hour_minute` from `FlutterSharedPreferences` file (RESEARCH §10 R-9 — this is the highest-risk landmine of Phase 5; verify with Wave 0 parity test).
- Both `ACTION_BOOT_COMPLETED` and `ACTION_LOCKED_BOOT_COMPLETED` actions in the intent-filter (RESEARCH §5 manifest block lines 547-557).
- Receiver `android:exported="true"` (must accept the system's BOOT_COMPLETED broadcast — V4 ASVS access-control lock).
- Receiver guard: `if (intent.action != Intent.ACTION_BOOT_COMPLETED && intent.action != Intent.ACTION_LOCKED_BOOT_COMPLETED) return;` — V5 input validation.

### `MainActivity.onNewIntent` deep-link parser

**Why new:** Phase 4 introduced `PauseActivity` with route params, but `MainActivity` itself has no `onNewIntent` override yet.

**Source:** RESEARCH §5 line 559 + V5 ASVS validation rule:
- Extract `intent.getStringExtra("deep_link_to")`.
- Validate against allow-list `{"/checkin"}` only — reject all other values (V5 lock).
- Use a Pigeon callback or write `pending_deep_link` to `SharedPreferences` and have `HomeScreen.initState` consume + clear (RESEARCH §5 line 559 — simpler alternative).

### `AlarmManager.setExactAndAllowWhileIdle` invocation site

**Why new:** v1 has no alarm scheduling. RESEARCH §5 lines 395-454 provides the full skeleton including `canScheduleExactAlarms()` guard, `computeNextOccurrenceMs(h, m)` helper, and persistence to `FlutterSharedPreferences`.

---

## No Analog Found

Files with NO close existing match in the codebase. Planner consults RESEARCH §5–§6 directly:

| File | Role | Reason no analog |
|------|------|------------------|
| `ReminderAlarmReceiver.kt` | BroadcastReceiver | No `BroadcastReceiver` skeleton exists; the only Phase 4 broadcast is `LocalBroadcastManager.sendBroadcast` (not a receiver). RESEARCH §5 provides the full pattern. |
| `BootReceiver.kt` | BroadcastReceiver | Same — no boot-listener exists. RESEARCH §5 provides the full pattern. |
| `MainActivity.onNewIntent` override | platform | `PauseActivity` has extras parsing (Plan 04-06 PauseActivity.kt), but `MainActivity` does not — first Phase 5 use. |

For these three, the planner consults RESEARCH §5 lines 460-557 verbatim. The implementation is small (~80 lines of Kotlin total across the three) and the RESEARCH-provided skeleton can be copied directly.

---

## Metadata

**Analog search scope:**
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/**` (all Dart sources)
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/**` (all Kotlin sources)
- `/Users/jintanakhomwong/projects/not-to-do-list/pigeons/**` (Pigeon API definitions)
- `/Users/jintanakhomwong/projects/not-to-do-list/test/**` (all Dart tests)
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/test/kotlin/**` (JVM tests)

**Files scanned:** 64 (Dart 45, Kotlin 9, Pigeon 5, manifest 1, tests 4 read-deep + many listed-only)

**Pattern extraction date:** 2026-05-21

**Cross-references for the planner:**
- RESEARCH §4 → algorithm pseudocode for `streak_rollover_service.dart`
- RESEARCH §5 → full Kotlin skeletons for `NotificationApiImpl.kt`, `ReminderAlarmReceiver.kt`, `BootReceiver.kt`
- RESEARCH §6 → POST_NOTIFICATIONS earned-prompt flow + 3-state UX
- RESEARCH §7 → `/checkin` Riverpod providers + submit transaction
- RESEARCH §8 → 5 required providers + copy-lock table + day-dot colors
- RESEARCH §9 → 15 test files in Wave 0 with explicit test-name lock
- RESEARCH §10 → 10 risks; planner must mention R-3 (Xiaomi BootReceiver kill) and R-9 (FlutterSharedPreferences cross-process) in plan acceptance criteria
- RESEARCH §11 → 9-plan execution order across 4 waves; planner follows verbatim
- UI-SPEC §Copywriting Contract → every visible string is locked

## PATTERN MAPPING COMPLETE
38 Phase 5 files mapped to 22 distinct analog files; 3 BroadcastReceiver/onNewIntent skeletons identified as new-to-codebase and routed to RESEARCH §5 for the planner.
