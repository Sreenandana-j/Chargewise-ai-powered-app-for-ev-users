import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Paints the soft rounded-blob shape that sits behind the car
/// illustration at the top of the splash screen, plus the small
/// scattered dots and the leaf accent seen in the Figma design.
class SplashBlobBackground extends StatelessWidget {
  final double height;

  const SplashBlobBackground({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipPath(
      clipper: _BlobClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        color: isDark ? AppColors.darkBlob : AppColors.paleGreenBlob,
        child: Stack(
          children: [
            // Leaf accent, top-right
            Positioned(
              top: height * 0.14,
              right: 24,
              child: Opacity(
                opacity: isDark ? 0.25 : 0.5,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Icon(
                    Icons.eco_rounded,
                    size: 46,
                    color: isDark ? AppColors.accentGreen : AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
            // Scattered dots
            Positioned(
              top: height * 0.42,
              left: 0,
              right: 0,
              child: _DotRow(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  final bool isDark;
  const _DotRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = (isDark ? AppColors.accentGreen : AppColors.primaryGreen)
        .withValues(alpha: 0.35);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final sizes = [4.0, 6.0, 8.0, 6.0, 4.0];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: sizes[i],
            height: sizes[i],
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      }),
    );
  }
}

/// Clips a rectangle into a shape with a smooth concave curve at the
/// bottom, giving the "blob" silhouette from the design.
class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.15,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
