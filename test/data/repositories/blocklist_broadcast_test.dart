// Phase 4 Plan 04-01 — Wave 0 stub for BlockListRepository broadcast emit.
// Implementation lands in Plan 04-04, which wires the LocalBroadcast emit on
// every insert/update/delete mutation via the BlocklistBroadcastApi Pigeon
// channel.
//
// D-10 contract: Dart fires
//   'com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED'
// as a LocalBroadcast whenever BlockListRepository mutates.
// The service updates its in-memory Set<String> on receipt.
// The service NEVER reads from SQLite directly.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlockListRepository broadcast emit (D-10)', () {
    test(
      'placeholder',
      () {},
      skip: "Plan 04-04 fills — contract action string is "
          "'com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED'",
    );
  });
}
