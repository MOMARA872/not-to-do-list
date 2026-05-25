// Phase 6 Plan 06-06 — disclosure_route_test.dart
// Tests /settings/disclosure nav-branch (SETT-05, RESEARCH §Pattern 5).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/pages/accessibility_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/permission_status_mock.dart';

/// Builds a GoRouter with a back-stack so pop() can work.
/// /settings → /settings/disclosure (AccessibilityStep with fromSettings:true)
Widget buildDisclosureApp({required MockPermissionStatusApi mock}) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, __) => const Scaffold(body: Text('settings-screen')),
        routes: [
          GoRoute(
            path: 'disclosure',
            builder: (_, __) =>
                const AccessibilityStep(fromSettings: true),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding/permissions/battery-opt',
        builder: (_, __) =>
            const Scaffold(body: Text('battery-opt-screen')),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Source-level checks (no widget rendering needed for these)
  final stepSource = File(
    'lib/features/onboarding/pages/accessibility_step.dart',
  ).readAsStringSync();

  final routerSource = File(
    'lib/core/router/app_router.dart',
  ).readAsStringSync();

  group('Phase 6 / Disclosure route (SETT-05, RESEARCH §Pattern 5)', () {
    test(
      'Test 1: AccessibilityStep constructor has fromSettings bool param',
      () {
        expect(
          stepSource.contains('this.fromSettings = false'),
          isTrue,
          reason: 'AccessibilityStep must have fromSettings: bool = false param',
        );
        expect(
          stepSource.contains('final bool fromSettings;'),
          isTrue,
          reason: 'AccessibilityStep must declare final bool fromSettings field',
        );
      },
    );

    test(
      'Test 2: app_router.dart /settings/disclosure uses fromSettings: true',
      () {
        expect(
          routerSource.contains('AccessibilityStep(fromSettings: true)'),
          isTrue,
          reason:
              '/settings/disclosure must use const AccessibilityStep(fromSettings: true)',
        );
      },
    );

    test(
      'Test 3: source has two widget.fromSettings nav-branch forks',
      () {
        final branches = 'widget.fromSettings'
            .allMatches(stepSource)
            .length;
        expect(
          branches,
          greaterThanOrEqualTo(2),
          reason:
              'Two context.go nav sites must have widget.fromSettings forks '
              '(success branch + skip branch)',
        );
      },
    );

    test(
      'Test 4: context.pop() called in fromSettings branch (not go to battery-opt)',
      () {
        // The source should contain context.pop() for the fromSettings branch
        expect(
          stepSource.contains('context.pop()'),
          isTrue,
          reason:
              'When fromSettings=true, navigation must call context.pop()',
        );
      },
    );

    testWidgets(
      'Test 5: tapping Skip from settings/disclosure pops back to settings',
      (tester) async {
        final mock = buildMockPermissionStatusApi(accessibility: false);
        await tester.pumpWidget(buildDisclosureApp(mock: mock));
        await tester.pumpAndSettle();

        // Navigate to /settings/disclosure
        final router = tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .routerConfig as GoRouter;
        router.go('/settings/disclosure');
        await tester.pumpAndSettle();

        // The AccessibilityStep should be visible
        expect(find.text('Pause before you open blocked apps'), findsOneWidget);

        // Tap Skip
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Should pop back to /settings, NOT navigate to battery-opt
        expect(find.text('settings-screen'), findsOneWidget);
        expect(find.text('battery-opt-screen'), findsNothing);
      },
    );

    test(
      'Test 6: 5 verbatim PLAY-06 phrases still intact (regression check)',
      () {
        const requiredPhrases = [
          'package name',
          'only when a window-state-changed event fires',
          'never reads your screen',
          'never sends anything off your device',
          'disable this at any time',
        ];
        for (final phrase in requiredPhrases) {
          expect(
            stepSource.contains(phrase),
            isTrue,
            reason: 'PLAY-06: accessibility_step.dart must contain "$phrase" verbatim',
          );
        }
      },
    );
  });
}
