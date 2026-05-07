import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/permission_status_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Build.FINGERPRINT change detection (ONBD-07)', () {
    test(
      'first install: stored is null -> baseline recorded, '
      'fingerprintChanged=false',
      () async {
        SharedPreferences.setMockInitialValues({});
        final mock = buildMockPermissionStatusApi(
          usageAccess: true,
          accessibility: true,
          batteryOptExempt: true,
          fingerprint: 'fp-A',
        );
        final container = ProviderContainer(
          overrides: [
            permissionStatusApiProvider.overrideWith((_) => mock),
          ],
        );
        addTearDown(container.dispose);
        final h = await container.read(permissionHealthProvider.future);
        expect(h.fingerprintChanged, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('last_known_fingerprint'), 'fp-A');
      },
    );

    test(
      'OS update: stored != current -> fingerprintChanged=true -> '
      'allHealthy=false even if all granted',
      () async {
        SharedPreferences.setMockInitialValues(
          {'last_known_fingerprint': 'fp-OLD'},
        );
        final mock = buildMockPermissionStatusApi(
          usageAccess: true,
          accessibility: true,
          batteryOptExempt: true,
          fingerprint: 'fp-NEW',
        );
        final container = ProviderContainer(
          overrides: [
            permissionStatusApiProvider.overrideWith((_) => mock),
          ],
        );
        addTearDown(container.dispose);
        final h = await container.read(permissionHealthProvider.future);
        expect(h.fingerprintChanged, isTrue);
        expect(
          h.allHealthy,
          isFalse,
          reason: 'fingerprintChanged should force allHealthy=false',
        );
      },
    );

    test('persistCurrentFingerprint clears the change flag', () async {
      SharedPreferences.setMockInitialValues(
        {'last_known_fingerprint': 'fp-OLD'},
      );
      final mock = buildMockPermissionStatusApi(
        usageAccess: true,
        accessibility: true,
        batteryOptExempt: true,
        fingerprint: 'fp-NEW',
      );
      final container = ProviderContainer(
        overrides: [
          permissionStatusApiProvider.overrideWith((_) => mock),
        ],
      );
      addTearDown(container.dispose);
      var h = await container.read(permissionHealthProvider.future);
      expect(h.fingerprintChanged, isTrue);
      await container
          .read(permissionHealthProvider.notifier)
          .persistCurrentFingerprint();
      h = await container.read(permissionHealthProvider.future);
      expect(h.fingerprintChanged, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_known_fingerprint'), 'fp-NEW');
    });
  });
}
