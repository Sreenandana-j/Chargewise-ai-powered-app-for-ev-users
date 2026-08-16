/// A single recommended charging stop along a calculated route.
class ChargingStop {
  final String stationName;
  final int atDistanceKm; // distance from origin where the stop sits
  final int chargeTimeMinutes;
  final double estimatedCost;
  final int speedKw;

  const ChargingStop({
    required this.stationName,
    required this.atDistanceKm,
    required this.chargeTimeMinutes,
    required this.estimatedCost,
    required this.speedKw,
  });

  /// Map from a charging_stops_suggested entry returned by the backend.
  factory ChargingStop.fromBackendJson(Map<String, dynamic> json,
      {required double distanceKm}) {
    return ChargingStop(
      stationName: json['name'] as String? ?? 'Charging Station',
      atDistanceKm: distanceKm.round(),
      chargeTimeMinutes: 25, // estimated; backend doesn't give exact minutes here
      estimatedCost: (json['power_kw'] as num? ?? 50) * 0.25 * 0.5, // rough estimate
      speedKw: (json['power_kw'] as num? ?? 50).toInt(),
    );
  }
}

/// Energy consumed/added across a route, used to render the \"Energy
/// Breakdown\" bars on the Route Results screen.
class EnergyBreakdown {
  final double drivingKwh;
  final double climateControlKwh;
  final double chargingAddedKwh;

  const EnergyBreakdown({
    required this.drivingKwh,
    required this.climateControlKwh,
    required this.chargingAddedKwh,
  });

  /// Used to size the relative bar widths in the UI.
  double get maxKwh {
    final values = [drivingKwh, climateControlKwh, chargingAddedKwh];
    return values.reduce((a, b) => a > b ? a : b);
  }
}

/// A single [latitude, longitude] coordinate on the route polyline.
typedef RoutePoint = List<double>;

/// The full result of an eco-route calculation — everything the
/// Route Results screen needs in one payload.
///
/// Can be constructed from the FastAPI `RoutePlanResponse` via
/// [RouteResult.fromBackendJson].
class RouteResult {
  final String routeType; // e.g. "Eco Route"
  final String vehicleName;
  final double totalDistanceKm;
  final Duration travelTime;
  final int batteryOnArrivalPercent;
  final DateTime arrivalTime;
  final ChargingStop? chargingStop;
  final EnergyBreakdown energyBreakdown;

  /// Decoded route geometry from the backend — list of [lat, lon] pairs.
  /// Used to draw the polyline on the interactive map.
  final List<RoutePoint> routePolyline;

  /// Whether this result came from the live backend.
  final bool isFromBackend;

  const RouteResult({
    required this.routeType,
    required this.vehicleName,
    required this.totalDistanceKm,
    required this.travelTime,
    required this.batteryOnArrivalPercent,
    required this.arrivalTime,
    required this.energyBreakdown,
    this.chargingStop,
    this.routePolyline = const [],
    this.isFromBackend = false,
  });

  /// Build a [RouteResult] from the FastAPI `RoutePlanResponse` JSON.
  ///
  /// Backend payload shape:
  /// ```json
  /// {
  ///   "distance_km": 95.2,
  ///   "duration_mins": 110.5,
  ///   "route_points": [[lat, lon], ...],
  ///   "battery_prediction": {
  ///     "vehicle_name": "Tata Nexon EV",
  ///     "battery_after": 42.0,
  ///     "energy_used_kwh": 14.6,
  ///     "is_trip_feasible": true,
  ///     "recommendation": "..."
  ///   },
  ///   "charging_stops_suggested": [...]
  /// }
  /// ```
  factory RouteResult.fromBackendJson(Map<String, dynamic> json) {
    final pred = json['battery_prediction'] as Map<String, dynamic>? ?? {};
    final distanceKm = (json['distance_km'] as num?)?.toDouble() ?? 0.0;
    final durationMins = (json['duration_mins'] as num?)?.toDouble() ?? 0.0;
    final batteryAfter =
        (pred['battery_after'] as num?)?.toInt().clamp(0, 100) ?? 0;
    final energyUsed = (pred['energy_used_kwh'] as num?)?.toDouble() ?? 0.0;
    final vehicleName = pred['vehicle_name'] as String? ?? 'Your EV';

    // Parse route polyline [[lat, lon], ...]
    final rawPoints = json['route_points'] as List<dynamic>? ?? [];
    final polyline = rawPoints
        .map((p) {
          final pair = p as List<dynamic>;
          return [
            (pair[0] as num).toDouble(),
            (pair[1] as num).toDouble(),
          ];
        })
        .toList();

    // Charging stop (if any)
    ChargingStop? chargingStop;
    final stops = json['charging_stops_suggested'] as List<dynamic>? ?? [];
    if (stops.isNotEmpty) {
      chargingStop = ChargingStop.fromBackendJson(
        stops.first as Map<String, dynamic>,
        distanceKm: distanceKm * 0.6, // suggest stop at ~60% of route
      );
    }

    final now = DateTime.now();

    return RouteResult(
      routeType: 'Eco Route',
      vehicleName: vehicleName,
      totalDistanceKm: distanceKm,
      travelTime: Duration(minutes: durationMins.round()),
      batteryOnArrivalPercent: batteryAfter,
      arrivalTime: now.add(Duration(minutes: durationMins.round())),
      chargingStop: chargingStop,
      energyBreakdown: EnergyBreakdown(
        drivingKwh: energyUsed,
        climateControlKwh: energyUsed * 0.12, // ~12% of consumption estimate
        chargingAddedKwh: chargingStop != null ? energyUsed * 0.7 : 0.0,
      ),
      routePolyline: polyline,
      isFromBackend: true,
    );
  }
}
