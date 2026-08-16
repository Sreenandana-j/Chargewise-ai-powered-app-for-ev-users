import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/vehicle.dart';
import 'widgets/offline_feature_list.dart';

/// "No Internet Connection" screen — a dedicated full-screen state
/// (distinct from the inline [ErrorView] used for individual failed
/// requests) meant to be pushed whenever a network/API call fails
/// outright, e.g. `Navigator.pushNamed(AppRoutes.connectionError)`.
///
/// Offers quick diagnostic actions, a primary retry action that
/// attempts to pop back to the previous screen once connectivity looks
/// restored, and a "Go Offline" path into the app's locally-available
/// features.
class ConnectionErrorScreen extends StatefulWidget {
  const ConnectionErrorScreen({super.key});

  @override
  State<ConnectionErrorScreen> createState() => _ConnectionErrorScreenState();
}

class _ConnectionErrorScreenState extends State<ConnectionErrorScreen> {
  bool _retrying = false;

  Future<void> _retryConnection() async {
    setState(() => _retrying = true);

    // Simulates a real connectivity check. Swap this for an actual
    // reachability probe (e.g. via `connectivity_plus` or a lightweight
    // HTTP HEAD request) once a real network layer exists.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() => _retrying = false);

    // Reached from the route-generation flow (Route Loading passes the
    // in-flight Vehicle along on failure) — retry by re-running Route
    // Loading for that same vehicle rather than just popping back.
    final vehicle = ModalRoute.of(context)?.settings.arguments as Vehicle?;
    if (vehicle != null) {
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.routeLoading, arguments: vehicle);
      return;
    }

    if (Navigator.of(context).canPop()) {
      // Connectivity restored — return to whatever screen hit the error.
      Navigator.of(context).pop();
    } else {
      // Nothing to pop back to (e.g. reached as the very first screen)
      // — fall back to the app's home dashboard.
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  void _goOffline() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You're browsing offline — showing locally saved data")),
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  void _placeholderAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 40,
                      color: theme.disabledColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9A825),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.priority_high_rounded, size: 14, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'No Internet Connection',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "We couldn't connect to our servers. Please check your "
                'Wi-Fi or mobile data and try again.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _placeholderAction('Check Wi-Fi'),
                      child: const FittedBox(child: Text('Check Wi-Fi')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _placeholderAction('Check Data'),
                      child: const FittedBox(child: Text('Check Data')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _placeholderAction('Restart App'),
                      child: const FittedBox(child: Text('Restart App')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _retrying ? null : _retryConnection,
                  icon: _retrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_retrying ? 'Retrying…' : 'Retry Connection'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _goOffline,
                  icon: const Icon(Icons.wifi_rounded),
                  label: const Text('Go Offline'),
                ),
              ),
              const SizedBox(height: 24),
              const OfflineFeatureList(
                features: [
                  'Saved routes & destinations',
                  'Downloaded maps',
                  'Vehicle settings',
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Error code: NET_ERR_CONNECTION_REFUSED',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
