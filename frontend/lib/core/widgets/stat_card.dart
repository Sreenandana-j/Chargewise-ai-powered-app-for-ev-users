import 'package:flutter/material.dart';

/// A compact card showing one icon + big value + small label — used for
/// the Distance / Travel Time / Battery on Arrival / Arrival Time grid
/// on the Route Results screen. Generic enough to reuse anywhere a
/// single stat needs a highlighted card.
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 10),
            Text(value, style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
