// Phase 4 Plan 04-01 — Wave 0 stub for PauseController tests.
// Implementation lands in Plan 04-07.
//
// D-13 contract:
//   PauseController is a hand-written Riverpod controller (no @riverpod
//   codegen — see 01-01-SUMMARY.md for the analyzer-pin incompatibility).
//   Writes pause_events via PauseEventRepository at session-end
//   (insert-at-end to avoid UPDATE-by-id race on activity kill).
//
// Note: This file does NOT import package:not_to_do_list/features/pause/
// — those modules do not exist until Plan 04-07.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PAUS-04 cooldown drain auto-completes outcome=0', () {
    test(
      'placeholder',
      () {},
      skip: 'Plan 04-07 fills (PAUS-04 timer reaches 0 → outcome=0 written '
          '→ confirmation card shown → PauseActivity.finish())',
    );
  });

  group('PAUS-05 Cancel writes outcome=1', () {
    test(
      'placeholder',
      () {},
      skip: 'Plan 04-07 fills (PAUS-05 Cancel pressed → outcome=1 written, '
          'cooldownChosenSeconds null when no chip tapped first)',
    );
  });

  group('PAUS-06 Use anyway writes outcome=2', () {
    test(
      'placeholder',
      () {},
      skip: 'Plan 04-07 fills (PAUS-06 Use anyway → outcome=2 written, '
          'soft entries only per PAUS-09 + CD-02 available immediately)',
    );
  });

  group('D-13 insert-at-session-end seam', () {
    test(
      'placeholder',
      () {},
      skip: 'Plan 04-07 fills (D-13 PauseEventRepository.insertOutcome called '
          'exactly once per session at resolution, NOT at chip-tap)',
    );
  });
}
