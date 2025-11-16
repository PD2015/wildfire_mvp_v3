# FireDetailsBottomSheet Widget Contract

## Widget Interface

```dart
class FireDetailsBottomSheet extends StatefulWidget {
  final FireIncident incident;           // Required fire incident to display
  final VoidCallback onClose;            // Required callback when sheet dismissed
  final VoidCallback? onRetry;           // Optional retry callback for failed loads
  final bool isLoading;                  // Whether additional data is loading
  final String? errorMessage;            // Error message to display if applicable
  
  const FireDetailsBottomSheet({
    Key? key,
    required this.incident,
    required this.onClose,
    this.onRetry,
    this.isLoading = false,
    this.errorMessage,
  }) : super(key: key);
}
```

## UI Component Structure

### Layout Hierarchy
```
DraggableScrollableSheet
├── Container (rounded top corners, elevation)
│   ├── Column
│   │   ├── Handle Bar (drag indicator)
│   │   ├── Header Section
│   │   │   ├── Fire Icon + Title
│   │   │   ├── Close Button (X)
│   │   │   └── Data Source Chip
│   │   ├── Fire Details Section
│   │   │   ├── Detection Time Row
│   │   │   ├── Sensor Source Row  
│   │   │   ├── Confidence Level Row
│   │   │   ├── Fire Radiative Power Row
│   │   │   └── Last Update Row
│   │   ├── Location Section
│   │   │   ├── Distance from User Row
│   │   │   └── Bearing Direction Row
│   │   ├── Risk Assessment Section
│   │   │   ├── Risk Level Indicator
│   │   │   ├── FWI Value Display
│   │   │   └── Risk Timestamp
│   │   └── Action Section
│   │       ├── Retry Button (if error)
│   │       └── More Info Button
```

## Accessibility Requirements

### Semantic Structure
```dart
Semantics(
  container: true,
  label: 'Fire incident details',
  child: Column(
    children: [
      Semantics(
        header: true,
        label: 'Fire detected at ${incident.detectedAt.format()}',
        child: HeaderSection(),
      ),
      Semantics(
        label: 'Fire characteristics',
        child: FireDetailsSection(),
      ),
      Semantics(
        label: 'Distance and direction',  
        child: LocationSection(),
      ),
      Semantics(
        label: 'Wildfire risk assessment',
        child: RiskSection(),
      ),
    ],
  ),
);
```

### Touch Targets
- **Close Button**: Minimum 44dp × 44dp
- **Retry Button**: Minimum 44dp × 44dp  
- **More Info Button**: Minimum 44dp × 44dp
- **Drag Handle**: Minimum 44dp height, full width

### Screen Reader Support
- Header announces fire detection time and location
- Each data row has descriptive label (e.g., "Confidence level: 85 percent")
- Risk level announced with color-independent description
- Loading states announced as "Loading risk assessment"
- Error states announced with retry instructions

## State Management

### Loading State UI
```dart
Widget _buildLoadingState() {
  return Column(
    children: [
      _buildFireDetails(), // Show available incident data
      const Divider(),
      Row(
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(width: 16),
          Semantics(
            liveRegion: true,
            label: 'Loading risk assessment and distance information',
            child: const Text('Loading additional details...'),
          ),
        ],
      ),
    ],
  );
}
```

### Error State UI
```dart
Widget _buildErrorState(String message) {
  return Column(
    children: [
      _buildFireDetails(), // Show available incident data
      const Divider(),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).errorColor),
            const SizedBox(height: 8),
            Semantics(
              label: 'Error: $message',
              child: Text(message, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ],
  );
}
```

### Data Display Components

