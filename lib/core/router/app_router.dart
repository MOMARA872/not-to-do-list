import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/home/pages/empty_home_screen.dart';

/// GoRouter provider — hand-written (no `@riverpod` codegen) because Plan 01-01
/// dropped `riverpod_annotation`/`riverpod_generator` due to analyzer-pin
/// incompatibility with `pigeon 26.3.4` + Flutter 3.41 (`meta 1.17`).
/// See `.planning/phases/01-foundation-play-declaration/01-01-SUMMARY.md`.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const EmptyHomeScreen(),
      ),
    ],
  ),
);
