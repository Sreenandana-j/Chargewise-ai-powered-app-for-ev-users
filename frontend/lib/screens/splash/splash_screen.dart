import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/circular_percent_indicator.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/feature_chip.dart';
import '../../core/widgets/loading_dots_indicator.dart';
import '../../data/services/dummy_data_service.dart';
import '../../data/services/session_service.dart';
import 'widgets/ev_car_illustration.dart';
import 'widgets/splash_blob_background.dart';

/// The app's entry screen.
///
/// Responsibilities:
///  * Plays a short branded intro animation (logo fade/scale in).
///  * Kicks off app initialization via [DummyDataService.initializeApp]
///    and reflects real progress in the UI (dots label + progress bar +
///    circular percentage badge).
///  * Shows an [ErrorView] with retry if initialization fails.
///  * Checks JWT session: navigates to [AppRoutes.home] if already
///    logged in, or [AppRoutes.login] for first-time / signed-out users.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final DummyDataService _dataService = DummyDataService();

  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: AppConstants.fadeInDuration,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _startInitialization();
  }

  /// Subscribes to the initialization progress stream and reacts to
  /// completion / failure. Extracted so [_retry] can call it again.
  void _startInitialization({bool simulateError = false}) {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _progress = 0.0;
    });

    _dataService.initializeApp(simulateError: simulateError).listen(
      (value) {
        if (!mounted) return;
        setState(() => _progress = value);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
      },
      onDone: () async {
        if (!mounted || _hasError) return;
        // Small pause so the user actually perceives the "100%" moment
        // before we navigate away.
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        // Auth guard: if a valid JWT exists, skip login and go straight home.
        final isLoggedIn = await SessionService.instance.isLoggedIn();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          isLoggedIn ? AppRoutes.home : AppRoutes.login,
        );
      },
    );
  }

  void _retry() => _startInitialization();

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    // Responsive scale: shrink the illustration on very small/narrow
    // devices, cap growth on tablets so the layout doesn't look sparse.
    final isTablet = size.width >= AppConstants.mobileMaxWidth;
    final carWidth = isTablet ? 260.0 : (size.width * 0.5).clamp(160.0, 240.0);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ---- Top blob + car illustration ----
                      SizedBox(
                        height: size.height * 0.34,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            SplashBlobBackground(height: size.height * 0.30),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: EvCarIllustration(width: carWidth),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ---- App icon badge ----
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.alt_route_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ---- Title ----
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 56,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ---- Tagline ----
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          AppConstants.tagline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---- Feature chips ----
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FeatureChip(
                            icon: Icons.bolt_rounded,
                            iconColor: AppColors.chipYellow,
                            label: 'Fast Charging',
                          ),
                          FeatureChip(
                            icon: Icons.map_rounded,
                            iconColor: AppColors.chipBlue,
                            label: 'Smart Routes',
                          ),
                          FeatureChip(
                            icon: Icons.eco_rounded,
                            iconColor: AppColors.chipLeaf,
                            label: 'Eco Score',
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ---- Loading / progress / error area ----
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _hasError
                            ? ErrorView(
                                message: _errorMessage ??
                                    'Something went wrong while starting the app.',
                                onRetry: _retry,
                              )
                            : Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const LoadingDotsIndicator(
                                        label: '${AppConstants.initializingLabel}...',
                                      ),
                                      const SizedBox(width: 14),
                                      CircularPercentIndicator(progress: _progress),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: _progress,
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    AppConstants.poweredBy,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 20),

                      // ---- Home-indicator style bar, echoing the mock ----
                      Container(
                        width: 120,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
