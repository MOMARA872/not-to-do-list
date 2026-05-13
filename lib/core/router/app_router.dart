import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/dashboard/pages/dashboard_screen.dart';
import 'package:not_to_do_list/features/home/pages/home_screen.dart';
import 'package:not_to_do_list/features/list/pages/add_app_picker_screen.dart';
import 'package:not_to_do_list/features/list/pages/add_habit_screen.dart';
import 'package:not_to_do_list/features/list/pages/edit_entry_screen.dart';
import 'package:not_to_do_list/features/onboarding/pages/accessibility_step.dart';
import 'package:not_to_do_list/features/onboarding/pages/battery_opt_step.dart';
import 'package:not_to_do_list/features/onboarding/pages/quick_add_screen.dart';
import 'package:not_to_do_list/features/onboarding/pages/usage_access_step.dart';
import 'package:not_to_do_list/features/onboarding/pages/welcome_screen.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_complete_provider.dart';
import 'package:not_to_do_list/features/pause/pages/pause_screen.dart';

/// GoRouter provider — hand-written (no `@riverpod` codegen) because Plan 01-01
/// dropped `riverpod_annotation`/`riverpod_generator` due to analyzer-pin
/// incompatibility with `pigeon 26.3.4` + Flutter 3.41 (`meta 1.17`).
/// See `.planning/phases/01-foundation-play-declaration/01-01-SUMMARY.md`.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      // T-2-10: onboarding-redirect-bypass mitigation. The redirect runs
      // on EVERY navigation, so even direct route URLs trigger the gate.
      final completed =
          ref.read(onboardingCompleteProvider).value ?? false;
      final goingToOnboarding =
          state.matchedLocation.startsWith('/onboarding');
      if (!completed && !goingToOnboarding) return '/onboarding/welcome';
      if (completed && goingToOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/onboarding/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/quick-add', builder: (_, __) => const QuickAddScreen()),
      GoRoute(path: '/onboarding/permissions/usage-access', builder: (_, __) => const UsageAccessStep()),
      GoRoute(path: '/onboarding/permissions/accessibility', builder: (_, __) => const AccessibilityStep()),
      GoRoute(path: '/onboarding/permissions/battery-opt', builder: (_, __) => const BatteryOptStep()),
      GoRoute(path: '/list/add-app', builder: (_, __) => const AddAppPickerScreen()),
      GoRoute(path: '/list/add-habit', builder: (_, __) => const AddHabitScreen()),
      GoRoute(path: '/list/edit/:id', builder: (ctx, state) => EditEntryScreen(id: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/pause/:entryId',
        builder: (ctx, state) => PauseScreen(
          entryId: int.parse(state.pathParameters['entryId']!),
          packageName: state.uri.queryParameters['package'] ?? '',
          blockMode: state.uri.queryParameters['mode'] ?? 'soft',
          triggeredAt: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(state.uri.queryParameters['triggeredAt'] ?? '') ?? 0,
          ),
        ),
      ),
    ],
  );
});
