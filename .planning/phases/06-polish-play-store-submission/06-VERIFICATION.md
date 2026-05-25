---
phase: 6
slug: polish-play-store-submission
status: pending_overnight_run
rel_06_status: pending
play_08_status: pending_closed_track_review
created: "2026-05-24"
last_updated: "2026-05-24"
---

# Phase 6 Verification — Polish & Play Store Submission

**Phase goal:** Convert the software-complete Settings + export + reset + theme +
privacy + disclosure + telemetry-gate work into a submittable Play Store closed-track
build, with the same evidence-and-gate discipline that Phase 4 REL-04 and Phase 5
REL-05 used.

**Exit criteria:**
1. REL bookend: OEM-survival overnight gate PASS on real Samsung AND real Xiaomi
2. Play Console closed-track review PASS at version 1.0.0+1

---

## Section 1: Software completion summary

All 8 Phase 6 plans have landed. Summary:

| Plan | Slug | Outcome |
|------|------|---------|
| 06-01 | Wave 0 — RED test stubs + pubspec deps | 11 RED test stubs + 4 new deps (archive, flutter_file_dialog, flutter_markdown_plus, package_info_plus). See [06-01-SUMMARY.md](06-01-SUMMARY.md) |
| 06-02 | themeModeProvider + MaterialApp wire-up | AsyncNotifier<ThemeMode> + shared_preferences persistence + themeMode wired in app.dart. See [06-02-SUMMARY.md](06-02-SUMMARY.md) |
| 06-03 | Settings hub shell + router + Phase 5 D-08 closure | SettingsScreen 6 sections + 8 tiles + 4 GoRouter routes + HomeScreen gear icon + inline Streak section (D-08 closure). See [06-03-SUMMARY.md](06-03-SUMMARY.md) |
| 06-04 | Export screen + ZIP + SAF bridge | ExportController (Drift → CSV/JSON → ZIP → flutter_file_dialog SAF). See [06-04-SUMMARY.md](06-04-SUMMARY.md) |
| 06-05 | Reset screen + Drift transactional wipe | ResetController (Drift transaction × 5 tables + SharedPreferences.clear + route to /onboarding/welcome). See [06-05-SUMMARY.md](06-05-SUMMARY.md) |
| 06-06 | Privacy screen + Accessibility disclosure | PrivacyScreen (flutter_markdown_plus rendering docs/PRIVACY.md) + AccessibilityDisclosureScreen. See [06-06-SUMMARY.md](06-06-SUMMARY.md) |
| 06-07 | PLAY-09 telemetry invariants + APK string sweep + version bump | Extended play_invariants_test.dart with pubspec.lock and decoded APK absence greps; version bumped to 1.0.0+1. See [06-07-SUMMARY.md](06-07-SUMMARY.md) |
| 06-08 | Play listing assets + this verification document | docs/PRIVACY.md final copy + docs/play-listing/ tree + 06-VERIFICATION.md. See [06-08-SUMMARY.md](06-08-SUMMARY.md) |

---

## Section 2: Phase 5 D-08 soft-lock closure note

Phase 5 D-08 promised a Settings Streak tile but did not ship the UI.
Phase 6 Plan 06-03 closed the loop by adding an inline Streak section above Appearance
per RESEARCH §Streak Threshold Tile option a.i (recommended). Phase 5 D-08 is now
SHIPPED, not deferred. Reference: [06-03-SUMMARY.md](06-03-SUMMARY.md).

The inline Streak tile re-uses the Phase 5 `_ThresholdDialog` Slider UI without
duplication — the tile opens the threshold dialog inline on the Settings screen.
This is the Claude's Discretion recommended option: the provider already existed,
the UI is one inline row, and it closes the Phase 5 broken promise cleanly.

---

## Section 3: 9-step OEM-survival overnight protocol (REL bookend)

**Status:** BLOCKING manual gate (Task 3a)

This is the implicit REL bookend for Phase 6 — not a new REQ-ID, mirrors the
Phase 4 REL-04 and Phase 5 REL-05 evidence pattern.

**Pass criterion:** All 9 steps complete on BOTH Samsung AND Xiaomi with no failures.

**Evidence directory:** `.planning/phases/06-polish-play-store-submission/evidence/`
Save timestamped logcat + screenshots under:
- `evidence/samsung-YYYY-MM-DD/` for Samsung run
- `evidence/xiaomi-YYYY-MM-DD/` for Xiaomi run

### Pre-flight (run before starting OEM gate)

All four must exit 0 or succeed before starting the overnight run:

```bash
flutter clean && flutter test
```
Expected: all tests pass, 0 failures.

```bash
flutter test test/policy/
```
Expected: PLAY-02..10 absence greps all pass, Phase 4/5 invariants pass.

