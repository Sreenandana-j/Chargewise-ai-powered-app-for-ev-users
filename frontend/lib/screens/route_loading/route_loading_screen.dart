import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/vehicle.dart';
import '../route/route_screen.dart';
import '../splash/widgets/ev_car_illustration.dart';
import 'widgets/animated_battery_badge.dart';
import 'widgets/loading_step_row.dart';

/// "Finding the best route for your EV" — a short animated interstitial
/// shown between the Route Planning screen and the Route Results
/// screen while the (simulated) route calculation runs.
///
/// Uses only built-in Flutter animation widgets ([AnimationController] +
/// [Tween]) — no extra animation packages — and reuses the existing
/// [EvCarIllustration] from the splash screen rather than a new asset.
/// Once the progress animation completes, it replaces itself with the
/// existing [AppRoutes.results] route, forwarding along whichever
/// [Vehicle] was passed in.
class RouteLoadingScreen extends StatefulWidget {
  const RouteLoadingScreen({super.key});

  @override
  State<RouteLoadingScreen> createState() => _RouteLoadingScreenState();
}

class _RouteLoadingScreenState extends State<RouteLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const _steps = ['Route', 'Chargers', 'Traffic', 'ETA'];

  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishAndNavigate();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs once the loading animation completes.
  /// Navigates to Route Results, forwarding the [RoutePlanArgs] so
  /// the results screen can call the real `/routes/plan` API.
  Future<void> _finishAndNavigate() async {
    if (_navigated) return;
    _navigated = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    // Support both RoutePlanArgs (new) and legacy Vehicle (old) arguments.
    RoutePlanArgs? planArgs;
    if (args is RoutePlanArgs) {
      planArgs = args;
    } else if (args is Vehicle) {
      planArgs = RoutePlanArgs(
        vehicle: args,
        origin: 'Tiruvalla, Kerala',
        destination: 'Kochi, Kerala',
        batteryPercent: 80.0,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.results,
      arguments: planArgs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EvCarIllustration(width: 200),
                const SizedBox(height: 24),
                const AnimatedBatteryBadge(percent: 100),
                const SizedBox(height: 6),
                Text(
                  'Analyzing charging stops along your route',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Text(
                  'Finding the best route for your EV',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Optimizing for range, charger availability & traffic',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 8,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    // Each step "completes" at its own quarter of the
                    // overall progress animation.
                    final completed = (_progress.value * _steps.length)
                        .floor()
                        .clamp(0, _steps.length)
                        .toInt();
                    return LoadingStepRow(steps: _steps, completedCount: completed);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
