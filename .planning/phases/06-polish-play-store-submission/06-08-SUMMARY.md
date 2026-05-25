---
phase: "06-polish-play-store-submission"
plan: "08"
subsystem: "play-store-submission-assets + verification-protocol"
paused_at: "task_3a"
status: "partial — blocked at Task 3a OEM overnight gate"
tags: ["wave-5", "play-listing", "privacy-policy", "verification", "OEM-gate", "SETT-05", "PLAY-07", "PLAY-08"]
dependency_graph:
  requires:
    - "06-07 (PLAY-09 telemetry invariants + version bump)"
  provides:
    - "docs/PRIVACY.md final copy (replaces 06-01 stub)"
    - "docs/play-listing/ full asset tree"
    - "06-VERIFICATION.md OEM protocol + Play submission runbook"
    - "assets/onboarding/README.md with 8 placeholder PNG list"
    - "evidence/ directory for OEM gate artifacts"
  affects:
    - "Task 3a: OEM overnight gate (Samsung + Xiaomi) — BLOCKING"
    - "Task 3b: Play Console submission + closed-track verdict — BLOCKING"
    - "Task 4: Phase bookkeeping (depends on Task 3b PASS)"
tech_stack:
  added: []
  patterns:
    - "GitHub Pages /docs folder for Privacy Policy hosting"
    - "Play Console closed-track submission runbook"
key_files:
  created:
    - "docs/play-listing/short-description.txt"
    - "docs/play-listing/full-description.txt"
    - "docs/play-listing/permission-declaration.md"
    - "docs/play-listing/screenshots/README.md"
    - "docs/play-listing/README.md"
    - ".planning/phases/06-polish-play-store-submission/06-VERIFICATION.md"
    - ".planning/phases/06-polish-play-store-submission/evidence/.gitkeep"
    - ".planning/phases/06-polish-play-store-submission/CHECKPOINT-task3a.md"
  modified:
    - "docs/PRIVACY.md (replaced 06-01 stub with final privacy policy)"
    - "assets/onboarding/README.md (added all 8 placeholder PNG replacement notes)"
decisions:
  - "docs/PRIVACY.md structure follows calm-tone register from Phase 4 D-07 lock — no external links (RESEARCH Pitfall 6)"
  - "short-description.txt is 67 bytes (within 80 char Play Store limit)"
  - "full-description.txt is 2741 bytes (within 4000 char Play Store limit)"
  - "permission-declaration.md verbatim mirrors docs/play-declaration.md secs 1-4 per RESEARCH Pitfall 1"
  - "06-VERIFICATION.md has two BLOCKING gate tokens: PHASE-6 OEM PASS (Task 3a) and PLAY-08 CLOSED TRACK PASS (Task 3b)"
  - "Evidence directory created at .planning/phases/06-polish-play-store-submission/evidence/ mirroring Phase 4 REL-04 and Phase 5 REL-05 patterns"
metrics:
  duration: "~25 min (Tasks 1 + 2 only; Tasks 3a/3b/4 pending)"
  completed_date: "2026-05-24"
  tasks_completed: 2
  tasks_total: 4
  files_created: 7
  files_modified: 2
---

# Phase 6 Plan 8: Play Store Submission Assets + Verification Protocol — PARTIAL SUMMARY

**One-liner:** Final Privacy Policy + Play Console listing assets + 9-step OEM overnight protocol + Play submission runbook; paused at Task 3a OEM blocking gate.

**Status:** PAUSED — waiting for OEM overnight gate (Task 3a) before Play Console submission (Task 3b) and bookkeeping (Task 4).

---

## Tasks Completed

### Task 1: Final docs/PRIVACY.md + docs/play-listing/ asset tree (commit: 9a5bf7b)

Replaced the 06-01 stub in `docs/PRIVACY.md` with the full privacy policy:
- Calm-tone register (Phase 4 D-07 lock honored)
- Sections: What we collect / What we do not do / Local data storage / Deleting your data / Permissions / Contact
- Contains literal phrase "zero data" (required for privacy_policy_url_present_test.dart grep)
- No external links (RESEARCH Pitfall 6 — avoids link-tap-not-handled Play rejection)
- 84 lines (exceeds the 30-line minimum)

Created `docs/play-listing/` directory tree:
- `short-description.txt`: 67 bytes (limit: 80) — "Mindful pause-screen helper for apps and habits you want to not do."
- `full-description.txt`: 2741 bytes (limit: 4000) — calm-tone narrative, no gamification language, no deferred features (no parent PIN, kid mode, content filter per PROJECT.md)
- `permission-declaration.md`: verbatim copy of play-declaration.md sections 1–4 reshaped for Play Console form fields; demo video URL placeholder in section 4
- `screenshots/README.md`: capture checklist for 2 phone screenshots (1080x1920+) + 1 feature graphic (1024x500)
- `README.md`: Play Console field-to-file map + GitHub Pages enablement note

