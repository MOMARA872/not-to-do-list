# Play Console Data Safety Form — Not To-Do List

**Source of truth for:** the Play Console Data Safety form (PLAY-09).
**Last updated:** 2026-04-27 (Phase 1 commit)

---

## Section 1. Data collection and sharing

**Summary:** Data Collected: None. Data Shared: None. (Detail in the table and Section 2 below.)

| Question | Answer |
|----------|--------|
| Does your app collect or share any of the required user data types? | **No.** |
| Is all of the user data collected by your app encrypted in transit? | **N/A** — no data is collected or transmitted. |
| Do you provide a way for users to request that their data is deleted? | **Yes** — Settings → "Reset all data" deletes every entry, streak day, pause event, and check-in (SETT-02, Phase 6). |

## Section 2. Data types — declaration

For every Play Data Safety data category, the answer is **NOT COLLECTED**:

- Personal info: NOT COLLECTED
- Financial info: NOT COLLECTED
- Health and fitness: NOT COLLECTED
- Messages: NOT COLLECTED
- Photos and videos: NOT COLLECTED
- Audio files: NOT COLLECTED
- Files and docs: NOT COLLECTED
- Calendar: NOT COLLECTED
- Contacts: NOT COLLECTED
- App activity: NOT COLLECTED *(see note below)*
- Web browsing: NOT COLLECTED
- App info and performance: NOT COLLECTED
- Device or other identifiers: NOT COLLECTED

**Note on "App activity":** The user's Not-To-Do List, screen-time aggregates, daily check-ins, streak history, and pause-event log are stored exclusively in a SQLite database on the user's device. They are never transmitted off-device. Per the Play Data Safety policy, "data that stays on the user's device" is not "collected" for the purposes of this form.

## Section 3. Verification — actual code matches declaration

The Data Safety form's "no telemetry" claim is verifiable against the dependency tree.

**Dependency-tree audit command:**
```bash
flutter pub deps | grep -iE "firebase|fcm|analytics|crashlytics|amplitude|mixpanel|segment|sentry|datadog|appsflyer|adjust"
```
Expected output: **(empty)**.

**Network-permission audit:** the `INTERNET` permission is **not** declared in `AndroidManifest.xml`. The app cannot make any network request. (If a future phase adds a feature that requires network — e.g., M2 Supabase sync — this section MUST be updated and the Data Safety form re-submitted.)

**Build artifact audit:** the release APK can be inspected with `apkanalyzer` to verify no Google Play Services, Firebase, or analytics libraries are present (Phase 6 verification).

## Section 4. User controls

| Control | Implementation Phase |
|---------|----------------------|
| View all data the app stores | Daily / Weekly / Monthly dashboard (Phase 3) |
| Export all data (CSV + JSON) | SETT-01 (Phase 6) |
| Delete all data | SETT-02 (Phase 6) |
| Disable any single permission at any time | All four permissions are user-revocable from system Settings; app degrades gracefully (REL-02) |

## Section 5. Cross-reference

This document is consistent with `docs/play-declaration.md` (Section 5: Data Safety form alignment).

If any future change requires telemetry, FCM, analytics, or any off-device transmission, this document and the Play Console Data Safety form MUST be updated in the same commit as the dependency-tree change.
