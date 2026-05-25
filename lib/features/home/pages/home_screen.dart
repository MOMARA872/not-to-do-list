import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/core/router/pending_nav_request_provider.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:not_to_do_list/features/health/widgets/health_check_banner.dart';
import 'package:not_to_do_list/features/home/widgets/avoided_today_card.dart';
import 'package:not_to_do_list/features/home/widgets/block_list_row.dart';
import 'package:not_to_do_list/features/home/widgets/cumulative_totals_card.dart';
import 'package:not_to_do_list/features/home/widgets/empty_home_state.dart';
import 'package:not_to_do_list/features/onboarding/providers/post_notifications_provider.dart';
import 'package:not_to_do_list/features/reminder/widgets/reminder_off_banner.dart';

/// Private stream provider over [blockListRepoProvider]'s `watchAll()`.
/// `autoDispose` cancels the Drift subscription when the home tree leaves
/// the widget tree (also keeps widget tests' timers from leaking).
final StreamProvider<List<BlockListData>> _homeEntriesProvider =
    StreamProvider.autoDispose<List<BlockListData>>((ref) {
  final repo = ref.watch(blockListRepoProvider);
  return repo.watchAll();
});

/// Surface 4 — unified Apps + Habits home list.
///
/// Mounts [HealthCheckBanner] above the list in an [AnimatedSwitcher];
/// the banner is visible iff [PermissionHealth.allHealthy] is false. The
/// list itself is a pure consumer of [blockListRepoProvider]'s reactive
/// `watchAll()` stream — no business logic.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final entriesAsync = ref.watch(_homeEntriesProvider);
    final healthAsync = ref.watch(permissionHealthProvider);

    // NOTF-06: listen for the earned-prompt nav signal set by
    // BlockListRepository after the first entry insert.
    ref.listen<String?>(pendingNavRequestProvider, (prev, next) {
      if (next != null) {
        ref.read(pendingNavRequestProvider.notifier).state = null;
        context.go(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Not To-Do List'),
        centerTitle: false,
        actions: [
          // Phase 6 D-01: Settings gear is FIRST action (UI-SPEC §HomeScreen).
          Semantics(
            label: 'Settings',
            child: IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () => context.go('/settings'),
            ),
          ),
          Semantics(
            label: 'Daily reminder settings',
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Daily reminder',
              onPressed: () => context.go('/settings/reminder'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner 1 (tracking-offline) — higher priority per D-12.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: healthAsync.maybeWhen(
              data: (h) => h.allHealthy
                  ? const SizedBox.shrink()
                  : HealthCheckBanner(health: h),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          // Banner 2 (reminder-off, NOTF-07) — below tracking-offline per D-12.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: ref.watch(postNotificationsGrantedProvider).maybeWhen(
                  data: (granted) => granted
                      ? const SizedBox.shrink()
                      : const ReminderOffBanner(),
                  orElse: () => const SizedBox.shrink(),
                ),
          ),
          // Phase 3 D-17 — two home cards above the unified list. NOT
          // wrapped in AnimatedSwitcher: they belong to the home identity,
          // not transient state.
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AvoidedTodayCard(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CumulativeTotalsCard(),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text('$e')),
              data: (entries) {
                if (entries.isEmpty) return const EmptyHomeState();
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) => BlockListRow(entry: entries[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_habit',
            onPressed: () => context.go('/list/add-habit'),
            label: const Text('+ Add habit'),
            backgroundColor: cs.surface,
            foregroundColor: cs.primary,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_app',
            onPressed: () => context.go('/list/add-app'),
            label: const Text('+ Add app'),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
