// Plan 02-08 implementation. (Wave 0 stub replaced.)
//
// onResume re-check pattern (RESEARCH §onResume Return-Detection Pattern).
// Pumps AppLifecycleState.resumed via tester.binding and asserts:
//   1. permission flipped granted on resume → step auto-advances.
//   2. permission still denied on resume → OEM fallback panel becomes
//      visible (textContaining the generic 'Open your phone' fallback for
//      a non-aggressive OEM, or vendor-specific copy for a known one).
//   3. spurious resume (lock-screen / quick switch) is idempotent — no
//      crash, no advance if grant remains false.
// `when(() => mock.method())` is the canonical mocktail idiom.
// ignore_for_file: unnecessary_lambdas
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/pages/accessibility_step.dart';
import 'package:not_to_do_list/features/onboarding/pages/usage_access_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/permission_status_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapStep({
    required MockPermissionStatusApi mock,
    required String initialLocation,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
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
          builder: (_, __) =>
              const Scaffold(body: Text('battery-arrived')),
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
      'UsageAccessStep: AppLifecycleState.resumed re-checks; flipped grant '
      'auto-advances to accessibility', (tester) async {
    final mock = buildMockPermissionStatusApi();
    await tester.pumpWidget(
      wrapStep(
        mock: mock,
        initialLocation: '/onboarding/permissions/usage-access',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('See which apps you actually use'), findsOneWidget);

    // Simulate user granting in Settings then returning.
    when(() => mock.isUsageAccessGranted()).thenAnswer((_) async => true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Pause before you open blocked apps'), findsOneWidget);
  });

  testWidgets(
      'UsageAccessStep: resume with grant still denied surfaces OEM '
      'fallback panel', (tester) async {
    final mock = buildMockPermissionStatusApi(manufacturer: 'xiaomi');
    await tester.pumpWidget(
      wrapStep(
        mock: mock,
        initialLocation: '/onboarding/permissions/usage-access',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('On Xiaomi'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.textContaining('On Xiaomi'), findsOneWidget);
  });

  testWidgets(
      'Spurious resume (lock-screen / quick switch) is idempotent — no '
      'crash, does not advance', (tester) async {
    final mock = buildMockPermissionStatusApi();
    await tester.pumpWidget(
      wrapStep(
        mock: mock,
        initialLocation: '/onboarding/permissions/usage-access',
      ),
    );
    await tester.pumpAndSettle();

    // Three spurious resumes in a row, grant remains false throughout.
    for (var i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('See which apps you actually use'), findsOneWidget);
    // No exceptions surfaced into tester.
    expect(tester.takeException(), isNull);
  });
}
