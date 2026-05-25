// Phase 6 Wave 0 RED stub — privacy_policy_url_present_test.dart
// Implementation in 06-06/06-08. Tests docs/PRIVACY.md existence and
// SettingsScreen Privacy tile linkage.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 6 / Privacy policy present (SETT-05, PLAY-08)', () {
    test(
      'docs/PRIVACY.md exists and is non-empty',
      () {
        final file = File('docs/PRIVACY.md');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'SETT-05: docs/PRIVACY.md must exist as bundled asset',
        );
        expect(
          file.readAsStringSync().trim().isNotEmpty,
          isTrue,
          reason: 'SETT-05: docs/PRIVACY.md must be non-empty',
        );
      },
    );

    test(
      'SettingsScreen source contains Privacy Policy ListTile entry '
      'pointing to /settings/privacy',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-06',
        );
      },
    );
  });
}
