---
title: Integration Test Troubleshooting
status: active
last_updated: 2025-10-30
category: guides
subcategory: testing
related:
  - guides/testing/integration-tests.md
  - guides/testing/platform-specific.md
replaces:
  - ../../INTEGRATION_TEST_FIXES.md
  - ../../INTEGRATION_TEST_PUMP_STRATEGY.md
---

# Integration Test Troubleshooting

Comprehensive guide to debugging integration test failures and understanding pump strategies for GoogleMap widgets.

---

## Common Test Failures

### 1. GoogleMap Pump Strategy Issues

#### Problem: Tests Timeout After 2 Minutes
**Error**:
```
'package:flutter_test/src/binding.dart': Failed assertion: line 2156 pos 12: 
'_pendingFrame == null': is not true.
```

**Root Cause**: `pumpAndSettle()` waits for all animations to complete. GoogleMap continuously renders frames (camera movement, tile loading, marker animations), so `pumpAndSettle()` never completes within the 2-minute timeout.

#### Solution: Use `pump()` Instead of `pumpAndSettle()`

```dart
// ❌ WRONG: Waits indefinitely for GoogleMap animations to settle
await tester.pumpAndSettle(const Duration(seconds: 5));

// ✅ CORRECT: Fixed duration + single frame render
await tester.pump(const Duration(seconds: 5));
await tester.pump(); // Render one frame after delay
```

#### Why This Works

| Method | Behavior | Use Case |
|--------|----------|----------|
| `pumpAndSettle()` | Repeatedly calls `pump()` until **no frames** scheduled | Standard Flutter animations that **complete** (fade, slide) |
| `pump()` | Advances clock by duration, renders **exactly one frame** | Continuous rendering widgets like **GoogleMap** |

**Key Insight**: GoogleMap never stops scheduling frames (tile loading, camera animations), so `pumpAndSettle()` waits forever. Use `pump()` with fixed duration for map-related tests.

---

### 2. ErrorWidget.builder Modified During Tests

#### Problem: All Tests Fail with Global State Error
**Error**:
```
The value of ErrorWidget.builder was changed by the test.
```

**Root Cause**: Integration tests don't allow global state modifications. If your app modifies `ErrorWidget.builder` in `MaterialApp.builder`, tests will fail.

#### Solution: Remove Global Error Widget Modifications

```dart
// ❌ WRONG: Modifies global state (causes test failures)
MaterialApp(
  builder: (context, child) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(details); // Modifies global state
    };
    return child ?? const SizedBox.shrink();
  },
);

// ✅ CORRECT: Clean navigation wrapper (no global modifications)
MaterialApp(
  builder: (context, child) {
    return child ?? const SizedBox.shrink();
  },
);
```

**Files to Check**:
- `lib/app.dart` - Remove ErrorWidget.builder assignment
- `lib/main.dart` - Verify no global error handler modifications

---

### 3. iOS Swift Compilation Errors

#### Problem: iOS Builds Fail with API Label Error
**Error**:
```swift
Incorrect argument label in call (have 'forInfoPlistKey:', expected 'forInfoDictionaryKey:')
/ios/Runner/AppDelegate.swift:14:38
```

**Root Cause**: Apple renamed the API from `object(forInfoPlistKey:)` to `object(forInfoDictionaryKey:)` in newer iOS SDKs.

#### Solution: Update Swift Method Name

```swift
// ❌ WRONG: Old API (causes compilation error)
if let apiKey = Bundle.main.object(forInfoPlistKey: "GMSApiKey") as? String {
    GMSServices.provideAPIKey(apiKey)
}

// ✅ CORRECT: New API (works with current iOS SDK)
if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
    GMSServices.provideAPIKey(apiKey)
}
```

**File to Fix**: `ios/Runner/AppDelegate.swift` (line ~14)

---

### 4. Void Await Errors

#### Problem: Compilation Error on Lifecycle Methods
**Error**:
```dart
Error: This expression has type 'void' and can't be used.
await binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
```

**Root Cause**: `handleAppLifecycleStateChanged()` returns `void`, not `Future<void>`. It's a synchronous method that cannot be awaited.

#### Solution: Remove Await from Synchronous Methods

