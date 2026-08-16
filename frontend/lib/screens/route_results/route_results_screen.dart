import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/route_result.dart';
import '../../data/models/vehicle.dart';
import '../../data/services/route_api_service.dart';
import '../../data/services/route_planner_data_service.dart';
import '../route/route_screen.dart';
import 'widgets/charging_stop_card.dart';
import 'widgets/energy_breakdown_card.dart';
import 'widgets/route_map_placeholder.dart';
import 'widgets/route_map_view.dart';

/// Displays the calculated eco route:
/// - Real backend: called via [RouteApiService] with the [RoutePlanArgs]
///   passed from Route Loading screen (origin, destination, vehicle, battery%).
/// - Fallback: if no args or backend unreachable, uses [RoutePlannerDataService].
///
/// Shows an interactive OSM map (flutter_map) with the route polyline when
/// real data is available, or the placeholder when using dummy data.
class RouteResultsScreen extends StatefulWidget {
  const RouteResultsScreen({super.key});

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

enum _ViewState { loading, data, error }

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  final RouteApiService _apiService = RouteApiService();
  final RoutePlannerDataService _fallbackService = RoutePlannerDataService();

  _ViewState _state = _ViewState.loading;
  RouteResult? _result;
  String? _errorMessage;
  bool _requested = false;
  RoutePlanArgs? _planArgs;

  static const _fallbackVehicle = Vehicle(
    id: 'veh_default',
    name: 'your EV',
    variant: '',
    imageUrl: '',
    batteryCapacityKwh: 0,
    estRangeKm: 0,
    batteryPercent: 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is RoutePlanArgs) {
        _planArgs = args;
        _loadRealRoute(args);
      } else {
        // Fallback: legacy vehicle-only arg
        final vehicle = args as Vehicle? ?? _fallbackVehicle;
        _loadFallbackRoute(vehicle);
      }
    }
  }

  /// Call the real FastAPI /routes/plan endpoint.
  Future<void> _loadRealRoute(RoutePlanArgs args) async {
    setState(() => _state = _ViewState.loading);
    try {
      final result = await _apiService.planRoute(
        RoutePlanParams(
          origin: args.origin,
          destination: args.destination,
          vehicle: args.vehicle ?? _fallbackVehicle,
          batteryPercent: args.batteryPercent,
        ),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = _ViewState.data;
      });
    } catch (e) {
      // Try dummy fallback before showing error
      try {
        final result = await _fallbackService.calculateRoute(
          vehicle: args.vehicle ?? _fallbackVehicle,
        );
        if (!mounted) return;
        setState(() {
          _result = result;
          _state = _ViewState.data;
        });
      } catch (fallbackErr) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _state = _ViewState.error;
        });
      }
    }
  }

  Future<void> _loadFallbackRoute(Vehicle vehicle) async {
    setState(() => _state = _ViewState.loading);
    try {
      final result = await _fallbackService.calculateRoute(vehicle: vehicle);
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = _ViewState.data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _state = _ViewState.error;
      });
    }
  }

  void _goToStations() {
    Navigator.of(context).pushNamed(AppRoutes.stations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: const Text('Route Found'),
      ),
      body: SafeArea(top: false, child: _buildBody()),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.results),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.loading:
        return const Center(child: CircularProgressIndicator());

      case _ViewState.error:
        return ErrorView(
          message: _errorMessage ?? 'Unable to calculate a route.',
          onRetry: () {
            _requested = false;
            didChangeDependencies();
          },
        );

      case _ViewState.data:
        final result = _result!;
        final theme = Theme.of(context);
        final arrivalLabel = TimeOfDay.fromDateTime(result.arrivalTime).format(context);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            // ── Route subtitle ────────────────────────────────────────
            const SizedBox(height: 8),
            Text(
              '${result.routeType} — Optimized for ${result.vehicleName}',
              style: theme.textTheme.bodyMedium,
            ),
            if (_planArgs != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.trip_origin_rounded, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_planArgs!.origin}  →  ${_planArgs!.destination}',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // ── Map ───────────────────────────────────────────────────
            result.routePolyline.isNotEmpty
                ? RouteMapView(
                    routePolyline: result.routePolyline,
                    totalDistanceKm: result.totalDistanceKm,
                    hasChargingStop: result.chargingStop != null,
                  )
                : RouteMapPlaceholder(
                    totalDistanceKm: result.totalDistanceKm,
                    hasChargingStop: result.chargingStop != null,
                  ),

            const SizedBox(height: 16),

            // ── Stats grid ────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  icon: Icons.alt_route_rounded,
                  iconColor: theme.colorScheme.primary,
                  value: '${result.totalDistanceKm.toStringAsFixed(1)} km',
                  label: 'Total Distance',
                ),
                StatCard(
                  icon: Icons.access_time_rounded,
                  iconColor: theme.colorScheme.primary,
                  value: _formatDuration(result.travelTime),
                  label: 'Travel Time',
                ),
                StatCard(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: _batteryColor(result.batteryOnArrivalPercent, theme),
                  value: '${result.batteryOnArrivalPercent}%',
                  label: 'Battery on Arrival',
                ),
                StatCard(
                  icon: Icons.navigation_rounded,
                  iconColor: theme.colorScheme.primary,
                  value: arrivalLabel,
                  label: 'Arrival Time',
                ),
              ],
            ),

            // ── Charging stop ─────────────────────────────────────────
            if (result.chargingStop != null) ...[
              const SizedBox(height: 16),
              ChargingStopCard(
                stop: result.chargingStop!,
                onViewAllStations: _goToStations,
              ),
            ],

            // ── Energy breakdown ──────────────────────────────────────
            const SizedBox(height: 16),
            EnergyBreakdownCard(breakdown: result.energyBreakdown),

            // ── Battery warning ───────────────────────────────────────
            if (result.batteryOnArrivalPercent < 20) ...[
              const SizedBox(height: 12),
              _BatteryWarningBanner(percent: result.batteryOnArrivalPercent),
            ],

            // ── Start Navigation CTA ──────────────────────────────────
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Starting turn-by-turn navigation…'),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation_rounded),
                label: const Text(
                  'Start Navigation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
    }
  }

  Color _batteryColor(int percent, ThemeData theme) {
    if (percent < 20) return const Color(0xFFE53935);
    if (percent < 40) return const Color(0xFFFFA726);
    return theme.colorScheme.primary;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }
}

/// Warning banner shown when battery on arrival is critically low.
class _BatteryWarningBanner extends StatelessWidget {
  final int percent;
  const _BatteryWarningBanner({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Battery will be at $percent% on arrival. A charging stop is strongly recommended.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
