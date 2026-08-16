import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

/// The four top-level sections reachable from the bottom navigation
/// bar, in on-screen order.
enum AppTab { vehicles, route, results, stations }

/// Reusable bottom navigation bar for the route-planning flow
/// (Vehicles → Route → Results → Stations).
///
/// Each screen passes its own [currentTab] so the matching icon/label
/// is highlighted automatically. Tapping a different tab swaps to that
/// screen via a named route; tapping the already-active tab is a no-op.
class AppBottomNav extends StatelessWidget {
  final AppTab currentTab;

  const AppBottomNav({super.key, required this.currentTab});

  static const _items = [
    (tab: AppTab.vehicles, label: 'Vehicles', icon: Icons.directions_car_filled_rounded),
    (tab: AppTab.route, label: 'Route', icon: Icons.near_me_rounded),
    (tab: AppTab.results, label: 'Results', icon: Icons.alt_route_rounded),
    (tab: AppTab.stations, label: 'Stations', icon: Icons.bolt_rounded),
  ];

  String _routeFor(AppTab tab) {
    switch (tab) {
      case AppTab.vehicles:
        return AppRoutes.vehicles;
      case AppTab.route:
        return AppRoutes.route;
      case AppTab.results:
        return AppRoutes.results;
      case AppTab.stations:
        return AppRoutes.stations;
    }
  }

  void _onTap(BuildContext context, AppTab tab) {
    if (tab == currentTab) return;
    Navigator.of(context).pushNamed(_routeFor(tab));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = AppTab.values.indexOf(currentTab);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.scaffoldBackgroundColor,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.textTheme.bodyMedium?.color,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      showUnselectedLabels: true,
      elevation: 8,
      onTap: (index) => _onTap(context, _items[index].tab),
      items: [
        for (final item in _items)
          BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          ),
      ],
    );
  }
}
