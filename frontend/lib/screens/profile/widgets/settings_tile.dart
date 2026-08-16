import 'package:flutter/material.dart';

/// A settings row with a toggle switch on the trailing edge — used for
/// "Push Notifications" / "Dark Mode" in the Profile screen's App
/// Settings section.
class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// A tappable settings row with a trailing chevron — used for
/// navigational entries like "Language & Region" or "Help & Support"
/// that would push a deeper settings screen in a full implementation.
class SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: theme.textTheme.bodyLarge),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.disabledColor),
          ],
        ),
      ),
    );
  }
}
