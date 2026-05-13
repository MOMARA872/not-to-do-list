package com.nottodo.not_to_do_list.service

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * JVM unit test for ScheduleWindow.kt — pinned to the SAME 200+ tuples as
 * test/domain/schedule/schedule_window_parity_test.dart (D-12 parity oracle).
 *
 * If a tuple here disagrees with the Dart side, fix the Kotlin port — the
 * Dart helper (Phase 2 frozen surface) is the contract.
 *
 * All tuples use TimeZone.getDefault() to match the Dart side's local-time
 * semantics (Dart: DateTime(y,m,d,h,min) is local; toLocal() is a no-op).
 *
 * Run: ./gradlew :app:test
 */
class ScheduleWindowTest {

    // Weekday mask bits (Mon=bit0…Sun=bit6, matching Dart DateTime.weekday)
    private val kMon = 0x01
    private val kTue = 0x02
    private val kWed = 0x04
    private val kThu = 0x08
    private val kFri = 0x10
    private val kSat = 0x20
    private val kSun = 0x40
    private val kWeekdays = kMon or kTue or kWed or kThu or kFri // 0x1F
    private val kWeekend = kSat or kSun // 0x60
    private val kAllDays = 0x7F

    /**
     * Convert local calendar date/time to epoch milliseconds.
     * month is 1-based (Jan=1) to match Dart and human-readable labels.
     * Mirrors Dart's DateTime(year, month, day, hour, minute).
     */
    private fun ms(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance(TimeZone.getDefault())
        cal.set(year, month - 1, day, hour, minute, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun win(nowMs: Long, s: Int?, e: Int?, m: Int?): Boolean =
        isInScheduleWindow(nowEpochMs = nowMs, startMinutes = s, endMinutes = e, weekdayMask = m)

    // ------------------------------------------------------------------
    // GROUP 1: Null / partial-null (20 tuples) — any null → false
    // ------------------------------------------------------------------

    @Test fun allNullsReturnFalse() {
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), null, null, null))   // Mon 10:00
        assertEquals(false, win(ms(2026, 1, 5, 0, 0), null, null, null))    // Mon midnight
        assertEquals(false, win(ms(2026, 1, 10, 12, 0), null, null, null))  // Sat noon
        assertEquals(false, win(ms(2026, 1, 11, 23, 59), null, null, null)) // Sun 23:59
    }

    @Test fun startNullReturnsFalse() {
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), null, 1020, kAllDays)) // start=null
        assertEquals(false, win(ms(2026, 1, 5, 14, 0), null, 540, kMon))      // cross-midnight scenario
        assertEquals(false, win(ms(2026, 1, 5, 8, 0), null, 0, kWeekdays))    // zero-end
        assertEquals(false, win(ms(2026, 1, 5, 12, 0), null, 1440, kAllDays)) // max-end
    }

    @Test fun endNullReturnsFalse() {
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), 540, null, kAllDays)) // end=null
        assertEquals(false, win(ms(2026, 1, 5, 23, 0), 1320, null, kMon))   // cross-midnight start
        assertEquals(false, win(ms(2026, 1, 5, 0, 0), 0, null, kWeekdays))  // zero-start
        assertEquals(false, win(ms(2026, 1, 5, 9, 0), 540, null, kSat))     // wrong-mask
    }

    @Test fun maskNullReturnsFalse() {
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), 540, 1020, null)) // same-day in-range
        assertEquals(false, win(ms(2026, 1, 5, 23, 0), 1320, 360, null)) // cross-midnight head
        assertEquals(false, win(ms(2026, 1, 5, 2, 0), 1320, 360, null))  // cross-midnight tail
        assertEquals(false, win(ms(2026, 1, 5, 12, 0), 540, 1020, null)) // midday
    }

    @Test fun partialNullsReturnFalse() {
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), 540, null, null))    // only start
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), null, 1020, null))   // only end
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), null, null, kAllDays)) // only mask
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), 0, null, null))      // only zero-start
    }

    // ------------------------------------------------------------------
    // GROUP 2a: Same-day — Monday 2026-01-05 (weekday=1, kMon=0x01)
    // Window 09:00-17:00 (start=540, end=1020)
    // ------------------------------------------------------------------

    @Test fun sameDayMidWindow() {
        assertEquals(true, win(ms(2026, 1, 5, 12, 0), 540, 1020, kMon))      // Mon mid-window
        assertEquals(true, win(ms(2026, 1, 5, 10, 0), 540, 1020, kAllDays))  // Mon alldays-mask
        assertEquals(true, win(ms(2026, 1, 5, 10, 0), 540, 1020, kWeekdays)) // Mon weekdays-mask
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), 540, 1020, kWeekend)) // Mon weekend-mask-false
        assertEquals(false, win(ms(2026, 1, 5, 12, 0), 540, 1020, kTue))     // Mon wrong-mask-tue
        // Tue 2026-01-06
        assertEquals(true, win(ms(2026, 1, 6, 12, 0), 540, 1020, kTue))      // Tue mid-window
        assertEquals(true, win(ms(2026, 1, 6, 12, 0), 540, 1020, kWeekdays)) // Tue weekdays-mask
        assertEquals(false, win(ms(2026, 1, 6, 12, 0), 540, 1020, kMon))     // Tue wrong-mask-mon
        // Wed 2026-01-07
        assertEquals(true, win(ms(2026, 1, 7, 12, 0), 540, 1020, kWed))      // Wed mid-window
        assertEquals(true, win(ms(2026, 1, 7, 12, 0), 540, 1020, kWeekdays)) // Wed weekdays-mask
        assertEquals(false, win(ms(2026, 1, 7, 12, 0), 540, 1020, kMon))     // Wed wrong-mask-mon
        // Thu 2026-01-08
        assertEquals(true, win(ms(2026, 1, 8, 12, 0), 540, 1020, kThu))      // Thu mid-window
        assertEquals(true, win(ms(2026, 1, 8, 12, 0), 540, 1020, kWeekdays)) // Thu weekdays-mask
        assertEquals(false, win(ms(2026, 1, 8, 12, 0), 540, 1020, kWeekend)) // Thu weekend-mask-false
        assertEquals(true, win(ms(2026, 1, 8, 10, 0), 540, 1020, kAllDays))  // alldays-on-thu
        // Fri 2026-01-09
        assertEquals(true, win(ms(2026, 1, 9, 12, 0), 540, 1020, kFri))      // Fri mid-window
        assertEquals(true, win(ms(2026, 1, 9, 12, 0), 540, 1020, kWeekdays)) // Fri weekdays-mask
        assertEquals(false, win(ms(2026, 1, 9, 12, 0), 540, 1020, kWeekend)) // Fri weekend-mask-false
        // Sat 2026-01-10
        assertEquals(true, win(ms(2026, 1, 10, 12, 0), 540, 1020, kSat))      // Sat mid-window
        assertEquals(true, win(ms(2026, 1, 10, 12, 0), 540, 1020, kWeekend))  // Sat weekend-mask
        assertEquals(false, win(ms(2026, 1, 10, 12, 0), 540, 1020, kWeekdays))// Sat weekdays-false
        assertEquals(true, win(ms(2026, 1, 10, 10, 0), 540, 1020, kAllDays))  // alldays-on-sat
        assertEquals(true, win(ms(2026, 1, 10, 10, 0), 540, 1020, kWeekend))  // weekend-on-sat
        // Sun 2026-01-11
        assertEquals(true, win(ms(2026, 1, 11, 12, 0), 540, 1020, kSun))      // Sun mid-window
        assertEquals(true, win(ms(2026, 1, 11, 12, 0), 540, 1020, kWeekend))  // Sun weekend-mask
        assertEquals(false, win(ms(2026, 1, 11, 12, 0), 540, 1020, kWeekdays))// Sun weekdays-false
        assertEquals(true, win(ms(2026, 1, 11, 10, 0), 540, 1020, kAllDays))  // alldays-on-sun
        assertEquals(true, win(ms(2026, 1, 11, 10, 0), 540, 1020, kWeekend))  // weekend-on-sun
        // Mon|Wed mask combos
        assertEquals(true, win(ms(2026, 1, 5, 10, 0), 540, 1020, kMon or kWed))  // mon-wed on Mon
        assertEquals(false, win(ms(2026, 1, 6, 10, 0), 540, 1020, kMon or kWed)) // mon-wed on Tue
        assertEquals(true, win(ms(2026, 1, 7, 10, 0), 540, 1020, kMon or kWed))  // mon-wed on Wed
    }

    @Test fun sameDayAtStart_inclusive() {
        assertEquals(true, win(ms(2026, 1, 5, 9, 0), 540, 1020, kMon))    // Mon at-start
        assertEquals(true, win(ms(2026, 1, 6, 9, 0), 540, 1020, kTue))    // Tue at-start
        assertEquals(true, win(ms(2026, 1, 8, 9, 0), 540, 1020, kThu))    // Thu at-start
        assertEquals(true, win(ms(2026, 1, 9, 9, 0), 540, 1020, kFri))    // Fri at-start
        assertEquals(true, win(ms(2026, 1, 10, 9, 0), 540, 1020, kSat))   // Sat at-start
        assertEquals(true, win(ms(2026, 1, 11, 9, 0), 540, 1020, kSun))   // Sun at-start
        assertEquals(true, win(ms(2026, 1, 5, 9, 1), 540, 1020, kAllDays))// one-min-after-start
    }

    @Test fun sameDayAtEnd_exclusive() {
        assertEquals(false, win(ms(2026, 1, 5, 17, 0), 540, 1020, kMon))   // Mon at-end-exclusive
        assertEquals(false, win(ms(2026, 1, 6, 17, 0), 540, 1020, kTue))   // Tue at-end
        assertEquals(false, win(ms(2026, 1, 8, 17, 0), 540, 1020, kThu))   // Thu at-end
        assertEquals(false, win(ms(2026, 1, 9, 17, 0), 540, 1020, kFri))   // Fri at-end
        assertEquals(false, win(ms(2026, 1, 10, 17, 0), 540, 1020, kSat))  // Sat at-end
        assertEquals(false, win(ms(2026, 1, 11, 17, 0), 540, 1020, kSun))  // Sun at-end
        assertEquals(true, win(ms(2026, 1, 5, 16, 59), 540, 1020, kMon))   // one-min-before-end
    }

    @Test fun sameDayWeekdayMismatch() {
        assertEquals(false, win(ms(2026, 1, 5, 18, 0), 540, 1020, kMon))   // after-end
        assertEquals(false, win(ms(2026, 1, 5, 8, 59), 540, 1020, kMon))   // before-start
        assertEquals(false, win(ms(2026, 1, 7, 8, 0), 540, 1020, kWed))    // Wed before-start
        assertEquals(false, win(ms(2026, 1, 7, 17, 30), 540, 1020, kWed))  // Wed after-end
        assertEquals(false, win(ms(2026, 1, 5, 5, 0), 540, 1020, kAllDays))// before-window alldays
        assertEquals(false, win(ms(2026, 1, 5, 20, 0), 540, 1020, kAllDays))// after-window alldays
        assertEquals(false, win(ms(2026, 1, 5, 8, 59), 540, 1020, kAllDays))// one-min-before-start
    }

    @Test fun sameDayEdgeCases() {
        // Zero-width window (start == end → empty [start,start) → always false)
        assertEquals(false, win(ms(2026, 1, 5, 9, 0), 540, 540, kAllDays))   // at start
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), 540, 540, kAllDays))  // after start
        // Full-day-ish window 00:00-23:59
        assertEquals(true, win(ms(2026, 1, 5, 12, 0), 0, 1439, kMon))        // mid
        assertEquals(true, win(ms(2026, 1, 5, 0, 0), 0, 1439, kMon))         // at-start
        assertEquals(false, win(ms(2026, 1, 5, 23, 59), 0, 1439, kMon))      // at-end-exclusive
        // One-minute window 10:30-10:31
        assertEquals(true, win(ms(2026, 1, 5, 10, 30), 630, 631, kMon))      // in window
        assertEquals(false, win(ms(2026, 1, 5, 10, 31), 630, 631, kMon))     // at end
        // Window 10:00-12:00 crossing noon
        assertEquals(true, win(ms(2026, 1, 5, 11, 59), 600, 720, kAllDays))  // before noon
        assertEquals(false, win(ms(2026, 1, 5, 12, 0), 600, 720, kAllDays))  // at end exclusive
        assertEquals(true, win(ms(2026, 1, 5, 11, 0), 600, 720, kAllDays))   // 11:00 in window
        assertEquals(false, win(ms(2026, 1, 5, 12, 0), 600, 720, kTue))      // wrong day
        // Midnight to noon window
        assertEquals(true, win(ms(2026, 1, 5, 6, 0), 0, 720, kMon))          // 06:00 in window
        assertEquals(false, win(ms(2026, 1, 5, 12, 0), 0, 720, kMon))        // noon at end exclusive
    }

    // ------------------------------------------------------------------
    // GROUP 3a: Cross-midnight head (today is the START day)
    // Window 22:00(1320)→06:00(360)
    // ------------------------------------------------------------------

    @Test fun crossMidnightHead_todayBit() {
        assertEquals(true, win(ms(2026, 1, 5, 23, 0), 1320, 360, kMon))     // head-Mon-23:00-monMask
        assertEquals(true, win(ms(2026, 1, 5, 23, 0), 1320, 360, kAllDays)) // head-Mon-23:00-alldays
        assertEquals(false, win(ms(2026, 1, 5, 23, 0), 1320, 360, kTue))    // head-Mon-23:00-tue-mask-false
        assertEquals(true, win(ms(2026, 1, 5, 23, 0), 1320, 360, kWeekdays))// head-Mon-23:00-weekdays
        assertEquals(true, win(ms(2026, 1, 5, 22, 0), 1320, 360, kMon))     // head-Mon-at-start-22:00
        assertEquals(true, win(ms(2026, 1, 5, 23, 59), 1320, 360, kMon))    // head-Mon-23:59
        assertEquals(true, win(ms(2026, 1, 6, 23, 0), 1320, 360, kTue))     // head-Tue-23:00-tueMask
        assertEquals(false, win(ms(2026, 1, 6, 23, 0), 1320, 360, kMon))    // head-Tue-23:00-monMask-false
        assertEquals(true, win(ms(2026, 1, 7, 23, 0), 1320, 360, kWed))     // head-Wed-23:00
        assertEquals(true, win(ms(2026, 1, 8, 23, 0), 1320, 360, kThu))     // head-Thu-23:00
        assertEquals(true, win(ms(2026, 1, 9, 23, 0), 1320, 360, kFri))     // head-Fri-23:00
        assertEquals(true, win(ms(2026, 1, 10, 23, 0), 1320, 360, kSat))    // head-Sat-23:00
        assertEquals(true, win(ms(2026, 1, 11, 23, 0), 1320, 360, kSun))    // head-Sun-23:00
        assertEquals(true, win(ms(2026, 1, 11, 23, 0), 1320, 360, kWeekend))// head-Sun-23:00-weekend
        assertEquals(false, win(ms(2026, 1, 9, 23, 0), 1320, 360, kWeekend))// head-Fri-23:00-weekend-false
        assertEquals(true, win(ms(2026, 1, 5, 22, 0), 1320, 360, kAllDays)) // head-at-start-exact
        assertEquals(false, win(ms(2026, 1, 5, 21, 59), 1320, 360, kAllDays))// head-one-min-before-start-false
        assertEquals(true, win(ms(2026, 1, 5, 23, 30), 1320, 360, kWeekdays))// head-Mon-23:30-weekdays
        assertEquals(false, win(ms(2026, 1, 10, 23, 0), 1320, 360, kWeekdays))// head-Sat-23:00-weekdays-false
        assertEquals(true, win(ms(2026, 1, 5, 22, 1), 1320, 360, kMon))     // head-Mon-22:01
    }

    // ------------------------------------------------------------------
    // GROUP 3b: Cross-midnight tail (START day was yesterday)
    // START-day semantics: at 01:00 Tue, the window started on Mon.
    // ------------------------------------------------------------------

    @Test fun crossMidnightTail_yesterdayBit_startDay() {
        assertEquals(true, win(ms(2026, 1, 6, 1, 0), 1320, 360, kMon))     // Tue-01:00-monMask (START=Mon)
        assertEquals(false, win(ms(2026, 1, 6, 1, 0), 1320, 360, kTue))    // Tue-01:00-tueMask-false
        assertEquals(true, win(ms(2026, 1, 6, 1, 0), 1320, 360, kAllDays)) // Tue-01:00-alldays
        assertEquals(true, win(ms(2026, 1, 6, 1, 0), 1320, 360, kWeekdays))// Tue-01:00-weekdays (Mon weekday)
        assertEquals(true, win(ms(2026, 1, 6, 0, 0), 1320, 360, kMon))     // Tue-00:00-monMask
        assertEquals(false, win(ms(2026, 1, 6, 0, 0), 1320, 360, kTue))    // Tue-00:00-tueMask-false
        assertEquals(false, win(ms(2026, 1, 6, 6, 0), 1320, 360, kMon))    // Tue-06:00-at-end-exclusive
        assertEquals(true, win(ms(2026, 1, 6, 5, 59), 1320, 360, kMon))    // Tue-05:59-one-min-before-end
        assertEquals(true, win(ms(2026, 1, 7, 0, 30), 1320, 360, kTue))    // Wed-00:30-tueMask (yesterday=Tue)
        assertEquals(false, win(ms(2026, 1, 7, 0, 30), 1320, 360, kWed))   // Wed-00:30-wedMask-false
        assertEquals(true, win(ms(2026, 1, 8, 1, 30), 1320, 360, kWed))    // Thu-01:30-wedMask (yesterday=Wed)
        assertEquals(false, win(ms(2026, 1, 8, 1, 30), 1320, 360, kThu))   // Thu-01:30-thuMask-false
        assertEquals(true, win(ms(2026, 1, 9, 3, 0), 1320, 360, kThu))     // Fri-03:00-thuMask (yesterday=Thu)
        assertEquals(true, win(ms(2026, 1, 10, 2, 0), 1320, 360, kFri))    // Sat-02:00-friMask (yesterday=Fri)
        assertEquals(true, win(ms(2026, 1, 10, 2, 0), 1320, 360, kWeekdays))// Sat-02:00-weekdays (yesterday=Fri)
        assertEquals(true, win(ms(2026, 1, 11, 1, 0), 1320, 360, kSat))    // Sun-01:00-satMask (yesterday=Sat)
        assertEquals(true, win(ms(2026, 1, 11, 1, 0), 1320, 360, kWeekend))// Sun-01:00-weekend (yesterday=Sat)
        assertEquals(true, win(ms(2026, 1, 5, 1, 0), 1320, 360, kSun))     // Mon-01:00-sunMask (yesterday=Sun)
        assertEquals(true, win(ms(2026, 1, 5, 1, 0), 1320, 360, kWeekend)) // Mon-01:00-weekend (yesterday=Sun)
        assertEquals(false, win(ms(2026, 1, 5, 1, 0), 1320, 360, kWeekdays))// Mon-01:00-weekdays-false (yesterday=Sun)
    }

    // ------------------------------------------------------------------
    // GROUP 3c: Cross-midnight gap (14 tuples → false)
    // ------------------------------------------------------------------

    @Test fun crossMidnightGap_returnsFalse() {
        assertEquals(false, win(ms(2026, 1, 5, 6, 0), 1320, 360, kAllDays))   // gap-06:00-at-end
        assertEquals(false, win(ms(2026, 1, 5, 7, 0), 1320, 360, kAllDays))   // gap-07:00
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), 1320, 360, kAllDays))  // gap-10:00
        assertEquals(false, win(ms(2026, 1, 5, 12, 0), 1320, 360, kAllDays))  // gap-noon
        assertEquals(false, win(ms(2026, 1, 5, 17, 0), 1320, 360, kAllDays))  // gap-17:00
        assertEquals(false, win(ms(2026, 1, 5, 21, 0), 1320, 360, kAllDays))  // gap-21:00
        assertEquals(false, win(ms(2026, 1, 5, 21, 59), 1320, 360, kAllDays)) // gap-21:59-one-min-before-start
        assertEquals(false, win(ms(2026, 1, 5, 14, 0), 1320, 360, kMon))      // gap-Mon-14:00-monMask
        assertEquals(false, win(ms(2026, 1, 6, 6, 0), 1320, 360, kAllDays))   // gap-Tue-06:00-at-tail-end
        // Narrow: 23:30(1410)→00:30(30)
        assertEquals(false, win(ms(2026, 1, 5, 1, 0), 1410, 30, kAllDays))    // gap-narrow-01:00
        assertEquals(false, win(ms(2026, 1, 5, 12, 0), 1410, 30, kAllDays))   // gap-narrow-noon
        assertEquals(false, win(ms(2026, 1, 5, 23, 29), 1410, 30, kAllDays))  // gap-narrow-23:29
        assertEquals(false, win(ms(2026, 1, 6, 0, 30), 1410, 30, kAllDays))   // gap-narrow-Tue-00:30-at-end
        assertEquals(false, win(ms(2026, 1, 6, 1, 0), 1410, 30, kAllDays))    // gap-narrow-Tue-01:00
    }

    // ------------------------------------------------------------------
    // GROUP 3d: Narrow cross-midnight head+tail (6 tuples)
    // Window 23:30(1410)→00:30(30)
    // ------------------------------------------------------------------

    @Test fun crossMidnightNarrowWindow() {
        assertEquals(true, win(ms(2026, 1, 5, 23, 30), 1410, 30, kMon))   // narrow-head-Mon-at-start
        assertEquals(true, win(ms(2026, 1, 5, 23, 50), 1410, 30, kMon))   // narrow-head-Mon-23:50
        assertEquals(true, win(ms(2026, 1, 6, 0, 0), 1410, 30, kMon))     // narrow-tail-Tue-00:00-monMask
        assertEquals(true, win(ms(2026, 1, 6, 0, 29), 1410, 30, kMon))    // narrow-tail-Tue-00:29-one-min-before-end
        assertEquals(false, win(ms(2026, 1, 6, 0, 0), 1410, 30, kTue))    // narrow-tail-Tue-00:00-tueMask-false
        assertEquals(true, win(ms(2026, 1, 6, 0, 0), 1410, 30, kAllDays)) // narrow-tail-Tue-00:00-alldays
    }

    // ------------------------------------------------------------------
    // GROUP 3e: Cross-midnight per-weekday combos (50 tuples)
    // Window 21:00(1260)→03:00(180)
    // ------------------------------------------------------------------

    @Test fun crossMidnightHead_todayBit_window2() {
        val s = 1260; val e = 180
        // Mon head
        assertEquals(true, win(ms(2026, 1, 5, 21, 0), s, e, kMon))      // head-Mon-at-start
        assertEquals(true, win(ms(2026, 1, 5, 22, 0), s, e, kMon))      // head-Mon-22:00
        assertEquals(true, win(ms(2026, 1, 5, 23, 59), s, e, kMon))     // head-Mon-23:59
        assertEquals(false, win(ms(2026, 1, 5, 21, 0), s, e, kTue))     // head-Mon-21:00-tueMask-false
        assertEquals(false, win(ms(2026, 1, 5, 20, 59), s, e, kAllDays))// gap-Mon-20:59-before-start
        assertEquals(false, win(ms(2026, 1, 5, 10, 0), s, e, kAllDays)) // gap-Mon-10:00
        // Tue head
        assertEquals(true, win(ms(2026, 1, 6, 21, 0), s, e, kTue))      // head-Tue-at-start
        assertEquals(true, win(ms(2026, 1, 6, 23, 0), s, e, kTue))      // head-Tue-23:00
        assertEquals(false, win(ms(2026, 1, 6, 21, 0), s, e, kWed))     // head-Tue-21:00-wedMask-false
        // Wed head
        assertEquals(true, win(ms(2026, 1, 7, 21, 0), s, e, kWed))      // head-Wed-at-start
        assertEquals(true, win(ms(2026, 1, 7, 23, 0), s, e, kWed))      // head-Wed-23:00
        assertEquals(false, win(ms(2026, 1, 7, 21, 0), s, e, kThu))     // head-Wed-21:00-thuMask-false
        // Thu head
        assertEquals(true, win(ms(2026, 1, 8, 21, 0), s, e, kThu))      // head-Thu-at-start
        assertEquals(true, win(ms(2026, 1, 8, 23, 0), s, e, kThu))      // head-Thu-23:00
        assertEquals(false, win(ms(2026, 1, 8, 21, 0), s, e, kFri))     // head-Thu-21:00-friMask-false
        // Fri head
        assertEquals(true, win(ms(2026, 1, 9, 21, 0), s, e, kFri))      // head-Fri-at-start
        assertEquals(true, win(ms(2026, 1, 9, 23, 0), s, e, kFri))      // head-Fri-23:00
        assertEquals(false, win(ms(2026, 1, 9, 21, 0), s, e, kSat))     // head-Fri-21:00-satMask-false
        // Sat head
        assertEquals(true, win(ms(2026, 1, 10, 21, 0), s, e, kSat))     // head-Sat-at-start
        assertEquals(true, win(ms(2026, 1, 10, 23, 0), s, e, kSat))     // head-Sat-23:00
        assertEquals(false, win(ms(2026, 1, 10, 21, 0), s, e, kSun))    // head-Sat-21:00-sunMask-false
        // Sun head
        assertEquals(true, win(ms(2026, 1, 11, 21, 0), s, e, kSun))     // head-Sun-at-start
        assertEquals(true, win(ms(2026, 1, 11, 23, 0), s, e, kSun))     // head-Sun-23:00
        assertEquals(false, win(ms(2026, 1, 11, 21, 0), s, e, kMon))    // head-Sun-21:00-monMask-false
    }

    @Test fun crossMidnightTail_yesterdayBit_window2() {
        val s = 1260; val e = 180
        // Tue tail (start=Mon)
        assertEquals(true, win(ms(2026, 1, 6, 1, 0), s, e, kMon))       // tail-Tue-01:00-monMask (start=Mon)
        assertEquals(true, win(ms(2026, 1, 6, 2, 59), s, e, kMon))      // tail-Tue-02:59-monMask
        assertEquals(false, win(ms(2026, 1, 6, 3, 0), s, e, kMon))      // tail-Tue-03:00-at-end-exclusive
        assertEquals(false, win(ms(2026, 1, 6, 1, 0), s, e, kTue))      // tail-Tue-01:00-tueMask-false
        // Wed tail (start=Tue)
        assertEquals(true, win(ms(2026, 1, 7, 1, 0), s, e, kTue))       // tail-Wed-01:00-tueMask (start=Tue)
        assertEquals(false, win(ms(2026, 1, 7, 1, 0), s, e, kWed))      // tail-Wed-01:00-wedMask-false
        // Thu tail (start=Wed)
        assertEquals(true, win(ms(2026, 1, 8, 1, 0), s, e, kWed))       // tail-Thu-01:00-wedMask (start=Wed)
        assertEquals(false, win(ms(2026, 1, 8, 1, 0), s, e, kThu))      // tail-Thu-01:00-thuMask-false
        // Fri tail (start=Thu)
        assertEquals(true, win(ms(2026, 1, 9, 1, 0), s, e, kThu))       // tail-Fri-01:00-thuMask (start=Thu)
        assertEquals(false, win(ms(2026, 1, 9, 1, 0), s, e, kFri))      // tail-Fri-01:00-friMask-false
        // Sat tail (start=Fri)
        assertEquals(true, win(ms(2026, 1, 10, 1, 0), s, e, kFri))      // tail-Sat-01:00-friMask (start=Fri)
        assertEquals(false, win(ms(2026, 1, 10, 1, 0), s, e, kSat))     // tail-Sat-01:00-satMask-false
        // Sun tail (start=Sat)
        assertEquals(true, win(ms(2026, 1, 11, 1, 0), s, e, kSat))      // tail-Sun-01:00-satMask (start=Sat)
        assertEquals(false, win(ms(2026, 1, 11, 1, 0), s, e, kSun))     // tail-Sun-01:00-sunMask-false
        // Mon tail (start=Sun) — 2026-01-12 = Mon
        assertEquals(true, win(ms(2026, 1, 12, 1, 0), s, e, kSun))      // tail-Mon2-01:00-sunMask (start=Sun)
        assertEquals(false, win(ms(2026, 1, 12, 1, 0), s, e, kMon))     // tail-Mon2-01:00-monMask-false
    }

    // ------------------------------------------------------------------
    // GROUP 4: Weekday bitmask edges — single-day-only mask (7 tuples)
    // ------------------------------------------------------------------

    @Test fun weekdayBitmaskEdges() {
        assertEquals(true, win(ms(2026, 1, 5, 12, 0), 540, 1020, kMon))   // single-Mon
        assertEquals(true, win(ms(2026, 1, 6, 12, 0), 540, 1020, kTue))   // single-Tue
        assertEquals(true, win(ms(2026, 1, 7, 12, 0), 540, 1020, kWed))   // single-Wed
        assertEquals(true, win(ms(2026, 1, 8, 12, 0), 540, 1020, kThu))   // single-Thu
        assertEquals(true, win(ms(2026, 1, 9, 12, 0), 540, 1020, kFri))   // single-Fri
        assertEquals(true, win(ms(2026, 1, 10, 12, 0), 540, 1020, kSat))  // single-Sat
        assertEquals(true, win(ms(2026, 1, 11, 12, 0), 540, 1020, kSun))  // single-Sun
    }

    // ------------------------------------------------------------------
    // GROUP 5: DST boundary tuples (8 tuples)
    // Uses TimeZone.getDefault() matching Dart's local DateTime semantics.
    // Spring forward 2026-03-08 (Sunday); Fall back 2025-11-02 (Sunday).
    // America/Los_Angeles DST transition dates — local TZ used for epoch.
    // ------------------------------------------------------------------

    @Test fun dstBoundary() {
        // Spring forward 2026-03-08 (Sun): window 01:00-03:00 (start=60, end=180)
        assertEquals(true, win(ms(2026, 3, 8, 1, 30), 60, 180, kSun))    // spring-fwd 01:30 in window
        assertEquals(false, win(ms(2026, 3, 8, 3, 30), 60, 180, kSun))   // spring-fwd 03:30 after window
        assertEquals(true, win(ms(2026, 3, 8, 2, 30), 60, 180, kSun))    // spring-fwd 02:30 in window
        assertEquals(false, win(ms(2026, 3, 8, 0, 30), 60, 180, kSun))   // spring-fwd 00:30 before window
        // Fall back 2025-11-02 (Sun): window 00:00-02:00 (start=0, end=120)
        assertEquals(true, win(ms(2025, 11, 2, 0, 30), 0, 120, kSun))    // fall-back 00:30 in window
        assertEquals(false, win(ms(2025, 11, 2, 2, 0), 0, 120, kSun))    // fall-back 02:00 at end exclusive
        assertEquals(true, win(ms(2025, 11, 2, 1, 30), 0, 120, kSun))    // fall-back 01:30 in window
        assertEquals(false, win(ms(2025, 11, 2, 2, 30), 0, 120, kSun))   // fall-back 02:30 after window
    }
}
