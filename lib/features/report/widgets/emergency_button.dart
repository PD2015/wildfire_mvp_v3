import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';

/// Emergency contact button widget with accessibility and theming support
///
/// Displays an emergency contact as a styled button with proper touch targets,
/// semantic labels, and Material 3 theming. Handles different priority levels
/// with appropriate visual styling.
class EmergencyButton extends StatelessWidget {
  /// Emergency contact to display
  final EmergencyContact contact;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Optional custom text override
  final String? text;

  /// Emergency priority for styling (derived from contact if not provided)
  EmergencyPriority get priority => contact.priority;

  const EmergencyButton({
    super.key,
    required this.contact,
    this.onPressed,
    this.text,
  });

  /// Creates an emergency button with custom text
  const EmergencyButton.withText({
    super.key,
    required this.contact,
    required String this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get display text - custom text or contact's display text
    final buttonText = text ?? contact.displayText;

    return Semantics(
      label: _getSemanticLabel(buttonText),
      hint: _getSemanticHint(),
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        // Material 3 design: 52dp height for comfortable touch
        height: 52.0,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: _getButtonStyle(colorScheme),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.call),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    buttonText,
                    style: _getTextStyle(theme),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gets button style based on emergency priority and Material 3 theme
  ButtonStyle _getButtonStyle(ColorScheme colorScheme) {
    switch (priority) {
      case EmergencyPriority.urgent:
        // 999 - Emergency: use tertiaryContainer (amber) for strong warning
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.tertiaryContainer,
          foregroundColor: colorScheme.onTertiaryContainer,
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          minimumSize: const Size(double.infinity, 52.0),
          tapTargetSize: MaterialTapTargetSize.padded,
        );

      case EmergencyPriority.nonEmergency:
        // 101 - Medium priority: use secondaryContainer tonal style
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          minimumSize: const Size(double.infinity, 52.0),
          tapTargetSize: MaterialTapTargetSize.padded,
        );

      case EmergencyPriority.anonymous:
        // Crimestoppers - match Police styling (secondary tonal)
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          minimumSize: const Size(double.infinity, 52.0),
          tapTargetSize: MaterialTapTargetSize.padded,
        );
    }
  }

  /// Gets text style with appropriate sizing and weight
  TextStyle _getTextStyle(ThemeData theme) {
    // Create TextStyle with NO color property at all
    // This ensures button's foregroundColor is used (not overridden by theme)
    final baseFontSize = theme.textTheme.labelLarge?.fontSize ?? 14.0;

    return TextStyle(
      fontSize: baseFontSize,
      fontWeight: FontWeight.w600,
      // CRITICAL: No color property - allows button foregroundColor to apply
    );
  }

  /// Creates semantic label for screen readers (C4 compliance)
  String _getSemanticLabel(String buttonText) {
    final priorityDescription = _getPriorityDescription();
    return '$buttonText. $priorityDescription';
  }

  /// Creates semantic hint for additional context
  String _getSemanticHint() {
    switch (priority) {
      case EmergencyPriority.urgent:
        return 'Emergency line. Tap to call immediately.';
      case EmergencyPriority.nonEmergency:
        return 'Non-emergency line. Tap to call for assistance.';
      case EmergencyPriority.anonymous:
        return 'Anonymous reporting line. Tap to call confidentially.';
    }
  }

  /// Gets priority description for accessibility
  String _getPriorityDescription() {
    switch (priority) {
      case EmergencyPriority.urgent:
        return 'Emergency contact';
      case EmergencyPriority.nonEmergency:
        return 'Non-emergency contact';
      case EmergencyPriority.anonymous:
        return 'Anonymous reporting contact';
    }
  }
}

/// Convenience widget for creating Fire Service button (999)
class FireServiceButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const FireServiceButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return EmergencyButton(
      contact: EmergencyContact.fireService,
      onPressed: onPressed,
    );
  }
}

/// Convenience widget for creating Police Scotland button (101)
class PoliceScotlandButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const PoliceScotlandButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return EmergencyButton(
      contact: EmergencyContact.policeScotland,
      onPressed: onPressed,
    );
  }
}

/// Convenience widget for creating Crimestoppers button (0800 555 111)
class CrimestoppersButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CrimestoppersButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return EmergencyButton(
      contact: EmergencyContact.crimestoppers,
      onPressed: onPressed,
    );
  }
}
