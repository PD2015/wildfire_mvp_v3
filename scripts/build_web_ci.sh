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
  echo "Usage: MAPS_API_KEY_WEB=<your-key> ./scripts/build_web_ci.sh"
  exit 1
fi

if ! grep -q "%MAPS_API_KEY%" web/index.html; then
  echo "❌ ERROR: Placeholder %MAPS_API_KEY% not found in web/index.html"
  echo "Please ensure web/index.html contains the placeholder pattern"
  exit 1
fi

echo "✅ Input validation passed"
echo "🔑 Using API key: ${MAPS_API_KEY_WEB:0:8}***"

# Phase 2: Inject API key
echo ""
echo "🔑 Injecting API key into web/index.html..."
cp web/index.html web/index.html.bak
sed -i.bkp 's|%MAPS_API_KEY%|?key='"$MAPS_API_KEY_WEB"'|g' web/index.html

# Phase 3: Build Flutter web
echo ""
echo "🔨 Building Flutter web app..."
flutter build web --release --dart-define=MAP_LIVE_DATA=false

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
