import '../models/route_result.dart';
import '../models/station_info.dart';
import '../models/vehicle.dart';

/// Stands in for a real backend/API client, following the same shape as
/// [DummyDataService]: every method returns a [Future] with artificial
/// latency so loading states are exercised realistically.
///
/// Kept as a separate file (rather than adding methods to the existing
/// `DummyDataService`) so the original data service — already relied on
/// by the home dashboard — stays untouched. Once a real backend exists,
/// this is the only class that needs to change; screens depend on this
/// interface, not on how the data is fetched.
class RoutePlannerDataService {
  /// Simulates fetching the user's saved vehicles.
  Future<List<Vehicle>> fetchVehicles({bool simulateError = false}) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (simulateError) {
      throw Exception('Unable to load your vehicles. Check your connection.');
    }

    return const [
      Vehicle(
        id: 'veh_001',
        name: 'Tesla Model 3',
        variant: 'Long Range AWD',
        imageUrl: 'https://picsum.photos/seed/tesla-model-3/800/600',
        batteryCapacityKwh: 82,
        estRangeKm: 602,
        batteryPercent: 82,
      ),
      Vehicle(
        id: 'veh_002',
        name: 'Hyundai IONIQ 6',
        variant: 'Long Range RWD',
        imageUrl: 'https://picsum.photos/seed/hyundai-ioniq6/800/600',
        batteryCapacityKwh: 77,
        estRangeKm: 385,
        batteryPercent: 55,
      ),
      Vehicle(
        id: 'veh_003',
        name: 'BMW iX3',
        variant: 'Impressive Edition',
        imageUrl: 'https://picsum.photos/seed/bmw-ix3/800/600',
        batteryCapacityKwh: 80,
        estRangeKm: 460,
        batteryPercent: 68,
      ),
      Vehicle(
        id: 'veh_004',
        name: 'Kia EV6',
        variant: 'GT-Line AWD',
        imageUrl: 'https://picsum.photos/seed/kia-ev6/800/600',
        batteryCapacityKwh: 77,
        estRangeKm: 480,
        batteryPercent: 90,
      ),
    ];
  }

  /// Simulates running an eco-route calculation for [vehicle].
  Future<RouteResult> calculateRoute({
    required Vehicle vehicle,
    bool simulateError = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (simulateError) {
      throw Exception('Could not calculate a route. Please try again.');
    }

    final now = DateTime.now();

    return RouteResult(
      routeType: 'Eco Route',
      vehicleName: vehicle.name,
      totalDistanceKm: 284,
      travelTime: const Duration(hours: 2, minutes: 48),
      batteryOnArrivalPercent: 12,
      arrivalTime: DateTime(now.year, now.month, now.day, 17, 22),
      chargingStop: const ChargingStop(
        stationName: 'GreenCharge Hub',
        atDistanceKm: 198,
        chargeTimeMinutes: 22,
        estimatedCost: 8.40,
        speedKw: 150,
      ),
      energyBreakdown: const EnergyBreakdown(
        drivingKwh: 58,
        climateControlKwh: 12,
        chargingAddedKwh: 44,
      ),
    );
  }

  /// Simulates fetching a filterable list of nearby charging stations.
  Future<List<StationInfo>> fetchStationsList({
    bool simulateError = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (simulateError) {
      throw Exception('Unable to load charging stations nearby.');
    }

    return const [
      StationInfo(
        id: 'stn_001',
        name: 'GreenCharge Hub — Central',
        distanceKm: 0.8,
        rating: 4.8,
        ratingCount: 312,
        isAvailable: true,
        connectorTypes: ['CCS2', 'Type 2'],
        speedKw: 150,
        availablePorts: 4,
        totalPorts: 6,
      ),
      StationInfo(
        id: 'stn_002',
        name: 'EcoVolt Station — Northside',
        distanceKm: 1.4,
        rating: 4.3,
        ratingCount: 87,
        isAvailable: false,
        connectorTypes: ['CHAdeMO', 'CCS2'],
        speedKw: 50,
        availablePorts: 0,
        totalPorts: 4,
      ),
      StationInfo(
        id: 'stn_003',
        name: 'FastCharge Point — West Mall',
        distanceKm: 2.1,
        rating: 4.6,
        ratingCount: 154,
        isAvailable: true,
        connectorTypes: ['CCS2', 'Type 2'],
        speedKw: 120,
        availablePorts: 2,
        totalPorts: 4,
      ),
      StationInfo(
        id: 'stn_004',
        name: 'SunPower Charge Point',
        distanceKm: 5.8,
        rating: 4.9,
        ratingCount: 63,
        isAvailable: true,
        connectorTypes: ['Type 2'],
        speedKw: 22,
        availablePorts: 2,
        totalPorts: 2,
      ),
    ];
  }
}
