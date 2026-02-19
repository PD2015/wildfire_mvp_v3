# Integration Test Quick Start Guide

## TL;DR - Run Integration Tests

```bash
# 1. Check available devices
flutter devices

# 2. Run on mobile device/emulator (Android/iOS)
flutter test integration_test/ -d <device-id>

# 3. For web, use flutter run instead (integration_test doesn't support web in test mode)
flutter run integration_test/map_integration_test.dart -d chrome
```

## Why Integration Tests?

**Problem**: GoogleMap widget requires platform channels that aren't available in `flutter test` (VM environment).

**Solution**: Use `integration_test` package which runs tests on real devices/emulators where platform channels work.

| Test Type | Command | GoogleMap Support | Speed |
|-----------|---------|-------------------|-------|
| Unit/Widget Tests | `flutter test` | ❌ No (hangs or fails) | 🚀 Fast (~10s) |
| Integration Tests | `flutter test integration_test/ -d <device>` | ✅ Yes (full support) | 🐢 Slower (~2min) |

## Quick Commands

### Mobile (Android/iOS - Full Integration Test Support)

```bash
# Android
flutter emulators --launch Pixel_6_API_34
flutter test integration_test/ -d emulator-5554

# iOS (macOS only)
open -a Simulator
flutter test integration_test/ -d iPhone

# Run specific test file
flutter test integration_test/map_integration_test.dart -d <device-id>
```

### Web (Limited - Use for Visual Testing)

```bash
# Web doesn't support `flutter test` for integration tests
# Instead, use `flutter run` for manual/visual testing:
flutter run integration_test/map_integration_test.dart -d chrome

# Or use regular flutter test for unit/widget tests:
flutter test test/widget/
```

## What Gets Tested

### Map Integration Tests ✅
- GoogleMap widget renders
- Fire markers appear on map
- Map is interactive (can pan/zoom)
- "Check risk here" FAB ≥44dp (C3)
- Source chip visible (C4 transparency)
- Map loads within 3s (T035 performance)

### Home Integration Tests ✅
- Location resolution (GPS/cache/manual/fallback)
- Fire risk banner displays
- Risk colors match FWI thresholds
- Timestamp visible (C4)
- Source chip visible (C4)
- Retry button works
- Touch targets ≥44dp (C3)

### App Integration Tests ✅
- Navigation: Home ↔ Map
- State persists across navigation
- Multiple navigation cycles work
- Rapid navigation doesn't crash
- App lifecycle (background/resume)

## Troubleshooting

### "No devices found"
```bash
# List devices
flutter devices

# For web: Make sure Chrome is installed
# For mobile: Start emulator first
flutter emulators
flutter emulators --launch <emulator-id>
```

### "GoogleMap not rendering"
1. Check API key configured for platform
2. Verify API key restrictions allow your package
3. Remember: macOS Desktop ≠ macOS Web (use `-d chrome`, not `-d macos`)

### "Tests hang forever"
- Increase timeout in test file: `timeout: const Timeout(Duration(minutes: 5))`
- Use verbose mode: `flutter test integration_test/ -d chrome --verbose`
- Check device is responsive: `adb devices` (Android) or check Simulator (iOS)

### "Compilation errors in integration tests"
```bash
# Some minor lint warnings are expected (unused variables in conditional checks)
# These don't affect test execution
# Run tests anyway - they will work despite warnings
```

## Expected Output

```
00:00 +0: loading /Users/.../integration_test/map_integration_test.dart
00:15 +1: GoogleMap renders on device with fire markers visible
✅ GoogleMap rendered successfully on device
00:22 +2: Fire incident markers appear on map
✅ 3 fire markers rendered
00:35 +3: "Check risk here" FAB is visible and ≥44dp (C3 accessibility)
✅ FAB size: 56.0x56.0dp
... (more tests)
00:02:15 +8: All tests passed!
```

## Integration with CI/CD

For GitHub Actions:

```yaml
name: Integration Tests (Web)

on: [push, pull_request]

jobs:
  integration-test-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.5'
      - run: flutter pub get
      - name: Run Integration Tests on Chrome
        run: |
          chromedriver --port=4444 &
          flutter test integration_test/ -d web-server
```

## Performance Notes

| Platform | Expected Time | Notes |
|----------|--------------|-------|
| Chrome (web) | ~1-2 min | Fastest, no emulator needed |
| Android emulator | ~2-3 min | Slower due to emulator overhead |
| iOS simulator | ~1.5-2.5 min | Fast on macOS |
| Physical device | ~1-2 min | Fastest for mobile platforms |

## Next Steps

1. **Run tests locally**: `flutter test integration_test/ -d chrome`
2. **Verify all pass**: Should see "All tests passed!" at end
3. **Test on target platforms**: Run on Android/iOS before release
4. **Add to CI/CD**: Automate web integration tests in GitHub Actions
5. **Extend coverage**: Add more integration tests for edge cases

## Related Documentation

- [Integration Test README](integration_test/README.md) - Full documentation
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Google Maps Setup](docs/GOOGLE_MAPS_SETUP.md)
- [Test Coverage Report](docs/TEST_COVERAGE.md)
