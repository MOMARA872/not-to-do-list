import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/dashboard/providers/cumulative_totals_provider.dart';

/// Home-screen card showing all-time cumulative avoidance (DASH-06 / D-11).
/// Aggregates pause_events (outcome IN (0, 1)). Phase 3 starts at 0/0
/// because pause_events is empty until Phase 4 ships PauseActivity.
class CumulativeTotalsCard extends ConsumerWidget {
  const CumulativeTotalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(cumulativeTotalsProvider);
    final tt = Theme.of(context).textTheme;
    final n = summaryAsync.maybeWhen(data: (s) => s.launchesBlocked, orElse: () => 0);
    final s = summaryAsync.maybeWhen(data: (t) => t.timeAvoidedSeconds, orElse: () => 0);
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final timeText = h == 0 ? '${m}m' : '${h}h ${m}m';

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go('/dashboard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total avoided', style: tt.titleMedium),
              const SizedBox(height: 4),
              Text(
                '$n launches blocked · $timeText saved',
                style: tt.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
