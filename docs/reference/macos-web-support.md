# macOS Web Support for Google Maps

**Date**: 2025-10-20  
**Status**: ✅ **WORKING**  
**Branch**: `011-a10-google-maps`

## Executive Summary

Google Maps **DOES work** on macOS when deployed as a **web application** (Flutter Web in Chrome/Safari). The confusion arose from two different "macOS" deployment targets:

1. **macOS Desktop (native Flutter app)** → ❌ NOT supported by `google_maps_flutter`
2. **macOS Web (Flutter web in browser)** → ✅ FULLY supported via `google_maps_flutter_web`

## Platform Support Matrix

| Platform | Deployment Type | Google Maps Support | Implementation |
|----------|----------------|---------------------|----------------|
| **Android** | Native mobile app | ✅ Full support | `google_maps_flutter_android` |
| **iOS** | Native mobile app | ✅ Full support | `google_maps_flutter_ios` |
| **macOS Desktop** | Native desktop app | ❌ Not supported | N/A - shows fallback UI |
| **macOS Web (Chrome)** | Flutter Web | ✅ Full support | `google_maps_flutter_web` ✨ |
| **macOS Web (Safari)** | Flutter Web | ✅ Full support | `google_maps_flutter_web` ✨ |
| **Windows/Linux Web** | Flutter Web | ✅ Full support | `google_maps_flutter_web` |

## How to Run on macOS Web

### 🔐 Recommended: Use Secure Build Scripts

The project includes secure scripts that automatically inject your API key without exposing it in git:

```bash
# Development with API key (recommended) ✅
./scripts/run_web.sh

# Production build with API key
./scripts/build_web.sh
```

📖 **Why use scripts?** See the Web Configuration section in `GOOGLE_MAPS_API_SETUP.md` for details on Flutter web's architectural limitations with environment variables.

**What the scripts do:**
1. ✅ Read `GOOGLE_MAPS_API_KEY_WEB` from `env/dev.env.json`
2. ✅ Temporarily inject API key into `web/index.html`
3. ✅ Run/build Flutter web
4. ✅ **Auto-restore** clean `web/index.html` (no secrets in git)

**Alternative for quick testing:**
```bash
# Works without API key (shows watermark)
flutter run -d chrome
```

**Expected behavior with API key:**
- ✅ Map loads successfully
- ✅ Fire markers appear (3 mock incidents)
- ✅ **No watermark** (API key is used)
- ✅ Clean console output

### 📝 API Key Configuration

Your API key is already configured in `env/dev.env.json`:

```json
{
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_ACTUAL_API_KEY_HERE"
}
```

**Note:** The project uses a shared unrestricted key for development (also used for Android/iOS). Check `env/dev.env.json` for the actual configured key.

**For production deployment:**
- Create a separate restricted API key (see [WEB_API_KEY_SECURITY.md](WEB_API_KEY_SECURITY.md))
- Configure HTTP referrer restrictions in Google Cloud Console
- Update `env/prod.env.json` with the restricted key

### Alternative: Manual Method (Without API Key)

If you want to test without the API key (shows watermark):

```bash
# Run in Chrome (manual method)
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false

# Build for web deployment
flutter build web --dart-define=MAP_LIVE_DATA=false

# Serve locally for testing
cd build/web && python3 -m http.server 8000
# Then open: http://localhost:8000
```

**Expected behavior (no API key):**
- ✅ Map loads successfully
- ✅ Fire markers appear (3 mock incidents)
- ⚠️ "For development purposes only" watermark
- ⚠️ Console warnings about `NoApiKeys` and `ApiProjectMapError` (expected, non-blocking)

## Technical Implementation

### Dependencies (Already Installed)

```yaml
dependencies:
  google_maps_flutter: ^2.5.0  # Platform interface
  # Transitive dependencies (auto-included):
  # - google_maps_flutter_web: 0.5.14+2 ✅
  # - google_maps_flutter_android: 2.18.4
  # - google_maps_flutter_ios: 2.15.5
```

### Web Configuration (`web/index.html`)

The `web/index.html` file is kept **clean** (no hardcoded API key) for security:

