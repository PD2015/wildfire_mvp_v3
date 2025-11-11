# Test Specifications Contract

**Feature**: RiskBanner Visual Refresh  
**Contract Type**: Testing Requirements  
**Date**: 2025-11-02

## Golden Test Contract

### Required Golden Tests
```dart
// Light mode - all risk levels
testWidgets('RiskBanner golden - VeryLow light mode', (tester) async {
  // Golden test with VeryLow risk level, light theme
});

testWidgets('RiskBanner golden - Low light mode', (tester) async {
  // Golden test with Low risk level, light theme  
});

testWidgets('RiskBanner golden - Moderate light mode', (tester) async {
  // Golden test with Moderate risk level, light theme
});

testWidgets('RiskBanner golden - High light mode', (tester) async {
  // Golden test with High risk level, light theme
});

testWidgets('RiskBanner golden - VeryHigh light mode', (tester) async {
  // Golden test with VeryHigh risk level, light theme
});

testWidgets('RiskBanner golden - Extreme light mode', (tester) async {
  // Golden test with Extreme risk level, light theme
});

// Dark mode - representative test
testWidgets('RiskBanner golden - Moderate dark mode', (tester) async {
  // Golden test with Moderate risk level, dark theme
});
```

### Golden Test Data Requirements
- **Mock FireRisk Data**: Consistent test data for each risk level
- **Location Label**: "(55.95, -3.19)" for coordinate display tests
- **Cached Badge**: Test both with and without cached freshness
- **Weather Panel**: Test both enabled and disabled configurations

## Widget Test Contract

### Location Row Test Requirements
```dart
testWidgets('shows location row when locationLabel provided', (tester) async {
  // GIVEN: RiskBanner with locationLabel
  // WHEN: Widget is built
  // THEN: Location icon and text are visible
});

testWidgets('hides location row when locationLabel is null', (tester) async {
  // GIVEN: RiskBanner without locationLabel
  // WHEN: Widget is built  
  // THEN: Location row is not rendered
});
```

### Weather Panel Test Requirements
```dart
testWidgets('shows weather panel when config enabled', (tester) async {
  // GIVEN: RiskBanner with config.showWeatherPanel = true
  // WHEN: Widget is built
  // THEN: Weather panel with Temperature/Humidity/Wind columns visible
});

testWidgets('hides weather panel when config disabled or null', (tester) async {
  // GIVEN: RiskBanner with config.showWeatherPanel = false or null config
  // WHEN: Widget is built
  // THEN: Weather panel is not rendered
});
```

### Updated Existing Tests
```dart
// Tests to UPDATE (remove expectations for external elements)
testWidgets('existing risk level display tests', (tester) async {
  // UPDATE: Remove expectations for external source chip
  // PRESERVE: Risk level color and text verification
});

testWidgets('existing cached badge tests', (tester) async {
  // PRESERVE: CachedBadge visibility logic
  // UPDATE: Verify it appears within new banner container
});

testWidgets('existing error state tests', (tester) async {
  // PRESERVE: onRetry callback functionality
  // UPDATE: Verify new warning icons (not fire icons)
  // UPDATE: Verify error styling within Card container
});
```

## Accessibility Test Contract

### Touch Target Verification
```dart
testWidgets('maintains minimum 44dp touch targets', (tester) async {
  // GIVEN: RiskBanner with interactive elements
  // WHEN: Touch target sizes are measured
  // THEN: All targets are ≥ 44dp
});
```

### Semantic Label Verification  
```dart
testWidgets('preserves semantic labels for screen readers', (tester) async {
  // GIVEN: RiskBanner in various states
  // WHEN: Semantic properties are checked
  // THEN: All elements have appropriate labels
});
```

## Integration Test Contract

### HomeScreen Integration
```dart
// MINIMAL CHANGES EXPECTED - most integration tests should pass
testWidgets('home screen displays enhanced risk banner', (tester) async {
  // GIVEN: HomeScreen with fire risk data
  // WHEN: Screen is rendered
  // THEN: New RiskBanner style is visible
  // AND: External timestamp row is removed
});
```

## Test Data Contract

### Mock FireRisk Objects
```dart
// Standard test data for each risk level
final veryLowRisk = FireRisk(
  level: RiskLevel.veryLow,
  fwi: 2.5,
  source: DataSource.mock,
  // ... other required fields
);

// Similar objects for: low, moderate, high, veryHigh, extreme
```

### Location Test Data
```dart
const testLocationLabel = "(55.95, -3.19)";
const nullLocationLabel = null;
```

### Configuration Test Data
```dart  
const enabledWeatherConfig = RiskBannerConfig(showWeatherPanel: true);
const disabledWeatherConfig = RiskBannerConfig(showWeatherPanel: false);
const nullConfig = null;
```

## Test File Organization

### Golden Test Files
```
test/widget/golden/
├── risk_banner_very_low_light_test.dart
├── risk_banner_low_light_test.dart
├── risk_banner_moderate_light_test.dart
├── risk_banner_moderate_dark_test.dart
├── risk_banner_high_light_test.dart
├── risk_banner_very_high_light_test.dart
└── risk_banner_extreme_light_test.dart
```

### Golden Reference Images
```
test/goldens/risk_banner/
├── very_low_light.png
├── low_light.png
├── moderate_light.png
├── moderate_dark.png
├── high_light.png
├── very_high_light.png
└── extreme_light.png
```

### Updated Widget Tests
```
test/widget/
└── risk_banner_test.dart  # Updated with new test cases
```

## Regression Prevention

### Visual Regression
- Golden tests prevent unintended visual changes
- Cover all risk levels and both light/dark themes
- Include location row and weather panel variations

### Behavioral Regression
- Preserve all existing unit test coverage
- Verify existing functionality still works
- Add tests for new optional features

### Accessibility Regression
- Touch target verification remains enforced
- Semantic label coverage maintained
- Screen reader compatibility preserved