// Phase 4 Plan 04-08 — flipped from Wave-0 skip stub to real unit tests.
//
// Verifies that permissionHealthProvider.accessibilityServiceGranted is
// truth-bearing after Plan 04-03 ships AccessibilityApiImpl (which replaced
// the hardcoded-false stub in MainActivity.kt).
//
// These are Dart-layer unit tests: they mock PermissionStatusApi to return a
// controlled isAccessibilityServiceEnabled() value and assert the provider
// reflects it correctly. The end-to-end Kotlin chain (AccessibilityManager →
// Pigeon → Dart) is verified by manual UAT in Task 04-08-04.
//
// `when(() => mock.method())` is the canonical mocktail idiom;
// unnecessary_lambdas lint misfires on it.
// ignore_for_file: unnecessary_lambdas

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/permission_status_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'permissionHealthProvider.accessibilityServiceGranted goes live '
    '(HealthCheckBanner truth-bearing)',
    () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      test(
        'permissionHealthProvider observes AccessibilityApi.isServiceEnabled → true',
        () async {
          final mock = buildMockPermissionStatusApi(
            usageAccess: true,
            accessibility: true,
            batteryOptExempt: true,
            fingerprint: 'fp-test',
          );
          final container = ProviderContainer(
            overrides: [
              permissionStatusApiProvider.overrideWith((_) => mock),
            ],
          );
          addTearDown(container.dispose);

          final health = await container.read(permissionHealthProvider.future);
          expect(
            health.accessibilityService,
            isTrue,
            reason: 'accessibilityServiceGranted should be true when '
                'AccessibilityApi.isServiceEnabled returns true',
          );
        },
      );

      test(
        'permissionHealthProvider observes AccessibilityApi.isServiceEnabled → false',
        () async {
          final mock = buildMockPermissionStatusApi(
            usageAccess: true,
            accessibility: false,
            batteryOptExempt: true,
            fingerprint: 'fp-test',
          );
          final container = ProviderContainer(
            overrides: [
              permissionStatusApiProvider.overrideWith((_) => mock),
            ],
          );
          addTearDown(container.dispose);

          final health = await container.read(permissionHealthProvider.future);
          expect(
            health.accessibilityService,
            isFalse,
            reason: 'accessibilityServiceGranted should be false when '
                'AccessibilityApi.isServiceEnabled returns false',
          );
          expect(
            health.allHealthy,
            isFalse,
            reason: 'allHealthy should be false when a11y service is off',
          );
        },
      );
    },
  );
}
