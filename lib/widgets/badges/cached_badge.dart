import 'package:flutter/material.dart';
import '../../theme/risk_palette.dart';

/// A small badge widget indicating cached data
///
/// Displays "Cached" text in a pill-shaped container with proper
/// accessibility support. Uses RiskPalette constants for consistent
/// styling across the application.
class CachedBadge extends StatelessWidget {
  const CachedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cached result',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: RiskPalette.midGray.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Text(
          'Cached',
          style: TextStyle(
            color: RiskPalette.white,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
