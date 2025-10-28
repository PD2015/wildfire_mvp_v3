#!/bin/bash
#
# xcode_build_phase_script.sh - Xcode Build Phase for API Key Injection
#
# This script is designed to run as an Xcode "Run Script Phase" to automatically
# process DART_DEFINES and inject API keys into Info.plist during builds.
#
# Usage: Add this as a Run Script Phase in Xcode before "Compile Sources"
#

set -e

echo "🔧 Xcode Build Phase: Processing environment variables..."

# Verify we're running in Xcode build context
if [ -z "$SRCROOT" ] || [ -z "$BUILT_PRODUCTS_DIR" ]; then
    echo "❌ This script must be run from an Xcode build phase"
    echo "Missing required Xcode environment variables (SRCROOT, BUILT_PRODUCTS_DIR)"
    exit 1
fi

# Check if DART_DEFINES are available
GENERATED_XCCONFIG="$SRCROOT/Flutter/Generated.xcconfig"
if [ ! -f "$GENERATED_XCCONFIG" ]; then
    echo "⚠️  No Generated.xcconfig found - skipping API key injection"
    echo "This is normal for clean builds or if flutter build hasn't been run yet"
    exit 0
fi

# Check if DART_DEFINES exist in the config
if ! grep -q "DART_DEFINES=" "$GENERATED_XCCONFIG"; then
    echo "⚠️  No DART_DEFINES found in Generated.xcconfig - using existing Info.plist values"
    exit 0
fi

# Check if our prebuild script exists
PREBUILD_SCRIPT="$SRCROOT/ios_prebuild.sh"
if [ ! -f "$PREBUILD_SCRIPT" ]; then
    echo "❌ Prebuild script not found at $PREBUILD_SCRIPT"
    echo "Expected to find ios_prebuild.sh in the ios/ directory"
    exit 1
fi

echo "✅ Found DART_DEFINES and prebuild script - processing API keys..."

# Execute our proven prebuild logic
cd "$SRCROOT"
bash "$PREBUILD_SCRIPT"

# Check if the script succeeded
if [ $? -eq 0 ]; then
    echo "✅ Xcode Build Phase: API key injection completed successfully"
else
    echo "❌ Xcode Build Phase: API key injection failed"
    exit 1
fi