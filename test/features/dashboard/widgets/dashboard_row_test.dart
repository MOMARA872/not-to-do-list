import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/dashboard/models/dash_row.dart';
import 'package:not_to_do_list/features/dashboard/widgets/dashboard_row.dart';
import 'package:not_to_do_list/features/list/providers/app_icon_cache_provider.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      // Force cache-miss so LetterAvatar shows up (no Pigeon icon fetch).
      appIconBytesProvider.overrideWith((ref, pkg) async => null),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('DashboardRow bar-fill + highlight (DASH-02 / D-06)', () {
    const notToDoRow = DashRow(
      isNotToDo: true,
      packageName: 'com.instagram.android',
      displayName: 'Instagram',
      foregroundSeconds: 600,
    );
    const otherRow = DashRow(
      isNotToDo: false,
      packageName: 'com.test.filler',
      displayName: 'Filler',
      foregroundSeconds: 300,
    );

    testWidgets('not-to-do row renders 4dp left BorderSide cs.primary', (tester) async {
      await tester.pumpWidget(_wrap(
        const DashboardRow(row: notToDoRow, maxSeconds: 1000),
      ));
      await tester.pump();
      // Verify a Container with a left BorderSide of width 4 exists.
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final dec = c.decoration;
        if (dec is! BoxDecoration) return false;
        final border = dec.border;
        if (border is! Border) return false;
        return border.left.width == 4;
      });
      expect(containers.length, greaterThanOrEqualTo(1));
    });

    testWidgets('non-not-to-do row renders no left border', (tester) async {
      await tester.pumpWidget(_wrap(
        const DashboardRow(row: otherRow, maxSeconds: 1000),
      ));
      await tester.pump();
      // The DashboardRow's outer Container has decoration.border == null.
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(DashboardRow), matching: find.byType(Container)).first,
      );
      final dec = container.decoration as BoxDecoration?;
      expect(dec?.border, isNull);
    });

    testWidgets('LinearProgressIndicator value = foregroundSeconds / maxSeconds clamped', (tester) async {
      await tester.pumpWidget(_wrap(
        const DashboardRow(row: notToDoRow, maxSeconds: 1000),
      ));
      await tester.pump();
      final lpi = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(lpi.value, closeTo(0.6, 0.001)); // 600 / 1000
    });

    testWidgets('renders displayName + duration text', (tester) async {
      await tester.pumpWidget(_wrap(
        const DashboardRow(row: notToDoRow, maxSeconds: 1000),
      ));
      await tester.pump();
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('10m'), findsOneWidget); // 600s = 10m
    });

    testWidgets('maxSeconds=0 yields fillRatio=0 (no crash)', (tester) async {
      const zeroRow = DashRow(
        isNotToDo: false,
        packageName: 'com.test.zero',
        displayName: 'Zero',
        foregroundSeconds: 0,
      );
      await tester.pumpWidget(_wrap(
        const DashboardRow(row: zeroRow, maxSeconds: 0),
      ));
      await tester.pump();
      final lpi = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(lpi.value, 0.0);
    });
  });
}
