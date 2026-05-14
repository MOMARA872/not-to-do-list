// PARITY-TUPLES (mirror in android/.../ScheduleWindowTest.kt):
//
// This file is the Dart side of the D-12 parity oracle. The Kotlin test at
// android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindowTest.kt
// mirrors every tuple below by hand (Kotlin cannot import Dart). If you add
// or change a tuple here, update the Kotlin side too.
//
// Tuple schema: (now, startMinutes, endMinutes, weekdayMask, expected, label)
//
// Weekday mask bits (matching Dart DateTime.weekday: Mon=1..Sun=7 → bit 0..6):
//   Mon=0x01, Tue=0x02, Wed=0x04, Thu=0x08, Fri=0x10, Sat=0x20, Sun=0x40
//
// All DateTime instances use LOCAL time (DateTime(...) without isUtc=true)
// so that now.toLocal() is a no-op and tests are timezone-independent.
// The Kotlin side uses System.currentTimeMillis()-based literals that map to
// the SAME local-calendar values when using TimeZone.getDefault().
//
// For Kotlin: use the helper below to convert a local-time tuple to epochMs:
//   LocalDateTime.of(year, month, day, hour, minute)
//     .atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
// or equivalent via java.util.Calendar:
//   Calendar.getInstance().apply { set(year, month-1, day, hour, minute, 0); set(Calendar.MILLISECOND, 0) }.timeInMillis
//
// Concrete epochMs for UTC machine (UTC offset = 0, used in Kotlin side):
// NOTE: The Kotlin ScheduleWindowTest.kt uses TimeZone.getDefault() which on
// a UTC CI machine gives the UTC offset. For local-time parity testing, the
// Kotlin test constructs Calendar instances directly with local-calendar values.
//
// DST tuples use America/Los_Angeles (UTC-8 standard, UTC-7 daylight):
//   Spring forward 2026-03-08: 02:00 → 03:00 local (gap at 02:00-03:00)
//   Fall back 2025-11-02: 02:00 → 01:00 local (duplicate hour)
// DST tuples in this Dart file use LOCAL DateTime and the machine's local TZ.
// The Kotlin counterpart also uses TimeZone.getDefault() (local TZ), not a pinned
// Pacific timezone. Both sides are locally-consistent but neither exercises real
// DST wall-clock gaps/folds. True DST testing would require pinned TZ + epoch math.

import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/domain/schedule/schedule_window.dart';

// Weekday bitmask constants (Mon=bit0 … Sun=bit6)
const int kMon = 0x01;
const int kTue = 0x02;
const int kWed = 0x04;
const int kThu = 0x08;
const int kFri = 0x10;
const int kSat = 0x20;
const int kSun = 0x40;
const int kWeekdays = kMon | kTue | kWed | kThu | kFri; // 0x1F
const int kWeekend = kSat | kSun; // 0x60
const int kAllDays = 0x7F;

class _Tuple {
  final DateTime now;
  final int? start;
  final int? end;
  final int? mask;
  final bool expected;
  final String label;

  const _Tuple({
    required this.now,
    required this.start,
    required this.end,
    required this.mask,
    required this.expected,
    required this.label,
  });
}

