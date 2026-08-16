import '../models/user_profile.dart';
import 'api_client.dart';

/// Fetches the signed-in user's identity from the real FastAPI backend.
/// Endpoint: GET /user/profile (authenticated)
///
/// The backend's `UserProfileResponse` only carries identity fields
/// (name, email, trip_count) — it has no concept of "lifetime miles"
/// or "saved" stats, so those are defaulted to 0 here. The Profile
/// screen keeps using [ProfileDataService] for the "My Vehicle" summary
/// and "Saved Routes" list, since the backend has no matching endpoint
/// for either of those yet.
class ProfileApiService {
  final _client = ApiClient.instance;

  Future<UserProfile> fetchProfile() async {
    final json = await _client.get('/user/profile');
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: '',
      isPremiumMember: false,
      totalRoutes: (json['trip_count'] as num?)?.toInt() ?? 0,
      totalMiles: 0,
      totalSaved: 0,
    );
  }
}
