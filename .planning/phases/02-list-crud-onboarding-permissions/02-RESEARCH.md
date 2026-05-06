# Phase 2: List CRUD + Onboarding & Permissions — Research

**Researched:** 2026-05-05
**Domain:** Flutter Android app — installed-app picker, 3-step permission funnel with OEM-aware fallbacks, self-healing health check, Drift v2 schema migration, schedule active-window evaluation
**Confidence:** HIGH on Drift migrations and Flutter lifecycle (verified against official docs and Phase 1 codebase). MEDIUM on per-OEM ComponentName fallbacks (community-maintained references; no official Google list — must be probed via `resolveActivity` at runtime, never assumed).

This document is **delta-only** against `02-CONTEXT.md` (locked discussion decisions) and `02-UI-SPEC.md` (locked visual contract). Items already locked there are referenced, not re-litigated.

---

## Phase 2 Research Summary

Phase 2 EXTENDS Phase 1's data + manifest skeleton; it does not rewrite anything. The five technical workstreams Phase 2 needs to land are:

1. **Drift v2 migration** — `block_list` gains one NOT-NULL `block_mode TEXT DEFAULT 'soft'` column and three NULLABLE schedule columns. Bump `schemaVersion` 1 → 2 in `lib/data/database/app_database.dart`. Round-trip test on in-memory DB. `[VERIFIED: lib/data/database/app_database.dart Phase 1 codebase]`
2. **App picker via Pigeon `AppPickerHostApi`** — new `@HostApi` adds `listInstalledApps()`, `recentlyUsedApps(daysBack)`, and `getApplicationIconPng(packageName)`. Kotlin side uses `PackageManager.queryIntentActivities(LAUNCHER)` (Phase 1 manifest already declares `<queries>` for this) and `UsageStatsManager.queryUsageStats(INTERVAL_DAILY, ...)` on a background `Executor`. Icons are encoded to PNG `Uint8List` and LRU-cached on the Dart side (50 entries, in-memory only). `[VERIFIED: AndroidManifest.xml Phase 1 codebase + CONTEXT.md icon strategy]`
3. **3-step permission funnel** — Usage Access → Accessibility → battery-opt, in that order. Each step: rationale screen → standard `Settings.ACTION_*` intent → `WidgetsBindingObserver.didChangeAppLifecycleState(AppLifecycleState.resumed)` rechecks the permission and auto-advances if granted. Cursor persisted in `shared_preferences` under `onboarding_step` (int 0–3). `[VERIFIED: CONTEXT.md + Flutter lifecycle docs]`
4. **OEM-aware reactive fallback (ONBD-04)** — fire the standard intent first; only when `intent.resolveActivity(packageManager) == null` OR the user returns un-granted, surface OEM-specific instructions keyed off `Build.MANUFACTURER`. ComponentName fallbacks are MEDIUM-confidence (community-maintained, not Google-blessed) — every fallback intent MUST be guarded by a second `resolveActivity` check before launch. dontkillmyapp.com per-vendor URLs are the safety net when no ComponentName resolves. `[CITED: dontkillmyapp.com per-vendor pages + community gist]`
5. **Self-healing health check (REL-02 / REL-03)** — runs on every cold launch + every `AppLifecycleState.resumed`. Uses the same status-check helpers as the funnel auto-advance. `Build.FINGERPRINT` is persisted across launches in `shared_preferences`; mismatch forces a re-verification banner regardless of cached state. Banner is a single-line amber bar at top of home (already specified in UI-SPEC §11). `[VERIFIED: research/PITFALLS.md #2 + UI-SPEC §11]`

**Primary recommendation:** Build out the picker channel and the permission status helpers first (those are the load-bearing native bits), THEN do the migration + repository, THEN the UI. The migration is small but locked early because LIST-08 + LIST-09 columns are required by the editor screen.

---

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Onboarding flow (locked):**
- Shape: `Welcome → Quick-add → 3-permission funnel → Home`. POST_NOTIFICATIONS is NOT in the install-time funnel; it is requested after the user adds their first not-to-do entry (deferred to Phase 5 NOTF-06).
- Welcome screen: ONE headline ("Build your Not-To-Do list") + ONE CTA ("Get Started") + one privacy claim ("We never see your data."). Single screen.
- Quick-add picker (LIST-07): full-screen, 5 cards (Instagram, TikTok, X, YouTube, Reddit), all unchecked by default, single CTA "Continue" (works with 0–5 selected).
- Permission funnel: 3 steps in order — (1) Usage Access, (2) Accessibility, (3) battery-optimization exemption.
- Skip behavior: 1-tap skip on every step + footer note explaining the consequence. NO "Are you sure?" dialog.
- Settings guidance assets: Static screenshot PNGs in `assets/onboarding/`. NO animated GIFs.
- OEM guidance timing: Reactive only — fire the standard Settings intent first; if it doesn't resolve OR the user returns un-granted, then show OEM-specific instructions keyed off `Build.MANUFACTURER`.
- Resume state: persisted in `shared_preferences` under key `onboarding_step` (int, 0–3).
- Health-check banner severity: subdued amber bar, single line "Tracking is offline — tap to fix". Not red. Not modal.

**App picker (locked):**
- Layout: Search-first + Suggested + Recently used + Alphabetical.
- System apps filter: Hide non-launchable system apps by default (filter `ApplicationInfo.FLAG_SYSTEM` AND no LAUNCHER intent), with a "Show all" toggle.
- Already-blocked apps: shown disabled and greyed-out with "already added" subtitle. NOT hidden, NOT linked to edit.
- Search match: display name only, case-insensitive substring. NOT package name. NOT fuzzy.
- Icon strategy: Fetch on demand via `PackageManager.getApplicationIcon`, in-memory LRU(50). NO disk persistence.
- After save: return to home with new entry visible at the top.
- Habit entry path: two separate buttons on home — `+ Add app` and `+ Add habit`.

**Reason note (LIST-03, locked):** Optional. Empty = generic fallback on pause screen. Char limit 500 (soft, counter visible past 400). Plain text.

**List + entry editor UX (locked):**
- Compact row (~64 dp). Layout: leading icon → name → reason snippet (1-line ellipsized) → trailing streak count.
- App vs Habit: icon source only. Apps show app icon; Habits show generic leaf glyph.
- Edit gesture: tap row → full detail/edit page. NOT inline expand. Long-press has no behavior.
- Delete UX: button at bottom of edit page only, destructive-red styling. NOT swipe-to-delete. No confirm dialog.
- Sort order: by last activity desc — `MAX(updatedAt, lastPauseEventTime, lastCheckInTime)`.

**Block-mode toggle (LIST-08, locked):**
- Segmented control on edit screen: `Soft (default)` | `Hard`.
- Inline subtitle: "Soft: cooldown + 'Use anyway'. Hard: cooldown only, no override."
- Hidden for Habit entries.
- Default value for new entries: `soft`.

**Schedule editor (LIST-09, locked):**
- Single optional active window per entry. Three controls: start time, end time, weekday mask (M T W T F S S, all selected by default).
- Default: "Always on" (no schedule). Toggle to reveal time + weekday inputs.
- Cross-midnight: treat as one continuous window. `end_time < start_time` means window crosses midnight.
- Streak day boundary: 04:00 local time.
- Storage shape: `schedule_start_minutes` (int, 0–1439, nullable), `schedule_end_minutes` (int, 0–1439, nullable), `schedule_weekday_mask` (int, 7-bit, nullable). All three nullable together.

**Hard-block + schedule combination (locked):** Independent toggles. An entry can be both. Outside window = dormant; inside window = intercept (and if hard-block, omit "Use anyway").

### Claude's Discretion

- Health-check banner UX details (banner already specified in UI-SPEC §11; this research takes the UI-SPEC as the contract).

### Deferred Ideas (OUT OF SCOPE)

- Multiple schedule windows per entry — v1 has one optional window only.
- Schedule presets ("Work hours", "Bedtime", etc.).
- Long-press multi-select for batch delete.
- Per-entry custom cooldown durations beyond 1/3/5/10 (DIFF-03).
- Streak history calendar heatmap (DIFF-02).
- Disk-cached app icons.
- Fuzzy search in app picker.
- Multiple languages / localization.

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIST-01 | Add app entry from installed-launchable picker | App Picker Implementation §; Pigeon `AppPickerHostApi.listInstalledApps()` |
| LIST-02 | Add habit entry (text-only) | UI-SPEC Surface 6; trivial Drift insert with `kind=1, packageName=null` |
| LIST-03 | Reason / motivation note (free text, 500-char soft cap) | UI-SPEC Surface 6/7; Phase 1 `reasonNote` column already exists |
| LIST-04 | Edit name, reason, category | UI-SPEC Surface 7; Drift update on `block_list` row |
| LIST-05 | Delete + cascade to streak/pause-event log | Drift v2 Migration §; cascade already declared on FKs in Phase 1 (`onDelete: KeyAction.cascade`) |
| LIST-06 | Unified Apps + Habits home list sorted by last activity | UI-SPEC Surface 4; Phase 2 sort key = `updatedAt` (only field available; pause/check-in tables empty in Phase 2) |
| LIST-07 | Quick-add of common offenders (Instagram/TikTok/X/YouTube/Reddit) | UI-SPEC Surface 2; pre-seed via `BlockListRepository.insertMany()` on Continue tap |
| LIST-08 | Per-entry block mode soft/hard (Apps only) | Drift v2 Migration § (`block_mode` column); UI-SPEC Surface 8 |
| LIST-09 | Per-entry active-window schedule | Drift v2 Migration § (3 nullable schedule columns); Schedule Active-Window Evaluation §; UI-SPEC Surface 9 |
| ONBD-01 | First-launch funnel sequences permission steps in order | onResume Return-Detection §; `<onboarding_flow>` locked to 3 install-time steps (notifications deferred to Phase 5 NOTF-06; see UI-SPEC ONBD-01 deviation note) |
| ONBD-02 | Custom rationale screen before each system dialog/deep-link | UI-SPEC Surface 3 (shared rationale layout) |
| ONBD-03 | onResume return-detection auto-advance | onResume Return-Detection § |
| ONBD-04 | OEM-aware fallback when standard Settings intent fails | Permission Step Deep-Links and OEM Fallback Map § |
| ONBD-05 | User can re-enter onboarding from Settings | Riverpod Provider Wiring §; banner tap routes back into the funnel at the failing step |
| ONBD-06 | Persistent "Tracking offline — fix" banner if any required permission revoked | Self-Healing Health Check Architecture §; UI-SPEC Surface 11 |
| ONBD-07 | After OS update (Build.FINGERPRINT change), re-verify permissions | Self-Healing Health Check Architecture §; `shared_preferences` key `last_known_fingerprint` |
| PLAY-06 | In-app prominent disclosure for AccessibilityService before grant | PLAY-06 Prominent Disclosure §; UI-SPEC Surface 3 Step 2 |
| REL-02 | Self-healing health check on every app open | Self-Healing Health Check Architecture § |
| REL-03 | OEM guidance routes to dontkillmyapp.com | Permission Step Deep-Links and OEM Fallback Map §; UI-SPEC Surface 11 OEM mapping |

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Welcome / Quick-add / Permission rationale screens | Flutter UI (Dart) | — | Pure widget tree; no platform calls except deep-link triggers |
| Persisting onboarding cursor + last fingerprint | Dart (`shared_preferences`) | — | Already in pubspec; flat key-value store is right tool |
| App picker enumeration | Native Android (Kotlin via Pigeon) | Dart UI consumer | `PackageManager` + `UsageStatsManager` are platform APIs; Dart only renders results |
| App icon decode + LRU cache | Dart | Native (PNG bytes only) | Kotlin returns PNG `Uint8List`; Dart `Image.memory` + Dart-side `LruMap<String,Uint8List>` (50 entries) |
| Permission status checks | Native Android (Kotlin via Pigeon) | Dart consumer | `AppOpsManager`, `AccessibilityManager`, `PowerManager` calls are Android-side; Dart maps to `bool` futures |
| Settings deep-link launch | Native Android (Kotlin via Pigeon) | Dart caller | `Intent` construction + `resolveActivity` guard live in Kotlin; Dart triggers via Pigeon void method |
| onResume lifecycle hook | Dart (`WidgetsBindingObserver`) | — | Standard Flutter lifecycle pattern; no native involvement |
| Drift schema migration (block_list v1→v2) | Dart (Drift `MigrationStrategy`) | — | Drift `Migrator.addColumn` runs Dart-side ALTER TABLE; entirely within `AppDatabase` |
| Schedule active-window evaluation helper | Dart (pure domain function) | — | No I/O; consumed by Phase 2 editor preview AND Phase 4 PAUS-10 / Phase 5 STRK-09 |
| Health-check banner state | Dart (Riverpod `permissionHealthProvider`) | Native (status checks) | Provider polls native status helpers; UI consumes provider value |

