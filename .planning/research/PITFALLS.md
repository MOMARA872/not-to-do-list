# Pitfalls Research

**Domain:** Flutter + Android screen-time tracker / soft-blocker (UsageStatsManager + AccessibilityService)
**Researched:** 2026-04-26
**Confidence:** HIGH for policy, OEM, and battery pitfalls (Google docs, Don't Kill My App, multiple corroborated sources). MEDIUM for Flutter-specific integration pitfalls (fewer authoritative sources, some inferred from native Android behavior).

---

## Critical Pitfalls

### Pitfall 1: Play Store rejection for AccessibilityService misuse

**What goes wrong:**
The app gets rejected (or worse — silently delisted after publishing, with developer-account suspension threatened) because the AccessibilityService Permission Declaration Form fails review. Google reviewers reject apps where the a11y use is not "narrow and clearly understood," not declared transparently, or where the app could plausibly be implemented without a11y.

**Why it happens:**
- Google's policy: "only services designed to help people with disabilities access their device... are eligible to declare that they are accessibility tools." Digital wellbeing/focus is *permitted*, but only if the use is narrow, declared, and the user is given prominent disclosure.
- Many devs check `isAccessibilityTool=true` (which they shouldn't — that flag is for genuine assistive tech).
- Many devs don't fill in the Permission Declaration Form *at all*, or fill it with marketing copy instead of a literal "we read the foreground app's package name to show our pause overlay" answer.
- "Apps using the Accessibility API for automation purposes... that enable an app to autonomously initiate, plan, and execute actions or decisions" are explicitly prohibited. Soft-block via overlay (user dismisses) is fine; force-closing the offending app via a11y gestures is not.

**How to avoid:**
- Set `android:isAccessibilityTool="false"` in the service config (we are NOT an accessibility tool).
- In the Play Console Permission Declaration Form, write literal mechanical descriptions: *"The service observes `TYPE_WINDOW_STATE_CHANGED` events and reads `event.getPackageName()` to determine the foreground app. If the package matches the user-defined Not-To-Do list, the app launches its own in-process pause Activity. The service does not perform gestures, read content, or autonomously dismiss other apps."*
- In-app prominent disclosure screen before requesting a11y, in plain English, with a screenshot of the pause overlay.
- Do NOT use a11y for anything you can do another way — for screen-time *measurement*, use UsageStatsManager only; reserve a11y for the launch-detection trigger.
- Test the rejection path: submit a closed-track build before public release so a rejection is recoverable.

**Warning signs:**
- Reviewer asks for a video showing the a11y feature → declaration was unclear.
- App got auto-flagged by Google's pre-launch report → policy bot disagrees with declared use.
- Anything in the manifest like `flagRequestFilterKeyEvents` or `canPerformGestures="true"` you didn't intentionally need.

**Phase to address:**
**Phase 1 (Foundations / permissions plumbing)** — write the declaration copy *before* writing the service. The declaration drives the implementation, not the reverse. Re-verify at **Phase N (Pre-launch)**.

---

### Pitfall 2: AccessibilityService silently killed by OEM battery managers (Xiaomi, Huawei, Samsung, Oppo, Vivo, OnePlus)

**What goes wrong:**
The user enables a11y, the app works for a day, then the OEM's "smart" battery manager decides the app is "draining battery" and disables it. Or kills it after the screen is off for 30 min. Or resets the a11y toggle silently after an OTA. The user never notices — until they open a blocked app and the pause screen doesn't appear, then they assume the app is broken.

**Why it happens:**
- Huawei has `PowerGenie` and `HwPFWService` killing non-whitelisted apps and any app holding a wakelock >60 min.
- Xiaomi MIUI/HyperOS resets autostart permissions after OTA updates and has multiple overlapping kill mechanisms (autostart, battery saver, MIUI optimizations).
- Samsung's "Sleeping Apps" list auto-adds apps with no foreground use for 3 days; OTAs reset battery exemptions.
- Oppo/Realme (ColorOS), Vivo (FuntouchOS), and OnePlus (OxygenOS post-merger) all behave similarly.
- The dev tests on a Pixel where everything works; ships; users on real-world devices report "the app stops blocking after a while."

**How to avoid:**
- Treat OEM survival as an **explicit feature**, not an afterthought.
- Run a **foreground service with persistent notification** alongside (or as the host of) the a11y trigger logic — it's harder to kill and gives the user a visible "I'm watching" cue. (See Pitfall 7 for the right tool choice.)
- After permission setup, check `PowerManager.isIgnoringBatteryOptimizations()` and prompt the user with `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (this *is* allowed for our use case — see Pitfall 6).
- Implement an **OEM-aware "fix it" flow**: detect manufacturer (`Build.MANUFACTURER`), and on Xiaomi/Huawei/Samsung/etc. show a step-by-step guide to whitelist the app in the OEM's specific battery menu. Link to dontkillmyapp.com per-OEM pages or replicate the steps in-app.
- Add a **self-healing health check**: on every app open, verify a11y is still enabled, foreground service is running, battery exemption still granted. If any are missing, route to a "your tracker is offline — fix in 30 seconds" screen.
- Detect OTAs (compare `Build.FINGERPRINT` between launches) and re-prompt for permissions afterward.

**Warning signs:**
- Beta tester says "it stopped working" with no reproducible bug → almost always OEM kill.
- Streak data has gaps that correlate with overnight idle periods.
- Crash-free but no events logged for >12h → service was killed.

**Phase to address:**
**Phase 3 (Background reliability / launch interception)** must include OEM survival as a first-class acceptance criterion, *not* a "we'll fix it later." Add health-check screen in **Phase 4 (Streak + check-in)** so users self-diagnose.

---

### Pitfall 3: PACKAGE_USAGE_STATS onboarding cliff (users abandon at the Settings hand-off)

**What goes wrong:**
The user installs the app, sees "Grant Usage Access in Settings →" and either (a) doesn't understand what to do, (b) gets dropped on a generic Special App Access list with hundreds of apps and can't find this one, (c) toggles it then hits Back and doesn't return to the app. Conversion from install → fully-permissioned drops below 50%.

**Why it happens:**
- `PACKAGE_USAGE_STATS` is a "special permission" — not a runtime prompt; only granted via Settings. The system intent `Settings.ACTION_USAGE_ACCESS_SETTINGS` opens the *list*, not your app's row directly (deep-linking to a specific app's row is unreliable across OEMs/Android versions).
- Combined with a11y + battery-optimization + notifications, that's **4 separate Settings hand-offs** before the app even works. Each one is a drop-off point.
- New devs underestimate this and treat it as a checkbox in onboarding, not an attended journey.

**How to avoid:**
- **Sequence the asks** — never ask for everything at once. Order matters: notifications first (least scary, easiest), then UsageStatsManager (needed for the dashboard, the visible win), then a11y (needed for blocking, gated by user adding their first not-to-do app), then battery-opt last.
- Build a **return-detection loop**: when launching the Settings intent, also start a check (lifecycle-aware, e.g. on `onResume`) that polls for `usageStatsGranted == true` and auto-advances the onboarding screen when it flips. Users hate having to come back and tap "Continue."
- Use **animated GIFs or short looping screen captures** showing exactly what to tap in Settings — not text instructions. Different OEMs have different menu names ("Usage access" vs. "Apps with usage access" vs. "Special access" vs. buried under "More").
- Provide a **fallback "I can't find it" path** — explicit OEM-specific instructions if `Settings.ACTION_USAGE_ACCESS_SETTINGS` fails to resolve (some Chinese ROMs).
- Treat onboarding completion as a **funnel metric** even pre-launch. Instrument each step locally (no telemetry, just for personal beta testing) so you can see where your alpha testers drop.

**Warning signs:**
- Beta testers say "I installed it but it doesn't show any data" — they didn't grant usage access.
- App opened > screen-time-data-present rate < 70% after onboarding.
- Support questions: "How do I turn it on?"

**Phase to address:**
**Phase 2 (Onboarding + permissions)**. This phase is doing more work than typical "permissions UI"; it's a wedge-defining UX. Budget real time for it.

---

### Pitfall 4: Treating accessibility service as if it can `startService()` itself / die-on-app-close mistake

**What goes wrong:**
The dev assumes "I'll just use the a11y service to detect launches" then runs into: a11y service is started/stopped *only by the system*, not by the app; if the user revokes a11y from Settings, the service dies and the app cannot restart it programmatically; if the app's process is killed, the service may also be killed depending on configuration; on reboot, a11y is sometimes auto-disabled (especially on certain OEMs/Android versions).

**Why it happens:**
- Misconception that `AccessibilityService` is "just a Service" — it's lifecycle-managed by the system.
- Reboot behavior is inconsistent: most modern Android keeps a11y on across reboot, but some OEMs and some Android versions don't, and `BOOT_COMPLETED` is delayed until first unlock.
- App developers test "happy path" only — never test "user revokes a11y, what happens to my streak?"

**How to avoid:**
- Architect from day one: **a11y service is a passive trigger; it is NOT the source of truth.** All state (streak, screen time, settings) lives in local DB. The service writes events; nothing else depends on the service being alive.
- On every app foreground, check `AccessibilityManager.isEnabled()` AND that *your specific service* appears in the enabled list. If not, show "Tracking is paused — re-enable in Settings."
- Register a `BOOT_COMPLETED` receiver to re-check permissions and start the foreground service after reboot. Do not assume a11y survives reboot — verify it.
- Build a **graceful-degradation mode**: if a11y is off but UsageStatsManager works, you can still track and warn ("you used Instagram for 30 min on your not-to-do list — reflect on it tomorrow") even though you couldn't soft-block in the moment.
- **Decouple** screen-time tracking (UsageStatsManager polling, works without a11y) from launch interception (a11y, optional).

**Warning signs:**
- Bug reports of "streak broke randomly with no usage."
- Users mentioning they "turned off the keyboard accessibility thing because it was confusing" — they nuked all a11y services.
- Service not in `getEnabledAccessibilityServiceList` even though manifest is correct.

**Phase to address:**
**Phase 1 (Architecture)** — the "service is passive trigger, DB is truth" decision is foundational. **Phase 3 (Launch interception)** verifies graceful degradation.

---

### Pitfall 5: Wrong tool for the job — AccessibilityService vs. Foreground Service vs. WorkManager

**What goes wrong:**
Dev uses WorkManager (correct for periodic deferred work) to poll UsageStatsManager every 15 min, then wonders why pause screens never appear before the user has already scrolled Instagram for 5 min. Or uses a foreground service polling at 1 sec but never enables a11y, so it can't show overlays without `SYSTEM_ALERT_WINDOW`. Or uses a11y for *both* detection and tracking, then can't track when a11y is off.

**Why it happens:**
- Confusion about which background mechanism does what. Each has different latency, different battery cost, different lifecycle, different policy implications.
- Tutorials online conflate them.

**How to avoid:** Use the right tool for each job:

| Need | Right tool | Why |
|------|-----------|-----|
| **Detect "blocked app launched RIGHT NOW" (sub-second latency for pause screen)** | AccessibilityService observing `TYPE_WINDOW_STATE_CHANGED` | UsageStatsManager has ~2.5 sec lag minimum (sometimes worse); too slow for "intercept the moment of impulse." |
| **Periodic screen-time aggregation (the dashboard)** | UsageStatsManager queries from a foreground service or WorkManager periodic task | UsageStatsManager is the ONLY API that gives you per-app totals. Lag doesn't matter for daily totals. |
| **Daily reminder push notification at user-chosen time** | `AlarmManager.setExactAndAllowWhileIdle()` (or WorkManager periodic) | WorkManager respects Doze; AlarmManager exact survives Doze for important user-facing reminders. |
| **Keeping a11y service alive across OEM kills** | A companion **foreground service with low-importance persistent notification** | Foreground services have higher OOM priority; act as a "tether" for the a11y service. |
| **Background streak rollover at midnight** | `WorkManager` periodic with constraints, OR check-and-update on every app open | Don't fight Doze for non-urgent work. |

**Warning signs:**
- "Pause screen sometimes doesn't show up" → polling-based detection, switch to a11y events.
- Notification jitter (reminder fires 2h late) → Doze killed your AlarmManager; switch to `setExactAndAllowWhileIdle`.
- Battery drain complaints → polling too aggressively or wakelock leak.

**Phase to address:**
**Phase 1 (Architecture)** — pick the topology before writing code. **Phase 3 (Launch interception)** validates latency.

---

### Pitfall 6: Doze + App Standby Buckets degrade tracking quietly

**What goes wrong:**
Phone sits idle overnight. User opens phone in the morning, thinks they didn't use Instagram (and indeed they didn't). But your app missed a UsageStatsManager poll, missed a streak-rollover task, missed the morning reminder. Or worse, your foreground service got moved to the **Restricted** App Standby Bucket because it ran "too much."

**Why it happens:**
- Doze defers background CPU/network when device is unused.
- App Standby Buckets (Active / Working Set / Frequent / Rare / Restricted) limit how often deferred jobs/alarms can fire. The Restricted bucket fires jobs ~once per day max.
- Foreground services exempt the app from being considered "idle" — but only while the FGS is actively running with a notification.
- Apps that do "heavy" work (frequent wakelocks, frequent jobs) get pushed to lower buckets by the system.

**How to avoid:**
- Run a foreground service while a11y is active — that keeps you in the Active bucket.
- For the daily reminder, use `setExactAndAllowWhileIdle` (allowed for user-facing reminders) — but understand the maintenance windows: Doze briefly wakes the device every ~hour or so; jobs can run in those windows but not arbitrarily.
- For streak rollover, do **lazy evaluation**: don't try to "fire at exactly 00:00" — instead, on every app open or every UsageStats query, check "did the calendar day change since last evaluation? If so, roll over." This is robust against Doze, reboots, and offline.
- Avoid frequent wakelocks. Don't poll in tight loops.
- Use `JobScheduler` constraints (idle, charging) for housekeeping work.
- Test with `adb shell dumpsys deviceidle force-idle` to simulate Doze.

**Warning signs:**
- Streak data has overnight gaps.
- Reminder fires hours late.
- `dumpsys usagestats` shows your app dropped to "RARE" or "RESTRICTED" bucket.

**Phase to address:**
**Phase 3 (Background reliability)** and **Phase 4 (Streak + reminders)**. Doze testing is a phase exit gate.

---

### Pitfall 7: Battery-optimization exemption request rejected by Play Store / abused

**What goes wrong:**
Dev adds `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission to the manifest, calls `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, and either (a) gets the app rejected for unjustified use or (b) gets approved but then OEM aggressive killers ignore the exemption anyway.

**Why it happens:**
- Google policy: apps may NOT request battery-optimization exemption *unless* "the core function of the app is adversely affected" by Doze/Standby. Just wanting to "be reliable" isn't enough.
- For our app, the core function (intercepting blocked-app launches in real time) genuinely *does* break if the a11y/foreground service is killed. So the exemption is justified — but the **justification copy in the Permission Declaration Form** must say so.
- Even with the exemption, OEM killers (Xiaomi, Huawei) operate at a layer Google's exemption doesn't reach.

**How to avoid:**
- Document the justification in writing in the Play Console *and* in your in-app rationale screen before showing the system dialog: *"Without this exemption, the device will pause our background tracking after a few hours of idle, causing your streak to break or pause screens to fail to appear."*
- Use `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (which shows the system dialog) — do NOT silently send users to settings or auto-grant via system permission (you can't anyway, but some try shady workarounds).
- Combine with OEM-specific battery whitelist guidance (Pitfall 2). Google's exemption is necessary but not sufficient.
- If you ever consider dropping the exemption to "look less invasive on Play": don't. The reliability cost is huge for our use case.

**Warning signs:**
- Play Store review requests "explain why your app needs to ignore battery optimizations."
- Users on stock Android (Pixel) report intermittent issues — exemption probably isn't being granted.

**Phase to address:**
**Phase 1 (Permissions architecture)** — write justification copy alongside the manifest entry. **Phase N (Pre-launch)** — ensure declaration form mirrors in-app copy.

---

### Pitfall 8: SYSTEM_ALERT_WINDOW (overlay) restrictions break the pause screen

**What goes wrong:**
Dev assumes the pause screen will be a `WindowManager.addView()` overlay using `SYSTEM_ALERT_WINDOW`. Hits multiple problems: (a) Android 12+ severely restricts background-launch from overlay-holding apps, (b) overlays interfere with system Settings (the dreaded "Screen Overlay Detected" error blocks granting any further permissions while an overlay is showing), (c) Play Store flags `SYSTEM_ALERT_WINDOW` as a sensitive permission requiring justification, (d) `HIDE_OVERLAY_WINDOWS` in Android 12 lets *other* apps opt out of having overlays drawn over them.

**Why it happens:**
- Overlay was the canonical "pause screen" pattern in 2016-era app blockers; the platform has since clamped down because malware abused it (74% of ransomware abuses `SYSTEM_ALERT_WINDOW`).

**How to avoid (preferred path for this app):**
- **Don't use a system overlay.** Instead, when a11y detects the blocked app launch, launch your **own full-screen Activity** (`Intent.FLAG_ACTIVITY_NEW_TASK` + your single-task pause Activity). This is what ScreenZen / Block / Limitly do. The system treats it as a normal activity launch.
- This avoids `SYSTEM_ALERT_WINDOW` entirely — no overlay permission needed, no "Screen Overlay Detected" interference, no Play Store sensitive-perm declaration.
- Caveat: launching activities from background was restricted in Android 10+. But: a11y service is on the **exemption list** for background activity launches (precisely because that's the legitimate use case for assistive tech). Verify this works on your minSdk in Phase 3.
- If you must use an overlay (e.g., to draw on top of a system app you can't redirect from), declare `SYSTEM_ALERT_WINDOW` and provide explicit justification on Play Console.

**Warning signs:**
- "Screen Overlay Detected" errors when granting other permissions.
- Pause activity launches but is immediately backgrounded.
- Play Console flags overlay permission.

**Phase to address:**
**Phase 3 (Launch interception)** — prototype the activity-launch approach early; it's the load-bearing UX.

---

### Pitfall 9: Streak dishonesty — bypass tactics users will use

**What goes wrong:**
Even self-disciplined adults will rationalize once. They'll change device time, force-stop the app, uninstall and reinstall, toggle airplane mode, switch user profiles, or use a guest profile. Each tactic breaks streak integrity in a different way. Users who can game the streak stop trusting their own data → product loses meaning → they churn.

**Why it happens:**
- Self-reported habit apps have universally-documented bypass patterns (see all the iOS Screen Time bypass guides).
- The user is both the regulator and the regulated. There's no parental authority watching.

**How to avoid (proportionate to "self-disciplined adult" target user):**

| Bypass | Defense | Tradeoff |
|--------|---------|----------|
| **Change device time forward to skip "today"** | Use `SystemClock.elapsedRealtimeNanos()` (boot-monotonic) alongside wall-clock. Detect "wall clock jumped backward" and flag streak as suspect. Or query `Network Time` periodically (no backend needed — just NTP). | Adds complexity; may false-positive on legitimate timezone change. |
| **Uninstall + reinstall to reset streak** | Cannot prevent without device-admin (overkill, scary) or backup restore. **Lean into honesty:** publicly say "if you uninstall, your streak resets — that's by design, you're choosing to start over." Make the user's deliberate uninstall a feature, not a bug. | None — this is the right philosophical stance for an adult mindfulness app. |
| **Force-stop the app from Settings** | Detect on next launch (boot timestamp + last-event-timestamp gap). Mark the gap as "tracking was off — day flagged as incomplete data." | Some legitimate force-stops happen (low memory). |
| **Toggle airplane mode / phone off all day** | We're 100% local; airplane mode doesn't help bypass our system. Phone-off means no events, which by definition means no usage of blocked apps either. **Phone off = honest no-usage day.** | None. |
| **Disable a11y to avoid pause screens, then re-enable later** | Detect a11y disable event; flag periods where a11y was off as "interception offline." | The user can still self-report — but mark the day as "self-reported only." |
| **Change timezone while traveling / cross dateline** | Anchor "day" to user-selected home-timezone, OR offer a "travel mode" toggle that uses device timezone but logs the shift. Use `LocalDate` derived from a stable reference (home timezone), not raw `LocalDateTime.now()`. | DST adds a 23h/25h day; handle explicitly. |

**Combined honesty strategy:**
1. Streak-of-streaks is the user's relationship with themselves, not with the app.
2. Make cheating *visible* — show "Day 12 — system-confirmed" vs. "Day 13 — self-reported, tracking was offline 4h." Don't auto-break the streak; let the user see the asterisk and decide.
3. The "Did you avoid X today?" daily check-in is the philosophical anchor — even with perfect tracking, the user has to *claim* the day.

**Warning signs:**
- Streak data with impossible jumps (last event timestamp > current time, e.g. user changed clock).
- Streak length growing while UsageStatsManager shows blocked-app usage.
- Frequent a11y on/off cycles.

**Phase to address:**
**Phase 4 (Streak + check-in)**. This is the honesty layer. Don't ship without at least time-tampering detection and a "day is incomplete" flag.

---

### Pitfall 10: Notification permission declined → daily reminder never fires

**What goes wrong:**
Android 13+ (API 33) requires runtime permission for notifications. User installs the app, the system never auto-prompts (you have to call `ActivityCompat.requestPermissions` yourself for `POST_NOTIFICATIONS`), so the prompt never appears, or the user taps "Don't allow" out of habit. The daily reminder — a core feature for habit formation — silently fails. Streaks degrade.

**Why it happens:**
- Industry-wide rejection rates on `POST_NOTIFICATIONS` are reported to be high (no single canonical number; varies by app category and prompt timing).
- If the user denies twice, the prompt is permanently dismissed — only Settings can re-enable.
- Foreground services on API 33+ also need `POST_NOTIFICATIONS` for their notification to show — so the persistent "I'm tracking" notification won't show either.

**How to avoid:**
- **Earn the prompt.** Don't ask on first launch. Ask after the user has set up at least one not-to-do app and seen value. Prefacing the system dialog with a custom rationale screen ("We send one reminder a day at the time you choose — you can turn it off any time. Tap allow on the next screen.") roughly doubles allow rates.
- Detect denial; show in-app banner: "Reminders are off — your daily check-in won't show. [Fix in Settings]"
- Make the foreground service notification *useful* (show today's screen time at a glance) rather than just "Service is running" — so it justifies its own existence even if reminders are denied.
- Test on Android 13, 14, 15, and 16 (different prompt behaviors across versions).

**Warning signs:**
- Reminder feature shipped, no notification prompt ever shown to user — you forgot to call `requestPermissions` yourself.
- Users say "the app doesn't remind me" — denied notifications.

**Phase to address:**
**Phase 2 (Onboarding)** for permission flow, **Phase 4 (Reminders)** for fallback UX.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Polling UsageStatsManager every second from a foreground service to detect launches (instead of a11y) | Skip a11y onboarding + Play declaration | 2.5+ sec latency means user already opened Instagram before pause screen fires; battery drain; will be pushed to Restricted bucket | Only as a fallback if a11y is denied; never primary |
| Hardcoding `Build.MANUFACTURER == "Xiaomi"` battery-fix instructions | Quick fix for one OEM | Have to maintain forever; new OEMs (Nothing, Honor-post-Huawei) keep appearing; instructions break across OEM UI updates | If isolated to one well-tested handler with a fallback "show generic instructions" |
| Storing streak in shared_preferences as a single integer | Trivial to implement | Loses all replay/audit capability; can't show "day 7 was self-reported", can't recover from bug; can't roll back tampering | Never for a streak-as-core-feature product |
| Using `flutter_accessibility_service` plugin without writing native fallback | Faster Phase 3 prototyping | Plugin abandonment risk; opaque manifest config; harder to satisfy Play declaration form (you must describe what your code does, not what a plugin's code does) | For prototype only; rewrite in Kotlin for production manifest clarity |
| Asking for all permissions in onboarding upfront | Single clear "setup" flow | Drops onboarding completion 30–50%; battery-opt + a11y + usage-stats + notifications is too many Settings hand-offs in a row | Never for a consumer app |
| Skipping `BOOT_COMPLETED` receiver because "it's a daily-use app" | One less manifest entry | After every reboot, foreground service is dead until next manual app open; streak rollover misses; reminders fail | Never |
| Using server time / NTP without a backend | More accurate tampering detection | Adds network dependency; conflicts with the local-only privacy stance | Never for this product (privacy is core) — use boot-monotonic clock instead |

---

## Integration Gotchas

Common mistakes when connecting to platform APIs.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| **UsageStatsManager** | Querying `queryAndAggregateUsageStats(now-1h, now)` and trusting the totals | Buckets are time-window aggregates, not point-in-time. For "right now" use `queryEvents`, not bucket totals. For dashboard use `INTERVAL_DAILY` and accept ~minutes of staleness. |
| **UsageStatsManager + Android R+** | Querying when device is locked → returns null silently | Wrap calls in try/catch; treat null as "data unavailable, retry later" |
| **AccessibilityService manifest config** | Subscribing to all event types ("just in case") | Subscribe ONLY to `typeWindowStateChanged` for foreground-app detection. Subscribing broader = battery drain + Play Store reviewer suspicion |
| **MethodChannel (Flutter ↔ Android)** | Returning `UsageStats` objects directly across the channel | MethodChannel only supports primitives, lists, maps. Serialize to `Map<String, Object>` on the Android side. |
| **MethodChannel for high-frequency events** | Posting every a11y event from native → Flutter for processing | Cross-channel calls are expensive (serialize + main-thread hop). Filter on Android side; only post `{packageName, isBlocked}` events when blocked-app match occurs. |
| **Foreground service notification (API 33+)** | Forgetting to declare `foregroundServiceType` | Required since Android 14. For our case: `dataSync` or `specialUse` (with `<property name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" value="..."/>`). |
| **`SYSTEM_ALERT_WINDOW`** | Adding to manifest "in case we need overlays" | Don't add unless used; Play Store flags it. Use Activity-based pause screen instead. |
| **`QUERY_ALL_PACKAGES`** | Adding to fetch the user-installed app list (for the not-to-do picker) | Play Store policy restricts `QUERY_ALL_PACKAGES`; declare in Play Console. Alternative: `<queries>` element in manifest with specific known packages, plus `LAUNCHER` intent filter query for browsable apps. |

---

## Performance Traps

Patterns that work at small scale but fail with normal real-world use.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Querying UsageStatsManager `INTERVAL_DAILY` for the past 90 days on every dashboard open | Slow dashboard, jank | Cache aggregated daily totals in local DB; only fetch the new "today" bucket; backfill on a worker | After ~30 days of usage |
| Logging every a11y event to local DB | DB bloat (1000+ rows/day), slow streak queries | Filter at the service: only log "blocked app foregrounded" events (rare); aggregate to daily totals at midnight | After ~2 weeks of heavy use |
| MethodChannel call from Dart on every UI rebuild to fetch "is blocked app currently in foreground" | UI jank, battery drain | Push state from native side via `EventChannel`; Flutter subscribes once | Even at 1 user — first day |
| Re-querying UsageStatsManager from Flutter UI thread for the dashboard | UI freeze for 100ms+ on slow devices | Move query to background isolate or native thread; cache result | Low-end Android (Go edition) immediately; mid-tier Android within 2 weeks of data |
| Computing streak by scanning all historical events on every check | Slow as data grows | Materialize streak as a derived value; update on event, not on read | After ~30 days |
| Pause-screen Activity creating fresh Flutter engine on every launch | 300–800ms cold-start; user already past the impulse moment | Keep pause Activity native (Kotlin + Compose or a simple XML layout). Don't load Flutter for this critical-path screen. | Even at 1 user — first day |

---

## Security & Privacy Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing the user's not-to-do list, screen-time data, and check-ins in plain SQLite without encryption | If device is shared / stolen, anyone can read sensitive habit data | Use `EncryptedSharedPreferences` for keys, SQLCipher (or Android Keystore-derived key + Room with field-level encryption) for the DB. Document the encryption choice. |
| Using `ADB`-readable file paths (`/sdcard/...`) for any data | App data leaves sandbox | Always use `getFilesDir()` / `getDatabasePath()` (internal storage); never request `READ_EXTERNAL_STORAGE` |
| Telemetry/crash-reporting SDK that ships data off-device | Contradicts "100% on-device" privacy stance — Play Store Data Safety form must disclose; users who chose this app for privacy will churn on detection | Use no SDK, OR an opt-in crash reporter that's off by default (e.g., Sentry with explicit toggle, NOT auto-init). Document as anti-feature in PROJECT.md (already there). |
| Logging the user-installed app list to logcat or a debug file | App list = sensitive (reveals dating apps, gambling apps, etc.) | Never log package names in production builds. Strip with ProGuard. |
| Backup including DB to Google Drive auto-backup | Habit data leaks to cloud | Set `android:allowBackup="false"` and `android:fullBackupContent="@xml/backup_rules"` excluding the habit DB |
| Pause-screen Activity not handling lock-screen visibility | If phone is unlocked-on-lockscreen-shortcut to blocked app, pause screen may show *under* lockscreen on some OEMs | Set `setShowWhenLocked(true)` and `setTurnScreenOn(true)` correctly; test |
| Accessibility service reading text content of windows (because plugin defaults pull all event types) | Massive privacy red flag for Play review; subjects user's keystrokes/messages to your process | Set service config to *only* `eventTypes="typeWindowStateChanged"` and `notificationTimeout` reasonable; do NOT set `flagRequestFilterKeyEvents`, `canRetrieveWindowContent`, or `flagRequestTouchExplorationMode` |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Pause screen takes 1+ seconds to appear | User has already started scrolling; pause screen feels punitive ("I was already in the app, why are you stopping me?") | Native (non-Flutter) pause Activity, sub-300ms target. Test on low-end devices. |
| Cooldown timer that silently auto-dismisses | User picks 5 min, forgets, doesn't know if they "won" | Audible/haptic gentle confirmation + "Take 5 mins back" stat counter |
| Hard wall in the pause flow ("you can't continue") | Contradicts the "self-disciplined adults" wedge; users uninstall | Always provide a "use anyway" button; the pause IS the intervention, not the block |
| Streak break with no explanation | User feels punished by an opaque system | Always show *why*: "Streak broke because you used Instagram for 12 minutes (your threshold: 5 min)." |
| Onboarding dumps all 4 permission requests up front | High abandonment | Earn each permission contextually (Pitfall 3) |
| Making the user manually pick from 200+ apps to build their not-to-do list | Decision fatigue → doesn't finish setup | Offer a curated starter set ("Common time-sinks: Instagram, TikTok, X, Reddit, YouTube") as one-tap-each, plus search |
| Daily check-in popup interrupting the user mid-task | User dismisses, churns | Fire as notification at user-chosen time; tapping opens check-in; never modal-overlay |
| Showing only "you used Instagram for 47m today" without comparison | Number means nothing | Compare to user's own past week; flag delta from yesterday |
| Asking for accessibility before the user has added their first not-to-do app | Permission-shock, no clear "why" | Gate the a11y prompt behind "I want to soft-block X" — the demand creates the rationale |

---

## "Looks Done But Isn't" Checklist

- [ ] **Pause screen:** Often missing **sub-300ms cold start** — verify with a stopwatch on a real low-end device, not the emulator. Verify it appears even when app process was previously killed.
- [ ] **Pause screen:** Often missing **back-button handling** — does pressing Back dismiss the pause screen *or* exit the blocked app? Define and test the answer.
- [ ] **Streak:** Often missing **midnight rollover when phone is off all night** — verify by setting clock back, killing app, advancing clock, opening app: does it roll forward correctly?
- [ ] **Streak:** Often missing **DST transition handling** — test by manually setting time to a DST boundary; verify 23h day and 25h day both work.
- [ ] **Streak:** Often missing **timezone change handling** — test by changing timezone +5h, then -10h.
- [ ] **Streak:** Often missing **clock-tampering detection** — set device time forward 24h; does the app trust it?
- [ ] **Onboarding:** Often missing **return-from-Settings auto-advance** — verify each permission step auto-advances when granted, doesn't require manual "Continue" tap.
- [ ] **Onboarding:** Often missing **graceful "skip" handling** — what does the app do if user denies a11y? Is the dashboard still useful?
- [ ] **Background reliability:** Often missing **post-OTA verification** — simulate by changing `Build.FINGERPRINT` mock; does the app re-prompt for permissions?
- [ ] **Background reliability:** Often missing **post-reboot verification** — actually reboot a test device; does tracking resume in <2 min after unlock?
- [ ] **Background reliability:** Often missing **OEM kill recovery** — install on a real Xiaomi or Samsung; leave overnight; does it still work in the morning?
- [ ] **Permissions:** Often missing **a11y disabled detection** — toggle a11y off in Settings; does the app show the "tracking offline" banner on next open?
- [ ] **Permissions:** Often missing **battery-opt revoked detection** — same.
- [ ] **Notifications (Android 13+):** Often missing **manual `POST_NOTIFICATIONS` runtime request** — system does NOT auto-prompt; you must call `requestPermissions`.
- [ ] **Foreground service (Android 14+):** Often missing **`foregroundServiceType` declaration** — won't start otherwise.
- [ ] **Play Store readiness:** Often missing **filled-in Permission Declaration Form** for a11y — write before submission, not after rejection.
- [ ] **Play Store readiness:** Often missing **`isAccessibilityTool=false`** explicitly set.
- [ ] **Play Store readiness:** Often missing **`allowBackup="false"`** for sensitive on-device data.
- [ ] **Privacy:** Often missing **Data Safety form** matching the actual code — Google now does ML cross-checks.
- [ ] **Pause overlay decision:** Often missing **explicit choice between Activity-launch and `SYSTEM_ALERT_WINDOW`** — document in architecture.

---

## Recovery Strategies

When pitfalls occur despite prevention.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Play Store rejects a11y declaration | LOW–MEDIUM | Re-write declaration with literal mechanical description; resubmit. Have a closed-track build ready as A/B. If app already published and removed: respond to appeal within 7 days. |
| Service killed by Xiaomi/Huawei in production | MEDIUM | Ship in-app OEM-aware "fix it" guide; route affected users to manufacturer-specific battery whitelist. Add health-check screen to make state visible. |
| User reports streak broken after timezone change | LOW (data) / MEDIUM (trust) | Add forensic log of clock/timezone changes; restore-from-events option that recomputes streak from raw event data |
| Onboarding completion <50% in beta | MEDIUM | Re-sequence permission asks; add animated guides for each Settings screen; add return-detection auto-advance |
| Notification permission denied at 80% in beta | MEDIUM | Add custom rationale screen *before* system dialog; defer ask until after first not-to-do added |
| Pause screen latency >1 sec | MEDIUM–HIGH | Switch from Flutter Activity to native Kotlin Activity for pause path; pre-warm if possible |
| User figures out clock-tampering bypass and complains | LOW (philosophical, not technical) | Implement boot-monotonic clock detection; mark suspect days with asterisk; lean into "honest streaks for self-disciplined adults" framing |
| Foreground service push to Restricted bucket | MEDIUM | Audit wakelock usage; reduce poll frequency; remove unused background work |
| App rejected for `QUERY_ALL_PACKAGES` | LOW | Switch to `<queries>` element + `LAUNCHER` intent filter; document in Play Console |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| #1 a11y declaration rejection | Phase 1 (architecture/manifest) + Phase N (pre-launch) | Closed-track Play submission passes; declaration form in repo as `docs/play-declaration.md` |
| #2 OEM battery killers | Phase 3 (background reliability) | Real-device overnight test on Xiaomi + Samsung; in-app health check exists |
| #3 PACKAGE_USAGE_STATS onboarding cliff | Phase 2 (onboarding) | Beta-tester completion rate >70% from install to first dashboard view |
| #4 a11y service lifecycle misuse | Phase 1 (architecture) | "Service is passive trigger" decision documented; graceful-degradation mode works without a11y |
| #5 Wrong tool choice (FGS vs a11y vs WorkManager) | Phase 1 (architecture) | Architecture doc has explicit table; latency measured at <500ms in Phase 3 |
| #6 Doze + Standby Buckets | Phase 3 (background) + Phase 4 (reminders) | `dumpsys deviceidle force-idle` test; reminder fires within 5 min of scheduled time |
| #7 Battery-opt exemption rejection | Phase 1 (manifest) + Phase N (pre-launch) | Justification copy in declaration matches in-app rationale |
| #8 SYSTEM_ALERT_WINDOW restrictions | Phase 3 (interception) | Activity-launch pause screen prototyped; no `SYSTEM_ALERT_WINDOW` in manifest |
| #9 Streak bypass tactics | Phase 4 (streak + check-in) | Clock-tampering test passes; "incomplete day" flag exists; uninstall-resets-streak documented |
| #10 Notification permission denied | Phase 2 (onboarding) + Phase 4 (reminders) | Custom rationale screen exists; in-app fallback banner if denied |

**Phase ordering implication:** Phase 1 must lock in architecture *and* Play Store declaration before Phase 2 starts on UI. Phases 2–4 must each include a "test on a real Xiaomi/Samsung overnight" gate, not a Pixel-only test.

---

## Sources

- [Use of the AccessibilityService API — Play Console Help](https://support.google.com/googleplay/android-developer/answer/10964491?hl=en) — HIGH confidence; canonical Google policy doc
- [Don't Kill My App](https://dontkillmyapp.com/) — HIGH confidence; community-maintained reference for OEM background-process behavior
- [Don't Kill My App — Xiaomi](https://dontkillmyapp.com/xiaomi)
- [Optimize for Doze and App Standby — Android Developers](https://developer.android.com/training/monitoring-device-state/doze-standby) — HIGH
- [App Standby Buckets — Android Developers](https://developer.android.com/topic/performance/appstandby) — HIGH
- [Notification runtime permission — Android Developers](https://developer.android.com/develop/ui/views/notifications/notification-permission) — HIGH
- [UsageStatsManager — Android Developers](https://developer.android.com/reference/android/app/usage/UsageStatsManager) — HIGH
- [Create an accessibility service — Android Developers](https://developer.android.com/guide/topics/ui/accessibility/service) — HIGH
- [Behavior changes: all apps (Android 12) — Android Developers](https://developer.android.com/about/versions/12/behavior-changes-all) — HIGH
- [Changes to foreground services — Android Developers](https://developer.android.com/develop/background-work/services/fgs/changes) — HIGH
- [Permissions and APIs that Access Sensitive Information — Play Console](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en) — HIGH
- [What Android OEMs do to background apps, and the 11 layers I built to survive it — DEV.to](https://dev.to/stoyan_minchev/what-android-oems-do-to-background-apps-and-the-11-layers-i-built-to-survive-it-28bb) — MEDIUM (single dev's experience but corroborates dontkillmyapp)
- [Beyond Doze: Building Reliable Background Execution on Modern Android — ProAndroidDev](https://proandroiddev.com/beyond-doze-building-reliable-background-execution-on-modern-android-including-oem-realities-5fa0a6e05672) — MEDIUM
- [Google Play policy about use of the Accessibility API — Orange OMA](https://orangeoma.zendesk.com/hc/en-us/articles/4407888308242) — MEDIUM (third-party summary of Google policy)
- [Inquiry About Policy Compliance for an App with App Usage Blocking Features — Play Developer Community](https://support.google.com/googleplay/android-developer/thread/319193084) — MEDIUM (community Q&A)
- [Technical details of App Gatekeeper v1.1 — TimelessSky](http://www.timelesssky.com/blog/technical-details-of-app-gatekeeper-version-1-1) — MEDIUM (independent analysis of UsageStatsManager polling latency, ~2.5s system lag)
- [usage_stats Flutter package](https://pub.dev/packages/usage_stats) — MEDIUM
- [flutter_accessibility_service Flutter package](https://pub.dev/packages/flutter_accessibility_service) — MEDIUM
- [How to Build a Streaks Feature — Trophy](https://trophy.so/blog/how-to-build-a-streaks-feature) — MEDIUM (general streak-design wisdom incl. timezones/DST)
- [How Kids Hack iOS Parent Controls — Cloudwards](https://www.cloudwards.net/how-to-hack-screen-time/) — LOW (popular-press article documenting common bypass tactics; corroborated across multiple similar pages)
- [Android Permission Security Flaw — Check Point Blog](https://blog.checkpoint.com/research/android-permission-security-flaw/) — MEDIUM (SYSTEM_ALERT_WINDOW abuse statistics)

---
*Pitfalls research for: Flutter+Android screen-time tracker / soft-blocker (UsageStatsManager + AccessibilityService)*
*Researched: 2026-04-26*
