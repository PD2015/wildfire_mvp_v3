import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation bar for primary app navigation
///
/// Provides accessible navigation between Home, Map, and Report Fire screens with:
/// - Material Design 3 NavigationBar widget
/// - ≥44dp touch targets (C3 compliance)
/// - Semantic labels for screen readers
/// - Active route highlighting
///
/// Constitutional compliance:
/// - C3: Accessibility with semantic labels and touch targets
/// - C1: Clean code following Material Design guidelines
class AppBottomNav extends StatelessWidget {
  /// Current route path for highlighting active destination
  final String currentPath;

  const AppBottomNav({
    super.key,
    required this.currentPath,
  });

  /// Get selected index based on current route
  int get _selectedIndex {
    if (currentPath.startsWith('/map')) {
      return 1;
    } else if (currentPath.startsWith('/report')) {
      return 2;
    }
    return 0; // Default to home
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
          tooltip: 'Navigate to home screen',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Map',
          tooltip: 'Navigate to map screen',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_fire_department_outlined),
          selectedIcon: Icon(Icons.local_fire_department),
          label: 'Report Fire',
          tooltip: 'Report a fire emergency',
        ),
      ],
    );
  }

  /// Handle navigation destination selection
  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (_selectedIndex != 0) {
          context.go('/');
        }
        break;
      case 1:
        if (_selectedIndex != 1) {
          context.go('/map');
        }
        break;
      case 2:
        if (_selectedIndex != 2) {
          context.go('/report');
        }
        break;
    }
  }
}
