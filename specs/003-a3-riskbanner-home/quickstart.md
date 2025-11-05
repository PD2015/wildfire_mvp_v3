# RiskBanner Quick Start Guide

## Overview
This guide demonstrates how to integrate and use the RiskBanner widget in the WildFire MVP application. The RiskBanner displays the current wildfire risk level with official Scottish Government colors and accessibility compliance.

## Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- A2 FireRiskService implementation (already available)
- Dependencies: `flutter_bloc`, `equatable`, `dartz`

## Quick Integration

### 1. Add Dependencies (if not already present)
```yaml
# pubspec.yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  dartz: ^0.10.1
```

### 2. Basic Usage
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/presentation/widgets/risk_banner_widget.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/presentation/bloc/risk_banner_cubit.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/domain/repositories/fire_risk_repository.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WildFire Risk')),
      body: Column(
        children: [
          // RiskBanner widget
          BlocProvider(
            create: (context) => RiskBannerCubit(
              repository: context.read<FireRiskRepository>(),
            ),
            child: RiskBannerWidget(
              latitude: 55.9533,  // Edinburgh coordinates
              longitude: -3.1883,
              onTap: () {
                // Navigate to detailed risk view
                Navigator.pushNamed(context, '/risk-details');
              },
            ),
          ),
          // Rest of home screen content
          Expanded(
            child: Center(
              child: Text('Other home screen content'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Dependency Injection Setup
```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/data/repositories/fire_risk_repository_impl.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/domain/repositories/fire_risk_repository.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FireRiskRepository>(
          create: (context) => FireRiskRepositoryImpl(
            service: context.read<FireRiskService>(), // A2 service
          ),
        ),
      ],
      child: MaterialApp(
        title: 'WildFire MVP',
        home: HomeScreen(),
      ),
    );
  }
}
```

## Customization Options

### Custom Configuration
```dart
RiskBannerWidget(
  latitude: 55.9533,
  longitude: -3.1883,
  config: RiskBannerConfig(
    minHeight: 80.0,        // Larger touch target
    padding: EdgeInsets.all(20.0),
    borderRadius: BorderRadius.circular(12.0),
    animationDuration: Duration(milliseconds: 500),
  ),
  onTap: () {
    // Custom tap handling
    showRiskDetailsDialog(context);
  },
)
```

### Custom Tap Handling
```dart
void showRiskDetailsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Wildfire Risk Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current risk level: High'),
          Text('Last updated: 2 hours ago'),
          Text('Data source: EFFIS'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

## Testing Your Integration

### Widget Test Example
```dart
// test/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';

void main() {
  testWidgets('RiskBanner appears on home screen', (tester) async {
    // Arrange: Mock repository
    final mockRepository = MockFireRiskRepository();
    when(mockRepository.getRiskData(
      latitude: anyNamed('latitude'),
      longitude: anyNamed('longitude'),
    )).thenAnswer((_) async => Right(
      FireRisk(
        level: WildfireRiskLevel.moderate,
        fwiValue: 45.0,
        source: 'EFFIS',
        timestamp: DateTime.now(),
        latitude: 55.9533,
        longitude: -3.1883,
      ),
    ));

    // Act: Build home screen
    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<FireRiskRepository>.value(
          value: mockRepository,
          child: HomeScreen(),
        ),
      ),
    );

    // Assert: RiskBanner is present
    expect(find.byType(RiskBannerWidget), findsOneWidget);
    
    // Wait for data to load
    await tester.pumpAndSettle();
    
    // Verify risk level is displayed
    expect(find.textContaining('Moderate'), findsOneWidget);
  });
}
```

## Troubleshooting

### Common Issues

#### 1. Widget not displaying
**Problem**: RiskBanner appears blank or doesn't render
**Solution**: 
- Verify `FireRiskRepository` is provided via `RepositoryProvider`
- Check coordinates are valid (lat: -90 to 90, lon: -180 to 180)
- Ensure A2 FireRiskService is properly initialized

#### 2. Colors not showing correctly
**Problem**: Wrong colors or default colors displayed
**Solution**:
- Verify `WildfireColors` constants are imported
- Check `WildfireRiskLevel` enum values match expectations
- Test color mapping with unit tests

#### 3. Accessibility warnings
**Problem**: Flutter inspector shows accessibility warnings
**Solution**:
- Ensure widget height is minimum 44dp
- Verify semantic labels are present: `Semantics(label: '...', child: widget)`
- Test with TalkBack/VoiceOver enabled

#### 4. Loading state stuck
**Problem**: Widget shows loading spinner indefinitely
**Solution**:
- Check network connectivity for EFFIS/SEPA services
- Verify A2 FireRiskService fallback chain is working
- Check logs for service timeout errors

#### 5. Tap not responding
**Problem**: onTap callback not triggered
**Solution**:
- Wrap widget in `GestureDetector` or `InkWell`
- Ensure widget has minimum touch target size
- Check for overlapping widgets blocking touch events

### Debug Mode
```dart
// Enable debug logging for RiskBanner
RiskBannerWidget(
  latitude: 55.9533,
  longitude: -3.1883,
  config: RiskBannerConfig(
    debugMode: true, // Shows state transitions in console
  ),
)
```

### Performance Optimization
```dart
// Use const constructor where possible
const RiskBannerWidget(
  latitude: 55.9533,
  longitude: -3.1883,
  // onTap: null, // Don't provide callback if not needed
)

// Cache heavy computations
class _HomeScreenState extends State<HomeScreen> {
  static const _edinburghCoords = (55.9533, -3.1883);
  
  @override 
  Widget build(BuildContext context) {
    return RiskBannerWidget(
      latitude: _edinburghCoords.$1,
      longitude: _edinburghCoords.$2,
    );
  }
}
```

## User Story Validation

### Story 1: Risk Display
**As a user, I want to see the current wildfire risk level on my home screen**

**Test Steps**:
1. Open app to home screen
2. Observe RiskBanner widget
3. Verify risk level is displayed with appropriate color
4. Confirm "Last Updated" timestamp is visible

**Expected Result**: Risk level clearly visible with correct Scottish Government color

### Story 2: Data Provenance  
**As a user, I want to know where the risk data comes from**

**Test Steps**:
1. View RiskBanner on home screen
2. Check for data source label (EFFIS, SEPA, Cache, Mock)
3. Verify timestamp shows when data was last refreshed

**Expected Result**: Clear indication of data source and age

### Story 3: Accessibility
**As a user with visual impairments, I want to access risk information via screen reader**

**Test Steps**:
1. Enable TalkBack (Android) or VoiceOver (iOS) 
2. Navigate to RiskBanner widget
3. Listen to semantic announcement
4. Verify risk level and metadata are spoken clearly

**Expected Result**: Screen reader announces "Moderate wildfire risk, last updated 2 hours ago, data from EFFIS"

### Story 4: Offline Capability
**As a user with poor connectivity, I want to see cached risk data when network fails**

**Test Steps**:
1. Load risk data with good connection
2. Disable network connectivity
3. Restart app or trigger refresh
4. Verify cached data is displayed with "cached" indicator

**Expected Result**: Previous risk data shown with clear "cached data" label

### Story 5: Error Handling
**As a user, I want clear feedback when risk data cannot be loaded**

**Test Steps**:
1. Configure network to reject all requests
2. Launch app with no cached data
3. Observe error state in RiskBanner
4. Verify error message is user-friendly

**Expected Result**: Clear error message like "Unable to load current wildfire risk data"

## Visual Refresh (A14 - November 2025)

### Material Card Design
RiskBanner now uses Material Design 3 Card widgets with consistent visual tokens:
- **Card Styling**: 16dp corner radius, 2.0 elevation, proper shadow
- **Padding**: 16dp internal padding for content
- **Layout**: Standardized spacing with 8dp/16dp increments

### Internal Timestamp & Source Display
Timestamp and data source information are now shown **internally** within the RiskBanner:
- **Location**: Displayed below risk level inside the card
- **Format**: "Updated {relative time}" + "Data Source: {EFFIS|SEPA|Cache|Mock}"
- **Benefits**: Consolidated UI, reduced duplication, single source of truth

**Migration Note**: If your HomeScreen previously displayed external timestamp/source rows, these should be removed to avoid duplication.

### Golden Test Coverage
The RiskBanner now has comprehensive visual regression testing:
- **7 Golden Tests**: All 6 risk levels × 2 themes (light/dark) + cached state
- **Test Location**: `test/widget/golden/risk_banner_*_test.dart`
- **Baseline Images**: `test/widget/golden/goldens/*.png`
- **Purpose**: Prevents unintended visual changes, ensures pixel-perfect rendering

To update golden baselines after intentional visual changes:
```bash
flutter test --update-goldens test/widget/golden/
```

### Privacy-Compliant Location Display
Coordinates are now shown with 2-decimal precision (C2 constitutional compliance):
- **Format**: "55.95, -3.19" (Edinburgh example)
- **Precision**: ±1.1km accuracy
- **Implementation**: Use `LocationUtils.logRedact()` for coordinate formatting

### Weather Panel (Optional)
Future enhancement placeholder for weather conditions:
```dart
RiskBanner(
  state: RiskBannerSuccess(riskData),
  config: RiskBannerConfig(showWeatherPanel: true), // Future use
)
```

## Performance Expectations

- **Initial Load**: < 500ms for cached data
- **Network Load**: < 5 seconds for fresh data (inherits A2 timeouts)
- **UI Transitions**: Smooth 60fps animations between states
- **Memory Usage**: < 5MB additional heap for widget and dependencies
- **Battery Impact**: Minimal - no background processing or polling

## Next Steps

1. **Integration**: Add RiskBanner to your home screen layout
2. **Customization**: Adjust colors and sizing per your design system
3. **Testing**: Run widget tests to verify integration
4. **Accessibility**: Test with screen readers and accessibility inspector
5. **Performance**: Profile app to ensure smooth rendering
6. **User Testing**: Validate with real users for usability