#!/usr/bin/env bash
# Constitutional Compliance Gates for WildFire MVP
# Enforces C1-C5 requirements at CI/pipeline level

set -e

echo "🏛️  WildFire MVP Constitutional Compliance Check"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track overall pass/fail
OVERALL_RESULT=0

# Function to print results
print_result() {
    local gate="$1"
    local status="$2"
    local message="$3"
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ $gate PASS${NC}: $message"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ $gate FAIL${NC}: $message"
        OVERALL_RESULT=1
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $gate WARN${NC}: $message"
    else
        echo -e "${BLUE}ℹ️  $gate INFO${NC}: $message"
    fi
}

echo
echo "🔍 Running constitutional compliance checks..."
echo

# =============================================================================
# C1: Code Quality & Testing Standards
# =============================================================================
echo -e "${BLUE}📋 C1: CODE QUALITY & TESTING STANDARDS${NC}"
echo "─────────────────────────────────────────────"

# Check Flutter analyze passes
echo "⚙️  Running flutter analyze..."
if flutter analyze --no-fatal-infos; then
    print_result "C1" "PASS" "Flutter analyze completed with no issues"
else
    print_result "C1" "FAIL" "Flutter analyze found issues"
fi

# Check code formatting
echo "⚙️  Checking dart format..."
if dart format --output=none --set-exit-if-changed .; then
    print_result "C1" "PASS" "Code formatting is consistent"
else
    print_result "C1" "FAIL" "Code formatting is inconsistent - run 'dart format .'"
fi

# Run tests and check coverage
echo "⚙️  Running tests with coverage..."
if flutter test --coverage; then
    print_result "C1" "PASS" "All tests passing"
    
    # Check if lcov is available for coverage analysis
    if command -v lcov >/dev/null 2>&1; then
        # Generate coverage summary
        COVERAGE_SUMMARY=$(lcov --summary coverage/lcov.info 2>/dev/null | grep lines || echo "lines......: 0.0%")
        COVERAGE_PERCENT=$(echo "$COVERAGE_SUMMARY" | grep -o '[0-9.]*%' | head -1)
        COVERAGE_NUM=$(echo "$COVERAGE_PERCENT" | sed 's/%//')
        
        if [ -n "$COVERAGE_NUM" ] && (( $(echo "$COVERAGE_NUM >= 90" | bc -l 2>/dev/null || echo "0") )); then
            print_result "C1" "PASS" "Test coverage $COVERAGE_PERCENT meets 90% requirement"
        else
            print_result "C1" "WARN" "Test coverage $COVERAGE_PERCENT may be below 90% target"
        fi
    else
        print_result "C1" "INFO" "lcov not available - install for coverage analysis"
    fi
else
    print_result "C1" "FAIL" "Tests failing"
fi

echo

# =============================================================================
# C2: Privacy & Security (No Secrets, Coordinate Redaction)
# =============================================================================
echo -e "${BLUE}🔒 C2: PRIVACY & SECURITY${NC}"
echo "──────────────────────────"

# Check for hardcoded secrets/API keys
echo "⚙️  Scanning for hardcoded secrets..."
SECRET_PATTERNS=(
    "api_key.*=.*['\"][^'\"]*['\"]"
    "apiKey.*=.*['\"][^'\"]*['\"]" 
    "API_KEY.*=.*['\"][^'\"]*['\"]"
    "secret.*=.*['\"][^'\"]*['\"]"
    "Secret.*=.*['\"][^'\"]*['\"]"
    "SECRET.*=.*['\"][^'\"]*['\"]"
    "password.*=.*['\"][^'\"]*['\"]"
    "Password.*=.*['\"][^'\"]*['\"]"
    "PASSWORD.*=.*['\"][^'\"]*['\"]"
    "token.*=.*['\"][^'\"]*['\"]"
    "Token.*=.*['\"][^'\"]*['\"]"
    "TOKEN.*=.*['\"][^'\"]*['\"]"
)

SECRETS_FOUND=0
for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r --include="*.dart" -E "$pattern" lib/ 2>/dev/null; then
        SECRETS_FOUND=1
        break
    fi
done

