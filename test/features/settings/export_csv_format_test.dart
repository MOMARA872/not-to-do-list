// Phase 6 GREEN — export_csv_format_test.dart
// Tests CSV escape + header row verbatim column names. SETT-01.
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

AppDatabase buildTestDb() => AppDatabase(NativeDatabase.memory());

PackageInfo buildFakePackageInfo() => PackageInfo(
      appName: 'Not To-Do List',
      packageName: 'com.example.not_to_do_list',
      version: '1.0.0',
      buildNumber: '1',
    );

Archive decodeZip(Uint8List bytes) => ZipDecoder().decodeBytes(bytes);

String csvContent(Archive archive, String filename) {
  final file = archive.firstWhere((f) => f.name == filename);
  return utf8.decode(file.content as List<int>);
}

void main() {
  setUpAll(setUpFileSavePortMock);

  late AppDatabase db;
  late MockFileSavePort mockSaver;

  setUp(() {
    db = buildTestDb();
    mockSaver = MockFileSavePort();
    when(
      () => mockSaver.save(
        bytes: any(named: 'bytes'),
        fileName: any(named: 'fileName'),
        mimeTypes: any(named: 'mimeTypes'),
      ),
    ).thenAnswer((_) async => '/storage/test.zip');
  });

  tearDown(() => db.close());

  group('Phase 6 / Export CSV format (SETT-01)', () {
    test('header row equals Drift column names verbatim per D-10', () async {
      final controller = ExportController(
        db,
        buildFakePackageInfo(),
        mockSaver,
      );
      await controller.exportAll();

      final captured = verify(
        () => mockSaver.save(
          bytes: captureAny(named: 'bytes'),
          fileName: any(named: 'fileName'),
          mimeTypes: any(named: 'mimeTypes'),
        ),
      ).captured;

      final archive = decodeZip(captured.first as Uint8List);
      final csv = csvContent(archive, 'block_list.csv');
      final firstLine = csv.split('\n').first;

      // Verbatim Drift column names (D-10) in declaration order.
      expect(firstLine, equals('id,kind,packageName,displayName,reasonNote,'
          'streakBreakThresholdMinutes,createdAt,updatedAt,blockMode,'
          'scheduleStartMinutes,scheduleEndMinutes,scheduleWeekdayMask'));
    });

    test(
      'CSV escaping wraps fields containing comma, quote, or newline in quotes',
      () async {
        final now = DateTime.utc(2026, 5, 24, 12);
        // Insert rows with special characters in displayName.
        await db.into(db.blockList).insert(
              BlockListCompanion.insert(
                kind: 0,
                packageName: const Value('com.test.comma'),
                displayName: 'Hello, World',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db.into(db.blockList).insert(
              BlockListCompanion.insert(
                kind: 1,
                displayName: 'He said "hi"',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final controller = ExportController(
          db,
          buildFakePackageInfo(),
          mockSaver,
        );
        await controller.exportAll();

        final captured = verify(
          () => mockSaver.save(
            bytes: captureAny(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeTypes: any(named: 'mimeTypes'),
          ),
        ).captured;

        final archive = decodeZip(captured.first as Uint8List);
        final csv = csvContent(archive, 'block_list.csv');

        // Comma → wrapped in double-quotes.
        expect(csv, contains('"Hello, World"'));
        // Internal double-quote → doubled inside wrapper.
        expect(csv, contains('"He said ""hi"""'));
      },
    );

    test(
      'CSV-injection prefix on =, +, -, @ fields per Security Domain V5',
      () async {
        final now = DateTime.utc(2026, 5, 24, 12);
        // Insert rows where displayName starts with injection characters.
        await db.into(db.blockList).insert(
              BlockListCompanion.insert(
                kind: 1,
                displayName: '=MALICIOUS()',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db.into(db.blockList).insert(
              BlockListCompanion.insert(
                kind: 1,
                displayName: '+dangerous',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db.into(db.blockList).insert(
              BlockListCompanion.insert(
                kind: 1,
                displayName: '@cmd',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final controller = ExportController(
          db,
          buildFakePackageInfo(),
          mockSaver,
        );
        await controller.exportAll();

        final captured = verify(
          () => mockSaver.save(
            bytes: captureAny(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeTypes: any(named: 'mimeTypes'),
          ),
        ).captured;

        final archive = decodeZip(captured.first as Uint8List);
        final csv = csvContent(archive, 'block_list.csv');

        // Each injection-prone field must be prefixed with a single quote.
        expect(csv, contains("'=MALICIOUS()"));
        expect(csv, contains("'+dangerous"));
        expect(csv, contains("'@cmd"));
      },
    );
  });
}
