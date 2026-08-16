import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Interactive OpenStreetMap map widget that renders the route polyline
/// returned by the backend `/routes/plan` endpoint.
///
/// Features:
/// - OSM tile layer (no API key needed)
/// - Green route polyline
/// - Start marker (green) and End marker (red)
/// - Yellow bolt marker for charging stops (if any)
/// - Automatically fits the map bounds to the full route
class RouteMapView extends StatefulWidget {
  /// List of [lat, lon] pairs from backend `route_points`.
  final List<List<double>> routePolyline;
  final double totalDistanceKm;
  final bool hasChargingStop;

  const RouteMapView({
    super.key,
    required this.routePolyline,
    required this.totalDistanceKm,
    required this.hasChargingStop,
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<LatLng> get _latLngs => widget.routePolyline
      .map((pt) => LatLng(pt[0], pt[1]))
      .toList();

  /// Compute the centre of all route points.
  LatLng get _centre {
    if (_latLngs.isEmpty) return const LatLng(9.9312, 76.2673); // Kochi fallback
    final latSum = _latLngs.fold(0.0, (acc, pt) => acc + pt.latitude);
    final lonSum = _latLngs.fold(0.0, (acc, pt) => acc + pt.longitude);
    return LatLng(latSum / _latLngs.length, lonSum / _latLngs.length);
  }

  /// Approximate zoom level based on route length.
  double get _initialZoom {
    if (widget.totalDistanceKm < 20) return 12.0;
    if (widget.totalDistanceKm < 60) return 10.0;
    if (widget.totalDistanceKm < 150) return 9.0;
    return 8.0;
  }

  /// Charging stop approximated at 60% along the route.
  LatLng? get _chargingStopLatLng {
    if (!widget.hasChargingStop || _latLngs.isEmpty) return null;
    final idx = (_latLngs.length * 0.6).round().clamp(0, _latLngs.length - 1);
    return _latLngs[idx];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = _latLngs;

    if (points.isEmpty) {
      return _Placeholder(
        totalDistanceKm: widget.totalDistanceKm,
        hasChargingStop: widget.hasChargingStop,
      );
    }

    final start = points.first;
    final end = points.last;
    final chargingPt = _chargingStopLatLng;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centre,
            initialZoom: _initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            // ── OSM Tile Layer ────────────────────────────────────────
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ev.route_planner',
              maxZoom: 18,
            ),

            // ── Route Polyline ────────────────────────────────────────
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 4.0,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),

            // ── Markers ───────────────────────────────────────────────
            MarkerLayer(
              markers: [
                // Start
                Marker(
                  point: start,
                  width: 36,
                  height: 36,
                  child: _MapPin(
                    icon: Icons.trip_origin_rounded,
                    color: const Color(0xFF43A047),
                  ),
                ),
                // End
                Marker(
                  point: end,
                  width: 36,
                  height: 36,
                  child: _MapPin(
                    icon: Icons.location_on_rounded,
                    color: const Color(0xFFE53935),
                  ),
                ),
                // Charging stop
                if (chargingPt != null)
                  Marker(
                    point: chargingPt,
                    width: 36,
                    height: 36,
                    child: _MapPin(
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFFFA726),
                    ),
                  ),
              ],
            ),

            // ── Distance label overlay ────────────────────────────────
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.totalDistanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round icon pin used as a map marker.
class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapPin({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

/// Fallback widget if polyline is empty (same style as RouteMapPlaceholder).
class _Placeholder extends StatelessWidget {
  final double totalDistanceKm;
  final bool hasChargingStop;

  const _Placeholder({
    required this.totalDistanceKm,
    required this.hasChargingStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined,
                size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              '${totalDistanceKm.toStringAsFixed(1)} km route',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
