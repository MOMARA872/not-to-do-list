// Phase 4 Plan 04-01 — Wave 0 stub for DoneConfirmationCard widget tests.
// Implementation lands in Plan 04-07.
//
// D-07 contract:
//   When the LinearProgressIndicator drains to zero, the screen morphs for
//   ~1.5 seconds into a calm confirmation card with the literal string
//   "✓ Cooldown complete" (per CONTEXT.md specifics line 195).
//   No streak callout (Phase-5 territory).
//   No judgment copy. No additional copy.
//   Duration: hardcoded Duration(milliseconds: 1500).
//   After 1.5s: PauseActivity.finish() returns to launcher.
//   pause_events row is written with outcome=0 BEFORE the card renders.
//
// Note: This file does NOT import package:not_to_do_list/features/pause/
// — those modules do not exist until Plan 04-07.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoneConfirmationCard (D-07 — ✓ Cooldown complete, 1.5s)', () {
    test(
      'placeholder',
      () {},
      skip: 'Plan 04-07 fills (D-07 auto-close card with literal '
          '"✓ Cooldown complete", 1.5s delay, outcome=0 written before render)',
    );
  });
}
