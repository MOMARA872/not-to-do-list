import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/core/router/app_router.dart';
import 'package:not_to_do_list/core/theme/app_theme.dart';
import 'package:not_to_do_list/features/health/widgets/_health_lifecycle_observer.dart';
import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';

class NotToDoApp extends ConsumerWidget {
  const NotToDoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider).maybeWhen(
          data: (m) => m,
          orElse: () => ThemeMode.system,
        );
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return HealthLifecycleObserver(
          child: MaterialApp.router(
            title: 'Not To-Do List',
            theme: AppTheme.light(dynamic: lightDynamic),
            darkTheme: AppTheme.dark(dynamic: darkDynamic),
            themeMode: themeMode,
            routerConfig: router,
          ),
        );
      },
    );
  }
}
