import 'package:flutter/material.dart';

/// Reusable card widget for onboarding content.
///
/// Provides consistent styling across all onboarding pages:
/// - Rounded corners
/// - Consistent padding (24dp)
/// - Max width constraint for tablets (400dp)
/// - Subtle elevation
/// - Optional icon header with title
class OnboardingCard extends StatelessWidget {
  /// The content to display inside the card.
  final Widget child;

  /// Optional padding override (default 24dp).
  final EdgeInsetsGeometry? padding;

  /// Optional icon to display above the content.
  final IconData? icon;

  /// Optional icon color (uses primary by default).
  final Color? iconColor;

  /// Optional title displayed below the icon.
  final String? title;

  /// Optional background color override.
  final Color? backgroundColor;

  const OnboardingCard({
    required this.child,
    this.padding,
    this.icon,
    this.iconColor,
    this.title,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: backgroundColor ?? theme.colorScheme.surface,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 32,
                    color: iconColor ?? theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                ],
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
