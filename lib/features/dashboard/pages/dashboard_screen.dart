import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/usage_repo_provider.dart';
import 'package:not_to_do_list/features/dashboard/providers/dashboard_range_provider.dart';
import 'package:not_to_do_list/features/dashboard/providers/dashboard_rows_provider.dart';
import 'package:not_to_do_list/features/dashboard/widgets/dashboard_row.dart';
import 'package:not_to_do_list/features/dashboard/widgets/dashboard_segmented.dart';
import 'package:not_to_do_list/features/dashboard/widgets/period_total_ribbon.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:not_to_do_list/features/health/widgets/health_check_banner.dart';

/// Screen at /dashboard (CONTEXT.md D-18). Renders D/W/M screen-time list
/// with not-to-do entries highlighted (DASH-02), reads from the
/// pre-aggregated daily_usage_summary table via dashboardRowsProvider, and
/// triggers lazy refresh on mount + on AppLifecycleState.resumed (D-12 +
/// D-14). Pull-to-refresh bypasses the 5-min cache (D-12).
///
/// dashboardRowsProvider is a StreamProvider.autoDispose.family<List<DashRow>,
/// DashboardRange> per D-19 literal — `ref.watch` returns
/// AsyncValue<List<DashRow>>, which we render via `.when()`.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lazy refresh on mount (D-14). refreshIfStale is idempotent.
    unawaited(
      Future.microtask(
        () => ref.read(usageRepositoryProvider).refreshIfStale(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(usageRepositoryProvider).refreshIfStale());
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(dashboardRangeProvider);
    final rowsAsync = ref.watch(dashboardRowsProvider(range));
    final healthAsync = ref.watch(permissionHealthProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Sticky no-permission banner (D-13 / Pitfall #8). Renders when
          // usageAccess is denied — user taps to fix.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: healthAsync.maybeWhen(
              data: (h) => h.usageAccess
                  ? const SizedBox.shrink()
                  : HealthCheckBanner(health: h),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          DashboardSegmented(
            value: range,
            onChanged: (next) =>
                ref.read(dashboardRangeProvider.notifier).state = next,
          ),
          PeriodTotalRibbon(range: range),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(usageRepositoryProvider)
                  .refreshIfStale(forceBypassCache: true),
              child: rowsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (rows) {
                  if (rows.isEmpty) {
                    return ListView(
                      // ListView (not Center) so RefreshIndicator can scroll.
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'No usage tracked yet — open an app and come back.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  // Bar-fill scale: max foregroundSeconds across all rows.
                  final maxSeconds = rows
                      .map((r) => r.foregroundSeconds)
                      .fold<int>(0, (a, b) => a > b ? a : b);
                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (ctx, i) => DashboardRow(
                      row: rows[i],
                      maxSeconds: maxSeconds,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
