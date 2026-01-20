import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/features/help/content/help_content.dart';

/// Help & Info hub screen providing access to guidance and educational content.
///
/// The menu is generated dynamically from [HelpContent], ensuring a single
/// source of truth for all help documents.
///
/// Sections:
/// - Getting Started: How to use the app, risk levels, when to use
/// - Wildfire Education: Understanding risk, weather/fuel, seasonal guidance
/// - Using the Map: Hotspots, burnt areas, data sources, update frequency
/// - Safety & Responsibility: What to do, limitations, emergency guidance
/// - About: App info and version (special screen, not a document)
///
/// Constitutional compliance:
/// - C3: Accessibility with ≥48dp touch targets and semantic labels
/// - C1: Clean architecture with section-based layout
class HelpInfoScreen extends StatelessWidget {
  const HelpInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Info')),
      body: SafeArea(
        child: ListView(
          children: [
            // Generate sections dynamically from HelpContent
            for (final section in HelpContent.sections) ...[
              if (section != HelpSection.gettingStarted) const Divider(),
              _SectionHeader(title: section.displayName),
              for (final doc in HelpContent.forSection(section))
                _HelpTile(
                  icon: doc.icon,
                  title: doc.title,
                  subtitle: doc.description,
                  onTap: () => context.push('/help/doc/${doc.id}'),
                ),
            ],

            const Divider(),

            // About section (special screen, not a document)
            const _SectionHeader(title: 'About'),
            _HelpTile(
              icon: Icons.info_outline,
              title: 'About WildFire',
              subtitle: 'App version and information',
              onTap: () => context.push('/help/about'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Section header for help groups.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// A list tile for help navigation.
class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
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
