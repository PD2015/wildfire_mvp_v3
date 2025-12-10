import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/onboarding_card.dart';

/// Page 1: Welcome introduction to the WildFire app.
///
/// Displays app purpose, key features, and a continue button.
class WelcomePage extends StatelessWidget {
  /// Callback when user taps continue.
  final VoidCallback onContinue;

  const WelcomePage({
    required this.onContinue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // App logo/icon
            Icon(
              Icons.local_fire_department,
              size: 80,
              color: theme.colorScheme.primary,
              semanticLabel: 'WildFire app logo',
            ),
            const SizedBox(height: 24),

            // Welcome title
            Text(
              'Welcome to WildFire',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              'Stay informed about wildfire activity in Scotland',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Feature highlights
            const OnboardingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureItem(
                    icon: Icons.map_outlined,
                    text: 'View active fires on an interactive map',
                  ),
                  SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.warning_amber_outlined,
                    text: 'Check fire risk levels for your area',
                  ),
                  SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.notifications_outlined,
                    text: 'Get alerts about nearby fire activity',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56, // 56dp for comfortable touch target
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Get Started'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// A single feature item with icon and text.
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
