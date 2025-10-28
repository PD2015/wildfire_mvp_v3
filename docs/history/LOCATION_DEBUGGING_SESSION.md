# Location Services Debugging Session - October 5, 2025

## Overview
This document records a comprehensive debugging session to resolve location services issues in the WildFire MVP app, specifically focusing on GPS coordinate acquisition and UK fire risk data integration.

## Initial Problem Statement
The app was using default coordinates instead of the user's actual location, preventing proper testing of UK fire risk services with realistic Scottish coordinates.

## Architecture Context
The app uses a 5-tier LocationResolver fallback system:
1. **GPS (Tier 1)**: Real device GPS with 2-second timeout
2. **Cache (Tier 2)**: SharedPreferences stored coordinates  
3. **Manual (Tier 3)**: User-entered coordinates via dialog
4. **Default (Tier 4)**: Scotland centroid (55.8642, -4.2518)
5. **Mock (Tier 5)**: Never-fail fallback

Fire risk data flows through FireRiskService orchestration:
1. **EFFIS**: European Fire Weather API (3s timeout)
2. **SEPA**: Scotland-specific service (2s timeout, Scotland only)
3. **Cache**: 6-hour TTL cache (200ms timeout)
4. **Mock**: Never-fail synthetic data

---

## Issues Discovered

### 1. Test Mode Interference
**Problem**: Portugal test coordinates (39.6, -9.2) were hardcoded in main.dart
**Impact**: App always returned test data instead of real location services
**Evidence**: Console showed "🧪 TEST MODE: Using Portugal coordinates"

### 2. Incomplete Cache Clearing
**Problem**: _clearCachedLocation() only removed lat/lon keys, missing version/timestamp
**Impact**: Stale cache entries persisted across app restarts
**Evidence**: Cache hits for expired data, inconsistent location resolution

### 3. Android Emulator GPS Persistence
**Problem**: Emulator GPS providers cache default coordinates (37.42, -122.08)
**Impact**: Fresh GPS calls returned stale California coordinates despite console updates
**Evidence**: Multiple telnet geo fix commands ignored by GPS provider

### 4. iOS Simulator GPS Consistency
**Problem**: iOS simulator also returned default coordinates, not set coordinates
**Impact**: Cross-platform GPS unreliability in simulator environments
**Evidence**: Same California coordinates on both iOS and Android simulators

---

## Solutions Implemented

### 1. Test Mode Preservation (COMPLETED)
**File**: `lib/main.dart`
**Action**: Commented out Portugal test logic while preserving code
```dart
// 🧪 TEST MODE - Comment out for production
// _logger.info('🧪 TEST MODE: Using Portugal coordinates (39.6, -9.2)');
// final testResult = await fireRiskService.getCurrent(lat: 39.6, lon: -9.2);
```
**Restoration**: Uncomment block and ensure proper test flag management

### 2. Enhanced Cache Clearing (COMPLETED)
**File**: `lib/main.dart`
**Action**: Added all SharedPreferences keys to clearing function
```dart
Future<void> _clearCachedLocation() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('manual_location_version');    // Added: Version tracking
  await prefs.remove('manual_location_lat');        // Existing
  await prefs.remove('manual_location_lon');        // Existing  
  await prefs.remove('manual_location_place');      // Added: Place name
  await prefs.remove('manual_location_timestamp');  // Added: Cache timestamp
  _logger.info('🧹 All cached location data cleared');
}
```
**Restoration**: No changes needed - this is a permanent improvement

### 3. GPS Tier Bypass (TEMPORARY - REQUIRES RESTORATION)
**File**: `lib/services/location_resolver_impl.dart`
**Action**: Hardcoded Aviemore coordinates and disabled GPS calls
```dart
@override
Future<Either<LocationError, LatLng>> getLatLon() async {
  // 🔧 GPS TEMPORARILY BYPASSED FOR UK TESTING
  _logger.info('GPS temporarily bypassed - using Aviemore coordinates for UK testing');
  return Right(LatLng(57.2, -3.8)); // Aviemore, Scotland
  
  // ORIGINAL GPS CODE (commented out):
  // try {
  //   if (!await Geolocator.isLocationServiceEnabled()) {
  //     _logger.warning('Location services disabled, falling back to cache');
  //     return await _getCachedLocation();
  //   }
  //   // ... rest of GPS implementation
}
```

### 4. Default Coordinate Update (TEMPORARY - REQUIRES RESTORATION)
**File**: `lib/services/location_resolver_impl.dart`  
**Action**: Changed Scotland centroid to Aviemore for consistent UK testing
```dart
// Original Scotland centroid
// static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);

// 🔧 TEMPORARILY CHANGED FOR UK TESTING
static const LatLng _scotlandCentroid = LatLng(57.2, -3.8); // Aviemore
```

---

## Current State Summary

### ✅ Permanently Fixed
- **Test mode management**: Preserved with clear commenting
- **Cache clearing**: Enhanced to remove all related keys
- **EFFIS integration**: Proven working for global coordinates
- **UK fire risk data**: Successfully retrieving realistic Scottish data

### ⚠️ Temporarily Modified (REQUIRES RESTORATION)
- **GPS tier bypass**: Hardcoded Aviemore coordinates (57.2, -3.8)
- **Default coordinates**: Changed from Scotland centroid to Aviemore
- **Location logging**: Shows "GPS temporarily bypassed" messages

### 🧪 Test Results Achieved
- **California coordinates**: FWI = 26.00584 (High Risk) - baseline confirmed
- **UK coordinates**: FWI = 0.3914763 (Very Low Risk) - realistic data
- **EFFIS coverage**: Global API working for both test regions
- **Service orchestration**: Proper fallback chain through EFFIS → Mock

