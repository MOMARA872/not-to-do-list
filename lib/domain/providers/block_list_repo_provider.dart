import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/core/router/pending_nav_request_provider.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_dao_provider.dart';
import 'package:not_to_do_list/domain/providers/blocklist_broadcast_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';

/// Hand-written [Provider] for [BlockListRepository] — the single seam UI +
/// onboarding code consumes for not-to-do list CRUD.
final Provider<BlockListRepository> blockListRepoProvider =
    Provider<BlockListRepository>(
  (ref) => BlockListRepository(
    ref.watch(blockListDaoProvider),
    ref.read(blocklistBroadcastApiProvider),
    // NOTF-06 earned-prompt fire-once callback (Option A pattern).
    // Writes the pending nav route so HomeScreen's ref.listen fires context.go.
    (route) async {
      ref.read(pendingNavRequestProvider.notifier).state = route;
    },
    // Injected isPostNotificationsGranted — keeps repo decoupled from Pigeon.
    () => ref.read(permissionStatusApiProvider).isPostNotificationsGranted(),
  ),
);
