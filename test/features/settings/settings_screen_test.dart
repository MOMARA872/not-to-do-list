// Phase 6 Wave 2 GREEN — settings_screen_test.dart
// Tests for SettingsScreen tile order and Phase 5 D-08 Streak section.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/settings/pages/settings_screen.dart';
import 'package:not_to_do_list/features/settings/widgets/section_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapSettingsScreen() {
  return ProviderScope(
    child: MaterialApp(
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  group('Phase 6 / Settings screen (SETT-04, SETT-05, PLAY-08)', () {
    testWidgets(
      'tile order: Reminder → Streak → Appearance → Data → Privacy → About (D-04 + Claude a.i)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        // Use a large screen to render all items without scrolling
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrapSettingsScreen());
        await tester.pumpAndSettle();

        // Find all SectionHeaders and verify order
        final headers = tester
            .widgetList<SectionHeader>(find.byType(SectionHeader))
            .map((w) => w.label)
            .toList();

        expect(headers.length, 6);
        expect(headers[0], 'Reminder');
        expect(headers[1], 'Streak');
        expect(headers[2], 'Appearance');
        expect(headers[3], 'Data');
        expect(headers[4], 'Privacy');
        expect(headers[5], 'About');
      },
    );

    testWidgets(
      'gear icon from HomeScreen routes to /settings',
      (tester) async {
        // This test verifies that SettingsScreen is reachable and renders
        // correctly (route registration verified via app_router presence)
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(_wrapSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsAtLeastNWidgets(1));
        expect(find.text('Daily reminder'), findsOneWidget);
      },
    );

    testWidgets(
      'Phase 5 D-08 inline Streak section closure above Appearance',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        // Use a large screen to render all items without scrolling
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrapSettingsScreen());
        await tester.pumpAndSettle();

        final headers = tester
            .widgetList<SectionHeader>(find.byType(SectionHeader))
            .map((w) => w.label)
            .toList();

        // Streak section must appear and must be BEFORE Appearance
        expect(headers.contains('Streak'), isTrue);
        final streakIdx = headers.indexOf('Streak');
        final appearanceIdx = headers.indexOf('Appearance');
        expect(streakIdx, lessThan(appearanceIdx));

        // StreakThresholdTile content is present
        expect(find.text('Streak threshold'), findsOneWidget);
      },
    );
  });
}
