// Phase 4 Plan 04-01 — Wave 0 stub for permissionHealthProvider a11y live test.
// End-to-end verification lands in Plan 04-08.
//
// Background:
//   permissionHealthProvider.accessibilityServiceGranted is currently
//   hardcoded to false because AccessibilityApi.isServiceEnabled() is
//   stubbed in MainActivity.kt:55-58 to return false.
//
//   Plan 04-03 ships AccessibilityApiImpl with the real
//   AccessibilityManager.getEnabledAccessibilityServiceList() check.
//   After 04-03 lands, the Kotlin side flips from hardcoded-false to the
//   actual system state — permissionHealthProvider becomes truth-bearing
//   for the first time.
//
//   This test asserts the Dart side observes the change after a refresh().
//   It is an end-to-end smoke test, not a unit test — it verifies the
//   HealthCheckBanner picks up the live a11y state on the next resume cycle.
//
// Note: This file does NOT import package:not_to_do_list/features/pause/
// — those modules do not exist until Plan 04-07.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'permissionHealthProvider.accessibilityServiceGranted goes live '
    '(HealthCheckBanner truth-bearing)',
    () {
      test(
        'placeholder',
        () {},
        skip: 'Plan 04-08 verifies end-to-end — the underlying Kotlin flip '
            'happens in Plan 04-03 (AccessibilityApiImpl replaces the '
            'hardcoded-false stub); this test asserts the Dart side observes '
            'the change after a refresh()',
      );
    },
  );
}
