# Google Maps Setup Guide

## Overview
This guide covers setting up Google Maps API keys for iOS, Android, and Web platforms in the WildFire MVP v3 application.

## Prerequisites
- Google Cloud Platform account
- Project with billing enabled
- Maps SDK for Android enabled
- Maps SDK for iOS enabled
- Maps JavaScript API enabled (for web platform)

## API Key Creation

### 1. Create API Keys
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services > Credentials**
4. Click **Create Credentials > API Key**
5. Create separate keys for Android and iOS

### 2. Android Key Restrictions
1. Click on the Android API key
2. Under **Application restrictions**, select **Android apps**
3. Click **Add an item**
4. Add your app's package name: `com.example.wildfire_mvp_v3`
5. Get SHA-1 fingerprint:
   ```bash
   # Debug certificate
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release certificate (use your keystore path)
   keytool -list -v -keystore /path/to/your/keystore.jks -alias your_alias
   ```
6. Add SHA-1 fingerprint to the key restrictions
7. Save changes

### 3. iOS Key Restrictions
1. Click on the iOS API key
2. Under **Application restrictions**, select **iOS apps**
3. Click **Add an item**
4. Add your app's bundle ID (found in `ios/Runner.xcodeproj`)
5. Save changes

### 4. Web Key Restrictions (Optional - for web platform)
1. Create a new API key for web usage
2. Under **Application restrictions**, select **HTTP referrers (web sites)**
3. Add authorized domains:
   - Development: `http://localhost:*` (for local testing)
   - Production: `https://yourdomain.com/*`
4. Under **API restrictions**, select **Restrict key** and enable:
   - Maps JavaScript API
5. Save changes

**Security Note**: Web keys are visible in browser source code. Use HTTP referrer restrictions and consider implementing a backend proxy for production deployments (see `docs/WEB_API_KEY_SECURITY.md`).

## Configuration

### 5. Set Environment Variables
1. Copy the template:
   ```bash
   cp env/dev.env.json.template env/dev.env.json
   ```

2. Edit `env/dev.env.json` and add your API keys:
   ```json
   {
     "MAP_LIVE_DATA": "false",
     "GOOGLE_MAPS_API_KEY_ANDROID": "your_android_key_here",
     "GOOGLE_MAPS_API_KEY_IOS": "your_ios_key_here",
     "GOOGLE_MAPS_API_KEY_WEB": "your_web_key_here",
     "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.eu/"
   }
   ```

3. **NEVER commit `env/dev.env.json`** - it's in `.gitignore`

### 6. Run with Environment File

**Mobile Platforms (Android/iOS):**
```bash
# Development with mock data (default, safest for testing)
flutter run -d <device> --dart-define-from-file=env/dev.env.json

# With live EFFIS data (requires EFFIS_BASE_URL configured)
flutter run -d <device> --dart-define-from-file=env/dev.env.json --dart-define=MAP_LIVE_DATA=true

# CI/CD (uses placeholder keys, mock data only)
flutter run --dart-define-from-file=env/ci.env.json
```

**Web Platform:**
```bash
# Development with secure API key injection (uses scripts/run_web.sh)
./scripts/run_web.sh

# OR manually without secure injection (not recommended)
flutter run -d chrome --dart-define-from-file=env/dev.env.json

# Production build with secure API key injection
./scripts/build_web.sh
```

See `docs/WEB_API_KEY_SECURITY.md` for web-specific security considerations.

## EFFIS WFS Integration

### 7. EFFIS WFS Endpoint Configuration

The application integrates with EFFIS (European Forest Fire Information System) for live fire data:

**Base URL**: `https://ies-ows.jrc.ec.europa.eu/`

**WFS Layer**: `effis:burntareas.latest` (current year burnt areas)

**Example Query**:
```
GET /wfs?service=WFS&version=2.0.0&request=GetFeature&typeName=effis:burntareas.latest&outputFormat=application/json&bbox={minLon},{minLat},{maxLon},{maxLat}
```

**Configuration**:
- Set `EFFIS_BASE_URL` in `env/dev.env.json`
- Enable with `MAP_LIVE_DATA=true` flag
- Default timeout: 8 seconds per service tier
- Fallback chain: EFFIS → Cache → Mock

**Data Freshness**:
- EFFIS updates: Daily during fire season
- Cache TTL: 6 hours
- Mock data: Always available (offline resilience)

See `docs/runbooks/effis-monitoring.md` for operational procedures.

## Cost Monitoring

### 8. Set Up Billing Alerts
Google Maps offers $200/month free tier. Set up alerts to avoid unexpected charges:

1. Go to **Billing > Budgets & alerts**
2. Create budget for your project
3. Set alerts at:
   - **50% threshold** ($100/month) - Warning email to team
   - **80% threshold** ($160/month) - Critical alert, review usage
   - **95% threshold** ($190/month) - Emergency alert, consider service limits

4. **Recommended Actions by Threshold**:
   - 50%: Review usage patterns, verify no unusual spikes
   - 80%: Audit API calls, optimize caching strategy
   - 95%: Consider quota caps or temporary service pause