```html
<head>
  <!-- Google Maps JavaScript API (required for google_maps_flutter_web) -->
  <!-- API key injected by build scripts at runtime -->
  <!-- DO NOT hardcode API key here - use ./scripts/run_web.sh instead -->
  <script src="https://maps.googleapis.com/maps/api/js"></script>
</head>
```

**Security Note:** The build scripts (`./scripts/run_web.sh` and `./scripts/build_web.sh`) automatically inject the API key at runtime and restore the clean version afterward. This prevents accidentally committing secrets to git.

For more details on the secure API key workflow, see:
- [WEB_API_KEY_SECURITY.md](WEB_API_KEY_SECURITY.md) - Complete security guide
- [API_KEY_SETUP.md](API_KEY_SETUP.md) - API key setup instructions

### Platform Detection Logic (`lib/features/map/screens/map_screen.dart`)

```dart
// Platform detection: google_maps_flutter supports:
// - Web (kIsWeb=true): Uses google_maps_flutter_web with Maps JavaScript API
// - Mobile (Android/iOS): Uses native Google Maps SDKs
// - macOS desktop (kIsWeb=false && Platform.isMacOS): NOT SUPPORTED
final bool isMapSupported =
    kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS));
```

**Key insight:** Use `kIsWeb` to detect web deployment, NOT `Platform.isMacOS`. When running Flutter Web on macOS, `kIsWeb=true` and the web implementation is used.

## Verified Functionality (2025-10-20)

Tested with both `./scripts/run_web.sh` (with API key) and `flutter run -d chrome` (without API key):

✅ **Working Features:**
- Map renders successfully in Chrome
- 3 mock fire incidents loaded
- Markers created with correct color coding:
  - 🔴 High intensity (red marker)
  - 🟠 Moderate intensity (orange marker)
  - 🔵 Low intensity (cyan marker)
- Map controls (zoom, pan) functional
- Info windows work on marker tap
- Source chip displays "DEMO DATA" correctly
- Risk check button renders properly

✅ **With Secure Script (`./scripts/run_web.sh`):**
- API key automatically injected from `env/dev.env.json`
- No watermark on map
- Clean console output
- `web/index.html` auto-restored on exit

⚠️ **Without API Key (manual `flutter run`):**
- `NoApiKeys` warning - Normal without API key
- `ApiProjectMapError` - Expected in development mode
- "For development purposes only" watermark
- Marker deprecation notice - FYI from Google (markers still work)

❌ **Known Limitations (Web Platform):**
- No "My Location" button (web platform limitation)
- No native GPS button (uses browser geolocation API)
- Marker color customization limited (uses default pin hues)

## Browser Compatibility

### Supported Browsers (Official)

According to Google Maps JavaScript API documentation:

- ✅ **Safari 15.6+** (macOS) - Latest 2 versions supported
- ✅ **Chrome** (all platforms) - Latest version
- ✅ **Firefox** (all platforms) - Latest version
- ✅ **Edge** (Windows/macOS) - Latest version

### Flutter Web Renderer

Flutter 3.35.5 uses **CanvasKit** renderer by default for web, which provides:
- ✅ Full Safari compatibility (15.6+)
- ✅ Consistent rendering across browsers
- ✅ Better performance than HTML renderer

No special renderer flags needed - Flutter auto-selects the best renderer.

## Testing Checklist

### Manual Testing (Chrome)
- [x] Map loads and centers on Scotland (with `./scripts/run_web.sh`)
- [x] 3 mock fire markers appear
- [x] Marker colors match intensity (red/orange/cyan)
- [x] Marker tap shows info window
- [x] Source chip shows "DEMO DATA"
- [x] Risk check button renders
- [x] No blocking errors in console
- [x] API key injection works (no watermark when using script)
- [x] Clean `web/index.html` after script exits

### Manual Testing (Safari) - TODO
- [ ] Map loads successfully
- [ ] Markers render correctly
- [ ] Touch/click interactions work
- [ ] Performance acceptable

### Integration Tests - TODO
- [ ] Add web-specific platform tests
- [ ] Verify Maps JS SDK loading
- [ ] Test fallback UI for macOS desktop
- [ ] Validate web-specific permissions flow

