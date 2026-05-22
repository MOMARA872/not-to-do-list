package com.nottodo.not_to_do_list.service

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * JVM oracle for cross-midnight day-anchoring in the streak engine (Plan 05-03).
 *
 * Mirrors ScheduleWindowTest.kt JUnit 4 + Calendar.getInstance ms helper.
 * Verifies that streakDayFor() from StreakDay.kt returns the correct local
 * midnight (epoch ms) for cross-midnight and always-on entry scenarios.
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
     * Returns epoch milliseconds for local midnight of a given date.
     */
    private fun midnight(year: Int, month: Int, day: Int): Long {
        val cal = Calendar.getInstance(TimeZone.getDefault())
        cal.set(year, month - 1, day, 0, 0, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    /**
     * Cross-midnight window (22:00–06:00): at 23:00 Mon (2026-01-05),
     * the streak day belongs to Mon midnight (not Tue).
     *
     * Expected: streakDayFor(2026-01-05 23:00) = 2026-01-05 midnight
     *
     * The 04:00 shift means 23:00 − 4h = 19:00 on Jan 5 → strips to Jan 5 midnight.
     */
    @Test
    fun crossMidnight_2200_to_0600_pointAt2300Mon_returnsMonMidnight() {
        val inputMs = ms(2026, 1, 5, 23, 0)  // Mon 2026-01-05 23:00
        val expected = midnight(2026, 1, 5)    // Mon 2026-01-05 midnight
        assertEquals(expected, streakDayFor(inputMs))
    }

    /**
     * Cross-midnight window (22:00–06:00): at 03:00 Tue (2026-01-06),
     * the streak day still belongs to Mon midnight (the 4h shift puts us
     * at 23:00 Mon, still Jan 5).
     *
     * Expected: streakDayFor(2026-01-06 03:00) = 2026-01-05 midnight
     *
     * 03:00 − 4h = 23:00 Jan 5 → strips to Jan 5 midnight.
     */
    @Test
    fun crossMidnight_2200_to_0600_pointAt0300Tue_returnsMonMidnight() {
        val inputMs = ms(2026, 1, 6, 3, 0)   // Tue 2026-01-06 03:00
        val expected = midnight(2026, 1, 5)   // Mon 2026-01-05 midnight
        assertEquals(expected, streakDayFor(inputMs))
    }

    /**
     * Always-on entry at midday Tue: 12:00 − 4h = 08:00 Tue → Tue midnight.
     * Control case: midday returns its own calendar day midnight.
     *
     * Expected: streakDayFor(2026-01-06 12:00) = 2026-01-06 midnight
     */
    @Test
    fun alwaysOnEntry_pointMidday_Tue_returnsTueMidnight() {
        val inputMs = ms(2026, 1, 6, 12, 0)   // Tue 2026-01-06 12:00
        val expected = midnight(2026, 1, 6)    // Tue 2026-01-06 midnight
        assertEquals(expected, streakDayFor(inputMs))
    }
}
