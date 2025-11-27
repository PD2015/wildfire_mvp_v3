#!/bin/bash
# Run Flutter app on Android emulator with environment variables
# Usage: ./scripts/run_android.sh [device-id]
# If no device-id provided, auto-detects first Android device

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if env file exists
if [ ! -f "env/dev.env.json" ]; then
    echo "❌ Error: env/dev.env.json not found"
    echo "   Copy env/dev.env.json.template to env/dev.env.json and add your API keys"
    exit 1
fi

# Use provided device or auto-detect Android emulator
if [ -n "$1" ] && [[ "$1" != -* ]]; then
    ANDROID_DEVICE="$1"
    shift
else
    # Look for emulator-* pattern (Android emulator)
    ANDROID_DEVICE=$(adb devices 2>/dev/null | grep -E "^emulator-[0-9]+" | head -1 | awk '{print $1}')
fi

if [ -z "$ANDROID_DEVICE" ]; then
    echo "❌ Error: No Android device found"
    echo "   Start an Android emulator or connect a physical device"
    echo ""
    echo "   Available devices:"
    flutter devices
    exit 1
fi

echo "🤖 Running on Android ($ANDROID_DEVICE) with API keys from env/dev.env.json..."
flutter run -d "$ANDROID_DEVICE" --dart-define-from-file=env/dev.env.json "$@"