```bash
flutter build apk --release
```
Expected: succeeds, APK at `build/app/outputs/apk/release/app-release.apk`.

```bash
flutter test test/policy/apk_telemetry_strings_test.dart
```
Expected: 0 grep matches (no telemetry strings in decoded APK).

### OEM gate steps (run on EACH device separately)

1. Install release APK on real Samsung Galaxy S20 Ultra (or equivalent OneUI 5+):
   ```bash
   adb install -r build/app/outputs/apk/release/app-release.apk
   ```

2. Cold-launch the app. Complete onboarding from `/onboarding/welcome`: grant Usage
   Access, enable AccessibilityService, grant battery optimization exemption. Verify
   all 3 permission steps complete with green status indicators.

3. Quick-add Instagram from the quick-add curated list. Add 1 habit entry manually.
   Both should appear on HomeScreen with streak badges.

4. Set daily reminder to a near-future time (5–10 minutes from now) in
   Settings → Reminder. Observe the reminder fires within that window to confirm
   AlarmManager scheduling works before the overnight run.

5. Lock phone, leave on charger overnight (8+ hours minimum). Do NOT interact with
   the device during this window — the test validates Doze-survival.

6. Next morning: verify the daily reminder fires within 5 minutes of the scheduled
   time. Verify notification tap deep-links to `/checkin` screen inside the app.
   Save logcat output to `evidence/samsung-YYYY-MM-DD/logcat-step6.txt`.

7. Open Instagram (or the added app entry). Verify the pause screen renders within
   less than 1 second of Instagram foregrounding.
   Save screenshot to `evidence/samsung-YYYY-MM-DD/step7-pause-screen.png`.

8. Complete a daily check-in from the deep-linked `/checkin` screen. Verify streak
   rolls over for the new day. Verify check-in submission is idempotent (tap submit
   twice — second tap should be a no-op, not a duplicate).

9. Repeat steps 1–8 on a real Xiaomi device (MIUI/HyperOS — aggressive battery
   manager is the primary OEM risk).

### Blocking gate tokens

- Type `SAMSUNG OEM PASS` when Samsung steps 6–8 are all observed working, with timestamp.
- Type `XIAOMI OEM PASS` when Xiaomi steps 6–8 are all observed working, with timestamp.
- Type `PHASE-6 OEM PASS` when BOTH Samsung AND Xiaomi gates have passed.
  This flips `rel_06_status` to `pass` and unblocks Task 3b (Play submission).

If either gate fails: type `BLOCKED: <reason>` with failure details. Do NOT proceed
to Task 3b until BOTH OEM gates PASS.

---

## Section 4: Play Console submission runbook

**Status:** Pending Task 3a PHASE-6 OEM PASS

### 4a. Pre-submission gates

All must pass before building the upload bundle:

```bash
flutter test
```
Expected: all tests pass, 0 failures, 0 skipped (or documented skips).

```bash
flutter test test/policy/
```
Expected: all policy tests pass (PLAY-02..10, Phase 4/5 invariants, APK strings).

```bash
flutter build apk --release
```
Confirm APK builds cleanly. Then re-run APK strings test with APK present:

```bash
flutter test test/policy/apk_telemetry_strings_test.dart
```
Expected: 0 grep matches.

```bash
flutter clean
```
Clean before final upload build to ensure no stale artifacts.

### 4b. GitHub Pages enablement (RESEARCH §Pattern 4 + Pitfall 8)

The Privacy Policy must be at a public HTTPS URL for the Data Safety form.
GitHub Pages is the zero-cost, zero-maintenance option:

1. Go to repo **Settings → Pages**
2. **Source:** Deploy from a branch
3. **Branch:** main, **Folder:** /docs
4. Click Save. Wait 1–5 minutes for the first build.
5. The Privacy Policy URL becomes: `https://USER.github.io/REPO/PRIVACY`
   (substitute your GitHub username and repo name; no `.md` extension)

Verify the URL returns 200:
```bash
curl -sIL https://USER.github.io/REPO/PRIVACY | head -1
```
Expected: `HTTP/2 200`

**Note:** Org/Enterprise GitHub may have Pages disabled. Fallback: any static host
with a stable HTTPS URL (e.g., Netlify free tier, raw.githubusercontent.com with
a redirect, or a minimal personal site). The URL must be permanent — Play Console
reviewers will check it.

Paste the live URL here once confirmed:
```
Privacy Policy URL: https://________________________________/PRIVACY
```

### 4c. Demo video recording (RESEARCH Pitfall 1 — REQUIRED)

The AccessibilityService Permission Declaration form **requires** a demo video URL.
Missing this is the #1 cause of rejection for AccessibilityService-using apps.

