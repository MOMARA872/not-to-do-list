// Phase 4 — pause-ux-the-wedge: source-policy invariants.
//
// Validates 5 gaps identified by the Nyquist auditor:
//   PAUS-01 — D-11 Intent contract (service → PauseActivity)
//   PAUS-08 — lock-screen flags before super.onCreate (D-15)
//   T-02    — fail-closed extras validation: finish() before super.onCreate
//   T-03    — PauseActivity declared android:exported="false"
//   REL-01  — no companion FGS in NotToDoAccessibilityService (CD-01)
//
// All checks are source-policy assertions (no runtime behavior).
// Run from project root: flutter test test/policy/phase_4_invariants_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4 source-policy invariants', () {
    // ---- PAUS-01: D-11 Intent contract ----
    test(
      'PAUS-01: NotToDoAccessibilityService launches PauseActivity '
      'with the D-11 Intent contract',
      () {
        final src = File(
          'android/app/src/main/kotlin/com/nottodo/not_to_do_list'
          '/service/NotToDoAccessibilityService.kt',
        ).readAsStringSync();

        // Explicit-component launch — T-4-05-03
        expect(
          src.contains('Intent(this, PauseActivity::class.java)'),
          isTrue,
          reason:
              'PAUS-01: NotToDoAccessibilityService must launch PauseActivity '
              'via explicit-component Intent(this, PauseActivity::class.java)',
        );

        // Must carry FLAG_ACTIVITY_NEW_TASK (D-11)
        expect(
          src.contains('FLAG_ACTIVITY_NEW_TASK'),
          isTrue,
          reason:
              'PAUS-01: Intent must add FLAG_ACTIVITY_NEW_TASK (D-11 contract)',
        );

        // All 4 lowercase_snake extras (D-11)
        for (final extra in <String>[
          '"extra_blocked_package"',
          '"extra_entry_id"',
          '"extra_block_mode"',
          '"extra_triggered_at_ms"',
        ]) {
          expect(
            src.contains(extra),
            isTrue,
            reason:
                'PAUS-01: NotToDoAccessibilityService must put extra $extra '
                'on the PauseActivity Intent (D-11)',
          );
        }
      },
    );

    // ---- PAUS-08: lock-screen flags before super.onCreate ----
    test(
      'PAUS-08: PauseActivity.onCreate calls setShowWhenLocked + '
      'setTurnScreenOn before super.onCreate (D-15)',
      () {
        final src = File(
          'android/app/src/main/kotlin/com/nottodo/not_to_do_list'
          '/PauseActivity.kt',
        ).readAsStringSync();

        // Both flags must be present at all
        expect(
          src.contains('setShowWhenLocked(true)'),
          isTrue,
          reason:
              'PAUS-08: PauseActivity must call setShowWhenLocked(true) (D-15)',
        );
        expect(
          src.contains('setTurnScreenOn(true)'),
          isTrue,
          reason:
              'PAUS-08: PauseActivity must call setTurnScreenOn(true) (D-15)',
        );

        // Order constraint: both flags must appear BEFORE the first
        // super.onCreate( in the file.
        final showWhenLockedOffset =
            src.indexOf('setShowWhenLocked(true)');
        final turnScreenOnOffset =
            src.indexOf('setTurnScreenOn(true)');
        final firstSuperOnCreateOffset =
            src.indexOf('super.onCreate(');

        expect(
          firstSuperOnCreateOffset,
          greaterThan(-1),
          reason: 'PAUS-08: PauseActivity must call super.onCreate()',
        );
        expect(
          showWhenLockedOffset,
          greaterThan(-1),
          reason: 'PAUS-08: setShowWhenLocked(true) not found',
        );
        expect(
          turnScreenOnOffset,
          greaterThan(-1),
          reason: 'PAUS-08: setTurnScreenOn(true) not found',
        );

        expect(
          showWhenLockedOffset,
          lessThan(firstSuperOnCreateOffset),
          reason:
              'PAUS-08: setShowWhenLocked(true) must appear BEFORE '
              'super.onCreate() (D-15 — window flags must be set before '
              'window attachment)',
        );
        expect(
          turnScreenOnOffset,
          lessThan(firstSuperOnCreateOffset),
          reason:
              'PAUS-08: setTurnScreenOn(true) must appear BEFORE '
              'super.onCreate() (D-15 — window flags must be set before '
              'window attachment)',
        );
      },
    );

    // ---- T-02: fail-closed extras validation ----
    test(
      'T-02: PauseActivity fails closed (finish() before super.onCreate) '
      'on malformed Intent extras',
      () {
        final src = File(
          'android/app/src/main/kotlin/com/nottodo/not_to_do_list'
          '/PauseActivity.kt',
        ).readAsStringSync();

        // All 4 guard tokens must be present in the validation block
        for (final token in <String>[
          'entryId == -1L',
          'blockedPackage.isEmpty()',
          'blockMode != "soft" && blockMode != "hard"',
          'triggeredAtMs <= 0L',
        ]) {
          expect(
            src.contains(token),
            isTrue,
            reason:
                'T-02: PauseActivity validation block must contain "$token" '
                '— fail-closed guard absent',
          );
        }

        // finish() must appear in the source
        expect(
          src.contains('finish()'),
          isTrue,
          reason: 'T-02: PauseActivity must call finish() on malformed extras',
        );

        // Order constraint: finish() must appear BEFORE the last (normal-path)
        // super.onCreate(). We check: finish() offset < last super.onCreate
        // offset. The fail-closed branch skips super.onCreate; the normal
        // path calls it after validation passes. The last super.onCreate is the
        // normal-path call — finish() in the guard branch must precede it.
        final finishOffset = src.indexOf('finish()');
        final lastSuperOnCreateOffset = src.lastIndexOf('super.onCreate(');

        expect(
          finishOffset,
          greaterThan(-1),
          reason: 'T-02: finish() not found in PauseActivity',
        );
        expect(
          lastSuperOnCreateOffset,
          greaterThan(-1),
          reason: 'T-02: super.onCreate() not found in PauseActivity',
        );
        expect(
          finishOffset,
          lessThan(lastSuperOnCreateOffset),
          reason:
              'T-02: finish() (fail-closed dismissal) must appear BEFORE '
              'the normal-path super.onCreate() — malformed Intent must '
              'dismiss without binding the Flutter engine',
        );
      },
    );

    // ---- T-03: PauseActivity android:exported="false" ----
    test(
      'T-03: PauseActivity declared android:exported="false" '
      'in AndroidManifest',
      () {
        final src = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();

        // Extract the PauseActivity activity block
        // Strategy: find the substring from android:name=".PauseActivity"
        // to the closing /> of that element.
        const nameToken = 'android:name=".PauseActivity"';
        final nameIndex = src.indexOf(nameToken);
        expect(
          nameIndex,
          greaterThan(-1),
          reason:
              'T-03: AndroidManifest must declare an activity with '
              'android:name=".PauseActivity"',
        );

        // Scan forward from the name token to the closing />
        final closingIndex = src.indexOf('/>', nameIndex);
        expect(
          closingIndex,
          greaterThan(-1),
          reason:
              'T-03: could not find closing /> for .PauseActivity activity element',
        );

        final pauseActivityBlock = src.substring(nameIndex, closingIndex + 2);
        expect(
          pauseActivityBlock.contains('android:exported="false"'),
          isTrue,
          reason:
              'T-03: PauseActivity must be declared android:exported="false" '
              '— external apps must not be able to launch PauseActivity '
              '(T-02 / T-4-05-03 mitigation)',
        );
      },
    );

    // ---- REL-01 (CD-01): no companion FGS shipped ----
    test(
      'REL-01 (CD-01): NotToDoAccessibilityService does not start '
      'a foreground service',
      () {
        final src = File(
          'android/app/src/main/kotlin/com/nottodo/not_to_do_list'
          '/service/NotToDoAccessibilityService.kt',
        ).readAsStringSync();

        // Strip comment lines before scanning so doc-comment references
        // to the token NAMES don't cause false positives.
        final codeOnly = src
            .split('\n')
            .where((line) => !RegExp(r'^\s*(//|\*)').hasMatch(line))
            .join('\n');

        expect(
          codeOnly.contains('startForeground('),
          isFalse,
          reason:
              'REL-01 (CD-01): NotToDoAccessibilityService must NOT call '
              'startForeground() — Phase 4 ships without companion FGS '
              '(CD-01 decision)',
        );
        expect(
          codeOnly.contains('NotificationCompat.Builder'),
          isFalse,
          reason:
              'REL-01 (CD-01): NotToDoAccessibilityService must NOT reference '
              'NotificationCompat.Builder — no FGS notification in Phase 4',
        );
        expect(
          codeOnly.contains('FOREGROUND_SERVICE'),
          isFalse,
          reason:
              'REL-01 (CD-01): NotToDoAccessibilityService must NOT reference '
              'FOREGROUND_SERVICE token — no FGS in Phase 4 (CD-01)',
        );
      },
    );
  });
}
