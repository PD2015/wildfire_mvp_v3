import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';
import 'package:wildfire_mvp_v3/services/onboarding_prefs_impl.dart';
import 'package:wildfire_mvp_v3/widgets/app_navigation_tile.dart';

/// About screen hub linking to legal documents.
///
/// Provides navigation to:
/// - Terms of Service
/// - Privacy Policy
/// - Data Sources & Attribution
///
/// Also displays app version information.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: ListView(
          children: [
            // App info header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // App icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'WildFire',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scottish Wildfire Tracker',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Legal documents section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Legal',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            AppNavigationTile(
              icon: Icons.description_outlined,
              title: LegalContent.termsOfService.title,
              subtitle: 'App usage terms and conditions',
              onTap: () => context.push('/about/terms'),
            ),

            AppNavigationTile(
              icon: Icons.privacy_tip_outlined,
              title: LegalContent.privacyPolicy.title,
              subtitle: 'How we handle your data',
              onTap: () => context.push('/about/privacy'),
            ),

            AppNavigationTile(
              icon: Icons.warning_amber_outlined,
              title: LegalContent.emergencyDisclaimer.title,
              subtitle: 'Important safety information',
              onTap: () => context.push('/about/disclaimer'),
            ),

            AppNavigationTile(
              icon: Icons.source_outlined,
              title: LegalContent.dataSources.title,
              subtitle: 'Data providers and attribution',
              onTap: () => context.push('/about/data-sources'),
            ),

            const Divider(),

            // App info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Legal Version'),
              subtitle: Text(
                'Content v${LegalContent.contentVersion}',
                style: theme.textTheme.bodySmall,
              ),
            ),

            // Developer section (debug only)
            if (kDebugMode) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Developer',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.refresh, color: theme.colorScheme.error),
                title: const Text('Reset Onboarding'),
                subtitle: const Text('Clear preferences and restart flow'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final service = OnboardingPrefsImpl(prefs);
                  await service.resetOnboarding();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Onboarding reset. Restart app or navigate to /onboarding',
                        ),
                      ),
                    );
                    context.go('/onboarding');
                  }
                },
              ),
            ],

            // Footer
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'For information only. Not an emergency alert system.\n'
                'Call 999 in an emergency.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
