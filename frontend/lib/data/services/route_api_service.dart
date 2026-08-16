import '../models/route_result.dart';
import '../models/vehicle.dart';
import 'api_client.dart';

/// Route planning parameters passed to the backend.
class RoutePlanParams {
  final String origin;
  final String destination;
  final Vehicle vehicle;
  final double batteryPercent;

  // Level 2 optional adjustments
  final double elevationGainM;
  final double avgSpeedKmh;
  final double temperatureC;
  final String trafficLevel; // "low" | "medium" | "heavy"
  final bool acOn;
  final double payloadWeightKg;
  final String roadType; // "city" | "highway" | "mixed"
  final double batteryHealth;

  const RoutePlanParams({
    required this.origin,
    required this.destination,
    required this.vehicle,
    required this.batteryPercent,
    this.elevationGainM = 0.0,
    this.avgSpeedKmh = 60.0,
    this.temperatureC = 25.0,
    this.trafficLevel = 'low',
    this.acOn = false,
    this.payloadWeightKg = 0.0,
    this.roadType = 'mixed',
    this.batteryHealth = 100.0,
  });
}

/// Calls the real FastAPI route planning endpoint.
/// Endpoint: POST /routes/plan  (authenticated)
///
/// Falls back gracefully: if the backend is unreachable, throws an
/// [ApiException] so the screen can show a proper error message.
class RouteApiService {
  final _client = ApiClient.instance;

  /// Plan an eco-route for the given [params].
  ///
  /// Returns a [RouteResult] parsed from the backend `RoutePlanResponse`.
  /// Throws [ApiException] on validation errors, auth failures, or network issues.
  Future<RouteResult> planRoute(RoutePlanParams params) async {
    final body = <String, dynamic>{
      'origin': params.origin,
      'destination': params.destination,
      'vehicle_id': params.vehicle.vehicleId,
      'battery_percentage': params.batteryPercent,
      'elevation_gain_m': params.elevationGainM,
      'avg_speed_kmh': params.avgSpeedKmh,
      'temperature_c': params.temperatureC,
      'traffic_level': params.trafficLevel,
      'ac_on': params.acOn,
      'payload_weight_kg': params.payloadWeightKg,
      'road_type': params.roadType,
      'battery_health': params.batteryHealth,
    };

    final response = await _client.post('/routes/plan', body);
    return RouteResult.fromBackendJson(response);
  }
}
