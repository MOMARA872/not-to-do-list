package com.nottodo.not_to_do_list.service

import java.util.Calendar
import java.util.TimeZone

/**
 * Kotlin port of lib/domain/schedule/streak_day.dart (Phase 5 Plan 05-03).
 *
 * Parity contract: semantics must be byte-for-byte equivalent to Dart's
 * [streakDayFor] — anchored by StreakDayAnchoringTest.kt.
 *
 * v1 day boundary: 04:00 local time.
 *   - Anything before 04:00 belongs to the PREVIOUS calendar day's streak.
 *   - Anything at or after 04:00 belongs to TODAY's streak.
 *
 * Example:
 *   02:00 on May 5  → streak day = May 4 midnight
 *   04:00 on May 5  → streak day = May 5 midnight
 *   23:00 on May 5  → streak day = May 5 midnight
 *
 * @param nowMs epoch milliseconds (local clock).
 * @return epoch milliseconds of local midnight for the streak day.
 */
fun streakDayFor(nowMs: Long): Long {
    val tz = TimeZone.getDefault()

    // Apply 4-hour subtraction (mirrors Dart: local.subtract(Duration(hours: 4)))
    val shiftedMs = nowMs - 4L * 60L * 60L * 1000L

    // Strip to local midnight (mirrors Dart: DateTime(shifted.year, shifted.month, shifted.day))
    val cal = Calendar.getInstance(tz)
    cal.timeInMillis = shiftedMs
    cal.set(Calendar.HOUR_OF_DAY, 0)
    cal.set(Calendar.MINUTE, 0)
    cal.set(Calendar.SECOND, 0)
    cal.set(Calendar.MILLISECOND, 0)

    return cal.timeInMillis
}
