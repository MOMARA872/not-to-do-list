// Plan 05-07 — ReminderOffBanner widget tests (GREEN).
//
// Covers: NOTF-07 (in-app banner when POST_NOTIFICATIONS denied),
//         UI-SPEC copy ("Reminder is off — tap to fix"),
//         tap behavior (permanently_denied → openAppNotificationSettings;
//                       rationale → /onboarding/permissions/notifications).
//
// Copy locked from 05-UI-SPEC.md §Copywriting Contract — no paraphrase.
// Harness mirrors test/features/home/health_banner_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/post_notifications_provider.dart';
import 'package:not_to_do_list/features/reminder/widgets/reminder_off_banner.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';

import '../../_fixtures/permission_status_mock.dart';

/// Mock that adds the Plan 05-04 notification methods.
class _MockPermissionStatusApiWithNotif extends MockPermissionStatusApi {}

/// Build a mock that stubs the Plan 05-04 notification methods.
_MockPermissionStatusApiWithNotif _buildNotifMock({
  required String rationaleState,
  bool postGranted = false,
}) {
  final m = _MockPermissionStatusApiWithNotif();
  // Existing methods.
  when(() => m.isUsageAccessGranted()).thenAnswer((_) async => true);
  when(() => m.isAccessibilityServiceEnabled()).thenAnswer((_) async => true);
  when(() => m.isIgnoringBatteryOptimizations()).thenAnswer((_) async => true);
  when(() => m.currentBuildFingerprint()).thenAnswer((_) async => 'fp-test');
  when(() => m.currentManufacturer()).thenAnswer((_) async => 'pixel');
  when(() => m.openUsageAccessSettings()).thenAnswer((_) async {});
  when(() => m.openAccessibilitySettings()).thenAnswer((_) async {});
  when(() => m.openBatteryOptSettings()).thenAnswer((_) async {});
  // Plan 05-04 notification methods.
  when(
    () => m.isPostNotificationsGranted(),
  ).thenAnswer((_) async => postGranted);
  when(
    () => m.postNotificationsRationaleState(),
  ).thenAnswer((_) async => rationaleState);
  when(
    () => m.openAppNotificationSettings(),
  ).thenAnswer((_) async {});
  when(
    () => m.requestPostNotifications(),
  ).thenAnswer((_) async => postGranted);
  return m;
}

/// Pump [ReminderOffBanner] inside a ProviderScope + GoRouter scaffold.
///
/// The banner is rendered inside a simple Scaffold body.
/// [postGranted] controls whether the banner is visible on Home.
Future<GoRouter> _pumpBanner(
  WidgetTester tester, {
  required _MockPermissionStatusApiWithNotif api,
  required bool postGranted,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: ReminderOffBanner()),
      ),
      GoRoute(
        path: '/onboarding/permissions/notifications',
        builder: (_, __) => const Scaffold(body: Text('NOTIF-ROUTE')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        permissionStatusApiProvider.overrideWithValue(api),
        postNotificationsGrantedProvider.overrideWith(
          () => _FakeNotifier(postGranted),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Minimal fake notifier for postNotificationsGrantedProvider.
class _FakeNotifier extends AsyncNotifier<bool>
    implements PostNotificationsGrantedNotifier {
  _FakeNotifier(this._value);
  final bool _value;

  @override
  Future<bool> build() async => _value;

  @override
  Future<void> refresh() async {}
}

void main() {
  group(
    'ReminderOffBanner visible when isPostNotificationsGranted=false '
    '(NOTF-07) — test_banner_visible_when_denied',
    () {
      testWidgets(
        'test_banner_visible_when_denied: '
        'banner is visible when POST_NOTIFICATIONS not granted',
        (tester) async {
          final api = _buildNotifMock(
            rationaleState: 'grantable',
            postGranted: false,
          );
          await _pumpBanner(tester, api: api, postGranted: false);
          expect(find.byType(ReminderOffBanner), findsOneWidget);
        },
      );
    },
  );

  group(
    'ReminderOffBanner hidden when isPostNotificationsGranted=true '
    '(NOTF-07) — test_banner_hidden_when_granted',
    () {
      testWidgets(
        'test_banner_hidden_when_granted: '
        'banner is not rendered when POST_NOTIFICATIONS is granted',
        (tester) async {
          // When granted=true, HomeScreen does not mount ReminderOffBanner.
          // This test verifies the banner itself exists but is absent when
          // the home screen does not render it.
          // We verify by overriding the provider to granted=true in a Home-like
          // scaffold that conditionally mounts the banner.
          final api = _buildNotifMock(
            rationaleState: 'grantable',
            postGranted: true,
          );
          final router = GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => Consumer(
                  builder: (ctx, ref, __) {
                    final granted =
                        ref.watch(postNotificationsGrantedProvider);
                    return Scaffold(
                      body: granted.maybeWhen(
                        data: (g) =>
                            g ? const Text('NO-BANNER') : const ReminderOffBanner(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                permissionStatusApiProvider.overrideWithValue(api),
                postNotificationsGrantedProvider.overrideWith(
                  () => _FakeNotifier(true),
                ),
              ],
              child: MaterialApp.router(routerConfig: router),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ReminderOffBanner), findsNothing);
          expect(find.text('NO-BANNER'), findsOneWidget);
        },
      );
    },
  );

  group(
    'ReminderOffBanner copy exact "Reminder is off — tap to fix" '
    '(UI-SPEC copy lock)',
    () {
      testWidgets(
        'banner renders verbatim "Reminder is off — tap to fix"',
        (tester) async {
          final api = _buildNotifMock(rationaleState: 'grantable');
          await _pumpBanner(tester, api: api, postGranted: false);
          expect(find.text('Reminder is off — tap to fix'), findsOneWidget);
        },
      );
    },
  );

  group(
    'ReminderOffBanner tap on permanently_denied → openAppNotificationSettings; '
    'on rationale → /onboarding/permissions/notifications',
    () {
      testWidgets(
        'tap when permanently_denied calls openAppNotificationSettings',
        (tester) async {
          final api = _buildNotifMock(
            rationaleState: 'permanently_denied',
            postGranted: false,
          );
          await _pumpBanner(tester, api: api, postGranted: false);
          await tester.tap(find.text('Reminder is off — tap to fix'));
          await tester.pumpAndSettle();
          verify(() => api.openAppNotificationSettings()).called(1);
        },
      );

      testWidgets(
        'tap when rationale available routes to /onboarding/permissions/notifications',
        (tester) async {
          final api = _buildNotifMock(
            rationaleState: 'rationale',
            postGranted: false,
          );
          final router = await _pumpBanner(tester, api: api, postGranted: false);
          await tester.tap(find.text('Reminder is off — tap to fix'));
          await tester.pumpAndSettle();
          expect(find.text('NOTIF-ROUTE'), findsOneWidget);
          expect(
            router.routerDelegate.currentConfiguration.fullPath,
            '/onboarding/permissions/notifications',
          );
        },
      );
    },
  );
}