```dart
// ❌ WRONG: Can't await void methods
await binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
await binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

// ✅ CORRECT: Synchronous calls (no await)
binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
```

**Files to Check**:
- `integration_test/app_integration_test.dart` - Remove await from lifecycle calls

---

### 5. Widget Not Found Errors

#### Problem: Test Fails with "No element found"
**Error**:
```
Expected: exactly one matching node in the widget tree
Actual: _WidgetTypeFinder:<zero widgets with type "RiskBanner">
```

**Debugging Steps**:

1. **Print Widget Tree**:
```dart
await tester.pumpWidget(app);
await tester.pump();
debugDumpApp(); // Prints entire widget tree
```

2. **List All Text Widgets**:
```dart
final textWidgets = find.byType(Text).evaluate();
for (final widget in textWidgets) {
  print('Found text: ${(widget.widget as Text).data}');
}
```

3. **Check Widget Keys**:
```dart
// Verify key exists before tapping
expect(find.byKey(Key('home_tab')), findsOneWidget);
await tester.tap(find.byKey(Key('home_tab')));
```

4. **Add Strategic Delays**:
```dart
// Wait for async operations
await tester.pump(Duration(milliseconds: 100));
await tester.pump(); // Single frame render
```

---

## Pump Strategy Pattern Guide

### Pattern 1: Standard Flutter Widgets (Use `pumpAndSettle()`)

```dart
// Navigation, dialogs, standard animations
testWidgets('Navigate to home screen', (tester) async {
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(Key('home_tab')));
  await tester.pumpAndSettle(Duration(seconds: 2)); // ✅ Works for navigation
  
  expect(find.text('Fire Risk Assessment'), findsOneWidget);
});
```

**Use When**:
- Navigation animations
- Dialog open/close
- Standard widget animations (fade, slide)
- Widgets that eventually "settle" to a final state

### Pattern 2: GoogleMap Widgets (Use `pump()`)

```dart
// Map rendering, markers, camera movement
testWidgets('Map renders with markers', (tester) async {
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(Key('map_tab')));
  await tester.pump(Duration(seconds: 5)); // ✅ Fixed duration
  await tester.pump(); // ✅ Single frame render
  
  expect(find.byType(GoogleMap), findsOneWidget);
  expect(find.byType(Marker), findsAtLeast(1));
});
```

**Use When**:
- GoogleMap rendering
- Map markers or overlays
- Camera movements
- Any continuous rendering widget

### Pattern 3: Mixed Widgets (Combine Strategies)

```dart
// Navigate TO map (use pumpAndSettle), THEN wait for map (use pump)
testWidgets('Navigate to map and verify markers', (tester) async {
  await tester.pumpWidget(app);
  
  // Standard navigation (pumpAndSettle OK)
  await tester.tap(find.byKey(Key('map_tab')));
  await tester.pumpAndSettle(Duration(seconds: 2));
  
  // Map rendering (pump required)
  await tester.pump(Duration(seconds: 3));
  await tester.pump();
  
  expect(find.byType(GoogleMap), findsOneWidget);
});
```

**Use When**:
- Tests that navigate to map screen
- Tests that mix standard widgets and GoogleMap
- Complex multi-step interactions

---

## Test Environment Issues

### Emulator Performance Problems

**Symptoms**:
- Tests run slower than expected
- Inconsistent timing failures
- Memory warnings

**Solutions**:

1. **Use x86_64 Emulator Images** (faster than ARM):
```bash
# Check available images
flutter emulators

# Launch high-performance emulator
flutter emulators --launch Pixel_7_API_34
```

2. **Allocate More Resources**:
- RAM: 4GB+ recommended
- Storage: 8GB+ recommended
- Enable hardware acceleration in AVD settings

3. **Close Other Apps**:
```bash
# Free up system resources
# Close Chrome, VS Code debuggers, etc.
```

### Flutter Framework Issues

**Problem**: Tests fail after Flutter upgrade or package changes

**Solution**:

```bash
# Clean Flutter environment
flutter clean
flutter pub get
flutter pub deps

# Verify environment
flutter doctor -v

# Update Flutter (if needed)
flutter upgrade
flutter doctor --android-licenses
```

---

## Platform-Specific Issues

### Android

