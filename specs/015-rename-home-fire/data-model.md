# Data Model: Rename Home → Fire Risk Screen and Update Navigation Icon

**Feature**: 015-rename-home-fire  
**Date**: 2025-11-01  
**Status**: Complete

## UI Configuration Entities

### NavigationItem
Represents a bottom navigation tab configuration.

**Current Model**:
```dart
NavigationItem(
  icon: Icons.home,
  label: "Home",
  route: "/",
  semanticLabel: "Home tab"
)
```

**Target Model**:
```dart
NavigationItem(
  icon: Icons.warning_amber,
  label: "Fire Risk", 
  route: "/",
  semanticLabel: "Fire risk information tab"
)
```

**Validation Rules**:
- Icon must be valid Material Design IconData
- Label must be ≤15 characters for bottom navigation display
- Route must be valid go_router path starting with "/"
- Semantic label must be descriptive ≥10 characters for accessibility

### ScreenConfiguration
Represents screen-level display configuration.

**Current Model**:
```dart
ScreenConfiguration(
  title: "Home",
  route: "/",
  appBarTitle: "Home"
)
```

**Target Model**:
```dart
ScreenConfiguration(
  title: "Fire Risk",
  route: "/", 
  appBarTitle: "Wildfire Risk"
)
```

**Business Rules**:
- Title used in navigation context (bottom nav label)
- AppBar title can be longer/more descriptive than navigation title
- Route remains "/" for backward compatibility

## Route Configuration Entities

### RouteDefinition
Represents go_router route mapping configuration.

**Current Routes**:
```dart
RouteDefinition(
  path: "/",
  screen: HomeScreen,
  name: "home"
)
```

**Target Routes**:
```dart
[
  RouteDefinition(
    path: "/",
    screen: FireRiskScreen, // same implementation as HomeScreen
    name: "fire-risk"
  ),
  RouteDefinition(
    path: "/fire-risk", 
    screen: FireRiskScreen, // alias to same screen
    name: "fire-risk-alias"
  )
]
```

**Migration Rules**:
- Primary route "/" points to FireRiskScreen (renamed destination)
- Alias route "/fire-risk" points to same screen for semantic clarity
- Route names updated to reflect fire risk purpose
- No breaking changes to existing navigation state

### DeepLinkCompatibility
Handles backward compatibility for existing bookmarks and saved navigation.

**Compatibility Matrix**:
- "/" → FireRiskScreen (unchanged path, updated destination)
- "/home" → Redirect to "/" (if exists, preserve compatibility)
- "/fire-risk" → FireRiskScreen (new semantic alias)

**State Preservation**:
- Navigation stack history maintained
- Browser back/forward buttons work unchanged
- Bookmarked URLs continue to function

## Accessibility Entities

### SemanticConfiguration
Screen reader and accessibility configuration.

**Current Semantics**:
```dart
SemanticConfiguration(
  screenTitle: "Home",
  navigationLabel: "Home tab",
  description: "Main screen"
)
```

**Target Semantics**:
```dart
SemanticConfiguration(
  screenTitle: "Wildfire Risk",
  navigationLabel: "Fire risk information tab", 
  description: "Current wildfire risk is {LEVEL}, updated {RELATIVE_TIME}. Source: {SOURCE}.",
  iconDescription: "Warning symbol indicating fire risk information"
)
```

**Dynamic Content Rules**:
- {LEVEL} replaced with current risk level (e.g., "Low", "High")
- {RELATIVE_TIME} replaced with human-readable timestamp (e.g., "2 hours ago")
- {SOURCE} replaced with data source (e.g., "EFFIS", "SEPA", "Cache")
- Description updates automatically when risk data changes

### IconAccessibility
Accessibility configuration for warning icon.

**Properties**:
- `iconData: Icons.warning_amber`
- `semanticLabel: "Warning symbol"`
- `tooltip: "Fire risk warning"`
- `isInteractive: true`
- `minimumTouchTarget: 44dp`

