// Phase 6 Plan 06-07 — Privacy policy present and in-app linkage assertion.
// Tests docs/PRIVACY.md existence and SettingsScreen Privacy tile linkage.
// Note: full public GitHub Pages URL assertion lands in 06-08 once listing is written.
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
        final src = File(
          'lib/features/settings/pages/settings_screen.dart',
        ).readAsStringSync();

        expect(
          src.contains('/settings/privacy'),
          isTrue,
          reason:
              'SETT-05/PLAY-08: settings_screen.dart must contain the route '
              '"/settings/privacy" — Privacy Policy tile must link to the '
              'privacy screen (06-03 route registration)',
        );
      },
    );
  });
}
