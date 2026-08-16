import '../models/charging_station.dart';
import '../models/station_info.dart';
import 'api_client.dart';

/// Fetches EV charging stations from the real FastAPI backend.
/// Endpoint: GET /charging-stations (authenticated)
///
/// Follows the same shape as [VehiclesApiService] / [RouteApiService]:
/// a thin wrapper around [ApiClient] that parses the backend JSON into
/// the frontend's existing models. Screens keep their existing dummy
/// fallback pattern for when the backend is unreachable.
class ChargingApiService {
  final _client = ApiClient.instance;

  /// Returns charging stations mapped to the simpler [ChargingStation]
  /// model used by the Home dashboard.
  Future<List<ChargingStation>> fetchNearbyStations() async {
    final rawList = await _client.getList('/charging-stations');
    return rawList
        .map((json) =>
            ChargingStation.fromBackendJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Returns charging stations mapped to the richer [StationInfo] model
  /// used by the "Charging Stations" listing/filter screen.
  Future<List<StationInfo>> fetchStationsList() async {
    final rawList = await _client.getList('/charging-stations');
    return rawList
        .map((json) => StationInfo.fromBackendJson(json as Map<String, dynamic>))
        .toList();
  }
}
