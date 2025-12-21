import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Help & Info hub screen providing access to guidance and educational content.
///
/// Sections:
/// - Getting Started: How to use the app, risk levels, when to use
/// - Wildfire Education: Understanding risk, weather/fuel, seasonal guidance
/// - Using the Map: Hotspots, data sources, update frequency
/// - Safety & Responsibility: What to do, limitations, emergency guidance
/// - About: App info and version
///
/// Constitutional compliance:
/// - C3: Accessibility with ≥48dp touch targets and semantic labels
/// - C1: Clean architecture with section-based layout
class HelpInfoScreen extends StatelessWidget {
  const HelpInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Info'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Getting Started section
            const _SectionHeader(title: 'Getting Started'),
            _HelpTile(
              icon: Icons.menu_book_outlined,
              title: 'How to use WildFire',
              subtitle: 'Quick guide to app features',
              onTap: () => context.push('/help/getting-started/how-to-use'),
            ),
            _HelpTile(
              icon: Icons.speed_outlined,
              title: 'What the risk levels mean',
              subtitle: 'Understanding fire risk ratings',
              onTap: () => context.push('/help/getting-started/risk-levels'),
            ),
            _HelpTile(
              icon: Icons.schedule_outlined,
              title: 'When to use this app',
              subtitle: 'And when not to rely on it',
              onTap: () => context.push('/help/getting-started/when-to-use'),
            ),

            const Divider(),

            // Wildfire Education section
            const _SectionHeader(title: 'Wildfire Education'),
            _HelpTile(
              icon: Icons.local_fire_department_outlined,
              title: 'Understanding wildfire risk',
              subtitle: 'Fire risk factors in Scotland',
              onTap: () =>
                  context.push('/help/wildfire-education/understanding-risk'),
            ),
            _HelpTile(
              icon: Icons.thermostat_outlined,
              title: 'Weather, fuel, and fire',
              subtitle: 'How conditions affect fire behaviour',
              onTap: () =>
                  context.push('/help/wildfire-education/weather-fuel-fire'),
            ),
            _HelpTile(
              icon: Icons.calendar_month_outlined,
              title: 'Seasonal guidance',
              subtitle: 'Risk patterns throughout the year',
              onTap: () =>
                  context.push('/help/wildfire-education/seasonal-guidance'),
            ),

            const Divider(),

            // Using the Map section
            const _SectionHeader(title: 'Using the Map'),
            _HelpTile(
              icon: Icons.location_on_outlined,
              title: 'What hotspots show',
              subtitle: 'Understanding map markers',
              onTap: () => context.push('/help/using-the-map/hotspots'),
            ),
            _HelpTile(
              icon: Icons.storage_outlined,
              title: 'Data sources explained',
              subtitle: 'Where our data comes from',
              onTap: () => context.push('/help/using-the-map/data-sources'),
            ),
            _HelpTile(
              icon: Icons.update_outlined,
              title: 'Update frequency & limits',
              subtitle: 'How often data refreshes',
              onTap: () => context.push('/help/using-the-map/update-frequency'),
            ),

            const Divider(),

            // Safety & Responsibility section
            const _SectionHeader(title: 'Safety & Responsibility'),
            _HelpTile(
              icon: Icons.emergency_outlined,
              title: 'What to do if you see fire',
              subtitle: 'Emergency response guidance',
              onTap: () => context.push('/help/safety/see-fire'),
            ),
            _HelpTile(
              icon: Icons.info_outline,
              title: 'Important limitations',
              subtitle: 'What this app cannot do',
              onTap: () => context.push('/help/safety/limitations'),
            ),
            _HelpTile(
              icon: Icons.phone_outlined,
              title: 'Emergency contacts',
              subtitle: 'Who to call in an emergency',
              onTap: () => context.push('/help/safety/emergency-guidance'),
            ),

            const Divider(),

            // About section
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
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
