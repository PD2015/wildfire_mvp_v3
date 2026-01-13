import 'package:flutter/material.dart';
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
        Icon(
          Icons.warning_amber_outlined,
          color: cs.onSurface,
          size: 24,
        ),
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

  /// Builds the emergency instruction text
  Widget _buildInstruction(ColorScheme cs, TextTheme textTheme) {
    return Text(
      'If it\'s spreading or unsafe, call 999 immediately.\n'
      'Give your location, what\'s burning, and a safe access point.',
      style: textTheme.bodyMedium?.copyWith(
        color: cs.onSurfaceVariant,
      ),
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
          Icon(
            Icons.info_outline,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
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

  const _SecondaryEmergencyButton({
    required this.contact,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
          label: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.onSurface,
            side: BorderSide(color: cs.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(0, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
      ),
    );
  }
}
