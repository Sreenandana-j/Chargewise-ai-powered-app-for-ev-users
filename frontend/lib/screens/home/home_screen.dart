import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/charging_station.dart';
import '../../data/services/charging_api_service.dart';
import '../../data/services/dummy_data_service.dart';
import 'widgets/station_card.dart';

/// Post-splash landing screen: a simple dashboard of nearby charging
/// stations. Demonstrates the same loading → data / error pattern used
/// on the splash screen, now applied to a real list of async data.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _ViewState { loading, data, error }

class _HomeScreenState extends State<HomeScreen> {
  final ChargingApiService _apiService = ChargingApiService();
  final DummyDataService _dataService = DummyDataService();

  _ViewState _state = _ViewState.loading;
  List<ChargingStation> _stations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _state = _ViewState.loading);
    try {
      // Try the real backend first; fall back to dummy data if unreachable.
      List<ChargingStation> stations;
      try {
        stations = await _apiService.fetchNearbyStations();
      } catch (_) {
        stations = await _dataService.fetchNearbyStations();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadStations,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Plan a Route',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.vehicles),
            icon: const Icon(Icons.directions_car_filled_rounded),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            icon: const Icon(Icons.person_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStations,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.loading:
        return const Center(child: CircularProgressIndicator());

      case _ViewState.error:
        return ListView(
          // Wrapped in a scrollable so RefreshIndicator's pull-to-retry
          // gesture still works even in the error state.
          children: [
            SizedBox(
              height: 420,
              child: ErrorView(
                message: _errorMessage ?? 'Unable to load stations.',
                onRetry: _loadStations,
              ),
            ),
          ],
        );

      case _ViewState.data:
        if (_stations.isEmpty) {
          return const Center(child: Text('No charging stations nearby.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _stations.length,
          itemBuilder: (context, index) {
            final station = _stations[index];
            return StationCard(
              station: station,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected ${station.name}')),
                );
              },
            );
          },
        );
    }
  }
}
