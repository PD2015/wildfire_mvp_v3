import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// RiskResultChip displays fire risk assessment result
///
/// Shows risk level, FWI value, timestamp, and data source
/// with Scottish color tokens for visual consistency.
///
/// Constitutional compliance:
/// - C3: Accessible with semantic labels
/// - C4: Uses official Scottish wildfire risk colors from RiskPalette
class RiskResultChip extends StatelessWidget {
  final FireRisk fireRisk;

  const RiskResultChip({
    super.key,
    required this.fireRisk,
  });

  Color _getRiskColor() {
    return switch (fireRisk.level) {
      RiskLevel.veryLow => RiskPalette.veryLow,
      RiskLevel.low => RiskPalette.low,
      RiskLevel.moderate => RiskPalette.moderate,
      RiskLevel.high => RiskPalette.high,
      RiskLevel.veryHigh => RiskPalette.veryHigh,
      RiskLevel.extreme => RiskPalette.extreme,
    };
  }

  String _getRiskLabel() {
    return switch (fireRisk.level) {
      RiskLevel.veryLow => 'VERY LOW',
      RiskLevel.low => 'LOW',
      RiskLevel.moderate => 'MODERATE',
      RiskLevel.high => 'HIGH',
      RiskLevel.veryHigh => 'VERY HIGH',
      RiskLevel.extreme => 'EXTREME',
    };
  }

  String _getSourceLabel() {
    return switch (fireRisk.source) {
      DataSource.effis => 'EFFIS',
      DataSource.sepa => 'SEPA',
      DataSource.cache => 'CACHE',
      DataSource.mock => 'MOCK',
    };
  }

  String _formatTimestamp() {
    // Format as ISO-8601 UTC
    return '${fireRisk.observedAt.toIso8601String().split('.')[0]}Z';
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    final riskLabel = _getRiskLabel();
    final sourceLabel = _getSourceLabel();

    return Semantics(
      label: 'Fire risk: $riskLabel, ${fireRisk.fwi != null ? 'FWI ${fireRisk.fwi!.toStringAsFixed(1)}' : 'FWI unavailable'}, Source: $sourceLabel, Last updated: ${_formatTimestamp()}',
      child: Card(
        elevation: 4,
        color: riskColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risk level
              Text(
                riskLabel,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              // FWI value
              if (fireRisk.fwi != null)
                Text(
                  'FWI: ${fireRisk.fwi!.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
              const SizedBox(height: 8),
              // Source
              Row(
                children: [
                  Icon(
                    _getSourceIcon(),
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sourceLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Timestamp
              Text(
                'Updated: ${_formatTimestamp()}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSourceIcon() {
    return switch (fireRisk.freshness) {
      Freshness.live => Icons.cloud_done,
      Freshness.cached => Icons.cached,
      Freshness.mock => Icons.science,
    };
  }
}
