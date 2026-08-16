import 'package:flutter/material.dart';

/// A circular progress ring with the percentage printed in the middle,
/// e.g. the "100%" badge on the splash screen.
class CircularPercentIndicator extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double size;

  const CircularPercentIndicator({
    super.key,
    required this.progress,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: 3,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          Text(
            '${(clamped * 100).round()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
