import 'package:flutter/material.dart';
import '../../../data/models/route_result.dart';

/// Highlights the single recommended charging stop on a calculated
/// route: station name + distance, then charge time / cost / speed in
/// three compact columns, plus a link through to the full stations
/// list.
class ChargingStopCard extends StatelessWidget {
  final ChargingStop stop;
  final VoidCallback onViewAllStations;

  const ChargingStopCard({
    super.key,
    required this.stop,
    required this.onViewAllStations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 6),
                Text('Recommended Charging Stop', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(stop.stationName, style: theme.textTheme.titleMedium),
                      ),
                      Text('km ${stop.atDistanceKm}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MiniStat(
                        icon: Icons.access_time_rounded,
                        value: '${stop.chargeTimeMinutes} min',
                        label: 'Charge Time',
                      ),
                      _MiniStat(
                        icon: Icons.attach_money_rounded,
                        value: stop.estimatedCost.toStringAsFixed(2),
                        label: 'Est. Cost',
                      ),
                      _MiniStat(
                        icon: Icons.speed_rounded,
                        value: '${stop.speedKw} kW',
                        label: 'Speed',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewAllStations,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All Stations'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: theme.textTheme.bodyMedium?.color),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
          Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
