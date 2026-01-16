import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/features/settings/services/settings_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// About screen within Help hub showing app information.
///
/// Displays:
/// - App icon and name
/// - Version number (tappable to unlock dev options in release builds)
/// - Quick links to key sections
class AboutHelpScreen extends StatefulWidget {
  const AboutHelpScreen({super.key});

  @override
  State<AboutHelpScreen> createState() => _AboutHelpScreenState();
}

class _AboutHelpScreenState extends State<AboutHelpScreen> {
  int _versionTapCount = 0;
  static const int _tapsToUnlock = 7;

  Future<void> _onVersionTap() async {
    setState(() => _versionTapCount++);

    if (_versionTapCount >= _tapsToUnlock) {
      _versionTapCount = 0;
      final prefs = await SharedPreferences.getInstance();
      final settingsPrefs = SettingsPrefs(prefs);
      await settingsPrefs.unlockDevOptions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Developer options unlocked!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (_versionTapCount >= 4) {
      // Give feedback when close
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_tapsToUnlock - _versionTapCount} more taps...'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About WildFire')),
      body: SafeArea(
        child: ListView(
          children: [
            // App info header
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // App icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 56,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'WildFire',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scottish Wildfire Awareness',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Version - tappable to unlock dev options
                  GestureDetector(
                    onTap: _onVersionTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Purpose section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PURPOSE',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'WildFire is a public awareness tool that helps people understand wildfire risk in Scotland. '
                    'It visualises publicly available fire danger data and satellite-detected hotspots.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),

            // Important note
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This app is for awareness only. In an emergency, always call 999.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick links section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'QUICK LINKS',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            _QuickLinkTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => context.push('/settings/about/terms'),
            ),

            _QuickLinkTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push('/settings/about/privacy'),
            ),

            _QuickLinkTile(
              icon: Icons.source_outlined,
              title: 'Data Sources',
              onTap: () => context.push('/settings/about/data-sources'),
            ),

            const SizedBox(height: 24),

            // Acknowledgments section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACKNOWLEDGMENTS',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fire Weather Index data: European Forest Fire Information System (EFFIS)\n\n'
                    'Satellite hotspot detection: NASA FIRMS\n\n'
                    'Map data: OpenStreetMap contributors\n\n'
                    'Built with Flutter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '© 2025 WildFire\nDecember 2025',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
