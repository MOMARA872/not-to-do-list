// Phase 4 Plan 04-01 — Wave 0 stub for CooldownChipRow widget tests.
// Implementation lands in Plan 04-07.
//
// D-04 contract:
//   CooldownChipRow is a M3 SegmentedButton clone of the Phase-2
//   BlockModeSegmented widget. Chips: [1m] [3m] [5m] [10m].
//   No default pre-selection — user must tap to start cooldown.
//   Tapping a different chip while running re-starts at new duration.
//   No [+Custom] chip (DIFF-03 v1.x deferred).
//
// Note: This file does NOT import package:not_to_do_list/features/pause/
// — those modules do not exist until Plan 04-07.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CooldownChipRow (D-04 SegmentedButton clone of BlockModeSegmented)', () {
    test(
      'placeholder',
      () {},
      skip: 'Plan 04-07 fills (D-04 SegmentedButton [1m,3m,5m,10m] chips)',
    );
  });
}
