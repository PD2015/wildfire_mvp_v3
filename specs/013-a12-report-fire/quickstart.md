# Quickstart: A12 – Report Fire Screen (MVP)

**Date**: 28 October 2025  
**Feature**: Emergency calling screen for Scotland fire incidents

## Prerequisites
- Flutter 3.35.5+ installed and configured
- WildFire MVP v3 repository cloned and dependencies installed
- Device with phone capability (for end-to-end testing) or emulator (for fallback testing)

## Quick Setup (5 minutes)

### 1. Add Dependencies
```bash
# Add url_launcher to pubspec.yaml (if not already present)
flutter pub add url_launcher
flutter pub get
```

### 2. Create Feature Structure
```bash
# Create directory structure
mkdir -p lib/features/report/{screens,models,widgets}
mkdir -p test/features/report/{screens,models,widgets}
mkdir -p test/integration/report
```

### 3. Verify Navigation Setup
```bash
# Check if go_router is configured (should already exist in WildFire MVP)
grep -r "go_router" lib/
```

## Development Workflow

### Phase 1: Core Models (15 minutes)
```bash
# 1. Create EmergencyContact model
touch lib/features/report/models/emergency_contact.dart

# 2. Create corresponding test
touch test/features/report/models/emergency_contact_test.dart

# 3. Run model tests
flutter test test/features/report/models/
```

### Phase 2: UI Components (30 minutes)
```bash
# 1. Create reusable emergency button widget
touch lib/features/report/widgets/emergency_button.dart
touch test/features/report/widgets/emergency_button_test.dart

# 2. Create main screen
touch lib/features/report/screens/report_fire_screen.dart
touch test/features/report/screens/report_fire_screen_test.dart

# 3. Run widget tests
flutter test test/features/report/
```

### Phase 3: Integration & Navigation (15 minutes)
```bash
# 1. Add route to go_router configuration
# Edit existing router configuration file

# 2. Create integration test
touch test/integration/report/report_fire_integration_test.dart

# 3. Run integration tests
flutter test integration_test/report/
```

## Testing Strategy

### Unit Testing
```bash
# Test individual components
flutter test test/features/report/models/ --reporter=expanded
flutter test test/features/report/widgets/ --reporter=expanded
```

### Widget Testing  
```bash
# Test UI behavior and accessibility
flutter test test/features/report/screens/ --reporter=expanded
```

### Integration Testing
```bash
# Test full user flows
flutter test integration_test/ --reporter=expanded
```

### Manual Testing (Critical)
```bash
# On real device - verify dialer integration
flutter run -d <device-id>

# On emulator - verify fallback behavior  
flutter run -d emulator
```

## Validation Checklist

### Functional Validation
- [ ] Screen displays at route "/report"
- [ ] Three emergency buttons visible with correct labels
- [ ] 999 button has emergency styling (red/critical appearance)
- [ ] Tapping buttons on device opens dialer with correct number
- [ ] Tapping buttons on emulator shows SnackBar fallback
- [ ] Back navigation works correctly
- [ ] Screen works offline (no loading states)

### Accessibility Validation
- [ ] All buttons ≥44dp touch target size
- [ ] Screen reader announces button labels correctly
- [ ] Semantic navigation order matches visual priority
- [ ] High contrast mode supported
- [ ] Large text scaling preserves layout

### Performance Validation
- [ ] Screen loads instantly (<200ms)
- [ ] Button taps respond immediately (<100ms)
- [ ] No memory leaks on repeated navigation
- [ ] Smooth animations at 60fps

### Cross-Platform Validation
- [ ] iOS: Phone app opens with number dialed
- [ ] Android: Default dialer opens with number entered  
- [ ] Web: tel: link attempted or graceful fallback
- [ ] macOS (web mode): Fallback notification shown

## Troubleshooting

### Common Issues

**"url_launcher not found" Error**:
```bash
flutter clean
flutter pub get
```

**Dialer doesn't open on device**:
- Verify phone capability in device settings
- Check tel: scheme permissions in platform-specific configs
- Test with simple tel:999 link in browser

**Widget tests fail**:
```bash
# Check for missing test dependencies
flutter pub deps
# Verify test imports and widget pump strategies
flutter test --reporter=expanded
```

**Integration tests timeout**:
```bash
# Increase timeout for slower devices
flutter test integration_test/ --timeout=60s
```

### Performance Issues
**Screen loads slowly**:
- Check for unnecessary network calls (should be none)
- Verify const constructors for static data
- Profile with Flutter Inspector

**Memory leaks on navigation**:
- Ensure StatelessWidget implementation
- Check for unsubscribed listeners (should be none)

## Quick Validation Commands

```bash
# Full test suite
flutter test && flutter test integration_test/

# Code quality checks  
flutter analyze
dart format --set-exit-if-changed .

# Build verification
flutter build apk --debug
flutter build web --debug

# Manual smoke test
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false
```

## Success Criteria Met When:
1. All tests pass (`flutter test` exits with 0)
2. Manual testing confirms dialer integration on real device
3. Manual testing confirms fallback behavior on emulator
4. Code quality gates pass (analyze + format)
5. Accessibility validation completes successfully
6. Cross-platform behavior verified on iOS + Android + Web

**Expected Total Development Time**: 60-90 minutes for complete implementation and testing