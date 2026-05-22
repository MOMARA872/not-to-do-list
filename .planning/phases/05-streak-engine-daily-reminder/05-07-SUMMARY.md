---
phase: 05-streak-engine-daily-reminder
plan: "07"
subsystem: streak-widgets-reminder-banner
tags: [streak, badge, day-dot, history-section, reminder-banner, lifecycle-observer, riverpod, widget-tests]
dependency_graph:
  requires: [05-02, 05-03, 05-04]
  provides:
    - StreakBadge widget (consumes streakBadgeProvider 3-field record read-only)
    - DayDot widget (4-state with mandatory grey tooltip)
    - StreakHistorySection widget (30-day GridView + summary text)
    - ReminderOffBanner widget (NOTF-07 amber banner, three-state tap)
  affects: [05-08-earned-prompt, 05-09-phase-exit]
tech_stack:
  added: []
  patterns:
    - ConsumerWidget-streak-badge
    - StatelessWidget-4state-day-dot
    - ConsumerWidget-streak-history-grid
    - ConsumerWidget-reminder-banner-amber-shell
    - lifecycle-observer-unawaited-calls
key_files:
  created:
    - lib/features/streak/widgets/streak_badge.dart
    - lib/features/streak/widgets/day_dot.dart
    - lib/features/streak/widgets/streak_history_section.dart
    - lib/features/reminder/widgets/reminder_off_banner.dart
  modified:
    - lib/features/home/widgets/block_list_row.dart
    - lib/features/list/pages/edit_entry_screen.dart
    - lib/features/home/pages/home_screen.dart
    - lib/features/health/widgets/_health_lifecycle_observer.dart
    - test/features/streak/streak_badge_test.dart
    - test/features/streak/streak_history_section_test.dart
    - test/features/home/reminder_off_banner_test.dart
decisions:
  - "StreakBadge uses ConsumerWidget consuming streakBadgeProvider family — no local state; matches PATTERNS.md analog"
  - "DayDot grey state wraps inner dot widget in Tooltip before placing in 24x24 container so touch target and tooltip area are correct size"
  - "StreakHistorySection pads rows list to exactly 30 cells using SizedBox(24,24) for empty slots rather than a sentinel status value"
  - "ReminderOffBanner is a ConsumerWidget (not StatelessWidget) to access ref.read(permissionStatusApiProvider) in tap handler"
  - "BlockListRow upgraded from StatelessWidget to ConsumerWidget since StreakBadge (a ConsumerWidget) is now in the widget tree via trailing slot"
metrics:
  duration: "~7 minutes"
  completed: "2026-05-22T20:31:00Z"
  tasks_completed: 1
  files_changed: 11
requirements: [STRK-05, STRK-07, NOTF-07]
---

# Phase 5 Plan 07: StreakBadge + StreakHistorySection + ReminderOffBanner + lazy-rollover hook Summary

4 new widget files + 4 modified files deliver the Home + entry-detail streak UI surfaces and NOTF-07 reminder-off banner; HealthLifecycleObserver gains streak rollover + post-notifications refresh on every AppLifecycleState.resumed; 3 Wave-0 test stubs flipped GREEN (17 tests, 0 skips).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | StreakBadge + DayDot + StreakHistorySection + ReminderOffBanner; wire BlockListRow + EditEntryScreen + HomeScreen + HealthLifecycleObserver; flip 3 Wave 0 widget tests to GREEN | bce61e4 | streak_badge.dart, day_dot.dart, streak_history_section.dart, reminder_off_banner.dart, block_list_row.dart, edit_entry_screen.dart, home_screen.dart, _health_lifecycle_observer.dart, streak_badge_test.dart, streak_history_section_test.dart, reminder_off_banner_test.dart |

## What Was Built

**StreakBadge** (`lib/features/streak/widgets/streak_badge.dart`): `ConsumerWidget` consuming `streakBadgeProvider(entryId)` 3-field record `({int current, int longest, bool breakDetectedToday})`. Standard format: `"🔥 {current} · best {longest}"`. D-05 strikethrough: when `breakDetectedToday==true`, renders `Text.rich` with the current-count span styled `TextDecoration.lineThrough`. Loading/error falls back to `"—"` placeholder (labelSmall, onSurfaceVariant).

**DayDot** (`lib/features/streak/widgets/day_dot.dart`): `StatelessWidget` with 4-state rendering per UI-SPEC §Color 4-State table — green filled (status=0 source=0), blue outlined (status=0 source=1), red filled+× glyph (status=1), grey outlined+— glyph wrapped in mandatory `Tooltip("Tracking was off this day")` (status=2). Today (status=3) renders date number only. Empty cells render `SizedBox(24,24)`. All states wrapped in `Semantics(label: ...)`.

**StreakHistorySection** (`lib/features/streak/widgets/streak_history_section.dart`): `ConsumerWidget` consuming `streakHistoryProvider(entryId)` + `streakBadgeProvider(entryId)`. Layout: Divider → SizedBox(16) → titleMedium label → SizedBox(12) → GridView(7-col, NeverScrollableScrollPhysics, shrinkWrap) → SizedBox(12) → summary text → SizedBox(4) → threshold help text → SizedBox(16). Pads grid to 30 cells.

