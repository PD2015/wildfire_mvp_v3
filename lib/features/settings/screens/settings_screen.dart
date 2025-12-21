import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Settings hub screen providing access to app configuration.
///
/// Sections:
/// - Notifications: Alert settings (coming soon)
/// - About: Legal documents (Terms, Privacy, Disclaimer, Data Sources)
/// - Advanced: Developer options (gated, visible in debug or when unlocked)
///
/// Constitutional compliance:
/// - C3: Accessibility with ≥48dp touch targets and semantic labels
/// - C1: Clean architecture with section-based layout
class SettingsScreen extends StatelessWidget {
  /// Whether developer options are unlocked (for release builds)
  final bool devOptionsUnlocked;

  const SettingsScreen({
    super.key,
    this.devOptionsUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAdvanced = kDebugMode || devOptionsUnlocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Notifications section
            const _SectionHeader(title: 'Notifications'),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Alert Settings',
              subtitle: 'Coming soon',
              enabled: false,
              onTap: () => context.push('/settings/notifications'),
            ),

            const Divider(),

            // About section (legal documents)
            const _SectionHeader(title: 'About'),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'App usage terms and conditions',
              onTap: () => context.push('/settings/about/terms'),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () => context.push('/settings/about/privacy'),
            ),
            _SettingsTile(
              icon: Icons.warning_amber_outlined,
              title: 'Emergency Disclaimer',
              subtitle: 'Important safety information',
              onTap: () => context.push('/settings/about/disclaimer'),
            ),
            _SettingsTile(
              icon: Icons.source_outlined,
              title: 'Data Sources',
              subtitle: 'Data providers and attribution',
              onTap: () => context.push('/settings/about/data-sources'),
            ),

            // Advanced section (gated)
            if (showAdvanced) ...[
              const Divider(),
              _SectionHeader(
                title: 'Advanced',
                color: theme.colorScheme.error,
              ),
              _SettingsTile(
                icon: Icons.developer_mode,
                title: 'Developer Options',
                subtitle: 'Debug tools and diagnostics',
                iconColor: theme.colorScheme.error,
                onTap: () => context.push('/settings/advanced'),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Section header for settings groups.
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader({
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(
            color: color ?? theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// A list tile for settings navigation.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = enabled
        ? (iconColor ?? theme.colorScheme.onSurfaceVariant)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return ListTile(
      leading: Icon(
        icon,
        color: effectiveIconColor,
      ),
      title: Text(
        title,
        style: enabled
            ? null
            : TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: enabled
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: enabled
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
