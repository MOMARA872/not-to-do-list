import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';

/// Settings tile for theme selection (Phase 6 SETT-04, D-05).
/// Renders an inline M3 SegmentedButton with 3 segments:
/// Light / Dark / System. Label-only segments (no icons) per UI-SPEC calm
/// tone. Reads and writes [themeModeProvider] directly.
class ThemeTile extends ConsumerWidget {
  const ThemeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider).maybeWhen(
          data: (m) => m,
          orElse: () => ThemeMode.system,
        );

    return ListTile(
      title: const Text('Theme'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const <ButtonSegment<ThemeMode>>[
          ButtonSegment<ThemeMode>(
            value: ThemeMode.light,
            label: Text('Light'),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.dark,
            label: Text('Dark'),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.system,
            label: Text('System'),
          ),
        ],
        selected: <ThemeMode>{currentMode},
        onSelectionChanged: (sel) =>
            ref.read(themeModeProvider.notifier).set(sel.first),
      ),
    );
  }
}