Updated `assets/onboarding/README.md`:
- Added a section listing all 8 placeholder PNGs needing replacement (3 in assets/onboarding/, 5 in assets/logos/)
- References STATE.md deferred items 2026-05-22

Verification: `flutter test test/policy/privacy_policy_url_present_test.dart` — 2/2 passing.

### Task 2: 06-VERIFICATION.md (commit: 4956982)

Created `.planning/phases/06-polish-play-store-submission/06-VERIFICATION.md`:
- Frontmatter: status=pending_overnight_run, rel_06_status=pending, play_08_status=pending_closed_track_review
- Section 1: software completion table for all 8 Phase 6 plans
- Section 2: Phase 5 D-08 soft-lock closure note (shipped via 06-03 inline Streak section)
- Section 3: 9-step OEM-survival overnight protocol with SAMSUNG OEM PASS + XIAOMI OEM PASS + PHASE-6 OEM PASS gate tokens
- Section 4: Play Console submission runbook (GitHub Pages, demo video recording, Internal track, Closed track, PLAY-08 CLOSED TRACK PASS gate token)
- Section 5: Play Console form fill checklists (Permission Declaration, Data Safety, Store listing, Closed testing)
- Section 6: pre-submission shell command block
- Section 7: phase-exit bookkeeping checklist (gated on both manual gates)
- Section 8: sign-off checklist

Created `evidence/` directory with `.gitkeep` for OEM gate run artifacts.

---

## Tasks Pending (blocked)

### Task 3a: BLOCKING — OEM overnight gate (Samsung + Xiaomi)

Requires real devices. The user must:
1. Run pre-flight: flutter clean && flutter test + flutter test test/policy/ + flutter build apk --release + apk_telemetry_strings_test
2. Run the 9-step protocol on a real Samsung Galaxy S20 Ultra (or OneUI 5+)
3. Run the 9-step protocol on a real Xiaomi device
4. Save evidence to `evidence/samsung-YYYY-MM-DD/` and `evidence/xiaomi-YYYY-MM-DD/`
5. Type `PHASE-6 OEM PASS` when both gates pass

See `CHECKPOINT-task3a.md` for the full gate instructions.

### Task 3b: BLOCKING — Play Console submission + closed-track verdict (depends on Task 3a)

After Task 3a PASS:
- Enable GitHub Pages (/docs folder); verify Privacy URL returns HTTP/2 200
- Record 30–60 sec demo video; upload to YouTube unlisted; paste URL in permission-declaration.md + Play Console form
- Build .aab; upload to Internal testing track; install on developer device
- Promote to Closed testing; add 5–20 named testers; submit for review
- Wait 1–7 business days for verdict
- Type `PLAY-08 CLOSED TRACK PASS` on PASS

### Task 4: Final bookkeeping (depends on Task 3b PASS)

REQUIREMENTS.md, ROADMAP.md, STATE.md, 06-VERIFICATION.md flips.
All gated on Task 3b PASS — do not run until Play Console closed-track verdict is PASS.

---

## Deviations from Plan

None — plans executed exactly as written for the autonomous portion (Tasks 1 + 2).

---

## Known Stubs

- `docs/play-listing/permission-declaration.md` section 4: contains `[TODO: insert YouTube unlisted URL after recording per 06-VERIFICATION.md]` placeholder. This is intentional — the demo video must be recorded on real hardware before Play submission (Task 3b).
- `docs/play-listing/screenshots/`: no actual screenshot files yet. `screenshots/README.md` provides the capture checklist. Real captures are required before Play submission.
- 8 placeholder PNGs in `assets/onboarding/` (3) and `assets/logos/` (5) still need replacement before Play submission. These are tracked and documented in `assets/onboarding/README.md`.

---

## Self-Check: PARTIAL

Plan is paused at Task 3a BLOCKING gate. Self-check covers completed tasks only.

Files created check:
- docs/PRIVACY.md: FOUND
- docs/play-listing/short-description.txt: FOUND (67 bytes, within 80)
- docs/play-listing/full-description.txt: FOUND (2741 bytes, within 4000)
- docs/play-listing/permission-declaration.md: FOUND (contains AccessibilityService)
- docs/play-listing/screenshots/README.md: FOUND (contains 1024x500)
- docs/play-listing/README.md: FOUND (contains Play Console field)
- assets/onboarding/README.md: FOUND (updated with 8 placeholder PNGs)
- 06-VERIFICATION.md: FOUND (contains PHASE-6 OEM PASS + PLAY-08 CLOSED TRACK PASS + Phase 5 D-08)
- evidence/.gitkeep: FOUND

Commits check:
- 9a5bf7b (Task 1): FOUND
- 4956982 (Task 2): FOUND

Test check:
- privacy_policy_url_present_test.dart: 2/2 PASS

## Self-Check: PASSED (autonomous tasks 1 + 2)