### 9. API Usage Quotas
- **Maps SDK for Android**: 28,000 loads/month free (~$200 included)
- **Maps SDK for iOS**: 28,000 loads/month free (~$200 included)
- **Maps JavaScript API (Web)**: 28,000 loads/month free (~$200 included)
- **Static Maps**: 100,000 loads/month free

**Cost Per 1,000 Loads After Free Tier**:
- Dynamic maps: $7/1,000 loads
- Static maps: $2/1,000 loads

**Monitor Usage**:
- Dashboard: **APIs & Services > Dashboard**
- Set custom quotas: **APIs & Services > Quotas**
- Consider implementing: Request throttling, user-based rate limits

**Cost Optimization Strategies**:
- ✅ 6-hour cache (already implemented - reduces API calls by ~75%)
- ✅ Lazy marker rendering (only visible markers loaded)
- ✅ Mock-first development (MAP_LIVE_DATA=false by default)
- Consider: Map style caching, viewport-based data fetching

## MAP_LIVE_DATA Feature Flag

### 10. Controlling Data Source

The `MAP_LIVE_DATA` flag controls whether the app uses live EFFIS data or mock data:

**Default (Development)**:
```bash
# MAP_LIVE_DATA=false (default) - uses mock data
flutter run --dart-define-from-file=env/dev.env.json
```

**Live Data (Testing/Production)**:
```bash
# MAP_LIVE_DATA=true - attempts EFFIS WFS, falls back to cache/mock
flutter run --dart-define=MAP_LIVE_DATA=true --dart-define-from-file=env/dev.env.json
```

**Behavior**:
- `false`: Skips EFFIS entirely, goes directly to mock data (fast, offline-capable)
- `true`: Attempts EFFIS WFS (8s timeout) → Cache (6h TTL) → Mock (never fails)

**Visual Indicators (C4 Trust & Transparency)**:
- Demo mode (`false`): Shows prominent "DEMO DATA" chip in amber
- Live mode (`true`): Shows source chip: "LIVE" (EFFIS), "CACHED", or "MOCK"
- Timestamp always visible: "Last updated: [ISO-8601 UTC]"

## Troubleshooting

### API Key Not Working

**Symptoms**: Map displays "For development purposes only" watermark, tiles don't load

**Solutions**:
1. Verify key restrictions match your app:
   - Android: Package name `com.example.wildfire_mvp_v3` + SHA-1 fingerprint
   - iOS: Bundle ID matches `ios/Runner/Info.plist`
   - Web: HTTP referrer matches your domain
2. Check SHA-1 fingerprint:
   ```bash
   # Debug certificate
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```
3. Ensure correct Maps SDK is enabled in GCP console:
   - Android: Maps SDK for Android
   - iOS: Maps SDK for iOS
   - Web: Maps JavaScript API
4. Wait 5-10 minutes after key creation for propagation
5. Verify API key is in correct environment file and not a placeholder

### Quota Exceeded

**Symptoms**: Map fails to load with 403 or quota error, billing alerts triggered

**Solutions**:
1. Check current usage: **GCP Console > APIs & Services > Dashboard**
2. Verify caching is working:
   ```dart
   // Check logs for cache hits
   grep "Cache hit" logs/app.log
   ```
3. Review cost optimization:
   - ✅ 6-hour cache reduces calls by ~75%
   - ✅ Lazy rendering loads only visible markers
   - Consider: Increase cache TTL to 12h, implement request throttling
4. Temporary fix: Set quota cap in GCP (prevents overspend)
5. Long-term: Upgrade billing plan or optimize data fetching patterns

### Map Not Displaying

**Android**:
1. Check `android/app/src/main/AndroidManifest.xml` has:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${GOOGLE_MAPS_API_KEY}" />
   ```
2. Verify `android/app/build.gradle.kts` has manifestPlaceholders
3. Check Logcat for API key errors: `adb logcat | grep -i "maps"`

**iOS**:
1. Check `ios/Runner/AppDelegate.swift` has:
   ```swift
   GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
   ```
2. Or `ios/Runner/Info.plist` has `GMSApiKey` entry
3. Check console for authorization errors in Xcode

**Web**:
1. Check `web/index.html` has Google Maps JavaScript API script:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY"></script>
   ```
2. Use secure injection scripts: `./scripts/run_web.sh`
3. Check browser console for CORS or API key errors
4. Verify HTTP referrer restrictions allow your domain

**All Platforms**:
- Verify device/emulator has internet connection
- Check firewall/proxy settings
- Run `flutter clean && flutter pub get` to refresh dependencies
- Ensure Flutter SDK is up to date: `flutter --version`

### EFFIS WFS Timeouts

**Symptoms**: Fire markers not loading, falls back to cached/mock data, logs show "EFFIS timeout"

**Solutions**:
1. Check EFFIS endpoint health:
   ```bash
   curl -I https://ies-ows.jrc.ec.europa.eu/wfs
   ```
