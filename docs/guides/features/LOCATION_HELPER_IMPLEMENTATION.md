---
title: Location Helper for Report Fire Screen - Implementation Plan
status: in-progress
created: 2025-12-03
last_updated: 2025-12-03
category: guides
subcategory: features
related:
  - ../setup/google-maps.md
  - ../../reference/test-regions.md
ticket: A16-location-helper
---

# Location Helper for Report Fire Screen

## Overview

Add an optional "Location Helper" card to the Report Fire screen that helps users find and communicate their location when calling 999/101/Crimestoppers.

**Key Principle**: This feature does NOT contact emergency services or submit reports. It only helps users read out location information when they make their own phone calls.

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Controller** | Create `ReportFireController` (ChangeNotifier) | Future-proofed for fire report submission feature |
| **Navigation** | Use existing go_router with `context.push()` + result handling | Consistent with codebase patterns |
| **what3words** | Parse `String?` → `What3wordsAddress?` on mapping | Minimal disruption to existing `PickedLocation` |
| **Coordinates** | 5dp with helper text: "Exact coordinates recommended for fire service" | Enhanced precision (~1m) for emergency responders |
| **Layout** | Separate card above emergency actions card | Clean separation of concerns |

---

## Constitutional Compliance

| Gate | Requirement | Implementation |
|------|-------------|----------------|
| **C2** | Privacy - no raw coordinate logging | Use `LocationUtils.logRedact()` in controller |
| **C3** | Accessibility - ≥48dp touch targets | All buttons use `SizedBox(height: 48)` |
| **C3** | Accessibility - semantic labels | `Semantics` widgets on all interactive elements |
| **C4** | Transparency | Clear disclaimer: "This app does not contact emergency services" |

---

## File Changes Summary

### New Files (5)

| # | File | Description |
|---|------|-------------|
| 1 | `lib/features/report/models/report_fire_state.dart` | State model with `ReportFireLocation` |
| 2 | `lib/features/report/controllers/report_fire_controller.dart` | ChangeNotifier controller |
| 3 | `lib/features/report/widgets/report_fire_location_helper_card.dart` | Helper card widget |
| 4 | `test/unit/features/report/models/report_fire_state_test.dart` | Unit tests for state model |
| 5 | `test/widget/features/report/report_fire_location_helper_card_test.dart` | Widget tests |

### Modified Files (2)

| # | File | Changes |
|---|------|---------|
| 1 | `lib/features/report/screens/report_fire_screen.dart` | Convert to StatefulWidget, add controller, insert card |
| 2 | `lib/app.dart` | Update `/report` route to inject controller |

---

## Implementation Phases

### Phase 1: Models & State

**File: `lib/features/report/models/report_fire_state.dart`**

```dart
import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart' as app;
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

/// Location data for fire report helper
/// 
/// Stores user-selected fire location to help communicate with emergency services.
/// Does NOT submit anything - purely informational.
class ReportFireLocation extends Equatable {
  final app.LatLng coordinates;
  final String? nearestPlaceName;
  final What3wordsAddress? what3words;
  final DateTime selectedAt;

  const ReportFireLocation({
    required this.coordinates,
    this.nearestPlaceName,
    this.what3words,
    required this.selectedAt,
  });

  /// Factory from PickedLocation result
  factory ReportFireLocation.fromPickedLocation({
    required app.LatLng coordinates,
    String? what3wordsRaw,
    String? placeName,
  }) {
    return ReportFireLocation(
      coordinates: coordinates,
      nearestPlaceName: placeName,
      what3words: what3wordsRaw != null 
          ? What3wordsAddress.tryParse(what3wordsRaw) 
          : null,
      selectedAt: DateTime.now(),
    );
  }

  /// 5dp precision for emergency services
  String get formattedCoordinates =>
      '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}';

  /// Plain text for clipboard
  String toClipboardText() {
    final buffer = StringBuffer();
    if (nearestPlaceName != null) {
      buffer.writeln('Nearest place: $nearestPlaceName');
    }
    buffer.writeln('Coordinates: $formattedCoordinates');
    if (what3words != null) {
      buffer.writeln('what3words: ${what3words!.displayFormat}');
    }
    return buffer.toString().trim();
  }

  @override
  List<Object?> get props => [coordinates, nearestPlaceName, what3words, selectedAt];
}

/// State for Report Fire screen
class ReportFireState extends Equatable {
  final ReportFireLocation? fireLocation;
  
  // Future fields for report submission:
  // final String? fireDescription;
  // final List<String>? photoUrls;
  // final bool isSubmitting;

  const ReportFireState({this.fireLocation});
  const ReportFireState.initial() : fireLocation = null;

  ReportFireState copyWith({
    ReportFireLocation? fireLocation,
    bool clearLocation = false,
  }) {
    return ReportFireState(
      fireLocation: clearLocation ? null : (fireLocation ?? this.fireLocation),
    );
  }

  bool get hasLocation => fireLocation != null;

  @override
  List<Object?> get props => [fireLocation];
}
```

---

### Phase 2: Controller

