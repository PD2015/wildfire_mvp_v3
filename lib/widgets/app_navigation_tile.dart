import 'package:flutter/material.dart';

/// Shared navigation list tile for settings, help, about, and legal screens.
///
/// Provides a consistent ListTile with leading icon, title, subtitle,
/// trailing chevron, and optional [enabled] / [iconColor] overrides.
///
/// ## Usage
/// ```dart
/// AppNavigationTile(
///   icon: Icons.info_outline,
///   title: 'About',
///   subtitle: 'Version info and legal',
///   onTap: () => Navigator.push(...),
/// )
///
/// AppNavigationTile(
///   icon: Icons.notifications,
///   title: 'Notifications',
///   subtitle: 'Coming soon',
///   onTap: () {},
///   enabled: false,
///   iconColor: Colors.amber,
/// )
/// ```
class AppNavigationTile extends StatelessWidget {
  /// Leading icon for the tile.
  final IconData icon;

  /// Primary title text.
  final String title;

  /// Secondary subtitle text.
  final String subtitle;

  /// Tap callback. Ignored when [enabled] is false.
  final VoidCallback onTap;

  /// Whether this tile is interactive. Defaults to true.
  final bool enabled;

  /// Optional icon color override. Defaults to `onSurfaceVariant`.
  final Color? iconColor;

  const AppNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const disabledAlpha = 0.5;
    final defaultColor = theme.colorScheme.onSurfaceVariant;

    final effectiveIconColor = enabled
        ? (iconColor ?? defaultColor)
        : (iconColor ?? defaultColor).withValues(alpha: disabledAlpha);

    return ListTile(
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(
        title,
        style: enabled
            ? null
            : TextStyle(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: disabledAlpha),
              ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: enabled
              ? defaultColor
              : defaultColor.withValues(alpha: disabledAlpha),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: enabled
            ? defaultColor
            : defaultColor.withValues(alpha: disabledAlpha),
      ),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
