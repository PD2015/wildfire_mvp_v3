#!/bin/bash
#
# ios_prebuild.sh - Injects API keys into iOS Info.plist before build
#

set -e

echo "🔧 iOS Pre-build: Processing API keys..."

# Paths
INFO_PLIST="$SRCROOT/Runner/Info.plist"
GENERATED_XCCONFIG="$SRCROOT/Flutter/Generated.xcconfig"

# Check if files exist
if [ ! -f "$INFO_PLIST" ]; then
    echo "❌ Info.plist not found at $INFO_PLIST"
    exit 1
fi

if [ ! -f "$GENERATED_XCCONFIG" ]; then
    echo "❌ Generated.xcconfig not found at $GENERATED_XCCONFIG"
    exit 1
fi

# Extract DART_DEFINES from Generated.xcconfig
DART_DEFINES=$(grep "DART_DEFINES=" "$GENERATED_XCCONFIG" | sed 's/DART_DEFINES=//')

if [ -z "$DART_DEFINES" ]; then
    echo "❌ No DART_DEFINES found in Generated.xcconfig"
    exit 1
fi

echo "✅ Found DART_DEFINES in Generated.xcconfig"

# Decode base64 DART_DEFINES to find Google Maps API key
API_KEY=""
echo "$DART_DEFINES" | tr ',' '\n' | while read -r encoded_define; do
    if [ ! -z "$encoded_define" ]; then
        # Decode base64
        decoded=$(echo "$encoded_define" | base64 -d 2>/dev/null || echo "")
        echo "  $decoded"
        
        if [[ "$decoded" == "GOOGLE_MAPS_API_KEY_IOS="* ]]; then
            API_KEY=$(echo "$decoded" | cut -d'=' -f2-)
            echo "Found API key: ${API_KEY:0:20}..."
            echo "$API_KEY" > /tmp/gms_api_key
        fi
    fi
done

if [ -f /tmp/gms_api_key ]; then
    API_KEY=$(cat /tmp/gms_api_key)
    rm /tmp/gms_api_key
fi

if [ -z "$API_KEY" ]; then
    echo "❌ GOOGLE_MAPS_API_KEY_IOS not found in DART_DEFINES"
    echo "Available defines:"
    for encoded_define in "${DEFINES[@]}"; do
        decoded=$(echo "$encoded_define" | base64 -d 2>/dev/null || echo "")
        echo "  $decoded"
    done
    exit 1
fi

echo "✅ Found Google Maps API key: ${API_KEY:0:20}..."

# Replace placeholder in Info.plist
if /usr/libexec/PlistBuddy -c "Set :GMSApiKey $API_KEY" "$INFO_PLIST" 2>/dev/null; then
    echo "✅ Successfully updated GMSApiKey in Info.plist"
else
    echo "❌ Failed to update GMSApiKey in Info.plist"
    exit 1
fi

echo "✅ iOS Pre-build complete - API key injected"