**File: `lib/features/report/controllers/report_fire_controller.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/picked_location.dart';
import 'package:wildfire_mvp_v3/features/report/models/report_fire_state.dart';

/// Controller for Report Fire screen
class ReportFireController extends ChangeNotifier {
  ReportFireState _state = const ReportFireState.initial();
  
  ReportFireState get state => _state;

  void _updateState(ReportFireState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Open location picker in fireReport mode
  Future<void> openLocationPicker(BuildContext context) async {
    final result = await context.push<PickedLocation>(
      '/location-picker',
      extra: LocationPickerMode.fireReport,
    );

    if (result != null) {
      onLocationPicked(result);
    }
  }

  /// Process picked location
  void onLocationPicked(PickedLocation picked) {
    final newLocation = ReportFireLocation.fromPickedLocation(
      coordinates: picked.coordinates,
      what3wordsRaw: picked.what3words,
      placeName: picked.placeName,
    );
    _updateState(_state.copyWith(fireLocation: newLocation));
    debugPrint('🔥 Fire location set: ${newLocation.formattedCoordinates}');
  }

  void clearLocation() {
    _updateState(_state.copyWith(clearLocation: true));
  }
  
  // Future: submitFireReport(), addPhoto(), etc.
}
```

---

### Phase 3: Location Helper Card Widget

**File: `lib/features/report/widgets/report_fire_location_helper_card.dart`**

Key features:
- Header with icon: "Location to give when you call"
- Subtitle: "Optional — helps you tell 999 where the fire is."
- Content when location set:
  - Nearest place (if available)
  - Coordinates (5dp, monospace) + helper text
  - what3words (or "Unavailable")
- Empty state message
- Buttons: "Open map to set location" / "Update location" + "Copy" icon
- Disclaimer: "This app does not contact emergency services..."

All buttons ≥48dp, semantic labels throughout.

---

### Phase 4: Update Report Fire Screen

**File: `lib/features/report/screens/report_fire_screen.dart`**

Changes:
1. Convert `StatelessWidget` → `StatefulWidget`
2. Accept `ReportFireController` as constructor parameter
3. Listen to controller in `initState`, remove in `dispose`
4. Insert `ReportFireLocationHelperCard` between banner and emergency card
5. Pass `controller.state.fireLocation` and `controller.openLocationPicker` to card

Layout order:
1. `_Banner` (existing)
2. `SizedBox(height: 16)`
3. `ReportFireLocationHelperCard` (NEW)
4. `SizedBox(height: 16)` 
5. Emergency actions `Card` (existing)
6. `SizedBox(height: 16)`
7. `_TipsCard` (existing)

---

### Phase 5: Update App Router

**File: `lib/app.dart`**

Update `/report` route:

```dart
GoRoute(
  path: '/report',
  name: 'report',
  builder: (context, state) {
    final controller = ReportFireController();
    return ReportFireScreen(controller: controller);
  },
),
```

Note: For now, controller is created per-navigation. Future optimization could use Provider/Riverpod for persistence across tab switches.

---

### Phase 6: Tests

**Unit tests:** `test/unit/features/report/models/report_fire_state_test.dart`
- `ReportFireLocation.formattedCoordinates` returns 5dp
- `ReportFireLocation.toClipboardText()` formats correctly
- `ReportFireLocation.fromPickedLocation()` parses what3words
- `ReportFireState.copyWith()` works correctly

**Widget tests:** `test/widget/features/report/report_fire_location_helper_card_test.dart`
- Shows empty state when no location
- Shows location details when set
- "Open map" button triggers callback
- "Copy" button copies to clipboard
- Disclaimer text is visible
- All buttons ≥48dp

---

## Acceptance Criteria

- [ ] Helper card visible below banner on Report Fire screen
- [ ] Card clearly states it's optional and doesn't contact services
- [ ] Tapping "Open map to set location" opens LocationPickerScreen
- [ ] After selecting location, card shows:
  - [ ] Nearest place (if available)
  - [ ] Coordinates with 5dp precision in monospace
  - [ ] Helper text: "Exact coordinates recommended for fire service"
  - [ ] what3words (or "Unavailable")
- [ ] Tapping copy button copies formatted text to clipboard
- [ ] SnackBar confirms copy
- [ ] All buttons ≥48dp touch targets
- [ ] Screen reader announces all interactive elements
- [ ] `flutter analyze` passes with 0 errors

---

## Testing Checklist

```bash
# Run after implementation
flutter analyze lib/features/report/
flutter test test/unit/features/report/
flutter test test/widget/features/report/

# Manual testing
# 1. Navigate to Report Fire tab
# 2. Verify helper card visible below banner
# 3. Tap "Open map to set location"
# 4. Select a location on map, confirm
# 5. Verify card shows coordinates, w3w, place name
# 6. Tap copy button, verify SnackBar
# 7. Paste into Notes app, verify format
# 8. Test with VoiceOver/TalkBack enabled
```

---

## Future Extensions

When implementing actual fire report submission:

1. Extend `ReportFireState` with:
   - `fireDescription: String?`
   - `photoUrls: List<String>?`
   - `isSubmitting: bool`
   - `submissionError: String?`
   - `submittedAt: DateTime?`

2. Add controller methods:
   - `setFireDescription(String)`
   - `addPhoto(File)`
   - `removePhoto(int index)`
   - `submitFireReport()`
   - `resetReport()`

3. Update screen with:
   - Description text field
   - Photo picker
   - Submit button with loading state
   - Success/error feedback

4. Add backend integration:
   - Firebase/API service
   - Offline queue
   - Push notification confirmation
