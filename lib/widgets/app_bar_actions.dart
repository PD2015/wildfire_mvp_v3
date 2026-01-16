import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared AppBar actions for Settings and Help navigation.
///
/// Displays two icon buttons in the AppBar for secondary navigation:
/// - Settings (gear icon) → /settings
/// - Help & Info (help icon) → /help
///
/// These actions appear on all primary screens (Fire Risk, Map, Report Fire)
/// to provide consistent access to settings and help content.
///
/// Constitutional compliance:
/// - C3: Accessibility with ≥48dp touch targets and semantic labels
/// - C1: Clean, reusable widget following Material Design guidelines
class AppBarActions extends StatelessWidget {
  /// Optional callback when settings is tapped (for testing)
  final VoidCallback? onSettingsTap;

  /// Optional callback when help is tapped (for testing)
  final VoidCallback? onHelpTap;

  const AppBarActions({super.key, this.onSettingsTap, this.onHelpTap});

  @override
  Widget build(BuildContext context) {
    GoRouterState? routerState;
    GoRouter? router;

    // Gracefully handle contexts that are not under a GoRouter route (e.g. tests)
    try {
      routerState = GoRouterState.of(context);
      router = GoRouter.of(context);
    } on GoError {
      routerState = null;
      router = null;
    }

    final currentPath = routerState?.uri.path ?? '';
    final isOnSettings = currentPath.startsWith('/settings');
    final isOnHelp = currentPath.startsWith('/help');

    VoidCallback? effectiveSettingsTap;
    if (onSettingsTap != null) {
      effectiveSettingsTap = onSettingsTap;
    } else if (router != null) {
      effectiveSettingsTap = () => router!.push('/settings');
    }

    VoidCallback? effectiveHelpTap;
    if (onHelpTap != null) {
      effectiveHelpTap = onHelpTap;
    } else if (router != null) {
      effectiveHelpTap = () => router!.push('/help');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Settings button
        IconButton(
          icon: Icon(isOnSettings ? Icons.settings : Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: effectiveSettingsTap,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        // Help button
        IconButton(
          icon: Icon(isOnHelp ? Icons.help : Icons.help_outline),
          tooltip: 'Help and information',
          onPressed: effectiveHelpTap,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      ],
    );
  }
}
