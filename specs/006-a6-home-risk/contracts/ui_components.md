# UI Components Contract

## Overview
Specialized UI components for the home screen that ensure constitutional compliance and accessibility requirements.

## SourceChip Component

### Purpose
Display data source information (EFFIS/SEPA/Cache/Mock) with proper styling and accessibility.

### API Contract
```dart
class SourceChip extends StatelessWidget {
  const SourceChip({
    super.key,
    required this.source,
    required this.semanticsLabel,
  });
  
  final DataSource source;
  final String semanticsLabel;
}
```

### Visual Design
```dart
Widget build(BuildContext context) {
  return Chip(
    label: Text(source.displayName),
    backgroundColor: _getSourceColor(source),
    labelStyle: TextStyle(
      color: _getSourceTextColor(source),
      fontWeight: FontWeight.w500,
    ),
    side: BorderSide.none,
  );
}

Color _getSourceColor(DataSource source) {
  return switch (source) {
    DataSource.live => Colors.green.shade100,
    DataSource.cached => Colors.orange.shade100, 
    DataSource.mock => Colors.grey.shade200,
  };
}
```

### Accessibility Requirements
- MUST have semantic label describing data source
- Text contrast MUST meet WCAG AA standards  
- Touch target MUST be ≥44dp if interactive

## TimestampText Component

### Purpose
Display "Last Updated" timestamp with relative time formatting and staleness indication.

### API Contract
```dart
class TimestampText extends StatelessWidget {
  const TimestampText({
    super.key,
    required this.timestamp,
    required this.semanticsLabel,
    this.isStale = false,
  });
  
  final DateTime timestamp;
  final String semanticsLabel;
  final bool isStale;
}
```

### Formatting Logic
```dart
String _formatRelativeTime(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  
  if (difference.inMinutes < 1) return 'Updated just now';
  if (difference.inMinutes < 60) return 'Updated ${difference.inMinutes} minutes ago';
  if (difference.inHours < 24) return 'Updated ${difference.inHours} hours ago';
  return 'Updated ${difference.inDays} days ago';
}

Widget build(BuildContext context) {
  return Text(
    _formatRelativeTime(timestamp),
    style: TextStyle(
      fontSize: 14,
      color: isStale ? Colors.orange.shade700 : Colors.grey.shade600,
      fontStyle: isStale ? FontStyle.italic : FontStyle.normal,
    ),
    semanticsLabel: semanticsLabel,
  );
}
```

### Staleness Indicators
- Text color changes to orange for stale data (>6 hours)
- Italic style applied for stale data
- Semantic label includes staleness context

## CachedDataBadge Component

### Purpose
Prominent indication when displaying cached data instead of live data.

### API Contract
```dart
class CachedDataBadge extends StatelessWidget {
  const CachedDataBadge({
    super.key,
    required this.timestamp,
    required this.semanticsLabel,
  });
  
  final DateTime timestamp;
  final String semanticsLabel;
}
```

### Visual Design
```dart
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.orange.shade100,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.orange.shade300),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: Colors.orange.shade700,
        ),
        SizedBox(width: 4),
        Text(
          'Using cached data',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.orange.shade700,
          ),
        ),
      ],
    ),
  );
}
```

### Accessibility Requirements
- Semantic label MUST describe cached data context
- Color contrast MUST meet WCAG AA standards
- Icon MUST have semantic meaning for screen readers

## RetryButton Component

### Purpose
Retry button with loading state indication and proper accessibility.

### API Contract
```dart
class RetryButton extends StatelessWidget {
  const RetryButton({
    super.key,
    required this.onPressed,
    required this.semanticsLabel,
    this.isLoading = false,
  });
  
  final VoidCallback onPressed;
  final String semanticsLabel;
  final bool isLoading;
}
```

### Implementation
```dart
Widget build(BuildContext context) {
  return ElevatedButton.icon(
    onPressed: isLoading ? null : onPressed,
    icon: isLoading 
      ? SizedBox(
          width: 16, 
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(Icons.refresh),
    label: Text(isLoading ? 'Retrying...' : 'Retry'),
    style: ElevatedButton.styleFrom(
      minimumSize: Size(88, 44), // 44dp minimum height
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
```

### Interaction States
- Disabled during loading with visual spinner
- Proper Material feedback on press
- Loading state shows progress indication

## ManualLocationButton Component

### Purpose
Button to trigger manual location entry dialog.

