import 'package:flutter/material.dart';
import '../../../data/models/saved_route.dart';

/// A single row in the Profile screen's "Saved Routes" list:
/// origin → destination, distance + ETA, and a trailing chevron.
class SavedRouteTile extends StatelessWidget {
  final SavedRoute route;
  final VoidCallback? onTap;

  const SavedRouteTile({super.key, required this.route, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceLabel = route.distanceMiles % 1 == 0
        ? route.distanceMiles.toStringAsFixed(0)
        : route.distanceMiles.toStringAsFixed(1);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.near_me_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${route.origin} → ${route.destination}',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$distanceLabel mi · ${route.etaMinutes} min',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.disabledColor),
          ],
        ),
      ),
    );
  }
}
