# Quick Implementation Guide: A7 — Location Display

**When you're ready to implement coordinate and place name display in the home screen.**

## 🚀 Quick Start (30 minutes)

### Step 1: Update HomeState Model (5 minutes)
```dart
// lib/models/home_state.dart
class HomeStateSuccess extends HomeState {
  final FireRisk riskData;
  final LatLng location;
  final DateTime lastUpdated;
  final String? placeName; // ADD THIS LINE

  const HomeStateSuccess({
    required this.riskData,
    required this.location,
    required this.lastUpdated,
    this.placeName, // ADD THIS LINE
  });

  @override
  List<Object?> get props => [riskData, location, lastUpdated, placeName]; // UPDATE THIS
}

// Also update HomeStateError similarly...
```

### Step 2: Create LocationInfo Widget (15 minutes)
```dart
// lib/widgets/location_info.dart
import 'package:flutter/material.dart';
import '../models/location_models.dart';
import '../utils/location_utils.dart';

class LocationInfo extends StatelessWidget {
  final LatLng coordinates;
  final String? placeName;

  const LocationInfo({
    super.key,
    required this.coordinates,
    this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    final displayCoords = LocationUtils.logRedact(
      coordinates.latitude, 
      coordinates.longitude
    );
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (placeName != null) ...[
              Row(
                children: [
                  const Icon(Icons.place, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      placeName!,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                const Icon(Icons.my_location, size: 16),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Location coordinates: $displayCoords',
                  child: Text(
                    displayCoords,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Update HomeScreen (10 minutes)
```dart
// lib/screens/home_screen.dart
// Add import at top:
import '../widgets/location_info.dart';

// In _buildStateInfo() method, update the HomeStateSuccess case:
case HomeStateSuccess(:final location, :final placeName):
  return Column(
    children: [
      // Existing success state info...
      
      const SizedBox(height: 16),
      LocationInfo(
        coordinates: location,
        placeName: placeName,
      ),
    ],
  );
```

## 🎯 What You'll See

**Before**: Just fire risk banner with timestamp  
**After**: Fire risk banner + location info showing coordinates like "55.95, -3.19" and place name (if available)

## 🧪 Quick Test

```bash
flutter run
# Look for coordinate display below the fire risk banner
# Try "Set Location" with a place name to see both coordinates and place name
```

## 📈 Phase 2: Add Place Name Loading (20 minutes)

### Update HomeController
```dart
// lib/controllers/home_controller.dart
Future<String?> getCachedPlaceName() async {
  final cache = LocationCache();
  return await cache.loadPlaceName();
}

// In _loadData() method, after location resolution:
final placeName = await getCachedPlaceName();

_updateState(HomeStateSuccess(
  riskData: riskResult.right,
  location: locationResult.right,
  lastUpdated: DateTime.now().toUtc(),
  placeName: placeName, // ADD THIS
));
```

## 🛡️ Privacy & Compliance

- **Coordinates**: Automatically redacted to 2 decimal places (e.g., 55.95, -3.19)
- **Place Names**: Only city/region level (no house numbers)
- **Accessibility**: Semantic labels for screen readers
- **Transparency**: Clear location attribution for user trust

## 🔧 Troubleshooting

**Widget not showing**: Check that LocationUtils.logRedact() is imported  
**Place names not loading**: Verify LocationCache is accessible  
**Layout issues**: Ensure proper SizedBox spacing (16dp recommended)  

## 📁 Files Modified

1. `lib/models/home_state.dart` - Add placeName fields
2. `lib/widgets/location_info.dart` - New widget (create file)
3. `lib/screens/home_screen.dart` - Import and display LocationInfo
4. `lib/controllers/home_controller.dart` - Load place names (Phase 2)

## 🎨 Visual Design

```
┌─────────────────────────────┐
│ 📍 Edinburgh, Scotland      │  ← Place name (if available)
│ 📍 55.95, -3.19            │  ← Privacy-redacted coordinates
└─────────────────────────────┘
```

---

**Ready to code?** Start with the HomeState model update, then create the LocationInfo widget, and finally integrate it into HomeScreen. Each step provides immediate visual feedback!