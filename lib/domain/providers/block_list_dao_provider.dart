import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';

/// Hand-written [Provider] for [BlockListDao] — Phase 2 follows the Phase 1
/// hand-written pattern per Plan 01-01's analyzer-conflict deviation.
/// See `lib/domain/providers/database_provider.dart`.
final Provider<BlockListDao> blockListDaoProvider = Provider<BlockListDao>(
  (ref) => BlockListDao(ref.watch(databaseProvider)),
);
