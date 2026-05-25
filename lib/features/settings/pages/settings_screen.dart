import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:not_to_do_list/features/reminder/providers/reminder_providers.dart';
import 'package:not_to_do_list/features/settings/widgets/about_tile.dart';
import 'package:not_to_do_list/features/settings/widgets/section_header.dart';
import 'package:not_to_do_list/features/settings/widgets/streak_threshold_tile.dart';
import 'package:not_to_do_list/features/settings/widgets/theme_tile.dart';

/// Settings hub — Phase 6 SETT-04/SETT-05/PLAY-08.
/// Sectioned ListView with 6 headers + 8 tiles in D-04 order + Claude's
/// Discretion option a.i (Streak section above Appearance, closing Phase 5
/// D-08 promise).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final reminderAsync = ref.watch(reminderTimeProvider);
    final hm = reminderAsync.maybeWhen(data: (v) => v, orElse: () => 1260);
    final reminderDisplay = DateFormat.jm().format(
      DateTime(2000, 1, 1, hm ~/ 60, hm % 60),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Reminder ──────────────────────────────────────────────────────
          const SectionHeader(label: 'Reminder'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Daily reminder'),
            subtitle: Text(reminderDisplay),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/reminder'),
          ),
          // ── Streak (Claude's Discretion a.i — closes Phase 5 D-08) ───────
          const SectionHeader(label: 'Streak'),
          const StreakThresholdTile(),
          // ── Appearance ────────────────────────────────────────────────────
          const SectionHeader(label: 'Appearance'),
          const ThemeTile(),
          // ── Data ──────────────────────────────────────────────────────────
          const SectionHeader(label: 'Data'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export data'),
            subtitle: const Text('Saves a ZIP file to your chosen location'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/export'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: cs.error),
            title: Text('Reset all data', style: TextStyle(color: cs.error)),
            subtitle: const Text('Permanently delete all entries and history'),
            onTap: () async => _showResetDialog(context, ref),
          ),
          // ── Privacy ───────────────────────────────────────────────────────
          const SectionHeader(label: 'Privacy'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_outlined),
            title: const Text('Accessibility disclosure'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/disclosure'),
          ),
          // ── About ─────────────────────────────────────────────────────────
          const SectionHeader(label: 'About'),
          const AboutTile(),
        ],
      ),
    );
  }

  Future<void> _showResetDialog(BuildContext context, WidgetRef ref) async {
    // TODO(06-05): wire ResetController + verbatim body copy per D-13
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data'),
        content: const Text('TODO(06-05): body copy literal'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
