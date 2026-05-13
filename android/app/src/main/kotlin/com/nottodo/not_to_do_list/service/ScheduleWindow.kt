package com.nottodo.not_to_do_list.service

import java.util.Calendar
import java.util.TimeZone

/**
 * Kotlin port of lib/domain/schedule/schedule_window.dart (Phase 2).
 *
 * D-12: byte-for-byte semantic parity with the Dart helper, pinned by
 * 200+ tuples in:
 *   - test/domain/schedule/schedule_window_parity_test.dart (Dart side)
 *   - android/app/src/test/.../ScheduleWindowTest.kt        (Kotlin side)
 *
 * Called by NotToDoAccessibilityService (Plan 04-05) to gate Intent launches
 * on PAUS-10 schedule windows. Outside the window: launch passes through.
 *
 * Same-day windows (start <= end) use a half-open interval [start, end).
 * Cross-midnight windows (end < start) cover [today.start..tomorrow.end];
 * the weekday mask refers to the START day (so a "weekdays-only 22:00–06:00"
 * schedule is active Mon-night-into-Tue, not Mon-night-into-Mon).
 *
 * PLAY-02: this file does pure time arithmetic; no AccessibilityService API
 * surface. Forbidden tokens are not present.
 */
fun isInScheduleWindow(
    nowEpochMs: Long,
    startMinutes: Int?,
    endMinutes: Int?,
    weekdayMask: Int?,
    timeZone: TimeZone = TimeZone.getDefault(),
): Boolean {
    // Null-guard: all three must be non-null (matches Dart line 38-40)
    if (startMinutes == null || endMinutes == null || weekdayMask == null) return false

    // Convert epoch + timezone to local hour/minute/weekday (mirrors Dart's now.toLocal())
    val cal = Calendar.getInstance(timeZone)
    cal.timeInMillis = nowEpochMs
    val nowMin = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)

    // Java Calendar: SUN=1..SAT=7. Dart: MON=1..SUN=7.
    // Conversion: dartWeekday = ((javaDayOfWeek + 5) % 7) + 1
    val dartToday = ((cal.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1
    val todayBit = 1 shl (dartToday - 1)

    return if (startMinutes <= endMinutes) {
        // Same-day window [start, end): half-open (matches Dart line 45-49)
        val inWindow = nowMin >= startMinutes && nowMin < endMinutes
        inWindow && (weekdayMask and todayBit) != 0
    } else {
        // Cross-midnight window (end < start)
        if (nowMin >= startMinutes) {
            // Head [start..midnight): check TODAY's weekday bit (START day)
            (weekdayMask and todayBit) != 0
        } else if (nowMin < endMinutes) {
            // Tail [midnight..end): START day was YESTERDAY — check yesterday's bit
            val yCal = Calendar.getInstance(timeZone)
            yCal.timeInMillis = nowEpochMs - 86_400_000L
            val dartYesterday = ((yCal.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1
            val yBit = 1 shl (dartYesterday - 1)
            (weekdayMask and yBit) != 0
        } else {
            // Gap [end..start): outside the window
            false
        }
    }
}
