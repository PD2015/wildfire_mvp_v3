# Integration Tests

Integration tests for WildFire MVP that run on real devices/emulators with full platform support (Google Maps, GPS, etc.).

## Running Integration Tests

Integration tests **require a real device or emulator** because they test platform-specific features like Google Maps and location services.

### Prerequisites

1. **Device/Emulator Running**:
   ```bash
   # Check available devices
   flutter devices
   
   # Start emulator (if needed)
   flutter emulators --launch <emulator-id>
   ```

2. **API Key Configured**:
   - Ensure `env/dev.env.json` has valid `GOOGLE_MAPS_API_KEY_WEB` (or platform-specific keys)
   - For Android: `android/app/src/main/AndroidManifest.xml` must have API key
   - For iOS: `ios/Runner/AppDelegate.swift` must have API key

### Run All Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test/ -d <device-id>

# Example: Run on Chrome (web)
flutter test integration_test/ -d chrome

# Example: Run on Android emulator
flutter test integration_test/ -d emulator-5554

# Example: Run on iPhone simulator
flutter test integration_test/ -d iPhone
```

### Run Specific Test File

```bash
# Map integration tests
flutter test integration_test/map_integration_test.dart -d <device-id>

# Home screen integration tests
flutter test integration_test/home_integration_test.dart -d <device-id>
```

### Run with Verbose Output

```bash
flutter test integration_test/ -d <device-id> --verbose
```

## Test Structure

```
integration_test/
├── README.md                      # This file
├── map_integration_test.dart      # Google Maps rendering, markers, interactions
├── home_integration_test.dart     # Home screen with real location services
└── app_integration_test.dart      # Full app navigation flows
```

## What Integration Tests Verify

### Map Integration Tests (`map_integration_test.dart`)
- ✅ GoogleMap widget renders on device
- ✅ Fire incident markers appear on map
- ✅ Map camera can be moved (pan/zoom)
- ✅ Markers are interactive (tap shows info)
- ✅ "Check risk here" FAB works
- ✅ Source chip displays correct data source
- ✅ Performance: Map loads within 3s
- ✅ C3 Accessibility: Touch targets ≥44dp
- ✅ C4 Transparency: Source and timestamp visible

### Home Integration Tests (`home_integration_test.dart`)
- ✅ Real GPS location resolution (if permissions granted)
- ✅ Manual location entry dialog works
- ✅ Fire risk banner displays correctly
- ✅ Risk level colors match FWI thresholds
- ✅ Timestamp shows relative time
- ✅ Retry button works after errors
- ✅ C2 Privacy: Coordinates are redacted in logs
- ✅ C3 Accessibility: All touch targets meet minimums

### App Integration Tests (`app_integration_test.dart`)
- ✅ Navigation between Home and Map screens
- ✅ State persistence across navigation
- ✅ Deep linking works
- ✅ Back button behavior
- ✅ App lifecycle (resume from background)

## Differences from Unit/Widget Tests

| Aspect | Unit/Widget Tests | Integration Tests |
|--------|------------------|-------------------|
| **Environment** | `flutter test` (VM) | `flutter test -d <device>` (Real device/emulator) |
| **Google Maps** | ❌ Not available (no platform channels) | ✅ Full GoogleMap widget support |
| **GPS/Location** | ❌ Mocked | ✅ Can test real GPS (with permissions) |
| **Speed** | 🚀 Fast (~10s for full suite) | 🐢 Slower (~2-5min depending on device) |
| **Purpose** | Logic correctness | UI/UX on real hardware |
| **CI/CD** | ✅ Runs in headless CI | ⚠️ Requires emulator in CI |

## CI/CD Integration

For GitHub Actions or other CI systems:

```yaml
# .github/workflows/integration_tests.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-test-android:
    runs-on: macos-latest  # macOS has Android emulator support
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Start Android Emulator
        run: |
          flutter emulators --launch <emulator-id>
      - name: Run Integration Tests
        run: flutter test integration_test/ -d emulator-5554
```

## Troubleshooting

### "No devices found"
```bash
# Check connected devices
flutter devices

# For web testing
flutter devices  # Should show Chrome

# For mobile testing, start emulator first
flutter emulators
flutter emulators --launch <emulator-id>
```

### "GoogleMap not rendering"
- **Check API key**: Ensure API key is configured for the platform (Android/iOS/Web)
- **Check restrictions**: Verify API key restrictions allow your package name
- **Check platform support**: macOS Desktop does NOT support GoogleMap (use web or mobile)

### "Integration test hangs"
- **Increase timeout**: Add `timeout: Timeout(Duration(minutes: 5))` to tests
- **Check device connectivity**: Ensure device is responsive (`adb devices` for Android)
- **Use verbose logging**: `flutter test integration_test/ -d <device> --verbose`

### "Permission errors for GPS"
- Integration tests may prompt for location permissions on first run
- Grant permissions manually or use platform-specific permission automation

## Performance Baselines

Expected integration test execution times:

| Platform | Map Integration Test | Home Integration Test | Full Suite |
|----------|---------------------|----------------------|------------|
| Chrome (web) | ~30s | ~20s | ~1min |
| Android emulator | ~60s | ~40s | ~2min |
| iOS simulator | ~50s | ~35s | ~2min |
| Physical device | ~40s | ~30s | ~90s |

## Best Practices

1. **Run locally before commit**: `flutter test integration_test/ -d chrome`
2. **Test on target platforms**: Android, iOS, and Web
3. **Use real data occasionally**: Set `MAP_LIVE_DATA=true` to test EFFIS integration
4. **Check accessibility**: Use screen reader mode on physical devices
5. **Profile performance**: Use `flutter run --profile` + DevTools for deep analysis

## Related Documentation

- [Flutter Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [WildFire MVP Testing Standards](../docs/TEST_COVERAGE.md)
- [Performance Requirements (C5)](../docs/context.md#constitutional-gates)
