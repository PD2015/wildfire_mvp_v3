#!/bin/bash
# Debug script for Android Google Maps issues
# Usage: ./scripts/debug_android_maps.sh

set -e

echo "🔍 Android Google Maps Debug Tool"
echo "=================================="
echo ""

# Check if Android emulator is running
echo "📱 Checking for running Android emulator..."
if flutter devices | grep -q "emulator"; then
    echo "✅ Android emulator detected"
else
    echo "❌ No Android emulator running"
    echo "   Start one with: flutter emulators --launch <emulator_id>"
    exit 1
fi

echo ""
echo "🔑 Checking API Key Configuration..."
echo "-----------------------------------"

# Check local.properties
if [ -f "android/local.properties" ]; then
    if grep -q "GOOGLE_MAPS_API_KEY_ANDROID" android/local.properties; then
        KEY=$(grep "GOOGLE_MAPS_API_KEY_ANDROID" android/local.properties | cut -d'=' -f2)
        echo "✅ API key found in local.properties: ${KEY:0:20}..."
    else
        echo "⚠️  No API key in local.properties"
    fi
else
    echo "⚠️  local.properties not found"
fi

# Check env/dev.env.json
if [ -f "env/dev.env.json" ]; then
    if grep -q "GOOGLE_MAPS_API_KEY_ANDROID" env/dev.env.json; then
        KEY=$(grep "GOOGLE_MAPS_API_KEY_ANDROID" env/dev.env.json | cut -d'"' -f4)
        echo "ℹ️  API key in dev.env.json: ${KEY:0:20}... (not used by Gradle)"
    fi
fi

echo ""
echo "📋 Collecting Android Logs..."
echo "----------------------------"

# Create logs directory
mkdir -p logs

# Capture logcat with Google Maps filters
echo "Capturing last 500 lines of logcat..."
adb logcat -d -t 500 > logs/android_full.log

echo "Filtering for Google Maps related logs..."
adb logcat -d | grep -iE "google|maps|api|key|authorization|tiles" > logs/android_maps.log 2>&1 || true

echo "Filtering for errors..."
adb logcat -d *:E > logs/android_errors.log 2>&1 || true

echo ""
echo "📊 Analysis"
echo "----------"

# Check for common errors
if grep -qi "authorization.*failure\|api.*key.*invalid\|api.*key.*not.*found" logs/android_maps.log 2>/dev/null; then
    echo "❌ API KEY ERROR DETECTED!"
    echo "   The API key may be invalid or not properly configured."
    echo ""
    grep -i "authorization\|api.*key" logs/android_maps.log | head -5
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "   1. Verify your API key at: https://console.cloud.google.com/google/maps-apis/credentials"
    echo "   2. Check API key restrictions (should allow Android apps)"
    echo "   3. Add package name: com.example.wildfire_mvp_v3"
    echo "   4. Add SHA-1 fingerprint for debug key:"
    echo "      keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
elif grep -qi "service.*disabled\|billing" logs/android_maps.log 2>/dev/null; then
    echo "❌ MAPS SERVICE ERROR DETECTED!"
    echo "   The Maps SDK may not be enabled or billing may not be set up."
    grep -i "service\|billing" logs/android_maps.log | head -5
    echo ""
    echo "🔧 Enable Maps SDK for Android:"
    echo "   https://console.cloud.google.com/google/maps-apis/apis/android-backend.googleapis.com"
else
    echo "ℹ️  No obvious API errors found in logs"
    echo "   Check the log files in ./logs/ directory for details"
fi

echo ""
echo "📁 Log files created:"
echo "   - logs/android_full.log (full logcat)"
echo "   - logs/android_maps.log (Google Maps related)"  
echo "   - logs/android_errors.log (all errors)"
echo ""
echo "🔍 To view logs in real-time, run:"
echo "   adb logcat | grep -iE 'google|maps|wildfire'"
echo ""
echo "💡 Common issues:"
echo "   1. API key not added to Google Cloud Console"
echo "   2. Maps SDK for Android not enabled"
echo "   3. Package name restriction mismatch"
echo "   4. SHA-1 fingerprint not added (for debug builds)"
echo "   5. Billing not enabled on Google Cloud project"
