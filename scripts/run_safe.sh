#!/bin/bash

# WildFire App - Safe Run Script
# Ensures Google Maps API keys are properly injected to prevent iOS crashes

set -e

echo "🔥 WildFire MVP - Starting with Google Maps API key injection..."
echo ""

# Check if environment file exists
if [ ! -f "env/dev.env.json" ]; then
    echo "❌ ERROR: env/dev.env.json not found!"
    echo "   Copy from template: cp env/dev.env.json.template env/dev.env.json"
    echo "   Then add your Google Maps API keys"
    exit 1
fi

echo "✅ Environment file found: env/dev.env.json"

# Show available devices
echo ""
echo "📱 Available devices:"
flutter devices

echo ""
echo "🚀 Choose a platform:"
echo "  [1] iOS Simulator (requires API keys)"
echo "  [2] Android Emulator"
echo "  [3] Chrome Web"
echo "  [4] macOS Desktop"
echo "  [5] Let Flutter choose device"
echo ""
read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo "🍎 Running on iOS Simulator with API key injection..."
        flutter run -d ios --dart-define-from-file=env/dev.env.json
        ;;
    2)
        echo "🤖 Running on Android Emulator with API key injection..."
        flutter run -d android --dart-define-from-file=env/dev.env.json
        ;;
    3)
        echo "🌐 Running on Chrome Web with API key injection..."
        flutter run -d chrome --dart-define-from-file=env/dev.env.json
        ;;
    4)
        echo "🖥️ Running on macOS Desktop with API key injection..."
        flutter run -d macos --dart-define-from-file=env/dev.env.json
        ;;
    5)
        echo "🎯 Running with device selection and API key injection..."
        flutter run --dart-define-from-file=env/dev.env.json
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac