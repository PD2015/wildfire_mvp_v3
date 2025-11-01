---
title: Integration Testing Guide
status: active
last_updated: 2025-10-30
category: guides
subcategory: testing
related:
  - guides/testing/platform-specific.md
  - guides/testing/troubleshooting.md
  - reference/test-coverage.md
replaces:
  - ../../INTEGRATION_TESTING.md
  - ../../INTEGRATION_TEST_QUICKREF.md
  - ../../INTEGRATION_TEST_QUICKSTART.md
---

# Integration Testing Guide

**TL;DR**: 16/24 tests passing. Map tests require manual verification due to GoogleMap framework incompatibility.

---

## 🚀 Quick Start

### Prerequisites
- Android emulator running: `emulator-5554` (recommended)
- Environment file: `env/dev.env.json` with API keys
- Flutter SDK 3.0+ with integration test support

### Quick Commands

```bash
# Run all integration tests (11 minutes)
flutter test integration_test/ -d emulator-5554

# Run specific test suites
flutter test integration_test/home_integration_test.dart -d emulator-5554    # 7/9 passing
flutter test integration_test/app_integration_test.dart -d emulator-5554     # 9/9 passing ✅
flutter test integration_test/map_integration_test.dart -d emulator-5554     # Skipped (manual testing)

# Manual map testing (interactive)
flutter run -d emulator-5554 --dart-define=MAP_LIVE_DATA=false
# Then follow interactive testing checklist in archived sessions
```

### Test Status at a Glance

| Suite | Status | Pass/Total | Duration |
|-------|--------|------------|----------|
| Home | ⚠️ Partial | 7/9 (78%) | ~5 min |
| Map | ⏭️ Skipped | 0/8 (manual) | ~2 min manual |
| App | ✅ Pass | 9/9 (100%) | ~4 min |
| **Total** | 🟡 Good | **16/24** | **~11 min + manual** |

---

## 📋 Test Architecture

### Test Suite Structure

```
integration_test/
├── home_integration_test.dart    # 9 tests - Home screen workflows
├── map_integration_test.dart     # 8 tests - Map functionality (manual)
└── app_integration_test.dart     # 9 tests - Navigation and lifecycle
```

### Test Categories

#### 1. **Home Screen Tests** (9 tests)
- ✅ Fire risk banner display and color validation
- ✅ Location resolution (GPS, cache, fallback)
- ✅ C4 transparency compliance (timestamp, source indicators)
- ⚠️ UI visibility issues (2 failing tests - timestamp and source chip not found)

#### 2. **Map Tests** (8 tests) 
- ⏭️ **Skipped in automation** due to GoogleMap framework incompatibility
- 🔍 **Manual testing required** with interactive verification
- ✅ Map rendering, markers, navigation, zoom controls

#### 3. **App Navigation Tests** (9 tests)
- ✅ Tab navigation (Home ↔ Map)
- ✅ App lifecycle (background/foreground)
- ✅ Deep linking and route handling
- ✅ Error state recovery

---

## 🛠️ Testing Methodology

### GoogleMap Testing Strategy

**Challenge**: GoogleMap widgets are incompatible with Flutter's `integration_test` framework due to continuous frame rendering.

**Solution**: Hybrid approach combining automated and manual testing.

#### Automated Testing (Standard Flutter Widgets)
```dart
// Works well with pumpAndSettle()
await tester.tap(find.byKey(Key('home_tab')));
await tester.pumpAndSettle(Duration(seconds: 2));
expect(find.text('Fire Risk Assessment'), findsOneWidget);
```

#### Manual Testing (GoogleMap Widgets) 
```dart
// GoogleMap tests are skipped in automation
testWidgets('Map renders with fire markers', (tester) async {
  // Test implementation exists but marked as skip: true
  // Requires manual verification following checklist
}, skip: true); // ← Framework incompatibility
```

### Pump Strategy for Maps

**Problem**: `pumpAndSettle()` waits indefinitely for GoogleMap animations to complete (camera movement, tile loading, marker animations never settle).

**Solution**: Use fixed-duration `pump()` instead of `pumpAndSettle()`:

```dart
// ❌ WRONG: Waits indefinitely (times out after 2 minutes)
await tester.pumpAndSettle(const Duration(seconds: 5));

// ✅ CORRECT: Fixed duration + single frame
await tester.pump(const Duration(seconds: 5));
await tester.pump(); // Render one frame after delay
```

**Why This Works**:
- `pumpAndSettle()`: Waits until NO frames are scheduled (never happens with GoogleMap)
- `pump()`: Advances clock by duration, renders exactly one frame
- Perfect for continuous rendering widgets like maps

**Related**: See `guides/testing/troubleshooting.md` for detailed pump strategy analysis.

