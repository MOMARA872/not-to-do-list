// Phase 4 Plan 04-01 — Wave 0 stub for schedule_window Dart parity oracle.
// Implementation (200+ tuple assertions) lands in Plan 04-02.
//
// D-12 contract:
//   The Kotlin port of isInScheduleWindow inside
//   NotToDoAccessibilityService must produce byte-for-byte identical
//   results to the Dart helper in
//   lib/domain/schedule/schedule_window.dart.
//
// Companion Kotlin test:
//   android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/
//     ScheduleWindowTest.kt
//   asserts the same 200+ (now, start, end, mask) tuples against the
//   Kotlin port. Plan 04-02 ships both the Kotlin port and the JVM unit
//   test alongside this Dart parity oracle.
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/domain/schedule/schedule_window.dart';

void main() {
  group('schedule_window Dart parity oracle (D-12 / PAUS-10)', () {
    test(
      'placeholder',
      () {
        // Verify the import resolves correctly — the Phase 2 helper exists.
        expect(
          isInScheduleWindow(
            now: DateTime(2026, 5, 10, 10),
            startMinutes: null,
            endMinutes: null,
            weekdayMask: null,
          ),
          isFalse,
        );
      },
      skip: 'Plan 04-02 fills — 200+ tuple parity assertions against '
          'the Kotlin port in ScheduleWindow.kt',
    );
  });
}
