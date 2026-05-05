import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/detectors/accessibility_blocked_app_detector.dart';
import 'package:not_to_do_list/data/detectors/usage_stats_polling_blocked_app_detector.dart';
import 'package:not_to_do_list/domain/blocked_app_detector.dart';
import 'package:not_to_do_list/domain/providers/blocked_app_detector_provider.dart';

void main() {
  group('blockedAppDetectorProvider (REL-05)', () {
    test('default flag (true) returns AccessibilityBlockedAppDetector', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final detector = container.read(blockedAppDetectorProvider);

      expect(detector, isA<AccessibilityBlockedAppDetector>());
      expect(detector, isA<BlockedAppDetector>());
    });

    test(
      'flag overridden to false returns UsageStatsPollingBlockedAppDetector',
      () {
        final container = ProviderContainer(
          overrides: [
            useAccessibilityServiceProvider.overrideWith((ref) => false),
          ],
        );
        addTearDown(container.dispose);

        final detector = container.read(blockedAppDetectorProvider);

        expect(detector, isA<UsageStatsPollingBlockedAppDetector>());
        expect(detector, isA<BlockedAppDetector>());
      },
    );
  });

  group('PLAY-02 enforcement-by-absence in BlockedAppDetector', () {
    test('blocked_app_detector.dart declares no autonomous-action methods', () {
      final source = File(
        'lib/domain/blocked_app_detector.dart',
      ).readAsStringSync();

      // Match a method/function DECLARATION (name followed by parens),
      // not commentary in a KDoc.
      expect(
        RegExp(r'\bperformAction\s*\(').hasMatch(source),
        isFalse,
        reason:
            'BlockedAppDetector must not declare performAction (PLAY-02)',
      );
      expect(
        RegExp(r'\bperformGlobalAction\s*\(').hasMatch(source),
        isFalse,
        reason:
            'BlockedAppDetector must not declare performGlobalAction (PLAY-02)',
      );
      expect(
        RegExp(r'\bdispatchGesture\s*\(').hasMatch(source),
        isFalse,
        reason:
            'BlockedAppDetector must not declare dispatchGesture (PLAY-02)',
      );
    });
  });
}
