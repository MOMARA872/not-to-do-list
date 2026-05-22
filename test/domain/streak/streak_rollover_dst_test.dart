// Plan 05-01 — Wave 0 RED stub: StreakRolloverService DST boundary tests.
//
// Covers: STRK-08 (DST 23h + 25h day correctness).
// Spring forward: 2026-03-08 (US DST, 23h day).
// Fall back:      2025-11-02 (US DST, 25h day).
//
// All tests are skipped — Plan 05-03 fills.
// Harness mirrors GROUP 5 _Tuple from
//   test/domain/schedule/schedule_window_parity_test.dart lines 436-447.

import 'package:flutter_test/flutter_test.dart';

// Tuple harness for DST boundary tests — mirrors schedule_window_parity_test.dart pattern.
typedef _DstTuple = ({
  DateTime day,
  String label,
});

final List<_DstTuple> _springForwardTuples = [
  (
    day: DateTime.utc(2026, 3, 8), // Spring forward US DST — 23h local day
    label: 'spring-forward 2026-03-08',
  ),
];

final List<_DstTuple> _fallBackTuples = [
  (
    day: DateTime.utc(2025, 11, 2), // Fall back US DST — 25h local day
    label: 'fall-back 2025-11-02',
  ),
];

void main() {
  group(
    'StreakRolloverService DST spring-forward 23h day '
    '(STRK-08) — test_spring_forward_23h_day',
    () {
      for (final t in _springForwardTuples) {
        test(
          'test_spring_forward_23h_day: '
          'rollover handles ${t.label} without off-by-one on streak day',
          () async {
            // Plan 05-03 fills
          },
          skip: 'Plan 05-03 fills',
        );
      }
    },
  );

  group(
    'StreakRolloverService DST fall-back 25h day '
    '(STRK-08) — test_fall_back_25h_day',
    () {
      for (final t in _fallBackTuples) {
        test(
          'test_fall_back_25h_day: '
          'rollover handles ${t.label} without double-counting on streak day',
          () async {
            // Plan 05-03 fills
          },
          skip: 'Plan 05-03 fills',
        );
      }
    },
  );
}
