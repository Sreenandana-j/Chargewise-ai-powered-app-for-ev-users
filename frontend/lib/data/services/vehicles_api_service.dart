import '../models/vehicle.dart';
import 'api_client.dart';

/// Fetches the vehicle catalogue from the real FastAPI backend.
/// Endpoint: GET /vehicles (public — no auth required)
class VehiclesApiService {
  final _client = ApiClient.instance;

  /// Returns the full list of EV vehicles seeded in the backend.
  /// Throws [ApiException] on network or server errors.
  Future<List<Vehicle>> fetchVehicles() async {
    final rawList = await _client.getList('/vehicles', requiresAuth: false);
    return rawList
        .map((json) => Vehicle.fromBackendJson(json as Map<String, dynamic>))
        .toList();
  }
}
