// Phase 6 Plan 06-06 — privacy_screen_test.dart
// Tests PrivacyScreen FutureBuilder + flutter_markdown_plus render.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/settings/pages/privacy_screen.dart';

void main() {
  group('Phase 6 / PrivacyScreen (SETT-05)', () {
    // Source-of-truth string for source-level checks.
    final source = File(
      'lib/features/settings/pages/privacy_screen.dart',
    ).readAsStringSync();

    testWidgets(
      'Test 1: renders Scaffold with AppBar title Privacy Policy',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
        // Pump first frame — AppBar renders synchronously
        await tester.pump();
        expect(find.byType(AppBar), findsOneWidget);
        // 'Privacy Policy' appears in AppBar; after future resolves it may also
        // appear in the Markdown heading rendered from docs/PRIVACY.md
        expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Test 2: shows CircularProgressIndicator while future loading',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
        // First pump — future has not yet completed; shows loading state
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    test(
      'Test 3: source contains Markdown(data: ...) render of asset data',
      () {
        // Acceptance criterion: source contains "Markdown(data:"
        expect(
          source.contains('Markdown(data:'),
          isTrue,
          reason: 'PrivacyScreen must render via Markdown(data: snap.data!)',
        );
      },
    );

    test(
      'Test 4: rootBundle.loadString called with docs/PRIVACY.md asset path',
      () {
        // Acceptance criterion: source contains the exact asset path.
        expect(
          source.contains("rootBundle.loadString('docs/PRIVACY.md')"),
          isTrue,
          reason: 'PrivacyScreen must use rootBundle.loadString("docs/PRIVACY.md")',
        );
      },
    );

    test(
      'Test 5: flutter_markdown_plus import used (NOT deprecated flutter_markdown)',
      () {
        expect(
          source.contains(
            "import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'",
          ),
          isTrue,
          reason:
              'Must import flutter_markdown_plus (NOT flutter_markdown which is deprecated)',
        );
        expect(
          source.contains("import 'package:flutter_markdown/"),
          isFalse,
          reason: 'Must NOT import deprecated flutter_markdown package',
        );
      },
    );

    testWidgets(
      'Test 6: widget tree contains PrivacyScreen Scaffold structure',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
        await tester.pump();
        // Widget tree contains FutureBuilder
        expect(find.byType(FutureBuilder<String>), findsOneWidget);
        // Scaffold is present
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    test(
      'Test 7: onTapLink not set (v1 PRIVACY.md has no external links)',
      () {
        // v1 PRIVACY.md has no external links — onTapLink should not be set.
        // Source-level check: no onTapLink: callback in PrivacyScreen.
        expect(
          source.contains('onTapLink:'),
          isFalse,
          reason: 'v1 PRIVACY.md has no external links — onTapLink must be unset',
        );
      },
    );
  });
}
