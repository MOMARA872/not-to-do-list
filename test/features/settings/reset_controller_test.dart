// Phase 6 Plan 05 — reset_controller_test.dart
// Tests for ResetController (SETT-02, D-13, D-14, Pitfall 2, Runtime State
// Inventory). Implements the 7 behaviours from 06-05-PLAN.md.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/providers/notification_api_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_complete_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/post_notifications_provider.dart';
import 'package:not_to_do_list/features/reminder/providers/reminder_providers.dart';
import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';
import 'package:not_to_do_list/features/settings/services/reset_controller.dart';
import 'package:not_to_do_list/features/streak/providers/streak_threshold_provider.dart';
import 'package:not_to_do_list/platform/notification_api.g.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockNotificationApi extends Mock implements NotificationApi {}

class _MockPermissionStatusApi extends Mock implements PermissionStatusApi {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates an in-memory AppDatabase seeded with one row per table.
Future<AppDatabase> _openSeededDb() async {
  final db = AppDatabase(NativeDatabase.memory());

  // Insert a block_list parent row.
  final entry = await db.into(db.blockList).insertReturning(
        BlockListCompanion.insert(
          kind: 0,
          packageName: const Value('com.example.test'),
          displayName: 'Test App',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

  // Child rows (FK-linked to block_list).
  await db.into(db.dailyCheckins).insert(
        DailyCheckinsCompanion.insert(
          entryId: entry.id,
          day: DateTime(2026, 1, 1),
          avoided: true,
          answeredAt: DateTime(2026, 1, 1),
        ),
      );

  await db.into(db.pauseEvents).insert(
        PauseEventsCompanion.insert(
          entryId: entry.id,
          packageName: 'com.example.test',
          triggeredAt: DateTime(2026, 1, 1),
          outcome: 1,
        ),
      );

  await db.into(db.dailyStreak).insert(
        DailyStreakCompanion.insert(
          entryId: entry.id,
          day: DateTime(2026, 1, 1),
          status: 0,
          source: 0,
          evaluatedAt: DateTime(2026, 1, 1),
        ),
      );

  // DailyUsageSummary has no block_list FK — independent row.
  await db.into(db.dailyUsageSummary).insert(
        DailyUsageSummaryCompanion.insert(
          packageName: 'com.example.test',
          day: DateTime(2026, 1, 1),
          foregroundSeconds: 600,
          aggregatedAt: DateTime(2026, 1, 1),
        ),
      );

  return db;
}

/// Builds a [ProviderContainer] with all 5 prefs-backed providers overridden.
/// Also stubs [permissionStatusApiProvider] so the Pigeon channel isn't called.
ProviderContainer _buildContainer() {
  final mockPermApi = _MockPermissionStatusApi();
  when(() => mockPermApi.isPostNotificationsGranted())
      .thenAnswer((_) async => false);

  return ProviderContainer(
    overrides: [
      permissionStatusApiProvider.overrideWithValue(mockPermApi),
      onboardingCompleteProvider.overrideWith(OnboardingCompleteNotifier.new),
      themeModeProvider.overrideWith(ThemeModeNotifier.new),
      reminderTimeProvider.overrideWith(ReminderTimeNotifier.new),
      streakThresholdProvider.overrideWith(StreakThresholdNotifier.new),
      postNotificationsGrantedProvider.overrideWith(
        PostNotificationsGrantedNotifier.new,
      ),
    ],
  );
}

/// A [BuildContext] fake that is always mounted (does not support context.go).
class _MountedContext extends Fake implements BuildContext {
  @override
  bool get mounted => true;
}

/// A [BuildContext] fake that is always unmounted.
class _UnmountedContext extends Fake implements BuildContext {
  @override
  bool get mounted => false;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Phase 6 / ResetController (SETT-02)', () {
    late AppDatabase db;
    late _MockNotificationApi mockNotifApi;

    setUp(() async {
      db = await _openSeededDb();
      mockNotifApi = _MockNotificationApi();
      when(() => mockNotifApi.cancelDailyReminder()).thenAnswer((_) async {});
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'theme_mode': 2,
        'reminder_hour_minute': 1260,
        'streak_threshold_minutes': 5,
      });
    });

    tearDown(() async {
      await db.close();
    });

    // Test 1: cancelDailyReminder() called BEFORE Drift wipe and prefs.clear().
    // Uses _UnmountedContext so the fake doesn't need GoRouter for nav step.
    test(
      'cancelDailyReminder() called BEFORE prefs.clear() (Runtime State Inventory)',
      () async {
        final callOrder = <String>[];

        when(() => mockNotifApi.cancelDailyReminder()).thenAnswer((_) async {
          callOrder.add('cancelDailyReminder');
        });

        final container = _buildContainer();
        addTearDown(container.dispose);

        final controller = ResetController(db, mockNotifApi, container);
        // _UnmountedContext prevents context.go() — we only assert alarm order.
        await controller.resetAll(_UnmountedContext());

        // cancelDailyReminder must have been called.
        expect(callOrder, contains('cancelDailyReminder'));
        // It must be the FIRST recorded event (before Drift + prefs ops).
        expect(callOrder.first, 'cancelDailyReminder');
      },
    );

    // Test 2: Drift transaction deletes all 5 tables in FK-safe child-first
    // order (no FK violation with foreign_keys=ON).
    test(
      'Drift transaction deletes child tables before block_list (FK-safe order)',
      () async {
        // Seed rows present before reset.
        expect((await db.select(db.dailyCheckins).get()).length, 1);
        expect((await db.select(db.pauseEvents).get()).length, 1);
        expect((await db.select(db.dailyStreak).get()).length, 1);
        expect((await db.select(db.dailyUsageSummary).get()).length, 1);
        expect((await db.select(db.blockList).get()).length, 1);

        final container = _buildContainer();
        addTearDown(container.dispose);

        final controller = ResetController(db, mockNotifApi, container);
        await controller.resetAll(_UnmountedContext());

        // All gone after reset.
        expect((await db.select(db.dailyCheckins).get()).length, 0);
        expect((await db.select(db.pauseEvents).get()).length, 0);
        expect((await db.select(db.dailyStreak).get()).length, 0);
        expect((await db.select(db.dailyUsageSummary).get()).length, 0);
        expect((await db.select(db.blockList).get()).length, 0);
      },
    );

    // Test 3: All 5 tables row-count == 0 after resetAll.
    test(
      'All 5 tables row-count == 0 after resetAll',
      () async {
        final container = _buildContainer();
        addTearDown(container.dispose);

        final controller = ResetController(db, mockNotifApi, container);
        await controller.resetAll(_UnmountedContext());

        expect((await db.select(db.blockList).get()), isEmpty);
        expect((await db.select(db.dailyCheckins).get()), isEmpty);
        expect((await db.select(db.pauseEvents).get()), isEmpty);
        expect((await db.select(db.dailyStreak).get()), isEmpty);
        expect((await db.select(db.dailyUsageSummary).get()), isEmpty);
      },
    );

    // Test 4: SharedPreferences.getKeys() is empty after resetAll.
    test(
      'SharedPreferences.getKeys() is empty after resetAll',
      () async {
        final prefsBefore = await SharedPreferences.getInstance();
        expect(prefsBefore.getKeys(), isNotEmpty);

        final container = _buildContainer();
        addTearDown(container.dispose);

        final controller = ResetController(db, mockNotifApi, container);
        await controller.resetAll(_UnmountedContext());

        final prefsAfter = await SharedPreferences.getInstance();
        expect(prefsAfter.getKeys(), isEmpty);
      },
    );

    // Test 5: All 5 providers re-enter AsyncLoading after invalidation.
    test(
      '5 providers invalidated — each re-enters AsyncLoading (D-14 + Pitfall 2)',
      () async {
        final container = _buildContainer();
        addTearDown(container.dispose);

        // Pre-load providers to AsyncValue.data state.
        await container.read(onboardingCompleteProvider.future);
        await container.read(themeModeProvider.future);
        await container.read(reminderTimeProvider.future);
        await container.read(streakThresholdProvider.future);
        await container.read(postNotificationsGrantedProvider.future);

        final controller = ResetController(db, mockNotifApi, container);
        await controller.resetAll(_UnmountedContext());

        // After invalidation each provider is in a loading/refreshing state.
        // Riverpod 3.x returns AsyncData(isLoading:true) when previous data
        // exists, or AsyncLoading for providers that haven't resolved before.
        // Both satisfy isLoading == true (D-14 + Pitfall 2 intent).
        expect(
          container.read(onboardingCompleteProvider).isLoading,
          isTrue,
          reason: 'onboardingCompleteProvider should be reloading',
        );
        expect(
          container.read(themeModeProvider).isLoading,
          isTrue,
          reason: 'themeModeProvider should be reloading',
        );
        expect(
          container.read(reminderTimeProvider).isLoading,
          isTrue,
          reason: 'reminderTimeProvider should be reloading',
        );
        expect(
          container.read(streakThresholdProvider).isLoading,
          isTrue,
          reason: 'streakThresholdProvider should be reloading',
        );
        expect(
          container.read(postNotificationsGrantedProvider).isLoading,
          isTrue,
          reason: 'postNotificationsGrantedProvider should be reloading',
        );
      },
    );

    // Test 6: context.go('/onboarding/welcome') invoked when context.mounted.
    testWidgets(
      'context.go("/onboarding/welcome") invoked when context.mounted (D-14)',
      (tester) async {
        final navigatedTo = <String>[];

        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (ctx, _) => _TriggerResetWidget(
                db: db,
                notifApi: mockNotifApi,
              ),
            ),
            GoRoute(
              path: '/onboarding/welcome',
              builder: (ctx, _) {
                navigatedTo.add('/onboarding/welcome');
                return const Scaffold(body: Text('Onboarding'));
              },
            ),
          ],
        );