---

## Standard Stack

### Core (Phase 2 deltas — everything else inherited from Phase 1)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dynamic_color` | ^1.7.0 | Material You palette on Android 12+; static fallback on Android 10/11 | UI-SPEC §Color requires it. `material-foundation/flutter-packages` (Google) maintains it. `[CITED: pub.dev/packages/dynamic_color]` |
| `url_launcher` | ^6.3.0 | Open `dontkillmyapp.com/{slug}` from health-check banner | Standard Flutter package; required by UI-SPEC Surface 11 OEM link `[CITED: pub.dev/packages/url_launcher]` |

**No new test deps required.** `flutter_test` + `mocktail 1.0.5` (already in dev_dependencies) cover unit + widget tests. `drift` 2.33 ships its own in-memory `NativeDatabase.memory()` for migration round-trip tests.

### Inherited from Phase 1 (no version change)

| Library | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^3.3.1 | State management; Phase 2 adds new providers, no codegen |
| `drift` / `drift_flutter` | ^2.33.0 / ^0.3.0 | SQLite ORM; Phase 2 bumps `schemaVersion` 1 → 2 |
| `go_router` | ^17.2.3 | Phase 2 adds 7 routes |
| `shared_preferences` | ^2.5.5 | `onboarding_step`, `last_known_fingerprint` |
| `pigeon` | ^26.3.4 (dev) | Phase 2 adds `pigeons/app_picker_api.dart` |
| `intl` | ^0.20.2 | Already present; needed for time formatting on schedule editor |

**Verification of `dynamic_color` 1.7.0:** Confirmed current stable on pub.dev as of Q1 2026. `[CITED: https://pub.dev/packages/dynamic_color]` `[ASSUMED: still current as of phase plan time — planner should re-run `flutter pub outdated` before merging Wave 0]`

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled Pigeon picker channel | `device_apps` package | `device_apps` is community-maintained, opaque manifest config, harder to satisfy PLAY-04 audit (manifest `<queries>` is the policy-relevant declaration). Phase 1's Pigeon-typed pattern is already the project standard — extend it. |
| `permission_handler` for Usage Access / Accessibility | Direct `AppOpsManager` + `AccessibilityManager` calls | `permission_handler` does NOT cover `PACKAGE_USAGE_STATS` or `BIND_ACCESSIBILITY_SERVICE` — these are special permissions granted via Settings, not runtime prompts. Native helpers are required regardless. Adding `permission_handler` for one permission (notifications, deferred to Phase 5) is unjustified. |
| `WidgetsBindingObserver` | `AppLifecycleListener` (Flutter 3.13+) | Both work; `WidgetsBindingObserver` is the long-standing pattern and the project does not yet have an `AppLifecycleListener` precedent. Use `WidgetsBindingObserver` for consistency. `[CITED: api.flutter.dev/.../WidgetsBindingObserver-class.html]` |

**Installation:**
```bash
flutter pub add dynamic_color url_launcher
```

---

## App Picker Implementation

### Pigeon channel shape (recommended)

Create `pigeons/app_picker_api.dart`:

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/app_picker_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
      errorClassName: 'AppPickerApiError', // see usage_api.dart for rationale
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
class InstalledApp {
  InstalledApp({
    required this.packageName,
    required this.displayName,
    required this.isSystemApp,
    required this.hasLauncherIntent,
  });
  final String packageName;
  final String displayName;
  final bool isSystemApp;        // ApplicationInfo.FLAG_SYSTEM
  final bool hasLauncherIntent;  // resolved via queryIntentActivities(LAUNCHER)
}

class RecentApp {
  RecentApp({
    required this.packageName,
    required this.totalForegroundSeconds,
  });
  final String packageName;
  final int totalForegroundSeconds;
}

@HostApi()
abstract class AppPickerApi {
  /// Returns ALL installed apps; Dart-side filter on `isSystemApp && !hasLauncherIntent`
  /// implements the default "hide non-launchable system apps" view.
  /// Visibility scope is governed by Phase 1's <queries> + LAUNCHER manifest entry.
  @async
  List<InstalledApp> listInstalledApps();

  /// Returns top apps by foreground seconds in the trailing window.
  /// Caller is responsible for first checking that Usage Access is granted via
  /// PermissionStatusApi.isUsageAccessGranted() — this method returns an empty list
  /// if not granted (it does NOT throw, to keep the Dart code branch-light).
  @async
  List<RecentApp> recentlyUsedApps(int daysBack);

