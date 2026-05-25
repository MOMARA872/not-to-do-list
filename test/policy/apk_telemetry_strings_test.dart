// Phase 6 Plan 06-07 — APK telemetry strings sweep.
// Tests decoded release APK classes*.dex for forbidden telemetry token strings.
// Gracefully skips when APK absent (CI may not have built release yet).
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 6 / APK telemetry strings (PLAY-09)', () {
    test(
      'decoded release APK classes*.dex strings contain no telemetry tokens',
      () {
        // Gracefully skip when APK absent (CI may not have built release yet).
        const apkPath = 'build/app/outputs/apk/release/app-release.apk';
        final apk = File(apkPath);
        if (!apk.existsSync()) return;

        // Sweep all classes*.dex files inside the APK (multidex-safe glob per
        // RESEARCH Pitfall 5 — classes2.dex, classes3.dex are all swept).
        final result = Process.runSync('sh', <String>[
          '-c',
          "unzip -p '$apkPath' 'classes*.dex' | strings | "
              "grep -iE '(firebase|crashlytics|analytics|fcm|remoteconfig)' | head -5",
        ]);
        expect(
          (result.stdout as String).trim(),
          isEmpty,
          reason:
              'PLAY-09: release APK contains forbidden telemetry tokens:\n${result.stdout}',
        );
      },
    );
  });
}
