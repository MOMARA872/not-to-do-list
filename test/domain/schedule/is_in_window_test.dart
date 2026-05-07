// Truth-table assertions for `isInScheduleWindow` — the canonical 13 cases
// from 02-RESEARCH.md §Schedule Active-Window Evaluation. Pure-Dart test:
// `flutter_test` is here only for `expect`/`group`/`test` plumbing.
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/domain/schedule/schedule_window.dart';

// Reference dates pinned to known weekdays in May 2026 (verified via
// DateTime.weekday at file-write time).
//   2026-05-04  Mon
//   2026-05-05  Tue
//   2026-05-06  Wed
//   2026-05-07  Thu
//   2026-05-08  Fri
//   2026-05-09  Sat
//   2026-05-10  Sun
DateTime monAt(int hour, int minute) => DateTime(2026, 5, 4, hour, minute);
DateTime tueAt(int hour, int minute) => DateTime(2026, 5, 5, hour, minute);
DateTime wedAt(int hour, int minute) => DateTime(2026, 5, 6, hour, minute);
DateTime satAt(int hour, int minute) => DateTime(2026, 5, 9, hour, minute);

const weekdaysOnly = 0x1F; // bits 0..4 = Mon..Fri
const allDays = 0x7F; // bits 0..6 = Mon..Sun

void main() {
  group('isInScheduleWindow (LIST-09)', () {
    test('WIN-01: same-day in window weekdays, now=14:00 Tue', () {
      expect(
        isInScheduleWindow(
          now: tueAt(14, 0),
          startMinutes: 9 * 60,
          endMinutes: 22 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isTrue,
      );
    });

    test('WIN-02: same-day before window — now=08:00 Tue', () {
      expect(
        isInScheduleWindow(
          now: tueAt(8, 0),
          startMinutes: 9 * 60,
          endMinutes: 22 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isFalse,
      );
    });

    test('WIN-03: same-day end-boundary half-open — now=22:00 Tue', () {
      expect(
        isInScheduleWindow(
          now: tueAt(22, 0),
          startMinutes: 9 * 60,
          endMinutes: 22 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isFalse,
      );
    });

    test('WIN-04: same-day weekend masked off — now=14:00 Sat', () {
      expect(
        isInScheduleWindow(
          now: satAt(14, 0),
          startMinutes: 9 * 60,
          endMinutes: 22 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isFalse,
      );
    });

    test('WIN-05: cross-midnight after start, now=23:30 Tue (Tue masked)', () {
      expect(
        isInScheduleWindow(
          now: tueAt(23, 30),
          startMinutes: 22 * 60,
          endMinutes: 6 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isTrue,
      );
    });

    test('WIN-06: cross-midnight before end, now=03:00 Wed (Tue masked)', () {
      expect(
        isInScheduleWindow(
          now: wedAt(3, 0),
          startMinutes: 22 * 60,
          endMinutes: 6 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isTrue,
      );
    });

    test('WIN-07: cross-midnight in the gap — now=14:00 Wed', () {
      expect(
        isInScheduleWindow(
          now: wedAt(14, 0),
          startMinutes: 22 * 60,
          endMinutes: 6 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isFalse,
      );
    });

    test('WIN-08: cross-midnight, now=23:30 Sat (Sat is unmasked)', () {
      expect(
        isInScheduleWindow(
          now: satAt(23, 30),
          startMinutes: 22 * 60,
          endMinutes: 6 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isFalse,
      );
    });

    test('WIN-09: cross-midnight, now=03:00 Mon (Sun is unmasked)', () {
      expect(
        isInScheduleWindow(
          now: monAt(3, 0),
          startMinutes: 22 * 60,
          endMinutes: 6 * 60,
          weekdayMask: weekdaysOnly,
        ),
        isFalse,
      );
    });

    test('WIN-10: DST spring-forward day — helper does not throw', () {
      // 2026-03-08 02:30 is a fictitious clock moment in US DST (the local
      // wall-clock skips from 02:00 to 03:00). DateTime() will normalize it,
      // but we just need to verify no crash on the synthesized boundary.
      expect(
        () => isInScheduleWindow(
          now: DateTime(2026, 3, 8, 2, 30),
          startMinutes: 22 * 60,
          endMinutes: 6 * 60,
          weekdayMask: allDays,
        ),
        returnsNormally,
      );
    });

    test('WIN-11: DST fall-back day — helper does not throw', () {
      // 2026-11-01 01:30 occurs twice in US DST; we just verify no crash.
      expect(
        () => isInScheduleWindow(
          now: DateTime(2026, 11, 1, 1, 30),
          startMinutes: 22 * 60,
          endMinutes: 6 * 60,
          weekdayMask: allDays,
        ),
        returnsNormally,
      );
    });

    test('WIN-12: leap-year Feb 29 — no special handling', () {
      expect(
        () => isInScheduleWindow(
          now: DateTime(2024, 2, 29, 14),
          startMinutes: 9 * 60,
          endMinutes: 17 * 60,
          weekdayMask: allDays,
        ),
        returnsNormally,
      );
    });

    test('WIN-13: all three null returns false', () {
      expect(
        isInScheduleWindow(
          now: tueAt(12, 0),
          startMinutes: null,
          endMinutes: null,
          weekdayMask: null,
        ),
        isFalse,
      );
    });
  });
}
