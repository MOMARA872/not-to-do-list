import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/features/home/widgets/block_list_row.dart';
import 'package:not_to_do_list/features/home/widgets/empty_home_state.dart';

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
/// Pure consumer of [blockListRepoProvider]'s reactive `watchAll()` stream;
/// no business logic. Plan 02-09 will mount the HealthCheckBanner above
/// this screen via the router shell, not inside this widget.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final entriesAsync = ref.watch(_homeEntriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not To-Do List'),
        centerTitle: false,
      ),
      body: entriesAsync.when(
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
