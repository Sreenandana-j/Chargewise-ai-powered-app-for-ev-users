import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/charging_station.dart';

/// Displays a single [ChargingStation] as a tappable card in the
/// dashboard list — distance, connector availability, price, and an
/// eco-score badge, mirroring the visual language of the splash chips.
class StationCard extends StatelessWidget {
  final ChargingStation station;
  final VoidCallback? onTap;

  const StationCard({super.key, required this.station, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = station.isAvailable;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Speed / status icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (available ? AppColors.primaryGreen : theme.disabledColor)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _speedIcon(station.speed),
                  color: available ? AppColors.primaryGreen : theme.disabledColor,
                ),
              ),
              const SizedBox(width: 12),
              // Name / address / connectors
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.address,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.ev_station_rounded,
                            size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          available
                              ? '${station.availableConnectors}/${station.totalConnectors} available'
                              : 'Fully occupied',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.eco_rounded,
                            size: 14, color: AppColors.chipLeaf),
                        const SizedBox(width: 4),
                        Text(
                          station.ecoScore.toStringAsFixed(1),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Distance + price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${station.distanceKm.toStringAsFixed(1)} km',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${station.pricePerKwh.toStringAsFixed(1)}/kWh',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _speedIcon(ChargingSpeed speed) {
    switch (speed) {
      case ChargingSpeed.ultraFast:
        return Icons.flash_on_rounded;
      case ChargingSpeed.fast:
        return Icons.bolt_rounded;
      case ChargingSpeed.standard:
        return Icons.battery_charging_full_rounded;
    }
  }
}
