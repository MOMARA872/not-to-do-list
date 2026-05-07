import 'package:flutter/material.dart';

/// Surface 9 — UI-SPEC LIST-09. Single optional active window with start +
/// end times (minutes since midnight, 0..1439) plus a 7-bit weekday mask
/// (bit 0 = Monday … bit 6 = Sunday).
///
/// Three-nullable-together contract: when the toggle is OFF, the widget
/// emits `(null, null, null)` and the entry is "always on". When the toggle
/// is ON, the widget always emits all three non-null.
class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({
    required this.startMinutes,
    required this.endMinutes,
    required this.weekdayMask,
    required this.onChanged,
    super.key,
  });

  final int? startMinutes;
  final int? endMinutes;
  final int? weekdayMask;

  /// Called with `(null, null, null)` when the toggle goes off, and with
  /// `(start, end, mask)` (all non-null) when any field changes while on.
  final void Function(int? start, int? end, int? mask) onChanged;

  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  static const int _defaultStart = 540; // 09:00
  static const int _defaultEnd = 1320; // 22:00
  static const int _defaultMask = 0x7F; // all 7 days

  bool get _hasSchedule =>
      widget.startMinutes != null &&
      widget.endMinutes != null &&
      widget.weekdayMask != null;

  void _toggle({required bool on}) {
    if (on) {
      widget.onChanged(_defaultStart, _defaultEnd, _defaultMask);
    } else {
      widget.onChanged(null, null, null);
    }
  }

  Future<void> _pickStart() async {
    final start = widget.startMinutes ?? _defaultStart;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60),
    );
    if (picked == null) return;
    widget.onChanged(
      picked.hour * 60 + picked.minute,
      widget.endMinutes ?? _defaultEnd,
      widget.weekdayMask ?? _defaultMask,
    );
  }

  Future<void> _pickEnd() async {
    final end = widget.endMinutes ?? _defaultEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: end ~/ 60, minute: end % 60),
    );
    if (picked == null) return;
    widget.onChanged(
      widget.startMinutes ?? _defaultStart,
      picked.hour * 60 + picked.minute,
      widget.weekdayMask ?? _defaultMask,
    );
  }

  void _toggleDay(int dayIndex) {
    final mask = widget.weekdayMask ?? _defaultMask;
    final bit = 1 << dayIndex;
    final newMask = (mask & bit) != 0 ? mask & ~bit : mask | bit;
    widget.onChanged(
      widget.startMinutes ?? _defaultStart,
      widget.endMinutes ?? _defaultEnd,
      newMask,
    );
  }

  String _formatMinutes(BuildContext context, int minutes) {
    final tod = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return tod.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSchedule = _hasSchedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Active window', style: theme.textTheme.titleMedium),
            Switch(
              value: hasSchedule,
              onChanged: (v) => _toggle(on: v),
            ),
          ],
        ),
        if (!hasSchedule)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Always on',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...<Widget>[
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStart,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    'From '
                    '${_formatMinutes(context, widget.startMinutes!)}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEnd,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    'To '
                    '${_formatMinutes(context, widget.endMinutes!)}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Days', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (int i = 0; i < 7; i++)
                FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: (widget.weekdayMask! & (1 << i)) != 0,
                  onSelected: (_) => _toggleDay(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.endMinutes! < widget.startMinutes!)
            Text(
              'Window crosses midnight — treated as one continuous block.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Streak day resets at 4:00 AM.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Single-letter weekday labels in Monday-first order (UI-SPEC §Surface 9).
/// The duplicate T (Tue/Thu) and S (Sat/Sun) are intentional — a 7-letter
/// row that fits on small screens.
const List<String> _dayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
