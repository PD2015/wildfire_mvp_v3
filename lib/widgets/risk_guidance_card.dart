import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../content/scotland_risk_guidance.dart';
import '../models/risk_guidance.dart';
import '../models/risk_level.dart';

/// Displays wildfire safety guidance based on current risk level
///
/// Shows Scotland-specific actionable advice from authoritative sources
/// (SFRS, Ready.Scot, CNPA). Falls back to generic guidance when risk
/// level is unavailable.
///
/// Design specifications:
/// - 12px rounded corners with 2px border
/// - Border color matches risk level (or theme outline when null)
/// - Surface background with 16px padding
/// - Circle bullet points for readability
/// - Optional info icon at top-right for contextual help
/// - Optional disclaimer text after bullet points
/// - Emergency footer: navigates to report screen
///
/// Constitutional compliance:
/// - C3: Accessible (≥44dp touch targets, semantic labels)
/// - C4: Transparency through public safety information
class RiskGuidanceCard extends StatelessWidget {
  /// Risk level to display guidance for, or null for generic guidance
  final RiskLevel? level;

  /// Optional override guidance (if null, uses ScotlandRiskGuidance)
  final RiskGuidance? guidance;

  const RiskGuidanceCard({super.key, this.level, this.guidance});

  @override
  Widget build(BuildContext context) {
    final effectiveGuidance =
        guidance ?? ScotlandRiskGuidance.getGuidance(level);
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
          side: BorderSide(color: cardBorderColor, width: 2),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    effectiveGuidance.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Summary
                  Text(
                    effectiveGuidance.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Bullet points
                  ...effectiveGuidance.bulletPoints.map(
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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

                  // Disclaimer (optional) - shown after bullets, before footer
                  if (effectiveGuidance.disclaimer != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      effectiveGuidance.disclaimer!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Emergency footer - navigates to report screen
                  FilledButton.tonal(
                    onPressed: () => context.go('/report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.tertiaryContainer,
                      foregroundColor: scheme.onTertiaryContainer,
                      padding: const EdgeInsets.all(16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ScotlandRiskGuidance.emergencyFooter,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Help icon at top-right (optional)
            if (effectiveGuidance.helpRoute != null)
              Positioned(
                top: 4,
                right: 4,
                child: Semantics(
                  label: effectiveGuidance.helpLinkLabel ??
                      'Learn more about risk levels',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                    tooltip: effectiveGuidance.helpLinkLabel ??
                        'Learn more about risk levels',
                    onPressed: () => context.push(effectiveGuidance.helpRoute!),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
