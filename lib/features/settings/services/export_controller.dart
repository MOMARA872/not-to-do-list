import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/features/settings/services/file_save_port.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Controller for the SETT-01 export flow.
///
/// Reads all 5 Drift DAOs in parallel, builds 5 CSVs + a data.json envelope,
/// packages them in a ZIP archive, and hands the bytes to [FileSavePort] for
/// the Storage Access Framework single-pick write.
///
/// Construction: `ExportController(db, packageInfo, saver)` — all three are
/// injected, making the class fully testable with a MockFileSavePort and
/// an in-memory Drift database (RESEARCH §Anti-Patterns).
class ExportController {
  ExportController(this._db, this._packageInfo, this._saver);

  final AppDatabase _db;
  final PackageInfo _packageInfo;
  final FileSavePort _saver;

  // ──────────────────────────────────────────────────────────────────────────
  // Per-table column order (verbatim Drift field-declaration order — D-10).
  // Hard-coded so the header row is stable even when a table has zero rows.
  // ──────────────────────────────────────────────────────────────────────────

  static const List<String> _blockListColumns = [
    'id',
    'kind',
    'packageName',
    'displayName',
    'reasonNote',
    'streakBreakThresholdMinutes',
    'createdAt',
    'updatedAt',
    'blockMode',
    'scheduleStartMinutes',
    'scheduleEndMinutes',
    'scheduleWeekdayMask',
  ];

  static const List<String> _dailyCheckinsColumns = [
    'id',
    'entryId',
    'day',
    'avoided',
    'answeredAt',
  ];

  static const List<String> _dailyStreakColumns = [
    'id',
    'entryId',
    'day',
    'status',
    'source',
    'usageMinutesObserved',
    'evaluatedAt',
  ];

  static const List<String> _pauseEventsColumns = [
    'id',
    'entryId',
    'packageName',
    'triggeredAt',
    'cooldownChosenSeconds',
    'outcome',
  ];

  static const List<String> _dailyUsageSummaryColumns = [
    'id',
    'packageName',
    'day',
    'foregroundSeconds',
    'launchCount',
    'aggregatedAt',
  ];

  // Columns that hold DateTime values. Drift's default toJson stores DateTime
  // as millisecondsSinceEpoch (int); we convert to ISO-8601 UTC in CSV output.
  static const Set<String> _dateTimeColumns = {
    'createdAt',
    'updatedAt',
    'day',
    'evaluatedAt',
    'triggeredAt',
    'answeredAt',
    'aggregatedAt',
  };

  // ──────────────────────────────────────────────────────────────────────────

