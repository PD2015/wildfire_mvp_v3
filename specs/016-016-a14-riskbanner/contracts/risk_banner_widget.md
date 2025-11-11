# RiskBanner Widget Contract

**Feature**: RiskBanner Visual Refresh  
**Contract Type**: Widget Interface  
**Date**: 2025-11-02

## Widget Interface

### Constructor Contract
```dart
class RiskBanner extends StatelessWidget {
  const RiskBanner({
    super.key,
    required this.fireRisk,
    this.onRetry,
    this.locationLabel,    // NEW: Optional coordinate display
    this.config,           // NEW: Optional configuration
  });

  final FireRisk fireRisk;
  final VoidCallback? onRetry;
  final String? locationLabel;           // NEW
  final RiskBannerConfig? config;        // NEW
}
```

### RiskBannerConfig Contract
```dart
class RiskBannerConfig {
  const RiskBannerConfig({
    this.showWeatherPanel = false,  // Default disabled
  });

  final bool showWeatherPanel;
}
```

## Visual Contract

### Success State Requirements
- **Container**: Material Card with 16dp corner radius, 16dp padding, elevation 2
- **Background**: Preserve existing RiskPalette color mapping
- **Title**: "Wildfire Risk: {LEVEL}" (preserved)
- **Location Row** (conditional):
  - Icon: Icons.location_on
  - Text: locationLabel value (e.g., "(55.95, -3.19)")
  - Visibility: Only when locationLabel is not null
- **Timestamp**: Internal display of relative time (moved from external row)
- **Data Source**: "Data Source: {EFFIS|SEPA|Cache|Mock}" as plain text
- **Cached Badge**: Preserve when fireRisk.freshness == Freshness.cached

### Loading State Requirements
- **Container**: Same Card styling as success state
- **Content**: CircularProgressIndicator with loading text
- **Semantics**: Preserve accessibility labels for loading state

### Error State Requirements  
- **Container**: Same Card styling as success state
- **Icon**: Icons.warning_amber_rounded or Icons.error_outline_rounded
- **Action**: Preserve onRetry functionality when provided
- **Semantics**: Clear error state accessibility

### Weather Panel Requirements (Optional)
- **Visibility**: Only when config?.showWeatherPanel == true
- **Container**: Nested rounded sub-card (8dp radius, 8dp padding)
- **Layout**: Three columns: Temperature | Humidity | Wind Speed
- **Content**: Placeholder labels and values (no live data)

## Behavioral Contract

### Parameter Handling
- **fireRisk**: Required - existing behavior preserved
- **onRetry**: Optional - existing behavior preserved  
- **locationLabel**: Optional - null means no location row displayed
- **config**: Optional - null defaults to all features disabled

### State Transitions
```
fireRisk.freshness:
  live/stale -> Normal display with all elements
  cached -> Normal display + CachedBadge overlay
  error -> Error state with warning icon + onRetry (if provided)

locationLabel:
  null -> No location row rendered
  string -> Location row with pin icon + formatted text

config.showWeatherPanel:
  true -> Weather panel rendered below main content
  false/null -> No weather panel
```

### Accessibility Contract
- **Touch Targets**: Minimum 44dp for all interactive elements
- **Semantics**: Preserve all existing semantic labels
- **Screen Reader**: Banner content readable as cohesive unit
- **Focus Order**: Logical top-to-bottom reading order

## Integration Contract

### HomeScreen Integration
```dart
// BEFORE (external timestamp row)
RiskBanner(fireRisk: riskData, onRetry: _handleRetry)
// + separate timestamp/source widgets

// AFTER (internal display)
RiskBanner(
  fireRisk: riskData,
  onRetry: _handleRetry, 
  locationLabel: _formatCoordinates(lat, lon),  // NEW
  config: RiskBannerConfig(),                   // NEW (optional)
)
// External timestamp/source rows removed
```

### Testing Contract
- **Golden Tests**: Visual regression prevention for all risk levels
- **Widget Tests**: Verify location row conditional rendering
- **Unit Tests**: Preserve existing logic test coverage
- **Accessibility Tests**: Verify semantic labels and touch targets

## Breaking Changes: None
- All existing constructor calls remain valid
- New parameters have sensible defaults
- Existing behavior preserved when new parameters not provided

## Performance Contract
- **Rendering**: No additional complexity beyond current implementation
- **Memory**: Minimal increase for configuration object
- **Animations**: Preserve any existing animation performance
- **Golden Tests**: Ensure no layout thrashing or excessive rebuilds