import '../models/charging_station.dart';

/// Stands in for a real backend/API client.
///
/// Every method returns a [Future] and introduces artificial latency so
/// the UI's loading states are exercised realistically. Swap this class
/// out for an HTTP-backed implementation (e.g. using `dio` or `http`)
/// once a real API is available — screens only depend on this
/// interface, not on how the data is fetched.
class DummyDataService {

  /// Simulates fetching nearby charging stations.
  /// [simulateError] lets callers/tests exercise the error UI on demand.
  Future<List<ChargingStation>> fetchNearbyStations({
    bool simulateError = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (simulateError) {
      throw Exception('Unable to reach charging network. Check your connection.');
    }

    return const [
      ChargingStation(
        id: 'st_001',
        name: 'GreenVolt Hub - MG Road',
        address: '12 MG Road, Kochi',
        distanceKm: 1.2,
        availableConnectors: 3,
        totalConnectors: 6,
        pricePerKwh: 12.5,
        ecoScore: 4.8,
        speed: ChargingSpeed.ultraFast,
      ),
      ChargingStation(
        id: 'st_002',
        name: 'EcoCharge Station',
        address: 'NH66, Tiruvalla Bypass',
        distanceKm: 3.6,
        availableConnectors: 0,
        totalConnectors: 4,
        pricePerKwh: 10.0,
        ecoScore: 4.2,
        speed: ChargingSpeed.fast,
      ),
      ChargingStation(
        id: 'st_003',
        name: 'SunPower Charge Point',
        address: 'Solar Park Road, Chengannur',
        distanceKm: 5.8,
        availableConnectors: 2,
        totalConnectors: 2,
        pricePerKwh: 9.5,
        ecoScore: 4.9,
        speed: ChargingSpeed.standard,
      ),
      ChargingStation(
        id: 'st_004',
        name: 'CityVolt Express',
        address: 'Railway Station Road, Alappuzha',
        distanceKm: 8.1,
        availableConnectors: 5,
        totalConnectors: 8,
        pricePerKwh: 11.0,
        ecoScore: 4.0,
        speed: ChargingSpeed.ultraFast,
      ),
    ];
  }

  /// Simulates app-startup initialization work (loading config, warming
  /// caches, checking auth, etc.) reporting progress as it goes via the
  /// returned [Stream], finishing at 1.0.
  Stream<double> initializeApp({bool simulateError = false}) async* {
    for (int i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 90));
      if (simulateError && i == 14) {
        throw Exception('Initialization failed. Please retry.');
      }
      yield i / 20;
    }
  }
}