  /// Export all data to a ZIP archive and save via the [FileSavePort].
  ///
  /// Returns the saved URI/path on success, or `null` when the user cancels.
  /// Throws on I/O failure — the caller (ExportScreen) decides the SnackBar.
  Future<String?> exportAll() async {
    // 1. Parallel DAO reads.
    final results = await Future.wait([
      _db.blockListDao.getAll(),
      _db.dailyCheckinsDao.getAll(),
      _db.dailyStreakDao.getAll(),
      _db.pauseEventDao.getAll(),
      _db.dailyUsageSummaryDao.getAll(),
    ]);

    final blockListRows = results[0] as List<BlockListData>;
    final dailyCheckinsRows = results[1] as List<DailyCheckin>;
    final dailyStreakRows = results[2] as List<DailyStreakData>;
    final pauseEventRows = results[3] as List<PauseEvent>;
    final dailyUsageSummaryRows = results[4] as List<DailyUsageSummaryData>;

    // 2. Build CSVs (header row = Drift column names verbatim, D-10).
    final csv0 = _toCsv(
      _blockListColumns,
      blockListRows.map((r) => r.toJson()).toList(),
    );
    final csv1 = _toCsv(
      _dailyCheckinsColumns,
      dailyCheckinsRows.map((r) => r.toJson()).toList(),
    );
    final csv2 = _toCsv(
      _dailyStreakColumns,
      dailyStreakRows.map((r) => r.toJson()).toList(),
    );
    final csv3 = _toCsv(
      _pauseEventsColumns,
      pauseEventRows.map((r) => r.toJson()).toList(),
    );
    final csv4 = _toCsv(
      _dailyUsageSummaryColumns,
      dailyUsageSummaryRows.map((r) => r.toJson()).toList(),
    );

    // 3. Build data.json envelope (D-11 + D-12).
    // Use default toJson (ms since epoch) then convert timestamps to UTC ISO.
    final envelope = {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion':
          '${_packageInfo.version}+${_packageInfo.buildNumber}',
      'tables': {
        'block_list': blockListRows
            .map((r) => _convertRowTimestamps(r.toJson()))
            .toList(),
        'daily_checkins': dailyCheckinsRows
            .map((r) => _convertRowTimestamps(r.toJson()))
            .toList(),
        'daily_streak': dailyStreakRows
            .map((r) => _convertRowTimestamps(r.toJson()))
            .toList(),
        'pause_events': pauseEventRows
            .map((r) => _convertRowTimestamps(r.toJson()))
            .toList(),
        'daily_usage_summary': dailyUsageSummaryRows
            .map((r) => _convertRowTimestamps(r.toJson()))
            .toList(),
      },
    };
    final jsonBytes = utf8.encode(jsonEncode(envelope));

    // 4. Build archive (5 CSVs + data.json = 6 entries).
    final archive = Archive()
      ..addFile(ArchiveFile('block_list.csv', csv0.length, csv0))
      ..addFile(ArchiveFile('daily_checkins.csv', csv1.length, csv1))
      ..addFile(ArchiveFile('daily_streak.csv', csv2.length, csv2))
      ..addFile(ArchiveFile('pause_events.csv', csv3.length, csv3))
      ..addFile(
        ArchiveFile('daily_usage_summary.csv', csv4.length, csv4),
      )
      ..addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    // 5. Encode ZIP.
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    // 6. Filename: local-time date for human clarity (D-09).
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final filename = 'not-to-do-list-export-$stamp.zip';

    // 7. Save via SAF — returns null on user cancel, throws on I/O error.
    return _saver.save(
      bytes: zipBytes,
      fileName: filename,
      mimeTypes: const <String>['application/zip'],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Convert DateTime columns in a Drift toJson() map from milliseconds-since-
  /// epoch (int) to ISO-8601 UTC strings (D-12). Returns a new map.
  Map<String, dynamic> _convertRowTimestamps(Map<String, dynamic> row) {
    return {
      for (final entry in row.entries)
        entry.key: _dateTimeColumns.contains(entry.key) && entry.value is int
            ? DateTime.fromMillisecondsSinceEpoch(
                entry.value as int,
                isUtc: true,
              ).toIso8601String()
            : entry.value,
    };
  }

  /// Format a single field value for CSV output.
  ///
  /// - DateTime (stored as ms since epoch int by Drift default toJson)
  ///   → ISO-8601 UTC string per D-12.
  /// - `null` → empty string.
  /// - Other values → [_escape] the string representation.
  String _formatField(String column, dynamic value) {
    if (value == null) return '';
    if (_dateTimeColumns.contains(column) && value is int) {
      // Drift's default toJson stores DateTime as millisecondsSinceEpoch.
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
          .toIso8601String();
    }
    return _escape(value.toString());
  }

  /// Build a CSV byte list for one table.
  ///
  /// - [columns]: hard-coded column order; becomes the header row (D-10).
  /// - [rows]: `row.toJson()` maps from Drift data classes.
  List<int> _toCsv(List<String> columns, List<Map<String, dynamic>> rows) {
    final buf = StringBuffer();
    // Header row — column names verbatim (D-10).
    buf.writeln(columns.join(','));
    for (final row in rows) {
      final fields = columns.map((col) => _formatField(col, row[col]));
      buf.writeln(fields.join(','));
    }
    return utf8.encode(buf.toString());
  }

  /// CSV-safe escape per RFC 4180 + OWASP CSV-injection mitigation (V5).
  ///
  /// 1. Fields starting with `=`, `+`, `-`, `@` are prefixed with `'`
  ///    (CSV-injection guard, Security Domain V5).
  /// 2. Fields containing `,`, `"`, or `\n` are wrapped in double-quotes
  ///    with internal `"` doubled (RFC 4180).
  String _escape(String s) {
    var result = s;
    // CSV-injection mitigation (OWASP).
    if (result.isNotEmpty && '=+-@'.contains(result[0])) {
      result = "'$result";
    }
    // RFC 4180 quoting.
    if (result.contains(',') ||
        result.contains('"') ||
        result.contains('\n')) {
      result = '"${result.replaceAll('"', '""')}"';
    }
    return result;
  }
}
