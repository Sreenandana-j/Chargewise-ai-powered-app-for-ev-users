import 'package:flutter/material.dart';

/// Three dots that pulse in sequence next to a status label, mirroring
/// the "● ● ● Initializing..." pattern in the Figma splash design.
///
/// Self-contained: owns its own [AnimationController] so it can be
/// dropped anywhere without extra wiring.
class LoadingDotsIndicator extends StatefulWidget {
  final String label;

  const LoadingDotsIndicator({super.key, required this.label});

  @override
  State<LoadingDotsIndicator> createState() => _LoadingDotsIndicatorState();
}

class _LoadingDotsIndicatorState extends State<LoadingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.dividerColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Stagger each dot's "pulse window" across the cycle.
              final t = (_controller.value - index * 0.2) % 1.0;
              final isActive = t < 0.35;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? activeColor : inactiveColor,
                ),
              );
            },
          );
        }),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
