---
phase: 04
slug: 04-pause-ux-the-wedge
status: verified
threats_open: 0
asvs_level: 2
created: 2026-05-15
---

# Phase 04 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Test source ↔ production source | Wave 0 adds nothing under `lib/` or `android/app/src/main/`. PLAY-02 invariants unaffected. | None |
| Pigeon channel (Dart → Kotlin AccessibilityApi) | Typed via generated `AccessibilityApi.g.kt`. Read-only state check + fire-and-forget Settings deep-link. | Boolean service state |
| Pigeon channel (Dart → Kotlin BlocklistBroadcastApi) | Typed `publishBlockList(List<BlockListEntrySnapshot>)`. Fire-and-forget. | entryId, packageName, blockMode, schedule fields (no reasonNote/PII) |
| Kotlin → LocalBroadcast bus | `Intent.setPackage(context.packageName)` + LocalBroadcastManager (in-process only). No exported manifest receiver. | JSON snapshot string (in-process) |
| AccessibilityService event thread → blockMap read | Single read of `@Volatile` Map reference. Safe by JVM memory model. | Package name lookup |
| BlockListReceiver → blockMap write | Single `@Volatile` assignment — publish happens-before next event-thread read. | Parsed snapshot entries |
| Service event thread → PauseActivity Intent | startActivity from AccessibilityService (exempt from Android 10 background-launch restriction). Explicit component `PauseActivity::class.java`. | 4 lowercase_snake extras (no reasonNote) |
| PauseActivity → FlutterEngineCache | Cache key `"pause_engine"`. Fallback to super on cache miss. | Engine reference |
| GoRouter /pause/:entryId | Path param entryId + 3 query params. CR-01 fail-closed default `'hard'` for missing/unrecognised mode. | entryId, packageName, blockMode, triggeredAt |
| PauseScreen → BlockListRepository.getById | Async read of BlockList row for reasonNote + displayName. | User-defined app/reason content (displayed on screen, not logged) |
| PauseController → PauseEventRepository.insertOutcome | Single-writer seam (D-13). outcome asserted 0/1/2. | outcome, cooldownChosenSeconds, entryId, packageName, triggeredAt |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-4-01 | Compliance | Wave 0 test sources | accept | Wave 0 adds nothing to `android/.../main/kotlin/` or `lib/` — only `test/` and `.planning/`. PLAY-02 scans `lib/` and `android/.../platform/` which are unaffected. | closed |
| T-4-T05 (01) | PLAY-02 | Wave 0 test sources | accept | PLAY-02 scans `lib/`, not `test/`. Stub files reference forbidden token names in prose skip-reason strings, never as code literals. | closed |
| T-4-02 | Information disclosure | 04-VERIFICATION.md | accept | Planning artifact, not shipped with APK. No PII beyond solo-developer device record. | closed |
| T-4-02-01 | Tampering | Kotlin port semantics drift (D-12) | mitigate | Parity oracle on both sides (201 Dart tuples + 200 Kotlin assertEquals). `flutter test` + `./gradlew :app:test` catches drift. Evidence: `ScheduleWindow.kt:25` `fun isInScheduleWindow(` + 201-tuple `schedule_window_parity_test.dart`. | closed |
| T-4-02-02 | DoS/Performance | Schedule check on event hot path | accept | O(1) function — two Calendar lookups + bit ops. No optimization needed at 800ms-debounced event rate. | closed |
| T-4-T05 (02) | PLAY-02 | ScheduleWindow.kt + ScheduleWindowTest.kt | mitigate | Non-comment-line grep returns 0 matches for `performAction(`/`performGlobalAction(`/`dispatchGesture(`. Plan 04-08 9th invariant covers `android/.../service/` scope. | closed |
| T-4-02-03 | Information disclosure | DST timezone in tests | accept | `America/Los_Angeles` is a public IANA tz identifier. Test data uses fixed epoch literals — no real device state. | closed |
| T-4-03-01 | Spoofing | AccessibilityManager service match | mitigate | FQCN exact-match: `"${context.packageName}/com.nottodo.not_to_do_list.service.NotToDoAccessibilityService"` verified at `AccessibilityApiImpl.kt:34`. No partial substring match. | closed |
| T-4-03-02 | Information disclosure | openAccessibilitySettings Intent | mitigate | `Settings.ACTION_ACCESSIBILITY_SETTINGS` + `FLAG_ACTIVITY_NEW_TASK` + `resolveActivity` guard (T-2-02 pattern preserved). No extras, no data URI. Verified in `AccessibilityApiImpl.kt`. | closed |
| T-4-T05 (03) | PLAY-02 | AccessibilityApiImpl.kt + MainActivity.kt | mitigate | Non-comment-line grep returns 0 matches. Phase 2 `play_invariants_test.dart` PLAY-02 test covers `android/.../platform/` — both files in scope. 8/8 (now 9/9) invariants green. | closed |
| T-4-03-03 | Resource leak/DoS | FlutterEngineCache pre-warm | mitigate | `if (FlutterEngineCache.getInstance().get("pause_engine") == null)` null-guard prevents engine duplication on activity restarts. Verified at `MainActivity.kt:27`. | closed |
| T-4-03-04 | Privacy | Pre-warmed engine running main.dart | accept | Pre-warmed engine boots same Dart code as main app. Never renders UI, never calls Pigeon APIs until PauseActivity binds. No background data access; no telemetry. | closed |
| T-4-04-01 | Spoofing/Privilege escalation | ACTION_BLOCKLIST_UPDATED LocalBroadcast | mitigate | (a) Qualified package-prefixed action string `"com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED"` at `BlocklistBroadcastApiImpl.kt:33-34`. (b) `Intent.setPackage(context.packageName)` at `BlocklistBroadcastApiImpl.kt:54`. (c) LocalBroadcastManager in-process by design. (d) No `<receiver>` in manifest. External injection impossible. | closed |
| T-4-04-02 | Information disclosure | Block list snapshot in broadcast | accept | Snapshot carries entryId, packageName, blockMode, schedule fields only. No reasonNote (confirmed: `_publishCurrent()` mapping at `block_list_repository.dart:128-135` excludes reasonNote). Broadcast is in-process. | closed |
| T-4-04-03 | Tampering | JSON-encoded snapshot | mitigate | Pigeon Kotlin DTO is typed (`data class BlockListEntrySnapshot`). JSON serialization is internal to `BlocklistBroadcastApiImpl`. Only producer is the impl itself — no third-party craft path. | closed |
| T-4-T05 (04) | PLAY-02 | BlocklistBroadcastApiImpl.kt + new Dart files | mitigate | Non-comment-line grep on `BlocklistBroadcastApiImpl.kt` returns 0 matches. Phase 2 Dart-side absence-grep scans `lib/` — all new `lib/` files pass 8/8 (9/9 after Phase 4) invariants. | closed |
| T-4-04-04 | Resource leak | Nullable broadcaster in BlockListRepository | accept | `BlocklistBroadcastApi? broadcaster` nullable for test ergonomics. Production provider always passes non-null. `?.publishBlockList` is a no-op when null, never throws. | closed |
| T-4-05-01 | Spoofing | ACTION_BLOCKLIST_UPDATED receiver | mitigate | LocalBroadcastManager is in-process by design. No manifest `<receiver>`. Combined with Plan 04-04 `setPackage` narrowing, external injection impossible. Service `BlockListReceiver` registered via LocalBroadcastManager only. | closed |
| T-4-05-02 | Tampering | Intent extras to PauseActivity | mitigate | PauseActivity validates all 4 extras; missing/invalid → `finish()` without engine bind or pause_events write (T-02 fail-closed). Verified at `PauseActivity.kt:43-55`. | closed |
| T-4-05-03 | Spoofing | PauseActivity external launch | mitigate | `android:exported="false"` at manifest line 85 (confirmed: `grep android:exported` returns `"false"` at line 85 for PauseActivity). Service uses explicit component `Intent(this, PauseActivity::class.java)` at `NotToDoAccessibilityService.kt:92`. | closed |
| T-4-05-04 | Privacy | reasonNote in logs | mitigate | Service contains ONE `Log.d(TAG, "service connected")` — static string only. No packageName, event data, or snapshot JSON logged. Pattern 1: service never reads SQLite. Snapshot DTO excludes reasonNote (T-4-04-02 evidence). | closed |
| T-4-05-05 | PLAY-02 | NotToDoAccessibilityService.kt | mitigate | Non-comment-line grep on service file returns 0 matches for `performAction(`/`performGlobalAction(`/`dispatchGesture(`. 9th PLAY-02 invariant (`play_invariants_test.dart:74`) covers `android/.../service/`. | closed |
| T-4-05-06 | DoS/Performance | 800ms debounce flood | mitigate | `DEBOUNCE_MS = 800L` per-package debounce at `NotToDoAccessibilityService.kt:39,77`. Research-anchored optimum. TYPE_WINDOW_STATE_CHANGED rapid re-fires dropped. | closed |
| T-4-05-07 | DoS/Crash | Malformed broadcast snapshot | mitigate | `BlockListReceiver.onReceive` wraps JSON parsing in `try/catch`. Malformed snapshot retains previous `blockMap` (fail-safe). Service does not crash; does not log snapshot (T-04). | closed |
| T-4-05-08 | Information disclosure | Pre-warmed engine + service same process | accept | Both run in same app process — no IPC boundary. `blockMap` is native-heap Kotlin; engine cannot read it without Pigeon (by design, Pattern 1). | closed |
| T-4-05-09 | REL-01/CD-01 | No companion FGS | accept | CD-01: ship without FGS. Manifest FGS perms declared-but-unused. `startForeground`/`NotificationCompat.Builder`/`FOREGROUND_SERVICE` absent from service file (non-comment lines grep = 0). Escalation rule documented in `04-VERIFICATION.md`. | closed |
| T-4-06-01 | Tampering/Spoofing | Intent extras in PauseActivity | mitigate | Fail-closed: `if (entryId == -1L || blockedPackage.isEmpty() || (blockMode != "soft" && blockMode != "hard") || triggeredAtMs <= 0L)` → `super.onCreate + finish() + return` at `PauseActivity.kt:43-55`. All 4 extras validated. No engine bind. No DB write. | closed |
| T-4-06-02 | Spoofing | External launch of PauseActivity | mitigate | `android:exported="false"` verified: `grep android:exported` returns `"false"` at manifest line 85 for PauseActivity entry. Plan 04-06 verified via `awk` — unchanged from Phase 1. | closed |
| T-4-06-03 | DoS/Resource leak | Cached engine reuse | mitigate | Engine owned by `FlutterEngineCache`, NOT by PauseActivity. `PauseActivity.finish()` does NOT destroy engine. `singleInstance` manifest flag ensures at most one PauseActivity exists at a time. | closed |
| T-4-06-04 | Information disclosure | reasonNote on lock screen | accept | Intended UX — PAUS-08 renders over lock screen. Mitigations: manifest `excludeFromRecents` prevents Recents preview leak; reasonNote never logged. User opted-in knowing this via Accessibility Service consent. | closed |
| T-4-T05 (06) | PLAY-02 | PauseActivity.kt | mitigate | Non-comment-line grep returns 0 matches. 9th PLAY-02 invariant covers root `android/.../not_to_do_list/` directory (includes `PauseActivity.kt`). | closed |
| T-4-06-05 | DoS/Crash | Engine cache miss | accept | Falls back to `super.provideFlutterEngine` — fresh engine. Functionally correct, slower cold-start (~700-900ms vs <300ms). Plan 04-08 measures and documents. Rare path: service only enabled after MainActivity has run. | closed |
| T-4-07-01 | Tampering | entryId from query string | mitigate | `blockListEntryProvider(entryId)` looks up live BlockList row. If null (deleted between Intent build and mount), `AsyncValue.when` error/null path calls `SystemNavigator.pop()` without writing pause_events. Fail-closed. | closed |
| T-4-07-02 | Privacy | reasonNote on lock screen (Dart side) | accept | Intended UX (same as T-4-06-04). `excludeFromRecents` prevents Recents leak. No `Log.d`/`print` of reasonNote in PauseController (code review: no logging calls). | closed |
| T-4-07-03 | Tampering | outcome value | mitigate | `assert(outcome >= 0 && outcome <= 2, ...)` in `pause_event_repository.dart:22`. PauseController passes hardcoded 0/1/2. Double layer: UI + controller assert. | closed |
| T-4-07-04 | DoS/Resource leak | Timer.periodic in PauseController | mitigate | `AutoDispose` cancels on provider dispose (PauseScreen unmount). Manual cancel in `cancel()`/`useAnyway()`/cooldown-completion paths as belt-and-suspenders. | closed |
| T-4-07-05 | Logic/UX bypass | Use anyway on hard entries (PAUS-09) | mitigate | `if (blockMode == 'soft') ...<Widget>[TextButton(...)]` at `pause_screen.dart:131` OMITS Use anyway from widget tree entirely (not just hidden). PauseController.useAnyway also asserts `blockMode=='soft'` as backstop. Two layers. | closed |
| T-4-07-06 | UX policy | Use anyway timing (CD-02) | accept | CD-02 variant (a): Use anyway enabled immediately on screen load. Hard entries omit it entirely. Escalation rule documented if user testing reveals bypass collapse. | closed |
| T-4-T05 (07) | PLAY-02 | All new Dart sources under lib/ | mitigate | Phase 2 Dart-side absence-grep scans `lib/`. All `lib/features/pause/` and `lib/data/repositories/pause_event_repository.dart` files pass 9/9 invariants. | closed |
| T-4-07-07 | Drift codegen drift | app_database.g.dart regen | accept | Drift codegen runs only for `app_database.g.dart` + new `pause_event_dao.g.dart`. Pigeon files NOT regenerated (Pitfall #9 preserved). Normal per Phase 2/3 precedent. | closed |
| T-4-08-01 | Logic/UX bypass | Onboarding redirect on /pause/:entryId | accept | Main app redirect to `/onboarding/welcome` is correct pre-onboarding. PauseActivity's engine bypasses redirect via `getInitialRoute` setting `/pause/:entryId` directly. Intentional. | closed |
| T-4-08-02 | PLAY-02 | Phase 4 expanded scope (service/ + root) | mitigate | 9th invariant added at `play_invariants_test.dart:74-112`. Covers `android/.../service/` + root `android/.../not_to_do_list/` Kotlin files. Verified: `grep -F 'Phase 4 expanded scope' play_invariants_test.dart` returns match. | closed |
| T-4-08-03 | UAT bypass | Silent emulator substitution for REL-04 | mitigate | Task 04-08-03 is `checkpoint:human-action` per CD-03. No automatic substitution path. User confirmed Samsung device (Option A). Protocol documented in `04-VERIFICATION.md`. | closed |
| T-4-08-04 | Information disclosure | Manual UAT logs | accept | `adb logcat -e PauseActivity` surfaces system "Displayed" timing line. No PII. Cold-start metric is system data, not user data. | closed |
| T-4-08-05 | Compliance | REL-01 deferral | accept | CD-01: ship without FGS. Deferral documented in `04-VERIFICATION.md` + `REQUIREMENTS.md` (REL-01 row). Escalation rule: revisit if REL-04 OEM gate fails on additional OEMs. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-04-01 | T-4-01, T-4-T05(01) | Wave 0 test files cannot introduce autonomous-action or PII risks — PLAY-02 scans `lib/` not `test/`. Planning artifacts are not shipped in APK. | solo developer (per CLAUDE.md project constraints) | 2026-05-15 |
| AR-04-02 | T-4-02 | 04-VERIFICATION.md is a planning artifact not shipped in APK. Solo developer records their own device data for their own records. | solo developer | 2026-05-15 |
| AR-04-03 | T-4-02-02 | Schedule gate is O(1) pure arithmetic — no I/O, no DB. Cost at 800ms debounce rate is microseconds. No optimization warranted. | solo developer | 2026-05-15 |
| AR-04-04 | T-4-02-03 | `America/Los_Angeles` is a public IANA TZ identifier. Fixed epoch literals in tests — no real device state. No PII. | solo developer | 2026-05-15 |
| AR-04-05 | T-4-03-04 | Pre-warmed engine boots same Dart code as main app. Never renders UI or calls platform APIs until PauseActivity binds. No background data access. PROJECT.md non-telemetry stance preserved. | solo developer | 2026-05-15 |
| AR-04-06 | T-4-04-02 | Broadcast snapshot intentionally excludes reasonNote (T-04 mitigation). Remaining fields (entryId, packageName, blockMode, schedule) are user-set data the user owns. Broadcast never leaves the app process. | solo developer | 2026-05-15 |
| AR-04-07 | T-4-04-04 | Nullable broadcaster is test ergonomics only. Production `blockListRepProvider` always passes non-null broadcaster. `?.publishBlockList` is a documented no-op guard (not a silent failure path). | solo developer | 2026-05-15 |
| AR-04-08 | T-4-05-08 | Both pre-warmed engine and service run in same app process. No IPC boundary to cross. `blockMap` is native-heap Kotlin; the Flutter engine cannot read it without going through Pigeon — Pattern 1 preserved. | solo developer | 2026-05-15 |
| AR-04-09 | T-4-05-09 | REL-01/CD-01: Phase 4 ships WITHOUT companion FGS. Manifest FGS perms declared-but-unused. Escalation rule: only add FGS if Plan 04-08's REL-04 overnight gate fails. Documented in `04-VERIFICATION.md` under `## REL-01 Disposition (CD-01)`. | solo developer | 2026-05-15 |
| AR-04-10 | T-4-06-04, T-4-07-02 | reasonNote visible on lock screen is the intended UX — the wedge is most powerful at the impulse moment before unlock. User explicitly opted into AccessibilityService knowing this. manifest `excludeFromRecents` prevents Recents leak. No logging of reasonNote. | solo developer | 2026-05-15 |
| AR-04-11 | T-4-06-05 | Engine cache miss falls back to `super.provideFlutterEngine` (fresh engine, ~700-900ms). Rare in practice — service only enabled after at least one MainActivity run. Plan 04-08 measures and documents cold-start in `04-VERIFICATION.md`. | solo developer | 2026-05-15 |
| AR-04-12 | T-4-07-06 | CD-02 variant (a): Use anyway enabled immediately (no after-cooldown gate). Hard entries omit it entirely (PAUS-09 mitigated). Escalation documented: if user testing shows immediate bypass collapses the wedge, escalate per CD-02 rule. | solo developer | 2026-05-15 |
| AR-04-13 | T-4-07-07 | Drift codegen is expected and normal for Drift schema changes. Only `app_database.g.dart` + new `pause_event_dao.g.dart` regenerated. Pigeon files untouched (Pitfall #9 preserved per Phase 2/3 precedent). | solo developer | 2026-05-15 |
| AR-04-14 | T-4-08-01 | Onboarding redirect on `/pause/:entryId` is correct behavior — PauseScreen should not be reachable before onboarding. PauseActivity's bound engine bypasses this via `getInitialRoute` override (intentional). | solo developer | 2026-05-15 |
| AR-04-15 | T-4-08-04 | Manual UAT log (`adb logcat -e PauseActivity`) surfaces Android system "Displayed" timing line. No PII. Cold-start reading is a system performance metric. | solo developer | 2026-05-15 |
| AR-04-16 | T-4-08-05 | REL-01 deferral per CD-01 is a deliberate v1 scope decision. FGS would add a Play Store permission declaration. Revisit only if REL-04 OEM gate fails on additional OEMs. Fully documented in `REQUIREMENTS.md` + `04-VERIFICATION.md`. | solo developer | 2026-05-15 |
| AR-04-17 | REL-04 (T-4-08-03) | REL-04 overnight OEM-survival gate is `pending_overnight_run` as of 2026-05-13. User confirmed Samsung device available; test protocol documented in `04-VERIFICATION.md`. Software gate is green. Phase 5 proceeds in parallel per the phase plan. | solo developer | 2026-05-15 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-15 | 46 | 46 | 0 | gsd-security-auditor (claude-sonnet-4-6) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-15
