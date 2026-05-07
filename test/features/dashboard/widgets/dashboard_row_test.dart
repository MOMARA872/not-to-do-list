// Phase 3 Plan 03-01 — Wave 0 stub for DashboardRow widget.
// Implementation lands in Plan 03-05.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardRow bar-fill + highlight (DASH-02 / D-06)', () {
    testWidgets('not-to-do row renders 4dp left accent border + 100% icon opacity', (tester) async {
      // Wave 3 — DashboardRow lands in Plan 03-05.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);

    testWidgets('non-not-to-do row renders no border + 60% icon opacity', (tester) async {
      // Wave 3 — DashboardRow lands in Plan 03-05.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);

    testWidgets('LinearProgressIndicator value = foregroundSeconds / maxSeconds clamped', (tester) async {
      // Wave 3 — DashboardRow lands in Plan 03-05.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    }, skip: true);
  });
}