Record a 30–60 second screencast on a real Pixel or Samsung device:

1. Cold open Not To-Do List from the home screen (show full app cold-start)
2. Quick-add Instagram from the curated list (show the not-to-do list concept)
3. Navigate to Settings → Accessibility disclosure (show PLAY-06 prominent disclosure)
4. Tap Instagram from the not-to-do list overview (or open Instagram from the drawer)
5. The pause screen renders within 1 second (show the core reflection moment)
6. Show the cooldown timer options; start one
7. Return to the app and show the streak badge updated

Upload to YouTube as **unlisted** (not private — Play Console reviewers must view it).
Paste the URL:
- Into `docs/play-listing/permission-declaration.md` section 4 (replaces the
  `[TODO: insert YouTube unlisted URL...]` placeholder)
- Into the Play Console Permission Declaration form section 4

### 4d. Internal testing track (D-15 step 1 — instant review)

Internal testing has no policy review — it is for self-testing the listing copy and
Data Safety form entries before triggering the real review.

1. Build the upload bundle:
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`

2. Open Play Console → Your app → Testing → Internal testing → Create new release
3. Upload `app-release.aab` (version 1.0.0+1 from pubspec.yaml)
4. Fill Store listing fields from `docs/play-listing/`:
   - Short description: paste `short-description.txt`
   - Full description: paste `full-description.txt`
   - Screenshots: upload `screenshots/screenshot-home.png` and `screenshot-pause.png`
   - Feature graphic: upload `screenshots/feature-graphic-1024x500.png`
5. Fill Data Safety form:
   - All 14 data type categories: Not collected
   - Data deletion: Yes (Settings → Reset all data)
   - Privacy Policy URL: paste the verified GitHub Pages URL
   - Encryption in transit: N/A (no transmission)
6. Fill Permission Declaration form:
   - Copy section 1 from `permission-declaration.md` (Core feature description)
   - Usage justification: App functionality
   - Data collection through accessibility: No
   - Demo video URL: paste YouTube unlisted URL from step 4c
7. Save draft, publish to Internal testing
8. Add developer's own Google account as sole internal tester
9. Install on developer Pixel/Samsung via the Internal track install link
10. Smoke-verify listing copy looks correct, Data Safety form shows correctly, app
    installs and launches cleanly

### 4e. Closed testing track (D-15 step 2 — REAL POLICY REVIEW)

Closed testing triggers Google's actual policy review of the AccessibilityService
declaration. This is where Play may request changes or reject.

1. Promote the same Internal build to Closed testing track
   (Play Console → Testing → Closed testing → Promote from Internal)
2. Add 5–20 named testers (minimum: developer + 1–2 friends for sanity per RESEARCH
   Open Question 7)
3. Write release notes: `"v1.0.0 first closed track release"`
4. Submit for review
5. Wait 1–7 business days for the Play Console review verdict

### 4f. STOP at closed-track PASS (per D-15 + ROADMAP Phase 6 success criterion 3)

v1 STOPS at closed-track PASS. Do NOT promote to open beta or production.
Post-closed-track promotion is a separate user decision (post-validation cycle).

**Task 3b STOP gate:** Type `PLAY-08 CLOSED TRACK PASS` with verdict timestamp to
proceed to Task 4 bookkeeping.

If rejected: capture the rejection reason in a "Review Rejection History" subsection
below this section. Fix per RESEARCH Pitfall 1 root-cause patterns (most likely:
missing demo video, declaration-vs-in-app mismatch, or `isAccessibilityTool` flag
check). Re-submit. Do NOT proceed to Task 4 until PASS.

---

## Section 5: Play Console form fill checklists

### Permission Declaration form

| Field | Value |
|-------|-------|
| Core feature description | Paste `permission-declaration.md` section 1 verbatim |
| Usage justification (category) | App functionality |
| Data collection through accessibility | No |
| Demonstration video URL | YouTube unlisted URL (record per section 4c) |

### Data Safety form

| Field | Value |
|-------|-------|
| Personal info | Not collected |
| Financial info | Not collected |
| Health and fitness | Not collected |
| Messages | Not collected |
| Photos and videos | Not collected |
| Audio files | Not collected |
| Files and docs | Not collected |
| Calendar | Not collected |
| Contacts | Not collected |
| App activity | Not collected |
| Web browsing | Not collected |
| App info and performance | Not collected |
| Device or other identifiers | Not collected |
| Data deletion | Yes — Settings → Reset all data |
| Privacy Policy URL | GitHub Pages URL (verified HTTP/2 200) |
| Encryption in transit | N/A |

### Store listing

| Field | Source |
|-------|--------|
| Short description | `docs/play-listing/short-description.txt` |
| Full description | `docs/play-listing/full-description.txt` |
| Phone screenshot 1 | `docs/play-listing/screenshots/screenshot-home.png` |
| Phone screenshot 2 | `docs/play-listing/screenshots/screenshot-pause.png` |
| Feature graphic | `docs/play-listing/screenshots/feature-graphic-1024x500.png` |

### Closed testing release

| Field | Value |
|-------|-------|
| Tester emails | Developer + 1–2 friends minimum |
| Release notes | `v1.0.0 first closed track release` |
| Upload bundle | `build/app/outputs/bundle/release/app-release.aab` |

---

## Section 6: Pre-submission verification commands

Run these in order before building the upload bundle. All must succeed:

```bash
# 1. Full test suite
flutter test

