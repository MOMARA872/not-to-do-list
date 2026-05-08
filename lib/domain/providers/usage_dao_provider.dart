import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/database/daos/daily_usage_summary_dao.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';

/// Hand-written [Provider] for [DailyUsageSummaryDao] — Phase 3 follows the
/// Phase 1 hand-written pattern per Plan 01-01's analyzer-conflict deviation.
/// See `lib/domain/providers/database_provider.dart`.
final Provider<DailyUsageSummaryDao> usageDaoProvider =
    Provider<DailyUsageSummaryDao>(
  (ref) => DailyUsageSummaryDao(ref.watch(databaseProvider)),
);
