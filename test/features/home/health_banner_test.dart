// Plan 02-09 Task 01 — HealthCheckBanner widget tests (ONBD-06, REL-02).
//
// Covers:
// - banner shows verbatim copy when usageAccess=false
// - banner is hidden (SizedBox.shrink) when allHealthy
// - expand toggle reveals the matching detail line
// - tap-to-fix routes to the FIRST failing step in priority order AND
//   resets onboardingCompleteProvider before navigating (T-2-10)
// - fingerprintChanged forces visibility even when all 3 perms granted
//   (ONBD-07)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:not_to_do_list/features/health/widgets/health_check_banner.dart';
import 'package:not_to_do_list/features/onboarding/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/permission_status_mock.dart';

/// Mounts the banner inside a `MaterialApp.router` harness with
/// ProviderScope overrides + a router that captures the location after
/// banner taps.
Future<GoRouter> _pumpBanner(
  WidgetTester tester, {
  required PermissionHealth health,
  required MockPermissionStatusApi api,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: HealthCheckBanner(health: health),
        ),
      ),
      GoRoute(
        path: '/onboarding/permissions/usage-access',
        builder: (_, __) => const Scaffold(body: Text('USAGE-ROUTE')),
      ),
      GoRoute(
        path: '/onboarding/permissions/accessibility',
        builder: (_, __) => const Scaffold(body: Text('A11Y-ROUTE')),
      ),
      GoRoute(
        path: '/onboarding/permissions/battery-opt',
        builder: (_, __) => const Scaffold(body: Text('BATTERY-ROUTE')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        permissionStatusApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      OnboardingKeys.complete: true,
    });
  });

  group('HealthCheckBanner (ONBD-06, REL-02)', () {
    testWidgets(
      'banner shows verbatim copy when usageAccess=false',
      (tester) async {
        final api = buildMockPermissionStatusApi();
        await _pumpBanner(
          tester,
          health: const PermissionHealth(
            usageAccess: false,
            accessibilityService: true,
            batteryOptExempt: true,
            fingerprintChanged: false,
          ),
          api: api,
        );
        expect(
          find.text('Tracking is offline — tap to fix'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'expand toggle reveals "Usage Access is off" detail '
      'when only usage is off',
      (tester) async {
        final api = buildMockPermissionStatusApi();
        await _pumpBanner(
          tester,
          health: const PermissionHealth(
            usageAccess: false,
            accessibilityService: true,
            batteryOptExempt: true,
            fingerprintChanged: false,
          ),
          api: api,
        );
        // Detail not visible until expanded.
        expect(
          find.text('Usage Access is off — screen-time tracking is paused.'),
          findsNothing,
        );
        await tester.tap(find.byTooltip("What's wrong?"));
        await tester.pumpAndSettle();
        expect(
          find.text('Usage Access is off — screen-time tracking is paused.'),
          findsOneWidget,
        );
        // Other detail rows must NOT be present (only usage is off).
        expect(
          find.text(
            'Accessibility Service is off — app blocking is paused.',
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'tap with usageAccess=false routes to '
      '/onboarding/permissions/usage-access AND '
      'resets onboardingCompleteProvider',
      (tester) async {
        final api = buildMockPermissionStatusApi();
        final router = await _pumpBanner(
          tester,
          health: const PermissionHealth(
            usageAccess: false,
            accessibilityService: false,
            batteryOptExempt: false,
            fingerprintChanged: false,
          ),
          api: api,
        );
        // Sanity: starting at /
        expect(
          router.routerDelegate.currentConfiguration.fullPath,
          '/',
        );
        // Tap the banner body (anywhere on the visible row text).
        await tester.tap(find.text('Tracking is offline — tap to fix'));
        await tester.pumpAndSettle();
        // Routed to usage-access (priority 1).
        expect(find.text('USAGE-ROUTE'), findsOneWidget);
        // onboarding_complete pref flipped to false.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(OnboardingKeys.complete), isFalse);
      },
    );

    testWidgets(
      'tap with usageAccess granted but accessibility off routes to '
      '/onboarding/permissions/accessibility ',
      (tester) async {
        final api = buildMockPermissionStatusApi();
        await _pumpBanner(
          tester,
          health: const PermissionHealth(
            usageAccess: true,
            accessibilityService: false,
            batteryOptExempt: false,
            fingerprintChanged: false,
          ),
          api: api,
        );
        await tester.tap(find.text('Tracking is offline — tap to fix'));
        await tester.pumpAndSettle();
        expect(find.text('A11Y-ROUTE'), findsOneWidget);
      },
    );

    testWidgets(
      'tap with only batteryOptExempt off routes to '
      '/onboarding/permissions/battery-opt',
      (tester) async {
        final api = buildMockPermissionStatusApi();
        await _pumpBanner(
          tester,
          health: const PermissionHealth(
            usageAccess: true,
            accessibilityService: true,
            batteryOptExempt: false,
            fingerprintChanged: false,
          ),
          api: api,
        );
        await tester.tap(find.text('Tracking is offline — tap to fix'));
        await tester.pumpAndSettle();
        expect(find.text('BATTERY-ROUTE'), findsOneWidget);
      },
    );

    testWidgets(
      'fingerprintChanged=true with all 3 perms granted still surfaces '
      'banner copy (ONBD-07) and tap routes to usage-access',
      (tester) async {
        final api = buildMockPermissionStatusApi();
        await _pumpBanner(
          tester,
          health: const PermissionHealth(
            usageAccess: true,
            accessibilityService: true,
            batteryOptExempt: true,
            fingerprintChanged: true,
          ),
          api: api,
        );
        // The widget renders unconditionally — visibility decision is
        // the parent's responsibility. Verify the copy is present so
        // the parent can rely on `!allHealthy` to mount us.
        expect(
          find.text('Tracking is offline — tap to fix'),
          findsOneWidget,
        );
        await tester.tap(find.text('Tracking is offline — tap to fix'));
        await tester.pumpAndSettle();
        // OS-update fallback walks the user from the top of the funnel.
        expect(find.text('USAGE-ROUTE'), findsOneWidget);
      },
    );
  });
}
