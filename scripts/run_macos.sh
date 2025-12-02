#!/bin/bash
# Run Flutter app on macOS with environment variables
# Usage: ./scripts/run_macos.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if env file exists
if [ ! -f "env/dev.env.json" ]; then
    echo "❌ Error: env/dev.env.json not found"
    echo "   Copy env/dev.env.json.template to env/dev.env.json and add your API keys"
    exit 1
fi

echo "🖥️ Running on macOS with API keys from env/dev.env.json..."
echo "⚠️ Note: Google Maps is NOT supported on macOS desktop"
flutter run -d macos --dart-define-from-file=env/dev.env.json "$@"
