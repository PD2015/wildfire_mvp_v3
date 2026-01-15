import 'package:flutter/material.dart';

/// Warning chip displayed when viewing demo or test data
///
/// Shows a prominent "DEMO DATA" warning with amber/warning colors to
/// ensure users are aware they're viewing non-production data. This appears
/// when using mock service or test region data.
///
/// Matches the styling of demo data chips shown on the map for visual
/// consistency across the application.
///
/// Example usage:
/// ```dart
/// DemoDataChip() // Default "DEMO DATA" label
/// DemoDataChip(label: 'TEST REGION') // Custom label
/// ```
///
/// Constitutional compliance:
/// - C3: Accessibility - High contrast meets WCAG AAA, clear semantic labels
/// - C4: Transparency - Prominent warning about data source
class DemoDataChip extends StatelessWidget {
  /// Optional custom warning text (defaults to "DEMO DATA")
  final String? label;

  const DemoDataChip({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? 'DEMO DATA';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Amber color for warning (Material 3 warning color)
    const amberBackground = Color(0xFFFF6F00); // Amber 900
    const amberBorder = Color(0xFFFFB300); // Amber 600

    return Semantics(
      label:
          'Warning: $displayLabel - This is test data, not real fire information',
      button: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: amberBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: amberBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.onPrimary,
              size: 18,
              semanticLabel: '', // Meaning conveyed by container semantic label
            ),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