---

## Restoration Plan for Production Devices

### Step 1: Restore GPS Implementation
**File**: `lib/services/location_resolver_impl.dart`
**Action**: Remove hardcoded bypass and restore full GPS logic

```dart
@override
Future<Either<LocationError, LatLng>> getLatLon() async {
  // RESTORE: Remove this bypass block entirely
  // _logger.info('GPS temporarily bypassed - using Aviemore coordinates for UK testing');
  // return Right(LatLng(57.2, -3.8));
  
  // RESTORE: Uncomment full GPS implementation
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _logger.warning('Location services disabled, falling back to cache');
      return await _getCachedLocation();
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _logger.warning('Location permission denied, falling back to cache');
        return await _getCachedLocation();
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _logger.warning('Location permission permanently denied, falling back to cache');
      return await _getCachedLocation();
    }
    
    _logger.info('Attempting GPS location acquisition...');
    final position = await Geolocator.getCurrentPosition(
      timeLimit: Duration(seconds: 2),
      desiredAccuracy: LocationAccuracy.medium,
    );
    
    final coords = LatLng(position.latitude, position.longitude);
    _logger.info('GPS location acquired: ${LocationUtils.logRedact(coords.latitude, coords.longitude)}');
    return Right(coords);
    
  } catch (e) {
    _logger.warning('GPS failed: $e, falling back to cache');
    return await _getCachedLocation();
  }
}
```

### Step 2: Restore Default Coordinates
**File**: `lib/services/location_resolver_impl.dart`
**Action**: Reset Scotland centroid to original coordinates

```dart
// RESTORE: Change back to original Scotland centroid
static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);
```

### Step 3: Verify Fallback Chain
**Expected behavior on real devices**:
1. **GPS Success**: User's actual coordinates used for local fire risk
2. **GPS Denied**: Falls back to cached manual coordinates (if any)
3. **No Cache**: Falls back to manual entry dialog
4. **No Manual**: Falls back to Scotland centroid (55.8642, -4.2518)

### Step 4: Remove Debug Logging
**File**: `lib/services/location_resolver_impl.dart`
**Action**: Remove temporary logging messages
- Remove "GPS temporarily bypassed" messages
- Keep standard location acquisition logging
- Maintain privacy-compliant coordinate redaction

---

## Testing Validation

### Emulator Testing (Current State)
```
✅ Hardcoded Aviemore coordinates (57.2, -3.8)
✅ UK fire risk data: FWI = 0.3914763 (Very Low Risk)
✅ EFFIS integration working
✅ Service orchestration: EFFIS → Mock fallback
```

### Expected Real Device Behavior (After Restoration)
```
✅ GPS permission request on first launch  
✅ User's actual coordinates for local fire risk assessment
✅ Fallback to cached coordinates if GPS fails
✅ Manual entry dialog for coordinate override
✅ Scotland centroid as final fallback
```

---

## Key Technical Insights

### 1. Emulator GPS Limitations
- Android/iOS simulators cache default coordinates
- Console `geo fix` commands often ignored by GPS providers
- Real devices have reliable GPS acquisition
- Testing location services requires real device validation

### 2. EFFIS API Global Coverage
- European Fire Weather API works worldwide
- Coordinates outside Europe return valid data
- California: High fire risk (FWI ~26)
- Scotland: Very low fire risk (FWI ~0.4)
- API responses consistent and reliable

### 3. SharedPreferences Cache Complexity
- Multiple keys required: version, lat, lon, place, timestamp
- Incomplete clearing causes cache persistence issues
- Version tracking prevents data format conflicts
- LRU eviction requires access timestamp management

### 4. Privacy-Compliant Logging
- Coordinate redaction required for PII compliance
- Log format: "55.95,-3.19" (2 decimal places)
- Never log full precision coordinates
- Geohash keys provide spatial privacy (4.9km resolution)

---

## File Change Summary

### Modified Files
1. **lib/main.dart**
   - Test mode logic commented out (preserved)
   - Enhanced cache clearing function (permanent)

2. **lib/services/location_resolver_impl.dart**
   - GPS tier bypassed (temporary)
   - Hardcoded Aviemore coordinates (temporary)
   - Default Scotland centroid changed (temporary)

### Unchanged Files
- **lib/services/fire_risk_service_impl.dart**: EFFIS orchestration working
- **lib/services/effis_service_impl.dart**: API integration stable
- **lib/models/**: Data models unchanged
- **lib/widgets/**: UI components unaffected

---

## Future Considerations

### Production Deployment Checklist
- [ ] Restore full GPS implementation
- [ ] Reset Scotland centroid coordinates  
- [ ] Remove debug logging messages
- [ ] Test on real devices across UK regions
- [ ] Validate manual coordinate entry dialog
- [ ] Verify cache clearing on app updates

### Enhanced Location Services
- Consider implementing more granular location accuracy settings
- Add user preference for coordinate override persistence
- Implement location history for frequently visited areas
- Add offline coordinate validation for remote areas

### Testing Infrastructure
- Establish real device testing protocol
- Create location services integration test suite
- Document regional fire risk data validation
- Set up automated testing for GPS permission flows

---

## Conclusion

This debugging session successfully:
1. **Identified and resolved** test mode interference
2. **Enhanced cache management** with complete key clearing
3. **Validated EFFIS integration** for global fire risk data
4. **Established UK testing capability** with realistic Scottish fire risk data
5. **Documented clear restoration path** for production deployment

The temporary hardcoded Aviemore coordinates provide a stable testing environment for UK fire risk services while maintaining a clear path back to full GPS functionality for real device deployment.