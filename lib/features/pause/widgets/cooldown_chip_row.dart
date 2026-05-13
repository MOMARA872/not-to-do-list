import 'package:flutter/material.dart';

/// M3 SegmentedButton chip row for selecting a cooldown duration (D-04).
///
/// Clones the Phase-2 BlockModeSegmented shape (lib/features/list/widgets/
/// block_mode_segmented.dart) with int values (seconds) instead of strings.
///
/// NO default pre-selection — selectedSeconds is null initially.
/// Tapping a chip calls onChanged(seconds); tapping a different chip while
/// running calls onChanged again (replace, not add — D-04).
class CooldownChipRow extends StatelessWidget {
  const CooldownChipRow({
    required this.selectedSeconds,
    required this.onChanged,
    super.key,
  });

  /// The currently selected cooldown in seconds, or null if no chip selected.
  final int? selectedSeconds;

  /// Called when the user taps a chip. Argument is the chip's value in seconds.
  final ValueChanged<int> onChanged;

  static const List<ButtonSegment<int>> _segments = [
    ButtonSegment<int>(value: 60, label: Text('1m')),
    ButtonSegment<int>(value: 180, label: Text('3m')),
    ButtonSegment<int>(value: 300, label: Text('5m')),
    ButtonSegment<int>(value: 600, label: Text('10m')),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Cooldown:', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: _segments,
          // Empty set = no default pre-selection (D-04).
          selected:
              selectedSeconds != null ? <int>{selectedSeconds!} : <int>{},
          onSelectionChanged: (sel) {
            if (sel.isNotEmpty) onChanged(sel.first);
          },
          emptySelectionAllowed: true,
        ),
      ],
    );
  }
}
