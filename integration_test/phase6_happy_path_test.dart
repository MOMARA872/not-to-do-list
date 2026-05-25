// Phase 6 Wave 0 RED stub — phase6_happy_path_test.dart
// Manual gate: 9-step OEM-survival overnight protocol.
// Template written in 06-08. Activation via PHASE-6 OEM PASS signal.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PHASE-6 OEM PASS — manual',
    (tester) async {
      markTestSkipped(
        'manual gate — run on real Xiaomi AND Samsung overnight '
        'per 06-VERIFICATION.md',
      );
      // 9-step OEM-survival overnight protocol:
      // Step 1: Complete onboarding on fresh install.
      // Step 2: Add at least one not-to-do entry.
      // Step 3: Trigger blocked-app launch → verify pause screen appears.
      // Step 4: Complete cooldown → verify app closes.
      // Step 5: Wait for streak roll-over (next day, lazy-on-open).
      // Step 6: Verify daily reminder fires at user-chosen time.
      // Step 7: Unplug device (Doze mode test ≥8h unplugged).
      // Step 8: Re-open app → verify streak incremented correctly.
      // Step 9: Export data → verify ZIP opens in external app.
    },
  );
}
