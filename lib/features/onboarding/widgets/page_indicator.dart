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

  /// Page titles for accessibility (optional).
  /// If provided, screen readers will announce "Step X of Y: [title]".
  final List<String>? pageTitles;

  const PageIndicator({
    required this.currentPage,
    required this.totalPages,
    this.pageTitles,
    super.key,
  });

  /// Default page titles for onboarding flow.
  static const List<String> defaultOnboardingTitles = [
    'Welcome',
    'Safety information',
    'Privacy',
    'Setup',
  ];

  String _getAccessibilityLabel() {
    final titles = pageTitles ?? defaultOnboardingTitles;
    final pageNumber = currentPage + 1;

    if (currentPage < titles.length) {
      return 'Step $pageNumber of $totalPages: ${titles[currentPage]}';
    }
    return 'Step $pageNumber of $totalPages';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: _getAccessibilityLabel(),
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
