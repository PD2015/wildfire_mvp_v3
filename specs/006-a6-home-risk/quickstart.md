# Quickstart: A6 — Home (Risk Feed Container & Screen)

**Feature**: Home screen with fire risk display and user interactions  
**Date**: 2025-10-04  
**Prerequisites**: A1-A5 services implemented (LocationResolver, FireRiskService, CacheService)

## Development Environment Setup

### Dependencies Check
```bash
# Verify existing services are available
ls lib/services/
# Expected: fire_risk_service.dart, location_resolver.dart, cache/

# Verify existing widgets
ls lib/widgets/
# Expected: risk_banner.dart (from A3)

# Run existing tests to ensure services work
flutter test test/unit/services/
flutter test test/integration/
```

### Branch Setup
```bash
# Ensure you're on the feature branch
git checkout 006-a6-home-risk
git status

# Verify specs directory
ls specs/006-a6-home-risk/
# Expected: spec.md, plan.md, research.md, data-model.md, contracts/
```

## Implementation Quickstart

### Step 1: Create HomeState Model (5 minutes)
```bash
# Create the state model
touch lib/models/home_state.dart
```

```dart
// lib/models/home_state.dart
import 'package:equatable/equatable.dart';
import '../services/models/fire_risk.dart';
import '../services/models/lat_lng.dart';

sealed class HomeState extends Equatable {
  const HomeState();
}

class HomeStateLoading extends HomeState {
  const HomeStateLoading({
    required this.isRetry,
    required this.startTime,
  });
  
  final bool isRetry;
  final DateTime startTime;
  
  @override
  List<Object> get props => [isRetry, startTime];
}

class HomeStateSuccess extends HomeState {
  const HomeStateSuccess({
    required this.riskData,
    required this.location,
    required this.lastUpdated,
    required this.source,
  });
  
  final FireRisk riskData;
  final LatLng location;
  final DateTime lastUpdated;
  final DataSource source;
  
  @override
  List<Object> get props => [riskData, location, lastUpdated, source];
}

class HomeStateError extends HomeState {
  const HomeStateError({
    required this.errorMessage,
    required this.canRetry,
    this.cachedData,
    this.location,
    this.lastUpdated,
  });
  
  final String errorMessage;
  final bool canRetry;
  final FireRisk? cachedData;
  final LatLng? location;
  final DateTime? lastUpdated;
  
  @override
  List<Object?> get props => [errorMessage, canRetry, cachedData, location, lastUpdated];
}
```

### Step 2: Create HomeController (15 minutes)
```bash
touch lib/controllers/home_controller.dart
```

```dart
// lib/controllers/home_controller.dart
import 'package:flutter/foundation.dart';
import '../models/home_state.dart';
import '../services/location_resolver.dart';
import '../services/fire_risk_service.dart';
import '../services/models/lat_lng.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required LocationResolver locationResolver,
    required FireRiskService fireRiskService,
  }) : _locationResolver = locationResolver,
       _fireRiskService = fireRiskService;

  final LocationResolver _locationResolver;
  final FireRiskService _fireRiskService;
  
  HomeState _state = const HomeStateLoading(isRetry: false, startTime: DateTime.now());
  HomeState get state => _state;
  
  void _updateState(HomeState newState) {
    _state = newState;
    notifyListeners();
  }
  
  Future<void> load({bool isRetry = false}) async {
    _updateState(HomeStateLoading(isRetry: isRetry, startTime: DateTime.now()));
    
    try {
      // Get location
      final locationResult = await _locationResolver.getLatLon();
      if (locationResult.isLeft()) {
        _updateState(HomeStateError(
          errorMessage: 'Unable to determine location',
          canRetry: true,
        ));
        return;
      }
      
      final location = locationResult.getOrElse(() => throw Exception());
      
      // Get risk data
      final riskResult = await _fireRiskService.getCurrent(
        lat: location.latitude,
        lon: location.longitude,
      );
      
      if (riskResult.isLeft()) {
        _updateState(HomeStateError(
          errorMessage: 'Unable to load fire risk data',
          canRetry: true,
          location: location,
        ));
        return;
      }
      
      final riskData = riskResult.getOrElse(() => throw Exception());
      
      _updateState(HomeStateSuccess(
        riskData: riskData,
        location: location,
        lastUpdated: DateTime.now(),
        source: riskData.source ?? DataSource.unknown,
      ));
      
    } catch (e) {
      _updateState(HomeStateError(
        errorMessage: 'An unexpected error occurred',
        canRetry: true,
      ));
    }
  }
  
  Future<void> retry() async {
    if (_state is HomeStateError) {
      await load(isRetry: true);
    }
  }
  
  Future<void> setManualLocation(LatLng coordinates, [String? placeName]) async {
    // Store manual location and reload
    // Implementation depends on LocationResolver.saveManual method
    await load();
  }
}
```

