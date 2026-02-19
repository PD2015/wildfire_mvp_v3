import 'package:flutter/material.dart';

/// Shared section header for grouped lists (settings, help, about screens).
///
/// Renders an uppercase title with semantic `header: true` for accessibility.
/// Uses the primary color by default, with an optional [color] override.
///
/// ## Usage
/// ```dart
/// SectionHeader(title: 'General')
/// SectionHeader(title: 'Legal', color: Colors.grey)
/// ```
class SectionHeader extends StatelessWidget {
  /// The section title text (will be uppercased automatically).
  final String title;

  /// Optional color override. Defaults to `colorScheme.primary`.
  final Color? color;

  const SectionHeader({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(
            color: color ?? theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