#### Missing API Key
**Problem**: Map shows but tiles don't load

**Solution**: Verify `android/app/build.gradle.kts` has manifestPlaceholders:
```kotlin
android {
    defaultConfig {
        manifestPlaceholders["GOOGLE_MAPS_API_KEY_ANDROID"] = 
            project.findProperty("dart.env.GOOGLE_MAPS_API_KEY_ANDROID") ?: "placeholder"
    }
}
```

#### StrictMode Violations
**Problem**: Warnings about main thread blocking

**Solution**: Ensure API calls use async/await, not blocking I/O

### iOS

#### Info.plist Missing Keys
**Problem**: App crashes on location request

**Solution**: Add location permissions to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show nearby wildfire risk.</string>
```

#### API Key Not Injected
**Problem**: Map renders but shows "For development purposes only" watermark

**Solution**: Verify Xcode Build Phase script runs before compilation (see `guides/setup/google-maps.md`)

### Web

#### CORS Blocking
**Problem**: API calls fail with CORS error

**Solution**: 
- Development: Run with `flutter run -d chrome` (localhost bypass)
- Production: Implement backend CORS proxy

#### Platform Guard Issues
**Problem**: Tests fail trying to access GPS on web

**Solution**: Add platform guards:
```dart
if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
  position = await Geolocator.getCurrentPosition();
} else {
  // Use default fallback on web
  return LatLng(57.2, -3.8);
}
```

---

## Test Isolation and State Management

### Clean State Between Tests

```dart
setUp(() async {
  // Reset app state
  SharedPreferences.setMockInitialValues({});
  
  // Reset mock services
  reset(mockFireRiskService);
  reset(mockLocationResolver);
  
  // Initialize test-specific state
  await tester.binding.setSurfaceSize(Size(400, 800)); // Consistent viewport
});

tearDown(() async {
  // Clean up test artifacts
  await tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter_test/integration_test', null
  );
});
```

### State Leakage Prevention

**Problem**: Tests pass individually but fail when run together

**Common Causes**:
1. SharedPreferences not reset between tests
2. Static variables holding state
3. Singleton services not reset
4. Mock responses not cleared

**Solution**: Use `setUp()` and `tearDown()` consistently

---

## Performance Debugging

### Measuring Test Execution Time

```dart
testWidgets('Map loads within 3s', (tester) async {
  final stopwatch = Stopwatch()..start();
  
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(Key('map_tab')));
  await tester.pump(Duration(seconds: 3));
  await tester.pump();
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(3000));
  print('✅ Map load time: ${stopwatch.elapsedMilliseconds}ms'); // gitleaks:allow
});
```

### Memory Leak Detection

```dart
testWidgets('No memory leaks during navigation', (tester) async {
  await tester.pumpWidget(app);
  
  // Navigate back and forth 10 times
  for (int i = 0; i < 10; i++) {
    await tester.tap(find.byKey(Key('map_tab')));
    await tester.pump(Duration(seconds: 1));
    
    await tester.tap(find.byKey(Key('home_tab')));
    await tester.pumpAndSettle(Duration(seconds: 1));
  }
  
  // Memory should be stable (check with Flutter DevTools)
});
```

---

## Quick Reference

### Test Failing? Check These First

1. ✅ **Using `pump()` for GoogleMap tests?**
2. ✅ **No global state modifications in app code?**
3. ✅ **iOS Swift API updated to `forInfoDictionaryKey`?**
4. ✅ **Not awaiting void methods?**
5. ✅ **Widget keys defined and correct?**
6. ✅ **SharedPreferences reset in `setUp()`?**
7. ✅ **Platform guards for web/desktop?**
8. ✅ **API keys configured correctly?**

### Quick Fixes

```bash
# Clean everything
flutter clean && flutter pub get

# Run single test for debugging
flutter test integration_test/home_integration_test.dart -d emulator-5554 --verbose

# Check for widget tree issues
flutter test --update-goldens # Updates golden files
```

---

## Related Documentation

- **[Integration Tests](integration-tests.md)** - Main testing guide
- **[Platform-Specific Testing](platform-specific.md)** - iOS, Android, Web setup
- **[Google Maps Setup](../setup/google-maps.md)** - API key configuration
