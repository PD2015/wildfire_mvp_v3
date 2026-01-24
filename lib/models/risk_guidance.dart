import 'package:equatable/equatable.dart';

/// Guidance information for a specific wildfire risk level
///
/// Provides public safety advice and behavioral guidance tailored to
/// the current fire risk conditions in Scotland.
///
/// Constitutional compliance:
/// - C4: Transparency through actionable public safety information
class RiskGuidance extends Equatable {
  /// Title of the guidance (e.g., "What this risk level means")
  final String title;

  /// Summary description of the risk level in plain language
  final String summary;

  /// List of bullet points with specific behavioral advice
  final List<String> bulletPoints;

  /// Optional label for contextual help link (used for accessibility/tooltip)
  /// e.g., "Learn more about risk levels"
  final String? helpLinkLabel;

  /// Optional route to navigate when help icon is tapped
  /// e.g., "/help/doc/risk-levels"
  final String? helpRoute;

  /// Optional disclaimer text shown after bullet points
  /// e.g., "Risk levels describe conditions, not safety."
  final String? disclaimer;

  /// Creates a RiskGuidance instance
  const RiskGuidance({
    required this.title,
    required this.summary,
    required this.bulletPoints,
    this.helpLinkLabel,
    this.helpRoute,
    this.disclaimer,
  });

  @override
  List<Object?> get props => [
        title,
        summary,
        bulletPoints,
        helpLinkLabel,
        helpRoute,
        disclaimer,
      ];

  @override
  String toString() {
    return 'RiskGuidance{title: $title, summary: $summary, '
        'bulletPoints: ${bulletPoints.length} items, '
        'helpRoute: $helpRoute, disclaimer: ${disclaimer != null}}';
  }
}
