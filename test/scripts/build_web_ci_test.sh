#!/bin/bash
# Unit tests for scripts/build_web_ci.sh
# Reference: specs/012-a11-ci-cd/contracts/build-script-contract.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🧪 Testing scripts/build_web_ci.sh"
echo "=================================="
echo ""

cd "$REPO_ROOT"

# Test counter
PASSED=0
FAILED=0

# Test 1: Missing API key
test_missing_api_key() {
  echo "Test 1: Missing API key environment variable"
  unset MAPS_API_KEY_WEB
  
  if ./scripts/build_web_ci.sh 2>&1 | grep -q "MAPS_API_KEY_WEB environment variable not set"; then
    echo "✅ Test 1 PASSED: Script detects missing API key"
    ((PASSED++))
  else
    echo "❌ Test 1 FAILED: Script did not detect missing API key"
    ((FAILED++))
  fi
  echo ""
}

# Test 2: Missing placeholder
test_missing_placeholder() {
  echo "Test 2: Missing placeholder in web/index.html"
  
  # Backup original
  cp web/index.html web/index.html.test.bak
  
  # Remove placeholder temporarily
  sed -i.tmp 's|%MAPS_API_KEY%||g' web/index.html
  
  export MAPS_API_KEY_WEB="test_key_12345"
  if ./scripts/build_web_ci.sh 2>&1 | grep -q "Placeholder %MAPS_API_KEY% not found"; then
    echo "✅ Test 2 PASSED: Script detects missing placeholder"
    ((PASSED++))
  else
    echo "❌ Test 2 FAILED: Script did not detect missing placeholder"
    ((FAILED++))
  fi
  
  # Restore original
  mv web/index.html.test.bak web/index.html
  rm -f web/index.html.tmp
  unset MAPS_API_KEY_WEB
  echo ""
}

# Test 3: Successful build
test_successful_build() {
  echo "Test 3: Successful build with cleanup"
  
  export MAPS_API_KEY_WEB="test_key_AIzaSyTest123"
  
  if ./scripts/build_web_ci.sh > /tmp/build_output.log 2>&1; then
    # Verify artifact contains key
    if grep -q "test_key_AIzaSyTest123" build/web/index.html; then
      # Verify original has placeholder restored
      if grep -q "%MAPS_API_KEY%" web/index.html; then
        # Verify no backup files left
        if [ ! -f "web/index.html.bak" ] && [ ! -f "web/index.html.bkp" ]; then
          echo "✅ Test 3 PASSED: Build succeeded, artifact has key, original restored, cleanup complete"
          ((PASSED++))
        else
          echo "❌ Test 3 FAILED: Backup files not cleaned up"
          ((FAILED++))
        fi
      else
        echo "❌ Test 3 FAILED: Original web/index.html not restored"
        ((FAILED++))
      fi
    else
      echo "❌ Test 3 FAILED: API key not injected in build artifact"
      ((FAILED++))
    fi
  else
    echo "❌ Test 3 FAILED: Build script failed"
    cat /tmp/build_output.log
    ((FAILED++))
  fi
  
  unset MAPS_API_KEY_WEB
  rm -f /tmp/build_output.log
  echo ""
}

# Test 4: API key masking in logs
test_api_key_masking() {
  echo "Test 4: API key masking in logs"
  
  export MAPS_API_KEY_WEB="test_key_AIzaSyTest456789"
  
  ./scripts/build_web_ci.sh > /tmp/build_output.log 2>&1 || true
  
  # Check that full key is NOT in logs
  if ! grep -q "test_key_AIzaSyTest456789" /tmp/build_output.log; then
    # Check that masked version IS in logs (first 8 chars)
    if grep -q "test_key" /tmp/build_output.log; then
      echo "✅ Test 4 PASSED: API key masked in logs"
      ((PASSED++))
    else
      echo "❌ Test 4 FAILED: No masked API key found in logs"
      ((FAILED++))
    fi
  else
    echo "❌ Test 4 FAILED: Full API key exposed in logs"
    ((FAILED++))
  fi
  
  unset MAPS_API_KEY_WEB
  rm -f /tmp/build_output.log
  echo ""
}

# Test 5: Cleanup on build failure (simulated)
test_cleanup_on_failure() {
  echo "Test 5: Cleanup on failure"
  
  # This test verifies the script structure has error handling
  # Actual build failure testing requires breaking Flutter build
  if grep -q "mv web/index.html.bak web/index.html" scripts/build_web_ci.sh; then
    if grep -q "rm -f web/index.html.bkp" scripts/build_web_ci.sh; then
      echo "✅ Test 5 PASSED: Cleanup logic present in script"
      ((PASSED++))
    else
      echo "❌ Test 5 FAILED: Temp file cleanup missing"
      ((FAILED++))
    fi
  else
    echo "❌ Test 5 FAILED: Backup restore logic missing"
    ((FAILED++))
  fi
  echo ""
}

# Run all tests
echo "Running build script tests..."
echo ""

test_missing_api_key
test_missing_placeholder
test_successful_build
test_api_key_masking
test_cleanup_on_failure

# Summary
echo "=================================="
echo "Test Results:"
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"
echo "=================================="

if [ $FAILED -eq 0 ]; then
  echo "🎉 All tests passed!"
  exit 0
else
  echo "⚠️  Some tests failed"
  exit 1
fi
