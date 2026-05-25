# CHECKPOINT — Task 3a: OEM-Survival Overnight Gate

**Status:** BLOCKED — awaiting user action
**Plan:** 06-08
**Gate token required:** `PHASE-6 OEM PASS`

---

## What was completed (Tasks 1 + 2)

All autonomous work is done and committed:

| Task | Commit | What was built |
|------|--------|----------------|
| Task 1 | 9a5bf7b | Final docs/PRIVACY.md + docs/play-listing/ asset tree + assets/onboarding/README.md with 8 placeholder PNGs listed |
| Task 2 | 4956982 | 06-VERIFICATION.md with 9-step OEM protocol + Play Console runbook + evidence directory |

## What the user must do now

Run the **9-step OEM-survival overnight protocol** from
`.planning/phases/06-polish-play-store-submission/06-VERIFICATION.md` Section 3
on BOTH a real Samsung AND a real Xiaomi device.

### Pre-flight (all must exit 0 before starting)

```bash
flutter clean && flutter test
flutter test test/policy/
flutter build apk --release
flutter test test/policy/apk_telemetry_strings_test.dart
```

### OEM Gate — Samsung (follow Section 3 steps 1–8 in 06-VERIFICATION.md)

1. Install release APK on real Samsung Galaxy S20 Ultra (or equivalent OneUI 5+)
2. Cold-launch, complete onboarding from /onboarding/welcome
3. Quick-add Instagram and 1 habit entry
4. Set daily reminder to a near-future time
5. Lock phone, leave on charger overnight (8+ hours)
6. Next morning: verify reminder fires within 5 min + notification tap deep-links to /checkin
7. Open Instagram — verify pause screen renders within 1 second
8. Complete check-in; verify streak rolls over; verify idempotent submission

Save evidence (logcat steps 6/7/8 + screenshots) to:
`.planning/phases/06-polish-play-store-submission/evidence/samsung-YYYY-MM-DD/`

Type `SAMSUNG OEM PASS` with timestamp when all 3 of steps 6/7/8 pass.

### OEM Gate — Xiaomi (follow Section 3 steps 1–8 in 06-VERIFICATION.md)

Repeat all 8 steps on a real Xiaomi device (MIUI/HyperOS).
The Xiaomi battery manager is the primary OEM risk — battery optimization exemption
must be granted during onboarding step 3.

Save evidence to:
`.planning/phases/06-polish-play-store-submission/evidence/xiaomi-YYYY-MM-DD/`

Type `XIAOMI OEM PASS` with timestamp when all 3 of steps 6/7/8 pass.

### Resume signal

Once BOTH Samsung AND Xiaomi gates pass:

**Type:** `PHASE-6 OEM PASS`

This unblocks Task 3b (Play Console submission + closed-track review).

If either gate fails: type `BLOCKED: <reason>`. Do NOT proceed to Task 3b until
BOTH gates PASS.

---

## What happens after this checkpoint

Task 3b: BLOCKING manual gate — Play Console submission (Internal → Closed) +
closed-track review verdict (1–7 days).

Task 4: Final bookkeeping flips (REQUIREMENTS.md, ROADMAP.md, STATE.md) — runs
ONLY after Task 3b PASS.
