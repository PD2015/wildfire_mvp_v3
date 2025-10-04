# HomeScreen Widget Contract

## Overview
HomeScreen is the main screen widget that displays fire risk information to users. It integrates with HomeController for state management and provides retry and manual location functionality.

## Widget API Contract

### Class Definition
```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    HomeController? controller,  // optional for DI testing
  });
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
```

### Constructor Parameters
```dart
HomeScreen({
  Key? key,
  HomeController? controller,  // Injectable for testing, defaults to production instance
})
```

### Widget Hierarchy
```dart
HomeScreen
├── Scaffold
│   ├── AppBar (minimal, app title)
│   └── Body
│       ├── SafeArea
│       └── Column
│           ├── RiskDisplaySection
│           │   ├── RiskBanner (A3 component)
│           │   ├── SourceChip
│           │   └── TimestampText
│           ├── ActionSection  
│           │   ├── RetryButton (when error state)
│           │   └── ManualLocationButton
│           └── StatusSection
│               ├── LoadingIndicator (when loading)
│               └── ErrorMessage (when error)
```

## State Integration Contract

### HomeController Binding
```dart
class _HomeScreenState extends State<HomeScreen> {
  late HomeController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _createProductionController();
    _controller.addListener(_onStateChanged);
    _controller.load(); // Trigger initial load
  }
  
  void _onStateChanged() {
    if (mounted) {
      setState(() {}); // Rebuild UI on state changes
    }
  }
}
```

### State-Based UI Rendering
```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: _buildBody(_controller.state),
  );
}

Widget _buildBody(HomeState state) {
  return switch (state) {
    HomeStateLoading() => _buildLoadingView(state),
    HomeStateSuccess() => _buildSuccessView(state), 
    HomeStateError() => _buildErrorView(state),
  };
}
```

## UI Component Contracts

### RiskDisplaySection
```dart
Widget _buildSuccessView(HomeStateSuccess state) {
  return Column(
    children: [
      // Primary risk display using existing A3 RiskBanner
      RiskBanner(
        riskLevel: state.riskData.level,
        confidence: state.riskData.confidence,
        semanticsLabel: 'Current fire risk: ${state.riskData.level.name}',
      ),
      
      // Source transparency (C4 compliance)
      SourceChip(
        source: state.source,
        semanticsLabel: 'Data source: ${state.source.displayName}',
      ),
      
      // Timestamp transparency (C4 compliance)  
      TimestampText(
        timestamp: state.lastUpdated,
        isStale: state.source == DataSource.cached,
        semanticsLabel: 'Last updated: ${_formatTimestamp(state.lastUpdated)}',
      ),
    ],
  );
}
```

### LoadingView  
```dart
Widget _buildLoadingView(HomeStateLoading state) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CircularProgressIndicator(
        semanticsLabel: state.isRetry ? 'Retrying...' : 'Loading fire risk data...',
      ),
      SizedBox(height: 16),
      Text(
        state.isRetry ? 'Retrying...' : 'Loading current fire risk...',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ],
  );
}
```

### ErrorView
```dart
Widget _buildErrorView(HomeStateError state) {
  return Column(
    children: [
      // Show cached data if available (fallback principle)
      if (state.cachedData != null) ...[
        RiskBanner(
          riskLevel: state.cachedData!.level, 
          confidence: state.cachedData.confidence,
          semanticsLabel: 'Cached fire risk: ${state.cachedData!.level.name}',
        ),
        CachedDataBadge(
          timestamp: state.lastUpdated!,
          semanticsLabel: 'Using cached data from ${_formatTimestamp(state.lastUpdated!)}',
        ),
      ],
      
      // Error message
      ErrorMessage(
        message: state.errorMessage,
        semanticsLabel: 'Error: ${state.errorMessage}',
      ),
      
      // Retry button (C5 resilience)
      if (state.canRetry)
        RetryButton(
          onPressed: _controller.retry,
          semanticsLabel: 'Retry loading fire risk data',
        ),
    ],
  );
}
```

