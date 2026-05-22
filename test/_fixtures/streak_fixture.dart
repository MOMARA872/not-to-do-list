// Phase 5 shared fixture: mock clock API and 2x2 source-resolution matrix.
//
// Provides:
//   buildClockMockApi({int bootMonotonicNanos}) — MockPermissionStatusApi stub.
//     NOTE: bootMonotonicNanos() is a new Pigeon method added in Plan 05-04.
//     Until then, the mock returns safe defaults for all existing methods.
//     Plan 05-03 extends this fixture with the actual stub for the new method.
//   kSourceResolutionMatrix — 6-cell tuple list mapping
//     (usageMinutes, checkinAvoided, a11yWasOn) → (expectedStatus, expectedSource)
//     per RESEARCH §4 _resolveDay docstring.
//
// Mirrors the shape of test/_fixtures/permission_status_mock.dart.
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';

class MockPermissionStatusApi extends Mock implements PermissionStatusApi {}

/// Convenience builder for clock-aware mock.
///
/// Returns a [MockPermissionStatusApi] with all existing methods stubbed.
/// The [bootMonotonicNanos] parameter is reserved for when Plan 05-04 extends
/// PermissionStatusApi with bootMonotonicNanos() — at that point, this factory
/// will add `when(() => m.bootMonotonicNanos()).thenAnswer(...)`.
MockPermissionStatusApi buildClockMockApi({
  int bootMonotonicNanos = 0,
}) {
  final m = MockPermissionStatusApi();
  // Safe defaults for all existing PermissionStatusApi methods.
  when(() => m.isUsageAccessGranted()).thenAnswer((_) async => false);
  when(
    () => m.isAccessibilityServiceEnabled(),
  ).thenAnswer((_) async => false);
  when(
    () => m.isIgnoringBatteryOptimizations(),
  ).thenAnswer((_) async => false);
  when(
    () => m.currentBuildFingerprint(),
  ).thenAnswer((_) async => 'fp-streak-test');
  when(() => m.currentManufacturer()).thenAnswer((_) async => 'pixel');
  when(() => m.openUsageAccessSettings()).thenAnswer((_) async {});
  when(() => m.openAccessibilitySettings()).thenAnswer((_) async {});
  when(() => m.openBatteryOptSettings()).thenAnswer((_) async {});
  // bootMonotonicNanos() stub added by Plan 05-04 when method is added to
  // PermissionStatusApi Pigeon interface.
  return m;
}

// ---------------------------------------------------------------------------
// 2x2 Source Resolution Matrix (STRK-04 / RESEARCH §4 _resolveDay)
//
// Row semantics:
//   usageMinutes   — foreground minutes observed for the entry on that day
//   checkinAvoided — true=yes I avoided, false=no I used it, null=not answered
//   a11yWasOn      — whether AccessibilityService was tracking that day
//   expectedStatus — 0=success, 1=broken, 2=incomplete-data
//   expectedSource — 0=system-confirmed, 1=self-reported-only
// ---------------------------------------------------------------------------

typedef SourceResolutionCell = ({
  int usageMinutes,
  bool? checkinAvoided,
  bool a11yWasOn,
  int expectedStatus,
  int expectedSource,
});

/// Six cells covering every branch of _resolveDay (RESEARCH §4).
const List<SourceResolutionCell> kSourceResolutionMatrix = [
  // 1. Broken by system data (a11y on, usage > threshold=5)
  (
    usageMinutes: 10,
    checkinAvoided: null,
    a11yWasOn: true,
    expectedStatus: 1, // broken
    expectedSource: 0, // system-confirmed
  ),
  // 2. Broken by self-report (checkin=no, a11y on)
  (
    usageMinutes: 0,
    checkinAvoided: false,
    a11yWasOn: true,
    expectedStatus: 1, // broken
    expectedSource: 0, // system-confirmed
  ),
  // 3. Success — system-confirmed (checkin=yes, a11y on)
  (
    usageMinutes: 0,
    checkinAvoided: true,
    a11yWasOn: true,
    expectedStatus: 0, // success
    expectedSource: 0, // system-confirmed
  ),
  // 4. Success — self-reported only (checkin=yes, a11y off)
  (
    usageMinutes: 0,
    checkinAvoided: true,
    a11yWasOn: false,
    expectedStatus: 0, // success
    expectedSource: 1, // self-reported-only
  ),
  // 5. Fallback success — no checkin, a11y on (system-confirmed fallback)
  (
    usageMinutes: 0,
    checkinAvoided: null,
    a11yWasOn: true,
    expectedStatus: 0, // success
    expectedSource: 0, // system-confirmed
  ),
  // 6. Incomplete data — no checkin, a11y off
  (
    usageMinutes: 0,
    checkinAvoided: null,
    a11yWasOn: false,
    expectedStatus: 2, // incomplete-data
    expectedSource: 0,
  ),
];
