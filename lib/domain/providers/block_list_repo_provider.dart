import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_dao_provider.dart';

/// Hand-written [Provider] for [BlockListRepository] — the single seam UI +
/// onboarding code consumes for not-to-do list CRUD.
final Provider<BlockListRepository> blockListRepoProvider =
    Provider<BlockListRepository>(
  (ref) => BlockListRepository(ref.watch(blockListDaoProvider)),
);
