import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Outlined "Continue with Google" button used on both the Login and
/// Sign-up screens.
///
/// The four-color "G" mark is drawn from plain [Text] glyphs rather
/// than a bundled brand asset — swap in the official Google logo SVG
/// (via `flutter_svg` + Google's brand asset) before shipping to
/// production, since using it verbatim here would require Google's
/// asset file rather than a redrawn approximation.
class SocialLoginButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = isLoading || onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GoogleMark(),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Minimal redrawn approximation of Google's "G" mark using plain text
/// glyphs in the brand colors, avoiding bundling the real logo asset.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4), // Google blue
      ),
    );
  }
}

/// Small helper the Auth screens use to draw the "or continue with"
/// divider between the form and the social sign-in button.
class OrDivider extends StatelessWidget {
  final String label;

  const OrDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textFaint),
          ),
        ),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
    );
  }
}
