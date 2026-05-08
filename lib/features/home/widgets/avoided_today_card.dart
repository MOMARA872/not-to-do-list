import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/dashboard/providers/avoided_today_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';

/// Home-screen card showing today's avoidance progress (DASH-05 / D-09).
/// Tap routes by priority:
/// - usageAccess=false -> /onboarding/permissions/usage-access
/// - total=0           -> /list/add-app
/// - otherwise         -> /dashboard
///
/// Material 3 Card.outlined per D-17 (low visual weight; does not compete
/// with the entries list below it).
class AvoidedTodayCard extends ConsumerWidget {
  const AvoidedTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(avoidedTodayProvider);
    final healthAsync = ref.watch(permissionHealthProvider);
    final tt = Theme.of(context).textTheme;

    final usageAccess =
        healthAsync.maybeWhen(data: (h) => h.usageAccess, orElse: () => true);

    String subtitle;
    VoidCallback onTap;

    if (!usageAccess) {
      subtitle = 'Tracking is offline — tap to fix';
      onTap = () => context.go('/onboarding/permissions/usage-access');
    } else {
      final total = summaryAsync.maybeWhen(data: (s) => s.total, orElse: () => 0);
      final succeeded = summaryAsync.maybeWhen(data: (s) => s.succeeded, orElse: () => 0);
      if (total == 0) {
        subtitle = 'No entries yet';
        onTap = () => context.go('/list/add-app');
      } else {
        subtitle = '$succeeded of $total entries succeeded today';
        onTap = () => context.go('/dashboard');
      }
    }

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Avoided today', style: tt.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
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
