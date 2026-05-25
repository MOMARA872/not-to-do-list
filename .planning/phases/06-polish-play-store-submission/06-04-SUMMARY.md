---
phase: 06-polish-play-store-submission
plan: "04"
subsystem: settings
tags: [flutter, dart, drift, riverpod, archive, zip, csv, export, saft, flutter_file_dialog, package_info_plus]

requires:
  - phase: 06-01
    provides: Wave 0 test stubs + getAll() DAO methods on all 5 DAOs
  - phase: 06-03
    provides: ExportScreen placeholder at lib/features/settings/pages/export_screen.dart

provides:
  - "FileSavePort abstract interface + FlutterFileDialogSavePort impl (SAF plugin port)"
  - "fileSavePortProvider Riverpod binding for FileSavePort"
  - "MockFileSavePort fixture activated for widget tests (replaces Wave 0 placeholder)"
  - "ExportController: parallel DAO reads, 5 CSVs + data.json envelope, ZIP archive via archive package"
  - "ExportScreen ConsumerWidget with Export action tile + SnackBar success/cancel/error handling"

affects:
  - 06-05 (can use MockFileSavePort via same fixture)
  - 06-06 (export flow complete; Settings hub now has real Export tile destination)

tech-stack:
  added:
    - "archive: ^4.0.9 (ZipEncoder/ZipDecoder)"
    - "flutter_file_dialog: ^3.0.3 (SAF SaveFileDialogParams)"
    - "package_info_plus: ^10.1.0 (PackageInfo.fromPlatform)"
    - "intl: ^0.20.2 (DateFormat yyyyMMdd-HHmm)"
  patterns:
    - "Pigeon-port abstraction for SAF plugin (FileSavePort interface + FlutterFileDialogSavePort impl)"
    - "ValueSerializer-aware CSV format with hard-coded per-table column lists for stable header rows"
    - "UTC timestamp conversion: Drift ms-epoch → ISO-8601 UTC via _convertRowTimestamps helper"
    - "PackageInfo.setMockInitialValues() for widget test stubbing of platform channel"

key-files:
  created:
    - "lib/features/settings/services/file_save_port.dart"
    - "lib/domain/providers/file_save_port_provider.dart"
    - "lib/features/settings/services/export_controller.dart"
    - "test/features/settings/file_save_port_test.dart"
    - "test/features/settings/export_controller_test.dart"
    - "test/features/settings/export_csv_format_test.dart"
    - "test/features/settings/export_json_envelope_test.dart"
  modified:
    - "lib/features/settings/pages/export_screen.dart (replaced 06-03 placeholder)"
    - "test/_fixtures/file_save_port_mock.dart (activated from Wave 0 placeholder)"
    - "test/features/settings/export_screen_test.dart (unskipped from Wave 0 RED stub)"

key-decisions:
  - "FileSavePort uses 3-arg save(bytes, fileName, mimeTypes) matching the plan interface — not a 2-arg saveZip variant from RESEARCH sketch"
  - "DateTime ISO-8601 UTC in CSV output via _convertRowTimestamps (ms-epoch to UTC ISO) instead of ValueSerializer.defaults because Drift stores DateTime as local DateTimes that toIso8601String() without Z"
  - "ExportController uses ConsumerWidget (not ConsumerStatefulWidget) for ExportScreen per Settings pattern; context.mounted guard via if (!context.mounted) return"
  - "PackageInfo.setMockInitialValues() preferred over a dedicated Riverpod provider for PackageInfo to keep ExportScreen interface minimal"
  - "FakeUint8List for mocktail fallback value replaced with Uint8List(0) after discovering Uint8List is a final class that cannot be implemented outside its library"

requirements-completed: [SETT-01]

duration: 30min
completed: 2026-05-25
---

# Phase 6 Plan 04: Export Data (SETT-01) Summary

**FileSavePort Pigeon-port abstraction + ExportController building ZIP(5 CSVs + data.json) via archive package + ExportScreen ConsumerWidget with SAF cancel/error SnackBar flow**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-05-25T03:07:14Z
- **Completed:** 2026-05-25T03:37:14Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- FileSavePort abstract interface + FlutterFileDialogSavePort impl wrap the `flutter_file_dialog` SAF plugin for testability; `fileSavePortProvider` mirrors notificationApiProvider Pigeon-port shape
- ExportController reads all 5 Drift DAOs in parallel via `Future.wait`, builds RFC 4180 + CSV-injection-safe CSVs with verbatim column names, wraps in data.json envelope `{schemaVersion:1, exportedAt(UTC ISO-8601), appVersion, tables}`, encodes ZIP via archive package
- ExportScreen replaces 06-03 CircularProgressIndicator placeholder; handles cancel (silent), success ('Export saved'), and error ('Export failed. Check available storage and try again.') per Pitfall 3; `context.mounted` guard after every `await`
- 22 total new tests across 5 test files — all passing, no skipped SETT-01 tests

