import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';
import 'package:not_to_do_list/features/streak/widgets/day_dot.dart';

/// 30-day streak history grid + summary text for the entry detail screen.
///
/// Consumes [streakHistoryProvider] (Stream of last 30 DailyStreakData, asc)
/// and [streakBadgeProvider] for the current + longest counts.
///
/// Layout per UI-SPEC §Screen 3:
///   Divider
///   SizedBox(16)
///   Text "Streak history" (titleMedium)
///   SizedBox(12)
///   GridView — 7-col, NeverScrollableScrollPhysics, shrinkWrap
///   SizedBox(12)
///   Text "{N} days · best {M}" (bodyMedium, onSurfaceVariant)
///   SizedBox(4)
///   Text "Streak breaks if you use this app over 5 min/day (change in Settings)"
///       (labelSmall, onSurfaceVariant)
///   SizedBox(16)
class StreakHistorySection extends ConsumerWidget {
  const StreakHistorySection({required this.entryId, super.key});

  final int entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final historyAsync = ref.watch(streakHistoryProvider(entryId));
    final badgeAsync = ref.watch(streakBadgeProvider(entryId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Streak history',
          style: tt.titleMedium,
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('$e'),
          data: (rows) {
            // Pad to exactly 30 cells with sentinel status=-1 for empty cells.
            // The rows are in ascending order (oldest first).
            final dots = List.generate(30, (i) {
              if (i < rows.length) {
                final r = rows[i];
                return DayDot(
                  day: r.day,
                  status: r.status,
                  source: r.source,
                );
              }
              // Empty cell (before entry creation).
              return const SizedBox(width: 24, height: 24);
            });

            return GridView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              children: dots,
            );
          },
        ),
        const SizedBox(height: 12),
        badgeAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (d) => Text(
            '${d.current} days · best ${d.longest}',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Streak breaks if you use this app over 5 min/day (change in Settings)',
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
