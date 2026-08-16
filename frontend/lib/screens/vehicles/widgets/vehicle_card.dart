import 'package:flutter/material.dart';
import '../../../data/models/vehicle.dart';

/// Displays a single [Vehicle] as a card: hero image, name/variant,
/// estimated range, battery capacity + charge level, and a "Select
/// Vehicle" call to action — mirroring the "Your Vehicles" Figma design.
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onSelect;

  const VehicleCard({super.key, required this.vehicle, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image — network image with graceful loading/error fallback,
          // or stylish placeholder if URL is empty
          AspectRatio(
            aspectRatio: 16 / 9,
            child: vehicle.imageUrl.isNotEmpty
                ? Image.network(
                    vehicle.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: theme.colorScheme.surfaceContainerLow,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Icon(
                        Icons.directions_car_rounded,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.electric_car_rounded,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        if (vehicle.connectorType.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${vehicle.connectorType} · ${vehicle.chargingSpeedKw.toInt()} kW DC',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle.name, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(vehicle.variant, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${vehicle.estRangeKm} km',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text('est. range', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${vehicle.batteryCapacityKwh.toStringAsFixed(0)} kWh',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: vehicle.batteryPercent / 100,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${vehicle.batteryPercent}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    child: const Text('Select Vehicle'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
