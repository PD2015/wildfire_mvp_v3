import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Warning chip displayed when viewing demo or test data
/// 
/// Shows a prominent "DEMO DATA" warning with high contrast colors to
/// ensure users are aware they're viewing non-production data. This appears
/// when using mock service or test region data.
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
  
  const DemoDataChip({
    super.key,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? 'DEMO DATA';
    
    return Semantics(
      label: 'Warning: $displayLabel - This is test data, not real fire information',
      button: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: RiskPalette.extreme, // Red background for high visibility
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: RiskPalette.white,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000), // 20% opacity black
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: RiskPalette.white,
              size: 18,
              semanticLabel: '', // Meaning conveyed by container semantic label
            ),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: const TextStyle(
                color: RiskPalette.white,
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
