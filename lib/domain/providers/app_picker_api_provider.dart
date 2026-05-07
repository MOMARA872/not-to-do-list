import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/platform/app_picker_api.g.dart';

/// Pigeon channel singleton for the app picker (installed apps, recently used,
/// per-package PNG icon bytes). Hand-written (no `@riverpod` codegen).
///
/// Tests override via:
/// `appPickerApiProvider.overrideWith((ref) => MockAppPickerApi())`.
final Provider<AppPickerApi> appPickerApiProvider =
    Provider<AppPickerApi>((ref) => AppPickerApi());
