// `when(() => mock.method())` is the canonical mocktail idiom; the
// unnecessary_lambdas lint misfires on it.
// ignore_for_file: unnecessary_lambdas

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/permission_status_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('permissionHealthProvider (REL-02, ONBD-06)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'all granted, fresh install -> allHealthy=true and fingerprint baseline '
      'recorded',
      () async {
        final mock = buildMockPermissionStatusApi(
          usageAccess: true,
          accessibility: true,
          batteryOptExempt: true,
          fingerprint: 'fp-pixel-16',
        );
        final container = ProviderContainer(
          overrides: [
            permissionStatusApiProvider.overrideWith((_) => mock),
          ],
        );
        addTearDown(container.dispose);

        final health = await container.read(permissionHealthProvider.future);
        expect(health.allHealthy, isTrue);
        expect(health.fingerprintChanged, isFalse);
        // Baseline persisted
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('last_known_fingerprint'), 'fp-pixel-16');
      },
    );

    test('one permission revoked -> allHealthy=false', () async {
      final mock = buildMockPermissionStatusApi(
        accessibility: true,
        batteryOptExempt: true,
      );
      final container = ProviderContainer(
        overrides: [
          permissionStatusApiProvider.overrideWith((_) => mock),
        ],
      );
      addTearDown(container.dispose);

      final health = await container.read(permissionHealthProvider.future);
      expect(health.allHealthy, isFalse);
      expect(health.usageAccess, isFalse);
    });

    test('refresh() recomputes after permission change', () async {
      var grantState = false;
      final mock = MockPermissionStatusApi();
      when(() => mock.isUsageAccessGranted())
          .thenAnswer((_) async => grantState);
      when(() => mock.isAccessibilityServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mock.isIgnoringBatteryOptimizations())
          .thenAnswer((_) async => true);
      when(() => mock.currentBuildFingerprint())
          .thenAnswer((_) async => 'fp-x');
      when(() => mock.currentManufacturer())
          .thenAnswer((_) async => 'pixel');

      final container = ProviderContainer(
        overrides: [
          permissionStatusApiProvider.overrideWith((_) => mock),
        ],
      );
      addTearDown(container.dispose);

      var h = await container.read(permissionHealthProvider.future);
      expect(h.usageAccess, isFalse);
      grantState = true;
      await container.read(permissionHealthProvider.notifier).refresh();
      h = await container.read(permissionHealthProvider.future);
      expect(h.usageAccess, isTrue);
    });
  });
}
