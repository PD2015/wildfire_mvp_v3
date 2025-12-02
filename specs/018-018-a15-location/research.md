# Research: 018-A15 Location Picker & what3words Integration

**Branch**: `018-018-a15-location` | **Date**: 2025-11-27 | **Spec**: spec.md

---

## 1. what3words API Integration

### Decision: Direct HTTP Integration (not SDK)

**Rationale**:
- Matches existing service patterns (`EffisService`, `SepaService`, `FireRiskService`)
- Uses existing `http` package + `dartz` Either pattern already in project
- Zero bundle size increase vs ~2-3MB for official SDK
- Full control over error handling, retry logic, and timeout configuration
- Project already has comprehensive Either-based error handling pattern

**API Endpoints Required**:
| Endpoint | Purpose | Rate Limit |
|----------|---------|------------|
| `POST /v3/convert-to-coordinates` | what3words → LatLng | 1000/day free |
| `POST /v3/convert-to-3wa` | LatLng → what3words | 1000/day free |
| `GET /v3/autosuggest` | Search suggestions | 1000/day free |

**Authentication**: API key in `X-Api-Key` header (same pattern as EFFIS)

**Alternatives Rejected**:
- **Official SDK** (`what3words_api` package): 2.5MB bundle increase, less control over error handling
- **Geocoding-only**: Doesn't provide what3words which is specifically required for Scotland emergency services

---

## 2. Google Places API Integration

### Decision: Use existing Google Maps API key with Places API enabled

**Rationale**:
- Google Cloud project already configured for Maps API (A10)
- Places API uses same key with additional API enablement
- No additional billing setup required (shared quota)
- Autocomplete pricing: $2.83/1000 sessions (within free tier $200/month)

**API Endpoints Required**:
| Endpoint | Purpose |
|----------|---------|
| Place Autocomplete | Search suggestions as user types |
| Place Details | Get coordinates for selected place |

**Implementation Approach**:
- Use `google_maps_webservice` package OR direct HTTP (evaluate bundle size)
- Debounce autocomplete requests (300ms) to minimize API calls
- Cache recent searches in memory (10 items) to reduce calls

**Alternatives Rejected**:
- **OSM Nominatim**: No autocomplete, limited UK postcode support
- **Mapbox Geocoding**: Requires separate API key and billing

---

## 3. Map Picker UI Pattern

### Decision: Full-screen picker with fixed crosshair + camera movement

**Rationale**:
- More intuitive than draggable marker (tap targets can be small)
- Camera movement provides smooth UX on all platforms
- Matches Google Maps app pattern users are familiar with
- Avoids marker drag gesture conflicts with map pan

**UI Layout**:
```
┌─────────────────────────────────────────┐
│ [←] Select Location              [Done] │ ← AppBar
├─────────────────────────────────────────┤
│ 🔍 Search place or what3words...        │ ← Search bar
├─────────────────────────────────────────┤
│                                         │
│                                         │
│                  ✛                      │ ← Fixed crosshair center
│         [GoogleMap widget]              │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│ 📍 55.9533, -3.1883                     │ ← Info panel
│ ///slurs.this.name         [📋] [📍GPS] │
└─────────────────────────────────────────┘
```

**Alternatives Rejected**:
- **Draggable marker**: Small tap target, conflicts with pan gesture
- **Tap-to-place**: Requires precise tapping, hard on small screens
- **Bottom sheet picker**: Less immersive, harder to see full map

---

## 4. State Management Pattern

### Decision: Dedicated LocationPickerController (ChangeNotifier)

**Rationale**:
- Matches existing pattern (`HomeController`, `MapController`)
- Encapsulates picker-specific state (search, marker position, what3words)
- Clean separation from HomeController (risk location) and ReportFireScreen (fire location)
- Testable with mock services

**State Shape**:
```dart
sealed class LocationPickerState {}
class LocationPickerInitial extends LocationPickerState {}
class LocationPickerReady extends LocationPickerState {
  final LatLng selectedLocation;
  final String? what3words;          // null while loading
  final bool isLoadingWhat3words;
  final String? searchQuery;
  final List<PlaceResult>? suggestions;
  final String? errorMessage;
}
```

**Alternatives Rejected**:
- **Stateless with callbacks**: Too complex for search + w3w + map state
- **BLoC/Riverpod**: Overkill for single-screen picker, adds dependencies
- **Inline StatefulWidget state**: Not testable, violates existing patterns

---

## 5. Navigation & Return Pattern

### Decision: Navigator.pop with typed PickedLocation result

**Rationale**:
- ReportFireScreen is StatelessWidget with no controller (confirmed in codebase)
- Picker is transient (pick → return → done), doesn't need persistent state
- Matches Flutter navigation best practices
- Future-proof: Add ReportFireController only if draft reports added later

