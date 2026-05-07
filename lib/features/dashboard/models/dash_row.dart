/// One row in the dashboard list (DASH-02). Computed by dashboardRowsProvider
/// by joining block_list (not-to-do entries) with daily_usage_summary (totals
/// over the active range). Pure data class — no Flutter, no Riverpod imports.
class DashRow {
  const DashRow({
    required this.isNotToDo,
    required this.packageName,
    required this.displayName,
    required this.foregroundSeconds,
  });

  /// True if this row corresponds to a block_list entry. Drives D-06
  /// (4dp accent + 100% icon opacity) and D-07 (pinned to top).
  final bool isNotToDo;

  /// Android package name. Used for icon lookup via AppIconLruCache (Phase 2)
  /// with letter-avatar fallback (Plan 03-05).
  final String packageName;

  /// Human-readable label. From block_list.displayName for not-to-do rows;
  /// from packageName (last segment) for non-list rows when no display label
  /// is available (Phase 3 doesn't query PackageManager.getApplicationLabel
  /// for every row — ~50 apps would mean ~50 IPC calls).
  final String displayName;

  /// Aggregate foreground seconds across the active range.
  final int foregroundSeconds;
}