---

## 🔧 Technical Implementation

### Test Environment Setup

#### Device Configuration
```bash
# Recommended: Android emulator for consistent testing
flutter emulators --launch Pixel_7_API_34

# Alternative: Physical device (may have timing variations)
flutter devices
flutter test integration_test/ -d <device_id>
```

#### Environment Variables
```json
{
  "MAP_LIVE_DATA": "false",
  "GOOGLE_MAPS_API_KEY_ANDROID": "your_key_here",
  "GOOGLE_MAPS_API_KEY_IOS": "your_key_here"
}
```

**Testing Modes**:
- `MAP_LIVE_DATA=false`: Uses mock fire data (fast, consistent)
- `MAP_LIVE_DATA=true`: Uses live EFFIS data (variable timing, real network conditions)

### Widget Finding Strategies

#### Key-Based Selection (Recommended)
```dart
// Reliable across UI changes
await tester.tap(find.byKey(Key('map_tab')));
await tester.tap(find.byKey(Key('retry_button')));
await tester.tap(find.byKey(Key('set_location_button')));
```

#### Text-Based Selection (Fragile)
```dart
// Can break with localization or UI text changes
await tester.tap(find.text('Retry'));           // ⚠️ Fragile
await tester.tap(find.byKey(Key('retry_button'))); // ✅ Robust
```

#### Semantic Selection (Accessibility)
```dart
// Best for accessibility compliance
await tester.tap(find.bySemanticsLabel('Navigate to map'));
await tester.tap(find.bySemanticsLabel('Retry fire risk data'));
```

### Error Handling in Tests

#### Global Error Widget Handling
**Issue**: Integration tests fail if app modifies global `ErrorWidget.builder`.

**Solution**: Avoid global state modifications in app code:
```dart
// ❌ WRONG: Causes integration test failures
MaterialApp(
  builder: (context, child) {
    ErrorWidget.builder = (details) => CustomError(); // Modifies global state
    return child;
  },
);

// ✅ CORRECT: Clean navigation wrapper
MaterialApp(
  builder: (context, child) {
    return child ?? const SizedBox.shrink(); // No global modifications
  },
);
```

#### Test-Specific Error Handling
```dart
testWidgets('Handles service timeout gracefully', (tester) async {
  // Simulate network timeout
  when(mockService.getFwi(any, any)).thenThrow(TimeoutException());
  
  await tester.pumpWidget(app);
  await tester.pump(Duration(seconds: 10)); // Wait for error state
  
  expect(find.text('Request timed out'), findsOneWidget);
  expect(find.byKey(Key('retry_button')), findsOneWidget);
});
```

---

## 📊 Performance Considerations

### Test Execution Times
- **Home tests**: ~5 minutes (includes service timeouts)
- **App tests**: ~4 minutes (navigation only)
- **Map tests**: ~2 minutes manual verification
- **Total**: ~11 minutes automated + manual verification

### Optimization Strategies

#### Parallel Test Execution
```bash
# Run test suites in parallel (separate terminals)
flutter test integration_test/home_integration_test.dart -d emulator-5554 &
flutter test integration_test/app_integration_test.dart -d emulator-5556 &
wait
```

#### Mock Data for Speed
```dart
// Fast, consistent results
await tester.binding.defaultBinaryMessenger.setMockMessageHandler(
  'flutter_test/integration_test',
  (message) async {
    return mockFireRiskData.toJson(); // Instant response
  },
);
```

#### Timeout Optimization
```dart
// Adjust timeouts based on test type
const Duration shortTimeout = Duration(seconds: 2);  // UI interactions
const Duration mediumTimeout = Duration(seconds: 5); // Service calls
const Duration longTimeout = Duration(seconds: 10);  // Error recovery
```

---

## 🔍 Debugging Integration Tests

### Common Test Failures

#### "Widget not found" Errors
```dart
// Debug: Print widget tree
await tester.pumpWidget(app);
await tester.pump();
print(find.byType(MaterialApp).evaluate().first.widget);

// Debug: List all visible text
final textWidgets = find.byType(Text).evaluate();
for (final widget in textWidgets) {
  print('Found text: ${(widget.widget as Text).data}');
}
```

#### Timing Issues
```dart
// Add strategic delays for async operations
await tester.pump(Duration(milliseconds: 100)); // Short delay
await tester.pump(); // Single frame render

// Or use pumpAndSettle for non-map widgets
await tester.pumpAndSettle(Duration(seconds: 2));
```

#### State Issues
```dart
// Verify widget state before interaction
expect(find.byKey(Key('home_tab')), findsOneWidget);
await tester.tap(find.byKey(Key('home_tab')));
await tester.pump();
// Verify state after interaction
expect(find.text('Fire Risk Assessment'), findsOneWidget);
```

