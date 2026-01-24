import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_button.dart';

/// Emergency hero card combining header, call-to-action, and emergency buttons.
///
/// This is the primary call-to-action on the Report Fire screen, designed to
/// guide users quickly through emergency reporting with clear visual hierarchy:
///
/// 1. Fire icon + headline asking about fire sighting
/// 2. Clear instruction for emergency situations
/// 3. Prominent 999 button for immediate emergencies
/// 4. Secondary row with 101 Police and Crimestoppers options
/// 5. Disclaimer that app doesn't contact services directly
///
/// ## Design Decisions
/// - Fire icon reinforces emergency context
/// - 999 button uses filled style (most prominent)
/// - 101/Crimestoppers use outlined style (secondary)
/// - Disclaimer at bottom for legal compliance
///
/// ## Constitutional Compliance
/// - C3: All buttons ≥48dp touch target, semantic labels
/// - C4: Uses theme tokens, no hardcoded colors
class EmergencyHeroCard extends StatelessWidget {
  /// Callback when 999 Fire Service button is pressed
  final VoidCallback? onCall999;

  /// Callback when 101 Police Scotland button is pressed
  final VoidCallback? onCall101;

  /// Callback when Crimestoppers button is pressed
  final VoidCallback? onCallCrimestoppers;

  const EmergencyHeroCard({
    super.key,
    this.onCall999,
    this.onCall101,
    this.onCallCrimestoppers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Semantics(
      container: true,
      label: 'Emergency reporting guidance. See smoke, flames, or a campfire?',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with fire icon
              _buildHeader(cs, textTheme),
              const SizedBox(height: 16),

              // Emergency instruction
              _buildInstruction(cs, textTheme),
              const SizedBox(height: 16),

              // 999 Fire Service button (prominent)
              EmergencyButton(
                contact: EmergencyContact.fireService,
                onPressed: onCall999,
              ),
              const SizedBox(height: 16),

              // Non-emergency guidance with "Learn more" link
              _buildNonEmergencyGuidance(context, cs, textTheme),
              const SizedBox(height: 12),

              // Secondary buttons row: 101 and Crimestoppers
              _buildSecondaryButtonsRow(cs),
              const SizedBox(height: 16),

              // Disclaimer
              _buildDisclaimer(context, cs),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header with warning icon and headline
  Widget _buildHeader(ColorScheme cs, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Warning icon (no background)
        Icon(Icons.warning_amber_outlined, color: cs.onSurface, size: 24),
        const SizedBox(width: 12),

        // Headline
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'See smoke, flames, or a campfire?',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the emergency instruction text with bold emphasis on key action
  Widget _buildInstruction(ColorScheme cs, TextTheme textTheme) {
    final baseStyle = textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
    );
    final boldStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.bold,
      color: cs.onSurface,
    );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'If it\'s spreading or unsafe, '),
          TextSpan(text: 'call 999 immediately. ', style: boldStyle),
          const TextSpan(
            text:
                'Give your location, what\'s burning, and a safe access point.',
          ),
        ],
      ),
    );
  }

  /// Builds non-emergency guidance text with "Learn more" link
  ///
  /// Provides brief inline context for when to use 101 vs Crimestoppers,
  /// with a link to detailed help content for scenarios like:
  /// - Unattended campfires
  /// - Smouldering peat needing monitoring
  /// - Suspicious activity
  Widget _buildNonEmergencyGuidance(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider to separate from 999 button
        Divider(color: cs.outlineVariant, height: 1),
        const SizedBox(height: 16),

        // Title - white and bold to stand out
        Text(
          'Not an emergency?',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Bullet points with highlighted numbers
        _buildBulletItem(
          cs,
          textTheme,
          text:
              'Someone lighting a fire irresponsibly? Call Police Scotland on ',
          highlightedNumber: '101',
        ),
        const SizedBox(height: 8),
        _buildBulletItem(
          cs,
          textTheme,
          text: 'Want to report anonymously? Call ',
          highlightedNumber: 'Crimestoppers',
        ),

        const SizedBox(height: 12),

        // "Learn more" link with icon - 48dp touch target for C3 compliance
        Semantics(
          link: true,
          label: 'Learn more about when to call each number',
          child: InkWell(
            onTap: () => GoRouter.of(context).push('/help/doc/see-fire'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline, size: 16, color: cs.onSurface),
                  const SizedBox(width: 6),
                  Text(
                    'When to call each number',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: cs.onSurface),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a bullet item with highlighted number/text
  Widget _buildBulletItem(
    ColorScheme cs,
    TextTheme textTheme, {
    required String text,
    required String highlightedNumber,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•  ',
          style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              children: [
                TextSpan(text: text),
                TextSpan(
                  text: highlightedNumber,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the secondary buttons row (101 and Crimestoppers)
  Widget _buildSecondaryButtonsRow(ColorScheme cs) {
    return Row(
      children: [
        // 101 Police Scotland
        Expanded(
          child: _SecondaryEmergencyButton(
            contact: EmergencyContact.policeScotland,
            onPressed: onCall101,
          ),
        ),
        const SizedBox(width: 12),

        // Crimestoppers
        Expanded(
          child: _SecondaryEmergencyButton(
            contact: EmergencyContact.crimestoppers,
            onPressed: onCallCrimestoppers,
          ),
        ),
      ],
    );
  }

  /// Builds the disclaimer text
  Widget _buildDisclaimer(BuildContext context, ColorScheme cs) {
    return Semantics(
      label:
          'Important: This app does not contact emergency services. Always phone yourself.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'This app does not contact emergency services. Always phone 999, 101 or Crimestoppers yourself.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Secondary emergency button with outlined style for 101/Crimestoppers
///
/// Uses outlined button style to visually distinguish from the primary
/// 999 emergency button while maintaining accessibility standards.
class _SecondaryEmergencyButton extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback? onPressed;

  const _SecondaryEmergencyButton({required this.contact, this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Shorter label for row layout
    final label = switch (contact) {
      EmergencyContact.policeScotland => '101 Police',
      EmergencyContact.crimestoppers => 'Crimestoppers',
      _ => contact.displayText,
    };

    return Semantics(
      label: 'Call ${contact.displayText}',
      hint: 'Double tap to call',
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        height: 48.0,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.call, size: 18),
          label: Text(label, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            // Only override size/tap target; theme handles colors and border
            minimumSize: const Size(0, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
      ),
    );
  }
}
