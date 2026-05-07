// Phase 3 shared fixture: seeds a deterministic 30-day x 20-app slab into the
// daily_usage_summary table plus 5 canonical not-to-do block_list rows.
// Mirrors test/_fixtures/permission_status_mock.dart's convenience-builder
// shape. Used by:
// - test/perf/dashboard_render_test.dart (D-20 first-frame budget)
// - test/data/repositories/usage_repository_test.dart (Wave 2)
// - test/features/dashboard/dashboard_screen_test.dart (Wave 3)
import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

/// The 5 not-to-do offenders the seed pre-populates as block_list rows so
/// dashboardRowsProvider's not-to-do-vs-other join has highlighted rows.
const List<({String packageName, String displayName})> kSeedNotToDoApps =
    <({String packageName, String displayName})>[
  (packageName: 'com.instagram.android', displayName: 'Instagram'),
  (packageName: 'com.zhiliaoapp.musically', displayName: 'TikTok'),
  (packageName: 'com.twitter.android', displayName: 'X'),
  (packageName: 'com.google.android.youtube', displayName: 'YouTube'),
  (packageName: 'com.reddit.frontpage', displayName: 'Reddit'),
];

/// Seed [db] with [days] x [packages] daily_usage_summary rows for perf tests
/// (D-20) + edge-case asserts. Default = 30 x 20 = 600 rows.
///
/// foregroundSeconds is deterministic ((d*13 + p*17) % 7200) so the perf test
/// is reproducible. The first 5 packages match the kSeedNotToDoApps list and
/// are also inserted as block_list rows (kind=0) so the dashboard's
/// not-to-do highlight has rows to join with.
Future<void> seedUsageSummary(
  AppDatabase db, {
  int days = 30,
  int packages = 20,
  DateTime? endDay,
}) async {
  assert(packages >= 5, 'seedUsageSummary requires at least 5 packages so '
      'the canonical not-to-do offenders fit at indices 0..4.');
  final end = endDay ?? DateTime.now();
  final today = DateTime(end.year, end.month, end.day);

  // Insert the 5 not-to-do block_list rows so the join sees them.
  for (var i = 0; i < kSeedNotToDoApps.length; i++) {
    final entry = kSeedNotToDoApps[i];
    await db.into(db.blockList).insert(
          BlockListCompanion.insert(
            kind: 0,
            packageName: Value(entry.packageName),
            displayName: entry.displayName,
            createdAt: today,
            updatedAt: today,
          ),
        );
  }

  // Generate 20 packageNames: 5 canonical + 15 fillers.
  final packageNames = <String>[
    for (final e in kSeedNotToDoApps) e.packageName,
    for (var i = 0; i < packages - kSeedNotToDoApps.length; i++)
      'com.test.filler$i',
  ];

  // Insert 30 x 20 = 600 daily_usage_summary rows. Deterministic seconds.
  for (var d = 0; d < days; d++) {
    final day = today.subtract(Duration(days: d));
    for (var p = 0; p < packages; p++) {
      final packageName = packageNames[p];
      final foregroundSeconds = (d * 13 + p * 17) % 7200;
      await db.into(db.dailyUsageSummary).insert(
            DailyUsageSummaryCompanion.insert(
              packageName: packageName,
              day: day,
              foregroundSeconds: foregroundSeconds,
              aggregatedAt: day.add(const Duration(hours: 23)),
            ),
          );
    }
  }
}
