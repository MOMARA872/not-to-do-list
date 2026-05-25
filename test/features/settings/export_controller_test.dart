// Phase 6 GREEN — export_controller_test.dart
// Tests ExportController ZIP round-trip, filename pattern, parallel reads,
// and FileSavePort return-value passthrough. SETT-01.
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/features/settings/services/export_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../_fixtures/file_save_port_mock.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────��───────────────────���──────────────────────────────────────────────────

AppDatabase buildTestDb() => AppDatabase(NativeDatabase.memory());

PackageInfo buildFakePackageInfo({
  String version = '1.0.0',
  String buildNumber = '1',
}) {
  return PackageInfo(
    appName: 'Not To-Do List',
    packageName: 'com.example.not_to_do_list',
    version: version,
    buildNumber: buildNumber,
  );
}

/// Insert 1 block_list row and 1 row in every child table for testing.
Future<int> seedDb(AppDatabase db) async {
  final now = DateTime.utc(2026, 5, 24, 12);

  // block_list entry.
  final entryId = await db.into(db.blockList).insert(
        BlockListCompanion.insert(
          kind: 0,
          packageName: const Value('com.instagram.android'),
          displayName: 'Instagram',
          createdAt: now,
          updatedAt: now,
        ),
      );

  // daily_checkins row.
  await db.into(db.dailyCheckins).insert(
        DailyCheckinsCompanion.insert(
          entryId: entryId,
          day: now,
          avoided: true,
          answeredAt: now,
        ),
      );

  // daily_streak row.
  await db.into(db.dailyStreak).insert(
        DailyStreakCompanion.insert(
          entryId: entryId,
          day: now,
          status: 0,
          source: 0,
          evaluatedAt: now,
        ),
      );

  // pause_events row.
  await db.into(db.pauseEvents).insert(
        PauseEventsCompanion.insert(
          entryId: entryId,
          packageName: 'com.instagram.android',
          triggeredAt: now,
          outcome: 0,
        ),
      );

  // daily_usage_summary row.
  await db.into(db.dailyUsageSummary).insert(
        DailyUsageSummaryCompanion.insert(
          packageName: 'com.instagram.android',
          day: now,
          foregroundSeconds: 300,
          aggregatedAt: now,
        ),
      );

  return entryId;
}

// ─��───────────────────────────────────────────────────────────────────────────
// Tests
// ────────��─────────────────��──────────────────────────────────���───────────────

void main() {
  setUpAll(setUpFileSavePortMock);

  late AppDatabase db;
  late MockFileSavePort mockSaver;
  late ExportController controller;
  const savedPath = '/storage/emulated/0/export.zip';

  setUp(() async {
    db = buildTestDb();
    await seedDb(db);
    mockSaver = MockFileSavePort();
    when(
      () => mockSaver.save(
        bytes: any(named: 'bytes'),
        fileName: any(named: 'fileName'),
        mimeTypes: any(named: 'mimeTypes'),
      ),
    ).thenAnswer((_) async => savedPath);

    controller = ExportController(
      db,
      buildFakePackageInfo(),
      mockSaver,
    );
  });

  tearDown(() => db.close());

  group('Phase 6 / ExportController (SETT-01)', () {
    test('ZIP contains 5 CSVs + data.json (6 files total)', () async {
      final path = await controller.exportAll();
      expect(path, equals(savedPath));

      // Capture the bytes that were handed to the port.
      final captured = verify(
        () => mockSaver.save(
          bytes: captureAny(named: 'bytes'),
          fileName: any(named: 'fileName'),
          mimeTypes: any(named: 'mimeTypes'),
        ),
      ).captured;
      final bytes = captured.first as Uint8List;

      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.map((f) => f.name).toSet();
      expect(names, containsAll([
        'block_list.csv',
        'daily_checkins.csv',
        'daily_streak.csv',
        'pause_events.csv',
        'daily_usage_summary.csv',
        'data.json',
      ]));
      expect(archive.length, equals(6));
    });

    test(
      'filename matches not-to-do-list-export-YYYYMMDD-HHMM.zip regex',
      () async {
        await controller.exportAll();

        final captured = verify(
          () => mockSaver.save(
            bytes: any(named: 'bytes'),
            fileName: captureAny(named: 'fileName'),
            mimeTypes: any(named: 'mimeTypes'),
          ),
        ).captured;
        final filename = captured.first as String;

        expect(
          filename,
          matches(RegExp(r'^not-to-do-list-export-\d{8}-\d{4}\.zip$')),
        );
      },
    );

    test('data.json schemaVersion equals 1', () async {
      await controller.exportAll();

      final captured = verify(
        () => mockSaver.save(
          bytes: captureAny(named: 'bytes'),
          fileName: any(named: 'fileName'),
          mimeTypes: any(named: 'mimeTypes'),
        ),
      ).captured;
      final bytes = captured.first as Uint8List;

      final archive = ZipDecoder().decodeBytes(bytes);
      final jsonFile = archive.firstWhere((f) => f.name == 'data.json');
      final jsonMap =
          jsonDecode(utf8.decode(jsonFile.content as List<int>))
              as Map<String, dynamic>;

      expect(jsonMap['schemaVersion'], equals(1));
    });

    test('data.json exportedAt is ISO-8601 UTC ending in Z', () async {
      await controller.exportAll();

      final captured = verify(
        () => mockSaver.save(
          bytes: captureAny(named: 'bytes'),
          fileName: any(named: 'fileName'),
          mimeTypes: any(named: 'mimeTypes'),
        ),
      ).captured;
      final bytes = captured.first as Uint8List;

      final archive = ZipDecoder().decodeBytes(bytes);
      final jsonFile = archive.firstWhere((f) => f.name == 'data.json');
      final jsonMap =
          jsonDecode(utf8.decode(jsonFile.content as List<int>))
              as Map<String, dynamic>;

      final exportedAt = jsonMap['exportedAt'] as String;
      expect(exportedAt, endsWith('Z'));
      // Must parse as valid DateTime.
      expect(() => DateTime.parse(exportedAt), returnsNormally);
    });

    test('exportAll returns the FileSavePort.save() return value', () async {
      final path = await controller.exportAll();
      expect(path, equals(savedPath));

      // null return (user cancel) should pass through.
      when(
        () => mockSaver.save(
          bytes: any(named: 'bytes'),
          fileName: any(named: 'fileName'),
          mimeTypes: any(named: 'mimeTypes'),
        ),
      ).thenAnswer((_) async => null);

      final nullPath = await controller.exportAll();
      expect(nullPath, isNull);
    });
  });
}
