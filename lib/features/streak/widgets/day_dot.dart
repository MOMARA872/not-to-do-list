import 'package:flutter/material.dart';

/// 4-state day-dot widget for the 30-day streak history grid.
///
/// States (UI-SPEC §Color 4-State table):
///   status=0, source=0 → green filled circle (system-confirmed success)
///   status=0, source=1 → blue outlined circle (self-reported-only success)
///   status=1            → red filled + × glyph (broken)
///   status=2            → grey outlined + — glyph + Tooltip MANDATORY
///   status=3            → date number only (today — pending)
///   empty               → SizedBox 24×24 (before entry creation)
///
/// The `day` parameter is required for accessibility labels.
class DayDot extends StatelessWidget {
  const DayDot({
    required this.day,
    required this.status,
    required this.source,
    super.key,
  });

  final DateTime day;

  /// 0 = success, 1 = broken, 2 = incomplete-data, 3 = pending/today.
  final int status;

  /// 0 = system-confirmed, 1 = self-reported-only.
  /// Only relevant when status=0.
  final int source;

  // --- 4-state color tokens (UI-SPEC §Color, fixed — not M3 seed) ---

  // Green (system-confirmed success)
  static const Color _greenLight = Color(0xFF2E7D32);
  static const Color _greenDark = Color(0xFF66BB6A);

  // Blue (self-reported-only success)
  static const Color _blueLight = Color(0xFF1565C0);
  static const Color _blueDark = Color(0xFF64B5F6);

  // Red (broken)
  static const Color _redLight = Color(0xFFC62828);
  static const Color _redDark = Color(0xFFEF9A9A);

  // Grey (incomplete-data)
  static const Color _greyLight = Color(0xFF757575);
  static const Color _greyDark = Color(0xFF9E9E9E);

  String _semanticLabel() {
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    final dateStr = '${day.year}-$m-$d';
    switch (status) {
      case 0:
        return source == 0
            ? '$dateStr — avoided, system confirmed'
            : '$dateStr — avoided, self-reported';
      case 1:
        return '$dateStr — streak broken';
      case 2:
        return '$dateStr — incomplete data';
      case 3:
        return '$dateStr — pending';
      default:
        return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    Widget dot;

    switch (status) {
      case 0:
        // Success: green filled (source=0) or blue outlined (source=1)
        if (source == 0) {
          final color = isDark ? _greenDark : _greenLight;
          dot = Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          );
        } else {
          final color = isDark ? _blueDark : _blueLight;
          dot = Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
          );
        }

      case 1:
        // Broken: red filled + × overlay
        final color = isDark ? _redDark : _redLight;
        dot = SizedBox(
          width: 8,
          height: 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              Text(
                '×',
                style: TextStyle(
                  fontSize: 8,
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        );

      case 2:
        // Incomplete-data: grey outlined + — overlay + mandatory Tooltip
        final color = isDark ? _greyDark : _greyLight;
        final innerDot = SizedBox(
          width: 8,
          height: 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color),
                ),
              ),
              Text(
                '—',
                style: TextStyle(
                  fontSize: 8,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        );
        // MANDATORY tooltip per D-07 / UI-SPEC §Interaction Contracts.
        dot = Tooltip(
          message: 'Tracking was off this day',
          child: innerDot,
        );

      case 3:
        // Today — pending: date number only, no circle.
        dot = Text(
          '${day.day}',
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        );

      default:
        // Empty (before entry creation): SizedBox only.
        return const SizedBox(width: 24, height: 24);
    }

    // Wrap in 24×24 container with semantic label.
    return Semantics(
      label: _semanticLabel(),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(child: dot),
      ),
    );
  }
}
