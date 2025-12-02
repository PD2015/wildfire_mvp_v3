#!/bin/bash
set -e

# CI/CD Build Script for Flutter Web with API Key Injection
# Used by GitHub Actions to inject Google Maps API key at build time
# Reference: specs/012-a11-ci-cd/contracts/build-script-contract.sh

echo "🔨 Flutter Web CI Build Script"
echo "================================"

# Phase 1: Validate inputs
if [ -z "$MAPS_API_KEY_WEB" ]; then
  echo "❌ ERROR: MAPS_API_KEY_WEB environment variable not set"
  echo "Usage: MAPS_API_KEY_WEB=<your-key> GEOCODING_API_KEY=<geocoding-key> ./scripts/build_web_ci.sh"
  exit 1
fi

# Geocoding API key is optional (falls back to MAPS_API_KEY_WEB if not set)
if [ -z "$GEOCODING_API_KEY" ]; then
  echo "⚠️  WARNING: GEOCODING_API_KEY not set - geocoding/search may not work with referrer-restricted keys"
  echo "   Consider creating a separate key with API restriction (Geocoding API only) instead of HTTP referrer restriction"
  GEOCODING_API_KEY=""
fi

if ! grep -q 'src="https://maps.googleapis.com/maps/api/js"' web/index.html; then
  echo "❌ ERROR: Google Maps script tag not found in web/index.html"
  echo "Expected: <script src=\"https://maps.googleapis.com/maps/api/js\"></script>"
  exit 1
fi

echo "✅ Input validation passed"
echo "🔑 Using Maps API key: ${MAPS_API_KEY_WEB:0:8}***"
if [ -n "$GEOCODING_API_KEY" ]; then
  echo "🔑 Using Geocoding API key: ${GEOCODING_API_KEY:0:8}***"
fi

# Phase 2: Inject API key
echo ""
echo "🔑 Injecting API key into web/index.html..."
cp web/index.html web/index.html.bak
sed -i.bkp 's|https://maps.googleapis.com/maps/api/js"|https://maps.googleapis.com/maps/api/js?key='"$MAPS_API_KEY_WEB"'"|g' web/index.html

# Phase 3: Build Flutter web
echo ""
echo "🔨 Building Flutter web app..."
# Pass API keys via dart-define:
# - GOOGLE_MAPS_API_KEY_WEB: For Static Maps API and Maps JS API (FeatureFlags.googleMapsApiKeyWeb)
# - GOOGLE_MAPS_GEOCODING_API_KEY: For Geocoding/Places REST API (FeatureFlags.geocodingApiKey)
# Also inject Maps key into index.html for JavaScript Maps API (handled above)

# Build command with optional geocoding key
BUILD_CMD="flutter build web --release --dart-define=MAP_LIVE_DATA=false --dart-define=GOOGLE_MAPS_API_KEY_WEB=$MAPS_API_KEY_WEB"

if [ -n "$GEOCODING_API_KEY" ]; then
  BUILD_CMD="$BUILD_CMD --dart-define=GOOGLE_MAPS_GEOCODING_API_KEY=$GEOCODING_API_KEY"
fi

eval $BUILD_CMD

if [ $? -ne 0 ]; then
  echo "❌ Build failed! Restoring original web/index.html..."
  mv web/index.html.bak web/index.html
  rm -f web/index.html.bkp
  exit 1
fi

echo "✅ Web build complete!"

# Phase 4: Cleanup
echo ""
echo "🔒 Cleaning up API key injection..."
mv web/index.html.bak web/index.html
rm -f web/index.html.bkp

# Verify cleanup
if grep -q "$MAPS_API_KEY_WEB" web/index.html; then
  echo "❌ WARNING: API key still present in web/index.html after cleanup!"
  exit 1
fi

if [ ! -f "build/web/index.html" ]; then
  echo "❌ ERROR: Build artifact not found at build/web/index.html"
  exit 1
fi

echo "✅ Cleanup complete - original web/index.html restored"
echo ""
echo "================================"
echo "✅ Build successful!"
echo "📦 Artifact: build/web/"
echo "================================"
