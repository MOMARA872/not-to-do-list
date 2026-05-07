// Plan 02-08 implementation. (Wave 0 stub replaced.)
//
// End-to-end coverage of the 3-step permission funnel as a sequence:
// usage-access → accessibility → battery-opt → home (cursor + complete
// state persisted along the way). Sibling of permission_funnel_test.dart
// — that file unit-tests each step in isolation; this file covers the
// full sequenced traversal.
// `when(() => mock.method())` is the canonical mocktail idiom.
// ignore_for_file: unnecessary_lambdas
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
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

  Widget buildApp({required MockPermissionStatusApi mock}) {
    final router = GoRouter(
      initialLocation: '/onboarding/permissions/usage-access',
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

  testWidgets(
      'sequenced skip-through: skip Step 1 → skip Step 2 → skip Step 3 → '
      'lands on / and onboarding_complete=true', (tester) async {
    final mock = buildMockPermissionStatusApi();
    await tester.pumpWidget(buildApp(mock: mock));
    await tester.pumpAndSettle();
    expect(find.text('See which apps you actually use'), findsOneWidget);

    // Step 1 skip
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Pause before you open blocked apps'), findsOneWidget);

    // Step 2 skip
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Keep tracking running overnight'), findsOneWidget);

    // Step 3 skip — funnel exits to /, marks complete.
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('home-arrived'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_complete'), isTrue);
  });

  testWidgets(
      'sequenced grant-through: grant 1 → grant 2 → grant 3 (all on '
      'resume) → lands on / with cursor advanced and complete=true',
      (tester) async {
    final mock = buildMockPermissionStatusApi();
    await tester.pumpWidget(buildApp(mock: mock));
    await tester.pumpAndSettle();
    expect(find.text('See which apps you actually use'), findsOneWidget);

    // User grants Usage Access in Settings → returns.
    when(() => mock.isUsageAccessGranted()).thenAnswer((_) async => true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Pause before you open blocked apps'), findsOneWidget);

    // User grants Accessibility → returns.
    when(() => mock.isAccessibilityServiceEnabled())
        .thenAnswer((_) async => true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Keep tracking running overnight'), findsOneWidget);

    // User grants battery-opt → returns. Funnel completes.
    when(() => mock.isIgnoringBatteryOptimizations())
        .thenAnswer((_) async => true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('home-arrived'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(prefs.getInt('onboarding_step'), greaterThanOrEqualTo(2));
  });
}