## Task Commits

1. **Task 1: FileSavePort + provider + fixture activation** - `a753ce9` (feat)
2. **Task 2: ExportController ZIP + CSV + JSON envelope** - `677fd72` (feat)
3. **Task 3: ExportScreen widget** - `547be57` (feat)

## Files Created/Modified

- `lib/features/settings/services/file_save_port.dart` — abstract FileSavePort + FlutterFileDialogSavePort impl
- `lib/domain/providers/file_save_port_provider.dart` — Riverpod Provider<FileSavePort>
- `lib/features/settings/services/export_controller.dart` — ExportController with parallel DAO reads, CSV/ZIP/JSON build
- `lib/features/settings/pages/export_screen.dart` — Real ExportScreen replacing 06-03 placeholder
- `test/_fixtures/file_save_port_mock.dart` — Activated MockFileSavePort (replaces Wave 0 placeholder abstract class)
- `test/features/settings/file_save_port_test.dart` — 4 tests: delegate, null-cancel, rethrow, Riverpod override
- `test/features/settings/export_controller_test.dart` — 5 tests: ZIP contents, filename regex, schemaVersion, exportedAt UTC, passthrough return
- `test/features/settings/export_csv_format_test.dart` — 3 tests: header row verbatim, RFC 4180 quote wrapping, CSV-injection prefix
- `test/features/settings/export_json_envelope_test.dart` — 5 tests: envelope keys, table keys, appVersion format, exportedAt UTC, ISO-8601 in table rows
- `test/features/settings/export_screen_test.dart` — 5 widget tests: render, success SnackBar, cancel silent, error SnackBar, mounted guard

## Decisions Made

- Used `Uint8List(0)` as mocktail fallback value instead of a `FakeUint8List extends Fake implements Uint8List` — `Uint8List` is a `final` class that cannot be implemented outside `dart:typed_data`
- `_convertRowTimestamps` helper for the JSON envelope rather than `ValueSerializer.defaults(serializeDateTimeValuesAsString: true)`: Drift stores DateTimes in local timezone; `toIso8601String()` doesn't append `Z` on local times, so we convert via `fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String()` to get proper UTC ISO-8601 with Z suffix

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Uint8List cannot be used as Fake for mocktail fallback**
- **Found during:** Task 1 (file_save_port_mock.dart activation)
- **Issue:** `class FakeUint8List extends Fake implements Uint8List` failed to compile — Uint8List is a `final` class restricted from external implementation
- **Fix:** Replaced `FakeUint8List()` fallback with `Uint8List(0)` directly in `registerFallbackValue`
- **Files modified:** `test/_fixtures/file_save_port_mock.dart`
- **Committed in:** a753ce9

**2. [Rule 1 - Bug] Drift ISO-8601 DateTime without UTC Z suffix**
- **Found during:** Task 2 (export_json_envelope_test.dart — exportedAt ISO-8601 UTC ending in Z)
- **Issue:** `ValueSerializer.defaults(serializeDateTimeValuesAsString: true)` calls `DateTime.toIso8601String()` on Drift's locally-stored DateTime objects, producing `2026-05-24T05:00:00.000` (no Z); test requires UTC string ending in Z
- **Fix:** Added `_convertRowTimestamps(Map<String,dynamic> row)` helper that converts DateTime columns (ms-epoch int) via `DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String()`, which always produces a Z-suffix UTC string
- **Files modified:** `lib/features/settings/services/export_controller.dart`
- **Committed in:** 677fd72

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both auto-fixes necessary for correctness. No scope creep.

## Known Stubs

None — ExportScreen is fully wired; ExportController reads live Drift data; FileSavePort delegates to real SAF plugin in production.

## Threat Flags

None — export flow uses SAF (user-owned destination); no world-readable location fallback. CSV injection mitigation applied per Security Domain V5.

## Self-Check: PASSED

Files exist:
- `lib/features/settings/services/file_save_port.dart` — FOUND
- `lib/domain/providers/file_save_port_provider.dart` — FOUND
- `lib/features/settings/services/export_controller.dart` — FOUND
- `lib/features/settings/pages/export_screen.dart` — FOUND
- `test/_fixtures/file_save_port_mock.dart` — FOUND

Commits exist:
- `a753ce9` — feat(06-04): FileSavePort port abstraction + Riverpod provider + mock fixture — FOUND
- `677fd72` — feat(06-04): ExportController ZIP build with CSV + JSON envelope (SETT-01) — FOUND
- `547be57` — feat(06-04): ExportScreen wired with SAF cancel/error SnackBar feedback — FOUND

---
*Phase: 06-polish-play-store-submission*
*Completed: 2026-05-25*
