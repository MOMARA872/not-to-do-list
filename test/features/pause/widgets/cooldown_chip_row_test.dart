// Plan 04-07 — Task 04-07-03: CooldownChipRow widget tests.
//
// D-04 contract:
//   CooldownChipRow is a M3 SegmentedButton clone of the Phase-2
//   BlockModeSegmented widget. Chips: [1m] [3m] [5m] [10m].
//   No default pre-selection — user must tap to start cooldown.
//   Tapping a different chip while running re-starts at new duration.
//   No [+Custom] chip (DIFF-03 v1.x deferred).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/pause/widgets/cooldown_chip_row.dart';

Widget _buildRow({
  int? selectedSeconds,
  required ValueChanged<int> onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: CooldownChipRow(
        selectedSeconds: selectedSeconds,
        onChanged: onChanged,
      ),
    ),
  );
}

void main() {
  group('CooldownChipRow (D-04 SegmentedButton clone of BlockModeSegmented)', () {
    testWidgets(
      'renders 4 chips with labels 1m, 3m, 5m, 10m',
      (tester) async {
        await tester.pumpWidget(_buildRow(
          selectedSeconds: null,
          onChanged: (_) {},
        ));

        expect(find.text('1m'), findsOneWidget);
        expect(find.text('3m'), findsOneWidget);
        expect(find.text('5m'), findsOneWidget);
        expect(find.text('10m'), findsOneWidget);
        // No default pre-selection (D-04) — verify "Cooldown:" label present.
        expect(find.text('Cooldown:'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping each chip calls onChanged with 60/180/300/600',
      (tester) async {
        final tapped = <int>[];

        await tester.pumpWidget(_buildRow(
          selectedSeconds: null,
          onChanged: tapped.add,
        ));

        await tester.tap(find.text('1m'));
        await tester.pump();
        expect(tapped, [60]);

        await tester.tap(find.text('3m'));
        await tester.pump();
        expect(tapped, [60, 180]);

        await tester.tap(find.text('5m'));
        await tester.pump();
        expect(tapped, [60, 180, 300]);

        await tester.tap(find.text('10m'));
        await tester.pump();
        expect(tapped, [60, 180, 300, 600]);
      },
    );
  });
}