## Comparison: macOS Desktop vs macOS Web

| Feature | macOS Desktop | macOS Web (Chrome/Safari) |
|---------|--------------|---------------------------|
| **Deployment** | `flutter run -d macos` | `./scripts/run_web.sh` |
| **Google Maps** | ❌ Shows fallback UI | ✅ Full map functionality (with API key) |
| **Fire Markers** | ❌ Listed in text | ✅ Interactive markers |
| **GPS Location** | ✅ Native geolocator | ⚠️ Browser geolocation API |
| **Cache** | ✅ Native file system | ⚠️ localStorage (~5-10MB limit) |
| **Performance** | ⚡ Native performance | 🐢 Slower (JavaScript) |
| **Use Case** | Development only | Production-ready (with API key) |

## Recommendations

### For Development/Testing on macOS
**Use the secure web script (recommended):**
```bash
./scripts/run_web.sh
```
**Advantages:**
- ✅ Full Google Maps support with API key (no watermark)
- ✅ Fast hot reload
- ✅ Secure API key injection (no secrets in git)
- ✅ Easy browser DevTools debugging
- ✅ Auto-cleanup on exit (Ctrl+C)

**Alternative (without API key):**
```bash
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false
```
- Shows "for development purposes only" watermark but still functional

### For Production Deployment

**Priority order:**
1. **Mobile (Android/iOS)** - Best user experience, full feature support
2. **Web (all platforms)** - Requires API key setup, acceptable for desktop users
3. **macOS Desktop** - Not recommended (no map support)

### API Key Security

If deploying web to production:
- ✅ Create separate API key for web (different from mobile keys)
- ✅ Restrict by HTTP referrer (not IP or package name)
- ✅ Enable only "Maps JavaScript API" (not all APIs)
- ✅ Set up billing alerts at 50% and 80% of free tier quotas
- ✅ Monitor usage regularly

## Troubleshooting

### "Google Maps is not supported on macOS Desktop" Message

**Problem:** Seeing fallback UI when running on macOS  
**Cause:** Running native macOS desktop app (`flutter run -d macos`)  
**Solution:** Switch to web platform: `flutter run -d chrome`

### Map Shows "For development purposes only" Watermark

**Problem:** Watermark appears on map  
**Cause:** No API key configured (expected in development)  
**Solution:**
- Development: Ignore (map still works)
- Production: Add API key to `web/index.html`

### Console Error: "ApiProjectMapError"

**Problem:** Error in browser console about API project  
**Cause:** Running without API key or invalid key restrictions  
**Solution:**
- Development: Safe to ignore
- Production: Configure API key with correct referrer restrictions

## Next Steps

### Immediate (Completed)
- [x] Verify web deployment works on Chrome
- [x] Update documentation (this file)
- [x] Update copilot-instructions.md
- [x] Clarify platform detection comments

### Short Term
- [ ] Test on Safari (macOS) using `./scripts/run_web.sh`
- [ ] Create web-specific integration tests
- [x] Document API key setup workflow (see WEB_API_KEY_SECURITY.md)

### Long Term (Production)
- [x] Obtain production Google Maps JavaScript API key (shared dev key exists)
- [ ] Create separate restricted API key for production deployment
- [ ] Configure HTTP referrer restrictions (production key)
- [ ] Update `env/prod.env.json` with restricted key
- [ ] Implement backend CORS proxy for EFFIS API (if needed)
- [ ] Performance optimization for web (lazy marker loading)
- [ ] Cross-browser testing (Firefox, Edge, Safari)

## References

- **google_maps_flutter_web**: https://pub.dev/packages/google_maps_flutter_web
- **Google Maps JavaScript API**: https://developers.google.com/maps/documentation/javascript
- **Browser Support**: https://developers.google.com/maps/documentation/javascript/browsersupport
- **API Key Setup**: https://developers.google.com/maps/documentation/javascript/get-api-key
- **Flutter Web**: https://docs.flutter.dev/get-started/web

---

**Conclusion:** macOS web support for Google Maps is **fully functional** and ready for development/testing. Production deployment requires API key setup but is otherwise production-ready.
