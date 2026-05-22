// Plan 05-01 — Wave 0 RED stub: ReminderOffBanner widget tests.
//
// Covers: NOTF-07 (in-app banner when POST_NOTIFICATIONS denied),
//         UI-SPEC copy ("Reminder is off — tap to fix"),
//         tap behavior (permanently_denied → openAppNotificationSettings;
//                       rationale → /onboarding/permissions/notifications).
//
// Copy locked from 05-UI-SPEC.md §Copywriting Contract — no paraphrase.
// All tests are skipped — Plan 05-07 fills.
// Harness mirrors test/features/home/health_banner_test.dart.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'ReminderOffBanner visible when isPostNotificationsGranted=false '
    '(NOTF-07) — test_banner_visible_when_denied',
    () {
      testWidgets(
        'test_banner_visible_when_denied: '
        'banner is visible when POST_NOTIFICATIONS not granted',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );
    },
  );

  group(
    'ReminderOffBanner hidden when isPostNotificationsGranted=true '
    '(NOTF-07) — test_banner_hidden_when_granted',
    () {
      testWidgets(
        'test_banner_hidden_when_granted: '
        'banner is not rendered when POST_NOTIFICATIONS is granted',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );
    },
  );

  group(
    'ReminderOffBanner copy exact "Reminder is off — tap to fix" '
    '(UI-SPEC copy lock)',
    () {
      testWidgets(
        'banner renders verbatim "Reminder is off — tap to fix"',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );
    },
  );

  group(
    'ReminderOffBanner tap on permanently_denied → openAppNotificationSettings; '
    'on rationale → /onboarding/permissions/notifications',
    () {
      testWidgets(
        'tap when permanently_denied calls openAppNotificationSettings',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );

      testWidgets(
        'tap when rationale available routes to /onboarding/permissions/notifications',
        (tester) async {
          // Plan 05-07 fills
        },
        skip: true, // Plan 05-07 fills
      );
    },
  );
}
