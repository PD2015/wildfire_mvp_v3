import 'package:flutter/material.dart';
import '../content/scotland_risk_guidance.dart';
import '../models/risk_level.dart';

/// Displays wildfire safety guidance based on current risk level
///
/// Shows Scotland-specific actionable advice from authoritative sources
/// (SFRS, Ready.Scot, CNPA). Falls back to generic guidance when risk
/// level is unavailable.
///
/// Design specifications:
/// - 24px rounded corners
/// - 4px top border in risk level color (or grey if null)
/// - Surface background with padding
/// - Circle bullet points for readability
/// - Emergency footer: "Call 999..."
///
/// Constitutional compliance:
/// - C3: Accessible (≥44dp touch targets, semantic labels)
/// - C4: Transparency through public safety information
class RiskGuidanceCard extends StatelessWidget {
  /// Risk level to display guidance for, or null for generic guidance
  final RiskLevel? level;

  const RiskGuidanceCard({
    super.key,
    this.level,
  });

  @override
  Widget build(BuildContext context) {
    final guidance = ScotlandRiskGuidance.getGuidance(level);
    // final borderColor = level?.color ?? Colors.grey;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBackground =
        isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerHighest;
    final cardBorderColor = isDark
        ? level?.color ?? scheme.outline
        : level?.color ?? scheme.outlineVariant;
    // Bullet colour (mint accent)
    // final bulletColor = scheme.secondary; //?????

    return Semantics(
      label: level != null
          ? 'Guidance for ${level!.name} wildfire risk level'
          : 'General wildfire safety guidance',
      child: Card(
        margin: EdgeInsets.zero,
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: cardBorderColor,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                guidance.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Summary
              Text(
                guidance.summary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Bullet points
              ...guidance.bulletPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circle bullet - uses theme color for subtlety
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 12),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Emergency footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ScotlandRiskGuidance.emergencyFooter,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
