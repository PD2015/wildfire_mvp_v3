import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/onboarding_card.dart';
import 'package:wildfire_mvp_v3/features/onboarding/widgets/radius_selector.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';

/// Page 4: Setup preferences and consent.
///
/// Allows user to:
/// - Understand location usage
/// - Select notification radius
/// - Acknowledge safety disclaimer
/// - Accept terms and privacy policy
/// - Complete onboarding
class SetupPage extends StatefulWidget {
  /// Initial notification radius in km.
  final int initialRadius;

  /// Whether disclaimer has been acknowledged.
  final bool disclaimerAcknowledged;

  /// Whether terms have been accepted.
  final bool termsAccepted;

  /// Callback when radius changes.
  final ValueChanged<int> onRadiusChanged;

  /// Callback when disclaimer acknowledgment changes.
  final ValueChanged<bool> onDisclaimerChanged;

  /// Callback when terms acceptance changes.
  final ValueChanged<bool> onTermsChanged;

  /// Callback when user completes setup.
  final VoidCallback onComplete;

  /// Callback to view terms.
  final VoidCallback? onViewTerms;

  /// Callback to view privacy policy.
  final VoidCallback? onViewPrivacy;

  const SetupPage({
    required this.initialRadius,
    required this.disclaimerAcknowledged,
    required this.termsAccepted,
    required this.onRadiusChanged,
    required this.onDisclaimerChanged,
    required this.onTermsChanged,
    required this.onComplete,
    this.onViewTerms,
    this.onViewPrivacy,
    super.key,
  });

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late int _selectedRadius;
  late bool _disclaimerAcknowledged;
  late bool _termsAccepted;

  @override
  void initState() {
    super.initState();
    _selectedRadius = widget.initialRadius;
    _disclaimerAcknowledged = widget.disclaimerAcknowledged;
    _termsAccepted = widget.termsAccepted;
  }

  void _updateRadius(int radius) {
    setState(() => _selectedRadius = radius);
    widget.onRadiusChanged(radius);
  }

  void _updateDisclaimer(bool? value) {
    final acknowledged = value ?? false;
    setState(() => _disclaimerAcknowledged = acknowledged);
    widget.onDisclaimerChanged(acknowledged);
  }

  void _updateTerms(bool? value) {
    final accepted = value ?? false;
    setState(() => _termsAccepted = accepted);
    widget.onTermsChanged(accepted);
  }

  bool get _canComplete => _disclaimerAcknowledged && _termsAccepted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Setup icon
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: theme.colorScheme.primary,
              semanticLabel: 'Setup preferences',
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Set Your Preferences',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Customise how WildFire works for you',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Location info card (informational only)
            const OnboardingCard(
              icon: Icons.my_location_outlined,
              title: 'Location Access',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoItem(
                    icon: Icons.place_outlined,
                    text:
                        'WildFire uses your location to show nearby fire risk',
                  ),
                  SizedBox(height: 8),
                  _InfoItem(
                    icon: Icons.visibility_outlined,
                    text: 'Location is only used while the app is open',
                  ),
                  SizedBox(height: 8),
                  _InfoItem(
                    icon: Icons.touch_app_outlined,
                    text:
                        'You\'ll be prompted for permission when you first use the map',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification radius card
            OnboardingCard(
              icon: Icons.notifications_outlined,
              title: 'Notification Radius',
              child: Column(
                children: [
                  Text(
                    'Get notified about fires within:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadiusSelector(
                    selectedRadius: _selectedRadius,
                    onChanged: _updateRadius,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRadiusDescription(_selectedRadius),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Consent checkboxes card
            OnboardingCard(
              child: Column(
                children: [
                  // Disclaimer acknowledgment checkbox
                  CheckboxListTile(
                    key: const Key('disclaimer_checkbox'),
                    value: _disclaimerAcknowledged,
                    onChanged: _updateDisclaimer,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'I understand this app is informational only and is not an emergency alert system.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  // Terms acceptance checkbox
                  CheckboxListTile(
                    key: const Key('terms_checkbox'),
                    value: _termsAccepted,
                    onChanged: _updateTerms,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: widget.onViewTerms,
                              child: Text(
                                'Terms of Service',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: widget.onViewPrivacy,
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                  // Version info
                  Text(
                    'Terms version: ${OnboardingConfig.currentTermsVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Complete button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _canComplete ? widget.onComplete : null,
                child: const Text('Complete Setup'),
              ),
            ),
            const SizedBox(height: 8),

            // Helper text
            if (!_canComplete)
              Text(
                'Please acknowledge the disclaimer and accept the terms to continue',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getRadiusDescription(int radius) {
    if (radius == 0) {
      return 'You won\'t receive fire notifications';
    }
    return 'You\'ll be notified about fires within $radius km of your location';
  }
}

/// A simple info item with icon and text for the location card.
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
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
