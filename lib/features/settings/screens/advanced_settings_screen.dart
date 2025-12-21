import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/services/onboarding_prefs_impl.dart';

/// Advanced settings screen with developer options.
///
/// Access is gated:
/// - **Debug builds**: Always visible in Settings
/// - **Release builds**: Hidden by default, unlock by tapping version 7 times
///
/// Features:
/// - Reset onboarding (clears preferences, returns to onboarding flow)
/// - Clear location cache (forces fresh GPS lookup)
/// - Future: Feature flag toggles
class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  Future<void> _resetOnboarding(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding?'),
        content: const Text(
          'This will clear your preferences and return you to the '
          'onboarding flow. You\'ll need to accept the terms again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      final service = OnboardingPrefsImpl(prefs);
      await service.resetOnboarding();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Onboarding reset. Redirecting...')),
        );
        context.go('/onboarding');
      }
    }
  }

  Future<void> _clearLocationCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Location Cache?'),
        content: const Text(
          'This will clear your cached location data. '
          'The app will request fresh GPS coordinates on next use.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      // Clear location-related preferences
      await prefs.remove('manual_location_lat');
      await prefs.remove('manual_location_lon');
      await prefs.remove('manual_location_place');

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location cache cleared')));
      }
    }
  }

  Future<void> _clearFireRiskCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Fire Risk Cache?'),
        content: const Text(
          'This will clear cached fire risk data. '
          'Fresh data will be fetched from the API on next request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      // Clear all fire risk cache entries (they start with 'fire_risk_cache_')
      final keys = prefs.getKeys().where(
            (k) => k.startsWith('fire_risk_cache_'),
          );
      for (final key in keys) {
        await prefs.remove(key);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleared ${keys.length} cached entries')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Options')),
      body: SafeArea(
        child: ListView(
          children: [
            // Warning banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These options are for testing and debugging. '
                      'Use with caution.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Data management section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Semantics(
                header: true,
                child: Text(
                  'DATA MANAGEMENT',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            _DevOptionTile(
              icon: Icons.refresh,
              title: 'Reset Onboarding',
              subtitle: 'Clear preferences and restart onboarding flow',
              onTap: () => _resetOnboarding(context),
            ),

            _DevOptionTile(
              icon: Icons.location_off_outlined,
              title: 'Clear Location Cache',
              subtitle: 'Remove cached location data',
              onTap: () => _clearLocationCache(context),
            ),

            _DevOptionTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Clear Fire Risk Cache',
              subtitle: 'Remove cached fire risk data',
              onTap: () => _clearFireRiskCache(context),
            ),

            const Divider(indent: 16, endIndent: 16),

            // Debug info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Semantics(
                header: true,
                child: Text(
                  'DEBUG INFO',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            ListTile(
              leading: Icon(
                Icons.bug_report_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Debug Mode'),
              subtitle: const Text(kDebugMode ? 'Enabled' : 'Disabled'),
              trailing: Icon(
                kDebugMode ? Icons.check_circle : Icons.cancel,
                color: kDebugMode
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),

            ListTile(
              leading: Icon(
                Icons.phone_android_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Platform'),
              subtitle: Text(
                Theme.of(context).platform.toString().split('.').last,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// A list tile for developer options.
class _DevOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DevOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.error),
      title: Text(title, style: TextStyle(color: theme.colorScheme.error)),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
      onTap: onTap,
    );
  }
}