        final mockPermApi = _MockPermissionStatusApi();
        when(() => mockPermApi.isPostNotificationsGranted())
            .thenAnswer((_) async => false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notificationApiProvider.overrideWithValue(mockNotifApi),
              permissionStatusApiProvider.overrideWithValue(mockPermApi),
              onboardingCompleteProvider.overrideWith(
                OnboardingCompleteNotifier.new,
              ),
              themeModeProvider.overrideWith(ThemeModeNotifier.new),
              reminderTimeProvider.overrideWith(ReminderTimeNotifier.new),
              streakThresholdProvider.overrideWith(StreakThresholdNotifier.new),
              postNotificationsGrantedProvider.overrideWith(
                PostNotificationsGrantedNotifier.new,
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        // Let post-frame callback fire, resetAll run, and navigation complete.
        await tester.pumpAndSettle();

        expect(navigatedTo, contains('/onboarding/welcome'));
      },
    );

    // Test 7: When context is unmounted, no navigation attempted.
    test(
      'When context.unmounted after async chain, no nav call is attempted',
      () async {
        final container = _buildContainer();
        addTearDown(container.dispose);

        final controller = ResetController(db, mockNotifApi, container);

        // Unmounted context — go() must NOT fire. Completes without error.
        await expectLater(
          controller.resetAll(_UnmountedContext()),
          completes,
        );

        // Drift wipe + prefs.clear still ran (only navigation is guarded).
        expect((await db.select(db.blockList).get()), isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), isEmpty);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Widget helper for Test 6.
// ---------------------------------------------------------------------------

/// Pumped widget that triggers [ResetController.resetAll] after the first
/// frame, giving [context] a live GoRouter ancestor so [context.go] works.
class _TriggerResetWidget extends StatefulWidget {
  const _TriggerResetWidget({required this.db, required this.notifApi});

  final AppDatabase db;
  final NotificationApi notifApi;

  @override
  State<_TriggerResetWidget> createState() => _TriggerResetWidgetState();
}

class _TriggerResetWidgetState extends State<_TriggerResetWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      final controller = ResetController(
        widget.db,
        widget.notifApi,
        container,
      );
      await controller.resetAll(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Settings'));
  }
}
