// Plan 05-01 — Wave 0 RED stub: ReminderSettingsScreen widget tests.
//
// Covers: NOTF-01 (24h time picker in Settings),
//         D-09 (default reminder time 21:00),
//         D-01/NOTF-01 (showTimePicker persists hour*60+minute to prefs).
//
// All tests are skipped — Plan 05-08 fills.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'ReminderSettingsScreen shows ListTile "Daily reminder" subtitle '
    'in DateFormat.jm() (NOTF-01)',
    () {
      testWidgets(
        'ListTile title renders "Daily reminder"',
        (tester) async {
          // Plan 05-08 fills
        },
        skip: true, // Plan 05-08 fills
      );

      testWidgets(
        'ListTile subtitle renders time in DateFormat.jm() format',
        (tester) async {
          // Plan 05-08 fills
        },
        skip: true, // Plan 05-08 fills
      );

      testWidgets(
        'default time is 21:00 (stored as 1260 = 21*60 in prefs)',
        (tester) async {
          // Plan 05-08 fills
        },
        skip: true, // Plan 05-08 fills
      );
    },
  );

  group(
    'ReminderSettingsScreen showTimePicker persists hour*60+minute '
    'to prefs key reminder_hour_minute (NOTF-01)',
    () {
      testWidgets(
        'picking a new time persists hour*60+minute under reminder_hour_minute',
        (tester) async {
          // Plan 05-08 fills
        },
        skip: true, // Plan 05-08 fills
      );

      testWidgets(
        'dismissing time picker (null) does not change persisted value',
        (tester) async {
          // Plan 05-08 fills
        },
        skip: true, // Plan 05-08 fills
      );
    },
  );

  group(
    'ReminderSettingsScreen onPick calls '
    'NotificationApi.scheduleDailyReminder(h, m)',
    () {
      testWidgets(
        'scheduleDailyReminder called with correct hour and minute after pick',
        (tester) async {
          // Plan 05-08 fills
        },
        skip: true, // Plan 05-08 fills
      );
    },
  );
}
