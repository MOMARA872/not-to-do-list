// Plan 05-01 — Wave 0 RED stub: StreakHistorySection widget tests.
//
// Covers: D-16 (30-day 7-column GridView in entry detail),
//         D-07 (4 dot states: green/blue/red/grey),
//         D-07 mandatory grey tooltip ("Tracking was off this day"),
//         UI-SPEC copy "{N} days · best {M}".
//
// Copy locked from 05-UI-SPEC.md §Copywriting Contract — no paraphrase.
// All tests are skipped — Plan 05-07 fills.
// Harness mirrors test/features/home/health_banner_test.dart.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreakHistorySection renders 30-day 7-col GridView (D-16)', () {
    testWidgets(
      'GridView has crossAxisCount=7 and shows 30 day cells',
      (tester) async {
        // Plan 05-07 fills
      },
      skip: true, // Plan 05-07 fills
    );
  });

  group(
    'StreakHistorySection renders 4 dot states (D-07 — green/blue/red/grey)',
    () {
      testWidgets(
        'green dot for status=0 source=0 (system-confirmed success)',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );

      testWidgets(
        'blue dot for status=0 source=1 (self-reported-only success)',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );

      testWidgets(
        'red dot for status=1 (broken)',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );

      testWidgets(
        'grey dot for status=2 (incomplete-data)',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );
    },
  );

  group(
    'StreakHistorySection grey dot has Tooltip '
    '"Tracking was off this day" (D-07 mandatory)',
    () {
      testWidgets(
        'grey dot cell has Tooltip with message "Tracking was off this day"',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );
    },
  );

  group(
    'StreakHistorySection summary text '
    '"{N} days · best {M}" (UI-SPEC copy)',
    () {
      testWidgets(
        'summary text renders "{N} days · best {M}" format',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );

      testWidgets(
        'threshold help text renders '
        '"Streak breaks if you use this app over 5 min/day (change in Settings)"',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );
    },
  );
}
