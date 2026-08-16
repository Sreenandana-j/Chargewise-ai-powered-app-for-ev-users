import 'package:flutter/material.dart';
import '../../../core/widgets/tag_pill.dart';
import '../../../data/models/station_info.dart';

/// A single charging station in the "Charging Stations" scrollable
/// list: name, availability badge, distance, rating, connector-type
/// tags, live port availability, and a "Navigate" call to action.
class StationListCard extends StatelessWidget {
  final StationInfo station;
  final VoidCallback onNavigate;

  const StationListCard({super.key, required this.station, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableColor = theme.colorScheme.primary;
    final busyColor = theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(station.name, style: theme.textTheme.titleMedium),
                ),
                _AvailabilityBadge(
                  isAvailable: station.isAvailable,
                  availableColor: availableColor,
                  busyColor: busyColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 4),
                Text('${station.distanceKm.toStringAsFixed(1)} km', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 10),
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF9A825)),
                const SizedBox(width: 2),
                Text(
                  '${station.rating.toStringAsFixed(1)} (${station.ratingCount})',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final type in station.connectorTypes) TagPill(label: type)],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: availableColor),
                  const SizedBox(width: 4),
                  Text('${station.speedKw} kW', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Icon(Icons.ev_station_rounded, size: 16, color: theme.textTheme.bodyMedium?.color),
                  const SizedBox(width: 4),
                  Text(
                    '${station.availablePorts}/${station.totalPorts} ports free',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: station.portsFraction,
                minHeight: 6,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation(availableColor),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Navigate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  final Color availableColor;
  final Color busyColor;

  const _AvailabilityBadge({
    required this.isAvailable,
    required this.availableColor,
    required this.busyColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isAvailable ? availableColor : busyColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Available' : 'Busy',
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
