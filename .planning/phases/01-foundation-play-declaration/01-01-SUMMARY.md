# Plan 01-01 — Foundation Toolchain & Project Scaffold

**Phase:** 01-foundation-play-declaration
**Plan:** 01-01
**Wave:** 0
**Completed:** 2026-05-04

## What landed

Wave 0 toolchain installed and the Flutter Android-only project scaffolded at `/Users/jintanakhomwong/projects/not-to-do-list`. All Phase-1 dependencies pinned, lints active, telemetry-free dep tree confirmed, folder skeleton ready for Wave-1 plans.

## Toolchain versions installed

| Component | Version |
|-----------|---------|
| Flutter SDK | 3.41.9 (channel stable, darwin-arm64) |
| Dart SDK | 3.11.5 |
| JDK (Temurin) | 17.0.19 (2026-04-21) |
| Android SDK platforms | android-36 |
| Android SDK build-tools | 36.0.0 |
| Android SDK platform-tools | 37.0.0 |
| Android SDK cmdline-tools | latest (sdkmanager 19.0) |

`flutter doctor` Android section: `[✓] Android toolchain - develop for Android devices (Android SDK version 36.0.0)` — green. Xcode line stays `[✗]` (expected — Phase 1 is Android-only).

## Resolved package versions (pubspec.lock)

| Package | Resolved |
|---------|----------|
| drift | 2.33.0 |
| drift_flutter | 0.3.0 |
| flutter_riverpod | 3.3.1 |
| pigeon | 26.3.4 |
| go_router | 17.2.3 |
| shared_preferences | 2.5.5 |
| very_good_analysis | 10.2.0 |

## Deviations from RESEARCH §1 / STACK.md

The planner's pubspec versions were keyed off training-time pub.dev snapshots; live `flutter pub get` showed the ecosystem had moved. The plan explicitly authorized version bumps under Assumption A6. Bumps applied:

| Package | Plan pin | Resolved | Reason |
|---------|----------|----------|--------|
| `drift` | ^2.32.1 | ^2.33.0 | Latest stable on pub.dev |
| `drift_flutter` | ^0.2.0 | ^0.3.0 | A6 fallback path |
| `go_router` | ^14.0.0 | ^17.2.3 | Major bump (no breaking API for our placeholder usage) |
| `very_good_analysis` | ^7.0.0 | ^10.2.0 | Lint preset moved; placeholder code analyses clean |
| `intl` | ^0.20.0 | ^0.20.2 | patch bump |
| `path_provider` | ^2.1.0 | ^2.1.5 | patch bump |
| `path` | ^1.9.0 | ^1.9.1 | patch bump |
| `shared_preferences` | ^2.3.0 | ^2.5.5 | minor bump |
| `mocktail` | ^1.0.0 | ^1.0.5 | patch bump |

**Dropped from Phase 1 (with rationale):**

| Package | Why dropped |
|---------|-------------|
| `riverpod_annotation` | Generator depends on it; dropping with generator |
| `riverpod_generator` | Pinned analyzer minor incompatible with `pigeon 26.3.4` + Flutter 3.41 (`meta 1.17`). Phase 1 providers will be hand-written; reintroduce when ecosystem converges on analyzer 12+ |
| `custom_lint` | 0.8.x pins `analyzer ^8.0` while `drift_dev 2.33` requires `analyzer >=10.0`. IDE-side lint helper only |
| `riverpod_lint` | Depends on `custom_lint` |

Lints are still enforced via `very_good_analysis 10.2.0` — these were nice-to-haves, not load-bearing. The drop is recoverable in a single pubspec edit once the ecosystem unblocks.

## Project shape verified

- `applicationId = "com.nottodo.not_to_do_list"` (Gradle locked)
- `compileSdk = 36`, `minSdk = 29`, `targetSdk = 36`
- Java 17 sourceCompatibility + targetCompatibility
- Kotlin `jvmTarget` = 17
- No `ios/`, `macos/`, `linux/`, `windows/`, `web/` directories (verified via shell loop)
- `test/widget_test.dart` deleted (auto-generated counter-app test)
- `lib/main.dart` replaced with `_PlaceholderApp` stub
- `analysis_options.yaml` extends `package:very_good_analysis/analysis_options.yaml`

## Folder skeleton (RESEARCH §7) — created

20 directories under `lib/`, `test/`, `pigeons/`, `docs/`, `tool/`, `android/app/src/main/res/xml/`, `android/app/src/main/kotlin/com/nottodo/not_to_do_list/{service,platform}/`. 5 `.gitkeep` files placed in dirs that will be filled by Phase 2.

## Verification commands (all exit 0)

```
flutter --version | head -1                 # Flutter 3.41.9 ...
java -version 2>&1 | head -1                # openjdk version "17.0.19" ...
sdkmanager --list_installed                 # platforms;android-36, build-tools;36.0.0, platform-tools
flutter pub get                             # 96 deps resolved
flutter analyze                             # No issues found!
flutter pub deps | grep -iE "firebase|fcm|analytics|crashlytics|amplitude|mixpanel|segment|sentry|datadog|appsflyer|adjust"
                                            # (no output — SETT-03/PLAY-09 dep audit clean)
```

## Phase requirements satisfied

- **SETT-03** (no data leaves device — dep tree audit): ✓ confirmed via grep against the regex authored in plan §6 step 6. Zero matches.

(Other phase REQ-IDs land in Plans 01-02 / 01-03 / 01-04 / 01-05.)

## Files of record

| File | State |
|------|-------|
| `pubspec.yaml` | Replaced with Phase-1 pinned deps (sorted alphabetically) |
| `pubspec.lock` | New |
| `analysis_options.yaml` | Replaced with `very_good_analysis 10.2` extend |
| `android/app/build.gradle.kts` | `compileSdk=36`, `minSdk=29`, `targetSdk=36` locked |
| `lib/main.dart` | `_PlaceholderApp` stub |
| `.gitignore` | Appended Pigeon helper + IDE-local lines |
| `~/.zshrc` | Appended JAVA_HOME, flutter, ANDROID_HOME exports (backup at `~/.zshrc.bak`) |

## Notes for downstream plans

- **01-04 (Pigeon stubs + BlockedAppDetector):** RESEARCH §6's hand-written provider pattern is now the canonical Phase-1 approach (no `@riverpod` annotation). The `BlockedAppDetector` interface, two stub implementations, and the Riverpod selector should use plain `Provider`/`StateProvider` — no codegen.
- **01-03 (Drift schema):** drift 2.33.0 is API-compatible with the 2.32.1 schema patterns documented in RESEARCH §2. No changes needed.
- **02 (next phase):** when ecosystem stabilizes on analyzer 12+, reintroduce `riverpod_annotation`, `riverpod_generator`, `custom_lint`, `riverpod_lint` in a single pubspec edit. Watch `meta` package's Flutter SDK pin.

---

*Plan 01-01 complete. Wave 1 plans (01-02, 01-03, 01-04) are unblocked.*
