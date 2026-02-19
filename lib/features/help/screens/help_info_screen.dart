import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/features/help/content/help_content.dart';
import 'package:wildfire_mvp_v3/widgets/app_navigation_tile.dart';
import 'package:wildfire_mvp_v3/widgets/section_header.dart';

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
              SectionHeader(title: section.displayName),
              for (final doc in HelpContent.forSection(section))
                AppNavigationTile(
                  icon: doc.icon,
                  title: doc.title,
                  subtitle: doc.description,
                  onTap: () => context.push('/help/doc/${doc.id}'),
                ),
            ],

            const Divider(),

            // About section (special screen, not a document)
            const SectionHeader(title: 'About'),
            AppNavigationTile(
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
