# Widget Contracts: 018-A15 Location Picker

**Branch**: `018-018-a15-location` | **Date**: 2025-11-27

---

## 1. LocationPickerScreen

### Contract

```dart
/// Full-screen location picker with map, search, and what3words
///
/// Entry points:
/// - HomeScreen "Change/Set" button → mode: riskLocation
/// - ReportFireScreen "Set Location" button → mode: fireReport
///
/// Returns: PickedLocation via Navigator.pop, or null if cancelled
class LocationPickerScreen extends StatefulWidget {
  /// Initial location to center map (current location or default)
  final LatLng? initialLocation;
  
  /// Mode determines UI variations and return behavior
  final LocationPickerMode mode;
  
  /// Optional initial place name for display
  final String? initialPlaceName;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.mode = LocationPickerMode.riskLocation,
    this.initialPlaceName,
  });
}
```

### UI Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Back    Select Location                           Confirm ✓   │ AppBar
├─────────────────────────────────────────────────────────────────┤
│ 🔍 Search place or ///what3words...                             │ SearchBar
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                                                                  │
│                         ✛                                       │ GoogleMap
│                    (crosshair)                                  │ + fixed
│                                                                  │ center
│                                                [terrain] [sat]  │ marker
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ 📍 55.95, -3.19                                    [📋 Copy]   │ InfoPanel
│ ///slurs.this.name                              [📍 Use GPS]   │
└─────────────────────────────────────────────────────────────────┘
```

### Mode Variations

| Element | riskLocation | fireReport |
|---------|--------------|------------|
| AppBar title | "Select Location" | "Fire Location" |
| Emergency banner | Hidden | Visible ("Call 999 first!") |
| Confirm button | "Confirm" | "Use this location" |
| Copy button | Optional | Prominent (for w3w) |
| On confirm | Save + pop | Pop only |

### Accessibility (C3)

- AppBar back button: ≥48dp, semantic "Go back"
- Search bar: ≥48dp height, semantic "Search for location"
- Map: semantic "Interactive map. Pan to select location"
- Crosshair: decorative (no semantic label)
- Coordinates: semantic "Selected coordinates: {coords}"
- what3words: semantic "what3words address: {address}"
- Copy button: ≥48dp, semantic "Copy what3words to clipboard"
- GPS button: ≥48dp, semantic "Use current GPS location"
- Confirm button: ≥48dp, semantic "Confirm selected location"

### Test Assertions

```dart
testWidgets('LocationPickerScreen opens with initial location', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LocationPickerScreen(
        initialLocation: const LatLng(55.9533, -3.1883),
      ),
    ),
  );
  
  expect(find.text('Select Location'), findsOneWidget);
  expect(find.byType(GoogleMap), findsOneWidget);
  expect(find.text('55.95, -3.19'), findsOneWidget); // Redacted coords
});

testWidgets('fireReport mode shows emergency banner', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LocationPickerScreen(
        mode: LocationPickerMode.fireReport,
      ),
    ),
  );
  
  expect(find.text('Fire Location'), findsOneWidget);
  expect(find.textContaining('Call 999'), findsOneWidget);
});

testWidgets('Confirm button pops with PickedLocation', (tester) async {
  PickedLocation? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await Navigator.push<PickedLocation>(
              context,
              MaterialPageRoute(
                builder: (_) => LocationPickerScreen(
                  initialLocation: const LatLng(55.9533, -3.1883),
                ),
              ),
            );
          },
          child: const Text('Open Picker'),
        ),
      ),
    ),
  );
  
  await tester.tap(find.text('Open Picker'));
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
  
  expect(result, isNotNull);
  expect(result!.coordinates.latitude, closeTo(55.9533, 0.01));
});
```

---

## 2. LocationSearchBar

### Contract

```dart
/// Search bar with autocomplete for places and what3words
///
/// Detects input type:
/// - Starts with /// or / → what3words search
/// - Otherwise → Google Places autocomplete
class LocationSearchBar extends StatelessWidget {
  /// Current search query
  final String query;
  
  /// Autocomplete suggestions
  final List<PlaceSearchResult>? suggestions;
  
  /// Loading state for suggestions
  final bool isLoading;
  
  /// Called when query changes (debounced by controller)
  final ValueChanged<String> onQueryChanged;
  
  /// Called when suggestion selected
  final ValueChanged<PlaceSearchResult> onSuggestionSelected;
  
  /// Called when what3words entered and validated
  final ValueChanged<String> onWhat3wordsEntered;

  const LocationSearchBar({
    super.key,
    required this.query,
    this.suggestions,
    this.isLoading = false,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    required this.onWhat3wordsEntered,
  });
}
```

### UI Behavior

1. **Empty state**: Placeholder "Search place or ///what3words..."
2. **Typing**: Show suggestions dropdown below
3. **what3words detection**: Input starts with `/` or `///` → validate w3w format
4. **Loading**: Show spinner in trailing position
5. **Clear**: X button when query non-empty

### Test Assertions

