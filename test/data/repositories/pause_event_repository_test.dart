// Phase 4 Plan 04-01 — Wave 0 stub for PauseEventRepository.
// Implementation lands in Plan 04-07.
//
// D-13 contract: Dart is the single writer to pause_events.
// PauseActivity (Flutter side) writes one row per session at session-end
// (insert-at-end pattern to avoid UPDATE-by-id race on activity kill).
//
// outcome mapping (from CONTEXT.md specifics):
//   0 = cooldown auto-completed (timer ran to 0)
//   1 = Cancel pressed (cooldownChosenSeconds may be null if no chip was tapped)
//   2 = Use anyway pressed (soft entries only)
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PauseEventRepository.insertOutcome (D-13)', () {
    group('outcome=0 cooldown-completed', () {
      test(
        'placeholder',
        () {},
        skip: 'Plan 04-07 fills (PAUS-04 cooldown drain outcome=0)',
      );
    });

    group('outcome=1 cancel', () {
      test(
        'placeholder',
        () {},
        skip: 'Plan 04-07 fills (PAUS-05 Cancel writes outcome=1)',
      );
    });

    group('outcome=2 use-anyway', () {
      test(
        'placeholder',
        () {},
        skip: 'Plan 04-07 fills (PAUS-06 Use anyway writes outcome=2)',
      );
    });
  });
}
