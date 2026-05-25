import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/settings/services/file_save_port.dart';

/// Riverpod binding for [FileSavePort].
///
/// Mirrors [notificationApiProvider] shape (Pigeon-port project convention).
/// Widget tests override via:
/// ```dart
/// fileSavePortProvider.overrideWith((ref) => MockFileSavePort())
/// ```
final Provider<FileSavePort> fileSavePortProvider =
    Provider<FileSavePort>((ref) => const FlutterFileDialogSavePort());
