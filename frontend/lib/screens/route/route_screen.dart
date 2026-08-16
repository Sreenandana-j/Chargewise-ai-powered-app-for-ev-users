import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../data/models/vehicle.dart';

/// Route planning args passed to the loading/results screens.
class RoutePlanArgs {
  final Vehicle? vehicle;
  final String origin;
  final String destination;
  final double batteryPercent;

  const RoutePlanArgs({
    required this.vehicle,
    required this.origin,
    required this.destination,
    required this.batteryPercent,
  });
}

/// "Route" tab — lets the user confirm origin/destination and current
/// battery percentage before jumping to the calculated Route Results screen.
///
/// Passes a [RoutePlanArgs] object to the loading screen so the backend
/// has all the parameters needed to call `/routes/plan`.
class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final TextEditingController _originController =
      TextEditingController(text: 'Tiruvalla, Kerala');
  final TextEditingController _destinationController = TextEditingController();

  double _batteryPercent = 80.0;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _findRoute(Vehicle? vehicle) {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination.')),
      );
      return;
    }

    // Route Planning → Route Loading (animated) → Route Results.
    Navigator.of(context).pushNamed(
      AppRoutes.routeLoading,
      arguments: RoutePlanArgs(
        vehicle: vehicle,
        origin: _originController.text.trim(),
        destination: destination,
        batteryPercent: _batteryPercent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = ModalRoute.of(context)?.settings.arguments as Vehicle?;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: const Text('Plan Route'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Where are you headed?', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                vehicle != null
                    ? 'Planning for ${vehicle.name} · ${vehicle.variant}'
                    : 'Select a vehicle first for a personalized route',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // ── Origin ─────────────────────────────────────────────────
              TextField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: 'Origin',
                  prefixIcon: const Icon(Icons.trip_origin_rounded),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Destination ────────────────────────────────────────────
              TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'Where to?',
                  prefixIcon: const Icon(Icons.location_on_rounded),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Battery Percentage ─────────────────────────────────────
              _BatterySlider(
                value: _batteryPercent,
                onChanged: (v) => setState(() => _batteryPercent = v),
                vehicle: vehicle,
              ),
              const SizedBox(height: 28),

              // ── Find Route ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _findRoute(vehicle),
                  icon: const Icon(Icons.alt_route_rounded),
                  label: const Text('Find Eco Route'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.route),
    );
  }
}

/// Battery percentage slider with live label and range estimate.
class _BatterySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Vehicle? vehicle;

  const _BatterySlider({
    required this.value,
    required this.onChanged,
    required this.vehicle,
  });

  Color _batteryColor(double pct) {
    if (pct < 20) return const Color(0xFFE53935);
    if (pct < 40) return const Color(0xFFFFA726);
    return const Color(0xFF43A047);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _batteryColor(value);
    final pct = value.round();

    // Estimate remaining range from vehicle specs
    String rangeLabel = '';
    if (vehicle != null && vehicle!.estRangeKm > 0) {
      final remaining = ((value / 100) * vehicle!.estRangeKm).round();
      rangeLabel = '≈ $remaining km remaining';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.battery_charging_full_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                'Current Battery Level',
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: color,
            onChanged: onChanged,
          ),
          if (rangeLabel.isNotEmpty)
            Text(
              rangeLabel,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
        ],
      ),
    );
  }
}
