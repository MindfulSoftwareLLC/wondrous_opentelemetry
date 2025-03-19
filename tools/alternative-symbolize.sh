#!/bin/bash
# Alternative approach to symbolize Flutter stack traces
set -e

# Find the most recent debug symbols directory
LATEST_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* 2>/dev/null | head -1)
if [ -z "$LATEST_SYMBOLS_DIR" ]; then
  echo "Error: No debug symbols directory found!"
  exit 1
fi

echo "Using debug symbols from: $LATEST_SYMBOLS_DIR"

# Create target directories if they don't exist
mkdir -p "$LATEST_SYMBOLS_DIR/for_symbolize"
mkdir -p "$LATEST_SYMBOLS_DIR/for_symbolize/app.so"
mkdir -p "$LATEST_SYMBOLS_DIR/for_symbolize/app.so.isolated_symbols"

# Copy and rename files
if [ -f "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" ]; then
  echo "Copying ARM64 symbols..."
  cp "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" "$LATEST_SYMBOLS_DIR/for_symbolize/app.so/app.so"
  cp "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" "$LATEST_SYMBOLS_DIR/for_symbolize/app.so.isolated_symbols/app.so.isolated_symbols"
else
  echo "Warning: ARM64 symbols not found!"
fi

# Try different naming approach for the enhanced stack trace
cp tools/complete-test-stack-trace.txt tools/stack-trace-for-alternative.txt

# Now try symbolization with this structure
echo "Attempting symbolization with alternative structure..."
flutter symbolize \
  --debug-info="$LATEST_SYMBOLS_DIR/for_symbolize" \
  --input=tools/stack-trace-for-alternative.txt \
  --verbose

echo "If that didn't work, here's one more approach to try manually:"
echo "1. Go to $LATEST_SYMBOLS_DIR/android"
echo "2. Create a directory structure like this:"
echo "   mkdir -p app.so/arm64-v8a"
echo "   cp app.android-arm64.symbols app.so/arm64-v8a/libapp.so"
echo "3. Then run: flutter symbolize --debug-info=path/to/app.so --input=path/to/stack-trace.txt"
