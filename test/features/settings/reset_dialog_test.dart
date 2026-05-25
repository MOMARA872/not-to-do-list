// Phase 6 Plan 05 — reset_dialog_test.dart
// Tests for the Reset AlertDialog wired in SettingsScreen (SETT-02, D-13).
// Implements 6 behaviours from 06-05-PLAN.md Task 2.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/providers/notification_api_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_complete_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/post_notifications_provider.dart';
import 'package:not_to_do_list/features/reminder/providers/reminder_providers.dart';
import 'package:not_to_do_list/features/settings/pages/settings_screen.dart';
import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';
import 'package:not_to_do_list/features/streak/providers/streak_threshold_provider.dart';
import 'package:not_to_do_list/platform/notification_api.g.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';
import 'package:drift/native.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockNotificationApi extends Mock implements NotificationApi {}

class _MockPermissionStatusApi extends Mock implements PermissionStatusApi {}

// ---------------------------------------------------------------------------
// Test setup helpers
// ---------------------------------------------------------------------------

const _verbatimD13Body =
    'This deletes every entry, streak day, pause event, and check-in. '
    'This cannot be undone.';

/// Pumps the SettingsScreen in a GoRouter context with all providers stubbed.
/// Returns the mock notif api for call verification.
Future<_MockNotificationApi> _pumpSettingsScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'reminder_hour_minute': 1260,
    'theme_mode': 0,
    'streak_threshold_minutes': 5,
  });

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  final mockNotifApi = _MockNotificationApi();
  when(() => mockNotifApi.cancelDailyReminder()).thenAnswer((_) async {});
  when(() => mockNotifApi.scheduleDailyReminder(any(), any()))
      .thenAnswer((_) async {});

  final mockPermApi = _MockPermissionStatusApi();
  when(() => mockPermApi.isPostNotificationsGranted())
      .thenAnswer((_) async => false);

  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (ctx, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/reminder',
        builder: (ctx, _) => const Scaffold(body: Text('Reminder')),
      ),
      GoRoute(
        path: '/settings/export',
        builder: (ctx, _) => const Scaffold(body: Text('Export')),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (ctx, _) => const Scaffold(body: Text('Privacy')),
      ),
      GoRoute(
        path: '/settings/disclosure',
        builder: (ctx, _) => const Scaffold(body: Text('Disclosure')),
      ),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (ctx, _) => const Scaffold(body: Text('Onboarding')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationApiProvider.overrideWithValue(mockNotifApi),
        permissionStatusApiProvider.overrideWithValue(mockPermApi),
        onboardingCompleteProvider.overrideWith(OnboardingCompleteNotifier.new),
        themeModeProvider.overrideWith(ThemeModeNotifier.new),
        reminderTimeProvider.overrideWith(ReminderTimeNotifier.new),
        streakThresholdProvider.overrideWith(StreakThresholdNotifier.new),
        postNotificationsGrantedProvider.overrideWith(
          PostNotificationsGrantedNotifier.new,
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return mockNotifApi;
}

/// Taps the Reset tile to open the AlertDialog.
Future<void> _openResetDialog(WidgetTester tester) async {
  // The Reset tile has the text 'Reset all data'.
  final resetTile = find.widgetWithText(ListTile, 'Reset all data');
  await tester.tap(resetTile);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Phase 6 / Reset AlertDialog (SETT-02, D-13)', () {
    // Test 1: AlertDialog body text equals verbatim D-13 copy.
    testWidgets(
      'AlertDialog body text equals verbatim D-13 copy',
      (tester) async {
        // Force a tall enough viewport so the Reset tile is visible.
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpSettingsScreen(tester);
        await _openResetDialog(tester);

        expect(find.text(_verbatimD13Body), findsOneWidget);
      },
    );

    // Test 2: AlertDialog title equals "Reset all data".
    testWidgets(
      'AlertDialog title equals "Reset all data"',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpSettingsScreen(tester);
        await _openResetDialog(tester);

        // The title should be in the AlertDialog.
        expect(find.text('Reset all data'), findsWidgets);
      },
    );

    // Test 3: Cancel button is first (TextButton), Reset button is second
    // (FilledButton with cs.error styling).
    testWidgets(
      'Cancel button is first in actions; Reset is FilledButton with error style',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpSettingsScreen(tester);
        await _openResetDialog(tester);

        // Cancel must be a TextButton and Reset must be a FilledButton.
        expect(
          find.widgetWithText(TextButton, 'Cancel'),
          findsOneWidget,
          reason: 'Cancel should be a TextButton',
        );
        expect(
          find.widgetWithText(FilledButton, 'Reset'),
          findsOneWidget,
          reason: 'Reset should be a FilledButton',
        );

        // Verify positional order: Cancel appears to the left of Reset
        // (i.e. Cancel is listed first in the actions list per D-13).
        final cancelOffset =
            tester.getCenter(find.widgetWithText(TextButton, 'Cancel'));
        final resetOffset =
            tester.getCenter(find.widgetWithText(FilledButton, 'Reset'));
        expect(
          cancelOffset.dx,
          lessThan(resetOffset.dx),
          reason: 'Cancel should appear to the left of (before) Reset',
        );
      },
    );

    // Test 4: Calm-tone source-grep — body literal has no ! or ?.
    test('Calm-tone: dialog body string has zero ! or ? characters', () {
      expect(_verbatimD13Body.contains('!'), isFalse);
      expect(_verbatimD13Body.contains('?'), isFalse);
    });

    // Test 5: Tap Cancel → dialog closes, no ResetController invocation.
    testWidgets(
      'Tap Cancel → dialog closes, no resetAll called',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockNotifApi = await _pumpSettingsScreen(tester);
        await _openResetDialog(tester);

        // Tap Cancel.
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be gone.
        expect(find.text(_verbatimD13Body), findsNothing);
        // cancelDailyReminder must NOT have been called.
        verifyNever(() => mockNotifApi.cancelDailyReminder());
      },
    );

    // Test 6: Tap Reset → dialog closes, then ResetController.resetAll runs.
    testWidgets(
      'Tap Reset → dialog closes, then resetAll runs (cancelDailyReminder called)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockNotifApi = await _pumpSettingsScreen(tester);
        await _openResetDialog(tester);

        // Tap Reset.
        await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
        await tester.pumpAndSettle();

        // Dialog should be gone.
        expect(find.text(_verbatimD13Body), findsNothing);
        // cancelDailyReminder MUST have been called (proof resetAll ran).
        verify(() => mockNotifApi.cancelDailyReminder()).called(1);
      },
    );
  });

  // Additional source-grep test for the source file itself (Test 4 extended).
  group('Reset dialog — source-grep invariants', () {
    test('settings_screen.dart body literal has no ! or ?', () {
      final source = File(
        'lib/features/settings/pages/settings_screen.dart',
      ).readAsStringSync();

      // Find the verbatim body line and assert no ! or ? in it.
      final bodyLine = source
          .split('\n')
          .firstWhere(
            (line) => line.contains('This deletes every entry'),
            orElse: () => '',
          );

      expect(bodyLine, isNotEmpty, reason: 'Verbatim D-13 body must exist');
      expect(bodyLine.contains('!'), isFalse, reason: 'No ! in body copy');
      expect(bodyLine.contains('?'), isFalse, reason: 'No ? in body copy');
    });
  });
}
