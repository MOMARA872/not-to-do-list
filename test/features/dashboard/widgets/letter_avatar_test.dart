import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/dashboard/widgets/letter_avatar.dart';

void main() {
  group('LetterAvatar fallback (DASH-02)', () {
    testWidgets('renders first letter uppercased', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LetterAvatar(label: 'instagram'))),
      );
      expect(find.text('I'), findsOneWidget);
    });

    testWidgets('empty label renders "?"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LetterAvatar(label: ''))),
      );
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('uses first character even with multi-byte text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LetterAvatar(label: 'Über'))),
      );
      expect(find.text('Ü'), findsOneWidget);
    });
  });
}
