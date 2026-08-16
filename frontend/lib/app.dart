import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Root widget of the application.
///
/// Wires together:
///  * Material 3 light/dark [ThemeData] (follows the device setting via
///    [ThemeMode.system] — swap for a user-toggle later if desired).
///  * Named-route navigation via [AppRoutes.onGenerateRoute].
class EvRoutePlannerApp extends StatelessWidget {
  const EvRoutePlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
