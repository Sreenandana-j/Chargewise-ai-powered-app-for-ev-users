/// A previously-run route the user has bookmarked, shown in the
/// "Saved Routes" section of the Profile screen (origin → destination,
/// distance, and estimated travel time).
class SavedRoute {
  final String id;
  final String origin;
  final String destination;
  final double distanceMiles;
  final int etaMinutes;

  const SavedRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.distanceMiles,
    required this.etaMinutes,
  });
}
