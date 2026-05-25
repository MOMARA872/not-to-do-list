// Phase 6 GREEN — export_json_envelope_test.dart
// Tests data.json envelope shape per D-11 + D-12. SETT-01.
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

Future<Map<String, dynamic>> runExportGetJson(
  AppDatabase db,
  PackageInfo pi,
  MockFileSavePort saver,
) async {
  final controller = ExportController(db, pi, saver);
  await controller.exportAll();

  final captured = verify(
    () => saver.save(
      bytes: captureAny(named: 'bytes'),
      fileName: any(named: 'fileName'),
      mimeTypes: any(named: 'mimeTypes'),
    ),
  ).captured;

  final bytes = captured.first as Uint8List;
  final archive = ZipDecoder().decodeBytes(bytes);
  final jsonFile = archive.firstWhere((f) => f.name == 'data.json');
  return jsonDecode(utf8.decode(jsonFile.content as List<int>))
      as Map<String, dynamic>;
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

  group('Phase 6 / Export JSON envelope (SETT-01, D-11)', () {
    test(
      'envelope keys exactly: schemaVersion, exportedAt, appVersion, tables',
      () async {
        final json = await runExportGetJson(
          db,
          buildFakePackageInfo(),
          mockSaver,
        );

        expect(json.keys.toSet(), equals({'schemaVersion', 'exportedAt', 'appVersion', 'tables'}));
        expect(json['schemaVersion'], equals(1));
        expect(json['exportedAt'], isA<String>());
        expect(json['appVersion'], isA<String>());
        expect(json['tables'], isA<Map>());
      },
    );

    test('tables keys exactly the 5 table names', () async {
      final json = await runExportGetJson(
        db,
        buildFakePackageInfo(),
        mockSaver,
      );

      final tables = json['tables'] as Map<String, dynamic>;
      expect(
        tables.keys.toSet(),
        equals({
          'block_list',
          'daily_checkins',
          'daily_streak',
          'pause_events',
          'daily_usage_summary',
        }),
      );
    });

    test('appVersion format is "version+buildNumber"', () async {
      final json = await runExportGetJson(
        db,
        buildFakePackageInfo(version: '1.0.0', buildNumber: '1'),
        mockSaver,
      );

      expect(json['appVersion'], equals('1.0.0+1'));
    });

    test(
      'exportedAt ends with Z (ISO-8601 UTC) and parses as valid DateTime',
      () async {
        final json = await runExportGetJson(
          db,
          buildFakePackageInfo(),
          mockSaver,
        );

        final exportedAt = json['exportedAt'] as String;
        expect(exportedAt, endsWith('Z'));
        expect(() => DateTime.parse(exportedAt), returnsNormally);
        final parsed = DateTime.parse(exportedAt);
        expect(parsed.isUtc, isTrue);
      },
    );

    test(
      'tables arrays contain rows in ISO-8601 UTC string format for DateTime fields',
      () async {
        final now = DateTime.utc(2026, 5, 24, 12);
        await db.into(db.blockList).insert(
              BlockListCompanion.insert(
                kind: 0,
                packageName: const Value('com.test.app'),
                displayName: 'TestApp',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final json = await runExportGetJson(
          db,
          buildFakePackageInfo(),
          mockSaver,
        );

        final blockList =
            (json['tables'] as Map<String, dynamic>)['block_list'] as List;
        expect(blockList, isNotEmpty);
        final row = blockList.first as Map<String, dynamic>;
        final createdAt = row['createdAt'] as String;
        expect(createdAt, endsWith('Z'));
        expect(() => DateTime.parse(createdAt), returnsNormally);
      },
    );
  });
}
