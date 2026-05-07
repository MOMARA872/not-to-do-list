# Phase 2 Deferred Items

Out-of-scope discoveries logged during plan execution. Each item references
the plan it surfaced under. Resolve in a follow-up plan or polish pass.

## Style/lint infos in already-shipped Plan 02-03 outputs

**Discovered during:** Plan 02-05 execution (final `dart analyze`).
**Owner:** Plan 02-03 (frozen).
**Action:** None — these are pre-existing very_good_analysis infos in files
this plan does not own. Per CLAUDE.md surgical-changes rule, leaving them
for the plan owner.

- `pigeons/app_picker_api.dart` lines 40-54: 5x `lines_longer_than_80_chars`
  in doc comments + 1x `unintended_html_in_doc_comment` (`<queries>`).
- `pigeons/permission_status_api.dart` line 18: 1x `lines_longer_than_80_chars`.
- `test/_fixtures/permission_status_mock.dart` lines 8-25: 11x infos
  (`lines_longer_than_80_chars` and `unnecessary_lambdas`). The
  `unnecessary_lambdas` lint misfires on the canonical mocktail
  `when(() => mock.method())` idiom — the file would benefit from a
  file-level `// ignore_for_file: unnecessary_lambdas` (already applied to
  `test/features/health/permission_health_provider_test.dart` in this plan).
