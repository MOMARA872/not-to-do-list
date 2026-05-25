// Phase 6 Wave 0 fixture: mock FileSavePort for export tests.
// Mirrors test/_fixtures/permission_status_mock.dart convention.
//
// TODO(06-04): Replace this placeholder with the real FileSavePort import after
// lib/features/settings/services/file_save_port.dart lands in 06-04 Task 1.
// Delete the placeholder abstract class below and uncomment:
// import 'package:not_to_do_list/features/settings/services/file_save_port.dart';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';

/// Placeholder — superseded by lib/features/settings/services/file_save_port.dart
/// in 06-04. The real interface lands there; this stub keeps Wave 0 tests
/// compilable without the production file.
@Deprecated('placeholder — superseded by file_save_port.dart in 06-04')
abstract class FileSavePort {
  /// Returns the saved URI/path, or null on user cancel.
  /// Throws on I/O failure.
  Future<String?> save({
    required Uint8List bytes,
    required String fileName,
    required List<String> mimeTypes,
  });
}

class MockFileSavePort extends Mock implements FileSavePort {}
