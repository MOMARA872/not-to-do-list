// Plan 05-01 — Wave 0 RED stub: StreakBadge widget tests.
//
// Covers: STRK-07 (home shows current + longest streak),
//         D-14 (badge format "🔥 N · best M"),
//         D-15 (day-0 renders "🔥 0 · best 0"),
//         D-05 (break-detection day shows strikethrough on prior count).
//
// Copy locked from 05-UI-SPEC.md §Copywriting Contract — no paraphrase.
// All tests are skipped — Plan 05-07 fills.
// Harness mirrors test/features/home/health_banner_test.dart.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'StreakBadge renders 🔥 3 · best 12 when current=3, longest=12 '
    '(STRK-07 + D-14)',
    () {
      testWidgets(
        'badge text matches "🔥 3 · best 12" when current=3 longest=12',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );
    },
  );

  group('StreakBadge renders 🔥 0 · best 0 on day-0 (D-15)', () {
    testWidgets(
      'badge text matches "🔥 0 · best 0" when current=0 longest=0',
      (tester) async {
        // Plan 05-07 fills
      },
      skip: true, // Plan 05-07 fills
    );
  });

  group('StreakBadge renders strikethrough on break-detection day (D-05)', () {
    testWidgets(
      'badge prior-count has TextDecoration.lineThrough on break day',
      (tester) async {
        // Plan 05-07 fills
      },
      skip: true, // Plan 05-07 fills
    );

    testWidgets(
      'badge format "🔥 0 · best N" from next day after break (no strikethrough)',
      (tester) async {
        // Plan 05-07 fills
      },
      skip: true, // Plan 05-07 fills
    );
  });
}
