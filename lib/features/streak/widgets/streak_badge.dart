import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';

/// Compact trailing badge for `BlockListRow`.
///
/// Consumes `streakBadgeProvider`'s 3-field record
/// `({int current, int longest, bool breakDetectedToday})` — read-only.
/// Plan 05-03 owns the provider; this plan does NOT modify it.
///
/// Format: "🔥 {current} · best {longest}" (UI-SPEC §Copywriting Contract).
/// Day-0: "🔥 0 · best 0" (D-15 — no CTA, no hidden badge).
/// Break-detection day (D-05): renders the prior count with
/// [TextDecoration.lineThrough] via [Text.rich].
class StreakBadge extends ConsumerWidget {
  const StreakBadge({required this.entryId, super.key});

  final int entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final badgeAsync = ref.watch(streakBadgeProvider(entryId));

    return badgeAsync.when(
      loading: () => Text(
        '—',
        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      error: (_, __) => Text(
        '—',
        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      data: (d) {
        final baseStyle = tt.labelSmall?.copyWith(
          color: d.current > 0 ? cs.onSurface : cs.onSurfaceVariant,
        );

        // D-05: strikethrough on break-detection day.
        if (d.breakDetectedToday) {
          // Render "🔥 {current}" with strikethrough,
          // then " · best {longest}" plain.
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '🔥 ${d.current}',
                  style: baseStyle?.copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                TextSpan(
                  text: ' · best ${d.longest}',
                  style: baseStyle,
                ),
              ],
            ),
          );
        }

        // Standard format: "🔥 {current} · best {longest}"
        return Text(
          '🔥 ${d.current} · best ${d.longest}',
          style: baseStyle,
        );
      },
    );
  }
}