2. Verify `EFFIS_BASE_URL` in `env/dev.env.json` is correct
3. Check network connectivity: `ping ies-ows.jrc.ec.europa.eu`
4. Review timeout setting (default 8s): Consider increasing for slow networks
5. Verify MAP_LIVE_DATA=true: `grep "Attempting EFFIS" logs/app.log`
6. Fallback chain working: Cache → Mock (check source chip shows "CACHED" or "MOCK")

**Expected Behavior**:
- EFFIS timeout is **normal** and **expected** in production
- Fallback chain ensures service never fails completely
- Cache provides 6-hour resilience window
- Mock data guarantees offline functionality

See `docs/runbooks/effis-monitoring.md` for operational procedures.

### Environment File Issues

**Symptoms**: Keys not loading, app crashes on startup, "dart-define not found" errors

**Solutions**:
1. Verify file exists: `test -f env/dev.env.json && echo "✅ Found" || echo "❌ Missing"`
2. Check file is valid JSON:
   ```bash
   cat env/dev.env.json | python -m json.tool
   ```
3. Ensure all required fields present:
   - `MAP_LIVE_DATA`
   - `GOOGLE_MAPS_API_KEY_ANDROID`
   - `GOOGLE_MAPS_API_KEY_IOS`
   - `GOOGLE_MAPS_API_KEY_WEB` (for web platform)
   - `EFFIS_BASE_URL`
4. Copy from template if corrupted:
   ```bash
   cp env/dev.env.json.template env/dev.env.json
   # Then add your actual keys
   ```
5. Verify not accidentally committed: `git check-ignore -v env/dev.env.json`

## Security Best Practices

### API Key Security (C2 Constitutional Compliance)
- ✅ **Never commit API keys to version control**
  - `env/dev.env.json` is gitignored
  - Pre-commit hook blocks accidental commits
  - Use `env/dev.env.json.template` for sharing structure only
- ✅ **Use key restrictions** (package name, bundle ID, SHA-1, HTTP referrers)
  - Prevents unauthorized usage
  - Limits blast radius if key compromised
- ✅ **Rotate keys periodically**
  - Quarterly rotation recommended
  - Immediately rotate if key exposed
  - Document rotation procedure for team
- ✅ **Monitor usage for anomalies**
  - Set up GCP billing alerts (50%, 80%, 95%)
  - Review usage patterns weekly
  - Investigate unexpected spikes
- ✅ **Use separate keys for dev/staging/production**
  - Dev: Unrestricted (localhost, debug certificates)
  - Staging: Restricted to staging domains/apps
  - Production: Strictly restricted to production domains/apps
- ✅ **Web-specific security**
  - Use build-time injection (never hardcode in source)
  - HTTP referrer restrictions mandatory
  - Consider backend proxy for production (see `docs/WEB_API_KEY_SECURITY.md`)

### Logging Privacy (C2 Constitutional Compliance)
- ✅ **Coordinate redaction**: Always use `GeographicUtils.logRedact()` or `LocationUtils.logRedact()`
  - Logs coordinates at 2 decimal places (~1km precision)
  - Example: `55.95,-3.19` instead of `55.9533,-3.1883`
  - Prevents user location tracking from logs
- ✅ **Geohash logging**: Use geohash keys for spatial operations
  - Example: `gcpue` (precision 5 = ~4.9km resolution)
  - Inherently privacy-preserving
- ✅ **No PII in logs**: Never log device IDs, user IDs, or precise timestamps with coordinates

## References

### Google Maps Documentation
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Maps SDK for Android Setup](https://developers.google.com/maps/documentation/android-sdk/start)
- [Maps SDK for iOS Setup](https://developers.google.com/maps/documentation/ios-sdk/start)
- [Maps JavaScript API Setup](https://developers.google.com/maps/documentation/javascript/get-api-key)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)

### EFFIS Documentation
- [EFFIS Homepage](https://effis.jrc.ec.europa.eu/)
- [EFFIS WFS Service](https://ies-ows.jrc.ec.europa.eu/)
- [EFFIS Data Access](https://effis.jrc.ec.europa.eu/applications/data-and-services)

### Project Documentation
- `docs/WEB_API_KEY_SECURITY.md` - Web platform security guide
- `docs/WEB_PLATFORM_RESEARCH.md` - Web compatibility analysis
- `docs/CROSS_PLATFORM_TESTING.md` - Platform testing matrix
- `docs/runbooks/effis-monitoring.md` - EFFIS operational procedures
- `docs/privacy-compliance.md` - Privacy compliance statement
- `docs/accessibility-statement.md` - Accessibility features

### Cost Management
- [Google Maps Pricing](https://mapsplatform.google.com/pricing/)
- [Free Tier Details](https://cloud.google.com/maps-platform/pricing#maps-static)
- [Cost Calculator](https://cloud.google.com/products/calculator)
- [Billing Alerts Setup](https://cloud.google.com/billing/docs/how-to/budgets)
