import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Custom marker widget for displaying fire incidents on map.
///
/// Visual properties:
/// - Size: based on confidence/FRP (small <50%, medium 50-80%, large >80%)
/// - Color: based on incident age (fresh <6h red, recent 6-24h orange, old >24h gray)
/// - Selection: highlighted border when selected
/// - Accessibility: semantic labels describe fire details
///
/// C3 Compliance: Semantic labels for screen readers
/// C4 Compliance: Visual transparency of fire data freshness via color coding
class FireMarker extends StatelessWidget {
  final FireIncident incident;
  final bool isSelected;
  final VoidCallback? onTap;

  const FireMarker({
    super.key,
    required this.incident,
    this.isSelected = false,
    this.onTap,
  });

  /// Calculate marker size based on confidence and FRP values.
  ///
  /// Size tiers:
  /// - Small (30dp): confidence <50% OR frp <5 MW
  /// - Medium (44dp): confidence 50-80% OR frp 5-15 MW
  /// - Large (56dp): confidence >80% OR frp >15 MW
  ///
  /// C3 Compliance: Medium/Large markers meet ≥44dp touch target requirement
  double get _markerSize {
    final confidence = incident.confidence ?? 0.0;
    final frp = incident.frp ?? 0.0;

    // Large: high confidence OR high FRP
    if (confidence > 80 || frp > 15) {
      return 56.0;
    }

    // Medium: moderate confidence OR moderate FRP
    if (confidence > 50 || frp > 5) {
      return 44.0;
    }

    // Small: low confidence AND low FRP
    return 30.0;
  }

  /// Get marker color based on incident age.
  ///
  /// Color coding for temporal awareness:
  /// - Fresh (<6h): Red (RiskPalette.veryHigh) - immediate attention
  /// - Recent (6-24h): Orange (RiskPalette.moderate) - ongoing monitoring
  /// - Old (>24h): Gray (RiskPalette.midGray) - historical context
  Color get _markerColor {
    final age = DateTime.now().toUtc().difference(incident.detectedAt);

    if (age.inHours < 6) {
      return RiskPalette.veryHigh; // Fresh fires - red
    } else if (age.inHours < 24) {
      return RiskPalette.moderate; // Recent fires - orange
    } else {
      return RiskPalette.midGray; // Old fires - gray
    }
  }

  /// Build semantic label for screen readers (C3 compliance).
  ///
  /// Includes: age description, confidence level, fire intensity
  String get _semanticLabel {
    final age = DateTime.now().toUtc().difference(incident.detectedAt);
    final ageDescription = _formatAge(age);
    final confidence = incident.confidence ?? 0.0;
    final confidenceLevel = confidence > 80
        ? 'high confidence'
        : confidence > 50
            ? 'moderate confidence'
            : 'low confidence';

    final intensity = incident.intensity.toLowerCase();

    return 'Fire incident detected $ageDescription, $confidenceLevel, $intensity level';
  }

  /// Format age for semantic label.
  String _formatAge(Duration age) {
    if (age.inHours < 1) {
      return '${age.inMinutes} minutes ago';
    } else if (age.inHours < 24) {
      return '${age.inHours} hours ago';
    } else {
      return '${age.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _markerSize,
          height: _markerSize,
          decoration: BoxDecoration(
            color: _markerColor,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: RiskPalette.blueAccent,
                    width: 4,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: _markerSize * 0.6,
            semanticLabel: '',
          ),
        ),
      ),
    );
  }
}

/// Marker size tier enumeration for testing and documentation.
enum MarkerSize {
  small(30.0),
  medium(44.0),
  large(56.0);

  const MarkerSize(this.size);
  final double size;
}

/// Marker color enumeration for testing and documentation.
enum MarkerAgeColor {
  fresh(RiskPalette.veryHigh), // <6h - red
  recent(RiskPalette.moderate), // 6-24h - orange
  old(RiskPalette.midGray); // >24h - gray

  const MarkerAgeColor(this.color);
  final Color color;
}
