import 'vehicle.dart';

/// Wraps an existing [Vehicle] with the extra display fields the "My
/// Vehicle" card on the Profile screen needs (connector type).
///
/// Intentionally a thin wrapper rather than new fields bolted onto
/// [Vehicle] itself, so the existing Vehicles / Route Results screens
/// and their model stay completely untouched.
class ProfileVehicleSummary {
  final Vehicle vehicle;
  final String connectorType;

  const ProfileVehicleSummary({
    required this.vehicle,
    required this.connectorType,
  });
}
