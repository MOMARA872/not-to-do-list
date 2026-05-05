import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

/// Singleton [AppDatabase] for the app lifetime.
///
/// Phase 1 uses a plain Riverpod [Provider] (not `@riverpod` codegen) because
/// `riverpod_generator` was dropped in Plan 01-01 due to an analyzer-version
/// conflict with `pigeon 26.3.4` + Flutter 3.41 (see 01-01-SUMMARY.md). The DB
/// is closed when the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
