# Web Platform Research & Compatibility (T029)

**Date**: October 20, 2025  
**Status**: ✅ Complete  
**Branch**: `011-a10-google-maps`

## Executive Summary

The WildFire MVP v3 app **has web platform support** through the `google_maps_flutter_web` plugin (v0.5.14+2), which is automatically included as a transitive dependency of `google_maps_flutter ^2.5.0`. However, web deployment requires **additional configuration** for Google Maps API keys, CORS policies, and feature flag handling.

---

## Current Web Support Status

### ✅ Already Supported
- **google_maps_flutter_web**: Automatically included (v0.5.14+2)
- **Flutter web target**: Available (`flutter run -d chrome`)
- **Core services**: All HTTP-based services work (EFFIS, FireRiskService)
- **State management**: ChangeNotifier works across all platforms
- **Routing**: go_router supports web navigation

### ⚠️ Platform Limitations

#### 1. **Location Services (Partial Support)**
- **Web**: Uses browser Geolocation API (requires HTTPS in production)
- **Behavior**: GPS permission dialog is browser-native, not Flutter UI
- **Fallback**: Default Scotland centroid fallback still works
- **Issue**: `geolocator` package may need web-specific permission handling

#### 2. **SharedPreferences (Different Implementation)**
- **Web**: Uses browser `localStorage` instead of native storage
- **Impact**: Cache persistence works, but storage limits differ
- **Limitation**: ~5-10MB localStorage limit vs unlimited mobile storage
- **Risk**: LRU eviction may trigger more frequently on web

#### 3. **Google Maps API Key Configuration**
- **Requirement**: Web requires separate API key configuration in `web/index.html`
- **Security**: API key must be restricted by HTTP referrer (not package name)
- **Current State**: **NOT YET CONFIGURED** - needs web API key setup

---

## Required Web Configuration

### 1. Google Maps JavaScript API Key

**✅ IMPLEMENTED in `web/index.html`**:
```html
<head>
  <!-- ... existing head content ... -->
  
  <!-- Google Maps JavaScript API (required for google_maps_flutter_web) -->
  <!-- For development with MAP_LIVE_DATA=false, map works without API key -->
  <!-- For production with MAP_LIVE_DATA=true, add API key: ?key=YOUR_WEB_API_KEY -->
  <script src="https://maps.googleapis.com/maps/api/js"></script>
</head>
```

**Development Mode** (current setup):
- Works without API key for demo purposes
- Shows "For development purposes only" watermark on map
- All features functional (markers, pan, zoom, info windows)

**Production Mode** (requires configuration):
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY"></script>
```

**API Key Restrictions** (Google Cloud Console):
- **Application restrictions**: HTTP referrers
- **Allowed referrers**:
  - `http://localhost:*` (development)
  - `https://yourdomain.com/*` (production)
- **API restrictions**: Maps JavaScript API

### 2. Environment Variable Injection

**Update `web/index.html` for dart-define support**:
```html
<script>
  // Inject dart-define environment variables
  const flutterConfig = {
    MAP_LIVE_DATA: '{{MAP_LIVE_DATA}}',
  };
</script>
```

### 3. CORS Policy for EFFIS API

**Issue**: EFFIS WMS endpoint may block cross-origin requests from browser

**Workaround Options**:
1. **Proxy Server**: Route EFFIS requests through your backend server
2. **CORS Proxy**: Use a CORS proxy service (development only)
3. **EFFIS CORS Support**: Check if EFFIS enables CORS headers (unlikely)

**Recommended**: Implement backend proxy for production web deployment

---

## Platform-Specific Feature Matrix

| Feature | Android | iOS | macOS | **Web** | Notes |
|---------|---------|-----|-------|---------|-------|
| **GoogleMap Widget** | ✅ | ✅ | ❌ | ✅ | macOS not supported by google_maps_flutter |
| **GPS Location** | ✅ | ✅ | ✅ | ⚠️ | Web requires HTTPS, browser permission UI |
| **SharedPreferences Cache** | ✅ | ✅ | ✅ | ⚠️ | Web uses localStorage (~5-10MB limit) |
| **HTTP API Calls (EFFIS)** | ✅ | ✅ | ✅ | ⚠️ | Web may need CORS proxy for EFFIS |
| **MAP_LIVE_DATA Flag** | ✅ | ✅ | ✅ | ⚠️ | Needs index.html injection setup |
| **Marker Rendering** | ✅ | ✅ | ❌ | ✅ | Performance may differ on web |
| **App Lifecycle (resume)** | ✅ | ✅ | ✅ | ⚠️ | Web uses Page Visibility API |

**Legend**:
- ✅ Fully supported
- ⚠️ Supported with limitations
- ❌ Not supported

---

## Web-Specific Testing Checklist

### Functional Testing
- [ ] Map loads and centers on location
- [ ] Fire markers appear correctly
- [ ] Marker tap shows info window
- [ ] "Check risk here" button works
- [ ] Source chip displays correctly (DEMO DATA/LIVE/CACHED)
- [ ] Location permission prompt (browser native)
- [ ] Cache persistence across page reloads
- [ ] Error handling for network timeouts
- [ ] Responsive layout (different screen sizes)

