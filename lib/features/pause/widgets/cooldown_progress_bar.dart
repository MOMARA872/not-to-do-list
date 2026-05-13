import 'package:flutter/material.dart';

/// Thin LinearProgressIndicator + "X:XX remaining" caption (D-05).
///
/// When totalSeconds or remainingMs is null, renders SizedBox.shrink().
/// When a chip has been selected, renders the bar draining 100% → 0% and
/// a BodySmall caption showing "X:XX remaining".
class CooldownProgressBar extends StatelessWidget {
  const CooldownProgressBar({
    required this.totalSeconds,
    required this.remainingMs,
    super.key,
  });

  final int? totalSeconds;
  final int? remainingMs;

  @override
  Widget build(BuildContext context) {
    if (totalSeconds == null || remainingMs == null) {
      return const SizedBox.shrink();
    }
    final total = totalSeconds!;
    final remaining = remainingMs!;
    final progress = total > 0
        ? (remaining / (total * 1000)).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: <Widget>[
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 4),
        Text(
          _formatRemaining(remaining),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Formats remainingMs into "M:SS remaining"
  /// (e.g. 222000ms → "3:42 remaining").
  static String _formatRemaining(int ms) {
    final totalSec = (ms / 1000).ceil();
    final minutes = totalSec ~/ 60;
    final seconds = totalSec % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} remaining';
  }
}