// ---------------------------------------------------------------------------
// Tuple builder — generates all 200+ deterministic test cases.
// All DateTime(...) instances are LOCAL time (no isUtc=true).
//
// Calendar reference (Jan 2026, local dates):
//   2026-01-05 = Monday    (weekday=1, bit0=0x01)
//   2026-01-06 = Tuesday   (weekday=2, bit1=0x02)
//   2026-01-07 = Wednesday (weekday=3, bit2=0x04)
//   2026-01-08 = Thursday  (weekday=4, bit3=0x08)
//   2026-01-09 = Friday    (weekday=5, bit4=0x10)
//   2026-01-10 = Saturday  (weekday=6, bit5=0x20)
//   2026-01-11 = Sunday    (weekday=7, bit6=0x40)
//   2026-01-12 = Monday    (weekday=1)
// ---------------------------------------------------------------------------
List<_Tuple> _buildTuples() {
  final tuples = <_Tuple>[];

  // ------------------------------------------------------------------
  // GROUP 1: Null / partial-null (20 tuples)
  // Any null → false per Dart line 38-40.
  // ------------------------------------------------------------------

  // 1a. All three null (4 tuples)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: null, end: null, mask: null, expected: false, label: 'null/all-null Mon 10:00'),
    _Tuple(now: DateTime(2026, 1, 5, 0, 0), start: null, end: null, mask: null, expected: false, label: 'null/all-null Mon midnight'),
    _Tuple(now: DateTime(2026, 1, 10, 12, 0), start: null, end: null, mask: null, expected: false, label: 'null/all-null Sat noon'),
    _Tuple(now: DateTime(2026, 1, 11, 23, 59), start: null, end: null, mask: null, expected: false, label: 'null/all-null Sun 23:59'),
  ]);

  // 1b. start null (4 tuples)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: null, end: 1020, mask: kAllDays, expected: false, label: 'null/start-null'),
    _Tuple(now: DateTime(2026, 1, 5, 14, 0), start: null, end: 540, mask: kMon, expected: false, label: 'null/start-null cross-midnight scenario'),
    _Tuple(now: DateTime(2026, 1, 5, 8, 0), start: null, end: 0, mask: kWeekdays, expected: false, label: 'null/start-null zero-end'),
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: null, end: 1440, mask: kAllDays, expected: false, label: 'null/start-null max-end'),
  ]);

  // 1c. end null (4 tuples)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 540, end: null, mask: kAllDays, expected: false, label: 'null/end-null'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 0), start: 1320, end: null, mask: kMon, expected: false, label: 'null/end-null cross-midnight start'),
    _Tuple(now: DateTime(2026, 1, 5, 0, 0), start: 0, end: null, mask: kWeekdays, expected: false, label: 'null/end-null zero-start'),
    _Tuple(now: DateTime(2026, 1, 5, 9, 0), start: 540, end: null, mask: kSat, expected: false, label: 'null/end-null wrong-mask'),
  ]);

  // 1d. mask null (4 tuples)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 540, end: 1020, mask: null, expected: false, label: 'null/mask-null same-day in-range'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 0), start: 1320, end: 360, mask: null, expected: false, label: 'null/mask-null cross-midnight head'),
    _Tuple(now: DateTime(2026, 1, 5, 2, 0), start: 1320, end: 360, mask: null, expected: false, label: 'null/mask-null cross-midnight tail'),
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 540, end: 1020, mask: null, expected: false, label: 'null/mask-null midday'),
  ]);

  // 1e. Two values null (4 tuples)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 540, end: null, mask: null, expected: false, label: 'null/only-start-set'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: null, end: 1020, mask: null, expected: false, label: 'null/only-end-set'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: null, end: null, mask: kAllDays, expected: false, label: 'null/only-mask-set'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 0, end: null, mask: null, expected: false, label: 'null/only-start-zero-set'),
  ]);

  // ------------------------------------------------------------------
  // GROUP 2: Same-day windows (start <= end), 60+ tuples
  // Window 09:00-17:00 = startMinutes=540, endMinutes=1020
  // ------------------------------------------------------------------

  // 2a. Monday 2026-01-05 (weekday=1, kMon=0x01)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 540, end: 1020, mask: kMon, expected: true, label: 'same-day/Mon-mid-window'),
    _Tuple(now: DateTime(2026, 1, 5, 9, 0), start: 540, end: 1020, mask: kMon, expected: true, label: 'same-day/Mon-at-start-inclusive'),
    _Tuple(now: DateTime(2026, 1, 5, 17, 0), start: 540, end: 1020, mask: kMon, expected: false, label: 'same-day/Mon-at-end-exclusive'),
    _Tuple(now: DateTime(2026, 1, 5, 16, 59), start: 540, end: 1020, mask: kMon, expected: true, label: 'same-day/Mon-one-min-before-end'),
    _Tuple(now: DateTime(2026, 1, 5, 8, 59), start: 540, end: 1020, mask: kMon, expected: false, label: 'same-day/Mon-before-start'),
    _Tuple(now: DateTime(2026, 1, 5, 18, 0), start: 540, end: 1020, mask: kMon, expected: false, label: 'same-day/Mon-after-end'),
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 540, end: 1020, mask: kTue, expected: false, label: 'same-day/Mon-wrong-mask-tue'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 540, end: 1020, mask: kAllDays, expected: true, label: 'same-day/Mon-alldays-mask'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 540, end: 1020, mask: kWeekdays, expected: true, label: 'same-day/Mon-weekdays-mask'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 540, end: 1020, mask: kWeekend, expected: false, label: 'same-day/Mon-weekend-mask-false'),
  ]);

  // 2b. Tuesday 2026-01-06 (weekday=2, kTue=0x02)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 6, 12, 0), start: 540, end: 1020, mask: kTue, expected: true, label: 'same-day/Tue-mid-window'),
    _Tuple(now: DateTime(2026, 1, 6, 9, 0), start: 540, end: 1020, mask: kTue, expected: true, label: 'same-day/Tue-at-start'),
    _Tuple(now: DateTime(2026, 1, 6, 17, 0), start: 540, end: 1020, mask: kTue, expected: false, label: 'same-day/Tue-at-end-exclusive'),
    _Tuple(now: DateTime(2026, 1, 6, 12, 0), start: 540, end: 1020, mask: kMon, expected: false, label: 'same-day/Tue-wrong-mask-mon'),
    _Tuple(now: DateTime(2026, 1, 6, 12, 0), start: 540, end: 1020, mask: kWeekdays, expected: true, label: 'same-day/Tue-weekdays-mask'),
  ]);

  // 2c. Wednesday 2026-01-07 (weekday=3, kWed=0x04)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 7, 12, 0), start: 540, end: 1020, mask: kWed, expected: true, label: 'same-day/Wed-mid-window'),
    _Tuple(now: DateTime(2026, 1, 7, 12, 0), start: 540, end: 1020, mask: kMon, expected: false, label: 'same-day/Wed-wrong-mask-mon'),
    _Tuple(now: DateTime(2026, 1, 7, 12, 0), start: 540, end: 1020, mask: kWeekdays, expected: true, label: 'same-day/Wed-weekdays-mask'),
    _Tuple(now: DateTime(2026, 1, 7, 8, 0), start: 540, end: 1020, mask: kWed, expected: false, label: 'same-day/Wed-before-start'),
    _Tuple(now: DateTime(2026, 1, 7, 17, 30), start: 540, end: 1020, mask: kWed, expected: false, label: 'same-day/Wed-after-end'),
  ]);

  // 2d. Thursday 2026-01-08 (weekday=4, kThu=0x08)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 8, 12, 0), start: 540, end: 1020, mask: kThu, expected: true, label: 'same-day/Thu-mid-window'),
    _Tuple(now: DateTime(2026, 1, 8, 12, 0), start: 540, end: 1020, mask: kWeekdays, expected: true, label: 'same-day/Thu-weekdays-mask'),
    _Tuple(now: DateTime(2026, 1, 8, 12, 0), start: 540, end: 1020, mask: kWeekend, expected: false, label: 'same-day/Thu-weekend-mask-false'),
    _Tuple(now: DateTime(2026, 1, 8, 9, 0), start: 540, end: 1020, mask: kThu, expected: true, label: 'same-day/Thu-at-start'),
    _Tuple(now: DateTime(2026, 1, 8, 17, 0), start: 540, end: 1020, mask: kThu, expected: false, label: 'same-day/Thu-at-end'),
  ]);

  // 2e. Friday 2026-01-09 (weekday=5, kFri=0x10)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 9, 12, 0), start: 540, end: 1020, mask: kFri, expected: true, label: 'same-day/Fri-mid-window'),
    _Tuple(now: DateTime(2026, 1, 9, 12, 0), start: 540, end: 1020, mask: kWeekdays, expected: true, label: 'same-day/Fri-weekdays-mask'),
    _Tuple(now: DateTime(2026, 1, 9, 12, 0), start: 540, end: 1020, mask: kWeekend, expected: false, label: 'same-day/Fri-weekend-mask-false'),
    _Tuple(now: DateTime(2026, 1, 9, 9, 0), start: 540, end: 1020, mask: kFri, expected: true, label: 'same-day/Fri-at-start'),
    _Tuple(now: DateTime(2026, 1, 9, 17, 0), start: 540, end: 1020, mask: kFri, expected: false, label: 'same-day/Fri-at-end'),
  ]);

  // 2f. Saturday 2026-01-10 (weekday=6, kSat=0x20)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 10, 12, 0), start: 540, end: 1020, mask: kSat, expected: true, label: 'same-day/Sat-mid-window'),
    _Tuple(now: DateTime(2026, 1, 10, 12, 0), start: 540, end: 1020, mask: kWeekend, expected: true, label: 'same-day/Sat-weekend-mask'),
    _Tuple(now: DateTime(2026, 1, 10, 12, 0), start: 540, end: 1020, mask: kWeekdays, expected: false, label: 'same-day/Sat-weekdays-mask-false'),
    _Tuple(now: DateTime(2026, 1, 10, 9, 0), start: 540, end: 1020, mask: kSat, expected: true, label: 'same-day/Sat-at-start'),
    _Tuple(now: DateTime(2026, 1, 10, 17, 0), start: 540, end: 1020, mask: kSat, expected: false, label: 'same-day/Sat-at-end'),
  ]);

  // 2g. Sunday 2026-01-11 (weekday=7, kSun=0x40)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 11, 12, 0), start: 540, end: 1020, mask: kSun, expected: true, label: 'same-day/Sun-mid-window'),
    _Tuple(now: DateTime(2026, 1, 11, 12, 0), start: 540, end: 1020, mask: kWeekend, expected: true, label: 'same-day/Sun-weekend-mask'),
    _Tuple(now: DateTime(2026, 1, 11, 12, 0), start: 540, end: 1020, mask: kWeekdays, expected: false, label: 'same-day/Sun-weekdays-mask-false'),
    _Tuple(now: DateTime(2026, 1, 11, 9, 0), start: 540, end: 1020, mask: kSun, expected: true, label: 'same-day/Sun-at-start'),
    _Tuple(now: DateTime(2026, 1, 11, 17, 0), start: 540, end: 1020, mask: kSun, expected: false, label: 'same-day/Sun-at-end'),
  ]);

  // 2h. Same-day edge cases
  tuples.addAll([
    // Zero-width window (start == end → always false)
    _Tuple(now: DateTime(2026, 1, 5, 9, 0), start: 540, end: 540, mask: kAllDays, expected: false, label: 'same-day/zero-width-window-at-start'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 540, end: 540, mask: kAllDays, expected: false, label: 'same-day/zero-width-window-after-start'),
    // Full-day-ish window 00:00-23:59
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 0, end: 1439, mask: kMon, expected: true, label: 'same-day/near-full-day-mid'),
    _Tuple(now: DateTime(2026, 1, 5, 0, 0), start: 0, end: 1439, mask: kMon, expected: true, label: 'same-day/near-full-day-at-start'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 59), start: 0, end: 1439, mask: kMon, expected: false, label: 'same-day/near-full-day-at-end-exclusive'),
    // Small 1-minute window 10:30-10:31
    _Tuple(now: DateTime(2026, 1, 5, 10, 30), start: 630, end: 631, mask: kMon, expected: true, label: 'same-day/one-minute-window-in'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 31), start: 630, end: 631, mask: kMon, expected: false, label: 'same-day/one-minute-window-at-end'),
    // Window crossing noon
    _Tuple(now: DateTime(2026, 1, 5, 11, 59), start: 600, end: 720, mask: kAllDays, expected: true, label: 'same-day/window-before-noon'),
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 600, end: 720, mask: kAllDays, expected: false, label: 'same-day/window-noon-at-end-exclusive'),
    _Tuple(now: DateTime(2026, 1, 5, 11, 0), start: 600, end: 720, mask: kAllDays, expected: true, label: 'same-day/window-11:00-in'),
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 600, end: 720, mask: kTue, expected: false, label: 'same-day/window-noon-wrong-day'),
    // Before/after window with all-days mask
    _Tuple(now: DateTime(2026, 1, 5, 5, 0), start: 540, end: 1020, mask: kAllDays, expected: false, label: 'same-day/before-window-alldays'),
    _Tuple(now: DateTime(2026, 1, 5, 20, 0), start: 540, end: 1020, mask: kAllDays, expected: false, label: 'same-day/after-window-alldays'),
    // Minute boundary precision
    _Tuple(now: DateTime(2026, 1, 5, 8, 59), start: 540, end: 1020, mask: kAllDays, expected: false, label: 'same-day/one-min-before-start'),
    _Tuple(now: DateTime(2026, 1, 5, 9, 1), start: 540, end: 1020, mask: kAllDays, expected: true, label: 'same-day/one-min-after-start'),
    // Mon|Wed mask
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 540, end: 1020, mask: kMon | kWed, expected: true, label: 'same-day/mon-wed-mask-on-mon'),
    _Tuple(now: DateTime(2026, 1, 6, 10, 0), start: 540, end: 1020, mask: kMon | kWed, expected: false, label: 'same-day/mon-wed-mask-on-tue-false'),
    _Tuple(now: DateTime(2026, 1, 7, 10, 0), start: 540, end: 1020, mask: kMon | kWed, expected: true, label: 'same-day/mon-wed-mask-on-wed'),
    // Weekend mask on Sat+Sun
    _Tuple(now: DateTime(2026, 1, 10, 10, 0), start: 540, end: 1020, mask: kWeekend, expected: true, label: 'same-day/weekend-mask-on-sat'),
    _Tuple(now: DateTime(2026, 1, 11, 10, 0), start: 540, end: 1020, mask: kWeekend, expected: true, label: 'same-day/weekend-mask-on-sun'),
    // All-days on various days
    _Tuple(now: DateTime(2026, 1, 10, 10, 0), start: 540, end: 1020, mask: kAllDays, expected: true, label: 'same-day/alldays-mask-on-sat'),
    _Tuple(now: DateTime(2026, 1, 11, 10, 0), start: 540, end: 1020, mask: kAllDays, expected: true, label: 'same-day/alldays-mask-on-sun'),
    _Tuple(now: DateTime(2026, 1, 8, 10, 0), start: 540, end: 1020, mask: kAllDays, expected: true, label: 'same-day/alldays-mask-on-thu'),
    // Midnight to noon window
    _Tuple(now: DateTime(2026, 1, 5, 6, 0), start: 0, end: 720, mask: kMon, expected: true, label: 'same-day/midnight-to-noon-at-06:00'),
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 0, end: 720, mask: kMon, expected: false, label: 'same-day/midnight-to-noon-at-end-exclusive'),
  ]);

  // ------------------------------------------------------------------
  // GROUP 3: Cross-midnight windows (end < start), 60 tuples
  // Window 22:00(1320)→06:00(360): head=[22:00..midnight), tail=[00:00..06:00)
  // ------------------------------------------------------------------

  // 3a. Cross-midnight head (today is the START day), 20 tuples
  tuples.addAll([
    // head: Mon 23:00 (nowMin=1380 >= 1320) → today=Mon bit → true/false
    _Tuple(now: DateTime(2026, 1, 5, 23, 0), start: 1320, end: 360, mask: kMon, expected: true, label: 'cross-midnight/head-Mon-23:00-monMask'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 0), start: 1320, end: 360, mask: kAllDays, expected: true, label: 'cross-midnight/head-Mon-23:00-alldays'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 0), start: 1320, end: 360, mask: kTue, expected: false, label: 'cross-midnight/head-Mon-23:00-tue-mask-false'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 0), start: 1320, end: 360, mask: kWeekdays, expected: true, label: 'cross-midnight/head-Mon-23:00-weekdays'),
    _Tuple(now: DateTime(2026, 1, 5, 22, 0), start: 1320, end: 360, mask: kMon, expected: true, label: 'cross-midnight/head-Mon-at-start-22:00'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 59), start: 1320, end: 360, mask: kMon, expected: true, label: 'cross-midnight/head-Mon-23:59'),
    _Tuple(now: DateTime(2026, 1, 6, 23, 0), start: 1320, end: 360, mask: kTue, expected: true, label: 'cross-midnight/head-Tue-23:00-tueMask'),
    _Tuple(now: DateTime(2026, 1, 6, 23, 0), start: 1320, end: 360, mask: kMon, expected: false, label: 'cross-midnight/head-Tue-23:00-monMask-false'),
    _Tuple(now: DateTime(2026, 1, 7, 23, 0), start: 1320, end: 360, mask: kWed, expected: true, label: 'cross-midnight/head-Wed-23:00'),
    _Tuple(now: DateTime(2026, 1, 8, 23, 0), start: 1320, end: 360, mask: kThu, expected: true, label: 'cross-midnight/head-Thu-23:00'),
    _Tuple(now: DateTime(2026, 1, 9, 23, 0), start: 1320, end: 360, mask: kFri, expected: true, label: 'cross-midnight/head-Fri-23:00'),
    _Tuple(now: DateTime(2026, 1, 10, 23, 0), start: 1320, end: 360, mask: kSat, expected: true, label: 'cross-midnight/head-Sat-23:00'),
    _Tuple(now: DateTime(2026, 1, 11, 23, 0), start: 1320, end: 360, mask: kSun, expected: true, label: 'cross-midnight/head-Sun-23:00'),
    _Tuple(now: DateTime(2026, 1, 11, 23, 0), start: 1320, end: 360, mask: kWeekend, expected: true, label: 'cross-midnight/head-Sun-23:00-weekend'),
    _Tuple(now: DateTime(2026, 1, 9, 23, 0), start: 1320, end: 360, mask: kWeekend, expected: false, label: 'cross-midnight/head-Fri-23:00-weekend-false'),
    _Tuple(now: DateTime(2026, 1, 5, 22, 0), start: 1320, end: 360, mask: kAllDays, expected: true, label: 'cross-midnight/head-at-start-exact'),
    _Tuple(now: DateTime(2026, 1, 5, 21, 59), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/head-one-min-before-start-false'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 30), start: 1320, end: 360, mask: kWeekdays, expected: true, label: 'cross-midnight/head-Mon-23:30-weekdays'),
    _Tuple(now: DateTime(2026, 1, 10, 23, 0), start: 1320, end: 360, mask: kWeekdays, expected: false, label: 'cross-midnight/head-Sat-23:00-weekdays-false'),
    _Tuple(now: DateTime(2026, 1, 5, 22, 1), start: 1320, end: 360, mask: kMon, expected: true, label: 'cross-midnight/head-Mon-22:01'),
  ]);

  // 3b. Cross-midnight tail (yesterday is the START day), 20 tuples
  // START-day semantics: at 01:00 Tue, the window started on Mon → check Mon bit
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 6, 1, 0), start: 1320, end: 360, mask: kMon, expected: true, label: 'cross-midnight tail/Tue-01:00-monMask-true (START=Mon)'),
    _Tuple(now: DateTime(2026, 1, 6, 1, 0), start: 1320, end: 360, mask: kTue, expected: false, label: 'cross-midnight tail/Tue-01:00-tueMask-false (yesterday=Mon)'),
    _Tuple(now: DateTime(2026, 1, 6, 1, 0), start: 1320, end: 360, mask: kAllDays, expected: true, label: 'cross-midnight tail/Tue-01:00-alldays'),
    _Tuple(now: DateTime(2026, 1, 6, 1, 0), start: 1320, end: 360, mask: kWeekdays, expected: true, label: 'cross-midnight tail/Tue-01:00-weekdays (Mon is weekday)'),
    _Tuple(now: DateTime(2026, 1, 6, 0, 0), start: 1320, end: 360, mask: kMon, expected: true, label: 'cross-midnight tail/Tue-00:00-monMask'),
    _Tuple(now: DateTime(2026, 1, 6, 0, 0), start: 1320, end: 360, mask: kTue, expected: false, label: 'cross-midnight tail/Tue-00:00-tueMask-false'),
    _Tuple(now: DateTime(2026, 1, 6, 6, 0), start: 1320, end: 360, mask: kMon, expected: false, label: 'cross-midnight tail/Tue-06:00-at-end-exclusive'),
    _Tuple(now: DateTime(2026, 1, 6, 5, 59), start: 1320, end: 360, mask: kMon, expected: true, label: 'cross-midnight tail/Tue-05:59-one-min-before-end'),
    _Tuple(now: DateTime(2026, 1, 7, 0, 30), start: 1320, end: 360, mask: kTue, expected: true, label: 'cross-midnight tail/Wed-00:30-tueMask (yesterday=Tue)'),
    _Tuple(now: DateTime(2026, 1, 7, 0, 30), start: 1320, end: 360, mask: kWed, expected: false, label: 'cross-midnight tail/Wed-00:30-wedMask-false'),
    _Tuple(now: DateTime(2026, 1, 8, 1, 30), start: 1320, end: 360, mask: kWed, expected: true, label: 'cross-midnight tail/Thu-01:30-wedMask (yesterday=Wed)'),
    _Tuple(now: DateTime(2026, 1, 8, 1, 30), start: 1320, end: 360, mask: kThu, expected: false, label: 'cross-midnight tail/Thu-01:30-thuMask-false'),
    _Tuple(now: DateTime(2026, 1, 9, 3, 0), start: 1320, end: 360, mask: kThu, expected: true, label: 'cross-midnight tail/Fri-03:00-thuMask (yesterday=Thu)'),
    _Tuple(now: DateTime(2026, 1, 10, 2, 0), start: 1320, end: 360, mask: kFri, expected: true, label: 'cross-midnight tail/Sat-02:00-friMask (yesterday=Fri)'),
    _Tuple(now: DateTime(2026, 1, 10, 2, 0), start: 1320, end: 360, mask: kWeekdays, expected: true, label: 'cross-midnight tail/Sat-02:00-weekdays (yesterday=Fri)'),
    _Tuple(now: DateTime(2026, 1, 11, 1, 0), start: 1320, end: 360, mask: kSat, expected: true, label: 'cross-midnight tail/Sun-01:00-satMask (yesterday=Sat)'),
    _Tuple(now: DateTime(2026, 1, 11, 1, 0), start: 1320, end: 360, mask: kWeekend, expected: true, label: 'cross-midnight tail/Sun-01:00-weekend (yesterday=Sat)'),
    _Tuple(now: DateTime(2026, 1, 5, 1, 0), start: 1320, end: 360, mask: kSun, expected: true, label: 'cross-midnight tail/Mon-01:00-sunMask (yesterday=Sun)'),
    _Tuple(now: DateTime(2026, 1, 5, 1, 0), start: 1320, end: 360, mask: kWeekend, expected: true, label: 'cross-midnight tail/Mon-01:00-weekend (yesterday=Sun)'),
    _Tuple(now: DateTime(2026, 1, 5, 1, 0), start: 1320, end: 360, mask: kWeekdays, expected: false, label: 'cross-midnight tail/Mon-01:00-weekdays-false (yesterday=Sun)'),
  ]);

  // 3c. Cross-midnight gap (nowMin in [end..start) → false), 14 tuples
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 6, 0), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/gap-06:00-at-end'),
    _Tuple(now: DateTime(2026, 1, 5, 7, 0), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/gap-07:00'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/gap-10:00'),
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/gap-noon'),
    _Tuple(now: DateTime(2026, 1, 5, 17, 0), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/gap-17:00'),
    _Tuple(now: DateTime(2026, 1, 5, 21, 0), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/gap-21:00'),
    _Tuple(now: DateTime(2026, 1, 5, 21, 59), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/gap-21:59-one-min-before-start'),
    _Tuple(now: DateTime(2026, 1, 5, 14, 0), start: 1320, end: 360, mask: kMon, expected: false, label: 'cross-midnight/gap-Mon-14:00-monMask'),
    _Tuple(now: DateTime(2026, 1, 6, 6, 0), start: 1320, end: 360, mask: kAllDays, expected: false, label: 'cross-midnight/gap-Tue-06:00-at-tail-end'),
    // Narrow cross-midnight: 23:30(1410)→00:30(30), gap=[30..1410)
    _Tuple(now: DateTime(2026, 1, 5, 1, 0), start: 1410, end: 30, mask: kAllDays, expected: false, label: 'cross-midnight/gap-narrow-01:00'),
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 1410, end: 30, mask: kAllDays, expected: false, label: 'cross-midnight/gap-narrow-noon'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 29), start: 1410, end: 30, mask: kAllDays, expected: false, label: 'cross-midnight/gap-narrow-23:29'),
    _Tuple(now: DateTime(2026, 1, 6, 0, 30), start: 1410, end: 30, mask: kAllDays, expected: false, label: 'cross-midnight/gap-narrow-Tue-00:30-at-end'),
    _Tuple(now: DateTime(2026, 1, 6, 1, 0), start: 1410, end: 30, mask: kAllDays, expected: false, label: 'cross-midnight/gap-narrow-Tue-01:00'),
  ]);

  // 3d. Narrow cross-midnight head+tail: window 23:30(1410)→00:30(30)
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 23, 30), start: 1410, end: 30, mask: kMon, expected: true, label: 'cross-midnight/narrow-head-Mon-at-start'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 50), start: 1410, end: 30, mask: kMon, expected: true, label: 'cross-midnight/narrow-head-Mon-23:50'),
    _Tuple(now: DateTime(2026, 1, 6, 0, 0), start: 1410, end: 30, mask: kMon, expected: true, label: 'cross-midnight/narrow-tail-Tue-00:00-monMask'),
    _Tuple(now: DateTime(2026, 1, 6, 0, 29), start: 1410, end: 30, mask: kMon, expected: true, label: 'cross-midnight/narrow-tail-Tue-00:29-one-min-before-end'),
    _Tuple(now: DateTime(2026, 1, 6, 0, 0), start: 1410, end: 30, mask: kTue, expected: false, label: 'cross-midnight/narrow-tail-Tue-00:00-tueMask-false'),
    _Tuple(now: DateTime(2026, 1, 6, 0, 0), start: 1410, end: 30, mask: kAllDays, expected: true, label: 'cross-midnight/narrow-tail-Tue-00:00-alldays'),
  ]);

  // 3e. Additional cross-midnight per weekday (50 tuples)
  // Window 21:00(1260)→03:00(180), 10 tuples per weekday pair (head+tail)
  const cmStart = 1260; // 21:00
  const cmEnd = 180; // 03:00

  // Mon head + tail
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 21, 0), start: cmStart, end: cmEnd, mask: kMon, expected: true, label: 'cm2/head-Mon-at-start'),
    _Tuple(now: DateTime(2026, 1, 5, 22, 0), start: cmStart, end: cmEnd, mask: kMon, expected: true, label: 'cm2/head-Mon-22:00'),
    _Tuple(now: DateTime(2026, 1, 5, 23, 59), start: cmStart, end: cmEnd, mask: kMon, expected: true, label: 'cm2/head-Mon-23:59'),
    _Tuple(now: DateTime(2026, 1, 5, 21, 0), start: cmStart, end: cmEnd, mask: kTue, expected: false, label: 'cm2/head-Mon-21:00-tueMask-false'),
    _Tuple(now: DateTime(2026, 1, 6, 1, 0), start: cmStart, end: cmEnd, mask: kMon, expected: true, label: 'cm2/tail-Tue-01:00-monMask (start=Mon)'),
    _Tuple(now: DateTime(2026, 1, 6, 2, 59), start: cmStart, end: cmEnd, mask: kMon, expected: true, label: 'cm2/tail-Tue-02:59-monMask'),
    _Tuple(now: DateTime(2026, 1, 6, 3, 0), start: cmStart, end: cmEnd, mask: kMon, expected: false, label: 'cm2/tail-Tue-03:00-at-end-exclusive'),
    _Tuple(now: DateTime(2026, 1, 6, 1, 0), start: cmStart, end: cmEnd, mask: kTue, expected: false, label: 'cm2/tail-Tue-01:00-tueMask-false'),
    _Tuple(now: DateTime(2026, 1, 5, 20, 59), start: cmStart, end: cmEnd, mask: kAllDays, expected: false, label: 'cm2/gap-Mon-20:59-before-start'),
    _Tuple(now: DateTime(2026, 1, 5, 10, 0), start: cmStart, end: cmEnd, mask: kAllDays, expected: false, label: 'cm2/gap-Mon-10:00'),
  ]);

  // Tue head + tail
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 6, 21, 0), start: cmStart, end: cmEnd, mask: kTue, expected: true, label: 'cm2/head-Tue-at-start'),
    _Tuple(now: DateTime(2026, 1, 6, 23, 0), start: cmStart, end: cmEnd, mask: kTue, expected: true, label: 'cm2/head-Tue-23:00'),
    _Tuple(now: DateTime(2026, 1, 6, 21, 0), start: cmStart, end: cmEnd, mask: kWed, expected: false, label: 'cm2/head-Tue-21:00-wedMask-false'),
    _Tuple(now: DateTime(2026, 1, 7, 1, 0), start: cmStart, end: cmEnd, mask: kTue, expected: true, label: 'cm2/tail-Wed-01:00-tueMask (start=Tue)'),
    _Tuple(now: DateTime(2026, 1, 7, 1, 0), start: cmStart, end: cmEnd, mask: kWed, expected: false, label: 'cm2/tail-Wed-01:00-wedMask-false'),
  ]);

  // Wed head + tail
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 7, 21, 0), start: cmStart, end: cmEnd, mask: kWed, expected: true, label: 'cm2/head-Wed-at-start'),
    _Tuple(now: DateTime(2026, 1, 7, 23, 0), start: cmStart, end: cmEnd, mask: kWed, expected: true, label: 'cm2/head-Wed-23:00'),
    _Tuple(now: DateTime(2026, 1, 7, 21, 0), start: cmStart, end: cmEnd, mask: kThu, expected: false, label: 'cm2/head-Wed-21:00-thuMask-false'),
    _Tuple(now: DateTime(2026, 1, 8, 1, 0), start: cmStart, end: cmEnd, mask: kWed, expected: true, label: 'cm2/tail-Thu-01:00-wedMask (start=Wed)'),
    _Tuple(now: DateTime(2026, 1, 8, 1, 0), start: cmStart, end: cmEnd, mask: kThu, expected: false, label: 'cm2/tail-Thu-01:00-thuMask-false'),
  ]);

  // Thu head + tail
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 8, 21, 0), start: cmStart, end: cmEnd, mask: kThu, expected: true, label: 'cm2/head-Thu-at-start'),
    _Tuple(now: DateTime(2026, 1, 8, 23, 0), start: cmStart, end: cmEnd, mask: kThu, expected: true, label: 'cm2/head-Thu-23:00'),
    _Tuple(now: DateTime(2026, 1, 8, 21, 0), start: cmStart, end: cmEnd, mask: kFri, expected: false, label: 'cm2/head-Thu-21:00-friMask-false'),
    _Tuple(now: DateTime(2026, 1, 9, 1, 0), start: cmStart, end: cmEnd, mask: kThu, expected: true, label: 'cm2/tail-Fri-01:00-thuMask (start=Thu)'),
    _Tuple(now: DateTime(2026, 1, 9, 1, 0), start: cmStart, end: cmEnd, mask: kFri, expected: false, label: 'cm2/tail-Fri-01:00-friMask-false'),
  ]);

  // Fri head + tail
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 9, 21, 0), start: cmStart, end: cmEnd, mask: kFri, expected: true, label: 'cm2/head-Fri-at-start'),
    _Tuple(now: DateTime(2026, 1, 9, 23, 0), start: cmStart, end: cmEnd, mask: kFri, expected: true, label: 'cm2/head-Fri-23:00'),
    _Tuple(now: DateTime(2026, 1, 9, 21, 0), start: cmStart, end: cmEnd, mask: kSat, expected: false, label: 'cm2/head-Fri-21:00-satMask-false'),
    _Tuple(now: DateTime(2026, 1, 10, 1, 0), start: cmStart, end: cmEnd, mask: kFri, expected: true, label: 'cm2/tail-Sat-01:00-friMask (start=Fri)'),
    _Tuple(now: DateTime(2026, 1, 10, 1, 0), start: cmStart, end: cmEnd, mask: kSat, expected: false, label: 'cm2/tail-Sat-01:00-satMask-false'),
  ]);

  // Sat head + tail
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 10, 21, 0), start: cmStart, end: cmEnd, mask: kSat, expected: true, label: 'cm2/head-Sat-at-start'),
    _Tuple(now: DateTime(2026, 1, 10, 23, 0), start: cmStart, end: cmEnd, mask: kSat, expected: true, label: 'cm2/head-Sat-23:00'),
    _Tuple(now: DateTime(2026, 1, 10, 21, 0), start: cmStart, end: cmEnd, mask: kSun, expected: false, label: 'cm2/head-Sat-21:00-sunMask-false'),
    _Tuple(now: DateTime(2026, 1, 11, 1, 0), start: cmStart, end: cmEnd, mask: kSat, expected: true, label: 'cm2/tail-Sun-01:00-satMask (start=Sat)'),
    _Tuple(now: DateTime(2026, 1, 11, 1, 0), start: cmStart, end: cmEnd, mask: kSun, expected: false, label: 'cm2/tail-Sun-01:00-sunMask-false'),
  ]);

  // Sun head + tail
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 11, 21, 0), start: cmStart, end: cmEnd, mask: kSun, expected: true, label: 'cm2/head-Sun-at-start'),
    _Tuple(now: DateTime(2026, 1, 11, 23, 0), start: cmStart, end: cmEnd, mask: kSun, expected: true, label: 'cm2/head-Sun-23:00'),
    _Tuple(now: DateTime(2026, 1, 11, 21, 0), start: cmStart, end: cmEnd, mask: kMon, expected: false, label: 'cm2/head-Sun-21:00-monMask-false'),
    _Tuple(now: DateTime(2026, 1, 12, 1, 0), start: cmStart, end: cmEnd, mask: kSun, expected: true, label: 'cm2/tail-Mon2-01:00-sunMask (start=Sun)'),
    _Tuple(now: DateTime(2026, 1, 12, 1, 0), start: cmStart, end: cmEnd, mask: kMon, expected: false, label: 'cm2/tail-Mon2-01:00-monMask-false'),
  ]);

  // ------------------------------------------------------------------
  // GROUP 4: Weekday bitmask edges — single-day-only mask (7 tuples)
  // ------------------------------------------------------------------
  tuples.addAll([
    _Tuple(now: DateTime(2026, 1, 5, 12, 0), start: 540, end: 1020, mask: kMon, expected: true, label: 'bitmask-edge/single-Mon'),
    _Tuple(now: DateTime(2026, 1, 6, 12, 0), start: 540, end: 1020, mask: kTue, expected: true, label: 'bitmask-edge/single-Tue'),
    _Tuple(now: DateTime(2026, 1, 7, 12, 0), start: 540, end: 1020, mask: kWed, expected: true, label: 'bitmask-edge/single-Wed'),
    _Tuple(now: DateTime(2026, 1, 8, 12, 0), start: 540, end: 1020, mask: kThu, expected: true, label: 'bitmask-edge/single-Thu'),
    _Tuple(now: DateTime(2026, 1, 9, 12, 0), start: 540, end: 1020, mask: kFri, expected: true, label: 'bitmask-edge/single-Fri'),
    _Tuple(now: DateTime(2026, 1, 10, 12, 0), start: 540, end: 1020, mask: kSat, expected: true, label: 'bitmask-edge/single-Sat'),
    _Tuple(now: DateTime(2026, 1, 11, 12, 0), start: 540, end: 1020, mask: kSun, expected: true, label: 'bitmask-edge/single-Sun'),
  ]);

  // ------------------------------------------------------------------
  // GROUP 5: DST boundary tuples (8 tuples)
  //
  // These use LOCAL DateTime instances so toLocal() is a no-op. The
  // Dart helper computes weekdays from the local DateTime.weekday field
  // directly, which is correct regardless of DST — DateTime handles DST
  // internally when you construct a local DateTime.
  //
  // Spring forward 2026-03-08: Sunday (weekday=7=Sun)
  //   At 01:30 local, before forward → kSun, window 01:00-03:00 → true
  //   At 03:30 local, after forward  → kSun, window 01:00-03:00 → false
  //
  // Fall back 2025-11-02: Sunday (weekday=7=Sun)
  //   At 00:30 local → kSun, window 00:00-02:00 → true
  //   At 02:00 local → kSun, window 00:00-02:00 → false (exclusive)
  //
  // DST-safety: both halves of the window use the same local date, so
  // the weekday bit is consistent. The Kotlin counterpart also uses
  // TimeZone.getDefault() (local TZ), not a pinned Pacific timezone.
  // Both sides are locally-consistent but neither exercises real DST
  // wall-clock gaps/folds. True DST testing would require pinned TZ + epoch math.
  // ------------------------------------------------------------------
  tuples.addAll([
    // Spring forward 2026-03-08 (Sunday)
    _Tuple(now: DateTime(2026, 3, 8, 1, 30), start: 60, end: 180, mask: kSun, expected: true, label: 'dst/spring-forward-2026-Sun-01:30-in-window'),
    _Tuple(now: DateTime(2026, 3, 8, 3, 30), start: 60, end: 180, mask: kSun, expected: false, label: 'dst/spring-forward-2026-Sun-03:30-after-window'),
    _Tuple(now: DateTime(2026, 3, 8, 2, 30), start: 60, end: 180, mask: kSun, expected: true, label: 'dst/spring-forward-2026-Sun-02:30-in-window'),
    _Tuple(now: DateTime(2026, 3, 8, 0, 30), start: 60, end: 180, mask: kSun, expected: false, label: 'dst/spring-forward-2026-Sun-00:30-before-window'),
    // Fall back 2025-11-02 (Sunday)
    _Tuple(now: DateTime(2025, 11, 2, 0, 30), start: 0, end: 120, mask: kSun, expected: true, label: 'dst/fall-back-2025-Sun-00:30-in-window'),
    _Tuple(now: DateTime(2025, 11, 2, 2, 0), start: 0, end: 120, mask: kSun, expected: false, label: 'dst/fall-back-2025-Sun-02:00-at-end-exclusive'),
    _Tuple(now: DateTime(2025, 11, 2, 1, 30), start: 0, end: 120, mask: kSun, expected: true, label: 'dst/fall-back-2025-Sun-01:30-in-window'),
    _Tuple(now: DateTime(2025, 11, 2, 2, 30), start: 0, end: 120, mask: kSun, expected: false, label: 'dst/fall-back-2025-Sun-02:30-after-window'),
  ]);

  return tuples;
}

final List<_Tuple> expectedTuples = _buildTuples();

void main() {
  group('schedule_window Dart parity oracle (D-12 / PAUS-10)', () {
    for (final t in expectedTuples) {
      test(t.label, () {
        expect(
          isInScheduleWindow(
            now: t.now,
            startMinutes: t.start,
            endMinutes: t.end,
            weekdayMask: t.mask,
          ),
          t.expected,
        );
      });
    }
  });
}
