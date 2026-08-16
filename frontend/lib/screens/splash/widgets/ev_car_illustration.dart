import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A lightweight, hand-built approximation of the EV car graphic from
/// the Figma splash screen, composed from Containers/Icons rather than
/// a raster asset.
///
/// In production, swap this for the real exported SVG (e.g. via
/// `flutter_svg`) by dropping the asset into `assets/images/` and
/// replacing the body of `build()` — the outer [SizedBox] contract
/// stays the same so no caller code needs to change.
class EvCarIllustration extends StatelessWidget {
  final double width;

  const EvCarIllustration({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? AppColors.accentGreen : AppColors.primaryGreen;
    final roofColor = isDark ? AppColors.primaryGreenDark : AppColors.accentGreen;

    return SizedBox(
      width: width,
      height: width * 0.62,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Ground shadow
          Positioned(
            bottom: 0,
            child: Container(
              width: width * 0.8,
              height: width * 0.05,
              decoration: BoxDecoration(
                color: AppColors.paleGreenBlob.withValues(alpha: isDark ? 0.15 : 0.6),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          // Car body
          Positioned(
            bottom: width * 0.12,
            child: Container(
              width: width * 0.72,
              height: width * 0.28,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(width * 0.08),
              ),
            ),
          ),

          // Roof / cabin
          Positioned(
            bottom: width * 0.30,
            child: Container(
              width: width * 0.4,
              height: width * 0.18,
              decoration: BoxDecoration(
                color: roofColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(width * 0.2),
                  topRight: Radius.circular(width * 0.2),
                ),
              ),
            ),
          ),

          // Left wheel
          Positioned(
            bottom: width * 0.04,
            left: width * 0.14,
            child: _Wheel(size: width * 0.16),
          ),

          // Right wheel
          Positioned(
            bottom: width * 0.04,
            right: width * 0.14,
            child: _Wheel(size: width * 0.16),
          ),

          // Charging plug badge (top-right)
          Positioned(
            top: 0,
            right: width * 0.12,
            child: Container(
              width: width * 0.16,
              height: width * 0.22,
              padding: EdgeInsets.all(width * 0.02),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(width * 0.03),
                border: Border.all(color: bodyColor, width: 1.4),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: AppColors.chipYellow,
                size: width * 0.12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  final double size;
  const _Wheel({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryGreenDark,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.15),
      ),
    );
  }
}
