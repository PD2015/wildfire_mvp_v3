---
title: PWA Material Icons Offline Fix
status: active
last_updated: 2025-11-26
category: guides
subcategory: setup
related:
  - guides/setup/google-maps.md
  - reference/test-coverage.md
---

# PWA Material Icons Offline Fix

## Problem

Material Icons (Flutter's default icon font) were not displaying in the PWA when offline or when loaded from cache. Icons appeared fine in regular Chrome browser but disappeared in PWA mode.

**Symptoms:**
- ✅ Icons visible in Chrome DevTools (localhost)
- ❌ Icons missing in installed PWA
- ❌ Icons missing after going offline
- ❌ Icons missing on reload from cache

## Root Cause

Flutter's service worker was being generated correctly and **did include** the MaterialIcons font file in its cache manifest:

```javascript
// flutter_service_worker.js (auto-generated)
const RESOURCES = {
  "assets/fonts/MaterialIcons-Regular.otf": "0d1517754cca310e17c37a1a3a50c3e1",
  // ... other assets
};
```

However, the browser was failing to load the font from the service worker cache because:

1. **No explicit font preload** in `index.html`
2. **No Google Fonts CDN fallback** for Material Icons
3. **No font-display strategy** defined

## Solution

### 1. Add Material Icons Font Link to index.html

Added explicit Google Fonts CDN link with preconnect optimization:

```html
<!-- web/index.html -->
<head>
  <!-- ... -->
  
  <!-- Ensure Material Icons font loads properly for PWA offline use -->
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons&display=swap" rel="stylesheet">
  
  <!-- ... -->
</head>
```

### 2. Add CSS Font-Face with font-display: swap

Added explicit `@font-face` declaration with `font-display: swap` to ensure graceful fallback:

```html
<!-- web/index.html -->
<style>
  /* Ensure Material Icons display properly in PWA mode */
  /* Use font-display: swap to show fallback while loading */
  @font-face {
    font-family: 'Material Icons';
    font-style: normal;
    font-weight: 400;
    font-display: swap;
    src: url(https://fonts.gstatic.com/s/materialicons/v140/flUhRq6tzZclQEJ-Vdg-IuiaDsNc.woff2) format('woff2');
  }
  
  .material-icons {
    font-family: 'Material Icons';
    font-weight: normal;
    font-style: normal;
    font-size: 24px;
    line-height: 1;
    letter-spacing: normal;
    text-transform: none;
    display: inline-block;
    white-space: nowrap;
    word-wrap: normal;
    direction: ltr;
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
    -moz-osx-font-smoothing: grayscale;
    font-feature-settings: 'liga';
  }
</style>
```

### 3. Verify Service Worker Registration

Flutter's `flutter_bootstrap.js` automatically handles service worker registration via the modern API. No manual registration needed.

**Old approach (deprecated):**
```javascript
// DON'T DO THIS - deprecated approach
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('flutter_service_worker.js');
  });
}
```

**Modern approach (automatic):**
```html
<!-- flutter_bootstrap.js handles service worker registration automatically -->
<script src="flutter_bootstrap.js" async></script>
```

### 4. Rebuild Web App

After making changes to `web/index.html`, rebuild the web app:

```bash
# Using the secure build script (injects API keys)
./scripts/build_web.sh

# Or manual build
flutter build web --release
```

## Verification Steps

### 1. Check Service Worker Cache

1. Build and serve the web app:
   ```bash
   cd build/web
   python3 -m http.server 8080
   ```

2. Open Chrome DevTools → Application → Service Workers
   - Verify service worker is registered
   - Status should be "activated and running"

3. Check Cache Storage:
   - Application → Cache Storage → flutter-app-cache
   - Verify `assets/fonts/MaterialIcons-Regular.otf` is cached

### 2. Test Offline Mode

1. Load the app normally (online)
2. Open Chrome DevTools → Network tab
3. Check "Offline" checkbox
4. Reload the page
5. **Verify:** Material Icons still display correctly

### 3. Test Installed PWA

1. Chrome → Menu → Install WildFire MVP
2. Launch installed PWA
3. Go offline (turn off Wi-Fi or use DevTools offline mode)
4. **Verify:** Icons still display

### 4. Test Font Fallback

1. Open DevTools → Network tab
2. Right-click MaterialIcons font request
3. Select "Block request URL"
4. Reload page
5. **Verify:** Icons show fallback (from Google Fonts CDN)

## Technical Details

### Font Loading Strategy

The solution implements a **three-tier font loading strategy**:

1. **Primary: Flutter Service Worker Cache**
   - MaterialIcons-Regular.otf bundled with app
   - Loaded from service worker cache when offline
   - Tree-shaken to ~12KB (99.3% reduction from 1.6MB)

2. **Secondary: Google Fonts CDN**
   - Fallback if service worker cache fails
   - Uses WOFF2 format (better compression)
   - Preconnect for faster loading

3. **Tertiary: font-display: swap**
   - Shows fallback font while Material Icons loads
   - Prevents invisible text during font load
   - Ensures icons are always visible (even if generic)

### Why This Works

**Problem:** Browsers prioritize cached resources differently than live CDN resources. The service worker cache was present but not being used as the primary font source.

**Solution:** By adding both the Google Fonts link (`<link>`) and explicit `@font-face` with `font-display: swap`, we tell the browser:

1. "Material Icons is a critical font, preload it"
2. "Use the CDN version if you don't have it cached yet"
3. "Show a fallback immediately, swap when ready"

This ensures the service worker cache is checked first, but if it fails, the CDN provides a fallback.

### Font Tree-Shaking

Flutter automatically tree-shakes the MaterialIcons font during build:

```
Font asset "MaterialIcons-Regular.otf" was tree-shaken, 
reducing it from 1645184 to 12172 bytes (99.3% reduction).
```

This means the bundled font **only includes glyphs used in the app**, making it very lightweight for offline use.

To disable tree-shaking (not recommended):
```bash
flutter build web --no-tree-shake-icons
```

## Related Issues

- **Flutter Issue #76009**: Service worker not caching MaterialIcons on iOS Safari
- **Flutter Issue #91237**: PWA icons disappear on reload

## Testing Checklist

- [x] Icons display in regular Chrome browser
- [x] Icons display in installed PWA (online)
- [x] Icons display in installed PWA (offline)
- [x] Icons display after clearing browser cache
- [x] Icons display on first load (new user)
- [x] Service worker cache includes MaterialIcons-Regular.otf
- [x] Google Fonts CDN link present in index.html
- [x] font-display: swap configured
- [x] No console errors about missing fonts

## Troubleshooting

### Icons still not showing offline

1. **Clear service worker cache:**
   - DevTools → Application → Service Workers → Unregister
   - Application → Cache Storage → Delete all caches
   - Hard reload (Cmd+Shift+R / Ctrl+Shift+F5)

2. **Verify font file in cache:**
   ```javascript
   // Run in Chrome DevTools console
   caches.open('flutter-app-cache').then(cache => {
     cache.match('assets/fonts/MaterialIcons-Regular.otf').then(response => {
       console.log('Font cached:', !!response);
     });
   });
   ```

3. **Check CSP headers:**
   - Ensure Content-Security-Policy allows fonts from fonts.gstatic.com
   - Add to Firebase hosting headers if needed

### Icons show as boxes (□)

This means the font file is loading but glyphs are missing:

1. **Rebuild with all icons:**
   ```bash
   flutter build web --no-tree-shake-icons
   ```

2. **Check if icon is in Material Icons:**
   - Visit https://fonts.google.com/icons
   - Verify icon name matches Flutter's `Icons.*` constant

### Font loading slowly

1. **Add preload hint:**
   ```html
   <link rel="preload" href="assets/fonts/MaterialIcons-Regular.otf" as="font" type="font/otf" crossorigin>
   ```

2. **Verify service worker is activated:**
   - DevTools → Application → Service Workers
   - Status should be "activated and running"

## References

- [Flutter Web Service Worker Documentation](https://docs.flutter.dev/platform-integration/web/initialization)
- [Google Fonts Material Icons](https://fonts.google.com/icons)
- [MDN: font-display](https://developer.mozilla.org/en-US/docs/Web/CSS/@font-face/font-display)
- [Web.dev: Font Loading Strategies](https://web.dev/font-display/)
