/// Represents an electric vehicle in the app.
///
/// Supports two construction paths:
///  1. [Vehicle()] const constructor — for dummy/fallback data.
///  2. [Vehicle.fromBackendJson()] — maps the FastAPI `VehicleResponse` schema
///     (vehicle_name, battery_capacity, range_km, connector_type, etc.)
class Vehicle {
  /// Integer backend ID — used when calling `/routes/plan`.
  final int vehicleId;

  /// Legacy string ID for internal / dummy use.
  final String id;

  final String name;
  final String variant;
  final String imageUrl;
  final double batteryCapacityKwh;
  final int estRangeKm;
  final int batteryPercent; // 0 - 100
  final String connectorType; // e.g. "CCS2", "Type 2"
  final double chargingSpeedKw; // max DC charging speed

  const Vehicle({
    this.vehicleId = 0,
    required this.id,
    required this.name,
    required this.variant,
    required this.imageUrl,
    required this.batteryCapacityKwh,
    required this.estRangeKm,
    required this.batteryPercent,
    this.connectorType = 'CCS2',
    this.chargingSpeedKw = 50.0,
  });

  /// Constructs a [Vehicle] from the FastAPI backend `VehicleResponse` JSON.
  ///
  /// Backend fields:
  ///   id (int), vehicle_name, battery_capacity (kWh), efficiency (kWh/km),
  ///   connector_type, charging_speed (kW), range_km, manufacturer, year
  factory Vehicle.fromBackendJson(Map<String, dynamic> json) {
    final backendId = json['id'] as int? ?? 0;
    final name = json['vehicle_name'] as String? ?? 'Unknown EV';
    final manufacturer = json['manufacturer'] as String? ?? '';
    final year = json['year'] as int?;

    // Build a variant string from manufacturer + year if available
    String variant = '';
    if (manufacturer.isNotEmpty) variant = manufacturer;
    if (year != null) variant = variant.isEmpty ? '$year' : '$variant · $year';

    return Vehicle(
      vehicleId: backendId,
      id: 'veh_$backendId',
      name: name,
      variant: variant,
      imageUrl: '', // Backend doesn't store images; UI falls back to icon
      batteryCapacityKwh: (json['battery_capacity'] as num?)?.toDouble() ?? 0,
      estRangeKm: (json['range_km'] as num?)?.toInt() ?? 0,
      batteryPercent: 80, // Default SOC — user sets actual % on Route screen
      connectorType: json['connector_type'] as String? ?? 'CCS2',
      chargingSpeedKw: (json['charging_speed'] as num?)?.toDouble() ?? 50.0,
    );
  }

  // Legacy fromJson kept for any existing callers
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicleId'] as int? ?? 0,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      variant: json['variant'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      batteryCapacityKwh:
          (json['batteryCapacityKwh'] as num?)?.toDouble() ?? 0,
      estRangeKm: json['estRangeKm'] as int? ?? 0,
      batteryPercent: json['batteryPercent'] as int? ?? 80,
      connectorType: json['connectorType'] as String? ?? 'CCS2',
      chargingSpeedKw: (json['chargingSpeedKw'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'id': id,
        'name': name,
        'variant': variant,
        'imageUrl': imageUrl,
        'batteryCapacityKwh': batteryCapacityKwh,
        'estRangeKm': estRangeKm,
        'batteryPercent': batteryPercent,
        'connectorType': connectorType,
        'chargingSpeedKw': chargingSpeedKw,
      };
}
