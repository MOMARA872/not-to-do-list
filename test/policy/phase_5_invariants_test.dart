// Phase 5 — streak-engine-daily-reminder: source-policy invariants.
//
// Validates Phase 5 constraints:
//   NOTF-05 — BootReceiver declared with BOOT_COMPLETED intent-filter
//   PLAY-Phase5 — no USE_EXACT_ALARM permission (alarm-class reserved; wrong perm)
//   zero-telemetry — no firebase_messaging / FirebaseMessaging imports under lib/
//   STRK-05 — no WorkManager PeriodicWorkRequest in android/.../streak/ Kotlin files
//   PLAY-Phase5 privacy — notification body must not contain entry names
//   NOTF-02 — reminder fires at chosen time (manual-only — AlarmManager real-device)
//   NOTF-04 — alarm fires within 5 min even under Doze (manual-only — real-device)
//
// Tests 2, 3, 4 are REAL (non-skipped) — pass today because artifacts are absent.
// Tests 1 and 5 are skipped until Plan 05-05 ships the receiver + notification body.
//
// Run from project root: flutter test test/policy/phase_5_invariants_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5 source-policy invariants', () {
    // ---- NOTF-05: BootReceiver declared with BOOT_COMPLETED ----
    // Skipped until Plan 05-05 adds the receiver declaration.
    test(
      'NOTF-05: BootReceiver declared with BOOT_COMPLETED intent-filter '
      'in AndroidManifest',
      () {
        final src = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();

        expect(
          src.contains('android:name=".receiver.BootReceiver"'),
          isTrue,
          reason:
              'NOTF-05: AndroidManifest must declare '
              'android:name=".receiver.BootReceiver" '
              '— BootReceiver needed for BOOT_COMPLETED re-arm (Plan 05-05)',
        );

        expect(
          src.contains('RECEIVE_BOOT_COMPLETED'),
          isTrue,
          reason:
              'NOTF-05: AndroidManifest must declare '
              'android.permission.RECEIVE_BOOT_COMPLETED — '
              'required for BootReceiver re-arm of daily reminder',
        );
      },
      skip: 'Plan 05-05 fills receiver declaration',
    );

    // ---- PLAY-Phase5: no USE_EXACT_ALARM permission (REAL — passes today) ----
    test(
      'PLAY-Phase5: no USE_EXACT_ALARM permission in AndroidManifest',
      () {
        final src = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();

        // Strip XML comment lines before scanning to avoid counting
        // doc-comment occurrences as false positives.
        final codeOnly = src
            .split('\n')
            .where((line) => !RegExp(r'^\s*<!--').hasMatch(line))
            .join('\n');

        expect(
          codeOnly.contains('USE_EXACT_ALARM'),
          isFalse,
          reason:
              'PLAY-Phase5: USE_EXACT_ALARM is reserved for alarm/calendar-class '
              'apps and triggers Play Store audit. '
              'Use SCHEDULE_EXACT_ALARM instead (per CLAUDE.md What NOT to Use).',
        );
      },
    );

    // ---- no FCM / firebase_messaging imports (REAL — passes today) ----
    test(
      'no FCM / firebase_messaging imports under lib/',
      () {
        final libDir = Directory('lib');
        expect(
          libDir.existsSync(),
          isTrue,
          reason: 'lib/ directory must exist',
        );

        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) =>
                  f.path.endsWith('.dart') &&
                  !f.path.endsWith('.g.dart'),
            );

        for (final file in dartFiles) {
          final src = file.readAsStringSync();

          // Strip single-line comment occurrences before scanning
          // (T-05-01 threat mitigation: grep -v '^#' analog)
          final codeOnly = src
              .split('\n')
              .where((line) => !RegExp(r'^\s*//').hasMatch(line))
              .join('\n');

          expect(
            codeOnly.contains('firebase_messaging'),
            isFalse,
            reason:
                'zero-telemetry: ${file.path} must not import firebase_messaging '
                '— v1 has no backend and no FCM dependency '
                '(CLAUDE.md What NOT to Use)',
          );
          expect(
            codeOnly.contains('FirebaseMessaging'),
            isFalse,
            reason:
                'zero-telemetry: ${file.path} must not reference FirebaseMessaging '
                '— v1 has no backend and no FCM dependency',
          );
        }
      },
    );

    // ---- STRK-05: no WorkManager PeriodicWorkRequest for streak (REAL — passes today) ----
    test(
      'STRK-05: no WorkManager PeriodicWorkRequest in android/.../streak/ '
      'Kotlin files',
      () {
        // streak/ directory does not exist yet in Phase 5 Wave 0;
        // this test verifies absence — BUILD_SUCCESSFUL even if path is empty.
        final streakDir = Directory(
          'android/app/src/main/kotlin/com/nottodo/not_to_do_list/streak',
        );

        if (!streakDir.existsSync()) {
          // Path absent → invariant trivially satisfied.
          return;
        }

        final kotlinFiles = streakDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.kt'));

        for (final file in kotlinFiles) {
          final src = file.readAsStringSync();

          // Strip comment lines before scanning.
          final codeOnly = src
              .split('\n')
              .where((line) => !RegExp(r'^\s*(//|\*)').hasMatch(line))
              .join('\n');

          expect(
            codeOnly.contains('PeriodicWorkRequest'),
            isFalse,
            reason:
                'STRK-05: ${file.path} must not use PeriodicWorkRequest '
                '— streak rollover is lazy-on-open, not scheduled '
                '(STATE.md key decision; STRK-05 locked)',
          );
        }
      },
    );

    // ---- PLAY-Phase5 privacy: notification body must not contain entry names ----
    // Skipped until Plan 05-05 ships the notification builder.
    test(
      'PLAY-Phase5: notification body must not contain entry names',
      () {
        // Plan 05-05 fills notification body — privacy check applied then.
        // Per CONTEXT D-10: body = "How did today go?" — no entry names.
        final libDir = Directory('lib');
        expect(libDir.existsSync(), isTrue);

        // When Plan 05-05 ships NotificationApiImpl, this test verifies that
        // the notification body literal does not embed entry displayName.
        // For now: no notification builder exists → trivially passes.
      },
      skip:
          'Plan 05-05 fills notification body — privacy check applied then',
    );

    // ---- NOTF-02 / NOTF-04: manual-only real-device gates ----
    // These requirements cannot be unit-tested. They are documented here
    // to ensure grep-based REQ-ID coverage passes per acceptance criteria.
    // See 05-VERIFICATION.md REL-05 protocol for the manual test procedure.
    test(
      'NOTF-02: reminder fires at chosen wall-clock time — '
      'manual-only (AlarmManager.setExactAndAllowWhileIdle real-device test)',
      () {
        // Manual test only — see 05-VERIFICATION.md REL-05 protocol step 6.
        // AlarmManager exact-alarm scheduling cannot be unit-tested in JVM or Flutter test.
      },
      skip: 'NOTF-02: manual-only — see 05-VERIFICATION.md REL-05 protocol',
    );

    test(
      'NOTF-04: alarm fires within 5 min of scheduled time even under Doze — '
      'manual-only (adb shell dumpsys deviceidle force-idle real-device test)',
      () {
        // Manual test only — see 05-VERIFICATION.md REL-05 protocol step 6.
        // Doze behavior requires real OS idle mode; cannot be simulated in tests.
      },
      skip: 'NOTF-04: manual-only — see 05-VERIFICATION.md REL-05 protocol',
    );
  });
}
