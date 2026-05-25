// Phase 6 Wave 0 RED stub — reset_controller_test.dart
// Implementation in 06-05. Tests transactional wipe.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 6 / ResetController (SETT-02)', () {
    test(
      'Drift transaction deletes child tables before block_list (FK-safe order)',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-05',
        );
      },
    );

    test(
      'SharedPreferences.clear() called after Drift transaction',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-05',
        );
      },
    );

    test(
      'cancelDailyReminder() called to clear pending alarm',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-05',
        );
      },
    );

    test(
      '5 providers invalidated in order (D-14 + Pitfall 2)',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-05',
        );
      },
    );

    test(
      'context.go("/onboarding/welcome") called after wipe (D-14)',
      () {
        markTestSkipped(
          'RED stub — Phase 6 Wave 0; implementation in 06-05',
        );
      },
    );
  });
}
