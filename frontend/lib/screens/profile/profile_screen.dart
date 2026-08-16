import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/profile_vehicle_summary.dart';
import '../../data/models/saved_route.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/profile_api_service.dart';
import '../../data/services/profile_data_service.dart';
import '../../data/services/session_service.dart';
import 'widgets/my_vehicle_card.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/saved_route_tile.dart';
import 'widgets/settings_tile.dart';

/// "Profile" screen — account overview reached from the Home screen's
/// profile icon. Shows the user's identity/membership, lifetime stats,
/// active vehicle, saved routes, app settings, support links, and a
/// logout action.
///
/// Follows the same loading → data / error [_ViewState] pattern used
/// across the rest of the app (Home, Vehicles, Route Results, Stations)
/// for a consistent feel.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ViewState { loading, data, error }

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileApiService _apiService = ProfileApiService();
  final ProfileDataService _dataService = ProfileDataService();

  _ViewState _state = _ViewState.loading;
  UserProfile? _profile;
  ProfileVehicleSummary? _vehicleSummary;
  List<SavedRoute> _savedRoutes = [];
  String? _errorMessage;

  // Local-only UI state for the two settings switches — a real
  // implementation would persist these via a settings/prefs service.
  bool _pushNotificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _state = _ViewState.loading);
    try {
      // Identity comes from the real backend when available, falling
      // back to dummy data if the backend is unreachable. The backend
      // has no "active vehicle" or "saved routes" concept yet, so
      // those two continue to come from the dummy service.
      UserProfile profile;
      try {
        profile = await _apiService.fetchProfile();
      } catch (_) {
        profile = await _dataService.fetchProfile();
      }
      final results = await Future.wait([
        _dataService.fetchActiveVehicle(),
        _dataService.fetchSavedRoutes(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _vehicleSummary = results[0] as ProfileVehicleSummary;
        _savedRoutes = results[1] as List<SavedRoute>;
        _state = _ViewState.data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _state = _ViewState.error;
      });
    }
  }

  void _changeVehicle() {
    // Reuses the existing Vehicles screen — no new picker needed.
    Navigator.of(context).pushNamed(AppRoutes.vehicles);
  }

  void _viewAllRoutes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full route history coming soon')),
    );
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Clear JWT so splash goes to login next time.
              await SessionService.instance.clearSession();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.loading:
        return const Center(child: CircularProgressIndicator());

      case _ViewState.error:
        return ErrorView(
          message: _errorMessage ?? 'Unable to load your profile.',
          onRetry: _loadProfile,
        );

      case _ViewState.data:
        final theme = Theme.of(context);
        final profile = _profile!;

        return RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              ProfileHeaderCard(
                profile: profile,
                onEdit: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile coming soon')),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.alt_route_rounded,
                      iconColor: theme.colorScheme.primary,
                      value: '${profile.totalRoutes}',
                      label: 'Routes',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.map_rounded,
                      iconColor: theme.colorScheme.primary,
                      value: '${profile.totalMiles}',
                      label: 'Miles',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.bookmark_rounded,
                      iconColor: theme.colorScheme.primary,
                      value: '${profile.totalSaved}',
                      label: 'Saved',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_vehicleSummary != null)
                MyVehicleCard(
                  summary: _vehicleSummary!,
                  onChangeVehicle: _changeVehicle,
                ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Saved Routes',
                child: Column(
                  children: [
                    for (final route in _savedRoutes) ...[
                      SavedRouteTile(route: route),
                      if (route != _savedRoutes.last) const Divider(height: 1),
                    ],
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _viewAllRoutes,
                        child: const Text('View All Routes'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'App Settings',
                child: Column(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_rounded,
                      label: 'Push Notifications',
                      value: _pushNotificationsEnabled,
                      onChanged: (v) => setState(() => _pushNotificationsEnabled = v),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark Mode',
                      value: _darkModeEnabled,
                      onChanged: (v) {
                        setState(() => _darkModeEnabled = v);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dark mode currently follows your system setting'),
                          ),
                        );
                      },
                    ),
                    SettingsNavTile(
                      icon: Icons.language_rounded,
                      label: 'Language & Region',
                      onTap: () => _showComingSoon('Language & Region'),
                    ),
                    SettingsNavTile(
                      icon: Icons.home_rounded,
                      label: 'Default Home Location',
                      onTap: () => _showComingSoon('Default Home Location'),
                    ),
                    SettingsNavTile(
                      icon: Icons.privacy_tip_rounded,
                      label: 'Privacy & Data',
                      onTap: () => _showComingSoon('Privacy & Data'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Support',
                child: Column(
                  children: [
                    SettingsNavTile(
                      icon: Icons.help_rounded,
                      label: 'Help & Support',
                      onTap: () => _showComingSoon('Help & Support'),
                    ),
                    SettingsNavTile(
                      icon: Icons.info_rounded,
                      label: 'About EV Route Planner',
                      onTap: () => _showComingSoon('About EV Route Planner'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }
}

/// Shared rounded-card wrapper with a titled header, used for the
/// Saved Routes / App Settings / Support sections so they read as one
/// consistent visual language.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
