import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/onboarding_card.dart';

/// Page 2: Emergency disclaimers and safety information.
///
/// Displays critical safety guidance about calling emergency services
/// and the informational nature of the app.
class DisclaimerPage extends StatelessWidget {
  /// Callback when user taps continue.
  final VoidCallback onContinue;

  /// Callback to view full terms of service.
  final VoidCallback? onViewTerms;

  const DisclaimerPage({
    required this.onContinue,
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
                      _EmergencyNumber(
                        number: '999',
                        label: 'Emergency',
                      ),
                      SizedBox(width: 24),
                      _EmergencyNumber(
                        number: '101',
                        label: 'Non-emergency',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer text
            OnboardingCard(
              child: Text(
                'This app provides informational data only and should '
                'not be used for emergency decisions. Fire data may be '
                'delayed or incomplete. Always follow official guidance '
                'from emergency services.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
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

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('I Understand'),
              ),
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

  const _EmergencyNumber({
    required this.number,
    required this.label,
  });

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
              color: theme.colorScheme.error,
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
