import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/route_result.dart';

/// Shows how energy was spent/added across a route: driving
/// consumption, climate control, and charging added — each as a
/// labeled proportional bar.
class EnergyBreakdownCard extends StatelessWidget {
  final EnergyBreakdown breakdown;

  const EnergyBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxKwh = breakdown.maxKwh;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ENERGY BREAKDOWN',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _EnergyRow(
              label: 'Driving consumption',
              valueKwh: breakdown.drivingKwh,
              maxKwh: maxKwh,
              color: AppColors.chipBlue,
            ),
            const SizedBox(height: 12),
            _EnergyRow(
              label: 'Climate control',
              valueKwh: breakdown.climateControlKwh,
              maxKwh: maxKwh,
              color: AppColors.chipYellow,
            ),
            const SizedBox(height: 12),
            _EnergyRow(
              label: 'Charging added',
              valueKwh: breakdown.chargingAddedKwh,
              maxKwh: maxKwh,
              color: AppColors.primaryGreen,
              isPositive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyRow extends StatelessWidget {
  final String label;
  final double valueKwh;
  final double maxKwh;
  final Color color;
  final bool isPositive;

  const _EnergyRow({
    required this.label,
    required this.valueKwh,
    required this.maxKwh,
    required this.color,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxKwh == 0 ? 0.0 : (valueKwh / maxKwh).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '${isPositive ? '+' : ''}${valueKwh.toStringAsFixed(0)} kWh',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
