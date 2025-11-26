---
title: PWA Best Practices for Flutter Web
status: active
last_updated: 2025-11-26
category: guides
subcategory: setup
related:
  - guides/setup/PWA_ICON_FIX.md
  - guides/setup/google-maps.md
---

# PWA Best Practices for Flutter Web

## Problem: Build Script Overwrites web/index.html

**Issue**: The `scripts/build_web.sh` script **reverts `web/index.html`** after building:

```bash
# Line 47 in build_web.sh
git checkout web/index.html 2>/dev/null
```

This means **any manual edits to `web/index.html` are lost** after running the build script.

**Why**: The script temporarily injects the Google Maps API key into `index.html` for the build, then restores the original to prevent committing secrets.

## Solution: Persistent PWA Configuration

Instead of manually editing `web/index.html` (which gets overwritten), use these approaches:

### Option 1: Modify Source index.html (Recommended)

Make changes to `web/index.html` and **commit them to git**. The build script only reverts if there are uncommitted changes.

```bash
# Edit web/index.html with PWA improvements
# Commit the changes
git add web/index.html
git commit -m "feat: add PWA offline support for Material Icons"

# Now build script won't revert (file is already in git)
./scripts/build_web.sh
```

### Option 2: Update Build Script

Modify `scripts/build_web.sh` to preserve PWA configuration:

```bash
# Instead of: git checkout web/index.html
# Use: Only restore if we made changes
if [ -f "web/index.html.original" ]; then
  mv web/index.html.original web/index.html
fi
```

## PWA Essential Checklist

Based on [web.dev PWA Checklist](https://web.dev/pwa-checklist/):

### ✅ Already Implemented

- [x] **HTTPS** (Firebase Hosting provides this)
- [x] **Web manifest** (`manifest.json` exists)
- [x] **Service worker** (Flutter auto-generates `flutter_service_worker.js`)
- [x] **Responsive design** (`viewport` meta tag configured)
- [x] **App icons** (192x192, 512x512, maskable variants)
- [x] **Splash screens** (Flutter native splash integrated)
- [x] **Standalone display mode** (in manifest)
- [x] **Theme color** (`#1B6B61` - Scottish forest green)

### ⚠️ Missing/Needs Improvement

#### 1. Material Icons Offline Support

**Problem**: Icons don't load in PWA offline mode.

**Solution** (needs to be in committed `web/index.html`):

```html
<head>
  <!-- ... existing meta tags ... -->
  
  <!-- Material Icons offline support -->
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons&display=swap" rel="stylesheet">
  
  <!-- PWA Material Icons fallback CSS -->
  <style>
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
</head>
```

#### 2. Better App Names in manifest.json

```json
{
  "name": "WildFire Scotland - Fire Risk Assessment",
  "short_name": "WildFire",
  "description": "Scottish wildfire risk assessment with real-time EFFIS data",
  "categories": ["utilities", "weather", "productivity"],
  "lang": "en-GB",
  "dir": "ltr"
}
```

#### 3. Offline Fallback Page

Create `web/offline.html` for when offline and service worker cache fails:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Offline - WildFire Scotland</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background-color: #1B6B61;
      color: white;
      text-align: center;
      padding: 20px;
    }
    h1 { margin-bottom: 10px; }
    p { opacity: 0.9; }
  </style>
</head>
<body>
  <div>
    <h1>📡 You're Offline</h1>
    <p>WildFire Scotland requires an internet connection.</p>
    <p>Please check your connection and try again.</p>
  </div>
</body>
</html>
```

#### 4. Meta Tags for Social Sharing (Open Graph)

Add to `web/index.html`:

```html
<!-- Open Graph / Facebook -->
<meta property="og:type" content="website">
<meta property="og:url" content="https://wildfire-app-e11f8.web.app/">
<meta property="og:title" content="WildFire Scotland - Fire Risk Assessment">
<meta property="og:description" content="Real-time wildfire risk data for Scotland powered by EFFIS">
<meta property="og:image" content="https://wildfire-app-e11f8.web.app/icons/Icon-512.png">

<!-- Twitter -->
<meta property="twitter:card" content="summary_large_image">
<meta property="twitter:url" content="https://wildfire-app-e11f8.web.app/">
<meta property="twitter:title" content="WildFire Scotland - Fire Risk Assessment">
<meta property="twitter:description" content="Real-time wildfire risk data for Scotland powered by EFFIS">
<meta property="twitter:image" content="https://wildfire-app-e11f8.web.app/icons/Icon-512.png">
```

#### 5. App Install Prompt Handling

Add to `web/index.html` before closing `</body>`:

```html
<script>
  // PWA install prompt handling
  let deferredPrompt;
  
  window.addEventListener('beforeinstallprompt', (e) => {
    // Prevent Chrome <=67 from automatically showing the prompt
    e.preventDefault();
    // Stash the event so it can be triggered later
    deferredPrompt = e;
    
    // Optionally, send analytics event that PWA install available
    console.log('PWA install available');
  });
  
  window.addEventListener('appinstalled', () => {
    console.log('PWA installed successfully');
    deferredPrompt = null;
  });
