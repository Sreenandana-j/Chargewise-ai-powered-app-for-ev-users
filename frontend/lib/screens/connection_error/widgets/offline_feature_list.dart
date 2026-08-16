import 'package:flutter/material.dart';

/// "Available offline" checklist card shown on the Connection Error
/// screen, listing app features that still work without a network
/// connection (saved routes, downloaded maps, vehicle settings).
class OfflineFeatureList extends StatelessWidget {
  final List<String> features;

  const OfflineFeatureList({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available offline:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final feature in features)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(feature, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
