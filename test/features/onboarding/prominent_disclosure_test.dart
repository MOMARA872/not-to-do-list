// Phase 2 Wave 0 stub. Assertions land in Plan 02-08.
//
// PLAY-06 verbatim disclosure-phrase contract.
// Plan 02-08 will read lib/features/onboarding/pages/accessibility_step.dart
// as a string and assert that ALL FIVE of the following phrases are present
// verbatim. The phrases are quoted from docs/play-declaration.md and must
// stay byte-identical in the rendered disclosure UI.
//
//   1. "package name"
//   2. "only when a window-state-changed event fires"
//   3. "never reads your screen"
//   4. "never sends anything off your device"
//   5. "disable this at any time"
//
// Source of truth: /Users/jintanakhomwong/projects/not-to-do-list/docs/play-declaration.md
// (Phase 1 commit). Any deviation = PLAY-06 contract break.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PLAY-06 prominent disclosure (PLAY-06)', () {
    test(
      'TODO: accessibility_step.dart contains all 5 verbatim PLAY-06 '
      'phrases listed in the comment block above',
      () {
        // Implemented in Plan 02-08.
      },
      skip: 'Wave 0 stub — see Plan 02-08',
    );
  });
}
