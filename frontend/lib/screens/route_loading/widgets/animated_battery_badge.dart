import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// An animated "charging" battery badge for the Route Loading screen:
/// a battery outline with a pulsing fill and a bolt icon, plus the
/// current percentage printed underneath.
///
/// Built entirely from [AnimationController] + basic shapes (no image
/// assets, no extra animation packages), matching how
/// [CircularPercentIndicator] and [EvCarIllustration] are built
/// elsewhere in the app.
class AnimatedBatteryBadge extends StatefulWidget {
  final int percent;

  const AnimatedBatteryBadge({super.key, required this.percent});

  @override
  State<AnimatedBatteryBadge> createState() => _AnimatedBatteryBadgeState();
}

class _AnimatedBatteryBadgeState extends State<AnimatedBatteryBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = theme.brightness == Brightness.dark
        ? AppColors.accentGreen
        : AppColors.primaryGreen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                return Container(
                  width: 74,
                  height: 34,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: fillColor, width: 2.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor:
                              ((widget.percent / 100).clamp(0.05, 1.0) * _pulse.value)
                                  .toDouble(),
                          heightFactor: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: fillColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: theme.colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Battery "nub" on the right edge.
            Container(
              width: 5,
              height: 14,
              margin: const EdgeInsets.only(left: 1),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${widget.percent}%',
          style: theme.textTheme.headlineMedium?.copyWith(color: fillColor),
        ),
      ],
    );
  }
}
