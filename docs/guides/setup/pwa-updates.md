# PWA Update System Guide

## Overview

The app now has an automatic update notification system that alerts users when a new version is available.

## How It Works

### User Experience
1. User has PWA open in browser/installed on device
2. You deploy a new version with updated theme colors, code, or assets
3. Browser detects new `flutter_service_worker.js` (auto-generated with new hashes)
4. Material Design snackbar appears: **"A new version is available!"**
5. User clicks **RELOAD** → app updates immediately
6. Or dismisses notification → update happens on next app launch

### Technical Flow
```
Deploy new build
    ↓
flutter_service_worker.js generated (new hash)
    ↓
service_worker_update.js detects updatefound event
    ↓
Snackbar notification shown
    ↓
User clicks RELOAD
    ↓
custom_service_worker.js receives SKIP_WAITING message
    ↓
New service worker activates + claims clients
    ↓
Page reloads with new version
```

## Testing the Update Prompt

### Local Testing

1. **Build version 1:**
   ```bash
   ./scripts/build_web.sh
   cd build/web && python3 -m http.server 8000
   ```

2. **Open in browser:**
   - Navigate to `http://localhost:8000`
   - Open DevTools → Application → Service Workers
   - Should see "custom_service_worker.js" registered

3. **Make a change:**
   - Edit `web/manifest.json`: change `"version": "1.0.0"` to `"version": "1.0.1"`
   - Or change theme color in `lib/theme/app_theme.dart`

4. **Rebuild:**
   ```bash
   ./scripts/build_web.sh
   ```

5. **Trigger update:**
   - Go back to browser (keep tab open)
   - Wait ~5 seconds or refresh page
   - **Snackbar should appear!** 📱

### Firebase Preview Testing

1. **Deploy to preview:**
   ```bash
   # Make code changes
   git add .
   git commit -m "test: update theme color"
   git push
   # GitHub Actions creates preview deployment
   ```

2. **Open preview URL on phone**

3. **Deploy new version:**
   ```bash
   # Make another change
   git commit -m "test: another update"
   git push
   ```

4. **On phone:** Wait 60 seconds → update prompt appears

## Update Frequency

- **Active tabs:** Checks every 60 seconds
- **On page load:** Checks immediately
- **Background tabs:** Update waits until user returns to tab

## Files Created

- `web/service_worker_update.js` - Update detection & UI
- `web/custom_service_worker.js` - Service worker wrapper with SKIP_WAITING
- `web/manifest.json` - Added version field (1.0.0)
- `web/index.html` - Links service_worker_update.js

## Customization

### Change update check interval

In `web/service_worker_update.js`:
```javascript
// Check every 60 seconds (default)
setInterval(function() {
  registration.update();
}, 60000);  // Change to 30000 for 30 seconds
```

### Change snackbar appearance

In `web/service_worker_update.js`, modify `showUpdatePrompt()`:
```javascript
snackbar.style.cssText = `
  background-color: #323232;  // Change background
  color: white;               // Change text color
  // ... other styles
`;
```

### Disable auto-dismiss

Remove or comment out:
```javascript
// Auto-dismiss after 10 seconds
setTimeout(function() {
  if (snackbar.parentNode) {
    snackbar.remove();
  }
}, 10000);  // Remove this to disable auto-dismiss
```

## Version Tracking

Update `web/manifest.json` version field before each deployment:

```json
{
  "version": "1.0.0",  // Update this: 1.0.1, 1.1.0, 2.0.0, etc.
  ...
}
```

This helps with debugging and user support:
- Check browser DevTools → Application → Manifest to see version
- Users can report which version they're using

## Troubleshooting

### Update prompt not appearing?

**Check service worker registration:**
```javascript
// In browser DevTools Console:
navigator.serviceWorker.getRegistrations().then(r => console.log(r));
```

**Force service worker update:**
```javascript
// In browser DevTools Console:
navigator.serviceWorker.getRegistrations()
  .then(r => r[0].update())
  .then(() => console.log('Update triggered'));
```

**Clear cache and re-register:**
1. DevTools → Application → Service Workers
2. Click "Unregister" 
3. Refresh page

### Update applies but old version still showing?

- Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)
- Check browser cache isn't disabled (DevTools → Network → disable cache should be OFF)
- Verify `flutter_service_worker.js` has different content hash

### Snackbar styling broken?

- Check for CSS conflicts in your app
- Verify `z-index: 9999` is high enough
- Test in incognito mode to rule out extensions

## Best Practices

1. **Increment version in manifest.json** before each deployment
2. **Test locally first** with the steps above
3. **Document breaking changes** in changelog for users
4. **Monitor Firebase Hosting** for deployment success
5. **Check analytics** to see how many users accept updates

## Resources

- [Service Worker Lifecycle](https://web.dev/service-worker-lifecycle/)
- [PWA Update Strategies](https://web.dev/service-worker-lifecycle/#skip-the-waiting-phase)
- [Flutter Web Service Worker](https://docs.flutter.dev/deployment/web#caching-issues)
