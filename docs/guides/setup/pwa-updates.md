---# PWA Update System Guide

title: PWA Update System Guide

status: active## Overview

last_updated: 2025-11-27

category: guidesThe app now has an automatic update notification system that alerts users when a new version is available.

subcategory: setup

---## How It Works



# PWA Update System Guide### User Experience

1. User has PWA open in browser/installed on device

## Overview2. You deploy a new version with updated theme colors, code, or assets

3. Browser detects new `flutter_service_worker.js` (auto-generated with new hashes)

The app uses Flutter's native service worker for PWA caching and updates. Updates are applied **silently** - users get the new version automatically on their next visit.4. Material Design snackbar appears: **"A new version is available!"**

5. User clicks **RELOAD** → app updates immediately

## How It Works6. Or dismisses notification → update happens on next app launch



### User Experience### Technical Flow

1. User has PWA open in browser/installed on device```

2. You deploy a new versionDeploy new build

3. Browser detects new `flutter_service_worker.js` (auto-generated with new content hashes)    ↓

4. New service worker installs in backgroundflutter_service_worker.js generated (new hash)

5. On next page load/visit, user gets the new version automatically    ↓

service_worker_update.js detects updatefound event

### Technical Flow    ↓

```Snackbar notification shown

Deploy new build    ↓

    ↓User clicks RELOAD

flutter_service_worker.js generated (new content hash)    ↓

    ↓custom_service_worker.js receives SKIP_WAITING message

Firebase serves with Cache-Control: no-cache headers    ↓

    ↓New service worker activates + claims clients

Browser fetches updated service worker    ↓

    ↓Page reloads with new version

New SW installs and activates on next navigation```

    ↓

User sees new version## Testing the Update Prompt

```

### Local Testing

## Why Silent Updates?

1. **Build version 1:**

We previously had a custom service worker with "New version available!" snackbar notifications. This was removed because:   ```bash

   ./scripts/build_web.sh

1. **Flutter deprecated their service worker** (Issue #156910) - fighting against framework direction   cd build/web && python3 -m http.server 8000

2. **Two service workers conflicting** - caused infinite reload loops   ```

3. **Complexity vs benefit** - snackbar UI added ~120 lines of code for minimal UX improvement

4. **Modern PWA best practice** - silent updates are less disruptive2. **Open in browser:**

   - Navigate to `http://localhost:8000`

## Cache Strategy   - Open DevTools → Application → Service Workers

   - Should see "custom_service_worker.js" registered

### Firebase Hosting Headers (`firebase.json`)

3. **Make a change:**

| File Type | Cache Strategy | Why |   - Edit `web/manifest.json`: change `"version": "1.0.0"` to `"version": "1.0.1"`

|-----------|---------------|-----|   - Or change theme color in `lib/theme/app_theme.dart`

| `index.html` | `no-cache, must-revalidate` | Always check for updates |

| `flutter_service_worker.js` | `no-cache, must-revalidate` | Triggers SW update cycle |4. **Rebuild:**

| `/assets/**` | `immutable, 1 year` | Content-hashed filenames |   ```bash

| `*.js`, `*.css` | `immutable, 1 year` | Content-hashed by Flutter |   ./scripts/build_web.sh

| Fonts (`.woff2`, etc.) | `immutable, 1 year` | Stable across versions |   ```



### How Cache Invalidation Works5. **Trigger update:**

   - Go back to browser (keep tab open)

Flutter's build process generates unique hashes for all assets:   - Wait ~5 seconds or refresh page

```   - **Snackbar should appear!** 📱

main.dart.js → main.dart.js?v=abc123

assets/fonts/... → assets/fonts/...?v=def456### Firebase Preview Testing

```

1. **Deploy to preview:**

When you deploy:   ```bash

1. `index.html` and `flutter_service_worker.js` are re-fetched (no-cache)   # Make code changes

2. Service worker sees new asset URLs (different hashes)   git add .

3. New assets are fetched, old ones expire from cache   git commit -m "test: update theme color"

4. **No manual cache clearing needed**   git push

   # GitHub Actions creates preview deployment

## Material Icons Offline Support   ```



Material Icons work offline via a three-tier fallback in `web/index.html`:2. **Open preview URL on phone**



1. **Primary**: Flutter's service worker cache (tree-shaken ~12KB)3. **Deploy new version:**

2. **Secondary**: Google Fonts CDN link (online fallback)   ```bash

3. **Tertiary**: `font-display: swap` prevents invisible text   # Make another change

   git commit -m "test: another update"

```html   git push

<!-- In index.html -->   ```

<link href="https://fonts.googleapis.com/icon?family=Material+Icons&display=swap" rel="stylesheet">

4. **On phone:** Wait 60 seconds → update prompt appears

<style>

  @font-face {## Update Frequency

    font-family: 'Material Icons';

    font-display: swap;- **Active tabs:** Checks every 60 seconds

    /* ... */- **On page load:** Checks immediately

  }- **Background tabs:** Update waits until user returns to tab

</style>

```## Files Created



This is independent of any custom service worker - it works with Flutter's native SW.- `web/service_worker_update.js` - Update detection & UI

- `web/custom_service_worker.js` - Service worker wrapper with SKIP_WAITING

## Testing Updates- `web/manifest.json` - Added version field (1.0.0)