### API Contract
```dart
class ManualLocationButton extends StatelessWidget {
  const ManualLocationButton({
    super.key,
    required this.onPressed,
    required this.semanticsLabel,
  });
  
  final VoidCallback onPressed;
  final String semanticsLabel;
}
```

### Implementation
```dart
Widget build(BuildContext context) {
  return OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(Icons.location_on),
    label: Text('Set Location'),
    style: OutlinedButton.styleFrom(
      minimumSize: Size(88, 44), // 44dp minimum height
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
```

## ErrorMessage Component

### Purpose
User-friendly error message display with proper semantic labeling.

### API Contract
```dart
class ErrorMessage extends StatelessWidget {
  const ErrorMessage({
    super.key,
    required this.message,
    required this.semanticsLabel,
    this.icon,
  });
  
  final String message;
  final String semanticsLabel;
  final IconData? icon;
}
```

### Implementation
```dart
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(16),
    margin: EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(
          icon ?? Icons.error_outline,
          color: Colors.red.shade600,
          size: 20,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}
```

### Error Types and Styling
- Network errors: warning icon with orange styling
- Service errors: error icon with red styling
- Validation errors: info icon with blue styling

## ManualLocationDialog Component

### Purpose
Dialog for manual coordinate entry with validation and accessibility.

### API Contract
```dart
class ManualLocationDialog extends StatefulWidget {
  const ManualLocationDialog({super.key});
  
  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}
```

### Form Implementation
```dart
class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _placeController = TextEditingController();
  String? _validationError;
  
  bool _validateCoordinates(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }
  
  void _saveLocation() {
    if (!_formKey.currentState!.validate()) return;
    
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    
    if (lat == null || lon == null || !_validateCoordinates(lat, lon)) {
      setState(() {
        _validationError = 'Please enter valid coordinates (-90 to 90 for latitude, -180 to 180 for longitude)';
      });
      return;
    }
    
    Navigator.of(context).pop(ManualLocationResult(
      coordinates: LatLng(lat, lon),
      placeName: _placeController.text.isNotEmpty ? _placeController.text : null,
    ));
  }
}
```

### Form Fields
```dart
TextFormField(
  controller: _latController,
  decoration: InputDecoration(
    labelText: 'Latitude',
    hintText: 'e.g., 55.9533',
    semanticCounterText: 'Latitude coordinate between -90 and 90',
  ),
  keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Latitude is required';
    final lat = double.tryParse(value!);
    if (lat == null) return 'Invalid latitude format';
    if (lat < -90 || lat > 90) return 'Latitude must be between -90 and 90';
    return null;
  },
)
```

### Accessibility Features
- Form labels with semantic descriptions
- Clear validation error messages
- Proper keyboard types for numeric input
- Error announcements for screen readers

## Loading Indicator Component

### Purpose
Consistent loading indicator with semantic labels.

### API Contract
```dart
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    required this.semanticsLabel,
    this.message,
  });
  
  final String semanticsLabel;
  final String? message;
}
```

### Implementation
```dart
Widget build(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CircularProgressIndicator(
        semanticsLabel: semanticsLabel,
      ),
      if (message != null) ...[
        SizedBox(height: 16),
        Text(
          message!,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ],
  );
}
```

## Testing Contracts

### Widget Testing
```dart
// Test component rendering
testWidgets('SourceChip displays correct source', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: SourceChip(
      source: DataSource.live,
      semanticsLabel: 'Live data source',
    ),
  ));
  
  expect(find.text('Live'), findsOneWidget);
  expect(find.bySemanticsLabel('Live data source'), findsOneWidget);
});

// Test accessibility
testWidgets('RetryButton meets 44dp minimum size', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: RetryButton(
      onPressed: () {},
      semanticsLabel: 'Retry action',
    ),
  ));
  
  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  expect(button.style?.minimumSize?.resolve({}), Size(88, 44));
});
```

### Integration Testing
- Dialog interaction flows
- Error state displays  
- Loading state transitions
- Touch target verification

## Constitutional Compliance

### C3: Accessibility
- All components MUST have semantic labels
- Interactive elements MUST be ≥44dp
- Color contrast MUST meet WCAG AA standards
- Screen reader compatibility verified

### C4: Trust & Transparency
- Source information clearly displayed
- Timestamp formatting human-readable
- Cached data prominently indicated
- Official color schemes enforced

### C5: Resilience
- Error states clearly communicated
- Loading states provide feedback
- Retry functionality always available
- Input validation prevents crashes

---

**Status**: UI component contracts defined with accessibility and constitutional compliance
**Dependencies**: Material Design widgets, existing theme system
**Testing**: Widget and integration test patterns specified