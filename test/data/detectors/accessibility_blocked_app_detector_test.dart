// Plan 04-04 — AccessibilityBlockedAppDetector tests.
//
// D-16 REL-05 swap pattern:
//   useAccessibilityServiceProvider stays default true in v1.
//   AccessibilityBlockedAppDetector fills initialize/updateBlockList/
//   isHealthy in Plan 04-04.
//   Note: detections stream stays Stream.empty() — the consumer is the
//   Intent path (service → PauseActivity via Intent), NOT the stream.
//   The stream is reserved for future analytics/health UIs (out of v1 scope).
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/detectors/accessibility_blocked_app_detector.dart';
import 'package:not_to_do_list/platform/accessibility_api.g.dart';
import 'package:not_to_do_list/platform/blocklist_broadcast_api.g.dart';

class MockBlocklistBroadcastApi extends Mock implements BlocklistBroadcastApi {}

class MockAccessibilityApi extends Mock implements AccessibilityApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(<BlockListEntrySnapshot>[]);
  });

  group('AccessibilityBlockedAppDetector (D-16 REL-05 swap)', () {
    late MockBlocklistBroadcastApi mockBroadcaster;
    late MockAccessibilityApi mockAccessibilityApi;
    late List<BlockListEntrySnapshot> fixedSnapshot;
    late AccessibilityBlockedAppDetector detector;

    setUp(() {
      mockBroadcaster = MockBlocklistBroadcastApi();
      mockAccessibilityApi = MockAccessibilityApi();
      fixedSnapshot = [
        BlockListEntrySnapshot(
          entryId: 1,
          packageName: 'com.example.app',
          blockMode: 'soft',
        ),
      ];

      when(() => mockBroadcaster.publishBlockList(any()))
          .thenAnswer((_) async {});
      when(() => mockAccessibilityApi.isServiceEnabled())
          .thenAnswer((_) async => true);

      detector = AccessibilityBlockedAppDetector(
        broadcaster: mockBroadcaster,
        accessibilityApi: mockAccessibilityApi,
        snapshotProvider: () async => fixedSnapshot,
      );
    });

    test('initialize() calls publishBlockList with the snapshot from snapshotProvider',
        () async {
      await detector.initialize({'com.example.app'});

      final captured = verify(
        () => mockBroadcaster.publishBlockList(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final snapshots = captured.first as List<BlockListEntrySnapshot>;
      expect(snapshots.length, 1);
      expect(snapshots.first.packageName, 'com.example.app');
    });

    test('updateBlockList() calls publishBlockList with the snapshot from snapshotProvider',
        () async {
      await detector.updateBlockList({'com.example.app'});

      final captured = verify(
        () => mockBroadcaster.publishBlockList(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final snapshots = captured.first as List<BlockListEntrySnapshot>;
      expect(snapshots.first.packageName, 'com.example.app');
    });

    test('isHealthy returns the value from AccessibilityApi.isServiceEnabled()',
        () async {
      final healthy = await detector.isHealthy;
      expect(healthy, isTrue);

      when(() => mockAccessibilityApi.isServiceEnabled())
          .thenAnswer((_) async => false);
      final unhealthy = await detector.isHealthy;
      expect(unhealthy, isFalse);
    });
  });
}
