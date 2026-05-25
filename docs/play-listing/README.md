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