#### Fire Details Section
```dart
Widget _buildFireDetailsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildDetailRow(
        icon: Icons.schedule,
        label: 'Detected',
        value: incident.detectedAt.format('MMM d, y h:mm a'),
        semanticLabel: 'Fire detected on ${incident.detectedAt.format()}',
      ),
      _buildDetailRow(
        icon: Icons.satellite,
        label: 'Source',
        value: incident.source,
        semanticLabel: 'Detected by ${incident.source} satellite sensor',
      ),
      _buildDetailRow(
        icon: Icons.trending_up,
        label: 'Confidence',
        value: '${incident.confidence.round()}%',
        semanticLabel: 'Detection confidence ${incident.confidence.round()} percent',
      ),
      if (incident.frp != null)
        _buildDetailRow(
          icon: Icons.local_fire_department,
          label: 'Fire Power',
          value: '${incident.frp!.toStringAsFixed(1)} MW',
          semanticLabel: 'Fire radiative power ${incident.frp!.toStringAsFixed(1)} megawatts',
        ),
      _buildDetailRow(
        icon: Icons.update,
        label: 'Last Update',
        value: incident.lastUpdate.format('h:mm a'),
        semanticLabel: 'Last updated at ${incident.lastUpdate.format()}',
      ),
    ],
  );
}
```

#### Risk Assessment Display
```dart
Widget _buildRiskSection(RiskAssessment? risk) {
  if (risk == null) return const SizedBox.shrink();
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: RiskPalette.colorFor(risk.level).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: RiskPalette.colorFor(risk.level)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: RiskPalette.colorFor(risk.level),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Wildfire risk level ${risk.level.displayName}',
              child: Text(
                risk.level.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RiskPalette.colorFor(risk.level),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: 'Fire weather index ${risk.fwiValue.toStringAsFixed(1)}',
              child: Text('FWI: ${risk.fwiValue.toStringAsFixed(1)}'),
            ),
            Semantics(
              label: 'Risk assessed ${risk.assessmentTime.timeAgo()}',
              child: Text('Updated ${risk.assessmentTime.timeAgo()}'),
            ),
          ],
        ),
      ],
    ),
  );
}
```

## Interaction Patterns

### Opening Animation
- Slides up from bottom with 300ms duration
- Drag handle visible immediately
- Content fades in after slide completes
- Focus moves to close button for accessibility

### Dismissal Methods
1. **Tap outside sheet**: Calls onClose callback
2. **Swipe down**: DraggableScrollableSheet built-in gesture
3. **Close button**: Explicit tap action
4. **Escape key**: For keyboard users

### Retry Flow
1. User sees error state with retry button
2. Tap retry button calls onRetry callback  
3. Widget transitions to loading state
4. Parent widget handles actual retry logic
5. Widget receives updated props with success/error result

## Constitutional Compliance

### C3. Accessibility
- All interactive elements ≥44dp touch targets
- Complete semantic labeling for screen readers
- Color-independent information display
- Proper focus management and navigation

### C4. Trust & Transparency  
- Data source chip prominently displayed
- Timestamps for detection and last update visible
- Risk assessment includes assessment time
- DEMO DATA indicator when in mock mode

### C5. Resilience & Test Coverage
- Graceful error state handling
- Retry mechanism for failed data loads
- Loading states prevent user confusion
- Fallback content when risk data unavailable

## Testing Strategy

### Widget Tests
```dart
testWidgets('displays fire incident details correctly', (tester) async {
  // Given: Fire incident with all fields populated
  // When: Widget renders
  // Then: All details displayed with correct formatting and labels
});

testWidgets('shows loading state for risk assessment', (tester) async {
  // Given: Fire incident but no risk data yet
  // When: Widget renders with isLoading=true
  // Then: Loading indicator and message displayed
});

testWidgets('displays error state with retry button', (tester) async {
  // Given: Error loading risk or distance data
  // When: Widget renders with errorMessage
  // Then: Error UI displayed with working retry button
});

testWidgets('meets accessibility requirements', (tester) async {
  // Given: Widget with complete fire data
  // When: Accessibility evaluation performed
  // Then: All semantic labels present, touch targets adequate
});
```

### Integration Tests
```dart
testWidgets('end-to-end bottom sheet interaction', (tester) async {
  // Given: Map with fire markers
  // When: User taps marker
  // Then: Bottom sheet opens with fire details
  // And: Risk assessment loads successfully
  // And: User can dismiss sheet via multiple methods
});
```