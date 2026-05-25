// Phase 6 fixture: mock FileSavePort for export tests.
// Mirrors test/_fixtures/permission_status_mock.dart convention.
//
// Activated in 06-04 Task 1 — real FileSavePort import replaces the
// placeholder abstract class that Wave 0 (06-01) used.
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/features/settings/services/file_save_port.dart';

export 'package:not_to_do_list/features/settings/services/file_save_port.dart';

class MockFileSavePort extends Mock implements FileSavePort {}

/// Register fallback values needed by tests that use [MockFileSavePort].
/// Call once inside [setUpAll] in test files that use the mock.
void setUpFileSavePortMock() {
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(<String>[]);
}
