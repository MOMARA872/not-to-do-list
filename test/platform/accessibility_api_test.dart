// Phase 4 Plan 04-01 — Wave 0 stub for AccessibilityApi Pigeon channel.
// Implementation lands in Plan 04-03 (Kotlin AccessibilityApiImpl replaces
// the hardcoded-false anonymous-object stub in MainActivity.kt).
// This mock harness is reused by Plan 04-08 (permissionHealthProvider live
// wiring via AccessibilityApi.isServiceEnabled()).
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/platform/accessibility_api.g.dart';

/// Reusable mocktail mock — Wave 1+ test files import this class.
class MockAccessibilityApi extends Mock implements AccessibilityApi {}

void main() {
  group('AccessibilityApi (REL-05 health surface)', () {
    test(
      'placeholder',
      () {},
      skip: 'Plan 04-03 fills AccessibilityApiImpl.isServiceEnabled',
    );
  });
}