```dart
testWidgets('detects what3words input', (tester) async {
  String? w3wResult;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LocationSearchBar(
          query: '',
          onQueryChanged: (_) {},
          onSuggestionSelected: (_) {},
          onWhat3wordsEntered: (w3w) => w3wResult = w3w,
        ),
      ),
    ),
  );
  
  await tester.enterText(find.byType(TextField), '///slurs.this.name');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  
  expect(w3wResult, equals('slurs.this.name'));
});

testWidgets('shows suggestions dropdown', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LocationSearchBar(
          query: 'Edin',
          suggestions: [
            PlaceSearchResult(placeId: '1', primaryText: 'Edinburgh'),
            PlaceSearchResult(placeId: '2', primaryText: 'Edinburgh Castle'),
          ],
          onQueryChanged: (_) {},
          onSuggestionSelected: (_) {},
          onWhat3wordsEntered: (_) {},
        ),
      ),
    ),
  );
  
  expect(find.text('Edinburgh'), findsOneWidget);
  expect(find.text('Edinburgh Castle'), findsOneWidget);
});
```

---

## 3. LocationInfoPanel

### Contract

```dart
/// Bottom panel showing selected location details
///
/// Displays coordinates (redacted) and what3words address
/// with copy and GPS buttons.
class LocationInfoPanel extends StatelessWidget {
  /// Selected coordinates (displayed with 2dp precision)
  final LatLng coordinates;
  
  /// what3words address (null while loading or unavailable)
  final What3wordsAddress? what3words;
  
  /// Loading state for what3words fetch
  final bool isLoadingWhat3words;
  
  /// Error message to display
  final String? errorMessage;
  
  /// Whether GPS button should be enabled
  final bool isGpsAvailable;
  
  /// Called when copy button tapped
  final VoidCallback? onCopyWhat3words;
  
  /// Called when GPS button tapped
  final VoidCallback? onUseGps;

  const LocationInfoPanel({
    super.key,
    required this.coordinates,
    this.what3words,
    this.isLoadingWhat3words = false,
    this.errorMessage,
    this.isGpsAvailable = false,
    this.onCopyWhat3words,
    this.onUseGps,
  });
}
```

### UI Structure

```
┌─────────────────────────────────────────────────────────────────┐
│  📍 55.95, -3.19                                                │
│  ///slurs.this.name  [📋]            [📍 Use GPS]              │
│  ─────────────────────────────────────────────────────────────  │
│  [Error message if any]                                         │
└─────────────────────────────────────────────────────────────────┘
```

### States

| State | Coordinates | what3words | Copy | GPS |
|-------|-------------|------------|------|-----|
| Initial | Shown | Loading spinner | Disabled | Enabled/Disabled |
| Ready | Shown | Shown with /// | Enabled | Enabled/Disabled |
| Error | Shown | "Unavailable" | Hidden | Enabled/Disabled |

### Test Assertions

```dart
testWidgets('shows loading state for what3words', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LocationInfoPanel(
          coordinates: const LatLng(55.9533, -3.1883),
          isLoadingWhat3words: true,
        ),
      ),
    ),
  );
  
  expect(find.text('55.95, -3.19'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('shows what3words with copy button', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LocationInfoPanel(
          coordinates: const LatLng(55.9533, -3.1883),
          what3words: What3wordsAddress.tryParse('slurs.this.name'),
          onCopyWhat3words: () {},
        ),
      ),
    ),
  );
  
  expect(find.text('///slurs.this.name'), findsOneWidget);
  expect(find.byIcon(Icons.copy), findsOneWidget);
});

testWidgets('copy button triggers callback', (tester) async {
  bool copied = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LocationInfoPanel(
          coordinates: const LatLng(55.9533, -3.1883),
          what3words: What3wordsAddress.tryParse('slurs.this.name'),
          onCopyWhat3words: () => copied = true,
        ),
      ),
    ),
  );
  
  await tester.tap(find.byIcon(Icons.copy));
  expect(copied, isTrue);
});
```

---

## 4. CrosshairOverlay

### Contract

```dart
/// Fixed crosshair overlay for center of map
///
/// Purely decorative - no interaction. Shows selected point.
class CrosshairOverlay extends StatelessWidget {
  /// Size of crosshair icon
  final double size;
  
  /// Color of crosshair
  final Color? color;

  const CrosshairOverlay({
    super.key,
    this.size = 48.0,
    this.color,
  });
}
```

### UI

Simple centered crosshair icon (`Icons.add` or custom asset) with subtle shadow for visibility on any map background.

### Test Assertions

```dart
testWidgets('renders centered crosshair', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Placeholder(), // Map placeholder
            CrosshairOverlay(),
          ],
        ),
      ),
    ),
  );
  
  final crosshair = find.byType(CrosshairOverlay);
  expect(crosshair, findsOneWidget);
  
  // Verify centered
  final widget = tester.widget<CrosshairOverlay>(crosshair);
  expect(widget.size, equals(48.0));
});
```

---

## Theme Integration

All widgets use existing theme variables:

```dart
// From BrandPalette
final scheme = Theme.of(context).colorScheme;

// Surface colors
scheme.surface           // Panel background
scheme.surfaceContainerHigh  // Card background (from LocationCard)

// Text colors  
scheme.onSurface         // Primary text
scheme.onSurfaceVariant  // Secondary text (coordinates)

// Interactive
scheme.primary           // Buttons, links
scheme.secondaryContainer // Tonal buttons (from LocationCard)

// From existing patterns
theme.textTheme.bodyLarge    // Coordinates
theme.textTheme.bodySmall    // what3words, subtitles
```

---

*Widget contracts complete. See service-contracts.md for API contracts.*
