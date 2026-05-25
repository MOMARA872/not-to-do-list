import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/streak/providers/streak_threshold_provider.dart';

/// Settings tile for Streak threshold — closes Phase 5 D-08 promise
/// (Claude's Discretion option a.i). Reads and writes
/// [streakThresholdProvider]. Tapping opens an AlertDialog with a Slider
/// matching the Phase 5 _ThresholdDialog UI.
class StreakThresholdTile extends ConsumerWidget {
  const StreakThresholdTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thresholdValue = ref.watch(streakThresholdProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 5,
        );

    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: const Text('Streak threshold'),
      subtitle: Text('Streak breaks after $thresholdValue min/day'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showPicker(context, ref, thresholdValue),
    );
  }

  Future<void> _showPicker(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _StreakThresholdDialog(initial: current),
    );
    if (picked == null) return;
    if (!context.mounted) return;
    await ref.read(streakThresholdProvider.notifier).set(picked);
  }
}

/// Dialog for selecting a streak threshold in [1, 60] minutes per day.
/// Mirrors the _ThresholdDialog body from reminder_settings_screen.dart.
class _StreakThresholdDialog extends StatefulWidget {
  const _StreakThresholdDialog({required this.initial});

  final int initial;

  @override
  State<_StreakThresholdDialog> createState() => _StreakThresholdDialogState();
}

class _StreakThresholdDialogState extends State<_StreakThresholdDialog> {
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
