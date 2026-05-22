package com.nottodo.not_to_do_list.service

import org.junit.Ignore
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * JVM oracle for cross-midnight day-anchoring in the streak engine.
 *
 * Each test body contains only a stub comment — @Ignore until Plan 05-03
 * ships streakDayFor parity logic.
 *
 * Mirrors ScheduleWindowTest.kt JUnit 4 + Calendar.getInstance ms helper.
 *
 * Run: ./gradlew :app:testDebugUnitTest --tests
 *      "com.nottodo.not_to_do_list.service.StreakDayAnchoringTest"
 */
class StreakDayAnchoringTest {

    /**
     * Convert local calendar date/time to epoch milliseconds.
     * month is 1-based (Jan=1) to match Dart and human-readable labels.
     * Mirrors ScheduleWindowTest.ms helper.
     */
    private fun ms(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance(TimeZone.getDefault())
        cal.set(year, month - 1, day, hour, minute, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    /**
     * Cross-midnight window (22:00–06:00) at 23:00 belongs to the START day's
     * streak row, not the next calendar day.
     *
     * Expected: streakDayFor(2026-01-05 23:00) = 2026-01-05 (start day)
     */
    @Ignore("Plan 05-03 fills")
    @Test
    fun crossMidnightStartDayBelongsToStartStreakRow_2200_to_0600() {
        // @Ignore until Plan 05-03 ships streakDayFor parity — see RESEARCH §4 STRK-09
        throw NotImplementedError("Plan 05-03 fills streakDayFor parity")
    }

    /**
     * Same-day window (09:00–17:00) at noon belongs to the calendar day's
     * own streak row (no cross-midnight anchoring needed).
     *
     * Expected: streakDayFor(2026-01-05 12:00) = 2026-01-05
     */
    @Ignore("Plan 05-03 fills")
    @Test
    fun sameDayWindowBelongsToOwnStreakRow() {
        // @Ignore until Plan 05-03 ships streakDayFor parity — see RESEARCH §4 STRK-09
        throw NotImplementedError("Plan 05-03 fills streakDayFor parity")
    }

    /**
     * Always-on entry (no schedule fields) — streak row matches calendar day
     * using the 04:00 boundary (04:00–23:59 and 00:00–03:59 both belong to
     * the streak day that started at 04:00).
     *
     * Expected: times after 04:00 belong to today; times before 04:00 belong
     * to yesterday (the "night owl" boundary from streakDayFor).
     */
    @Ignore("Plan 05-03 fills")
    @Test
    fun alwaysOnEntryBelongsToCalendarDay() {
        // @Ignore until Plan 05-03 ships streakDayFor parity — see RESEARCH §4 STRK-09
        throw NotImplementedError("Plan 05-03 fills streakDayFor parity")
    }
}
