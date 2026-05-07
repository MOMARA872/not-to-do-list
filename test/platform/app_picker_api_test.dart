// Phase 2 Plan 02-03: minimal smoke test that the Pigeon-generated
// `AppPickerApi` Dart class compiles and is instantiable. End-to-end picker
// behavior is exercised in Plan 02-06's widget tests via provider override —
// that is the more valuable test surface and does not depend on Pigeon
// channel internals (which change shape across Pigeon versions).
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/platform/app_picker_api.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Note: round-trip coverage of `listInstalledApps` lives in Plan 02-06's
  // widget tests, where `appPickerApiProvider` is overridden with a mock.
  // That is the canonical seam — it does not couple to the exact
  // Pigeon-emitted channel-name + codec internals (which change shape across
  // Pigeon versions). Plan 02-10 removed the previously-skipped placeholder
  // here so the suite reports zero skipped tests at the phase exit gate.
  group('AppPickerApi Pigeon channel (LIST-01)', () {
    test('AppPickerApi class exists and is instantiable', () {
      final api = AppPickerApi();
      expect(api, isNotNull);
    });
  });
}
