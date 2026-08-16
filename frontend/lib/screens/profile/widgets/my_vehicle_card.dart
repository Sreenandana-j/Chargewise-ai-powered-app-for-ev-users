import 'package:flutter/material.dart';
import '../../../data/models/profile_vehicle_summary.dart';

/// "My Vehicle" card on the Profile screen: vehicle name, range,
/// connector type, current battery percentage, and a "Change Vehicle"
/// button that hands off to the existing Vehicles screen.
class MyVehicleCard extends StatelessWidget {
  final ProfileVehicleSummary summary;
  final VoidCallback onChangeVehicle;

  const MyVehicleCard({
    super.key,
    required this.summary,
    required this.onChangeVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = summary.vehicle;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Vehicle', style: theme.textTheme.titleMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Range ${vehicle.estRangeKm} mi · ${summary.connectorType} Connector',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${vehicle.batteryPercent}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: vehicle.batteryPercent / 100,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onChangeVehicle,
                child: const Text('Change Vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
