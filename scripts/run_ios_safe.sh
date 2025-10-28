#!/bin/bash
set -e

echo "🔥 WildFire MVP - iOS Safe Runner"
echo "================================="
echo ""

# Check if environment file exists
if [ ! -f "env/dev.env.json" ]; then
    echo "❌ CRITICAL ERROR: env/dev.env.json not found!"
    echo ""
    echo "   This file is REQUIRED to prevent iOS crashes."
    echo "   Copy from template:"
    echo "   cp env/dev.env.json.template env/dev.env.json"
    echo ""
    exit 1
fi

# Validate API key exists and is not placeholder
IOS_KEY=$(grep -o '"GOOGLE_MAPS_API_KEY_IOS"[^"]*"[^"]*"' env/dev.env.json | cut -d'"' -f4)

if [ -z "$IOS_KEY" ] || [ "$IOS_KEY" = "your-ios-key-here" ] || [ "$IOS_KEY" = "AIzaSy...your-ios-key-here..." ]; then
    echo "❌ CRITICAL ERROR: Invalid Google Maps API key!"
    echo ""
    echo "   iOS will crash without a valid API key."
    echo "   Get a real key from: https://console.cloud.google.com/"
    echo "   Edit env/dev.env.json and add your key"
    echo ""
    exit 1
fi

echo "✅ Environment file found: env/dev.env.json"
echo "✅ iOS API key validated: ${IOS_KEY:0:20}..."
echo ""

# Get iOS device ID
DEVICE_ID=$(flutter devices | grep "ios" | grep -o '[A-Z0-9-]\{36\}' | head -1)

if [ -z "$DEVICE_ID" ]; then
    echo "❌ No iOS simulator found!"
    echo ""
    echo "Available devices:"
    flutter devices
    echo ""
    echo "Please start an iOS simulator first."
    exit 1
fi

echo "✅ Found iOS device: $DEVICE_ID"
echo ""

# Show what will be run
echo "🚀 About to run:"
echo "   flutter run -d $DEVICE_ID --dart-define-from-file=env/dev.env.json"
echo ""
echo "   This command will:"
echo "   ✅ Inject Google Maps API key to prevent crashes"
echo "   ✅ Start app on iOS simulator"
echo "   ✅ Enable hot reload for development"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "🚀 Starting WildFire MVP on iOS..."
echo "=================================="

# Pre-build: Run iOS prebuild script to inject API keys
echo ""
echo "🔧 Running iOS pre-build script..."
cd ios && SRCROOT=$(pwd) ./ios_prebuild.sh
if [ $? -ne 0 ]; then
    echo "❌ iOS pre-build failed. The app will crash without proper API key injection."
    echo "   This is expected on first run. The script will work after Generated.xcconfig is created."
else
    echo "✅ iOS pre-build successful - API keys injected"
fi
cd ..

echo ""
echo "🚀 Launching app..."

# Run the app with proper environment injection
flutter run -d "$DEVICE_ID" --dart-define-from-file=env/dev.env.json

