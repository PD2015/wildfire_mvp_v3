#!/bin/bash
#
# verify_xcode_integration.sh - Test script to verify Xcode Build Phase integration
#

echo "🧪 Testing Xcode Build Phase Integration..."
echo ""

# Test 1: Check if required files exist
echo "📋 Test 1: Checking required files..."

files=(
    "ios/ios_prebuild.sh"
    "ios/xcode_build_phase_script.sh"
    "ios/Runner/Info.plist"
    "ios/Flutter/Generated.xcconfig"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Test 2: Check file permissions
echo ""
echo "📋 Test 2: Checking file permissions..."

if [ -x "ios/ios_prebuild.sh" ]; then
    echo "✅ ios/ios_prebuild.sh is executable"
else
    echo "❌ ios/ios_prebuild.sh is not executable"
    echo "Run: chmod +x ios/ios_prebuild.sh"
    exit 1
fi

if [ -x "ios/xcode_build_phase_script.sh" ]; then
    echo "✅ ios/xcode_build_phase_script.sh is executable"
else
    echo "❌ ios/xcode_build_phase_script.sh is not executable"
    echo "Run: chmod +x ios/xcode_build_phase_script.sh"
    exit 1
fi

# Test 3: Check DART_DEFINES availability
echo ""
echo "📋 Test 3: Checking DART_DEFINES availability..."

if grep -q "DART_DEFINES=" ios/Flutter/Generated.xcconfig; then
    echo "✅ DART_DEFINES found in Generated.xcconfig"
    
    # Show available defines
    echo "Available environment variables:"
    DART_DEFINES=$(grep "DART_DEFINES=" ios/Flutter/Generated.xcconfig | sed 's/DART_DEFINES=//')
    echo "$DART_DEFINES" | tr ',' '\n' | while read -r encoded_define; do
        if [ ! -z "$encoded_define" ]; then
            decoded=$(echo "$encoded_define" | base64 -d 2>/dev/null || echo "")
            echo "  $decoded"
        fi
    done
else
    echo "⚠️  No DART_DEFINES found in Generated.xcconfig"
    echo "This is normal if flutter build hasn't been run yet"
    echo "Run: flutter build ios --dart-define-from-file=env/dev.env.json --no-codesign"
fi

# Test 4: Test Xcode build phase script
echo ""
echo "📋 Test 4: Testing Xcode build phase script..."

cd ios
export SRCROOT="$(pwd)"
export BUILT_PRODUCTS_DIR="$(pwd)/build"

if bash xcode_build_phase_script.sh; then
    echo "✅ Xcode build phase script executed successfully"
else
    echo "❌ Xcode build phase script failed"
    exit 1
fi

# Test 5: Verify API key injection
echo ""
echo "📋 Test 5: Verifying API key injection..."

if grep -q "GMSApiKey" Runner/Info.plist; then
    api_key=$(grep -A 1 "GMSApiKey" Runner/Info.plist | tail -1 | sed 's/<[^>]*>//g' | xargs)
    if [[ "$api_key" == *"AIza"* ]]; then
        echo "✅ Google Maps API key successfully injected: ${api_key:0:20}..."
    else
        echo "⚠️  GMSApiKey found but may be placeholder: $api_key"
    fi
else
    echo "❌ No GMSApiKey found in Info.plist"
    exit 1
fi

cd ..

echo ""
echo "🎉 All tests passed! Your Xcode Build Phase integration is ready."
echo ""
echo "Next steps:"
echo "1. Follow instructions in docs/XCODE_BUILD_PHASE_INTEGRATION.md"
echo "2. Add the Run Script Phase in Xcode"
echo "3. Test with: flutter run -d ios --dart-define-from-file=env/dev.env.json"
echo ""