import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/widgets/app_navigation_tile.dart';
import 'package:wildfire_mvp_v3/widgets/section_header.dart';

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

  const SettingsScreen({super.key, this.devOptionsUnlocked = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAdvanced = kDebugMode || devOptionsUnlocked;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            // Notifications section
            const SectionHeader(title: 'Notifications'),
            AppNavigationTile(
              icon: Icons.notifications_outlined,
              title: 'Alert Settings',
              subtitle: 'Coming soon',
              enabled: false,
              onTap: () => context.push('/settings/notifications'),
            ),

            const Divider(),

            // About section (legal documents)
            const SectionHeader(title: 'About'),
            AppNavigationTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'App usage terms and conditions',
              onTap: () => context.push('/settings/about/terms'),
            ),
            AppNavigationTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () => context.push('/settings/about/privacy'),
            ),
            AppNavigationTile(
              icon: Icons.warning_amber_outlined,
              title: 'Emergency Disclaimer',
              subtitle: 'Important safety information',
              onTap: () => context.push('/settings/about/disclaimer'),
            ),
            AppNavigationTile(
              icon: Icons.source_outlined,
              title: 'Data Sources',
              subtitle: 'Data providers and attribution',
              onTap: () => context.push('/settings/about/data-sources'),
            ),

            // Advanced section (gated)
            if (showAdvanced) ...[
              const Divider(),
              SectionHeader(title: 'Advanced', color: theme.colorScheme.error),
              AppNavigationTile(
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
