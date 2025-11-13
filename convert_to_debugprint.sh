#!/bin/bash
# Convert test scripts to use debugPrint() best practice

echo "🔧 Converting test scripts to use debugPrint() best practice..."

# Add Flutter foundation import and convert print() calls
files=(
  "test_active_fires_service.dart"
  "test_active_fires_response.dart" 
  "test_active_fires_simple.dart"
  "test_bottom_sheet_state.dart"
  "test_distance_calculator.dart"
  "test_fire_incident_enhanced.dart"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo "📝 Converting $file..."
    
    # Remove ignore directive if present
    sed -i '/ignore_for_file: avoid_print/d' "$file"
    
    # Add Flutter foundation import after first comment block
    if ! grep -q "import 'package:flutter/foundation.dart'" "$file"; then
      # Find first import line and add foundation import before it
      sed -i '/^import /i\import '\''package:flutter/foundation.dart'\'';' "$file"
    fi
    
    # Convert all print() to debugPrint()
    sed -i 's/print(/debugPrint(/g' "$file"
    
    echo "✅ Converted $file"
  fi
done

echo "🎉 All test scripts converted to use debugPrint() best practice!"
echo ""
echo "🔍 Checking for remaining print() issues..."
flutter analyze --no-fatal-infos 2>&1 | grep -E "(avoid_print|print)" | head -5 || echo "✅ No print() issues found!"