#!/bin/bash
# Run Flutter app on iOS simulator with environment variables
# Usage: ./scripts/run_ios.sh [device-id]
# If no device-id provided, auto-detects first iOS simulator

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

# Use provided device or auto-detect iOS simulator
if [ -n "$1" ] && [[ "$1" != -* ]]; then
    IOS_DEVICE="$1"
    shift
else
    # Look for booted iOS simulator UUID
    IOS_DEVICE=$(xcrun simctl list devices | grep -E "Booted" | head -1 | grep -oE "[A-F0-9-]{36}")
fi

if [ -z "$IOS_DEVICE" ]; then
    echo "❌ Error: No iOS simulator found"
    echo "   Start an iOS simulator from Xcode or run: open -a Simulator"
    echo ""
    echo "   Available devices:"
    flutter devices
    exit 1
fi

echo "� Running on iOS ($IOS_DEVICE) with API keys from env/dev.env.json..."
flutter run -d "$IOS_DEVICE" --dart-define-from-file=env/dev.env.json "$@"
