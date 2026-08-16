import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/vehicles/vehicles_screen.dart';
import '../../screens/route/route_screen.dart';
import '../../screens/route_results/route_results_screen.dart';
import '../../screens/stations/stations_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/route_loading/route_loading_screen.dart';
import '../../screens/connection_error/connection_error_screen.dart';

/// Route name constants — use these instead of raw strings everywhere
/// so typos become compile-time errors caught by the IDE.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';

  // ---- Route-planning flow (Vehicles → Route → Results → Stations) ----
  static const String vehicles = '/vehicles';
  static const String route = '/route';
  static const String results = '/results';
  static const String stations = '/stations';

  // ---- New screens ----
  static const String profile = '/profile';
  static const String routeLoading = '/route-loading';
  static const String connectionError = '/connection-error';

  /// Central place that maps a route name to the screen widget.
  /// Wired into [MaterialApp.onGenerateRoute] in app.dart.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case signup:
        return _buildRoute(const SignupScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case vehicles:
        return _buildRoute(const VehiclesScreen(), settings);
      case route:
        return _buildRoute(const RouteScreen(), settings);
      case results:
        return _buildRoute(const RouteResultsScreen(), settings);
      case stations:
        return _buildRoute(const StationsScreen(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case routeLoading:
        return _buildRoute(const RouteLoadingScreen(), settings);
      case connectionError:
        return _buildRoute(const ConnectionErrorScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for "${settings.name}"'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRoute _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: settings,
    );
  }
}
