import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// About section within Settings showing legal and policy documents.
///
/// This provides a dedicated screen for legal documents, though they
/// are also accessible directly from the main Settings hub.
class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Legal documents section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  'LEGAL DOCUMENTS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            _LegalTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'App usage terms and conditions',
              onTap: () => context.push('/settings/about/terms'),
            ),

            _LegalTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we collect and use your data',
              onTap: () => context.push('/settings/about/privacy'),
            ),

            _LegalTile(
              icon: Icons.warning_amber_outlined,
              title: 'Emergency Disclaimer',
              subtitle: 'Important safety information and limitations',
              onTap: () => context.push('/settings/about/disclaimer'),
            ),

            _LegalTile(
              icon: Icons.source_outlined,
              title: 'Data Sources',
              subtitle: 'Data providers and attribution',
              onTap: () => context.push('/settings/about/data-sources'),
            ),

            const SizedBox(height: 24),

            // Information section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Text(
                'These documents explain how WildFire works, your rights, and our responsibilities. Last updated December 2025.',
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

/// A list tile for legal document navigation.
class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LegalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
