import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/repositories/usage_repository.dart';
import 'package:not_to_do_list/domain/providers/usage_api_provider.dart';
import 'package:not_to_do_list/domain/providers/usage_dao_provider.dart';

/// Hand-written [Provider] for [UsageRepository] — the single seam UI +
/// dashboard surfaces consume to read daily usage totals (DASH-02/03/04)
/// and trigger lazy refresh (D-14).
///
/// Note: file name follows Phase 2's `block_list_repo_provider.dart`
/// convention; the symbol name `usageRepositoryProvider` matches CONTEXT.md
/// D-19 canonical name.
final Provider<UsageRepository> usageRepositoryProvider =
    Provider<UsageRepository>(
  (ref) => UsageRepository(
    ref.watch(usageDaoProvider),
    ref.watch(usageApiProvider),
  ),
);
