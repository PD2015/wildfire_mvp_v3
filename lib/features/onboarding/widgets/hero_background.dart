import 'package:flutter/material.dart';

/// Gradient background widget for onboarding hero sections.
///
/// Provides a fire-themed warm gradient background with
/// proper SafeArea handling.
class HeroBackground extends StatelessWidget {
  /// The content to display on top of the background.
  final Widget child;

  const HeroBackground({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fire-themed gradient colors
    final colors = isDark
        ? [
            /* const Color(0xFF1A1A2E), // Dark background
            const Color(0xFF16213E), // Deep blue
            const Color(0xFF0F3460), // Navy */

            /*  Color(0xFF062B27), // forest900
    Color(0xFF0C3B35), // forest800
    Color(0xFF0F4A43), // forest700 with mint tint */

            Color(0xFF052A23),
            Color(0x332C1A0F), // low-opacity ember glow
            Color(0xFF071F1B),
          ]
        : [
            const Color(0xFFFF6B35), // Bright orange
            const Color(0xFFFF8C42), // Light orange
            const Color(0xFFFFC93C), // Yellow
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: SafeArea(
        child: child,
      ),
    );
  }
}
