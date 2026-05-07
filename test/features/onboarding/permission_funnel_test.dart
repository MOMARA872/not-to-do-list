// Plan 02-08 implementation. (Wave 0 stub replaced.)
//
// Each step screen mounts, calls its permission check on init, and advances
// to the next route on grant. Skip routes also advance. BatteryOpt's
// completion path persists fingerprint + marks complete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/pages/accessibility_step.dart';
import 'package:not_to_do_list/features/onboarding/pages/battery_opt_step.dart';
import 'package:not_to_do_list/features/onboarding/pages/usage_access_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/permission_status_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp({
    required MockPermissionStatusApi mock,
    required String initialLocation,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home-arrived')),
        ),
        GoRoute(
          path: '/onboarding/permissions/usage-access',
          builder: (_, __) => const UsageAccessStep(),
        ),
        GoRoute(
          path: '/onboarding/permissions/accessibility',
          builder: (_, __) => const AccessibilityStep(),
        ),
        GoRoute(
          path: '/onboarding/permissions/battery-opt',
          builder: (_, __) => const BatteryOptStep(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        permissionStatusApiProvider.overrideWith((_) => mock),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('UsageAccessStep (ONBD-02, ONBD-03)', () {
    testWidgets(
        'mount with grant=true → auto-advances to '
        '/onboarding/permissions/accessibility', (tester) async {
      final mock = buildMockPermissionStatusApi(usageAccess: true);
      await tester.pumpWidget(
        buildApp(
          mock: mock,
          initialLocation: '/onboarding/permissions/usage-access',
        ),
      );
      await tester.pumpAndSettle();

      // Should land on the accessibility step (PLAY-06 disclosure visible).
      expect(find.text('Pause before you open blocked apps'), findsOneWidget);
    });

    testWidgets('mount with grant=false → stays on usage-access',
        (tester) async {
      final mock = buildMockPermissionStatusApi();
      await tester.pumpWidget(
        buildApp(
          mock: mock,
          initialLocation: '/onboarding/permissions/usage-access',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('See which apps you actually use'), findsOneWidget);
    });

    testWidgets('Skip → advances to accessibility step', (tester) async {
      final mock = buildMockPermissionStatusApi();
      await tester.pumpWidget(
        buildApp(
          mock: mock,
          initialLocation: '/onboarding/permissions/usage-access',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Pause before you open blocked apps'), findsOneWidget);
    });
  });

  group('AccessibilityStep (ONBD-02, ONBD-03, PLAY-06)', () {
    testWidgets('renders 3-paragraph PLAY-06 disclosure body',
        (tester) async {
      final mock = buildMockPermissionStatusApi();
      await tester.pumpWidget(
        buildApp(
          mock: mock,
          initialLocation: '/onboarding/permissions/accessibility',
        ),
      );
      await tester.pumpAndSettle();

      // The 5 verbatim phrases are present in the rendered text.
      expect(find.textContaining('package name'), findsOneWidget);
      expect(
        find.textContaining('only when a window-state-changed event fires'),
        findsOneWidget,
      );
      expect(find.textContaining('never reads your screen'), findsOneWidget);
      expect(
        find.textContaining('never sends anything off your device'),
        findsOneWidget,
      );
      expect(find.textContaining('disable this at any time'), findsOneWidget);
    });

    testWidgets('mount with grant=true → auto-advances to battery-opt',
        (tester) async {
      final mock = buildMockPermissionStatusApi(accessibility: true);
      await tester.pumpWidget(
        buildApp(
          mock: mock,
          initialLocation: '/onboarding/permissions/accessibility',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keep tracking running overnight'), findsOneWidget);
    });

    testWidgets('Skip → advances to battery-opt', (tester) async {
      final mock = buildMockPermissionStatusApi();
      await tester.pumpWidget(
        buildApp(
          mock: mock,
          initialLocation: '/onboarding/permissions/accessibility',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Keep tracking running overnight'), findsOneWidget);
    });
  });

  group('BatteryOptStep (ONBD-02, ONBD-03) — funnel completion', () {
    testWidgets(
        'mount with grant=true → persistCurrentFingerprint + markComplete '
        '+ routes to /', (tester) async {
      final mock = buildMockPermissionStatusApi(
        batteryOptExempt: true,
        fingerprint: 'fp-pixel-test',
      );
      await tester.pumpWidget(
        buildApp(
          mock: mock,
          initialLocation: '/onboarding/permissions/battery-opt',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('home-arrived'), findsOneWidget);
      // Side-effects: fingerprint baseline + onboarding_complete=true.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_known_fingerprint'), 'fp-pixel-test');
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });

    testWidgets(
        'Skip on final step → still completes onboarding + routes to /',
        (tester) async {
      final mock = buildMockPermissionStatusApi(fingerprint: 'fp-skip');
      await tester.pumpWidget(
        buildApp(
          mock: mock,
          initialLocation: '/onboarding/permissions/battery-opt',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('home-arrived'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
      expect(prefs.getString('last_known_fingerprint'), 'fp-skip');
    });
  });

  group('Lifecycle observer pairing (RESEARCH §Pitfall D)', () {
    testWidgets(
        'all 3 step screens add WidgetsBindingObserver in initState and '
        'remove in dispose without errors', (tester) async {
      final mock = buildMockPermissionStatusApi();
      // Mount → unmount → remount each step. If addObserver/removeObserver
      // are not paired, we get either a leak or a "used after dispose"
      // error from the Flutter framework.
      for (final loc in const [
        '/onboarding/permissions/usage-access',
        '/onboarding/permissions/accessibility',
        '/onboarding/permissions/battery-opt',
      ]) {
        await tester.pumpWidget(buildApp(mock: mock, initialLocation: loc));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  });
}