### ActionButtons
```dart
// Manual location button (always visible)
ManualLocationButton(
  onPressed: _showManualLocationDialog,
  semanticsLabel: 'Enter location manually',
  child: Icon(Icons.location_on),
)

// Retry button (error states only) 
RetryButton(
  onPressed: _controller.retry,
  semanticsLabel: 'Retry loading data',
  child: Icon(Icons.refresh),
)
```

## Accessibility Contract (C3)

### Touch Targets
- All interactive elements MUST be ≥44dp minimum touch target
- Buttons MUST have proper Material touch feedback

### Semantic Labels
```dart
// Risk display
RiskBanner(
  semanticsLabel: 'Current fire risk level: ${riskLevel.name}. ${riskLevel.description}',
)

// Source information  
SourceChip(
  semanticsLabel: 'Risk data from ${source.displayName}',
)

// Timestamp
TimestampText(
  semanticsLabel: 'Risk data last updated ${relativeTime}',
)

// Action buttons
RetryButton(
  semanticsLabel: 'Retry loading current fire risk data',
)

ManualLocationButton(
  semanticsLabel: 'Enter coordinates manually to check fire risk for specific location',
)
```

### Screen Reader Support
- State changes MUST announce context to screen readers
- Loading states MUST provide progress information
- Error states MUST announce error and available actions

## Manual Location Dialog Contract

### Dialog Interface
```dart
Future<LatLng?> _showManualLocationDialog() async {
  return showDialog<LatLng>(
    context: context,
    builder: (context) => ManualLocationDialog(),
  );
}
```

### Dialog Implementation
```dart
class ManualLocationDialog extends StatefulWidget {
  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController(); 
  String? _validationError;
  
  // Coordinate validation
  bool _validateCoordinates(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }
  
  // Save and return coordinates
  void _saveLocation() {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    
    if (lat == null || lon == null || !_validateCoordinates(lat, lon)) {
      setState(() {
        _validationError = 'Please enter valid coordinates';
      });
      return;
    }
    
    Navigator.of(context).pop(LatLng(lat, lon));
  }
}
```

## Performance Contract

### Build Performance
- Widget rebuild MUST complete within 16ms (60fps)
- State changes MUST trigger minimal widget rebuilds
- Heavy computations MUST be done in controller, not in build()

### Memory Management
- Controller listener MUST be removed in dispose()
- TextEditingController instances MUST be disposed
- No memory leaks on screen navigation

### Loading States
- Initial load MUST show loading indicator immediately
- Retry operations MUST show visual feedback
- Cached data MUST display while loading fresh data

## Testing Contract

### Widget Test Requirements
```dart
testWidgets('displays loading state initially', (tester) async {
  final mockController = MockHomeController();
  when(mockController.state).thenReturn(HomeStateLoading(isRetry: false, startTime: DateTime.now()));
  
  await tester.pumpWidget(MaterialApp(
    home: HomeScreen(controller: mockController),
  ));
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.text('Loading current fire risk...'), findsOneWidget);
});
```

### Accessibility Testing
```dart
testWidgets('has proper semantic labels', (tester) async {
  // Test semantic labels for all interactive elements
  // Verify 44dp minimum touch targets
  // Confirm screen reader announcements
});
```

### Integration Testing
- Test complete user flows with mock services
- Verify error handling and retry functionality
- Test manual location dialog integration

## Constitutional Compliance

### C1: Code Quality
- All widgets MUST have proper dispose() implementations
- No build() method side effects
- Proper state management separation

### C3: Accessibility
- Interactive elements ≥44dp touch targets
- Semantic labels for all user-facing content
- Screen reader compatibility

### C4: Trust & Transparency
- Risk data MUST show timestamp and source
- Official Scottish risk colors only
- Clear indication of cached vs live data

### C5: Resilience
- Graceful error state handling
- Retry functionality always available when appropriate
- No silent failures in UI updates

---

**Status**: HomeScreen widget contract defined with accessibility, performance, and constitutional compliance
**Dependencies**: HomeController, RiskBanner (A3), Material Design widgets
**Next**: Manual location dialog and utility widget contracts