import '../models/profile_vehicle_summary.dart';
import '../models/saved_route.dart';
import '../models/user_profile.dart';
import '../models/vehicle.dart';

/// Stands in for a real backend/API client, following the same shape as
/// [DummyDataService] / [RoutePlannerDataService]: every method returns
/// a [Future] with artificial latency so the Profile screen's loading
/// states are exercised realistically.
///
/// Kept as a separate file so the existing data services stay
/// untouched. Once a real backend exists, this is the only class that
/// needs to change — the Profile screen only depends on this interface.
class ProfileDataService {
  /// Simulates fetching the signed-in user's profile + lifetime stats.
  Future<UserProfile> fetchProfile({bool simulateError = false}) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (simulateError) {
      throw Exception('Unable to load your profile. Check your connection.');
    }

    return const UserProfile(
      name: 'Alex Johnson',
      email: 'alex.johnson@email.com',
      avatarUrl: 'https://i.pravatar.cc/160?img=12',
      isPremiumMember: true,
      totalRoutes: 48,
      totalMiles: 2341,
      totalSaved: 12,
    );
  }

  /// Simulates fetching the user's currently active vehicle for the
  /// "My Vehicle" summary card.
  Future<ProfileVehicleSummary> fetchActiveVehicle({
    bool simulateError = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (simulateError) {
      throw Exception('Unable to load your vehicle.');
    }

    return const ProfileVehicleSummary(
      vehicle: Vehicle(
        id: 'veh_001',
        name: 'Tesla Model 3 Long Range',
        variant: 'AWD',
        imageUrl: 'https://picsum.photos/seed/tesla-model-3/800/600',
        batteryCapacityKwh: 82,
        estRangeKm: 358,
        batteryPercent: 82,
      ),
      connectorType: 'CCS',
    );
  }

  /// Simulates fetching the user's saved/bookmarked routes.
  Future<List<SavedRoute>> fetchSavedRoutes({bool simulateError = false}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (simulateError) {
      throw Exception('Unable to load your saved routes.');
    }

    return const [
      SavedRoute(
        id: 'sr_001',
        origin: 'Home',
        destination: 'Office',
        distanceMiles: 24,
        etaMinutes: 34,
      ),
      SavedRoute(
        id: 'sr_002',
        origin: 'Office',
        destination: 'Supercharger - Oak St',
        distanceMiles: 2.1,
        etaMinutes: 5,
      ),
      SavedRoute(
        id: 'sr_003',
        origin: 'Home',
        destination: 'Whole Foods Market',
        distanceMiles: 8.4,
        etaMinutes: 14,
      ),
    ];
  }
}
