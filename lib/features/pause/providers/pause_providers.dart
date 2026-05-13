import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, NotifierProviderFamily;
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/repositories/pause_event_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/features/pause/controllers/pause_controller.dart';
import 'package:not_to_do_list/features/pause/models/pause_session.dart';

/// Hand-written providers for the pause feature (no @riverpod codegen — see
/// 01-01-SUMMARY.md for the analyzer-pin incompatibility).

/// Provider for the D-13 single-writer seam.
final Provider<PauseEventRepository> pauseEventRepositoryProvider =
    Provider<PauseEventRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PauseEventRepository(db.pauseEventDao);
});

/// Family provider for PauseController — one controller per session,
/// keyed by PauseSessionArgs. Auto-disposes on unmount (PauseActivity finish).
final NotifierProviderFamily<PauseController, PauseSession, PauseSessionArgs>
    pauseControllerProvider = NotifierProvider.autoDispose.family<
        PauseController, PauseSession, PauseSessionArgs>(
  PauseController.new,
);

/// Family provider for a BlockList row lookup by entryId.
///
/// PauseScreen uses this to read reasonNote + displayName without a Pigeon
/// round-trip (displayName is stored at insert time — D-03/Option b).
final FutureProviderFamily<BlockListData?, int> blockListEntryProvider =
    FutureProvider.autoDispose.family<BlockListData?, int>((ref, id) {
  final repo = ref.read(blockListRepoProvider);
  return repo.getById(id);
});
