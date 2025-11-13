#!/bin/bash
# Batch fix FireIncident constructor calls to use FireIncident.test factory

# Replace FireIncident( with FireIncident.test( in test files
find test/ -name "*.dart" -type f -exec sed -i 's/FireIncident(/FireIncident.test(/g' {} \;

echo "✅ Replaced FireIncident() with FireIncident.test() in test files"

# Also fix LatLngBounds( constructor calls to use const
find test/ -name "*.dart" -type f -exec sed -i 's/= LatLngBounds(/= const LatLngBounds(/g' {} \;

echo "✅ Added const to LatLngBounds constructor calls in test files"

echo "🔍 Checking for remaining issues..."
flutter analyze --no-fatal-infos 2>&1 | grep -E "(error|LatLngBounds|FireIncident|ambiguous)" | head -20