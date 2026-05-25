// Phase 6 Wave 2 GREEN — about_tile_test.dart
// Tests for AboutTile version format (PLAY-08, Pitfall 7).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/settings/widgets/about_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('Phase 6 / AboutTile (PLAY-08)', () {
    testWidgets(
      'renders version in "1.0.0 (1)" format from PackageInfo (Pitfall 7)',
      (tester) async {
        // Set up PackageInfo mock data
        PackageInfo.setMockInitialValues(
          appName: 'Not To-Do List',
          packageName: 'com.nottodo.not_to_do_list',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
          installerStore: null,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AboutTile()),
          ),
        );
        // Wait for the FutureBuilder to complete
        await tester.pumpAndSettle();

        // Should show "1.0.0 (1)" — parens, NOT "1.0.0+1" (Pitfall 7)
        expect(find.text('1.0.0 (1)'), findsOneWidget);
        // Must NOT show the "+" glue form
        expect(find.text('1.0.0+1'), findsNothing);
        // Title and icon present
        expect(find.text('About'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      },
    );
  });
}
