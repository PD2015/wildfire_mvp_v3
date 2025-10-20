#!/bin/bash
# Build script for web platform with secure API key injection
# Prevents API keys from being committed to git

set -e  # Exit on error

echo "🌐 Building WildFire MVP v3 for Web..."

# Check if env file exists
ENV_FILE="${1:-env/dev.env.json}"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Error: Environment file not found: $ENV_FILE"
  echo "   Create it from template: cp env/dev.env.json.template env/dev.env.json"
  exit 1
fi

echo "📦 Using environment file: $ENV_FILE"

# Extract web API key from env file
WEB_API_KEY=$(grep -o '"GOOGLE_MAPS_API_KEY_WEB":\s*"[^"]*"' "$ENV_FILE" | cut -d'"' -f4)

if [ -z "$WEB_API_KEY" ] || [ "$WEB_API_KEY" = "YOUR_WEB_API_KEY_HERE" ]; then
  echo "⚠️  Warning: No web API key found or using placeholder"
  echo "   Map will show 'for development purposes only' watermark"
  WEB_API_KEY=""
fi

# Create temporary index.html with API key injected
echo "🔑 Injecting API key into web/index.html..."
TMP_INDEX="web/index.html.tmp"
cp web/index.html "$TMP_INDEX"

if [ -n "$WEB_API_KEY" ]; then
  # Replace the script tag with one that includes the API key
  sed -i.bak 's|<script src="https://maps.googleapis.com/maps/api/js"></script>|<script src="https://maps.googleapis.com/maps/api/js?key='"$WEB_API_KEY"'"></script>|' "$TMP_INDEX"
  rm "${TMP_INDEX}.bak"
  echo "✅ API key injected"
else
  echo "⚠️  Building without API key (development mode)"
fi

# Move temporary file to original location
mv "$TMP_INDEX" web/index.html

# Build web app
echo "🔨 Building Flutter web app..."
flutter build web --dart-define-from-file="$ENV_FILE"

# Restore original index.html (without API key)
echo "🔐 Restoring original web/index.html (removing API key)..."
git checkout web/index.html 2>/dev/null || echo "   (web/index.html not in git yet)"

echo "✅ Web build complete!"
echo "📁 Output: build/web/"
echo ""
echo "To serve locally:"
echo "  cd build/web && python3 -m http.server 8000"
echo "  Open: http://localhost:8000"
