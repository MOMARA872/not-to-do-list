// Plan 04-04 — BlockListRepository D-10 broadcast emit tests.
//
// Verifies that BlockListRepository emits publishBlockList after every
// mutating operation (add, delete, republishCurrent).
//
// D-10 contract: Dart fires via BlocklistBroadcastApi.publishBlockList()
// after every insert/update/delete/insertMany so the AccessibilityService
// in-memory Map<String, ScheduleSlice> stays in sync without reading SQLite.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/platform/blocklist_broadcast_api.g.dart';

class MockBlocklistBroadcastApi extends Mock implements BlocklistBroadcastApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(<BlockListEntrySnapshot>[]);
  });

  group('BlockListRepository broadcast emit (D-10)', () {
    late AppDatabase db;
    late BlockListRepository repo;
    late MockBlocklistBroadcastApi mockBroadcaster;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      mockBroadcaster = MockBlocklistBroadcastApi();
      when(() => mockBroadcaster.publishBlockList(any()))
          .thenAnswer((_) async {});
      repo = BlockListRepository(BlockListDao(db), mockBroadcaster);
    });

    tearDown(() => db.close());

    test('add() emits publishBlockList with the new entry snapshot', () async {
      await repo.add(
        kind: 0,
        packageName: 'com.example.app',
        displayName: 'Example App',
      );

      final captured = verify(
        () => mockBroadcaster.publishBlockList(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final snapshots = captured.first as List<BlockListEntrySnapshot>;
      expect(snapshots.length, 1);
      expect(snapshots.first.packageName, 'com.example.app');
      expect(snapshots.first.blockMode, 'soft');
    });

    test(
        'delete() emits publishBlockList with the deleted entry absent from snapshot',
        () async {
      final id = await repo.add(
        kind: 0,
        packageName: 'com.example.deleteme',
        displayName: 'Delete Me',
      );
      clearInteractions(mockBroadcaster);

      await repo.delete(id);

      final captured = verify(
        () => mockBroadcaster.publishBlockList(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final snapshots = captured.first as List<BlockListEntrySnapshot>;
      expect(
        snapshots.any((s) => s.packageName == 'com.example.deleteme'),
        isFalse,
      );
    });

    test('republishCurrent() emits publishBlockList with current snapshot',
        () async {
      await repo.add(
        kind: 0,
        packageName: 'com.example.repub',
        displayName: 'Repub App',
      );
      clearInteractions(mockBroadcaster);

      await repo.republishCurrent();

      final captured = verify(
        () => mockBroadcaster.publishBlockList(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final snapshots = captured.first as List<BlockListEntrySnapshot>;
      expect(snapshots.any((s) => s.packageName == 'com.example.repub'), isTrue);
    });
  });
}
