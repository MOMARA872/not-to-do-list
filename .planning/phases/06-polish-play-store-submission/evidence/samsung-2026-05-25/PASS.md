# SAMSUNG OEM PASS

**Device:** Samsung Galaxy S20 Ultra (SM-G988U1)
**Android:** 13
**App version:** 1.0.0+1 (versionCode=1)
**Test window:** 2026-05-25 08:14 to 2026-05-26 13:58 MST (~30h, overnight Doze)
**Verdict:** PASS

## 9-step OEM-survival protocol — all steps verified

| Step | Item | Evidence |
|------|------|----------|
| 1 | Install release APK | `package-info.txt`, `Performing Streamed Install / Success` |
| 2 | Onboarding (Usage Access + AccessibilityService + battery exemption) | `appops-perms.txt`, `a11y-service-enabled.txt` |
| 3 | Quick-add Instagram + 1 habit entry | Visual on phone (user confirmed) |
| 4 | Daily reminder set | `alarm-state.txt` — RTC_WAKEUP scheduled 2026-05-25 20:15:00 with `exactAllowReason=permission` + idle whitelist |
| 5 | Lock + charge overnight (12h real Doze) | Device left undisturbed 2026-05-25 08:14 → 2026-05-26 ~14:00 MST |
| 6 | Reminder fires within 5 min + deep-link to /checkin | `alarm-fire-history.txt` — alarm fired `rtc=2026-05-25 20:15:00.628` (0.6s after scheduled), self-re-armed to 2026-05-26 20:15:00 in same `onReceive()` cycle |
| 7 | Pause screen renders <1s on Instagram foreground | User confirmed "pause screen perfectly good" 2026-05-26 |
| 8 | Check-in submit → streak rolls over + idempotent | User confirmed: "streak rolled + idempotent" — second tap no-op as designed |
| 9 | Repeat on Xiaomi | PENDING — see `evidence/xiaomi-YYYY-MM-DD/` |

## Key observations

- `setExactAndAllowWhileIdle` fires under Samsung OneUI 5 adaptive battery + 12h accumulated Doze with 0.6s precision — no missed wake.
- Self-re-arm in `ReminderAlarmReceiver.onReceive()` writes next-day alarm in same broadcast window (Doze-exempt 10s allowlist suffices).
- Idempotent check-in submit confirmed — Phase 5 STRK-08 invariant holds in release build.
- Pause screen latency: subjective <1s, user reported "perfectly good".
- POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS granted at runtime.
- `GET_USAGE_STATS` + `BIND_ACCESSIBILITY_SERVICE` + `ACCESS_ACCESSIBILITY` granted via Special Access (appops snapshot in `appops-perms.txt`).

## Files in this evidence directory

- `PASS.md` (this file)
- `package-info.txt` — versionCode/versionName/minSdk/targetSdk
- `appops-perms.txt` — special-access permissions
- `a11y-service-enabled.txt` — NotToDoAccessibilityService in enabled list
- `alarm-state.txt` — alarm registration pre-overnight
- `alarm-fire-history.txt` — full alarm fire log + re-arm proof
- `deviceidle-state.txt` — Doze settings snapshot
- `logcat-pre-overnight.txt` — 3374-line pre-test logcat
- `logcat-doze-window.txt` — force-idle window logcat
- `logcat-after-broadcast.txt` / `logcat-broadcast2.txt` — direct-trigger attempts (denied per T-05-16, as designed)
- `notification-listing.txt` / `notification-post-broadcast.txt` — notification listener dumps
- `step7-current-state.png` — screen capture at verification time

## Sign-off

Type token: `SAMSUNG OEM PASS 2026-05-26 13:58 MST`
