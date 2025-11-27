# Quickstart: 018-A15 Location Picker & what3words Integration

**Branch**: `018-018-a15-location` | **Date**: 2025-11-27

---

## Prerequisites

1. **API Keys configured** in `env/dev.env.json`:
   ```json
   {
     "WHAT3WORDS_API_KEY": "YOUR_W3W_KEY_HERE",
     "GOOGLE_MAPS_API_KEY_ANDROID": "...",
     "GOOGLE_MAPS_API_KEY_IOS": "...",
     "GOOGLE_MAPS_API_KEY_WEB": "..."
   }
   ```

2. **Google Places API enabled** in Google Cloud Console (same project as Maps API)

3. **Dependencies** (already in project - no changes needed):
   - `http: ^1.1.0`
   - `dartz: ^0.10.1`
   - `google_maps_flutter: ^2.5.0`
   - `equatable: ^2.0.5`

---

## Validation Steps

### 1. Feature: Open location picker from HomeScreen

```bash
# Run app
flutter run --dart-define-from-file=env/dev.env.json

# OR use the secure script
./scripts/run_web.sh
```

**Steps**:
1. App opens to Wildfire Risk screen (HomeScreen)
2. Observe LocationCard shows current location
3. Tap "Change" button
4. LocationPickerScreen opens with map centered on current location
5. See fixed crosshair in center of map

**Expected**:
- Map loads within 2 seconds
- Crosshair visible in center
- Location info panel shows coordinates (2dp precision)
- what3words loading then displays (///word.word.word format)

---

### 2. Feature: Pan map to select location

**Steps** (continuing from above):
1. Pan/drag the map to a new area
2. Wait for camera to settle (onCameraIdle)
3. Observe location info panel updates

**Expected**:
- Coordinates update to new position (crosshair center)
- what3words shows loading spinner
- what3words updates to new address
- No UI freezing during pan

---

### 3. Feature: Search for a place

**Steps**:
1. Tap search bar at top
2. Type "Edinburgh Castle"
3. Observe autocomplete suggestions appear
4. Tap a suggestion

**Expected**:
- Suggestions dropdown shows relevant results
- Tapping suggestion pans map to that location
- Crosshair stays centered
- Coordinates and what3words update

---

### 4. Feature: Search with what3words address

**Steps**:
1. Tap search bar
2. Type "///slurs.this.name" (or any valid w3w)
3. Press Enter/Done

**Expected**:
- App recognizes what3words format (starts with ///)
- Map pans to the what3words location
- Coordinates update to match
- what3words panel confirms the address

**Error case**:
1. Type "///invalid.words.here"
2. Press Enter

**Expected**:
- Error message: "Invalid what3words address"
- Map doesn't move
- Previous location preserved

---

### 5. Feature: Copy what3words to clipboard

**Steps**:
1. With a location selected showing what3words
2. Tap the copy button (📋) next to what3words

**Expected**:
- what3words address copied to clipboard
- Snackbar shows "what3words copied to clipboard"
- Can paste the address elsewhere

---

### 6. Feature: Use current GPS location

**Precondition**: GPS permission granted

**Steps**:
1. Pan map away from current location
2. Tap "Use GPS" button

**Expected**:
- Map animates to current GPS location
- Crosshair stays centered
- Coordinates and what3words update
- GPS icon highlighted/active

**GPS unavailable case**:
1. Deny location permission or disable GPS
2. Observe "Use GPS" button

**Expected**:
- Button disabled or hidden
- No crash or error

---

### 7. Feature: Confirm location and return to HomeScreen

**Steps**:
1. Select a location using any method above
2. Tap "Confirm" button in AppBar

**Expected**:
- LocationPickerScreen closes
- HomeScreen shows new location
- LocationCard subtitle: "Your chosen location"
- Fire risk data reloads for new coordinates

---

### 8. Feature: Cancel without saving

**Steps**:
1. Open picker, change location
2. Tap back button (←) or Android back gesture

**Expected**:
- Picker closes
- HomeScreen shows ORIGINAL location (not changed)
- No fire risk reload triggered

---

### 9. Feature: Fire report mode from ReportFireScreen

**Steps**:
1. Navigate to Report Fire tab
2. Tap new "Set Fire Location" button (to be added)
3. LocationPickerScreen opens in fire report mode

**Expected**:
- AppBar title: "Fire Location" (not "Select Location")
- Emergency banner visible at top: "Call 999 first!"
- Copy button more prominent
- Confirm button: "Use this location"

**Steps** (continuing):
4. Select a location
5. Tap "Use this location"

**Expected**:
- what3words automatically copied to clipboard
- Snackbar: "what3words copied - provide to emergency services"
- Picker closes
- Back on ReportFireScreen (no location saved to app)

---

### 10. Feature: Offline/error graceful degradation

**Test A: what3words API unavailable**:
1. Run app without WHAT3WORDS_API_KEY
2. Open location picker

**Expected**:
- Map works normally
- what3words section shows "Unavailable"
- Coordinates still display and copy works
- No crash

**Test B: Places API unavailable**:
1. Run app without Places API enabled
2. Try to search

**Expected**:
- Search bar shows error or is disabled
- Tap-to-place (pan) still works
- what3words still works
- Core functionality preserved

---

## Performance Validation

| Metric | Target | How to Verify |
|--------|--------|---------------|
| Map load time | <2s on 4G | Stopwatch from screen open |
| what3words response | <500ms | Observe loading spinner duration |
| Search suggestions | <300ms | Type and observe dropdown |
| No jank during pan | 60fps | Visual smoothness check |

---

## Test Commands

```bash
# Run all unit tests
flutter test test/unit/services/what3words_service_test.dart
flutter test test/unit/controllers/location_picker_controller_test.dart

# Run widget tests
flutter test test/widget/location_picker_screen_test.dart
flutter test test/widget/location_search_bar_test.dart
flutter test test/widget/location_info_panel_test.dart

# Run integration test
flutter test test/integration/location_picker_flow_test.dart

# Run all tests
flutter test

# Check code quality
flutter analyze
dart format --set-exit-if-changed lib/ test/
```

---

## Constitution Compliance Checklist

| Gate | Requirement | Validation |
|------|-------------|------------|
| C1 | flutter analyze passes | `flutter analyze` shows no issues |
| C2 | No PII in logs | Search logs for full coordinates - none found |
| C2 | what3words not logged | Search logs for w3w addresses - none found |
| C3 | ≥48dp touch targets | Visual inspection of all buttons |
| C3 | Semantic labels | VoiceOver/TalkBack test |
| C4 | Theme colors used | No hardcoded colors in new widgets |
| C5 | Error states visible | Test offline scenarios above |
| C5 | Graceful fallbacks | what3words unavailable doesn't break app |

---

*Quickstart complete. Feature ready for validation.*
