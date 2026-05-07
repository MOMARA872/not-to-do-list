// Plan 02-08 implementation. (Wave 0 stub replaced.)
//
// PLAY-06 verbatim disclosure-phrase contract.
// Reads lib/features/onboarding/pages/accessibility_step.dart as a string
// and asserts that ALL FIVE phrases below are present byte-identical.
// The phrases come from docs/play-declaration.md §4 (Phase 1 commit).
// Any deviation = PLAY-06 contract break.
//
// Source of truth: /docs/play-declaration.md
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PLAY-06 prominent disclosure (PLAY-06)', () {
    final source = File(
      'lib/features/onboarding/pages/accessibility_step.dart',
    ).readAsStringSync();

    // The 5 verbatim phrases that MUST appear (RESEARCH §PLAY-06).
    const requiredPhrases = [
      'package name',
      'only when a window-state-changed event fires',
      'never reads your screen',
      'never sends anything off your device',
      'disable this at any time',
    ];

    for (final phrase in requiredPhrases) {
      test('accessibility_step.dart contains verbatim phrase: "$phrase"', () {
        expect(
          source.contains(phrase),
          isTrue,
          reason: 'PLAY-06 prominent disclosure must contain "$phrase" '
              'verbatim. If reduced or paraphrased, update '
              'docs/play-declaration.md FIRST.',
        );
      });
    }

    test('accessibility_step.dart declares no autonomous-action methods', () {
      // Same PLAY-02 absence-grep pattern Phase 1 established.
      expect(RegExp(r'\bperformAction\s*\(').hasMatch(source), isFalse);
      expect(RegExp(r'\bperformGlobalAction\s*\(').hasMatch(source), isFalse);
      expect(RegExp(r'\bdispatchGesture\s*\(').hasMatch(source), isFalse);
    });
  });
}
