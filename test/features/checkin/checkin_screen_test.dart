// Plan 05-01 — Wave 0 RED stub: CheckinScreen widget tests.
//
// Covers: D-02 (pending entries with Yes/No SegmentedButton),
//         D-03 (Save check-in writes N rows in one Drift transaction),
//         D-01 (idempotent — already-answered entries show locked SegmentedButton),
//         UI-SPEC empty-state copy ("You're all caught up" + "Check back tomorrow."),
//         UI-SPEC error copy ("Something went wrong — your check-in wasn't saved. Try again.").
//
// Copy locked from 05-UI-SPEC.md §Copywriting Contract — no paraphrase.
// All tests are skipped — Plan 05-06 fills.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'CheckinScreen lists pending entries with Yes/No SegmentedButton '
    '(D-02 / D-03)',
    () {
      testWidgets(
        'pending entry has SegmentedButton with Yes and No segments',
        (tester) async {
          // Plan 05-06 fills
        },
        skip: true, // Plan 05-06 fills
      );

      testWidgets(
        '"Save check-in" button disabled until at least one entry answered',
        (tester) async {
          // Plan 05-06 fills
        },
        skip: true, // Plan 05-06 fills
      );
    },
  );

  group(
    'CheckinScreen Save check-in writes N rows in one Drift transaction '
    '(D-03)',
    () {
      testWidgets(
        'tapping Save check-in writes all answered rows in single transaction',
        (tester) async {
          // Plan 05-06 fills
        },
        skip: true, // Plan 05-06 fills
      );
    },
  );

  group(
    'CheckinScreen idempotent — already-answered entries show locked '
    'SegmentedButton (D-01)',
    () {
      testWidgets(
        'already-answered entry renders SegmentedButton as disabled with prior answer',
        (tester) async {
          // Plan 05-06 fills
        },
        skip: true, // Plan 05-06 fills
      );
    },
  );

  group(
    'CheckinScreen empty state heading "You\'re all caught up" + '
    'body "Check back tomorrow." (UI-SPEC copy)',
    () {
      testWidgets(
        'empty state shows "You\'re all caught up" heading',
        (tester) async {
          // Plan 05-06 fills
        },
        skip: true, // Plan 05-06 fills
      );

      testWidgets(
        'empty state shows "Check back tomorrow." body text',
        (tester) async {
          // Plan 05-06 fills
        },
        skip: true, // Plan 05-06 fills
      );
    },
  );

  group(
    'CheckinScreen error shows SnackBar '
    '"Something went wrong — your check-in wasn\'t saved. Try again." '
    '(UI-SPEC copy)',
    () {
      testWidgets(
        'write error shows SnackBar with verbatim error copy',
        (tester) async {
          // Plan 05-06 fills
        },
        skip: true, // Plan 05-06 fills
      );
    },
  );
}
