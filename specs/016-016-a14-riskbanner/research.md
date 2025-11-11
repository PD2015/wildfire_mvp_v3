# Research: RiskBanner Visual Refresh

**Feature**: RiskBanner Visual Refresh  
**Date**: 2025-11-02  
**Status**: Complete

## Design Decisions

### Decision: Material Design Card Container
**Rationale**: Use Material Design Card/Container with elevation for professional, platform-consistent appearance that works across iOS/Android/Web
**Alternatives considered**: 
- Custom painted container (rejected - unnecessary complexity)
- Simple Container with BoxDecoration (rejected - lacks proper elevation shadows)
- Existing banner styling (rejected - doesn't meet 16dp radius/elevation requirements)

### Decision: Local Styling Constants
**Rationale**: Define banner-specific constants (kBannerRadius, kBannerPadding, kBannerElevation) to avoid global theme side effects while maintaining consistency
**Alternatives considered**:
- Global theme updates (rejected - could affect other widgets)
- Hardcoded values (rejected - not maintainable)
- Theme extensions (rejected - overkill for single widget)

### Decision: Icons.location_on for Location Display
**Rationale**: Standard Material Design location pin icon, universally recognized, good semantic meaning
**Alternatives considered**:
- Custom location icon (rejected - unnecessary asset)
- Icons.place (rejected - less specific than location_on)
- Text-only coordinates (rejected - less visual hierarchy)

### Decision: RiskBannerConfig Class for Feature Flags
**Rationale**: Clean separation of concerns, allows weather panel to be scaffolded but disabled, future extensibility
**Alternatives considered**:
- Global feature flags (rejected - couples banner to app-wide config)
- Constructor parameters (rejected - would require changes up the widget tree)
- Hardcoded disabled (rejected - not configurable for future use)

### Decision: warning_amber_rounded for Error State
**Rationale**: Clear, non-threatening error indication, follows Material Design patterns, avoids fire iconography that could cause confusion with actual fire risk
**Alternatives considered**:
- Icons.error_outline (alternative - also acceptable)
- Icons.local_fire_department (rejected - could confuse with actual fire risk)
- Icons.warning (rejected - less rounded, harsher appearance)

## Technical Approach

### Widget Architecture
- Maintain existing StatelessWidget structure
- Add optional `locationLabel` parameter for coordinate display
- Add `config` parameter for RiskBannerConfig
- Preserve all existing parameters (fireRisk, onRetry, etc.)

### Styling Implementation
```dart
// Local constants (not global theme)
const double kBannerRadius = 16.0;
const EdgeInsets kBannerPadding = EdgeInsets.all(16.0);
const double kBannerElevation = 2.0;
```

### State-Specific Rendering
- **Success State**: Card with risk-appropriate background, location row, timestamp, data source, cached badge
- **Loading State**: Same card styling with CircularProgressIndicator, preserved semantics
- **Error State**: Same card styling with warning icon, onRetry functionality

### Weather Panel Scaffolding
- Nested Container/Card inside main banner when config.showWeatherPanel == true
- Three-column layout: Temperature | Humidity | Wind Speed
- Placeholder values and styling ready for future service integration
- Default disabled (showWeatherPanel: false)

## Testing Strategy

### Golden Test Coverage
- One golden per risk level (VeryLow, Low, Moderate, High, VeryHigh, Extreme) in light mode
- One dark mode golden (Moderate level as representative)
- Focus on visual regression prevention

### Widget Test Updates
- Preserve existing logic tests (risk level display, cached badge, etc.)
- Add location row visibility test when locationLabel provided
- Add weather panel visibility test when config enabled
- Update any tests that previously relied on external source chip

### Integration Considerations
- No integration test changes needed (UI-only refresh)
- Existing home screen integration tests should pass with minimal updates

## Dependencies Analysis

### Existing Dependencies (preserved)
- Flutter Material Design widgets
- RiskPalette (colors unchanged)
- CachedBadge widget (preserved)
- FireRisk model (unchanged)

### New Dependencies (minimal)
- None - using existing Material Design icons and widgets

## Risk Mitigation

### Visual Regression Prevention
- Comprehensive golden test suite
- Side-by-side comparison during development
- Multiple device/theme testing

### Accessibility Preservation
- Touch target verification (≥44dp maintained)
- Semantic label preservation
- Screen reader testing approach

### Performance Considerations
- No additional rendering complexity
- Existing widget performance preserved
- Golden tests ensure no layout thrashing

## Implementation Order
1. Define local styling constants
2. Update success state with new Card container
3. Add location row with conditional rendering
4. Move timestamp and data source inside banner
5. Add RiskBannerConfig and weather panel scaffolding
6. Update loading and error states with consistent styling
7. Create comprehensive golden test suite
8. Update existing widget tests for new expectations