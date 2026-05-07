// Phase 3 Plan 03-01 — Wave 0 stub for LetterAvatar fallback widget.
// Implementation lands in Plan 03-05.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LetterAvatar fallback (DASH-02)', () {
    testWidgets('renders first letter uppercased', (tester) async {
      // Wave 3 — LetterAvatar lands in Plan 03-05.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);

    testWidgets('empty label renders "?"', (tester) async {
      // Wave 3 — LetterAvatar lands in Plan 03-05.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);
  });
}