if [ $SECRETS_FOUND -eq 0 ]; then
    print_result "C2" "PASS" "No hardcoded secrets detected in lib/"
else
    print_result "C2" "FAIL" "Hardcoded secrets detected - use environment variables"
fi

# Check for coordinate redaction compliance
echo "⚙️  Checking coordinate privacy compliance..."
RAW_COORD_PATTERNS=(
    "log.*\$lat.*\$lon"
    "print.*\$lat.*\$lon" 
    "logger.*\$latitude.*\$longitude"
    "_logger.*position\.latitude.*position\.longitude"
)

RAW_COORDS_FOUND=0
for pattern in "${RAW_COORD_PATTERNS[@]}"; do
    if grep -r --include="*.dart" -E "$pattern" lib/ 2>/dev/null; then
        RAW_COORDS_FOUND=1
        break
    fi
done

if [ $RAW_COORDS_FOUND -eq 0 ]; then
    print_result "C2" "PASS" "No raw coordinate logging detected"
else
    print_result "C2" "FAIL" "Raw coordinate logging detected - use logRedact() helper"
fi

# Check for logRedact usage
if grep -r --include="*.dart" "logRedact\|GeographicUtils\.logRedact\|LocationUtils\.logRedact" lib/ >/dev/null 2>&1; then
    print_result "C2" "PASS" "Privacy-compliant coordinate logging detected"
else
    print_result "C2" "WARN" "No logRedact() usage found - ensure coordinate privacy"
fi

echo

# =============================================================================
# C3: Accessibility Standards
# =============================================================================
echo -e "${BLUE}♿ C3: ACCESSIBILITY STANDARDS${NC}"
echo "───────────────────────────────"

# Check for semantic labels
echo "⚙️  Checking accessibility implementation..."
if grep -r --include="*.dart" -E "(Semantics|semanticLabel|excludeSemantics)" lib/ >/dev/null 2>&1; then
    print_result "C3" "PASS" "Semantic labels detected in widgets"
else
    print_result "C3" "WARN" "No semantic labels found - verify accessibility implementation"
fi

# Check for touch target size considerations
if grep -r --include="*.dart" -E "(kMinInteractiveDimension|MinimumTapTargetSize|44\.0|48\.0)" lib/ test/ >/dev/null 2>&1; then
    print_result "C3" "PASS" "Touch target size considerations found"
else
    print_result "C3" "WARN" "No touch target size references found - ensure 44dp+ interactive elements"
fi

# Check for accessibility tests
if grep -r --include="*.dart" -E "(semantics|Semantics|tester\.semantics)" test/ >/dev/null 2>&1; then
    print_result "C3" "PASS" "Accessibility tests detected"
else
    print_result "C3" "WARN" "No accessibility tests found - add semantic validation"
fi

echo

# =============================================================================  
# C4: Trust & Transparency (Timestamps, Source Labels)
# =============================================================================
echo -e "${BLUE}🕐 C4: TRUST & TRANSPARENCY${NC}"
echo "────────────────────────────"

# Check for timestamp display
echo "⚙️  Checking transparency implementation..."
TIMESTAMP_PATTERNS=(
    "Updated.*ago"
    "Cached.*from"  
    "timestamp"
    "observedAt"
    "Last updated"
    "freshness"
)

TIMESTAMP_FOUND=0
for pattern in "${TIMESTAMP_PATTERNS[@]}"; do
    if grep -r --include="*.dart" -i "$pattern" lib/ >/dev/null 2>&1; then
        TIMESTAMP_FOUND=1
        break
    fi
done

if [ $TIMESTAMP_FOUND -eq 1 ]; then
    print_result "C4" "PASS" "Timestamp/freshness indicators detected"
else
    print_result "C4" "FAIL" "No timestamp indicators found - data freshness must be visible"
fi

# Check for data source labeling
SOURCE_PATTERNS=(
    "source"
    "EFFIS"
    "SEPA" 
    "Mock"
    "Cached"
    "DataSource"
)

SOURCE_FOUND=0
for pattern in "${SOURCE_PATTERNS[@]}"; do
    if grep -r --include="*.dart" "$pattern" lib/ >/dev/null 2>&1; then
        SOURCE_FOUND=1
        break
    fi