# 2. Policy tests only
flutter test test/policy/

# 3. Release APK build
flutter build apk --release

# 4. APK telemetry string sweep (run AFTER APK build — needs the artifact)
flutter test test/policy/apk_telemetry_strings_test.dart

# 5. Privacy URL live check (run AFTER GitHub Pages is live)
curl -sIL https://USER.github.io/REPO/PRIVACY | head -1
# Expected: HTTP/2 200

# 6. Upload bundle build (for Play Console upload)
flutter clean && flutter build appbundle --release
```

---

## Section 7: Phase-exit bookkeeping checklist

Gated on `rel_06_status: pass` AND `play_08_status: pass_closed_track`.
Do NOT flip requirements until BOTH gates have passed.

- [ ] REQUIREMENTS.md: flip SETT-01 to Complete (Plan 06-04; OEM gate PASS date)
- [ ] REQUIREMENTS.md: flip SETT-02 to Complete (Plan 06-05; OEM gate PASS date)
- [ ] REQUIREMENTS.md: flip SETT-04 to Complete (Plan 06-02+06-03; OEM gate PASS date)
- [ ] REQUIREMENTS.md: flip SETT-05 to Complete (Plan 06-06; OEM gate PASS date)
- [ ] REQUIREMENTS.md: flip PLAY-07 to Complete (Plan 06-08; Play closed-track PASS date)
- [ ] REQUIREMENTS.md: flip PLAY-08 to Complete (Plan 06-08; Play closed-track PASS date; build 1.0.0+1)
- [ ] REQUIREMENTS.md: update "v1 requirements complete" tally (verify live count)
- [ ] ROADMAP.md: Phase 6 row checkbox `[ ]` → `[x]`
- [ ] ROADMAP.md: Progress table Phase 6 row: Plans Complete = 8/8, Status = Complete, Completed = date
- [ ] ROADMAP.md: Notes section — append Phase 6 closure note
- [ ] STATE.md: completed_phases → 6
- [ ] STATE.md: total_plans → 46, completed_plans → 46, percent → 100
- [ ] STATE.md: Current Position → "Phase 6 COMPLETE; v1 SHIPPED to Play Console closed-track"
- [ ] STATE.md: Progress bar → 100%
- [ ] STATE.md: Active Todos updated; Phase 6 closed todo appended
- [ ] 06-VERIFICATION.md: frontmatter status → complete; rel_06_status → pass; play_08_status → pass_closed_track
- [ ] 06-VERIFICATION.md: Section 8 sign-off checkboxes all ticked with timestamps
- [ ] Optional: tag `v1.0.0-closed-track` on the commit containing the Play upload bundle

---

## Section 8: Sign-off

- [ ] Software-complete (all 8 plans landed — auto-flipped after 06-07)
- [ ] Pre-flight: flutter test exits 0
- [ ] Pre-flight: flutter test test/policy/ exits 0
- [ ] Pre-flight: flutter build apk --release succeeds
- [ ] Pre-flight: apk_telemetry_strings_test exits 0 with APK present
- [ ] OEM PASS Samsung Galaxy S20 Ultra 5G (Task 3a) — timestamp: _______________
- [ ] OEM PASS Xiaomi device (Task 3a — BLOCKING manual gate) — device model: ___; timestamp: _______________
- [ ] PHASE-6 OEM PASS confirmed (both Samsung + Xiaomi) — timestamp: _______________
- [ ] Play Internal track: build uploaded + listing copy verified on developer device (Task 3b)
- [ ] Demo video recorded and URL pasted in permission-declaration.md sec 4 + Play Console form (Task 3b)
- [ ] GitHub Pages live and Privacy URL returns HTTP/2 200 (Task 3b) — URL: _______________
- [ ] Play Closed track submitted (Task 3b) — submitted: _______________
- [ ] Play Closed track PASS verdict received (Task 3b — BLOCKING manual gate) — verdict date: _______________
- [ ] Final bookkeeping complete (Task 4) — completed: _______________
