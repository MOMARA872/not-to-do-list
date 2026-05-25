import 'dart:typed_data';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';

/// Port abstraction for the Storage Access Framework file-save dialog.
///
/// Production code depends on [FlutterFileDialogSavePort]; widget tests inject
/// [MockFileSavePort] via Riverpod override so no real Android intent is fired
/// during testing. (SETT-01 / RESEARCH §Anti-Patterns "wrap in port for test
/// stubbing".)
abstract class FileSavePort {
  /// Presents a file-save picker and writes [bytes] to the user-chosen
  /// location.
  ///
  /// Returns the saved URI/path on success, or `null` when the user cancels
  /// (Pitfall 3 — null is a silent cancel, not an error).
  ///
  /// Throws on I/O failure; the caller decides SnackBar copy.
  Future<String?> save({
    required Uint8List bytes,
    required String fileName,
    required List<String> mimeTypes,
  });
}

/// Concrete implementation that delegates to [FlutterFileDialog.saveFile].
///
/// The `mimeTypesFilter:` field name is intentionally plural — that is the
/// field name defined by `SaveFileDialogParams` (RESEARCH Pitfall hint,
/// lines 446-448).
class FlutterFileDialogSavePort implements FileSavePort {
  const FlutterFileDialogSavePort();

  @override
  Future<String?> save({
    required Uint8List bytes,
    required String fileName,
    required List<String> mimeTypes,
  }) {
    return FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
        mimeTypesFilter: mimeTypes,
      ),
    );
  }
}
