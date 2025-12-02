#!/bin/bash
# Run script for web platform development with secure API key injection
# Temporarily injects API key into web/index.html for flutter run

set -e  # Exit on error

echo "🌐 Running WildFire MVP v3 on Web..."

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

# Backup original index.html
echo "💾 Backing up web/index.html..."
cp web/index.html web/index.html.backup

# Inject API key
if [ -n "$WEB_API_KEY" ]; then
  echo "🔑 Injecting API key into web/index.html..."
  sed -i.bak 's|<script src="https://maps.googleapis.com/maps/api/js"></script>|<script src="https://maps.googleapis.com/maps/api/js?key='"$WEB_API_KEY"'"></script>|' web/index.html
  rm web/index.html.bak
  echo "✅ API key injected"
else
  echo "⚠️  Running without API key (development mode)"
fi

# Cleanup function
cleanup() {
  echo ""
  echo "🔐 Restoring original web/index.html..."
  if [ -f web/index.html.backup ]; then
    mv web/index.html.backup web/index.html
    echo "✅ Restored"
  fi
}

# Register cleanup on exit
trap cleanup EXIT INT TERM

# Run Flutter web on fixed port for API key restrictions
# Google Cloud Console HTTP referrer: http://localhost:8080/*
WEB_PORT=8080

echo "🚀 Starting Flutter web app on port $WEB_PORT..."
echo "   URL: http://localhost:$WEB_PORT"
echo "   Press Ctrl+C to stop"
echo ""
flutter run -d chrome --web-port=$WEB_PORT --dart-define-from-file="$ENV_FILE"