### Test Isolation

#### Clean State Between Tests
```dart
setUp(() async {
  // Reset app state
  SharedPreferences.setMockInitialValues({});
  
  // Reset mock services
  reset(mockFireRiskService);
  reset(mockLocationResolver);
});

tearDown(() async {
  // Clean up test artifacts
  await tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter_test/integration_test', null
  );
});
```

---

## 🚀 CI/CD Integration

### GitHub Actions Configuration
```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration_test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.0.0'
          
      - name: Launch Android Emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          script: |
            flutter test integration_test/ -d emulator-5554 \
              --dart-define-from-file=env/ci.env.json
```

### CI Environment Setup
```json
{
  "MAP_LIVE_DATA": "false",
  "GOOGLE_MAPS_API_KEY_ANDROID": "placeholder_for_ci",
  "GOOGLE_MAPS_API_KEY_IOS": "placeholder_for_ci"
}
```

**CI Benefits**:
- ✅ **Consistent environment**: All tests run with mock data
- ✅ **Fast execution**: No external API dependencies
- ✅ **Reliable results**: No network variability
- ⏭️ **Map tests skipped**: Manual verification in development

---

## 📚 Best Practices

### Test Organization
- ✅ **Group related tests**: Use `group()` for logical test grouping
- ✅ **Descriptive names**: Test names explain behavior and requirements
- ✅ **Key-based selectors**: Use `Key()` widgets for reliable element finding
- ✅ **Semantic labels**: Support accessibility testing with semantic labels

### Error Recovery Testing
- ✅ **Network timeouts**: Test service timeout scenarios (8s EFFIS timeout)
- ✅ **Permission denied**: Test GPS permission failure graceful handling
- ✅ **Service failures**: Test fallback chain (EFFIS → Cache → Mock)
- ✅ **UI recovery**: Test retry button functionality and state reset

### Constitutional Compliance (C4)
- ✅ **Transparency indicators**: Test timestamp and source chip visibility
- ✅ **Demo data labeling**: Test "DEMO DATA" chip in mock mode
- ✅ **Accessibility**: Test screen reader support with semantic labels
- ✅ **Error messaging**: Test clear, actionable error messages

---

## ❌ Known Issues

### 2 Home Tests Failing (UI visibility)
**Issue**: Timestamp and source chip not found in RiskBanner widget  
**Status**: Investigation needed  
**Workaround**: Manual verification confirms UI elements are present  
**Fix needed**: Update RiskBanner widget structure or test selectors

### 8 Map Tests Skipped (framework limitation)
**Issue**: GoogleMap incompatible with Flutter integration_test framework  
**Status**: By design - continuous frame rendering breaks test assumptions  
**Solution**: Manual testing required (see archived session docs)  
**Alternative**: Consider external E2E framework (Patrol, Maestro, Appium) for full automation

---

## 🔗 Before Release Checklist

```
[ ] All automated tests passing (16/16 non-map)
[ ] Manual map testing complete (8/8 tests)
[ ] Platform-specific testing verified (see platform-specific.md)
[ ] QA sign-off obtained
```

---

## 📖 References

### Flutter Documentation
- [Integration Testing](https://docs.flutter.dev/cookbook/testing/integration/introduction)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Testing Best Practices](https://docs.flutter.dev/testing)

### Project Documentation
- **[Platform-Specific Testing](platform-specific.md)** - iOS, Android, Web, macOS test procedures
- **[Troubleshooting](troubleshooting.md)** - Detailed debugging guide and pump strategy analysis
- **[Test Coverage](../../reference/test-coverage.md)** - Coverage metrics and reports

### Development Tools
- [Android Emulator](https://developer.android.com/studio/run/emulator)
- [iOS Simulator](https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator-or-on-a-device)
- [Flutter Inspector](https://docs.flutter.dev/development/tools/flutter-inspector)

---

## 🤔 FAQ

**Q: Why are map tests skipped?**  
A: GoogleMap continuously renders frames, breaking test framework assumptions. `pumpAndSettle()` waits indefinitely because animations never "settle".

**Q: Can we fix map tests?**  
A: No, not with Flutter's built-in `integration_test`. Requires external E2E framework (Patrol, Maestro, Appium).

**Q: Is manual testing sufficient?**  
A: Yes, map functionality is fully testable manually. Follow archived testing session checklists.

**Q: When to run manual tests?**  
A: Before every release, when map code changes, or when GoogleMap dependency updates.

**Q: Why use `pump()` instead of `pumpAndSettle()`?**  
A: `pumpAndSettle()` waits for animations to complete. GoogleMap never stops scheduling frames, so tests timeout. `pump()` advances time without waiting for animations to settle.
