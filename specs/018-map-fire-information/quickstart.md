# Quickstart: Map Fire Information Sheet

## Development Setup

### Prerequisites
- Flutter 3.35.5+ with Dart 3.9.2+
- VS Code with Dart/Flutter extensions
- Android Studio or Xcode for device testing
- Git checkout of `018-map-fire-information` branch

### Environment Configuration
```bash
# 1. Switch to feature branch
git checkout 018-map-fire-information

# 2. Install dependencies
flutter pub get

# 3. Set up environment file
cp env/dev.env.json.template env/dev.env.json
# Edit env/dev.env.json with your API keys

# 4. Run code generation (if needed)
flutter packages pub run build_runner build

# 5. Verify setup
flutter doctor
```

### Running the Application

#### Development Mode (Mock Data)
```bash
# Web (Chrome) - Mock data mode
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false

# Mobile - Mock data mode  
flutter run -d android --dart-define=MAP_LIVE_DATA=false
flutter run -d ios --dart-define=MAP_LIVE_DATA=false
```

#### Live Data Mode (Requires API Keys)
```bash
# Web with live EFFIS data
./scripts/run_web.sh

# Mobile with live data (set API keys in env file)
flutter run -d android --dart-define=MAP_LIVE_DATA=true
```

## Feature Testing Checklist

### ✅ Basic Functionality
- [ ] Map loads with fire markers visible
- [ ] Tapping fire marker opens bottom sheet
- [ ] Bottom sheet displays fire incident details
- [ ] Risk level loads and displays with correct colors
- [ ] Distance and bearing calculate correctly
- [ ] Data source chips show correct indicators

### ✅ Mock Data Mode (MAP_LIVE_DATA=false)
- [ ] "DEMO DATA" chip prominently displayed
- [ ] Mock fire incidents appear in Scotland region
- [ ] All mock data includes required fields (confidence, FRP, etc.)
- [ ] Risk assessment returns mock FWI values
- [ ] No network requests made to external APIs

### ✅ Live Data Mode (MAP_LIVE_DATA=true)  
- [ ] Live EFFIS data loads from real API
- [ ] Data source shows "EFFIS" or appropriate service
- [ ] Real-time fire incidents display current data
- [ ] Network errors handled gracefully with retry
- [ ] No "DEMO DATA" indicators present

### ✅ User Experience
- [ ] Bottom sheet opens smoothly with animation
- [ ] Sheet can be dismissed by tapping outside, swiping down, or close button
- [ ] Loading states show spinners for risk assessment
- [ ] Error states display helpful messages with retry buttons
- [ ] Multiple marker taps handled without conflicts

### ✅ Accessibility  
- [ ] Screen reader announces fire details correctly
- [ ] All interactive elements are ≥44dp touch targets
- [ ] Risk levels have color-independent labels
- [ ] Focus navigation works properly with keyboard
- [ ] Semantic labels present for all data fields

### ✅ Performance
- [ ] Viewport changes debounced properly (no request spam)
- [ ] Cached incidents display instantly on repeat views
- [ ] Bottom sheet opens within 200ms
- [ ] No memory leaks on repeated open/close cycles
- [ ] Smooth 60fps animation during sheet transitions

## Quick Verification Scripts

### Test Fire Marker Interaction
```bash
# Run integration test for marker tap flow
flutter test integration_test/map/fire_marker_interaction_test.dart

# Expected: Test passes with marker tap → bottom sheet → details displayed
```

### Verify Mock Data Compliance
```bash
# Run with mock data and check constitutional compliance
flutter run --dart-define=MAP_LIVE_DATA=false -d chrome
# 1. Open browser dev tools
# 2. Tap fire markers
# 3. Verify "DEMO DATA" chips visible
# 4. Check console for no external API calls
```

### Test Accessibility
```bash
# Run accessibility-focused widget tests
flutter test test/widget/fire_details_bottom_sheet_test.dart --reporter=expanded

# Expected: All accessibility tests pass with semantic labels verified
```

### Performance Verification
```bash
# Run performance-focused integration tests
flutter test integration_test/map/ --profile

# Expected: Viewport queries debounced, sheet loads <200ms
```

