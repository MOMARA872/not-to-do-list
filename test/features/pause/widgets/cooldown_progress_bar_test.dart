// Phase 4 Plan 04-01 — Wave 0 stub for CooldownProgressBar widget tests.
// Implementation lands in Plan 04-07.
//
// D-05 contract:
//   CooldownProgressBar is a thin LinearProgressIndicator pinned to the
//   top edge of the PauseScreen. Below the selected chip, a small caption
//   reads "X:XX remaining" (M3 BodySmall). The progress bar drains
//   left → right over the chosen cooldown duration.
//   No center progress ring (would compete with reason hero).
//   No big falling digits (clashes with calm mood).
//
// Note: This file does NOT import package:not_to_do_list/features/pause/
// — those modules do not exist until Plan 04-07.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'CooldownProgressBar (D-05 LinearProgressIndicator + X:XX remaining caption)',
    () {
      test(
        'placeholder',
        () {},
        skip: 'Plan 04-07 fills (D-05 top-pinned progress bar + caption)',
      );
    },
  );
}
