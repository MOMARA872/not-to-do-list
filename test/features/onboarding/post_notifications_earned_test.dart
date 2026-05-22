// Plan 05-08 — POST_NOTIFICATIONS earned-prompt tests (fills Wave 0 RED stubs).
//
// Covers: NOTF-06 (earned prompt fires on first not-to-do entry add),
//         fire-once (suppressed after StreakKeys.earnedPromptShown=true),
//         rationale screen body copy from RESEARCH §6,
//         T-05-16 (resumed re-check detects late grant).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/core/router/pending_nav_request_provider.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/pages/post_notifications_earned_step.dart';
import 'package:not_to_do_list/features/onboarding/providers/post_notifications_provider.dart';
import 'package:not_to_do_list/features/streak/storage/streak_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/permission_status_mock.dart';

// ---------- Helpers ----------

/// Extended mock that includes Plan 05-04 notification methods.
class _MockPermApiWithNotif extends MockPermissionStatusApi {}

/// Build a mock PermissionStatusApi with notification methods stubbed.
_MockPermApiWithNotif _buildPermApi({bool postGranted = false}) {
  final m = _MockPermApiWithNotif();
  when(() => m.isUsageAccessGranted()).thenAnswer((_) async => true);
  when(
    () => m.isAccessibilityServiceEnabled(),
  ).thenAnswer((_) async => true);
  when(
    () => m.isIgnoringBatteryOptimizations(),
  ).thenAnswer((_) async => true);
  when(() => m.currentBuildFingerprint()).thenAnswer((_) async => 'fp');
  when(() => m.currentManufacturer()).thenAnswer((_) async => 'pixel');
  when(() => m.openUsageAccessSettings()).thenAnswer((_) async {});
  when(() => m.openAccessibilitySettings()).thenAnswer((_) async {});
  when(() => m.openBatteryOptSettings()).thenAnswer((_) async {});
  when(
    () => m.isPostNotificationsGranted(),
  ).thenAnswer((_) async => postGranted);
  when(
    () => m.postNotificationsRationaleState(),
  ).thenAnswer((_) async => 'grantable');
  when(
    () => m.openAppNotificationSettings(),
  ).thenAnswer((_) async {});
  when(
    () => m.requestPostNotifications(),
  ).thenAnswer((_) async => postGranted);
  return m;
}

/// Fake PostNotificationsGrantedNotifier for overrides.
class _FakeGrantedNotifier extends AsyncNotifier<bool>
    implements PostNotificationsGrantedNotifier {
  _FakeGrantedNotifier(this._value);
  final bool _value;

  @override
  Future<bool> build() async => _value;

  @override
  Future<void> refresh() async {}
}

