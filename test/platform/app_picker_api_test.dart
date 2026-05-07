// Phase 2 Plan 02-03: minimal smoke test that the Pigeon-generated
// `AppPickerApi` Dart class compiles and is instantiable. End-to-end picker
// behavior is exercised in Plan 02-06's widget tests via provider override —
// that is the more valuable test surface and does not depend on Pigeon
// channel internals (which change shape across Pigeon versions).
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/platform/app_picker_api.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPickerApi Pigeon channel (LIST-01)', () {
    test('AppPickerApi class exists and is instantiable', () {
      final api = AppPickerApi();
      expect(api, isNotNull);
    });

    test(
      'listInstalledApps round-trips an InstalledApp list via mock channel',
      () async {
        // Full round-trip lands when widget tests in Plan 02-06 override the
        // appPickerApiProvider with a mock — that is the canonical seam. This
        // test stays skipped to document intent without coupling to the
        // exact Pigeon-emitted channel-name + codec internals.
      },
      skip: 'Exercised end-to-end via provider override in Plan 02-06',
    );
  });
}
