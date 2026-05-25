// Phase 6 Wave 0 RED stub — theme_mode_provider_test.dart
// Implementation in 06-02. Unskipped during GREEN flip in 06-02.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 6 / themeModeProvider (SETT-04)', () {
    test(
      'default ThemeMode.system when no prefs value stored',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-02',
        );
      },
    );

    test(
      'persists ThemeMode int across notifier rebuild',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-02',
        );
      },
    );

    test(
      'encode/decode round-trip: 0=system 1=light 2=dark',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-02',
        );
        // Silence unused import warning during RED phase.
        expect(ThemeMode.system, isA<ThemeMode>());
      },
    );
  });
}