## Common Development Issues

### Bottom Sheet Not Opening
**Symptoms**: Marker tap doesn't show bottom sheet
**Check**:
- MapController properly handling onTap events
- BottomSheetState managed correctly in provider/controller
- No exceptions in console during tap

### Missing Fire Data
**Symptoms**: Bottom sheet opens but shows limited information  
**Check**:
- ActiveFiresService returning complete FireIncident objects
- JSON parsing handling all required fields
- Mock data includes all new fields (detectedAt, source, confidence, frp)

### Risk Assessment Not Loading
**Symptoms**: Risk section shows loading spinner indefinitely
**Check**:
- EffisService.getFwi() call succeeding for fire coordinates
- Network connectivity in live data mode
- Error handling showing appropriate messages

### Distance Calculation Errors
**Symptoms**: Distance shows as "Unknown" or crashes
**Check**:
- Location permissions granted on device
- Geolocator service functioning correctly
- Fallback handling for denied location permissions

## Development Workflow

### 1. Model Changes
```bash
# After modifying FireIncident or related models
flutter test test/unit/models/ --reporter=expanded
# Verify all model tests pass before proceeding
```

### 2. Service Implementation  
```bash
# After implementing ActiveFiresService
flutter test test/unit/services/active_fires_service_test.dart
# Ensure contract compliance and error handling
```

### 3. UI Development
```bash
# After bottom sheet widget changes
flutter test test/widget/fire_details_bottom_sheet_test.dart
# Verify UI rendering and accessibility requirements
```

### 4. Integration Testing
```bash
# After end-to-end feature implementation
flutter test integration_test/map/fire_marker_interaction_test.dart
# Test complete user flow from map to details
```

### 5. Constitutional Gates
```bash
# Before committing changes
flutter analyze
dart format --set-exit-if-changed .
flutter test
# All gates must pass (C1: Code Quality & Tests)
```

## Demo Scenarios

### Scenario 1: Basic Fire Details
1. Launch app with `MAP_LIVE_DATA=false`
2. Navigate to Scotland region on map
3. Tap on any fire marker
4. **Expected**: Bottom sheet opens showing:
   - Detection time (mock timestamp)
   - Source: "VIIRS" or "MODIS"  
   - Confidence: percentage value
   - Fire power: MW value if available
   - Distance from current location
   - Risk level with Scottish colors
   - "DEMO DATA" chip visible

### Scenario 2: Error Handling
1. Launch app with invalid API configuration
2. Set `MAP_LIVE_DATA=true` 
3. Tap fire marker
4. **Expected**: 
   - Basic fire details show immediately
   - Risk section shows error with retry button
   - Distance calculates successfully
   - User can retry risk assessment

### Scenario 3: Accessibility Testing
1. Enable screen reader (TalkBack/VoiceOver)
2. Navigate to fire marker
3. Tap marker
4. **Expected**:
   - Screen reader announces fire detection details
   - Can navigate between detail sections
   - Risk level announced color-independently
   - Close button clearly labeled and accessible

## Troubleshooting

### Performance Issues
- Check viewport debouncing: should see ~300ms delay between pan/zoom and API calls
- Monitor memory usage: repeated sheet open/close should not leak
- Profile widget rebuilds: bottom sheet should rebuild minimally during loading

### Network Debugging
- Enable network logging: `flutter run --debug` shows HTTP requests
- Check CORS: web mode may need CORS handling for EFFIS API
- Verify timeouts: service calls should timeout after configured duration

### State Management  
- Use Flutter Inspector to examine widget tree during sheet interaction
- Check provider/controller state updates via dev tools
- Verify proper disposal of streams and controllers

## Success Criteria

Feature is complete when:
- ✅ All 20 functional requirements from specification met
- ✅ Constitutional gates C1-C5 pass completely  
- ✅ Integration tests pass on Android and iOS
- ✅ Accessibility audit shows 100% compliance
- ✅ Performance meets <200ms sheet load target
- ✅ Demo and live data modes work correctly
- ✅ Error handling provides clear user feedback