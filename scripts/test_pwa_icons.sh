#!/bin/bash

# PWA Offline Icon Test Script
# Tests that Material Icons load correctly in offline mode

set -e

echo "🧪 Testing PWA Material Icons Offline Functionality"
echo "=================================================="

# Start local web server
echo ""
echo "📡 Starting local web server..."
cd build/web
python3 -m http.server 8080 > /dev/null 2>&1 &
SERVER_PID=$!
echo "   Server PID: $SERVER_PID"
echo "   URL: http://localhost:8080"

# Wait for server to start
sleep 2

echo ""
echo "✅ Server started successfully"
echo ""
echo "📋 Manual Test Steps:"
echo "   1. Open Chrome: http://localhost:8080"
echo "   2. Open DevTools (F12)"
echo "   3. Go to Application tab"
echo "   4. Check Service Workers:"
echo "      - Should show 'flutter_service_worker.js' as activated"
echo "   5. Check Cache Storage → flutter-app-cache:"
echo "      - Verify 'assets/fonts/MaterialIcons-Regular.otf' is cached"
echo "   6. Go to Network tab"
echo "   7. Check 'Offline' checkbox"
echo "   8. Reload the page (Cmd+R / Ctrl+R)"
echo "   9. Verify icons display correctly:"
echo "      - Navigation icons (map, home, info)"
echo "      - Risk level icons"
echo "      - Location icons"
echo ""
echo "🔍 Automated Checks:"
echo ""

# Check service worker file exists
if [ -f "flutter_service_worker.js" ]; then
    echo "   ✅ Service worker file exists"
else
    echo "   ❌ Service worker file missing"
    kill $SERVER_PID
    exit 1
fi

# Check MaterialIcons in service worker cache manifest
if grep -q "MaterialIcons" flutter_service_worker.js; then
    echo "   ✅ MaterialIcons font in service worker cache manifest"
else
    echo "   ❌ MaterialIcons font NOT in service worker cache manifest"
    kill $SERVER_PID
    exit 1
fi

# Check index.html has Material Icons font link
if grep -q "fonts.googleapis.com/icon?family=Material" index.html; then
    echo "   ✅ Google Fonts Material Icons link in index.html"
else
    echo "   ❌ Material Icons font link missing from index.html"
    kill $SERVER_PID
    exit 1
fi

# Check for font-display: swap
if grep -q "font-display: swap" index.html; then
    echo "   ✅ font-display: swap configured"
else
    echo "   ❌ font-display: swap NOT configured"
    kill $SERVER_PID
    exit 1
fi

# Check manifest.json
if [ -f "manifest.json" ]; then
    echo "   ✅ PWA manifest.json exists"
else
    echo "   ❌ PWA manifest.json missing"
fi

echo ""
echo "=================================================="
echo "🎉 All automated checks passed!"
echo ""
echo "⚠️  Now perform manual testing in browser"
echo "   Press Ctrl+C when done to stop the server"
echo "=================================================="

# Wait for user to finish testing
wait $SERVER_PID