**Validation Rules**:
- Touch target must be ≥44dp for accessibility compliance
- Semantic label must convey icon meaning without visual context
- Tooltip provides additional context on hover/long press
- Interactive state clearly indicated for assistive technologies

## Theme Integration Entities

### UIConstants
Centralized constants for consistent theming.

**Current Constants**:
```dart
class UIConstants {
  static const String homeTitle = "Home";
  static const IconData homeIcon = Icons.home;
  static const String homeRoute = "/";
}
```

**Target Constants**:
```dart
class UIConstants {
  static const String fireRiskTitle = "Fire Risk";
  static const String fireRiskAppBarTitle = "Wildfire Risk";
  static const IconData fireRiskIcon = Icons.warning_amber;
  static const IconData fireRiskIconFallback = Icons.report_outlined;
  static const String fireRiskRoute = "/";
  static const String fireRiskRouteAlias = "/fire-risk";
  
  // Semantic labels
  static const String fireRiskNavSemantic = "Fire risk information tab";
  static const String fireRiskScreenSemantic = "Current wildfire risk is {LEVEL}, updated {RELATIVE_TIME}. Source: {SOURCE}.";
}
```

**Migration Strategy**:
- Preserve old constants as `@deprecated` for Phase 2 class renaming
- New constants follow consistent naming pattern
- Fallback icon available if primary icon has rendering issues

## State Management Entities

### NavigationState
Represents current navigation state and selected tab.

**Model (Unchanged)**:
```dart
NavigationState(
  currentRoute: String,
  selectedIndex: int,
  navigationHistory: List<String>
)
```

**Business Rules**:
- State management logic unchanged
- Route values updated but state structure preserved
- Navigation history maintains backward compatibility

### ScreenState
Represents fire risk screen state (previously HomeState).

**Current Model (lib/models/home_state.dart)**:
```dart
class HomeState {
  final FireRisk? currentRisk;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
}
```

**Future Model (Phase 2 - Optional)**:
```dart
class FireRiskScreenState { // Renamed for clarity
  final FireRisk? currentRisk;
  final bool isLoading; 
  final String? error;
  final DateTime? lastUpdated;
}
```

**Migration Notes**:
- Phase 1: Keep existing HomeState class, update UI only
- Phase 2: Optionally rename class with mechanical refactor
- Data structure and business logic unchanged

## Testing Data Models

### NavigationTestData
Test fixtures for navigation component testing.

**Widget Test Data**:
```dart
final testNavigationItem = NavigationItem(
  icon: Icons.warning_amber,
  label: "Fire Risk",
  route: "/",
  semanticLabel: "Fire risk information tab"
);

final testScreenConfig = ScreenConfiguration(
  title: "Fire Risk",
  appBarTitle: "Wildfire Risk"
);
```

**Route Test Data**:
```dart
final testRoutes = [
  '/' -> FireRiskScreen,
  '/fire-risk' -> FireRiskScreen
];

final testNavigationScenarios = [
  'Direct navigation to /',
  'Deep link to /fire-risk',
  'Browser back/forward navigation',
  'Bookmark restoration'
];
```

**Accessibility Test Data**:
```dart
final testSemanticLabels = [
  'Fire risk information tab',
  'Current wildfire risk is Low, updated 2 hours ago. Source: EFFIS.',
  'Warning symbol indicating fire risk information'
];
```

## Error Handling Models

### NavigationError  
Error states for navigation and routing issues.

**Error Types**:
- `routeNotFound`: Invalid route navigation
- `iconRenderFailure`: Material icon display issue
- `semanticConfigError`: Accessibility setup problem
- `deepLinkInvalid`: Malformed bookmark or saved URL

**Recovery Strategies**:
- Route fallback to primary "/" path
- Icon fallback to Icons.report_outlined
- Semantic fallback to basic "Fire Risk" label
- Deep link redirect to main screen with error logging

---

**Data Model Validation**: All entities align with existing Flutter patterns, maintain backward compatibility, and support constitutional requirements. No breaking changes to core data structures or business logic.