</script>
```

#### 6. Caching Strategy in Service Worker

While Flutter auto-generates the service worker, we can add custom caching for external resources by creating `web/custom-service-worker.js`:

```javascript
// Import Flutter's service worker
importScripts('flutter_service_worker.js');

// Add custom caching for external fonts
const CACHE_NAME = 'wildfire-external-v1';
const FONT_URLS = [
  'https://fonts.gstatic.com/s/materialicons/v140/flUhRq6tzZclQEJ-Vdg-IuiaDsNc.woff2'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(FONT_URLS);
    })
  );
});

self.addEventListener('fetch', (event) => {
  // Cache-first strategy for fonts
  if (event.request.url.includes('fonts.gstatic.com')) {
    event.respondWith(
      caches.match(event.request).then((response) => {
        return response || fetch(event.request).then((fetchResponse) => {
          return caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, fetchResponse.clone());
            return fetchResponse;
          });
        });
      })
    );
  }
});
```

#### 7. Performance Budget

Add to `web/index.html`:

```html
<!-- Resource hints for performance -->
<link rel="dns-prefetch" href="https://fonts.googleapis.com">
<link rel="dns-prefetch" href="https://fonts.gstatic.com">
<link rel="dns-prefetch" href="https://maps.googleapis.com">
<link rel="preconnect" href="https://fonts.googleapis.com" crossorigin>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preconnect" href="https://maps.googleapis.com" crossorigin>
```

#### 8. Accessibility - Screen Reader Support

Add ARIA labels to manifest:

```json
{
  "screenshots": [
    {
      "src": "screenshots/home.png",
      "sizes": "1280x720",
      "type": "image/png",
      "label": "Home screen showing fire risk level"
    },
    {
      "src": "screenshots/map.png",
      "sizes": "1280x720",
      "type": "image/png",
      "label": "Map view with active fire incidents"
    }
  ]
}
```

#### 9. Better iOS Support

Add to `web/index.html`:

```html
<!-- iOS specific meta tags -->
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="WildFire">
<link rel="apple-touch-icon" sizes="180x180" href="icons/Icon-192.png">
<link rel="apple-touch-startup-image" href="splash/img/light-2x.png">

<!-- Disable auto-detection of phone numbers -->
<meta name="format-detection" content="telephone=no">
```

#### 10. Security Headers (Firebase hosting.json)

Add to `firebase.json`:

```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          },
          {
            "key": "Referrer-Policy",
            "value": "strict-origin-when-cross-origin"
          },
          {
            "key": "Permissions-Policy",
            "value": "geolocation=(self), camera=(), microphone=()"
          }
        ]
      },
      {
        "source": "**/*.@(woff|woff2|ttf|otf)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      }
    ]
  }
}
```

## Implementation Priority

### High Priority (Do Now)
1. ✅ **Commit Material Icons fix to web/index.html**
2. ✅ **Update manifest.json with better names**
3. ✅ **Add Open Graph meta tags**
4. ✅ **Add resource hints (preconnect, dns-prefetch)**

### Medium Priority (Next Sprint)
5. ⚠️ Create offline fallback page
6. ⚠️ Add PWA install prompt handling
7. ⚠️ Update firebase.json security headers

### Low Priority (Future Enhancement)
8. 📋 Add screenshots to manifest
9. 📋 Custom service worker for advanced caching
10. 📋 Analytics for PWA install tracking

## Testing Checklist

After implementing improvements:

- [ ] Lighthouse PWA audit score >90
- [ ] Install as PWA on desktop (Chrome/Edge)
- [ ] Install as PWA on iOS Safari
- [ ] Install as PWA on Android Chrome
- [ ] Test offline mode (all icons load)
- [ ] Test add to home screen
- [ ] Test app launch from home screen
- [ ] Test share functionality
- [ ] Test orientation lock (portrait)
- [ ] Verify service worker caching

## References

- [web.dev PWA Checklist](https://web.dev/pwa-checklist/)
- [MDN Progressive Web Apps](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)
- [Flutter Web PWA](https://docs.flutter.dev/platform-integration/web/building#deploying-to-the-web)
- [Google Maps Web SDK PWA Support](https://developers.google.com/maps/documentation/javascript/overview#Progressive_Web_Apps)
- [Web App Manifest Spec](https://www.w3.org/TR/appmanifest/)
