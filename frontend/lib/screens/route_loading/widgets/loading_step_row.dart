import 'package:flutter/material.dart';

/// One labeled step in the Route Loading screen's step tracker
/// (Route / Chargers / Traffic / ETA). Shows a filled check-circle once
/// [isComplete], and a dim outline circle beforehand.
class LoadingStepRow extends StatelessWidget {
  final List<String> steps;
  final int completedCount;

  const LoadingStepRow({
    super.key,
    required this.steps,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < completedCount
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: i < completedCount
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: i < completedCount
                        ? theme.colorScheme.primary
                        : theme.textTheme.labelSmall?.color,
                    fontWeight: i < completedCount ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