### Performance Testing
- [ ] Initial map load time ≤3s
- [ ] Marker rendering for 50+ fires (may be slower than mobile)
- [ ] Memory usage (check browser DevTools)
- [ ] No jank during map pan/zoom
- [ ] Cache read/write operations ≤200ms

### Security Testing
- [ ] API key restrictions enforced (HTTP referrer)
- [ ] No sensitive data in browser localStorage
- [ ] CORS policy handled correctly
- [ ] HTTPS required for geolocation in production

### Cross-Browser Testing
- [ ] Chrome (primary target)
- [ ] Firefox
- [ ] Safari
- [ ] Edge
- [ ] Mobile browsers (iOS Safari, Chrome Android)

---

## Running Web Platform

### Development Mode (Mock Data)
```bash
# Run with demo data (no API key needed)
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false

# Build for web deployment
flutter build web --dart-define=MAP_LIVE_DATA=false
```

### Production Mode (Live Data)
```bash
# Requires web API key configured in web/index.html
flutter run -d chrome --dart-define=MAP_LIVE_DATA=true

# Production build with live data
flutter build web --dart-define=MAP_LIVE_DATA=true
```

### Deployment
```bash
# Build output goes to: build/web/
flutter build web --release

# Serve locally for testing
cd build/web && python3 -m http.server 8000
# Open: http://localhost:8000
```

---

## Known Web Limitations

### 1. **EFFIS WFS CORS Blocking**
- **Problem**: Browser blocks cross-origin requests to EFFIS WMS endpoint
- **Impact**: Cannot load live fire data directly from browser
- **Workaround**: Implement backend proxy server
- **Status**: **BLOCKER for web production with MAP_LIVE_DATA=true**

### 2. **localStorage Capacity**
- **Problem**: ~5-10MB limit vs unlimited mobile storage
- **Impact**: Cache may fill faster, LRU eviction more frequent
- **Mitigation**: Reduce cache capacity from 100 to 50 entries on web
- **Status**: Acceptable limitation

### 3. **No Native Permission UI**
- **Problem**: Browser location permission uses native browser UI
- **Impact**: Cannot customize permission dialog appearance
- **Mitigation**: Provide clear instructions before requesting permission
- **Status**: Acceptable limitation

### 4. **Performance Differences**
- **Problem**: JavaScript rendering slower than native mobile
- **Impact**: Marker rendering for 100+ fires may exceed performance targets
- **Mitigation**: Implement lazy loading/clustering earlier on web
- **Status**: Requires T020 (lazy marker rendering) for web optimization

---

## Web Platform Recommendations

### ✅ **Recommended for Development/Testing**
Web platform is **excellent for rapid development** with mock data:
- No need for emulators/simulators
- Fast hot reload
- Easy browser DevTools debugging
- Shareable demo URLs

**Command**: `flutter run -d chrome --dart-define=MAP_LIVE_DATA=false`

### ⚠️ **Conditional Recommendation for Production**
Web platform **requires additional infrastructure** for production:

**Prerequisites**:
1. Backend proxy server for EFFIS API (CORS workaround)
2. Google Maps JavaScript API key with HTTP referrer restrictions
3. HTTPS hosting for geolocation API
4. Responsive layout adjustments for desktop screens
5. Performance optimization (T020 lazy marker rendering)

**If prerequisites met**: ✅ Production-ready  
**If prerequisites NOT met**: ❌ Use mobile platforms only (Android/iOS)

---

## Action Items for Web Deployment

### Phase 1: Development/Demo (No Blockers)
- [x] Verify google_maps_flutter_web dependency
- [x] Document web platform limitations
- [ ] Test with `flutter run -d chrome` (MAP_LIVE_DATA=false)
- [ ] Create web platform test checklist

### Phase 2: Production (Requires Infrastructure)
- [ ] Obtain Google Maps JavaScript API key for web
- [ ] Configure API key in `web/index.html` with referrer restrictions
- [ ] Implement backend CORS proxy for EFFIS API
- [ ] Deploy to HTTPS hosting (for geolocation)
- [ ] Optimize for desktop screen sizes (responsive layout)
- [ ] Implement T020 lazy marker rendering (performance)

### Phase 3: Cross-Browser Testing
- [ ] Test Chrome (primary)
- [ ] Test Firefox
- [ ] Test Safari (macOS/iOS)
- [ ] Test Edge
- [ ] Test mobile browsers (iOS Safari, Chrome Android)

---

## Conclusion

**Web platform is VIABLE** for WildFire MVP v3 with these caveats:

1. **Development/Demo**: ✅ Ready now (mock data, no API key needed)
2. **Production Deployment**: ⚠️ Requires backend proxy + API key setup
3. **Performance**: ⚠️ May need T020 optimization for 100+ markers
4. **User Experience**: ⚠️ Browser-native location permissions (acceptable)

**Recommendation**: 
- Use web platform for **development and demos** immediately
- Plan **production web deployment** as Phase 2 (after mobile launch)
- Prioritize **mobile platforms** (Android/iOS) for initial production release

---

## References

- **google_maps_flutter_web**: https://pub.dev/packages/google_maps_flutter_web
- **Flutter Web**: https://docs.flutter.dev/get-started/web
- **Google Maps JavaScript API**: https://developers.google.com/maps/documentation/javascript
- **Browser Geolocation API**: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API
- **Web localStorage**: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage

---

**Next Steps**: Proceed to T030 (Cross-Platform Testing Matrix)
