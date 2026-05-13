// Phase 4 Plan 04-01 — Wave 0 stub for AccessibilityBlockedAppDetector.
// Implementation lands in Plan 04-04.
//
// D-16 REL-05 swap pattern:
//   useAccessibilityServiceProvider stays default true in v1.
//   AccessibilityBlockedAppDetector fills initialize/updateBlockList/
//   isHealthy in Plan 04-04.
//   Note: detections stream stays Stream.empty() — the consumer is the
//   Intent path (service → PauseActivity via Intent), NOT the stream.
//   The stream is reserved for future analytics/health UIs (out of v1 scope).
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccessibilityBlockedAppDetector (D-16 REL-05 swap)', () {
    test(
      'placeholder',
      () {},
      skip: 'Plan 04-04 fills initialize/updateBlockList/isHealthy',
    );
  });
}
