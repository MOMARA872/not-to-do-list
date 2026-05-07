import 'package:flutter/material.dart';

/// Surface 8 — UI-SPEC LIST-08. Apps-only segmented control between
/// `'soft'` (cooldown + "Use anyway") and `'hard'` (cooldown only). The
/// caller is responsible for hiding this widget for habit entries.
class BlockModeSegmented extends StatelessWidget {
  const BlockModeSegmented({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// `'soft'` or `'hard'`. Default for new entries is `'soft'`.
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Block mode', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'soft', label: Text('Soft')),
            ButtonSegment<String>(value: 'hard', label: Text('Hard')),
          ],
          selected: <String>{value},
          onSelectionChanged: (sel) => onChanged(sel.first),
        ),
        const SizedBox(height: 4),
        Text(
          'Soft: cooldown + "Use anyway". Hard: cooldown only, no override.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