/// Pump [PostNotificationsEarnedStep] in a [ProviderScope] + [GoRouter].
/// Uses MaterialApp.router so context.go('/') resolves correctly.
Future<void> _pumpEarnedStep(
  WidgetTester tester, {
  required _MockPermApiWithNotif api,
  bool postGranted = false,
}) async {
  final router = GoRouter(
    initialLocation: '/onboarding/permissions/notifications',
    routes: [
      GoRoute(
        path: '/onboarding/permissions/notifications',
        builder: (_, __) => const PostNotificationsEarnedStep(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        permissionStatusApiProvider.overrideWithValue(api),
        postNotificationsGrantedProvider.overrideWith(
          () => _FakeGrantedNotifier(postGranted),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// Build an in-memory [BlockListRepository] with the earned-prompt callback
/// wired to the given [container]'s [pendingNavRequestProvider].
BlockListRepository _buildRepo({
  required AppDatabase db,
  required ProviderContainer container,
  required _MockPermApiWithNotif api,
}) {
  return BlockListRepository(
    BlockListDao(db),
    null, // broadcaster not needed for these tests
    (route) async {
      container.read(pendingNavRequestProvider.notifier).state = route;
    },
    () => api.isPostNotificationsGranted(),
  );
}

// ---------- Tests ----------

void main() {
  group(
    'earned prompt fires on first block_list insert '
    '(NOTF-06) — test_prompt_fires_on_first_insert',
    () {
      testWidgets(
        'test_prompt_fires_on_first_insert: '
        'pendingNavRequest set to /onboarding/permissions/notifications '
        'after first entry inserted with earnedPromptShown=false and '
        'isPostNotificationsGranted=false',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final api = _buildPermApi(postGranted: false);
          final db = AppDatabase(NativeDatabase.memory());
          final container = ProviderContainer(
            overrides: [
              permissionStatusApiProvider.overrideWithValue(api),
            ],
          );
          addTearDown(() async {
            container.dispose();
            await db.close();
          });

          final repo = _buildRepo(db: db, container: container, api: api);
          await repo.add(kind: 1, displayName: 'Test habit');

          final pending = container.read(pendingNavRequestProvider);
          expect(pending, '/onboarding/permissions/notifications');

          // Second insert must NOT re-fire (earnedPromptShown=true now).
          container.read(pendingNavRequestProvider.notifier).state = null;
          await repo.add(kind: 1, displayName: 'Second habit');
          expect(container.read(pendingNavRequestProvider), isNull);
        },
      );
    },
  );

  group(
    'earned prompt suppressed after StreakKeys.earnedPromptShown=true '
    '(NOTF-06 fire-once)',
    () {
      testWidgets(
        'rationale not shown when earnedPromptShown=true in prefs',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            StreakKeys.earnedPromptShown: true,
          });
          final api = _buildPermApi(postGranted: false);
          final db = AppDatabase(NativeDatabase.memory());
          final container = ProviderContainer(
            overrides: [
              permissionStatusApiProvider.overrideWithValue(api),
            ],
          );
          addTearDown(() async {
            container.dispose();
            await db.close();
          });

          final repo = _buildRepo(db: db, container: container, api: api);
          await repo.add(kind: 1, displayName: 'Test habit');

          expect(container.read(pendingNavRequestProvider), isNull);
        },
      );

      testWidgets(
        'earnedPromptShown set to true after prompt is shown once',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final api = _buildPermApi(postGranted: false);
          final db = AppDatabase(NativeDatabase.memory());
          final container = ProviderContainer(
            overrides: [
              permissionStatusApiProvider.overrideWithValue(api),
            ],
          );
          addTearDown(() async {
            container.dispose();
            await db.close();
          });

          final repo = _buildRepo(db: db, container: container, api: api);
          await repo.add(kind: 1, displayName: 'Test habit');

          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool(StreakKeys.earnedPromptShown), isTrue);
        },
      );
    },
  );

  group('rationale screen body matches RESEARCH §6 copy verbatim', () {
    testWidgets(
      'rationale screen renders verbatim copy from RESEARCH §6',
      (tester) async {
        final api = _buildPermApi();
        await _pumpEarnedStep(tester, api: api);
        expect(
          find.textContaining(
            'Get a daily reminder to confirm your not-to-do list.',
          ),
          findsOneWidget,
        );
        expect(find.text('Continue'), findsOneWidget);
      },
    );
  });

  group('Continue button triggers requestPostNotifications + writes flag', () {
    testWidgets(
      'test_continue_button_triggers_request_and_writes_flag: '
      'tap Continue → api.requestPostNotifications called + '
      'prefs.earnedPromptShown=true',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final api = _buildPermApi(postGranted: false);
        await _pumpEarnedStep(tester, api: api);

        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        verify(() => api.requestPostNotifications()).called(1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(StreakKeys.earnedPromptShown), isTrue);
      },
    );
  });

  group(
    'resumed re-check handles late grant (T-05-16 mitigation)',
    () {
      testWidgets(
        'test_resumed_re_check_handles_late_grant: '
        'widget re-polls isPostNotificationsGranted on AppLifecycleState.resumed '
        'and writes earnedPromptShown=true when granted',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          // Initially not granted; becomes granted after resume.
          var granted = false;
          final api = _MockPermApiWithNotif();
          when(
            () => api.isPostNotificationsGranted(),
          ).thenAnswer((_) async => granted);
          when(
            () => api.requestPostNotifications(),
          ).thenAnswer((_) async => false);
          when(
            () => api.openAppNotificationSettings(),
          ).thenAnswer((_) async {});
          when(
            () => api.isUsageAccessGranted(),
          ).thenAnswer((_) async => true);
          when(
            () => api.isAccessibilityServiceEnabled(),
          ).thenAnswer((_) async => true);
          when(
            () => api.isIgnoringBatteryOptimizations(),
          ).thenAnswer((_) async => true);
          when(
            () => api.currentBuildFingerprint(),
          ).thenAnswer((_) async => 'fp');
          when(
            () => api.currentManufacturer(),
          ).thenAnswer((_) async => 'pixel');
          when(
            () => api.openUsageAccessSettings(),
          ).thenAnswer((_) async {});
          when(
            () => api.openAccessibilitySettings(),
          ).thenAnswer((_) async {});
          when(
            () => api.openBatteryOptSettings(),
          ).thenAnswer((_) async {});
          when(
            () => api.postNotificationsRationaleState(),
          ).thenAnswer((_) async => 'grantable');

          await _pumpEarnedStep(tester, api: api);
          // Rationale screen is showing.
          expect(find.textContaining('Get a daily reminder'), findsOneWidget);

          // Grant the permission.
          granted = true;
          // Simulate AppLifecycleState.resumed via binding.
          final binding = tester.binding;
          binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await tester.pumpAndSettle();

          // earnedPromptShown must be written (T-05-16 mitigation).
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool(StreakKeys.earnedPromptShown), isTrue);
        },
      );
    },
  );
}
