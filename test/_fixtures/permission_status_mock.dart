// Phase 2 shared fixture: mock PermissionStatusApi for funnel + banner tests.
// TODO(02-03): replace the local abstract below with
//   import 'package:not_to_do_list/platform/permission_status_api.g.dart';
// once Plan 02-03 lands the Pigeon codegen output.
import 'package:mocktail/mocktail.dart';

abstract class PermissionStatusApi {
  Future<bool> isUsageAccessGranted();
  Future<bool> isAccessibilityServiceEnabled();
  Future<bool> isIgnoringBatteryOptimizations();
  Future<String> currentBuildFingerprint();
  Future<String> currentManufacturer();
  Future<void> openUsageAccessSettings();
  Future<void> openAccessibilitySettings();
  Future<void> openBatteryOptSettings();
}

class MockPermissionStatusApi extends Mock implements PermissionStatusApi {}

/// Convenience builder. Defaults: every check returns false (i.e. nothing granted),
/// fingerprint = 'fp-test', manufacturer = 'pixel'.
MockPermissionStatusApi buildMockPermissionStatusApi({
  bool usageAccess = false,
  bool accessibility = false,
  bool batteryOptExempt = false,
  String fingerprint = 'fp-test',
  String manufacturer = 'pixel',
}) {
  final m = MockPermissionStatusApi();
  when(() => m.isUsageAccessGranted()).thenAnswer((_) async => usageAccess);
  when(() => m.isAccessibilityServiceEnabled()).thenAnswer((_) async => accessibility);
  when(() => m.isIgnoringBatteryOptimizations()).thenAnswer((_) async => batteryOptExempt);
  when(() => m.currentBuildFingerprint()).thenAnswer((_) async => fingerprint);
  when(() => m.currentManufacturer()).thenAnswer((_) async => manufacturer);
  when(() => m.openUsageAccessSettings()).thenAnswer((_) async {});
  when(() => m.openAccessibilitySettings()).thenAnswer((_) async {});
  when(() => m.openBatteryOptSettings()).thenAnswer((_) async {});
  return m;
}
