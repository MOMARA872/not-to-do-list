# Play Listing — Field-to-File Map

This directory contains all assets for the Play Console listing and submission.
Use the table below to map each Play Console field to the correct file.

---

## Field-to-file mapping

| Play Console field | File in this directory |
|---|---|
| Short description (≤80 chars) | `short-description.txt` |
| Full description (≤4000 chars) | `full-description.txt` |
| Phone screenshot 1 | `screenshots/screenshot-home.png` |
| Phone screenshot 2 | `screenshots/screenshot-pause.png` |
| Feature graphic (1024x500) | `screenshots/feature-graphic-1024x500.png` |
| Permission Declaration — Core feature description | `permission-declaration.md` section 1 |
| Permission Declaration — Usage justification | `permission-declaration.md` section 2 |
| Permission Declaration — Data collection through accessibility | `permission-declaration.md` section 3 ("No.") |
| Permission Declaration — Demonstration video URL | `permission-declaration.md` section 4 (record per `06-VERIFICATION.md` before submission) |
| Data Safety — Privacy Policy URL | GitHub Pages URL — see `06-VERIFICATION.md` GitHub Pages note |
| Data Safety — All 14 data type categories | "Not collected" (all categories) |
| Data Safety — Data deletion | "Yes — Settings → Reset all data" |

---

## GitHub Pages note

The Privacy Policy must be hosted at a public URL for the Data Safety form.
Enable GitHub Pages:

1. Go to repo Settings → Pages
2. Source: Deploy from a branch
3. Branch: main, Folder: /docs
4. Wait 1–5 minutes for build
5. The Privacy Policy URL becomes: `https://{your-username}.github.io/{repo-name}/PRIVACY`
6. Verify: `curl -sIL https://{username}.github.io/{repo}/PRIVACY | head -1` should return `HTTP/2 200`
7. Paste the live URL into the Play Console Data Safety form and into `06-VERIFICATION.md`

See `06-VERIFICATION.md` for the full GitHub Pages enablement and Privacy URL curl
verification step.

---

## Screenshot assets status

Phone screenshots and feature graphic require real Pixel captures.
See `screenshots/README.md` for the capture checklist and specifications.

The 8 placeholder PNG assets in `assets/onboarding/` and `assets/logos/` also need
replacement before closed-track submission — see `assets/onboarding/README.md` and
`assets/logos/README.md` for details.

---

## v1.0.0-rc1 submission packet (2026-05-26)

**Release tag:** `v1.0.0-rc1`

**Bundle to upload:**
- File: `build/app/outputs/bundle/release/app-release.aab`
- Size: 49 MB / 569 files
- SHA256: `167ba6c941c59870f4819bc9245528b12f5a35dd446d1b21fc0abc9cae9f9cbc`
- versionName `1.0.0` / versionCode `1` / minSdk 29 / targetSdk 36
- App signing: Play App Signing (default)

**Live URLs:**
- Privacy Policy: https://momara872.github.io/not-to-do-list/PRIVACY (HTTP 200 verified)
- Demo video (unlisted): https://youtube.com/shorts/gMzZExas9CA

**Screenshots captured (Samsung Galaxy S20 Ultra, 1440×3200):**
- `screenshots/01-home.png` — home with entries + streak badges
- `screenshots/02-pause.png` — pause reflection screen on Instagram
- `screenshots/03-settings.png` — Settings hub (6 sections)
- `screenshots/04-checkin.png` — daily check-in screen
- `screenshots/feature-graphic-1024x500.png` — generated banner

**Pre-submission gate (all PASS 2026-05-26):**
- `flutter test` → 559 pass / 5 skip / 0 fail
- `flutter test test/policy/` → 26 pass / 0 fail
- `flutter build apk --release` → 63.8 MB
- `flutter test test/policy/apk_telemetry_strings_test.dart` → 0 telemetry matches
- `flutter clean` → done
- `flutter build appbundle --release` → 51.6 MB .aab

**Samsung OEM bookend:** `SAMSUNG OEM PASS 2026-05-26 13:58 MST` — see `.planning/phases/06-polish-play-store-submission/evidence/samsung-2026-05-25/PASS.md`

**Data Safety form answers:**
- Data collected: None
- Data shared: None
- Data deletion: Yes — in-app (Settings → Reset all data)
- Encryption in transit: N/A
- Privacy Policy URL: https://momara872.github.io/not-to-do-list/PRIVACY

**Track strategy:** Internal testing first → Closed testing (real policy review) → STOP at closed-track PASS. Do NOT promote to open beta or production in v1.

**Deferred to M2:** alphabet pause variant, Play Billing subscription, Xiaomi OEM-survival gate.
