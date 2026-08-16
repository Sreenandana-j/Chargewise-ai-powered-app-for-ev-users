/// Represents the signed-in user's profile: identity, membership tier,
/// and the lifetime driving stats shown at the top of the Profile
/// screen (Routes / Miles / Saved).
///
/// Kept as its own small model — separate from [Vehicle] or any account
/// system — so a real auth/profile API can be swapped in later without
/// touching the Profile screen itself.
class UserProfile {
  final String name;
  final String email;
  final String avatarUrl;
  final bool isPremiumMember;
  final int totalRoutes;
  final int totalMiles;
  final int totalSaved;

  const UserProfile({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isPremiumMember,
    required this.totalRoutes,
    required this.totalMiles,
    required this.totalSaved,
  });
}
