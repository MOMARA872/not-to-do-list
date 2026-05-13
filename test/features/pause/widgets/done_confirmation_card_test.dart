// Plan 04-07 — Task 04-07-03: DoneConfirmationCard widget tests.
//
// D-07 contract:
//   When the LinearProgressIndicator drains to zero, the screen morphs for
//   ~1.5 seconds into a calm confirmation card with the literal string
//   "✓ Cooldown complete" (per CONTEXT.md specifics).
//   No streak callout. No additional copy. Duration: hardcoded 1500ms.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/pause/widgets/done_confirmation_card.dart';

void main() {
  group('DoneConfirmationCard (D-07 — ✓ Cooldown complete, 1.5s)', () {
    testWidgets(
      'renders a Card containing the literal text "✓ Cooldown complete"',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: DoneConfirmationCard()),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('✓ Cooldown complete'), findsOneWidget);
      },
    );
  });
}
