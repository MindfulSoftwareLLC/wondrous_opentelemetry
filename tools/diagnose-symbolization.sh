#!/bin/bash
# Script to diagnose Flutter symbolization issues
set -e

echo "Flutter Symbolization Diagnostic Tool"
echo "------------------------------------"

# Find Flutter version
echo "Checking Flutter version..."
flutter --version

# Find the most recent debug symbols directory
LATEST_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* 2>/dev/null | head -1)
if [ -z "$LATEST_SYMBOLS_DIR" ]; then
  echo "Error: No debug symbols directory found!"
  exit 1
fi

echo "Using debug symbols from: $LATEST_SYMBOLS_DIR"

# Check the Android symbols files
echo "Checking Android symbols files..."
for file in "$LATEST_SYMBOLS_DIR/android/"*.symbols; do
  echo "- $file ($(du -h "$file" | cut -f1))"
  file "$file"
done

# Check the original stack trace file
STACK_TRACE="./tools/release-android-stack-trace.txt"
echo "Checking stack trace file: $STACK_TRACE"
echo "Content ($(wc -l < "$STACK_TRACE") lines):"
cat "$STACK_TRACE"

# Extract build ID from the stack trace
BUILD_ID=$(grep -o "build_id: '[^']*'" "$STACK_TRACE" | sed "s/build_id: '//;s/'//")
echo "Build ID from stack trace: $BUILD_ID"

# Check if build ID is present in the symbols files
if [ ! -z "$BUILD_ID" ]; then
  echo "Checking for build ID in symbols files..."
  for file in "$LATEST_SYMBOLS_DIR/android/"*.symbols; do
    echo "Checking $file for build ID..."
    if strings "$file" | grep -q "$BUILD_ID"; then
      echo "BUILD ID MATCH FOUND in $file!"
    else
      echo "Build ID not found in $file"
    fi
  done
fi

# Check if Flutter can read the ZIP file
echo "Checking if Flutter can read the ZIP file..."
SYMBOLS_ZIP="/Users/mbushe/dev/mf/otel/wonderous_opentelemetry/debug-symbols/wonderous_opentelemetry_android_symbols_proper.zip"
if [ -f "$SYMBOLS_ZIP" ]; then
  echo "ZIP file exists: $SYMBOLS_ZIP ($(du -h "$SYMBOLS_ZIP" | cut -f1))"
  
  # Try to list the contents of the ZIP
  echo "ZIP file contents:"
  unzip -l "$SYMBOLS_ZIP" | head -10
  
  # Check if Flutter can actually read the file
  echo "Attempting to have Flutter read the ZIP file..."
  TEMP_FILE=$(mktemp)
  flutter symbolize --debug-info="$SYMBOLS_ZIP" --input="$STACK_TRACE" --verbose > "$TEMP_FILE" 2>&1 || true
  
  # Check if there are specific errors about the ZIP file
  if grep -q "Failed to open" "$TEMP_FILE" || grep -q "ZIP" "$TEMP_FILE" || grep -q "Archive" "$TEMP_FILE"; then
    echo "ZIP file-related errors found:"
    grep -i "zip\|archive\|failed to open" "$TEMP_FILE"
  fi
  
  rm "$TEMP_FILE"
else
  echo "ZIP file not found: $SYMBOLS_ZIP"
fi

# Check if we're dealing with a known Flutter issue
echo "Checking for known Flutter issues..."
if grep -q "Failed to decode symbols file for loading unit 1" "$TEMP_FILE"; then
  echo "This appears to be a known issue with Flutter's symbolizer."
  echo "It might be related to these issues:"
  echo "- https://github.com/flutter/flutter/issues/56631"
  echo "- https://github.com/flutter/flutter/issues/103061"
  echo "- https://github.com/flutter/flutter/issues/90958"
fi

echo ""
echo "Diagnostics complete."
echo ""
echo "Recommendations:"
echo "1. Try using Android NDK tools directly with './tools/manual-symbolize.sh'"
echo "2. Report this issue to the Flutter team with the diagnostic information above"
echo "3. Consider implementing your own symbolization service for OTel stack traces"
echo "4. Ensure your debug symbols are preserved for each app version"
