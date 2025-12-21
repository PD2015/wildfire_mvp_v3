import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/onboarding_card.dart';

/// Page 2: Emergency disclaimers and safety information.
///
/// Displays critical safety guidance about calling emergency services
/// and the informational nature of the app.
class DisclaimerPage extends StatelessWidget {
  /// Callback when user taps continue.
  final VoidCallback onContinue;

  /// Callback when user taps back.
  final VoidCallback? onBack;

  /// Callback to view full terms of service.
  final VoidCallback? onViewTerms;

  const DisclaimerPage({
    required this.onContinue,
    this.onBack,
    this.onViewTerms,
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
            const SizedBox(height: 24),

            // Warning icon
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: theme.colorScheme.error,
              semanticLabel: 'Important safety information',
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Important Safety Information',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Emergency callout card
            OnboardingCard(
              backgroundColor: theme.colorScheme.errorContainer,
              child: Column(
                children: [
                  Text(
                    'In an emergency, always call:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _EmergencyNumber(number: '999', label: 'Emergency'),
                      SizedBox(width: 24),
                      _EmergencyNumber(number: '101', label: 'Non-emergency'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer text
            const OnboardingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DisclaimerItem(
                    icon: Icons.info_outline,
                    text:
                        'WildFire provides general wildfire-risk information and satellite-detected hotspots.',
                  ),
                  SizedBox(height: 12),
                  _DisclaimerItem(
                    icon: Icons.warning_amber,
                    text: 'This app is not a real-time emergency alert system.',
                  ),
                  SizedBox(height: 12),
                  _DisclaimerItem(
                    icon: Icons.phone,
                    text:
                        'If you see fire or believe life or property is at risk, call 999 immediately.',
                  ),
                  SizedBox(height: 12),
                  _DisclaimerItem(
                    icon: Icons.phone_outlined,
                    text: 'For non-emergency fire concerns, call 101.',
                  ),
                  SizedBox(height: 12),
                  _DisclaimerItem(
                    icon: Icons.satellite_alt,
                    text:
                        'Satellite detections can include non-wildfire heat sources and may miss some fires.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // View terms link
            if (onViewTerms != null) ...[
              TextButton(
                onPressed: onViewTerms,
                child: const Text('View full terms and conditions'),
              ),
              const SizedBox(height: 8),
            ],

            // Navigation buttons
            Row(
              children: [
                // Back button
                if (onBack != null)
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: onBack,
                        child: const Text('Back'),
                      ),
                    ),
                  ),
                if (onBack != null) const SizedBox(width: 16),
                // Continue button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: onContinue,
                      child: const Text('I Understand'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Displays an emergency phone number prominently.
class _EmergencyNumber extends StatelessWidget {
  final String number;
  final String label;

  const _EmergencyNumber({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label phone number: $number',
      child: Column(
        children: [
          Text(
            number,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single disclaimer item with icon and text.
/// Matches the style of _FeatureItem in WelcomePage.
class _DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DisclaimerItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
