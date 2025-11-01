#!/bin/bash
#
# setup_xcode_build_phase.sh - Interactive setup for Xcode build phase
# 
# This script helps configure the Xcode build phase for automatic API key injection
# It provides instructions and verification steps
#

set -e

echo "🔧 Xcode Build Phase Setup for iOS Google Maps API Key"
echo "========================================================"
echo ""
echo "This script will guide you through setting up automatic API key"
echo "injection for iOS builds, ensuring your Google Maps integration"
echo "works correctly every time you build."
echo ""

# Check if we're in the project root
if [ ! -f "pubspec.yaml" ] || [ ! -d "ios" ]; then
    echo "❌ Error: This script must be run from the project root directory"
    echo "   Current directory: $(pwd)"
    exit 1
fi

echo "✅ Project root detected"
echo ""

# Verify required files exist
echo "🔍 Checking required files..."
MISSING_FILES=()

if [ ! -f "ios/ios_prebuild.sh" ]; then
    MISSING_FILES+=("ios/ios_prebuild.sh")
fi

if [ ! -f "ios/xcode_build_phase_script.sh" ]; then
    MISSING_FILES+=("ios/xcode_build_phase_script.sh")
fi

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "❌ Missing required files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "   - $file"
    done
    echo ""
    echo "Please ensure all iOS build scripts are present before continuing."
    exit 1
fi

echo "✅ All required files present"
echo ""

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x ios/ios_prebuild.sh
chmod +x ios/xcode_build_phase_script.sh
echo "✅ Scripts are now executable"
echo ""

# Verify API key is in env file
echo "🔑 Checking environment configuration..."
if [ -f "env/dev.env.json" ]; then
    if grep -q "GOOGLE_MAPS_API_KEY_IOS" env/dev.env.json; then
        KEY=$(grep "GOOGLE_MAPS_API_KEY_IOS" env/dev.env.json | cut -d'"' -f4)
        echo "✅ API key found in env/dev.env.json: ${KEY:0:20}..."
    else
        echo "⚠️  Warning: No GOOGLE_MAPS_API_KEY_IOS in env/dev.env.json"
        echo "   You'll need to add this before the build phase will work"
    fi
else
    echo "⚠️  Warning: env/dev.env.json not found"
    echo "   Create this file with your API key before building"
fi
echo ""

echo "📋 MANUAL STEPS REQUIRED"
echo "========================"
echo ""
echo "The Xcode build phase must be added manually through Xcode GUI:"
echo ""
echo "1. Open the Xcode workspace:"
echo "   $ open ios/Runner.xcworkspace"
echo ""
echo "2. In Xcode, select the 'Runner' target (left sidebar)"
echo ""
echo "3. Click the 'Build Phases' tab at the top"
echo ""
echo "4. Click the '+' button in the top left"
echo "   → Select 'New Run Script Phase'"
echo ""
echo "5. Rename the phase (double-click):"
echo "   Name: 'Process DART_DEFINES (API Keys)'"
echo ""
echo "6. IMPORTANT: Drag this phase to position it BEFORE 'Compile Sources'"
echo ""
echo "7. In the script text area, paste this exact content:"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ # Flutter DART_DEFINES API Key Injection                    │"
echo "│ # Processes env vars from --dart-define-from-file           │"
echo "│                                                              │"
echo "│ if [ -f \"\${SRCROOT}/ios/xcode_build_phase_script.sh\" ]; then │"
echo "│     echo \"🔧 Running DART_DEFINES processor...\"              │"
echo "│     bash \"\${SRCROOT}/ios/xcode_build_phase_script.sh\"       │"
echo "│ else                                                         │"
echo "│     echo \"⚠️  Build phase script not found\"                 │"
echo "│ fi                                                           │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "8. (Optional) Configure Input/Output Files for better caching:"
echo ""
echo "   Input Files:"
echo "   - \$(SRCROOT)/Flutter/Generated.xcconfig"
echo "   - \$(SRCROOT)/Runner/Info.plist"
echo "   - \$(SRCROOT)/ios/ios_prebuild.sh"
echo ""
echo "   Output Files:"
echo "   - \$(SRCROOT)/Runner/Info.plist"
echo ""
echo "9. Close Xcode or keep it open for the next step"
echo ""

read -p "Press ENTER when you've completed these steps in Xcode..."

echo ""
echo "🧪 VERIFICATION STEPS"
echo "===================="
echo ""
echo "Let's verify the setup works correctly:"
echo ""

# Test build to generate Generated.xcconfig
echo "1. Running a test build to generate Flutter config..."
flutter build ios --debug --no-codesign --dart-define-from-file=env/dev.env.json 2>&1 | grep -E "Xcode build|error|warning" || true
echo ""

# Check if Generated.xcconfig was created
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "✅ Generated.xcconfig created"
    
    if grep -q "DART_DEFINES" ios/Flutter/Generated.xcconfig; then
        echo "✅ DART_DEFINES found in Generated.xcconfig"
    else
        echo "⚠️  Warning: No DART_DEFINES in Generated.xcconfig"
    fi
else
    echo "⚠️  Generated.xcconfig not created - build may have failed"
fi
echo ""

# Test the prebuild script manually
echo "2. Testing ios_prebuild.sh script directly..."
cd ios
if SRCROOT=$(pwd) ./ios_prebuild.sh 2>&1; then
    echo "✅ Prebuild script executed successfully"
    
    # Check if API key was injected
    if grep -q '<string>AIzaSy' Runner/Info.plist; then
        API_KEY=$(grep -A 1 "GMSApiKey" Runner/Info.plist | grep "string" | sed 's/.*<string>\(.*\)<\/string>/\1/')
        echo "✅ API key injected into Info.plist: ${API_KEY:0:20}..."
    else
        echo "⚠️  API key not found in Info.plist"
    fi
else
    echo "❌ Prebuild script failed - check error messages above"
fi
cd ..
echo ""

echo "3. Final verification - Build with Xcode build phase..."
echo "   Run this command to test the full build:"
echo ""
echo "   $ flutter run -d iPhone --dart-define-from-file=env/dev.env.json"
echo ""
echo "   Look for this output in the Xcode build log:"
echo "   🔧 Running DART_DEFINES processor..."
echo "   ✅ Xcode Build Phase: API key injection completed successfully"
echo ""

read -p "Would you like to run a test build now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Running test build..."
    echo ""
    flutter run -d iPhone --dart-define-from-file=env/dev.env.json
else
    echo ""
    echo "Skipping test build. You can run it manually later."
fi

echo ""
echo "✅ SETUP COMPLETE"
echo "================"
echo ""
echo "Your Xcode build phase is now configured for automatic API key injection."
echo ""
echo "From now on, simply use:"
echo "  $ flutter run -d iPhone --dart-define-from-file=env/dev.env.json"
echo "  $ flutter build ios --dart-define-from-file=env/dev.env.json"
echo ""
echo "The API key will be automatically injected during the Xcode build phase."
echo ""
echo "📚 Documentation: docs/IOS_GOOGLE_MAPS_INTEGRATION.md"
echo ""
