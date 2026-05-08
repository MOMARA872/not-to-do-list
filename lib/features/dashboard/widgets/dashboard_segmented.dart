import 'package:flutter/material.dart';
import 'package:not_to_do_list/domain/dashboard/dashboard_range.dart';

/// Material 3 SegmentedButton<DashboardRange> at the top of /dashboard
/// (CONTEXT.md D-05). Mirrors BlockModeSegmented exactly except the type
/// parameter widens from String to DashboardRange and there are 3 segments.
class DashboardSegmented extends StatelessWidget {
  const DashboardSegmented({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final DashboardRange value;
  final ValueChanged<DashboardRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<DashboardRange>(
        segments: const <ButtonSegment<DashboardRange>>[
          ButtonSegment<DashboardRange>(
            value: DashboardRange.day,
            label: Text('Day'),
          ),
          ButtonSegment<DashboardRange>(
            value: DashboardRange.week,
            label: Text('Week'),
          ),
          ButtonSegment<DashboardRange>(
            value: DashboardRange.month,
            label: Text('Month'),
          ),
        ],
        selected: <DashboardRange>{value},
        onSelectionChanged: (sel) => onChanged(sel.first),
      ),
    );
  }
}
