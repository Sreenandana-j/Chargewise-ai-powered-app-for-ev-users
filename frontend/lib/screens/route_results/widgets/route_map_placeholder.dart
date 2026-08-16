import 'package:flutter/material.dart';

/// Stylized, non-interactive stand-in for a real map/route preview.
///
/// A live map integration (Google Maps / Mapbox) can replace this
/// widget later without touching the rest of the Route Results screen —
/// it only needs [totalDistanceKm] and [hasChargingStop] today.
class RouteMapPlaceholder extends StatelessWidget {
  final double totalDistanceKm;
  final bool hasChargingStop;

  const RouteMapPlaceholder({
    super.key,
    required this.totalDistanceKm,
    required this.hasChargingStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Terrain-like gradient backdrop stands in for real map tiles.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF223326), const Color(0xFF16241A)]
                      : [const Color(0xFFE9EFE2), const Color(0xFFD8E6D5)],
                ),
              ),
            ),
            // Distance badge, top-right — mirrors the Figma design.
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  '${totalDistanceKm.toStringAsFixed(0)} km',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            // Route line with origin / charging-stop / destination markers.
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Row(
                children: [
                  _Marker(color: theme.colorScheme.primary),
                  Expanded(child: _RouteLine(color: theme.colorScheme.primary)),
                  if (hasChargingStop) ...[
                    const _Marker(color: Color(0xFFF9A825), icon: Icons.bolt_rounded),
                    Expanded(child: _RouteLine(color: theme.colorScheme.primary)),
                  ],
                  Icon(Icons.flag_rounded, color: theme.colorScheme.primary, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final Color color;
  final IconData? icon;

  const _Marker({required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: icon != null ? Icon(icon, size: 10, color: Colors.white) : null,
    );
  }
}

class _RouteLine extends StatelessWidget {
  final Color color;

  const _RouteLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: 3, color: color.withValues(alpha: 0.5));
  }
}
