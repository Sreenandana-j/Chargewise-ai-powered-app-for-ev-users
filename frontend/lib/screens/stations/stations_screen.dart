import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/station_info.dart';
import '../../data/services/charging_api_service.dart';
import '../../data/services/route_planner_data_service.dart';
import 'widgets/station_list_card.dart';

/// The three quick filters available above the station list, matching
/// the Figma "Charging Stations" design.
enum _StationFilter { nearby, available, fastChargers }

/// "Charging Stations" screen — a filterable, scrollable list of nearby
/// stations reached from the Route Results screen's "View All Stations"
/// link (or directly via the bottom nav "Stations" tab).
///
/// Follows the same loading → data / error [_ViewState] pattern used
/// across the rest of the route-planning flow for consistency.
class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

enum _ViewState { loading, data, error }

class _StationsScreenState extends State<StationsScreen> {
  final ChargingApiService _apiService = ChargingApiService();
  final RoutePlannerDataService _dataService = RoutePlannerDataService();

  _ViewState _state = _ViewState.loading;
  List<StationInfo> _stations = [];
  String? _errorMessage;
  _StationFilter _filter = _StationFilter.nearby;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _state = _ViewState.loading);
    try {
      // Try the real backend first; fall back to dummy data if unreachable.
      List<StationInfo> stations;
      try {
        stations = await _apiService.fetchStationsList();
      } catch (_) {
        stations = await _dataService.fetchStationsList();
      }
      if (!mounted) return;
      setState(() {
        _stations = stations;
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

  /// Applies the active chip filter. "Nearby" is the default/unfiltered
  /// view (the service already returns stations sorted by distance).
  List<StationInfo> get _filteredStations {
    switch (_filter) {
      case _StationFilter.nearby:
        return _stations;
      case _StationFilter.available:
        return _stations.where((s) => s.isAvailable).toList();
      case _StationFilter.fastChargers:
        return _stations.where((s) => s.isFastCharger).toList();
    }
  }

  void _onNavigate(StationInfo station) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to ${station.name}…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: const Text('Charging Stations'),
      ),
      body: SafeArea(top: false, child: _buildBody()),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.stations),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.loading:
        return const Center(child: CircularProgressIndicator());

      case _ViewState.error:
        return ErrorView(
          message: _errorMessage ?? 'Unable to load charging stations.',
          onRetry: _loadStations,
        );

      case _ViewState.data:
        final stations = _filteredStations;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_stations.length} stations found nearby',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  _FilterChipRow(
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ],
              ),
            ),
            Expanded(
              child: stations.isEmpty
                  ? Center(
                      child: Text(
                        'No stations match this filter.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStations,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        itemCount: stations.length,
                        itemBuilder: (context, index) {
                          final station = stations[index];
                          return StationListCard(
                            station: station,
                            onNavigate: () => _onNavigate(station),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
    }
  }
}

/// Horizontally-scrollable row of "Nearby / Available / Fast Chargers"
/// filter chips shown above the station list.
class _FilterChipRow extends StatelessWidget {
  final _StationFilter selected;
  final ValueChanged<_StationFilter> onChanged;

  const _FilterChipRow({required this.selected, required this.onChanged});

  static const _labels = {
    _StationFilter.nearby: 'Nearby',
    _StationFilter.available: 'Available',
    _StationFilter.fastChargers: 'Fast Chargers',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _StationFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_labels[filter]!),
                selected: selected == filter,
                onSelected: (_) => onChanged(filter),
                showCheckmark: false,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: selected == filter
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }
}
