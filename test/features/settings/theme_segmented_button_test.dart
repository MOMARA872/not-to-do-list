// Phase 6 Wave 2 GREEN — theme_segmented_button_test.dart
// Tests for ThemeTile SegmentedButton behavior (SETT-04).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';
import 'package:not_to_do_list/features/settings/widgets/theme_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('Phase 6 / ThemeTile SegmentedButton (SETT-04)', () {
    testWidgets(
      '3 segments labelled Light, Dark, System',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(_wrap(const ThemeTile()));
        await tester.pumpAndSettle();

        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
        expect(find.text('System'), findsOneWidget);
      },
    );

    testWidgets(
      'tap segment writes themeModeProvider',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: ThemeTile()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Default is system — tap Light
        await tester.tap(find.text('Light'));
        await tester.pumpAndSettle();

        expect(container.read(themeModeProvider).value, ThemeMode.light);
      },
    );

    testWidgets(
      'selected set has exactly one element at all times',
      (tester) async {
        SharedPreferences.setMockInitialValues({'theme_mode': 2}); // dark
        await tester.pumpWidget(_wrap(const ThemeTile()));
        await tester.pumpAndSettle();

        // SegmentedButton with single selection should have exactly one selected
        final segBtn = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(segBtn.selected.length, 1);
        expect(segBtn.selected.first, ThemeMode.dark);
      },
    );
  });
}