**Return Type**:
```dart
class PickedLocation extends Equatable {
  final LatLng coordinates;
  final String? what3words;
  final String? placeName;  // From search or reverse geocode
}
```

**Entry Points**:
1. `HomeScreen._showManualLocationDialog()` → Opens picker, saves via `LocationResolver.saveManual()`
2. `ReportFireScreen` (new button) → Opens picker, returns result for clipboard copy

---

## 6. Privacy Compliance (C2)

### Decision: Use existing LocationUtils.logRedact() pattern

**Rationale**:
- Already implemented in codebase for 2-decimal precision
- Constitutional compliance documented
- what3words addresses NOT logged (can identify precise locations)

**Implementation**:
```dart
// Coordinate logging - ALWAYS use redaction
debugPrint('Selected: ${LocationUtils.logRedact(lat, lon)}');

// what3words - NEVER log (privacy risk)
// ❌ debugPrint('w3w: $what3words'); 
// ✅ debugPrint('w3w loaded successfully');
```

---

## 7. Offline & Error Handling (C5)

### Decision: Graceful degradation with clear user feedback

**Scenarios**:
| Condition | Behavior |
|-----------|----------|
| what3words API unavailable | Show "what3words unavailable", coordinates still work |
| Places API unavailable | Disable search, tap/pan to select still works |
| GPS unavailable | "Use GPS" button hidden/disabled |
| Network timeout | Show error with retry option |

**Rationale**:
- Core functionality (map picker) works offline with cached map tiles
- what3words is enhancement, not requirement
- Search is convenience, not requirement

---

## 8. API Key Configuration

### Decision: Add WHAT3WORDS_API_KEY to env/dev.env.json pattern

**Rationale**:
- Matches existing pattern for GOOGLE_MAPS_API_KEY_*
- Same String.fromEnvironment loading mechanism
- Same .gitignore protection

**Configuration**:
```json
// env/dev.env.json
{
  "WHAT3WORDS_API_KEY": "YOUR_KEY_HERE",
  "GOOGLE_MAPS_API_KEY_ANDROID": "...",
  "GOOGLE_MAPS_API_KEY_IOS": "...",
  "GOOGLE_MAPS_API_KEY_WEB": "..."
}
```

```dart
// lib/config/feature_flags.dart (addition)
static const String what3wordsApiKey = String.fromEnvironment(
  'WHAT3WORDS_API_KEY',
  defaultValue: '',
);
```

---

## 9. File Structure

### New Files (lib/)
```
lib/
├── features/
│   └── location_picker/
│       ├── screens/
│       │   └── location_picker_screen.dart      # Full-screen picker
│       ├── controllers/
│       │   └── location_picker_controller.dart  # ChangeNotifier
│       ├── widgets/
│       │   ├── location_search_bar.dart         # Search + autocomplete
│       │   ├── location_info_panel.dart         # Coords + w3w display
│       │   └── crosshair_overlay.dart           # Fixed center marker
│       └── models/
│           └── picked_location.dart             # Return type
├── services/
│   ├── what3words_service.dart                  # Interface
│   └── what3words_service_impl.dart             # HTTP implementation
└── models/
    └── what3words_models.dart                   # What3wordsAddress, errors
```

### Modified Files
```
lib/
├── app.dart                                     # Add /location-picker route
├── config/feature_flags.dart                    # Add WHAT3WORDS_API_KEY
├── screens/home_screen.dart                     # Navigate to picker (replace dialog)
├── widgets/location_card.dart                   # (Optional) Add mini-map preview
└── features/report/screens/report_fire_screen.dart  # Add "Set Location" button
```

### Test Files
```
test/
├── unit/
│   ├── services/what3words_service_test.dart
│   └── controllers/location_picker_controller_test.dart
├── widget/
│   ├── location_picker_screen_test.dart
│   ├── location_search_bar_test.dart
│   └── location_info_panel_test.dart
└── integration/
    └── location_picker_flow_test.dart
```

---

## Open Questions (Resolved)

| Question | Resolution | Decided By |
|----------|------------|------------|
| ReportFireScreen controller | Navigator.pop pattern | User confirmation |
| what3words SDK vs HTTP | Direct HTTP | User confirmation |
| Places API availability | Confirmed available | User confirmation |
| Map picker vs draggable marker | Fixed crosshair + camera | Research (UX best practice) |
| Mini-map in LocationCard | Deferred (future enhancement) | Complexity vs value |

---

## Dependencies to Add

```yaml
# pubspec.yaml - NO NEW DEPENDENCIES REQUIRED
# Uses existing:
# - http: ^1.1.0 (for what3words API)
# - dartz: ^0.10.1 (for Either pattern)
# - google_maps_flutter: ^2.5.0 (already included)
# - equatable: ^2.0.5 (for models)
```

---

*Research complete. Ready for Phase 1: Design & Contracts.*
