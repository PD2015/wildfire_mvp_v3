import 'package:flutter/material.dart';

/// Page indicator dots for onboarding flow.
///
/// Shows the current page position with a highlighted dot.
/// Includes accessibility support with page announcements.
class PageIndicator extends StatelessWidget {
  /// Current page index (0-based).
  final int currentPage;

  /// Total number of pages.
  final int totalPages;

  const PageIndicator({
    required this.currentPage,
    required this.totalPages,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Page ${currentPage + 1} of $totalPages',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final isActive = index == currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
