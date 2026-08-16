/// Richer charging-station record used specifically by the "Charging
/// Stations" listing/filter screen (rating, connector types, live port
/// availability).
///
/// This is intentionally separate from [ChargingStation] (the simpler
/// model already used on the dashboard) rather than modifying that
/// existing model — it keeps the current home dashboard untouched while
/// giving the new listing screen the extra fields its design needs.
class StationInfo {
  final String id;
  final String name;
  final double distanceKm;
  final double rating;
  final int ratingCount;
  final bool isAvailable; // false = "Busy"
  final List<String> connectorTypes; // e.g. CCS2, Type 2, CHAdeMO
  final int speedKw;
  final int availablePorts;
  final int totalPorts;

  const StationInfo({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.rating,
    required this.ratingCount,
    required this.isAvailable,
    required this.connectorTypes,
    required this.speedKw,
    required this.availablePorts,
    required this.totalPorts,
  });

  /// Used by the "Fast Chargers" filter chip.
  bool get isFastCharger => speedKw >= 100;

  double get portsFraction =>
      totalPorts == 0 ? 0 : availablePorts / totalPorts;

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    return StationInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      isAvailable: json['isAvailable'] as bool,
      connectorTypes: List<String>.from(json['connectorTypes'] as List),
      speedKw: json['speedKw'] as int,
      availablePorts: json['availablePorts'] as int,
      totalPorts: json['totalPorts'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'distanceKm': distanceKm,
        'rating': rating,
        'ratingCount': ratingCount,
        'isAvailable': isAvailable,
        'connectorTypes': connectorTypes,
        'speedKw': speedKw,
        'availablePorts': availablePorts,
        'totalPorts': totalPorts,
      };

  /// Constructs a [StationInfo] from the FastAPI backend
  /// `ChargingStationResponse` JSON.
  ///
  /// The backend has no rating/review data or live port counts, so
  /// those are defaulted/derived from `is_available` and the number of
  /// supported connector types (the closest available proxy).
  factory StationInfo.fromBackendJson(Map<String, dynamic> json) {
    final backendId = json['id'];
    final connectorTypes =
        (json['connector_types'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final isAvailable = json['is_available'] as bool? ?? true;
    final totalPorts = connectorTypes.isEmpty ? 1 : connectorTypes.length;

    return StationInfo(
      id: backendId.toString(),
      name: json['name'] as String? ?? 'Charging Station',
      distanceKm: 0.0,
      rating: 4.0,
      ratingCount: 0,
      isAvailable: isAvailable,
      connectorTypes: connectorTypes,
      speedKw: (json['max_power_kw'] as num?)?.round() ?? 0,
      availablePorts: isAvailable ? totalPorts : 0,
      totalPorts: totalPorts,
    );
  }
}