**ReminderOffBanner** (`lib/features/reminder/widgets/reminder_off_banner.dart`): `ConsumerWidget` copying HealthCheckBanner amber-token shell. Icon: `Icons.notifications_off_outlined`. Copy: `"Reminder is off — tap to fix"`. Three-state tap: `permanently_denied` → `openAppNotificationSettings()` (Pigeon); else → `context.go('/onboarding/permissions/notifications')`. No expand toggle, no dismiss button (T-05-28 mitigation).

**BlockListRow** (`lib/features/home/widgets/block_list_row.dart`): Upgraded from `StatelessWidget` to `ConsumerWidget`. Trailing slot: `Text('—', ...)` replaced with `StreakBadge(entryId: entry.id)`.

**EditEntryScreen** (`lib/features/list/pages/edit_entry_screen.dart`): Surgical splice — `StreakHistorySection(entryId: draft.id)` inserted after `ScheduleEditor` block and before `FilledButton('Save changes')`.

**HomeScreen** (`lib/features/home/pages/home_screen.dart`): Second `AnimatedSwitcher` inserted below the existing HealthCheckBanner switcher, wrapping `ReminderOffBanner` gated on `!postNotificationsGrantedProvider`. Stack order: tracking-offline above reminder-off (D-12).

**HealthLifecycleObserver** (`lib/features/health/widgets/_health_lifecycle_observer.dart`): `resumed` branch gains two new `unawaited` calls: `streakRolloverServiceProvider.notifier.rollover()` (STRK-05) and `postNotificationsGrantedProvider.notifier.refresh()` (NOTF-07 banner state refresh).

## Verification Results

- `flutter test test/features/streak/streak_badge_test.dart` — **4/4 PASS** (0 skips)
- `flutter test test/features/streak/streak_history_section_test.dart` — **8/8 PASS** (0 skips)
- `flutter test test/features/home/reminder_off_banner_test.dart` — **5/5 PASS** (0 skips)
- `flutter analyze lib/features/streak/ lib/features/reminder/ lib/features/home/ lib/features/list/ lib/features/health/` — 0 errors, 0 warnings (info-only: pre-existing line-length in avoided_today_card.dart, cumulative_totals_card.dart, streak_keys.dart)
- `flutter test test/policy/play_invariants_test.dart` — **9/9 PASS** (no PLAY-02 regression)
- `flutter test test/policy/phase_5_invariants_test.dart` — all green (4 expected skips for later plans)
- `grep -c "🔥" streak_badge.dart` = 6
- `grep -c "best" streak_badge.dart` = 6
- `grep -c "breakDetectedToday" streak_badge.dart` = 2
- `grep -c "Tracking was off this day" day_dot.dart` = 1
- `grep -c "Streak history" streak_history_section.dart` = 2
- `grep -c "Streak breaks if you use this app over 5 min/day" streak_history_section.dart` = 2
- `grep -c "Reminder is off — tap to fix" reminder_off_banner.dart` = 1
- `grep -c "Icons.notifications_off_outlined" reminder_off_banner.dart` = 1
- `grep -c "StreakBadge(entryId: entry.id)" block_list_row.dart` = 1
- `grep -c "StreakHistorySection(entryId" edit_entry_screen.dart` = 1
- `grep -c "streakRolloverServiceProvider" _health_lifecycle_observer.dart` = 1 (STRK-05 lock)
- `grep -c "postNotificationsGrantedProvider" _health_lifecycle_observer.dart` = 1
- `grep -c "ReminderOffBanner" home_screen.dart` = 1
- `git diff HEAD~1 -- lib/domain/streak/streak_rollover_service_providers.dart | wc -l` = 0 (providers file untouched)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] BlockListRow upgraded to ConsumerWidget**
- **Found during:** Task 1 (implementation)
- **Issue:** `BlockListRow` was a `StatelessWidget`. The `StreakBadge` (a `ConsumerWidget`) in the trailing slot requires Riverpod's `WidgetRef` to be available in the ancestor tree. `ConsumerWidget` is the correct parent type when the widget tree contains Riverpod consumers.
- **Fix:** Changed `BlockListRow extends StatelessWidget` to `ConsumerWidget` and updated `build(context)` to `build(context, ref)`. No behavioral change — `ref` is passed down implicitly.
- **Files modified:** `lib/features/home/widgets/block_list_row.dart`
- **Commit:** bce61e4 (inline)

## Known Stubs

None. All widgets are wired to real providers. The `streakBadgeProvider` fallback renders `"—"` when loading/error — this is the correct graceful degradation, not a stub.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns beyond the declared threat model. T-05-28 mitigated: `ReminderOffBanner` has no dismiss button (`InkWell(.*onTap.*dismiss` pattern absent).

## Self-Check: PASSED