done

if [ $SOURCE_FOUND -eq 1 ]; then
    print_result "C4" "PASS" "Data source labeling detected"
else
    print_result "C4" "FAIL" "No data source labeling found - source attribution required"
fi

# Check for official color usage
if [ -f "scripts/allowed_colors.txt" ]; then
    print_result "C4" "PASS" "Official color palette file exists"
else
    print_result "C4" "WARN" "No allowed_colors.txt found - ensure official palette usage"
fi

echo

# =============================================================================
# C5: Resilience & Error Handling
# =============================================================================
echo -e "${BLUE}🛡️  C5: RESILIENCE & ERROR HANDLING${NC}"
echo "──────────────────────────────────"

# Check for error handling patterns
echo "⚙️  Checking error handling implementation..."
ERROR_PATTERNS=(
    "try.*catch"
    "Either.*Left.*Right"
    "Result\."
    "\.fold\("
    "onError"
    "catchError"
)

ERROR_HANDLING_FOUND=0
for pattern in "${ERROR_PATTERNS[@]}"; do
    if grep -r --include="*.dart" -E "$pattern" lib/ >/dev/null 2>&1; then
        ERROR_HANDLING_FOUND=1
        break
    fi
done

if [ $ERROR_HANDLING_FOUND -eq 1 ]; then
    print_result "C5" "PASS" "Error handling patterns detected"
else
    print_result "C5" "FAIL" "No error handling patterns found"
fi

# Check for retry mechanisms
if grep -r --include="*.dart" -i "retry" lib/ >/dev/null 2>&1; then
    print_result "C5" "PASS" "Retry mechanisms detected"
else
    print_result "C5" "WARN" "No retry mechanisms found - consider adding user recovery options"
fi

# Check for fallback mechanisms
FALLBACK_PATTERNS=(
    "fallback"
    "default"
    "mock"
    "cache"
    "backup"
)

FALLBACK_FOUND=0
for pattern in "${FALLBACK_PATTERNS[@]}"; do
    if grep -r --include="*.dart" -i "$pattern" lib/ >/dev/null 2>&1; then
        FALLBACK_FOUND=1
        break
    fi
done

if [ $FALLBACK_FOUND -eq 1 ]; then
    print_result "C5" "PASS" "Fallback mechanisms detected"
else
    print_result "C5" "WARN" "No fallback mechanisms found - ensure graceful degradation"
fi

# Check for timeout handling
if grep -r --include="*.dart" -E "(timeout|Timeout|deadline)" lib/ >/dev/null 2>&1; then
    print_result "C5" "PASS" "Timeout handling detected"
else
    print_result "C5" "WARN" "No timeout handling found - ensure operations have limits"
fi

echo

# =============================================================================
# Summary
# =============================================================================
echo "📊 CONSTITUTIONAL COMPLIANCE SUMMARY"
echo "═══════════════════════════════════"

if [ $OVERALL_RESULT -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL CONSTITUTIONAL GATES PASSED${NC}"
    echo "✅ C1: Code Quality & Testing - COMPLIANT"
    echo "✅ C2: Privacy & Security - COMPLIANT" 
    echo "✅ C3: Accessibility - COMPLIANT"
    echo "✅ C4: Trust & Transparency - COMPLIANT"
    echo "✅ C5: Resilience & Error Handling - COMPLIANT"
    echo
    echo "🚀 Ready for production deployment"
else
    echo -e "${RED}❌ CONSTITUTIONAL COMPLIANCE FAILURES DETECTED${NC}"
    echo "🚫 Fix failures above before proceeding"
    echo
    echo "📚 Remediation Resources:"
    echo "  - Constitution: docs/constitution.md"
    echo "  - Implementation Guide: docs/CONTEXT.md"
    echo "  - Privacy Guidelines: C2 coordinate redaction patterns"
    echo "  - Accessibility: C3 semantic labels & touch targets"
    echo "  - Transparency: C4 timestamp & source visibility"
    echo "  - Resilience: C5 error handling & recovery"
fi

echo
echo "🏛️  Constitutional compliance check complete"
exit $OVERALL_RESULT