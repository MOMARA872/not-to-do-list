// Plan 02-06: Widget tests for ScheduleEditor (LIST-09).
//
// Covers: default 'Always on' state, toggle reveals From/To buttons + 7
// weekday chips, toggle off emits (null, null, null), cross-midnight
// annotation when end < start, streak-day annotation always shown when
// expanded, weekday-chip labels exactly M T W T F S S in order.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/list/widgets/schedule_editor.dart';

class _Capture {
  int? start;
  int? end;
  int? mask;
  int callCount = 0;

  void record(int? s, int? e, int? m) {
    start = s;
    end = e;
    mask = m;
    callCount++;
  }
}

Widget _wrap(ScheduleEditor child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

void main() {
  group('ScheduleEditor (LIST-09)', () {
    testWidgets(
      "default state shows 'Always on' label and Switch=off",
      (tester) async {
        final capture = _Capture();
        await tester.pumpWidget(
          _wrap(
            ScheduleEditor(
              startMinutes: null,
              endMinutes: null,
              weekdayMask: null,
              onChanged: capture.record,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Always on'), findsOneWidget);
        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isFalse);
        // Streak annotation is only shown when expanded.
        expect(find.text('Streak day resets at 4:00 AM.'), findsNothing);
      },
    );

    testWidgets(
      'toggling Switch on emits (540, 1320, 0x7F) defaults',
      (tester) async {
        final capture = _Capture();
        await tester.pumpWidget(
          _wrap(
            ScheduleEditor(
              startMinutes: null,
              endMinutes: null,
              weekdayMask: null,
              onChanged: capture.record,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(capture.callCount, 1);
        expect(capture.start, 540);
        expect(capture.end, 1320);
        expect(capture.mask, 0x7F);
      },
    );

    testWidgets(
      'toggling Switch off calls onChanged with (null, null, null)',
      (tester) async {
        final capture = _Capture();
        await tester.pumpWidget(
          _wrap(
            ScheduleEditor(
              startMinutes: 540,
              endMinutes: 1320,
              weekdayMask: 0x7F,
              onChanged: capture.record,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(capture.callCount, 1);
        expect(capture.start, isNull);
        expect(capture.end, isNull);
        expect(capture.mask, isNull);
      },
    );

    testWidgets(
      'cross-midnight annotation appears when endMinutes < startMinutes',
      (tester) async {
        final capture = _Capture();
        // 22:00 → 02:00 next day.
        await tester.pumpWidget(
          _wrap(
            ScheduleEditor(
              startMinutes: 1320,
              endMinutes: 120,
              weekdayMask: 0x7F,
              onChanged: capture.record,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Window crosses midnight — treated as one continuous block.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "streak day annotation 'Streak day resets at 4:00 AM.' always present "
      'when expanded',
      (tester) async {
        final capture = _Capture();
        await tester.pumpWidget(
          _wrap(
            ScheduleEditor(
              startMinutes: 540,
              endMinutes: 1320,
              weekdayMask: 0x7F,
              onChanged: capture.record,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Streak day resets at 4:00 AM.'), findsOneWidget);
      },
    );

    testWidgets(
      'weekday chips render exactly 7 labels in order M T W T F S S',
      (tester) async {
        final capture = _Capture();
        await tester.pumpWidget(
          _wrap(
            ScheduleEditor(
              startMinutes: 540,
              endMinutes: 1320,
              weekdayMask: 0x7F,
              onChanged: capture.record,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the FilterChips and inspect their label text in order.
        final chips =
            tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
        expect(chips.length, 7);
        final labels = chips
            .map((c) => (c.label as Text).data)
            .toList();
        expect(labels, <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']);
      },
    );
  });
}
