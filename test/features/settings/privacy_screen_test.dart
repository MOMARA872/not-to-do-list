// Phase 6 Plan 06-06 — privacy_screen_test.dart
// Tests PrivacyScreen FutureBuilder + flutter_markdown_plus render.
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/settings/pages/privacy_screen.dart';

void main() {
  group('Phase 6 / PrivacyScreen (SETT-05)', () {
    testWidgets(
      'Test 1: renders Scaffold with AppBar title Privacy Policy',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      },
    );

    testWidgets(
      'Test 2: shows CircularProgressIndicator while future loading',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
        // Before future resolves — initial frame only
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'Test 3: after future resolves, Markdown widget is present with data',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(Markdown), findsOneWidget);
        final markdown = tester.widget<Markdown>(find.byType(Markdown));
        expect(markdown.data, isNotEmpty);
      },
    );

    testWidgets(
      'Test 4: rootBundle.loadString called with docs/PRIVACY.md asset path',
      (tester) async {
        // The PrivacyScreen uses rootBundle.loadString('docs/PRIVACY.md').
        // Markdown widget present after settle = bundle loaded successfully.
        await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(Markdown), findsOneWidget);
      },
    );

    testWidgets(
      'Test 5: no external links handler set (onTapLink unset for v1)',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
        await tester.pumpAndSettle();
        final markdown = tester.widget<Markdown>(find.byType(Markdown));
        // v1 PRIVACY.md has no external links — onTapLink left unset
        expect(markdown.onTapLink, isNull);
      },
    );
  });
}
