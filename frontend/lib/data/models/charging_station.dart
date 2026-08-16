/// Represents a single EV charging station.
///
/// This mirrors the shape you would expect from a real charging-network
/// API response, so swapping [DummyDataService] for a real HTTP client
/// later only requires changing the service layer, not the UI.
class ChargingStation {
  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final int availableConnectors;
  final int totalConnectors;
  final double pricePerKwh;
  final double ecoScore; // 0.0 - 5.0
  final ChargingSpeed speed;

  const ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.availableConnectors,
    required this.totalConnectors,
    required this.pricePerKwh,
    required this.ecoScore,
    required this.speed,
  });

  bool get isAvailable => availableConnectors > 0;

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      availableConnectors: json['availableConnectors'] as int,
      totalConnectors: json['totalConnectors'] as int,
      pricePerKwh: (json['pricePerKwh'] as num).toDouble(),
      ecoScore: (json['ecoScore'] as num).toDouble(),
      speed: ChargingSpeed.values.firstWhere(
        (s) => s.name == json['speed'],
        orElse: () => ChargingSpeed.standard,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'distanceKm': distanceKm,
        'availableConnectors': availableConnectors,
        'totalConnectors': totalConnectors,
        'pricePerKwh': pricePerKwh,
        'ecoScore': ecoScore,
        'speed': speed.name,
      };

  /// Constructs a [ChargingStation] from the FastAPI backend
  /// `ChargingStationResponse` JSON.
  ///
  /// Backend fields: id (int), name, location, connector_types (list),
  /// max_power_kw, is_available (bool), price_per_kwh, operator.
  ///
  /// The backend doesn't track live connector counts or an eco score,
  /// so those are derived/defaulted from what's available:
  ///  - availableConnectors/totalConnectors derived from `is_available`
  ///    and the number of supported connector types.
  ///  - ecoScore defaults to a neutral 4.0 (backend has no rating data).
  ///  - distanceKm defaults to 0 (backend doesn't compute distance from
  ///    the user's location).
  factory ChargingStation.fromBackendJson(Map<String, dynamic> json) {
    final backendId = json['id'];
    final connectorTypes = (json['connector_types'] as List?)?.length ?? 1;
    final isAvailable = json['is_available'] as bool? ?? true;
    final maxPowerKw = (json['max_power_kw'] as num?)?.toDouble() ?? 0.0;

    return ChargingStation(
      id: backendId.toString(),
      name: json['name'] as String? ?? 'Charging Station',
      address: json['location'] as String? ?? '',
      distanceKm: 0.0,
      availableConnectors: isAvailable ? connectorTypes : 0,
      totalConnectors: connectorTypes,
      pricePerKwh: (json['price_per_kwh'] as num?)?.toDouble() ?? 0.0,
      ecoScore: 4.0,
      speed: maxPowerKw >= 100
          ? ChargingSpeed.ultraFast
          : (maxPowerKw >= 40 ? ChargingSpeed.fast : ChargingSpeed.standard),
    );
  }
}

enum ChargingSpeed { standard, fast, ultraFast }
