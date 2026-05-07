import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/core/router/app_router.dart';
import 'package:not_to_do_list/core/theme/app_theme.dart';

class NotToDoApp extends ConsumerWidget {
  const NotToDoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Not To-Do List',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
