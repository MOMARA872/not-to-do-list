import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:not_to_do_list/features/reminder/providers/reminder_providers.dart';
import 'package:not_to_do_list/features/streak/providers/streak_threshold_provider.dart';

/// Minimal /settings/reminder screen — ships the two pickers (Plan 05-08).
/// Phase 6 reorganizes this into a proper Settings screen.
///
/// Surface:
///   - ListTile #1 "Daily reminder" — showTimePicker → reminderTimeProvider.
///   - ListTile #2 "Streak threshold" (D-08) — numeric dialog →
///     streakThresholdProvider.
class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(reminderTimeProvider);
    final thresholdAsync = ref.watch(streakThresholdProvider);

    final hm = reminderAsync.maybeWhen(data: (v) => v, orElse: () => 1260);
    final thresholdValue =
        thresholdAsync.maybeWhen(data: (v) => v, orElse: () => 5);

    // Format reminder time via DateFormat.jm() — locale-aware 12/24h.
    final reminderDisplay = DateFormat.jm().format(
      DateTime(2000, 1, 1, hm ~/ 60, hm % 60),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily reminder'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // ListTile #1 — Daily reminder time picker (NOTF-01).
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Daily reminder'),
            subtitle: Text(reminderDisplay),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTime(context, ref, hm),
          ),
          // ListTile #2 — Streak threshold picker (D-08).
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Streak threshold'),
            subtitle: Text('Streak breaks after $thresholdValue min/day'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThresholdPicker(context, ref, thresholdValue),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref, int hm) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hm ~/ 60, minute: hm % 60),
    );
    if (picked == null) return;
    await ref
        .read(reminderTimeProvider.notifier)
        .set(picked.hour * 60 + picked.minute);
  }

  Future<void> _showThresholdPicker(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _ThresholdDialog(initial: current),
    );
    if (picked == null) return;
    // clampStreakThreshold is also enforced inside the notifier.set() call.
    await ref.read(streakThresholdProvider.notifier).set(picked);
  }
}

/// Dialog for selecting an integer threshold in [1, 60] (D-08).
/// Uses a Slider with 59 discrete steps — no third-party picker dependency.
class _ThresholdDialog extends StatefulWidget {
  const _ThresholdDialog({required this.initial});

  final int initial;

  @override
  State<_ThresholdDialog> createState() => _ThresholdDialogState();
}

class _ThresholdDialogState extends State<_ThresholdDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Streak threshold'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_value min/day'),
          Slider(
            value: _value.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '$_value',
            onChanged: (v) => setState(() => _value = v.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
