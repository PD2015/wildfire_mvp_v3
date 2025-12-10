import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/onboarding_card.dart';

/// Page 3: Privacy information and data usage transparency.
///
/// Explains what data is collected (location only when app open),
/// what is NOT collected (no tracking, no personal data stored).
class PrivacyPage extends StatelessWidget {
  /// Callback when user taps continue.
  final VoidCallback onContinue;

  /// Callback to view full privacy policy.
  final VoidCallback? onViewPrivacy;

  const PrivacyPage({
    required this.onContinue,
    this.onViewPrivacy,
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

            // Privacy icon
            Icon(
              Icons.shield_outlined,
              size: 64,
              color: theme.colorScheme.primary,
              semanticLabel: 'Privacy protection',
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Your Privacy Matters',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'We believe in transparency about your data',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // What we do collect
            OnboardingCard(
              icon: Icons.check_circle_outline,
              iconColor: theme.colorScheme.primary,
              title: 'What we use',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrivacyItem(
                    text: 'Location (only while app is open)',
                    isPositive: true,
                  ),
                  SizedBox(height: 8),
                  _PrivacyItem(
                    text: 'Your notification preferences',
                    isPositive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // What we don't collect
            OnboardingCard(
              icon: Icons.cancel_outlined,
              iconColor: theme.colorScheme.error,
              title: 'What we don\'t do',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrivacyItem(
                    text: 'No tracking or analytics',
                    isPositive: false,
                  ),
                  SizedBox(height: 8),
                  _PrivacyItem(
                    text: 'No personal data stored on servers',
                    isPositive: false,
                  ),
                  SizedBox(height: 8),
                  _PrivacyItem(
                    text: 'No location history saved',
                    isPositive: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // View privacy policy link
            if (onViewPrivacy != null) ...[
              TextButton(
                onPressed: onViewPrivacy,
                child: const Text('View full privacy policy'),
              ),
              const SizedBox(height: 8),
            ],

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// A privacy list item with checkmark or cross icon.
class _PrivacyItem extends StatelessWidget {
  final String text;
  final bool isPositive;

  const _PrivacyItem({
    required this.text,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isPositive ? Icons.check : Icons.close,
          size: 20,
          color: isPositive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        const SizedBox(width: 8),
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