- `web/index.html` - Links service_worker_update.js

### Local Testing

## Customization

1. **Build and serve:**

   ```bash### Change update check interval

   ./scripts/build_web.sh

   cd build/web && python3 -m http.server 8000In `web/service_worker_update.js`:

   ``````javascript

// Check every 60 seconds (default)

2. **Open in browser:**setInterval(function() {

   - Navigate to `http://localhost:8000`  registration.update();

   - Open DevTools → Application → Service Workers}, 60000);  // Change to 30000 for 30 seconds

   - Note the service worker status```



3. **Make a change and rebuild:**### Change snackbar appearance

   ```bash

   # Edit something in lib/In `web/service_worker_update.js`, modify `showUpdatePrompt()`:

   ./scripts/build_web.sh```javascript

   ```snackbar.style.cssText = `

  background-color: #323232;  // Change background

4. **Test update:**  color: white;               // Change text color

   - Refresh the page (or close and reopen)  // ... other styles

   - Service worker should update automatically`;

   - New version visible immediately```



### Force Service Worker Update### Disable auto-dismiss



```javascriptRemove or comment out:

// In browser DevTools Console:```javascript

navigator.serviceWorker.getRegistrations()// Auto-dismiss after 10 seconds

  .then(regs => regs.forEach(r => r.update()))setTimeout(function() {

  .then(() => console.log('Update triggered'));  if (snackbar.parentNode) {

```    snackbar.remove();

  }

### Clear Service Worker Completely}, 10000);  // Remove this to disable auto-dismiss

```

1. DevTools → Application → Service Workers

2. Click "Unregister"## Version Tracking

3. DevTools → Application → Storage → Clear site data

4. Refresh pageUpdate `web/manifest.json` version field before each deployment:



## Troubleshooting```json

{

### Old version still showing?  "version": "1.0.0",  // Update this: 1.0.1, 1.1.0, 2.0.0, etc.

  ...

1. **Hard refresh:** Cmd+Shift+R (Mac) / Ctrl+Shift+R (Windows/Linux)}

2. **Check SW status:** DevTools → Application → Service Workers```

3. **Clear storage:** DevTools → Application → Storage → Clear site data

This helps with debugging and user support:

### Icons missing offline?- Check browser DevTools → Application → Manifest to see version

- Users can report which version they're using

1. Ensure `index.html` has the Google Fonts link

2. Rebuild with `flutter build web --release`## Troubleshooting

3. Check DevTools → Application → Cache Storage for font files

### Update prompt not appearing?

### Service worker not updating?

**Check service worker registration:**

Check Firebase cache headers:```javascript

```bash// In browser DevTools Console:

curl -I https://your-site.web.app/flutter_service_worker.js | grep -i cachenavigator.serviceWorker.getRegistrations().then(r => console.log(r));

# Should show: cache-control: no-cache, no-store, must-revalidate```

```

**Force service worker update:**

## Version Tracking (Optional)```javascript

// In browser DevTools Console:

You can track versions in `web/manifest.json`:navigator.serviceWorker.getRegistrations()

  .then(r => r[0].update())

```json  .then(() => console.log('Update triggered'));

{```

  "version": "1.0.0",

  ...**Clear cache and re-register:**

}1. DevTools → Application → Service Workers

```2. Click "Unregister" 

3. Refresh page

Check version: DevTools → Application → Manifest

### Update applies but old version still showing?

## Files Involved

- Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)

| File | Purpose |- Check browser cache isn't disabled (DevTools → Network → disable cache should be OFF)

|------|---------|- Verify `flutter_service_worker.js` has different content hash

| `web/index.html` | Material Icons fallback, Flutter bootstrap |

| `web/manifest.json` | PWA manifest, optional version field |### Snackbar styling broken?

| `firebase.json` | Cache headers configuration |

| `flutter_service_worker.js` | Auto-generated by Flutter build |- Check for CSS conflicts in your app

- Verify `z-index: 9999` is high enough

## Historical Context- Test in incognito mode to rule out extensions



Previously the app had:## Best Practices

- `web/custom_service_worker.js` - Custom SW wrapper (removed)

- `web/service_worker_update.js` - Update notification UI (removed)1. **Increment version in manifest.json** before each deployment

2. **Test locally first** with the steps above

These were removed in November 2025 because:3. **Document breaking changes** in changelog for users

1. Flutter's service worker is officially deprecated4. **Monitor Firebase Hosting** for deployment success

2. Two SWs caused infinite reload loops5. **Check analytics** to see how many users accept updates

3. Simpler is better - native SW handles everything we need

## Resources

See: [Flutter Issue #156910](https://github.com/flutter/flutter/issues/156910)

- [Service Worker Lifecycle](https://web.dev/service-worker-lifecycle/)

## Resources- [PWA Update Strategies](https://web.dev/service-worker-lifecycle/#skip-the-waiting-phase)

- [Flutter Web Service Worker](https://docs.flutter.dev/deployment/web#caching-issues)

- [Flutter Web Service Worker (deprecated)](https://docs.flutter.dev/deployment/web#service-worker)
- [Service Worker Lifecycle](https://web.dev/service-worker-lifecycle/)
- [Firebase Hosting Cache Config](https://firebase.google.com/docs/hosting/full-config#headers)