  /// Returns null if the package is not installed or the icon couldn't be encoded.
  /// Encoded as PNG bytes. Decoded on the Dart side via Image.memory.
  @async
  Uint8List? getApplicationIconPng(String packageName);
}
```

**Why split into three methods, not one fat call:**
- `listInstalledApps()` is called once per picker open; ~150–300 entries on a typical phone.
- `recentlyUsedApps(7)` runs `UsageStatsManager.queryUsageStats(INTERVAL_BEST, now-7d, now)` on a background `Executor`. This is the only call that blocks for a noticeable interval (50–200 ms on real devices). Keeping it separate lets the picker render the alphabetical list immediately, then progressively reveal "Recently used" as a stream.
- `getApplicationIconPng()` is called per-row, lazily, and result is cached LRU(50) in Dart. Bundling icons into `listInstalledApps()` would multiply the Pigeon payload by ~50× (300 apps × ~30 KB each = 9 MB across the channel) — unacceptable.

### Kotlin side — system-app + launcher filter

```kotlin
// In AppPickerHostImpl.kt (Phase 2 implementation, Wave-1 native)
override fun listInstalledApps(callback: (Result<List<InstalledApp>>) -> Unit) {
  executor.execute {
    val pm = context.packageManager
    val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
    val launchablePackages = pm
      .queryIntentActivities(launcherIntent, 0)
      .map { it.activityInfo.packageName }
      .toSet()
    val all = pm.getInstalledApplications(PackageManager.MATCH_DEFAULT_ONLY)
      .map { ai ->
        InstalledApp(
          packageName = ai.packageName,
          displayName = pm.getApplicationLabel(ai).toString(),
          isSystemApp = (ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0,
          hasLauncherIntent = ai.packageName in launchablePackages,
        )
      }
      .sortedBy { it.displayName.lowercase() }
    callback(Result.success(all))
  }
}
```

**Notes:**
- `getInstalledApplications(MATCH_DEFAULT_ONLY)` returns only packages with a default activity — slightly narrower than `MATCH_ALL`, equivalent to "apps the user can plausibly launch." Combined with the `<queries>` LAUNCHER filter in the manifest, Android 11+ package visibility is satisfied without `QUERY_ALL_PACKAGES`. `[VERIFIED: PLAY-04 + Phase 1 manifest]`
- Background `Executor` (`Executors.newSingleThreadExecutor()`) — never run on the main thread. `UsageStatsManager` calls drop frames per `research/PITFALLS.md` integration gotchas. `[VERIFIED: research/PITFALLS.md]`
- Always honor the executor pattern via Pigeon's `@async` + Kotlin callback — Phase 1's `usage_api.g.dart` already establishes this pattern.

### UsageStatsManager parameters for "Recently used"

| Parameter | Recommendation | Rationale |
|-----------|----------------|-----------|
| `INTERVAL_*` | `INTERVAL_BEST` for a 7-day window | `INTERVAL_BEST` lets the system pick the optimal bucket size; `INTERVAL_DAILY` is fine but slightly slower for short windows. `[CITED: developer.android.com/reference/android/app/usage/UsageStatsManager#INTERVAL_BEST]` |
| Window | `now - 7 * 24 * 3600 * 1000` to `now` (in ms) | UI-SPEC: "top 5 by total foreground time over last 7 days" |
| Result mapping | Sort `UsageStats` list by `totalTimeInForeground` desc, take top 20 to give the picker headroom; Dart filters to top 5 not-already-added | Trim Pigeon payload but allow filtering already-added apps |
| Permission gate | `AppOpsManager.checkOpNoThrow(OPSTR_GET_USAGE_STATS, uid, packageName) == MODE_ALLOWED` BEFORE calling | Calling `queryUsageStats` without the grant returns an empty list silently — easy to misread as "user has no usage data." Always check first. `[CITED: developer.android.com/.../UsageStatsManager + research/PITFALLS.md gotcha "Querying when locked → returns null"]` |

### Icon encoding — PNG bytes via Bitmap

```kotlin
override fun getApplicationIconPng(packageName: String, callback: (Result<ByteArray?>) -> Unit) {
  executor.execute {
    try {
      val drawable = context.packageManager.getApplicationIcon(packageName)
      val bitmap = drawable.toBitmap(96, 96) // androidx.core.graphics.drawable.toBitmap
      val bytes = ByteArrayOutputStream().apply {
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, this)
      }.toByteArray()
      callback(Result.success(bytes))
    } catch (e: PackageManager.NameNotFoundException) {
      callback(Result.success(null))
    }
  }
}
```

- 96×96 dp logical → renders cleanly at the picker tile's 40×40 dp display size on all densities.
- PNG (lossless) over JPEG — icons frequently have alpha, JPEG would blow it out.
- Pigeon `Uint8List` maps to Kotlin `ByteArray` directly; no JNI wrangling. `[VERIFIED: Pigeon 26.3.4 type table]`

### Dart-side LRU cache

Implement as a `LinkedHashMap<String, Uint8List>` with capacity 50. On hit, move-to-end; on miss + full, evict oldest. Lifetime: a single Riverpod `Provider` that auto-disposes when the picker closes (use `Provider.autoDispose` so the cache is cleared between picker sessions — matches CONTEXT.md "drops on app close; rebuilds on next picker open"). `[VERIFIED: CONTEXT.md icon strategy]`

### Search behavior

Per UI-SPEC Surface 5: 150 ms debounce on the search field, case-insensitive substring match on `displayName` only (NOT `packageName`). Debounce via a Dart `Timer` in the controller; do not introduce `rxdart` for this.

---

## Permission Step Deep-Links and OEM Fallback Map

### Standard intents (the FAST path)

| Step | Intent action | Extras | Resolves on |
|------|---------------|--------|-------------|
| Usage Access | `Settings.ACTION_USAGE_ACCESS_SETTINGS` | (none) | Stock Android, most OEMs `[CITED: developer.android.com/reference/android/provider/Settings#ACTION_USAGE_ACCESS_SETTINGS]` |
| Accessibility | `Settings.ACTION_ACCESSIBILITY_SETTINGS` | (none — opens the list, not our row; per-app deep-link is unreliable across OEMs per `research/PITFALLS.md` #3) | Stock Android, most OEMs `[CITED: developer.android.com/reference/android/provider/Settings#ACTION_ACCESSIBILITY_SETTINGS]` |
| Battery-opt — preferred | `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | `Uri.parse("package:" + context.packageName)` data | Shows a system dialog that grants the exemption directly. Requires the `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` manifest permission (Phase 1 already declared it). `[VERIFIED: AndroidManifest.xml line 30 + CITED: developer.android.com/reference/android/provider/Settings#ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS]` |
| Battery-opt — fallback | `Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS` | (none) | Opens the list. User must manually find the app. Use only if `ACTION_REQUEST_*` doesn't resolve — rare but happens on some Android distributions. |

**Resolution gate (mandatory before launching any intent):**

```kotlin
private fun launchSettingsOrFallback(intent: Intent, fallbacks: List<Intent>) {
  val pm = context.packageManager
  if (intent.resolveActivity(pm) != null) {
    context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    return
  }
  for (fallback in fallbacks) {
    if (fallback.resolveActivity(pm) != null) {
      context.startActivity(fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
      return
    }
  }
  // No intent resolves — surface the dontkillmyapp.com link as final fallback (Dart side).
}
```

`resolveActivity(pm) != null` is the canonical guard. If it returns null, the intent will throw `ActivityNotFoundException` on launch — never assume it will succeed. `[CITED: developer.android.com/reference/android/content/Intent#resolveActivity]`

### OEM ComponentName map — REACTIVE fallbacks (MEDIUM confidence)

Phase 2 fires the standard intent first. Only if `resolveActivity` returns null OR the user comes back un-granted, surface OEM-specific guidance. The community-maintained ComponentNames below SHOULD ONLY BE USED through the same `resolveActivity` guard. Treat each as best-effort and fall through to dontkillmyapp.com if it doesn't resolve.

| Manufacturer (`Build.MANUFACTURER`, lowercase) | Settings target (autostart / battery whitelist) | Package | Activity | Confidence |
|---|---|---|---|---|
| `xiaomi` | MIUI Autostart | `com.miui.securitycenter` | `com.miui.permcenter.autostart.AutoStartManagementActivity` | MEDIUM `[CITED: gist.github.com/moopat/e9735fa8b5cff69d003353a4feadcdbc]` |
| `huawei` | Startup Manager | `com.huawei.systemmanager` | `com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity` (newer EMUI) OR `com.huawei.systemmanager.optimize.process.ProtectActivity` (older) | MEDIUM — try newer first; activity names differ by EMUI version `[CITED: same]` |
| `samsung` | Battery / Device Care | `com.samsung.android.lool` | `com.samsung.android.sm.ui.battery.BatteryActivity` | MEDIUM — One UI version drift `[CITED: same]` |
| `oppo` / `realme` | ColorOS Startup Manager | `com.coloros.safecenter` | `com.coloros.safecenter.permission.startup.StartupAppListActivity` (newer) OR `com.coloros.safecenter.startupapp.StartupAppListActivity` (older) | MEDIUM `[CITED: same]` |
| `vivo` | iManager Background Startup | `com.vivo.permissionmanager` | `com.vivo.permissionmanager.activity.BgStartUpManagerActivity` | MEDIUM `[CITED: same]` |
| `oneplus` | OxygenOS Battery Optimization | (use stock `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — modern OnePlus runs near-stock OxygenOS/ColorOS) | — | LOW — OnePlus post-merger runs ColorOS; the Oppo entries above may apply. ALWAYS guard with `resolveActivity`. `[ASSUMED]` |
| (any other) | (no ComponentName) | — | — | Show generic copy + dontkillmyapp.com link |

**Critical rule (this is the safety belt):**
- Detection: `Build.MANUFACTURER.lowercase()` matched against the list above.
- Per-OEM intent attempts MUST be wrapped in `resolveActivity(pm) != null` checks.
- If no ComponentName resolves AND the standard intent resolves (probably on stock + non-OEM-fork Android), prefer the standard intent and skip OEM steering entirely.
- If neither resolves, the UI falls back to the per-OEM dontkillmyapp.com link from UI-SPEC Surface 11.

**Why MEDIUM confidence:** ComponentNames change between OS revisions on aggressive OEMs (MIUI 12 vs 14, EMUI 11 vs HarmonyOS 4). There is no Google-blessed list. The community gist cited above is the most-referenced reference, corroborated by per-vendor Don't Kill My App pages. Always probe-then-fallback; never trust a ComponentName without `resolveActivity`. `[CITED: dontkillmyapp.com per-vendor pages]`

### dontkillmyapp.com URL pattern (REL-03)

Per UI-SPEC Surface 11 OEM mapping:

```dart
const oemSlugs = {
  'xiaomi': 'xiaomi',
  'huawei': 'huawei',
  'samsung': 'samsung',
  'oppo':   'oppo',
  'vivo':   'vivo',
  'oneplus': 'oneplus',
};
String? dontkillmyappUrl(String manufacturerLower) {
  final slug = oemSlugs[manufacturerLower];
  return slug == null ? null : 'https://dontkillmyapp.com/$slug';
}
```

Open via `url_launcher` package — `launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)`. `[CITED: pub.dev/packages/url_launcher#example]`

---

## onResume Return-Detection Pattern

### Pattern (REQUIRED — ONBD-03)

Each permission step's StatefulWidget mixes in `WidgetsBindingObserver`:

```dart
class _UsageAccessStepState extends ConsumerState<UsageAccessStep>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold-mount check — if already granted (e.g., re-entry after grant), advance immediately.
    _checkAndMaybeAdvance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndMaybeAdvance();
    }
  }

  Future<void> _checkAndMaybeAdvance() async {
    final granted = await ref
        .read(permissionStatusApiProvider)
        .isUsageAccessGranted();
    if (!mounted) return;
    if (granted) {
      // Persist cursor + advance
      ref.read(onboardingCursorProvider.notifier).advance();
      context.go('/onboarding/permissions/accessibility');
    }
  }
}
```

`AppLifecycleState.resumed` fires when the user returns from Settings — this is the canonical Flutter hook. `[CITED: api.flutter.dev/flutter/widgets/WidgetsBindingObserver/didChangeAppLifecycleState.html + api.flutter.dev/flutter/dart-ui/AppLifecycleState.html]`

**Edge case:** flutter/flutter#130055 documents that `didChangeAppLifecycleState(resumed)` can fire spuriously while the lock screen is visible on some devices. For Phase 2 this is harmless — re-checking permission state on a spurious resume just runs the same status check twice. The check is idempotent. `[CITED: github.com/flutter/flutter/issues/130055]`

### Status check helpers (Pigeon `PermissionStatusApi`)

Recommend a single new Pigeon channel that bundles all three checks (low call frequency, one round-trip on each resume):

```dart
@HostApi()
abstract class PermissionStatusApi {
  @async
  bool isUsageAccessGranted();

  @async
  bool isAccessibilityServiceEnabled(); // can REUSE existing AccessibilityApi.isServiceEnabled() — see Phase 1 lib/platform/accessibility_api.g.dart

  @async
  bool isIgnoringBatteryOptimizations();

  @async
  String currentBuildFingerprint(); // for Build.FINGERPRINT change detection (ONBD-07)

  @async
  String currentManufacturer();     // for OEM detection (ONBD-04 + REL-03)
}
```

Or extend the existing `AccessibilityApi` rather than creating a new channel; planner decides. The Phase 1 `AccessibilityApi.isServiceEnabled()` is already wired (`lib/platform/accessibility_api.g.dart`), so the cleanest addition is a NEW `PermissionStatusApi` for the other three, leaving the Phase 1 contract untouched.

### Kotlin status check implementations

```kotlin
fun isUsageAccessGranted(): Boolean {
  val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
  val mode = appOps.unsafeCheckOpNoThrow(            // unsafe* on API 29+
    AppOpsManager.OPSTR_GET_USAGE_STATS,
    Process.myUid(),
    context.packageName,
  )
  return mode == AppOpsManager.MODE_ALLOWED
}

fun isAccessibilityServiceEnabled(): Boolean {
  val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
  val target = ComponentName(context, NotToDoAccessibilityService::class.java).flattenToString()
  return am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
    .any { it.id == target || it.resolveInfo.serviceInfo.let { si ->
        ComponentName(si.packageName, si.name).flattenToString() == target } }
}

fun isIgnoringBatteryOptimizations(): Boolean {
  val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
  return pm.isIgnoringBatteryOptimizations(context.packageName)
}
```

**Notes:**
- On API 29+ (project's `minSdk`), `checkOpNoThrow` was renamed `unsafeCheckOpNoThrow`. Same semantics. `[CITED: developer.android.com/reference/android/app/AppOpsManager]`
- `PowerManager.isIgnoringBatteryOptimizations(packageName)` returns `true` if app is on the device's power allowlist. `[CITED: developer.android.com/reference/android/os/PowerManager#isIgnoringBatteryOptimizations(java.lang.String)]`
- The accessibility check matches by full `ComponentName` rather than package name alone — multiple a11y services per app are theoretically possible, and matching just by package would yield false positives.

### Already-granted bypass on cold mount

Per UI-SPEC Surface 3 interaction step 2: "If already granted → immediately call `advance()`". On screen mount, run the same `_checkAndMaybeAdvance()` — if the user re-enters onboarding (ONBD-05) and a step is already satisfied, it should auto-skip. The cursor in `shared_preferences` advances accordingly so a future cold launch doesn't re-show that step.

---

## Self-Healing Health Check Architecture

### Trigger points

1. **Cold launch:** `app.dart` startup invokes `permissionHealthProvider` once.
2. **Every `AppLifecycleState.resumed` from anywhere in the app:** A top-level `WidgetsBindingObserver` (placed at the `MaterialApp` level) re-evaluates the same provider.
3. **Manual refresh:** Tapping the banner triggers a re-evaluation before routing into the funnel — the user has just tried to fix something.

### Provider shape (Riverpod)

```dart
// lib/features/health/permission_health_provider.dart
class PermissionHealth {
  const PermissionHealth({
    required this.usageAccess,
    required this.accessibilityService,
    required this.batteryOptExempt,
    required this.fingerprintChanged,
  });
  final bool usageAccess;
  final bool accessibilityService;
  final bool batteryOptExempt;
  final bool fingerprintChanged; // ONBD-07: true when current Build.FINGERPRINT != stored

  bool get allHealthy =>
      usageAccess && accessibilityService && batteryOptExempt && !fingerprintChanged;
}

final permissionHealthProvider =
    AsyncNotifierProvider<PermissionHealthNotifier, PermissionHealth>(
  PermissionHealthNotifier.new,
);

class PermissionHealthNotifier extends AsyncNotifier<PermissionHealth> {
  @override
  Future<PermissionHealth> build() => _evaluate();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _evaluate());
  }

  Future<PermissionHealth> _evaluate() async {
    final api = ref.read(permissionStatusApiProvider);
    final prefs = await SharedPreferences.getInstance();
    final storedFp = prefs.getString('last_known_fingerprint');
    final currentFp = await api.currentBuildFingerprint();
    final fingerprintChanged = storedFp != null && storedFp != currentFp;
    if (storedFp == null) {
      // First run after install — record without flagging
      await prefs.setString('last_known_fingerprint', currentFp);
    }
    return PermissionHealth(
      usageAccess: await api.isUsageAccessGranted(),
      accessibilityService: await api.isAccessibilityServiceEnabled(),
      batteryOptExempt: await api.isIgnoringBatteryOptimizations(),
      fingerprintChanged: fingerprintChanged,
    );
  }
}
```

### Build.FINGERPRINT-change handling (ONBD-07)

After OS update:
1. `currentBuildFingerprint()` returns the new value from `Build.FINGERPRINT`.
2. Provider compares against `shared_preferences['last_known_fingerprint']`.
3. If different, `fingerprintChanged = true`. UI surfaces banner regardless of permission state — user is asked to re-verify because OEMs frequently reset autostart/battery exemptions across OTA. `[VERIFIED: research/PITFALLS.md #2 "OTAs reset battery exemptions" + Phase 1 already established this risk]`
4. After user re-enters funnel and grants/skips: persist the new fingerprint in `shared_preferences`, clearing the flag.

**Important:** On first install, `last_known_fingerprint` is null. Set it to the current value WITHOUT flagging — no historical baseline exists yet.

### Banner state → home screen

The home screen's `Scaffold.body` mounts the banner (UI-SPEC Surface 11) inside an `AnimatedSwitcher`:

```dart
final health = ref.watch(permissionHealthProvider);
health.when(
  data: (h) => h.allHealthy ? const SizedBox.shrink() : HealthCheckBanner(health: h),
  loading: () => const SizedBox.shrink(),
  error: (_, __) => const SizedBox.shrink(), // graceful degradation; never block home
);
```

Banner tap → routes to the FIRST failing step in the 3-step funnel (Usage → Accessibility → Battery), reusing the same screens via `context.go('/onboarding/permissions/usage-access')` etc. `[VERIFIED: UI-SPEC Surface 11 interaction]`

---

## Drift v2 Migration

### Target schema (block_list table — Phase 2)

| Column | Type | Nullable | Default | Source |
|--------|------|----------|---------|--------|
| `id` | INTEGER | NO | autoIncrement | Phase 1 (unchanged) |
| `kind` | INTEGER | NO | — | Phase 1 (unchanged) |
| `package_name` | TEXT | YES | — | Phase 1 (unchanged) |
| `display_name` | TEXT | NO | — | Phase 1 (unchanged) |
| `reason_note` | TEXT | NO | `''` | Phase 1 (unchanged) |
| `streak_break_threshold_minutes` | INTEGER | NO | 5 | Phase 1 (unchanged) |
| `created_at` | DATETIME | NO | — | Phase 1 (unchanged) |
| `updated_at` | DATETIME | NO | — | Phase 1 (unchanged) |
| **`block_mode`** | **TEXT** | **NO** | **`'soft'`** | **Phase 2 NEW (LIST-08)** |
| **`schedule_start_minutes`** | **INTEGER** | **YES** | — | **Phase 2 NEW (LIST-09)** |
| **`schedule_end_minutes`** | **INTEGER** | **YES** | — | **Phase 2 NEW (LIST-09)** |
| **`schedule_weekday_mask`** | **INTEGER** | **YES** | — | **Phase 2 NEW (LIST-09)** |

### Updated table definition

```dart
// lib/data/database/tables/block_list_table.dart (Phase 2)
class BlockList extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kind => integer()();
  TextColumn get packageName => text().nullable()();
  TextColumn get displayName => text()();
  TextColumn get reasonNote => text().withDefault(const Constant(''))();
  IntColumn get streakBreakThresholdMinutes =>
      integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Phase 2 additions
  TextColumn get blockMode =>
      text().withDefault(const Constant('soft'))();
  IntColumn get scheduleStartMinutes => integer().nullable()();
  IntColumn get scheduleEndMinutes => integer().nullable()();
  IntColumn get scheduleWeekdayMask => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{kind, packageName}];
}
```

### Migration step (Drift API)

```dart
// lib/data/database/app_database.dart
@override
int get schemaVersion => 2; // bumped from 1

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(blockList, blockList.blockMode);
          await m.addColumn(blockList, blockList.scheduleStartMinutes);
          await m.addColumn(blockList, blockList.scheduleEndMinutes);
          await m.addColumn(blockList, blockList.scheduleWeekdayMask);
        }
      },
    );
```

`Migrator.addColumn(table, column)` issues `ALTER TABLE ADD COLUMN`. Drift handles the SQL emission; the Dart-side column declaration with `withDefault(Constant('soft'))` translates to `DEFAULT 'soft'` in the emitted SQL, satisfying the NOT NULL + default constraint without needing a backfill statement. `[CITED: pub.dev/documentation/drift/latest/drift/Migrator-class.html + drift.simonbinder.eu/migrations/api/]`

**Critical pitfall (verified):** SQLite refuses `ADD COLUMN` of a NOT NULL column without a default — see drift issue #457. Our `blockMode` declaration HAS `withDefault(Constant('soft'))`, so it compiles to `ADD COLUMN block_mode TEXT NOT NULL DEFAULT 'soft'` and works on all SQLite versions. The three nullable schedule columns have no such constraint. `[CITED: github.com/simolus3/drift/issues/457]`

### Round-trip test (Wave 0 — REQUIRED)

```dart
// test/data/database/migration_v1_to_v2_test.dart
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart'; // schema verifier
import 'package:test/test.dart';

void main() {
  test('v1 → v2 migration: existing row gets defaults', () async {
    // 1. Open DB at v1 (using a captured v1 schema snapshot)
    //    Generated via `dart run drift_dev schema dump …` (Wave 0 task)
    final db = AppDatabase(NativeDatabase.memory());
    // 2. Insert a v1-shape row directly via raw SQL (so the test doesn't depend on the new code)
    await db.customStatement('''
      INSERT INTO block_list (kind, display_name, reason_note,
        streak_break_threshold_minutes, created_at, updated_at)
      VALUES (0, 'TestApp', '', 5, ?, ?)
    ''', [DateTime.now().millisecondsSinceEpoch ~/ 1000,
           DateTime.now().millisecondsSinceEpoch ~/ 1000]);
    // 3. Trigger migration by reading via the new schema
    final rows = await db.select(db.blockList).get();
    expect(rows, hasLength(1));
    expect(rows[0].blockMode, equals('soft'));
    expect(rows[0].scheduleStartMinutes, isNull);
    expect(rows[0].scheduleEndMinutes, isNull);
    expect(rows[0].scheduleWeekdayMask, isNull);
  });
}
```

**Better:** Use Drift's official schema-verifier API (`drift_dev` schema export + `verifySelf` test helper) to generate a v1 schema fixture and run the upgrade against it. `[CITED: drift.simonbinder.eu/migrations/exports/]`

### Cascade-delete behavior (LIST-05)

Phase 1 already declared `references(BlockList, #id, onDelete: KeyAction.cascade)` on:
- `daily_streak.entry_id` (line 8 of `daily_streak_table.dart`) `[VERIFIED]`
- `pause_events.entry_id` (line 8 of `pause_events_table.dart`) `[VERIFIED]`
- `daily_checkins.entry_id` (line 8 of `daily_checkins_table.dart`) `[VERIFIED]`

Cascade deletes work AS LONG AS SQLite foreign key enforcement is on. Drift turns this on by default via `PRAGMA foreign_keys = ON` in its connection setup. **Verify in Phase 2 Wave 0** that the migration does NOT inadvertently disable it (it shouldn't — Drift's `customStatement` migration helpers don't touch the pragma).

Round-trip test: insert a row, insert a child row in `pause_events`, delete the parent, assert the child is gone. (This is also a useful Phase 2 test against the Phase 4 contract — Phase 4 will exercise this for real.)

---

## Schedule Active-Window Evaluation

### Pure-Dart helper (REQUIRED — consumed by Phase 2 editor preview AND Phase 4 PAUS-10 + Phase 5 STRK-09)

```dart
/// True iff [now] falls within the schedule defined by start/end minutes-of-day
/// and weekday mask. Returns false (= dormant) if any of the three is null.
///
/// Cross-midnight: when end < start, the window covers
///   [today.start_minute → tomorrow.end_minute].
///   In the cross-midnight case, [now] inside [start..1440) is "today"
///   and [now] inside [0..end) is "tomorrow's tail of yesterday's window."
///   The weekday mask refers to the START day.
///
/// Streak day boundary: 04:00 local time is handled by the CALLER (Phase 5).
/// This helper operates on raw clock time, not "streak day."
bool isInScheduleWindow({
  required DateTime now,
  required int? startMinutes,   // 0..1439
  required int? endMinutes,     // 0..1439
  required int? weekdayMask,    // bit 0 = Mon, bit 6 = Sun (ISO 8601 ordering)
}) {
  if (startMinutes == null || endMinutes == null || weekdayMask == null) {
    return false; // 'always-on' is the absence of a schedule — handled by caller
  }
  final localNow = now.toLocal();
  final nowMinutes = localNow.hour * 60 + localNow.minute;
  final todayWeekdayBit = 1 << (localNow.weekday - 1); // DateTime.weekday: Mon=1..Sun=7
  if (startMinutes <= endMinutes) {
    // Same-day window
    final inWindow = nowMinutes >= startMinutes && nowMinutes < endMinutes;
    return inWindow && (weekdayMask & todayWeekdayBit) != 0;
  } else {
    // Cross-midnight window
    if (nowMinutes >= startMinutes) {
      // Tail of [start..midnight) on TODAY — START-day weekday must match
      return (weekdayMask & todayWeekdayBit) != 0;
    } else if (nowMinutes < endMinutes) {
      // Tail of [midnight..end) on TODAY — START day was YESTERDAY
      final yesterday = localNow.subtract(const Duration(days: 1));
      final yesterdayBit = 1 << (yesterday.weekday - 1);
      return (weekdayMask & yesterdayBit) != 0;
    }
    return false;
  }
}
```

**Important nuances:**
- **Half-open interval `[start, end)`** matches typical "from 22:00 to 06:00" intent — at 06:00:00 the window is closed.
- **Weekday mask is the START day, not the current calendar day.** A "weekdays only 22:00–06:00" schedule means Mon-night-into-Tue, Tue-night-into-Wed, …, Fri-night-into-Sat. On Sat 03:00, `localNow.weekday == 6 (Sat)`; the START day was Friday (weekday 5). So we look up `yesterday.weekday`. This is the rule documented in CONTEXT.md "the window covers `[today's start_time → tomorrow's end_time]`."
- **DST handling:** `DateTime.toLocal()` returns the local timezone; on a 23h or 25h DST day the minutes-of-day comparison is still correct because we're comparing within a single calendar day relative to local clock. BUT a window straddling the DST jump (e.g., 02:00–03:00 on the spring-forward day, when 02:30 doesn't exist in clock time) is degenerate. Phase 2 helper tolerates it: `nowMinutes` is whatever the local clock reports. Document this and don't try to be clever.
- **Streak day boundary (04:00):** OUT OF SCOPE for this helper. The streak engine (Phase 5) takes the wall-clock day from this helper and shifts by 4 hours to get the streak day. Phase 2 surfaces both the helper and a separate `streakDayFor(DateTime)` utility, but the streak shift is consumed only by Phase 5.

### Test matrix (REQUIRED — pure-Dart unit tests)

| Test ID | Scenario | Expected |
|---------|----------|----------|
| WIN-01 | Same-day, in window: 09:00–22:00 weekdays, now=14:00 Tue | true |
| WIN-02 | Same-day, before window: now=08:00 Tue | false |
| WIN-03 | Same-day, after window: now=22:00 Tue (boundary inclusive of end) | false (half-open) |
| WIN-04 | Same-day, weekend masked off: weekdays-only mask, now=14:00 Sat | false |
| WIN-05 | Cross-midnight, after start: 22:00–06:00 weekdays, now=23:30 Tue | true |
| WIN-06 | Cross-midnight, before end on next day: now=03:00 Wed (start day was Tue) | true |
| WIN-07 | Cross-midnight, in gap: now=14:00 Wed | false |
| WIN-08 | Cross-midnight, START day weekday off: weekdays-only, now=23:30 Sat (start day Sat is unmasked) | false |
| WIN-09 | Cross-midnight + START-day Sun, end-tail on Mon: weekdays-only mask, now=03:00 Mon (start day was Sun = unmasked) | false |
| WIN-10 | DST spring-forward day (23h day, fictitious 02:30), window 22:00–06:00 | helper returns whatever wall-clock reports; just verify no crash on synthesized boundary times |
| WIN-11 | DST fall-back day (25h day, 01:30 occurs twice), window 22:00–06:00 | each occurrence evaluated independently against wall-clock; no crash |
| WIN-12 | Leap-year Feb-29, normal weekday window | no special handling needed; verify no crash |
| WIN-13 | All three null → "always-on" semantics | false (caller treats null-schedule as dormant=false but interception=always; this helper deliberately stays mechanical) |

WIN-10 / WIN-11 should not assert on the truth value (semantics are degenerate); just assert the helper doesn't throw. The actual Phase 5 streak rollover handles 23h/25h days at the day-boundary level, not the within-day level.

---

## Riverpod Provider Wiring (Phase 2 deltas)

### What Phase 1 already gives us

| Provider | File | Phase 2 status |
|---|---|---|
| `databaseProvider` (Provider<AppDatabase>) | `lib/domain/providers/database_provider.dart` | REUSE — Phase 2 just adds DAO providers downstream |
| `useAccessibilityServiceProvider` (Provider<bool>) | `lib/domain/providers/blocked_app_detector_provider.dart` | DO NOT MODIFY — Phase 4 wedge |
| `blockedAppDetectorProvider` (Provider<BlockedAppDetector>) | `lib/domain/providers/blocked_app_detector_provider.dart` | DO NOT MODIFY — Phase 4 wedge |

Phase 1 also shipped:
- `app.dart` with one route (`/` → `EmptyHomeScreen`) using `go_router 17.2.3`
- `flutter_riverpod 3.3.1` is the project's state management — providers are HAND-WRITTEN (no `@riverpod` codegen, per Phase 1 Plan 01-01 SUMMARY: analyzer-version conflict with pigeon 26.3.4). Phase 2 follows the same hand-written pattern. `[VERIFIED: pubspec.yaml comments + lib/domain/providers/database_provider.dart Phase 1 codebase]`

### New Phase 2 providers (recommended hierarchy)

```
databaseProvider                     [Phase 1 — REUSE]
  └─ blockListDaoProvider            [Phase 2 — NEW; thin wrapper around AppDatabase methods]
       └─ blockListRepoProvider      [Phase 2 — NEW; CRUD + insertMany for quick-add seed]

permissionStatusApiProvider          [Phase 2 — NEW; Pigeon @HostApi instance]
  ├─ permissionHealthProvider        [Phase 2 — NEW; AsyncNotifierProvider]
  └─ onboardingControllerProvider    [Phase 2 — NEW; advances cursor in shared_preferences]

appPickerApiProvider                 [Phase 2 — NEW; Pigeon @HostApi instance]
  └─ installedAppsProvider           [Phase 2 — NEW; FutureProvider; fetched per picker open]
  └─ recentlyUsedAppsProvider        [Phase 2 — NEW; FutureProvider.family(daysBack)]
  └─ appIconCacheProvider            [Phase 2 — NEW; Provider.autoDispose for the LRU(50)]
  └─ appIconBytesProvider            [Phase 2 — NEW; FutureProvider.family(packageName) hitting cache]

onboardingCompleteProvider           [Phase 1 — REUSE if exists; if not, NEW Phase 2 with shared_preferences key 'onboarding_complete']
onboardingCursorProvider             [Phase 2 — NEW; int 0..3 in shared_preferences key 'onboarding_step']
```

**Note on `onboardingCompleteProvider`:** the user request mentions Phase 1 shipped one ("referenced in test override fixtures `onboardingCompleteOverrides`"). I scanned `lib/` and `test/` and did not find a definition with that exact name. The Phase 1 home screen is `EmptyHomeScreen` directly mounted at `/` with no onboarding gate. The planner should treat `onboardingCompleteProvider` as a Phase 2 NEW provider unless they find one I missed, and document the choice in the plan. `[ASSUMED: provider does not yet exist; verify before planning Wave 0]`

### GoRouter redirect (extending Phase 1)

Phase 1's router is single-route. Phase 2 adds 7 routes plus a redirect:

```dart
GoRouter(
  redirect: (ctx, state) {
    final completed = ref.read(onboardingCompleteProvider);
    final goingToOnboarding = state.matchedLocation.startsWith('/onboarding');
    if (!completed && !goingToOnboarding) return '/onboarding/welcome';
    if (completed && goingToOnboarding) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/onboarding/welcome', builder: ...),
    GoRoute(path: '/onboarding/quick-add', builder: ...),
    GoRoute(path: '/onboarding/permissions/usage-access', builder: ...),
    GoRoute(path: '/onboarding/permissions/accessibility', builder: ...),
    GoRoute(path: '/onboarding/permissions/battery-opt', builder: ...),
    GoRoute(path: '/list/add-app', builder: ...),
    GoRoute(path: '/list/add-habit', builder: ...),
    GoRoute(path: '/list/edit/:id', builder: ...),
  ],
);
```

The redirect runs on every navigation. The cursor in `shared_preferences['onboarding_step']` (int 0..3) drives WHICH step is shown when the user is in `/onboarding/permissions/...` — but that's a screen-level concern, not router-level.

### Picker channel slot

`appPickerApiProvider` is a sibling of `usageApiProvider` (Phase 1 Pigeon-instance providers). They are wrapped one level above the data layer because they ARE the platform boundary; repositories may consume them, but providers don't have to. The picker page consumes `installedAppsProvider` directly.

---

## PLAY-06 Prominent Disclosure

### Verbatim source — `docs/play-declaration.md` §4

The Phase 2 in-app disclosure (UI-SPEC Surface 3 Step 2) is **derived from**, not a direct copy of, `docs/play-declaration.md` §4. The UI-SPEC text is approved Phase 2 copy that satisfies the policy requirements without verbatim-copying the legal-style document. PLAY-06 says "in-app prominent disclosure for Accessibility Service is shown before grant" — UI-SPEC Surface 3 Step 2 satisfies this.

**Key requirements that UI-SPEC Surface 3 Step 2 already satisfies:**

1. ✅ Inside the app (not only the Play listing) — UI-SPEC Surface 3 places it at `/onboarding/permissions/accessibility`
2. ✅ Shown BEFORE the user is sent to Settings — the screen is the rationale screen; the CTA "I understand — open Settings" launches the deep-link
3. ✅ Plain-language description — UI-SPEC paragraph 1: "package name … only when a window-state-changed event fires"
4. ✅ States what the service NEVER does — UI-SPEC paragraph 2: "never reads your screen, never types on your behalf, and never sends anything off your device"
5. ✅ Separate UI (not buried in Privacy Policy) — Standalone screen, no scroll-to-find
6. ✅ Explicit tap to proceed — "I understand — open Settings" is the single CTA per UI-SPEC

**Cross-check task (Phase 2 verification step):** Diff the rendered text on Surface 3 Step 2 against `docs/play-declaration.md` §4 manually. The phrases that MUST appear verbatim or near-verbatim:
- "package name" / "only when a window-state-changed event fires"
- "never reads your screen"
- "never sends anything off your device"
- "disable this at any time"

If any future Phase 2 plan reduces the disclosure copy, the planner MUST flag the deviation and require an update to `docs/play-declaration.md` first (per UI-SPEC PLAY-06 compliance check note).

### Pause-screen screenshot asset (Phase 2 vs Phase 4)

**Status:** Open question. Phase 4 is where the actual pause screen ships. UI-SPEC Surface 3 Step 2 references the disclosure body but does NOT mandate a pause-screen screenshot in Phase 2 — only the Settings screenshot.

**Two options:**
1. **(Recommended) Ship Phase 2 disclosure WITHOUT a pause-screen screenshot.** The disclosure relies on textual paragraphs and the Settings screenshot. Pause-screen screenshot belongs to Phase 6 polish (PLAY-08 closed-track submission), where the actual rendered Phase 4 pause UI can be captured.
2. Ship a placeholder/wireframe pause-screen image as `assets/onboarding/pause_screen_preview.png` in Phase 2; replace in Phase 4. Risk: placeholder might land in a release if the Phase 4 update is missed.

The CONTEXT.md research gap "Surface as an open question in the research doc" is captured here. **Recommendation: option 1.** Skip the pause-screen image in Phase 2; revisit in Phase 4 once the actual screen exists. UI-SPEC Surface 3 Step 2 already has the Settings screenshot, which is the more useful asset for the Settings hand-off.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter SDK) + `mocktail 1.0.5` (already in dev_dependencies) |
| Config file | None — Flutter convention via `test/` directory |
| Quick run command | `flutter test test/data/database/migration_v1_to_v2_test.dart -r expanded` |
| Full suite command | `flutter test` |

Phase 1 already uses this stack (see `test/data/` and `test/domain/` subtrees from Phase 1). No new framework setup needed.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIST-01 | Picker enumerates launchable apps | integration (mock Pigeon channel) | `flutter test test/features/list/add_app_picker_test.dart -r expanded` | ❌ Wave 0 |
| LIST-02 | Add habit creates a row with kind=1, packageName=null | unit (Drift in-memory) | `flutter test test/data/repositories/block_list_repo_test.dart -r expanded` | ❌ Wave 0 |
| LIST-03 | Reason note saved as plain text up to 500 chars | unit | (same file as LIST-02) | ❌ Wave 0 |
| LIST-04 | Edit updates existing row | unit | (same file) | ❌ Wave 0 |
| LIST-05 | Delete cascades to streak/pause/checkins tables | unit (Drift in-memory; insert children, delete parent, assert empty) | `flutter test test/data/repositories/cascade_delete_test.dart -r expanded` | ❌ Wave 0 |
| LIST-06 | Home list sorts by `MAX(updatedAt, …)` desc | widget | `flutter test test/features/home/home_screen_test.dart -r expanded` | ❌ Wave 0 |
| LIST-07 | Quick-add seeds 5 entries | unit + widget | `flutter test test/features/onboarding/quick_add_test.dart -r expanded` | ❌ Wave 0 |
| LIST-08 | block_mode column persists; segmented control hidden for habits | unit (Drift) + widget (editor) | `flutter test test/features/list/edit_screen_test.dart -r expanded` | ❌ Wave 0 |
| LIST-09 | schedule columns persist; ScheduleEditor renders 3 controls | unit + widget | (same file) | ❌ Wave 0 |
| LIST-09 (helper) | `isInScheduleWindow` truth table (13 cases) | pure unit | `flutter test test/domain/schedule/schedule_window_test.dart -r expanded` | ❌ Wave 0 |
| ONBD-01 | 3-step funnel sequences correctly | widget (with mocked PermissionStatusApi) | `flutter test test/features/onboarding/funnel_flow_test.dart -r expanded` | ❌ Wave 0 |
| ONBD-02 | Each step shows rationale before deep-link | widget | (same file) | ❌ Wave 0 |
| ONBD-03 | onResume re-checks status and auto-advances | widget (pump `AppLifecycleState.resumed`) | (same file) | ❌ Wave 0 |
| ONBD-04 | OEM fallback triggered when standard intent doesn't resolve | unit (mock Pigeon: standard returns false, OEM probe returns true) | `flutter test test/features/onboarding/oem_fallback_test.dart -r expanded` | ❌ Wave 0 |
| ONBD-05 | Re-entering funnel from Settings works | widget | (same as ONBD-01 file) | ❌ Wave 0 |
| ONBD-06 | Banner shows when any permission revoked | widget (mock PermissionHealth all-revoked) | `flutter test test/features/health/banner_test.dart -r expanded` | ❌ Wave 0 |
| ONBD-07 | Build.FINGERPRINT mismatch flags re-verification | unit | `flutter test test/features/health/fingerprint_test.dart -r expanded` | ❌ Wave 0 |
| PLAY-06 | Disclosure copy contains required substrings | widget (golden-text or contains-asserts) | `flutter test test/features/onboarding/play06_disclosure_test.dart -r expanded` | ❌ Wave 0 |
| REL-02 | Health check evaluates on `AppLifecycleState.resumed` | widget | (same as ONBD-06 file) | ❌ Wave 0 |
| REL-03 | dontkillmyapp.com URL produced for known manufacturers | unit | `flutter test test/features/health/dontkillmyapp_url_test.dart -r expanded` | ❌ Wave 0 |
| Drift v1→v2 | Existing v1 row gets defaults | unit (Drift schema-export verifier) | `flutter test test/data/database/migration_v1_to_v2_test.dart -r expanded` | ❌ Wave 0 |
| Picker round-trip | Pigeon channel returns expected list | unit (Kotlin shadow + mock channel) | `flutter test test/platform/app_picker_api_test.dart -r expanded` + Kotlin `./gradlew :app:test` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/<scope>/` for the modified scope. Migration test runs in <1 s and is cheap to run on every commit touching the data layer.
- **Per wave merge:** `flutter test` (full suite) before promoting any wave.
- **Phase gate:** Full suite green AND a manual on-device pass on (a) Pixel emulator running stock Android 16 (b) any one OEM device available (Samsung/Xiaomi preferred per `research/PITFALLS.md` #2). Real-device overnight test is NOT a Phase 2 gate (deferred to Phase 4 per ROADMAP).

### Wave 0 Gaps

All test files above are NEW. Group them into the following Wave 0 tasks:

- [ ] `test/data/database/migration_v1_to_v2_test.dart` — Drift v2 migration round-trip
- [ ] `test/data/repositories/block_list_repo_test.dart` — LIST-01..04 + LIST-08/09 column persistence
- [ ] `test/data/repositories/cascade_delete_test.dart` — LIST-05 cascade
- [ ] `test/domain/schedule/schedule_window_test.dart` — 13-case schedule helper truth table
- [ ] `test/features/list/add_app_picker_test.dart` — LIST-01 picker UI with mocked Pigeon
- [ ] `test/features/list/edit_screen_test.dart` — LIST-04, LIST-08, LIST-09 editor widget
- [ ] `test/features/home/home_screen_test.dart` — LIST-06 sort order, empty state
- [ ] `test/features/onboarding/quick_add_test.dart` — LIST-07 quick-add seeding
- [ ] `test/features/onboarding/funnel_flow_test.dart` — ONBD-01/02/03/05
- [ ] `test/features/onboarding/oem_fallback_test.dart` — ONBD-04
- [ ] `test/features/onboarding/play06_disclosure_test.dart` — PLAY-06 verbatim phrase asserts
- [ ] `test/features/health/banner_test.dart` — ONBD-06 + REL-02 banner state
- [ ] `test/features/health/fingerprint_test.dart` — ONBD-07
- [ ] `test/features/health/dontkillmyapp_url_test.dart` — REL-03
- [ ] `test/platform/app_picker_api_test.dart` — Picker Pigeon round-trip (Dart side)
- [ ] `android/app/src/test/kotlin/.../AppPickerHostImplTest.kt` — Picker Pigeon (Kotlin side, JUnit, optional but recommended)
- [ ] Shared fixtures: `test/_fixtures/permission_status_mock.dart` — single mock implementation of `PermissionStatusApi` reused across funnel + banner tests

No new test framework install required.

---

## Common Pitfalls

### Pitfall A: Querying UsageStatsManager without first checking the AppOps grant

**What goes wrong:** `queryUsageStats(...)` returns an empty list (NOT an exception) when the grant is absent. UI shows "Recently used: empty" and the user thinks no recent apps exist; in fact, they just haven't granted Usage Access yet.

**How to avoid:** ALWAYS gate the call on `AppOpsManager.unsafeCheckOpNoThrow(OPSTR_GET_USAGE_STATS, …) == MODE_ALLOWED`. UI-SPEC Surface 5 already specifies the "Recently used unavailable (Usage Access denied)" copy — render it when the gate fails, instead of an empty list.

**Warning signs:** Beta tester says "the picker doesn't suggest any apps." `[CITED: research/PITFALLS.md integration gotchas]`

### Pitfall B: Trusting an OEM ComponentName without `resolveActivity`

**What goes wrong:** Hardcoded ComponentName launches `ActivityNotFoundException` when the OEM has renamed the activity in a newer ROM revision (MIUI 14 vs MIUI 15, EMUI vs HarmonyOS). The user sees the app crash on a "Step 3: enable autostart" tap.

**How to avoid:** EVERY OEM ComponentName in the table must be wrapped: `if (intent.resolveActivity(pm) != null) startActivity(...) else { fall through to dontkillmyapp.com link }`. Treat the ComponentName list as best-effort; the URL fallback is the safety net.

### Pitfall C: Drift `addColumn` of NOT NULL without default

**What goes wrong:** `m.addColumn(table, table.foo)` where `foo` is `text()()` (NOT NULL, no default) fails on existing rows: SQLite refuses with "Cannot add a NOT NULL column with default value NULL." `[CITED: github.com/simolus3/drift/issues/457]`

**How to avoid:** Our `blockMode` column has `withDefault(Constant('soft'))`, which Drift translates to `DEFAULT 'soft'` in the emitted SQL. Verified in the test plan above (`block_list_repo_test.dart` migration round-trip).

### Pitfall D: `WidgetsBindingObserver` not removed in `dispose()`

**What goes wrong:** Memory leak; the observer keeps the State alive and `didChangeAppLifecycleState` fires on a disposed widget. In tests, this manifests as "ref used after dispose" errors.

**How to avoid:** Always pair `addObserver(this)` in `initState` with `removeObserver(this)` in `dispose`. Code example above includes it. Lint rule `always_use_package_imports` and `discarded_futures` from `very_good_analysis 10.2.0` won't catch this; add an explicit checklist item to the planner's verification step.

### Pitfall E: Schedule helper assumes weekday by current calendar day for cross-midnight windows

**What goes wrong:** A "weekdays-only 22:00–06:00" schedule active at 03:00 Saturday would be considered "in window" if the helper checks `weekdayMask & saturdayBit`, but the START day was Friday — it should be in window. Conversely, 03:00 Monday shouldn't be in window because Sunday's mask bit is off.

**How to avoid:** Cross-midnight evaluation looks up YESTERDAY's weekday for the post-midnight tail. Test cases WIN-08 and WIN-09 cover this. The implementation above gets it right; this is documented to keep future contributors from "simplifying" the helper.

### Pitfall F: Spurious `AppLifecycleState.resumed` on lockscreen

**What goes wrong:** flutter/flutter#130055 reports `resumed` firing while the device is still locked, on some Android builds. If the recheck logic auto-advances on `resumed`, it would advance behind the lock screen — confusing UX.

**How to avoid:** The recheck is idempotent (it only advances if the permission is granted; granting requires Settings access, which requires unlock). A spurious resume that finds the permission STILL un-granted is harmless. Just don't pop a celebratory toast on resume; leave UI state-driven. `[CITED: github.com/flutter/flutter/issues/130055]`

---

## Code Examples

### Example 1: Pigeon @HostApi for app picker (Phase 2 NEW)

See [App Picker Implementation §](#app-picker-implementation) above for the full schema. `[CITED: pub.dev/packages/pigeon]`

### Example 2: Drift migration v1→v2

See [Drift v2 Migration §](#drift-v2-migration) above. `[CITED: drift.simonbinder.eu/migrations/api/]`

### Example 3: WidgetsBindingObserver auto-advance

See [onResume Return-Detection Pattern §](#onresume-return-detection-pattern) above. `[CITED: api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html]`

### Example 4: Settings deep-link with resolution guard (Kotlin)

```kotlin
// android/app/src/main/kotlin/.../platform/PermissionStatusApiImpl.kt
override fun openUsageAccessSettings(callback: (Result<Unit>) -> Unit) {
  val pm = context.packageManager
  val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  if (intent.resolveActivity(pm) != null) {
    context.startActivity(intent); callback(Result.success(Unit)); return
  }
  // Fallback: app-details settings (always resolves on stock Android)
  val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
    .setData(Uri.parse("package:${context.packageName}"))
    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  if (fallback.resolveActivity(pm) != null) {
    context.startActivity(fallback); callback(Result.success(Unit)); return
  }
  callback(Result.failure(Exception("No Settings activity resolves on this device")))
}
```

`[CITED: developer.android.com/reference/android/content/Intent#resolveActivity]`

### Example 5: Battery-opt request with package data Uri (Kotlin)

```kotlin
override fun requestIgnoreBatteryOptimizations(callback: (Result<Unit>) -> Unit) {
  val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
    .setData(Uri.parse("package:${context.packageName}"))
    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  // resolveActivity guard same as above; fallback to ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
}
```

The `package:<pkg>` data Uri is REQUIRED for `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` per the docs. `[CITED: developer.android.com/reference/android/provider/Settings#ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS]`

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | OEM ComponentName fallbacks (MIUI Autostart, EMUI Startup Manager, etc.) are still valid on current OEM ROMs | Permission Step Deep-Links § | LOW — every fallback is guarded by `resolveActivity`; if the ComponentName is stale, app falls through to dontkillmyapp.com link. No crash, just a non-optimal step. |
| A2 | OnePlus runs ColorOS-derived OEM screens, so the Oppo entries apply | Permission Step Deep-Links § | LOW — same `resolveActivity` guard. Worst case: OnePlus user sees the generic dontkillmyapp.com link. |
| A3 | `onboardingCompleteProvider` does NOT yet exist in Phase 1 codebase | Riverpod Provider Wiring § | MEDIUM — if it does exist and the planner creates a duplicate, the duplicate will conflict. Planner MUST scan `lib/` and `test/` for any existing definition before Wave 0. |
| A4 | `dynamic_color` 1.7.0 is still current as of phase plan time | Standard Stack | LOW — `flutter pub outdated` check at Wave 0 catches drift. Newer minor versions are typically backwards-compatible. |
| A5 | The Phase 5 streak engine consumes `isInScheduleWindow` and applies the 04:00 streak-day shift on top, not within | Schedule Active-Window Evaluation § | MEDIUM — if Phase 5 expects this helper to internalize the 04:00 shift, Phase 5 will need a wrapper. Documented explicitly in the helper's docstring to surface the contract early. |
| A6 | The Phase 4 PauseActivity reads schedule columns directly from the same Drift database; Phase 2 does not need a separate channel | Drift v2 Migration § | LOW — Phase 4 inherits the schema; the cascade-delete contract is already in place. |
| A7 | `permission_handler` is NOT needed for Phase 2 — none of the 3 funnel steps are runtime permissions | Standard Stack alternatives | LOW — Phase 5 will re-evaluate when adding POST_NOTIFICATIONS. |
| A8 | Pause-screen screenshot is NOT required as a Phase 2 asset — it is a Phase 4/6 concern | PLAY-06 Prominent Disclosure § | MEDIUM — if PLAY-06 is later interpreted to require a pause-screen image at install-time, Phase 2 needs an extra deliverable. Mitigation: capture the question for the planner (Open Questions §). |

---

## Open Questions for Planner

1. **Does `onboardingCompleteProvider` exist in Phase 1 codebase?**
   - What I found: I scanned `lib/domain/providers/`, `lib/data/`, and `test/` and did not find a provider with that exact name. The Phase 1 home is `EmptyHomeScreen` mounted directly at `/`.
   - What's unclear: The user's prompt mentioned "test override fixtures `onboardingCompleteOverrides`." If those fixtures exist somewhere I missed (e.g., in `test/_fixtures/`), Phase 2 must REUSE the existing provider.
   - Recommendation: Planner runs `grep -rn "onboardingComplete" lib/ test/` as the first step of Wave 0; if found, REUSE; if not, create as Phase 2 NEW.

2. **Pause-screen screenshot as Phase 2 asset (PLAY-06): ship a placeholder, or defer to Phase 4/6?**
   - What we know: UI-SPEC Surface 3 Step 2 does not mandate a pause-screen screenshot. Phase 4 ships the actual pause UI.
   - What's unclear: Whether reviewers will read the install-time disclosure as "incomplete" without a visual of the pause screen.
   - Recommendation: Defer to Phase 4. UI-SPEC's Settings screenshot + textual disclosure satisfies the policy requirements (per `docs/play-declaration.md` §4 — "describes in plain language exactly what data is accessed"). Re-evaluate at Phase 6 PLAY-08 when the closed-track build is being prepared.

3. **`ScheduleEditor`'s preview text — does it use `isInScheduleWindow` in Phase 2, or just persist the raw fields?**
   - What we know: Phase 4 PAUS-10 and Phase 5 STRK-09 are the helper's primary consumers.
   - What's unclear: Whether the Phase 2 editor should show "Window is currently active" / "Window will start in X hours" preview, requiring the helper to be wired into the editor itself.
   - Recommendation: SHIP the helper in Phase 2 (it's a 60-line pure-Dart function with 13 unit tests). DO NOT wire it into the editor preview UI in Phase 2 — UI-SPEC Surface 9 doesn't require it. Phase 4 wires it in for actual interception. This keeps Phase 2 surface area minimal.

4. **Banner "What's wrong?" expandable — single source of truth for which message text shows for each missing permission.**
   - What we know: UI-SPEC Surface 11 lists the 3 expandable lines verbatim.
   - What's unclear: Where the strings live (a `BannerCopy` const class? hardcoded in the widget?).
   - Recommendation: Hardcode in the widget for v1; English-only is a locked deferred item. Phase 6 polish or M2 localization can extract.

5. **Quick-add curated set — package names or display names?**
   - What we know: Display names locked: `Instagram`, `TikTok`, `X`, `YouTube`, `Reddit`. Package names: `com.instagram.android`, `com.zhiliaoapp.musically`, `com.twitter.android`, `com.google.android.youtube`, `com.reddit.frontpage`.
   - What's unclear: When the user taps "Continue" with N selected, the Phase 2 BlockListRepository inserts those entries — but the Android device might not have the apps installed.
   - Recommendation: Pre-seed REGARDLESS of installation status. The user is signaling intent to avoid these apps; whether they have them installed is orthogonal. The picker for adding more apps later filters to installed apps; the quick-add curated set is intentional even when not installed (the user might be reflecting on apps they recently uninstalled). Document this in the plan.

---

## Out-of-Scope Guardrails (Phase 2)

The planner MUST reject any task that drifts toward these features. v1 = ADULT SELF-CONTROL ONLY.

| Feature | Why Out of Scope | What to do if a plan task drifts here |
|---------|------------------|----------------------------------------|
| Website blocking (DNS, hosts file, accessibility text-content scanning) | Out of v1. AccessibilityService is `typeWindowStateChanged` ONLY (PLAY-03). No text-content reading. | Reject. Do not add `canRetrieveWindowContent` to the manifest. Do not introduce DNS or VPN code paths. |
| Parental control UI (Parent PIN, kid mode, protected-route concept) | Out of v1. PROJECT.md key decision 2026-05-05: "Adult self-control only — NO parental control in v1." | Reject. No PIN entry screens. No "kid mode" toggles. The `permissionHealthProvider` and onboarding cursor are NOT gated by any auth. |
| Anti-uninstall protection | Out of v1. PROJECT.md: "uninstall-resets-streak is by design." | Reject. Do NOT request `BIND_DEVICE_ADMIN`. Do NOT add to manifest. |
| Content-type filter (18+, gambling, violence) | Out of v1. PROJECT.md + REQUIREMENTS.md Out of Scope: "needs paid API or weak self-host blocklists; conflicts with free/OSS budget." | Reject. Do NOT add `READ_CONTACTS`, `READ_SMS`, web-content APIs, or any third-party categorization SDK. |
| `QUERY_ALL_PACKAGES` permission | PLAY-04 forbids. Phase 1 satisfies via `<queries>` + LAUNCHER intent filter. | Reject any plan task that would request `QUERY_ALL_PACKAGES`. The picker MUST work via the existing `<queries>` element. |
| `SYSTEM_ALERT_WINDOW` overlay UI for any Phase 2 surface | PLAY-05 forbids. Pause UI is Phase 4 PauseActivity (FlutterActivity, NOT overlay). Phase 2 has NO surfaces that need overlay. | Reject. Banner is a regular Material widget at top of `Scaffold.body`, not an overlay. |
| Telemetry / analytics / FCM | SETT-03 invariant. Phase 1 V10 dep audit verified zero such SDKs. | Reject any new dependency that ships data off-device. Do NOT add `firebase_*`, `sentry_*`, `mixpanel_*`, `amplitude_*`, or similar. |
| Modifying `BlockedAppDetector` interface or its providers | REL-05 abstraction owned by Phase 1. Phase 4 lights it up. | Reject. Phase 2 must NOT modify `lib/domain/blocked_app_detector.dart` or `lib/domain/providers/blocked_app_detector_provider.dart`. |
| Adding `riverpod_annotation` / `riverpod_generator` codegen | Phase 1 dropped these due to analyzer pin conflict with `pigeon 26.3.4`. Hand-written providers is the project standard. | Reject. New providers in Phase 2 are hand-written `Provider<T>` / `FutureProvider<T>` / `AsyncNotifierProvider<T,U>` declarations. |
| Modifying `AccessibilityApi.isServiceEnabled()` | Phase 1 contract. Phase 2 may extend with a NEW PermissionStatusApi but must not modify the existing channel. | Reject changes to `pigeons/accessibility_api.dart` or `lib/platform/accessibility_api.g.dart`. |
| Schedule presets ("Work hours", "Bedtime") in editor | CONTEXT.md `<deferred>`. v1 has only the manual time-pickers + weekday chips. | Reject. The schedule editor has exactly 3 controls per UI-SPEC Surface 9. |
| Multiple schedule windows per entry | CONTEXT.md `<deferred>`. v1 has ONE optional window per entry. | Reject. The Drift schema has exactly 3 schedule columns; no `block_list_schedules` child table in v1. |

---

## State of the Art

| Old Approach | Current Approach (Phase 2) | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled MethodChannel string keys | Pigeon 26.3.4 typed channels | Phase 1 architecture decision | Compile-time type safety; eliminates `MissingPluginException` class of bugs |
| `permission_handler` for everything | Per-permission native helpers via Pigeon | This research | UsageAccess + AccessibilityService are NOT runtime permissions; `permission_handler` doesn't cover them. Custom helpers are required regardless. |
| `device_apps` / `installed_apps` plugins | Custom `AppPickerApi` Pigeon channel | This research | Phase 1's Pigeon-typed pattern is project standard; community plugins have opaque manifest config that complicates PLAY-04 audit |
| Polling foreground app for blocked-app detection | AccessibilityService passive trigger | Phase 1 architecture decision (`research/PITFALLS.md` #5) | Sub-second latency for pause screen; UsageStatsManager has 2.5s+ lag |
| `SYSTEM_ALERT_WINDOW` overlay for pause UI | FlutterActivity (`PauseActivity`) | Phase 1 architecture decision | Cleaner Play Store review; no overlay restrictions on Android 12+ |

---

## Sources

### Primary (HIGH confidence)

- **Phase 1 codebase** — `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/`, `lib/domain/providers/`, `pigeons/`, `lib/platform/`, `android/app/src/main/AndroidManifest.xml`. Verified directly.
- **`docs/play-declaration.md`** §4 — verbatim source for PLAY-06 disclosure. Read fully.
- **`02-CONTEXT.md`** — locked discuss-phase decisions. All decisions in User Constraints copied verbatim.
- **`02-UI-SPEC.md`** — visual + interaction contract. Surfaces 1–13 read.
- **`research/ARCHITECTURE.md`** — Pigeon-typed channels, FlutterActivity pause, single-writer SQLite. Confirmed.
- **`research/PITFALLS.md`** — pitfall #2 (OEM kills), #3 (PACKAGE_USAGE_STATS onboarding cliff), #5 (right tool for the job), #10 (POST_NOTIFICATIONS). Cited inline.
- [Drift Migrator class — pub.dev](https://pub.dev/documentation/drift/latest/drift/Migrator-class.html) — `addColumn` signature
- [Drift migrations API guide](https://drift.simonbinder.eu/migrations/api/) — onUpgrade pattern
- [Drift schema export and verifier](https://drift.simonbinder.eu/migrations/exports/) — round-trip test approach
- [Drift issue #457](https://github.com/simolus3/drift/issues/457) — "Cannot add a NOT NULL column with default value NULL" pitfall
- [Flutter `WidgetsBindingObserver`](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html) — lifecycle hook contract
- [Flutter `AppLifecycleState.resumed`](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html) — state semantics
- [Android `Settings.ACTION_USAGE_ACCESS_SETTINGS`](https://developer.android.com/reference/android/provider/Settings#ACTION_USAGE_ACCESS_SETTINGS)
- [Android `Settings.ACTION_ACCESSIBILITY_SETTINGS`](https://developer.android.com/reference/android/provider/Settings#ACTION_ACCESSIBILITY_SETTINGS)
- [Android `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`](https://developer.android.com/reference/android/provider/Settings#ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) — requires `package:` data Uri
- [Android `PowerManager.isIgnoringBatteryOptimizations`](https://developer.android.com/reference/android/os/PowerManager#isIgnoringBatteryOptimizations(java.lang.String)) — exemption check
- [Android `Intent.resolveActivity`](https://developer.android.com/reference/android/content/Intent#resolveActivity(android.content.pm.PackageManager)) — pre-launch guard pattern
- [Android `<queries>` element](https://developer.android.com/guide/topics/manifest/queries-element) — Phase 1 manifest already wires this

### Secondary (MEDIUM confidence)

- [Don't Kill My App](https://dontkillmyapp.com/) — community-maintained per-OEM guidance pages
- [Per-OEM ComponentName gist (moopat)](https://gist.github.com/moopat/e9735fa8b5cff69d003353a4feadcdbc) — community-maintained ComponentName list for Xiaomi/Huawei/Samsung/Oppo/Vivo/iQOO/Asus/LeTV (cross-verified with Don't Kill My App)
- [`dynamic_color` package](https://pub.dev/packages/dynamic_color) — Material You palette; maintained by `material-foundation/flutter-packages` (Google org)
- [`url_launcher` package](https://pub.dev/packages/url_launcher) — for the dontkillmyapp.com link
- [Pigeon package](https://pub.dev/packages/pigeon) — Phase 1 already at 26.3.4
- [Flutter issue #130055](https://github.com/flutter/flutter/issues/130055) — `didChangeAppLifecycleState` spurious-resume edge case

### Tertiary (LOW confidence — flagged in Assumptions Log)

- OnePlus → ColorOS-derived ComponentNames (assumption A2)
- Specific MIUI / EMUI / ColorOS version coverage of the cited ComponentNames (general OEM ROM drift over time)

---

## Metadata

**Confidence breakdown:**
- Standard stack (Drift v2, Flutter lifecycle, Pigeon channel): HIGH — verified against official docs and Phase 1 code
- Architecture (provider hierarchy, channel split): HIGH — extends Phase 1 patterns
- App picker enumeration: HIGH on `<queries>` + `getInstalledApplications`; HIGH on `UsageStatsManager.queryUsageStats(INTERVAL_BEST)`
- Permission status helpers (AppOpsManager, AccessibilityManager, PowerManager): HIGH — standard Android APIs
- OEM ComponentName fallbacks: MEDIUM — community-maintained, ROM-version-dependent. Mitigated by `resolveActivity` guard + dontkillmyapp.com URL fallback.
- Schedule helper truth table: HIGH — pure-Dart function with deterministic test matrix
- PLAY-06 disclosure: HIGH — derived from `docs/play-declaration.md` §4 (verbatim source)
- Drift v1→v2 migration: HIGH — standard `addColumn` pattern, NOT NULL default verified compatible
- Pitfalls: HIGH — every pitfall cross-referenced to `research/PITFALLS.md` or to a specific GitHub issue / official doc

**Research date:** 2026-05-05
**Valid until:** 2026-06-05 (30 days — the stack is stable; only `dynamic_color` minor versions and OEM ROM revisions are likely to drift in this window)

## RESEARCH COMPLETE
