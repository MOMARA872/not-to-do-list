// Plan 04-07 — Task 04-07-03: CooldownProgressBar widget tests.
//
// D-05 contract:
//   CooldownProgressBar is a thin LinearProgressIndicator pinned to the
//   top edge of the PauseScreen. Below the selected chip, a small caption
//   reads "X:XX remaining" (M3 BodySmall). The progress bar drains
//   left → right over the chosen cooldown duration.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/pause/widgets/cooldown_progress_bar.dart';

Widget _buildBar({int? totalSeconds, int? remainingMs}) {
  return MaterialApp(
    home: Scaffold(
      body: CooldownProgressBar(
        totalSeconds: totalSeconds,
        remainingMs: remainingMs,
      ),
    ),
  );
}

void main() {
  group(
    'CooldownProgressBar (D-05 LinearProgressIndicator + X:XX remaining caption)',
    () {
      testWidgets(
        'renders SizedBox.shrink when totalSeconds is null',
        (tester) async {
          await tester.pumpWidget(
            _buildBar(totalSeconds: null, remainingMs: null),
          );

          expect(find.byType(LinearProgressIndicator), findsNothing);
          expect(find.textContaining('remaining'), findsNothing);
        },
      );

      testWidgets(
        'renders LinearProgressIndicator and X:XX remaining caption',
        (tester) async {
          // 3m42s remaining of a 10min cooldown.
          // remainingMs = 222000, totalSeconds = 600
          // value = 222000 / (600 * 1000) = 0.37
          await tester.pumpWidget(
            _buildBar(totalSeconds: 600, remainingMs: 222000),
          );

          expect(find.byType(LinearProgressIndicator), findsOneWidget);
          // Caption: ceil(222000/1000)=222s, 222/60=3min, 222%60=42s → "3:42 remaining"
          expect(find.text('3:42 remaining'), findsOneWidget);

          final progressBar = tester.widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          );
          // value = 222000 / 600000 ≈ 0.37
          expect(progressBar.value, closeTo(0.37, 0.01));
        },
      );
    },
  );
}
