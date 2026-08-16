import 'package:flutter/material.dart';

/// The "I agree to the Terms of Service and Privacy Policy" checkbox
/// row on the Sign-up screen. The two links are tappable text spans;
/// wire [onTermsTap] / [onPrivacyTap] to real screens/URLs later.
class TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.onTermsTap,
    this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('I agree to the ', style: theme.textTheme.bodyMedium),
              GestureDetector(
                onTap: onTermsTap,
                child: Text('Terms of Service', style: linkStyle),
              ),
              Text(' and ', style: theme.textTheme.bodyMedium),
              GestureDetector(
                onTap: onPrivacyTap,
                child: Text('Privacy Policy', style: linkStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
