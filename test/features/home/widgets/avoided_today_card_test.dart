// Phase 3 Plan 03-01 — Wave 0 stub for AvoidedTodayCard (home card).
// Implementation lands in Plan 03-06.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvoidedTodayCard (DASH-05 / D-08 / D-09)', () {
    testWidgets('renders "{X} of {Y} entries succeeded today" when Y > 0', (tester) async {
      // Wave 4 — AvoidedTodayCard lands in Plan 03-06.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);

    testWidgets('renders "No entries yet" when block_list is empty', (tester) async {
      // Wave 4 — AvoidedTodayCard lands in Plan 03-06.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);

    testWidgets('renders "Tracking is offline — tap to fix" when usageAccess=false', (tester) async {
      // Wave 4 — AvoidedTodayCard lands in Plan 03-06.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);

    testWidgets('tap routes to /dashboard when entries > 0 and usageAccess granted', (tester) async {
      // Wave 4 — AvoidedTodayCard lands in Plan 03-06.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);
  });
}
