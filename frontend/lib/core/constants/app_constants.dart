/// App-wide constant values: copy strings, durations, and responsive
/// breakpoints. Centralizing these avoids "magic numbers/strings"
/// scattered across screens.
class AppConstants {
  AppConstants._();

  // ---- Copy ----
  static const String appName = 'EV Route Planner';
  static const String tagline = 'Smart Routes. Happy Rides. Greener Tomorrow.';
  static const String poweredBy = 'Powered by clean energy routing';
  static const String initializingLabel = 'Initializing';

  // ---- Timing ----
  static const Duration splashMinDuration = Duration(milliseconds: 2400);
  static const Duration fadeInDuration = Duration(milliseconds: 700);
  static const Duration progressStep = Duration(milliseconds: 60);

  // ---- Responsive breakpoints ----
  static const double mobileMaxWidth = 480;
  static const double tabletMaxWidth = 900;
}