### Step 3: Create Basic HomeScreen (20 minutes)
```bash
touch lib/screens/home_screen.dart
```

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import '../models/home_state.dart';
import '../widgets/risk_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.controller,
  });
  
  final HomeController? controller;
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _createProductionController();
    _controller.addListener(_onStateChanged);
    _controller.load();
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  HomeController _createProductionController() {
    // TODO: Get from dependency injection or service locator
    throw UnimplementedError('Production controller creation not implemented');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WildFire Risk'),
      ),
      body: SafeArea(
        child: _buildBody(_controller.state),
      ),
    );
  }
  
  Widget _buildBody(HomeState state) {
    return switch (state) {
      HomeStateLoading() => _buildLoadingView(state),
      HomeStateSuccess() => _buildSuccessView(state),
      HomeStateError() => _buildErrorView(state),
    };
  }
  
  Widget _buildLoadingView(HomeStateLoading state) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading fire risk data...'),
        ],
      ),
    );
  }
  
  Widget _buildSuccessView(HomeStateSuccess state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          RiskBanner(
            riskLevel: state.riskData.level,
            confidence: state.riskData.confidence,
          ),
          const SizedBox(height: 16),
          Text('Last updated: ${_formatTimestamp(state.lastUpdated)}'),
          Text('Source: ${state.source.name}'),
        ],
      ),
    );
  }
  
  Widget _buildErrorView(HomeStateError state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(state.errorMessage),
          const SizedBox(height: 16),
          if (state.canRetry)
            ElevatedButton(
              onPressed: _controller.retry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}
```

### Step 4: Create Basic Tests (10 minutes)
```bash
mkdir -p test/unit/controllers test/unit/models test/widget/screens
touch test/unit/models/home_state_test.dart
touch test/unit/controllers/home_controller_test.dart
touch test/widget/screens/home_screen_test.dart
```

```dart
// test/unit/models/home_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/home_state.dart';

void main() {
  group('HomeState', () {
    test('HomeStateLoading equality works correctly', () {
      final now = DateTime.now();
      final state1 = HomeStateLoading(isRetry: false, startTime: now);
      final state2 = HomeStateLoading(isRetry: false, startTime: now);
      
      expect(state1, equals(state2));
    });
    
    // Add more state tests...
  });
}
```

## Quick Validation

### Manual Testing Checklist
```bash
# 1. Run the app (will initially crash - normal for quickstart)
flutter run

# 2. Run unit tests
flutter test test/unit/models/home_state_test.dart
flutter test test/unit/controllers/home_controller_test.dart

# 3. Run widget tests
flutter test test/widget/screens/home_screen_test.dart

# 4. Check for compilation errors
flutter analyze lib/models/home_state.dart
flutter analyze lib/controllers/home_controller.dart
flutter analyze lib/screens/home_screen.dart
```

### Integration Points to Verify
1. **LocationResolver Integration**: Controller can get location
2. **FireRiskService Integration**: Controller can fetch risk data  
3. **RiskBanner Integration**: Screen can display risk information
4. **State Management**: UI updates on state changes

### Expected Behavior After Quickstart
- ✅ HomeState model compiles and has basic equality
- ✅ HomeController compiles with basic state management
- ✅ HomeScreen compiles with basic UI structure
- ❌ App will crash on run (production controller not implemented)
- ❌ Integration tests will fail (services need mocking)

## Next Development Steps

### 1. Complete Service Integration (30 minutes)
- Implement production HomeController factory
- Add proper dependency injection
- Connect to existing LocationResolver and FireRiskService

### 2. Add UI Components (45 minutes)
- Implement SourceChip, TimestampText, CachedDataBadge
- Add ManualLocationDialog
- Improve RetryButton with loading states

### 3. Complete Testing (60 minutes)
- Add 6 integration test scenarios
- Mock LocationResolver and FireRiskService
- Test error flows and retry functionality
- Add accessibility tests

### 4. Constitutional Compliance (30 minutes)
- Verify 44dp touch targets
- Add semantic labels
- Test official color usage
- Validate timestamp/source display

## Common Issues and Solutions

### "Services not found" Error
```bash
# Ensure A1-A5 are implemented first
flutter test test/unit/services/ --reporter=compact
# Should show passing tests for LocationResolver, FireRiskService, etc.
```

### "RiskBanner not found" Error
```bash
# Ensure A3 RiskBanner is implemented
ls lib/widgets/risk_banner.dart
# If missing, implement basic RiskBanner first
```

### State Management Issues
```dart
// Always call notifyListeners() after state changes
void _updateState(HomeState newState) {
  _state = newState;
  notifyListeners(); // Critical for UI updates
}
```

### Memory Leaks
```dart
// Always remove listeners in dispose()
@override
void dispose() {
  _controller.removeListener(_onStateChanged);
  super.dispose();
}
```

## Success Criteria for Quickstart

After completing this quickstart, you should have:
- [x] Compilable HomeState model with sealed class hierarchy
- [x] Functional HomeController with ChangeNotifier pattern
- [x] Basic HomeScreen with state-based UI rendering
- [x] Foundation tests for models and controllers
- [x] Clear path to full implementation

**Estimated Time**: 50 minutes for basic structure  
**Next Phase**: Full implementation with UI components and integration tests

---

**Note**: This quickstart creates the foundation. Full A6 implementation requires completing UI components, service integration, and the 6-scenario test matrix as specified in the contracts.