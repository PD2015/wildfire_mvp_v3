#!/usr/bin/env bash
# Verify no ad-hoc Colors.* usage except in risk widgets
# Part of A11y Theme Overhaul (017-a11y-theme-overhaul)
# Constitutional gate C4: RiskPalette only for risk widgets

set -e

# Files excluded from Colors.* check (preserve RiskPalette usage per C4)
EXCLUDED_FILES=(
  "lib/theme/risk_palette.dart"
  "lib/widgets/risk_banner.dart"
  "lib/features/map/widgets/risk_result_chip.dart"
)

# Build exclusion pattern for grep
EXCLUDE_ARGS=""
for file in "${EXCLUDED_FILES[@]}"; do
  EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$file"
done

# Search for Colors.* usage (not in imports, not in excluded files)
# Exclude acceptable patterns:
# - Colors.transparent (semantic constant for transparency)
# - Colors.red.shade* in wildfire_a11y_theme.dart (ColorScheme error definitions)
VIOLATIONS=$(grep -r "Colors\." lib/ $EXCLUDE_ARGS \
  | grep -v "import 'package:flutter/material.dart'" \
  | grep -v "Colors.transparent" \
  | grep -v "wildfire_a11y_theme.dart.*Colors.red" \
  || true)

if [ -n "$VIOLATIONS" ]; then
  echo "❌ Ad-hoc Colors.* usage found (violates FR-011):"
  echo "$VIOLATIONS"
  echo ""
  echo "Expected: Use theme.colorScheme.* or BrandPalette.* instead"
  echo "Excluded files (RiskPalette preserved per C4):"
  for file in "${EXCLUDED_FILES[@]}"; do
    echo "  - $file"
  done
  echo ""
  echo "Acceptable patterns (excluded from check):"
  echo "  - Colors.transparent (semantic transparency constant)"
  echo "  - Colors.red.shade* in wildfire_a11y_theme.dart (ColorScheme definitions)"
  exit 1
else
  echo "✅ No ad-hoc Colors.* usage found (risk widgets excluded per C4)"
  exit 0
fi
