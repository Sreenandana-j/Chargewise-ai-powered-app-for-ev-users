import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/vehicle.dart';
import '../../data/services/route_planner_data_service.dart';
import '../../data/services/vehicles_api_service.dart';
import 'widgets/vehicle_card.dart';

/// "Your Vehicles" screen — the entry point of the route-planning flow.
/// The user picks a vehicle here, then continues on to the Route
/// Results screen for that vehicle.
///
/// Follows the same loading → data / error [_ViewState] pattern used on
/// [HomeScreen] and the splash screen for consistency across the app.
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

enum _ViewState { loading, data, error }

class _VehiclesScreenState extends State<VehiclesScreen> {
  final VehiclesApiService _apiService = VehiclesApiService();
  final RoutePlannerDataService _fallbackService = RoutePlannerDataService();
  final TextEditingController _searchController = TextEditingController();

  _ViewState _state = _ViewState.loading;
  List<Vehicle> _vehicles = [];
  String _query = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _state = _ViewState.loading);
    try {
      // Try the real backend first; fall back to dummy data if unreachable.
      List<Vehicle> vehicles;
      try {
        vehicles = await _apiService.fetchVehicles();
      } catch (_) {
        vehicles = await _fallbackService.fetchVehicles();
      }
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
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

  List<Vehicle> get _filteredVehicles {
    if (_query.isEmpty) return _vehicles;
    return _vehicles
        .where((v) => '${v.name} ${v.variant}'.toLowerCase().contains(_query))
        .toList();
  }

  void _onVehicleSelected(Vehicle vehicle) {
    // Vehicles → Route Planning, carrying the chosen vehicle forward.
    Navigator.of(context).pushNamed(AppRoutes.route, arguments: vehicle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(onPressed: () => Navigator.of(context).maybePop()),
                  ),
                  Text(
                    'EV ROUTE PLANNER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Your Vehicles', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Select a vehicle to begin route planning',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search vehicles...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.vehicles),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.loading:
        return const Center(child: CircularProgressIndicator());

      case _ViewState.error:
        return ErrorView(
          message: _errorMessage ?? 'Unable to load vehicles.',
          onRetry: _loadVehicles,
        );

      case _ViewState.data:
        final vehicles = _filteredVehicles;
        return RefreshIndicator(
          onRefresh: _loadVehicles,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            // +1 for the trailing "Add New Vehicle" placeholder card.
            itemCount: vehicles.length + 1,
            itemBuilder: (context, index) {
              if (index == vehicles.length) {
                return _AddVehicleCard(onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add-vehicle flow coming soon')),
                  );
                });
              }
              final vehicle = vehicles[index];
              return VehicleCard(
                vehicle: vehicle,
                onSelect: () => _onVehicleSelected(vehicle),
              );
            },
          ),
        );
    }
  }
}

/// Dashed "Add New Vehicle" placeholder shown at the end of the list,
/// matching the Figma design's connect-via-OBD-II entry point.
class _AddVehicleCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddVehicleCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: _SoftBorderBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),
                Text('Add New Vehicle', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Connect via OBD-II or enter specs manually',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight bordered container (no extra package dependency) used
/// only by [_AddVehicleCard] to suggest a tappable "add" slot.
class _SoftBorderBox extends StatelessWidget {
  final Widget child;

  const _SoftBorderBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor,
          width: 1.4,
        ),
      ),
      child: child,
    );
  }
}
