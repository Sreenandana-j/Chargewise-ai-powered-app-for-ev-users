import 'package:flutter/material.dart';
import '../../../data/models/user_profile.dart';

/// Top banner of the Profile screen: circular avatar, name, email, a
/// "Premium Member" badge (only when applicable), and an edit-profile
/// icon in the corner.
///
/// Uses the app's primary green as a soft gradient backdrop, echoing
/// the rounded-card language already used across the app's [Card]s.
class ProfileHeaderCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [theme.colorScheme.primary.withValues(alpha: 0.35), theme.colorScheme.surface]
              : [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.network(
                        profile.avatarUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                profile.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              if (profile.isPremiumMember) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Premium Member',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.white.withValues(alpha: 0.2),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Edit profile',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
