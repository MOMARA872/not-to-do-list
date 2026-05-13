// Phase 2 Plan 02-10 — cross-tree PLAY-policy + v1-scope invariants.
//
// Catches a regression at the next test run if any future phase introduces
// a forbidden symbol (autonomous-action AccessibilityService calls, the
// QUERY_ALL_PACKAGES / SYSTEM_ALERT_WINDOW / BIND_DEVICE_ADMIN permissions,
// or any of the v1-scope-out tokens for parental-control / kid-mode / etc.).
//
// Each invariant is a separate `test(...)` block so a failure points at
// exactly which rule broke. The test reads source files from disk (it is
// run from the project root by `flutter test`) and `RegExp(...).hasMatch(...)`
// checks for forbidden tokens — same absence-grep idiom Phase 1 established
// in `test/domain/providers/blocked_app_detector_provider_test.dart`.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 2 cross-tree policy invariants', () {
    // ---- PLAY-02: AccessibilityService never autonomous (Dart side) ----
    test(
      'PLAY-02: no Dart source declares performAction / '
      'performGlobalAction / dispatchGesture',
      () {
        final forbidden = <String>[
          r'\bperformAction\s*\(',
          r'\bperformGlobalAction\s*\(',
          r'\bdispatchGesture\s*\(',
        ];
        for (final entity
            in Directory('lib').listSync(recursive: true).whereType<File>()) {
          if (!entity.path.endsWith('.dart')) continue;
          if (entity.path.endsWith('.g.dart')) continue; // generated, exempt
          final src = entity.readAsStringSync();
          for (final pat in forbidden) {
            expect(
              RegExp(pat).hasMatch(src),
              isFalse,
              reason: 'PLAY-02: ${entity.path} contains forbidden symbol '
                  'matching $pat',
            );
          }
        }
      },
    );

    // ---- PLAY-02: AccessibilityService never autonomous (Kotlin side) ----
    test(
      'PLAY-02: no Kotlin source under platform/ declares performAction / '
      'performGlobalAction / dispatchGesture',
      () {
        final dir = Directory(
          'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform',
        );
        if (!dir.existsSync()) return; // platform impls land in Plan 02-03
        for (final entity in dir.listSync(recursive: true).whereType<File>()) {
          if (!entity.path.endsWith('.kt')) continue;
          final src = entity.readAsStringSync();
          for (final pat in <String>[
            r'\bperformAction\s*\(',
            r'\bperformGlobalAction\s*\(',
            r'\bdispatchGesture\s*\(',
          ]) {
            expect(
              RegExp(pat).hasMatch(src),
              isFalse,
              reason: 'PLAY-02: ${entity.path} contains forbidden symbol '
                  'matching $pat',
            );
          }
        }
      },
    );

    // ---- PLAY-02 (Phase 4 expanded scope): service/ + root activity files ----
    test(
      'PLAY-02: no Kotlin source under service/ or the root not_to_do_list/ '
      'package declares performAction / performGlobalAction / dispatchGesture',
      () {
        final dirs = <String>[
          'android/app/src/main/kotlin/com/nottodo/not_to_do_list/service',
          'android/app/src/main/kotlin/com/nottodo/not_to_do_list', // root only — recursive=false
        ];
        final forbidden = <String>[
          r'\bperformAction\s*\(',
          r'\bperformGlobalAction\s*\(',
          r'\bdispatchGesture\s*\(',
        ];
        for (final dir in dirs) {
          final d = Directory(dir);
          if (!d.existsSync()) continue;
          // For the root not_to_do_list/ scan, recursive=false so we only catch
          // root files (MainActivity.kt, PauseActivity.kt) — sub-packages
          // (platform/, service/) are scanned by their own dedicated tests above.
          final recursive = !dir.endsWith('/not_to_do_list');
          for (final entity
              in d.listSync(recursive: recursive).whereType<File>()) {
            if (!entity.path.endsWith('.kt')) continue;
            final src = entity.readAsStringSync();
            // Strip comment lines (// or leading * inside /** */) before scanning
            // to allow doc-comment references to forbidden token NAMES (the Phase 1
            // doc comment header on NotToDoAccessibilityService.kt mentions PLAY-02
            // by name; that's allowed). Code lines containing the literal calls
            // are NOT.
            final codeOnly = src
                .split('\n')
                .where((line) => !RegExp(r'^\s*(//|\*)').hasMatch(line))
                .join('\n');
            for (final pat in forbidden) {
              expect(
                RegExp(pat).hasMatch(codeOnly),
                isFalse,
                reason: 'PLAY-02 (Phase 4 expanded scope): ${entity.path} '
                    'contains forbidden symbol matching $pat in CODE line',
              );
            }
          }
        }
      },
    );

    // ---- PLAY-03: AccessibilityService events scoped to
    //               typeWindowStateChanged ----
    test(
      'PLAY-03: a11y service config does NOT request canRetrieveWindowContent '
      '/ canPerformGestures / flagRequestFilterKeyEvents',
      () {
        // Phase 1 placed the config at
        // android/app/src/main/res/xml/not_todo_a11y_config.xml.
        // Tolerate alternative paths that other phases may introduce.
        final candidates = <String>[
          'android/app/src/main/res/xml/not_todo_a11y_config.xml',
          'android/app/src/main/res/xml/accessibility_service_config.xml',
          'android/app/src/main/res/xml/not_to_do_accessibility_config.xml',
        ];
        var foundAny = false;
        for (final path in candidates) {
          final f = File(path);
          if (!f.existsSync()) continue;
          foundAny = true;
          final src = f.readAsStringSync();
          expect(
            src.contains('canRetrieveWindowContent="true"'),
            isFalse,
            reason: 'PLAY-03: $path must not enable canRetrieveWindowContent',
          );
          expect(
            src.contains('canPerformGestures="true"'),
            isFalse,
            reason: 'PLAY-03: $path must not enable canPerformGestures',
          );
          expect(
            src.contains('flagRequestFilterKeyEvents'),
            isFalse,
            reason:
                'PLAY-03: $path must not request flagRequestFilterKeyEvents',
          );
        }
        expect(
          foundAny,
          isTrue,
          reason: 'PLAY-03: expected an accessibility-service config XML to '
              'exist under android/app/src/main/res/xml/ — none found',
        );
      },
    );

    // ---- PLAY-04: <queries> + LAUNCHER, NOT QUERY_ALL_PACKAGES ----
    test('PLAY-04: AndroidManifest does not declare QUERY_ALL_PACKAGES', () {
      final src =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
        src.contains('android.permission.QUERY_ALL_PACKAGES'),
        isFalse,
        reason: 'PLAY-04: app uses <queries> + LAUNCHER, never '
            'QUERY_ALL_PACKAGES',
      );
      // Sanity: the <queries> element + LAUNCHER intent filter ARE present
      // (Phase 1 invariant).
      expect(src.contains('<queries>'), isTrue);
      expect(src.contains('android.intent.category.LAUNCHER'), isTrue);
    });

    // ---- PLAY-05: no SYSTEM_ALERT_WINDOW ----
    test('PLAY-05: AndroidManifest does not declare SYSTEM_ALERT_WINDOW', () {
      final src =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(src.contains('android.permission.SYSTEM_ALERT_WINDOW'), isFalse);
    });

    // ---- PLAY-06: prominent disclosure copy contains the 5 verbatim
    //               phrases (mirrors docs/play-declaration.md §4) ----
    test(
      'PLAY-06: accessibility_step.dart contains all 5 verbatim disclosure '
      'phrases',
      () {
        final src = File(
          'lib/features/onboarding/pages/accessibility_step.dart',
        ).readAsStringSync();
        for (final phrase in <String>[
          'package name',
          'only when a window-state-changed event fires',
          'never reads your screen',
          'never sends anything off your device',
          'disable this at any time',
        ]) {
          expect(
            src.contains(phrase),
            isTrue,
            reason: 'PLAY-06: missing verbatim phrase: "$phrase"',
          );
        }
      },
    );

    // ---- v1 scope: anti-uninstall is OUT (no BIND_DEVICE_ADMIN anywhere) ----
    test('v1 scope: no BIND_DEVICE_ADMIN anywhere in android/', () {
      for (final entity
          in Directory('android').listSync(recursive: true).whereType<File>()) {
        final p = entity.path;
        if (!(p.endsWith('.kt') || p.endsWith('.xml') || p.endsWith('.java'))) {
          continue;
        }
        final src = entity.readAsStringSync();
        expect(
          src.contains('BIND_DEVICE_ADMIN'),
          isFalse,
          reason: 'v1 scope: anti-uninstall is OUT OF v1 (PROJECT.md). '
              '${entity.path} references BIND_DEVICE_ADMIN.',
        );
      }
    });

    // ---- v1 scope: lib/ contains no parental-control / kid-mode /
    //               website-blocking / 18+ filter surfaces ----
    test(
      'v1 scope: lib/ contains no Parent-PIN / KidMode / website-blocking / '
      '18+ filter surfaces',
      () {
        // Token-based heuristic: these strings should not appear in any
        // production source. (Test files and planning docs are exempt.)
        final forbiddenTokens = <String>[
          'parentPin',
          'kidMode',
          'KidMode',
          'parentalControl',
          'ParentalControl',
          'contentFilter18',
          'websiteBlock',
          'dnsBlock',
        ];
        for (final entity
            in Directory('lib').listSync(recursive: true).whereType<File>()) {
          if (!entity.path.endsWith('.dart')) continue;
          if (entity.path.endsWith('.g.dart')) continue;
          final src = entity.readAsStringSync();
          for (final tok in forbiddenTokens) {
            expect(
              src.contains(tok),
              isFalse,
              reason: 'v1 scope: ${entity.path} contains out-of-scope token '
                  '"$tok"',
            );
          }
        }
      },
    );
  });
}
