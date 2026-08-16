import 'package:flutter/material.dart';

/// A small text-only outlined pill, used for compact metadata tags such
/// as connector types ("CCS2", "Type 2") on station cards.
///
/// Distinct from [FeatureChip] (which always shows an icon and is used
/// for feature callouts) — this is a lighter-weight tag for short
/// labels in dense lists.
class TagPill extends StatelessWidget {
  final String label;

  const TagPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
