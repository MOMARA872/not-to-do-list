import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/dashboard/dashboard_range.dart';
import 'package:not_to_do_list/features/dashboard/providers/dashboard_rows_provider.dart';

/// Card.outlined ribbon at the top of the dashboard list showing the
/// "{Day|Week|Month} total: {H}h {M}m across {N} apps" line (D-16).
/// Tap toggles to "Not-to-do total" — same data, filtered to isNotToDo=true.
///
/// Consumes dashboardRowsProvider (StreamProvider.autoDispose.family<
/// List<DashRow>, DashboardRange>) — `ref.watch` returns AsyncValue<List<
/// DashRow>>; `.maybeWhen(data: ..., orElse: ...)` selects the rendered shape.
class PeriodTotalRibbon extends ConsumerStatefulWidget {
  const PeriodTotalRibbon({required this.range, super.key});
  final DashboardRange range;

  @override
  ConsumerState<PeriodTotalRibbon> createState() => _PeriodTotalRibbonState();
}

class _PeriodTotalRibbonState extends ConsumerState<PeriodTotalRibbon> {
  bool _filtered = false;

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(dashboardRowsProvider(widget.range));
    return rowsAsync.maybeWhen(
      data: (rows) {
        final relevant = _filtered
            ? rows.where((r) => r.isNotToDo).toList()
            : rows;
        final totalSeconds =
            relevant.fold<int>(0, (a, r) => a + r.foregroundSeconds);
        final label = _filtered
            ? 'Not-to-do total'
            : '${_rangeLabel(widget.range)} total';
        return Card.outlined(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => setState(() => _filtered = !_filtered),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '$label: ${_formatDuration(totalSeconds)} '
                'across ${relevant.length} apps',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

String _rangeLabel(DashboardRange r) {
  switch (r) {
    case DashboardRange.day:
      return 'Day';
    case DashboardRange.week:
      return 'Week';
    case DashboardRange.month:
      return 'Month';
  }
}

String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h == 0) return '${m}m';
  return '${h}h ${m}m';
}
