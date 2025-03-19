#!/bin/bash
# Direct symbolization of specific addresses from the stack trace
set -e

echo "Manual Symbolization of Flutter Stack Trace Addresses"
echo "----------------------------------------------------"

# Find the most recent debug symbols directory
LATEST_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* 2>/dev/null | head -1)
if [ -z "$LATEST_SYMBOLS_DIR" ]; then
  echo "Error: No debug symbols directory found!"
  exit 1
fi

SYMBOLS_FILE="$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols"
echo "Using symbols file: $SYMBOLS_FILE"

# Extract the memory offsets from the instruction pointers
echo "Extracting offsets from stack trace..."
OFFSET1="0x49dec3"  # From _kDartIsolateSnapshotInstructions+0x49dec3
OFFSET2="0x49d57b"  # From _kDartIsolateSnapshotInstructions+0x49d57b

echo "Will symbolize the following offsets:"
echo "- $OFFSET1"
echo "- $OFFSET2"

# Attempt to find addr2line in common locations
echo "Searching for addr2line tool..."
ADDR2LINE=""

# Try to find in Android SDK
for dir in \
  "$HOME/Library/Android/sdk/ndk"* \
  "$HOME/Android/Sdk/ndk"* \
  "$ANDROID_SDK_ROOT/ndk"* \
  "$ANDROID_HOME/ndk"*
do
  if [ -d "$dir" ]; then
    FOUND=$(find "$dir" -path "*prebuilt/*" -name "*addr2line" -type f | head -1)
    if [ ! -z "$FOUND" ]; then
      ADDR2LINE="$FOUND"
      break
    fi
  fi
done

# If not found, look in common path locations
if [ -z "$ADDR2LINE" ]; then
  for cmd in \
    "aarch64-linux-android-addr2line" \
    "arm-linux-androideabi-addr2line" \
    "addr2line"
  do
    if command -v "$cmd" >/dev/null 2>&1; then
      ADDR2LINE=$(command -v "$cmd")
      break
    fi
  done
fi

if [ -z "$ADDR2LINE" ]; then
  echo "Could not find addr2line tool."
  echo "Please install the Android NDK or specify the path to addr2line manually."
  echo ""
  echo "For manual symbolization, use the following command with your addr2line tool:"
  echo "addr2line -e \"$SYMBOLS_FILE\" -f -C $OFFSET1 $OFFSET2"
  exit 1
fi

echo "Found addr2line tool: $ADDR2LINE"
echo ""
echo "Symbolizing offsets..."
echo "----------------------"

echo "For offset $OFFSET1:"
"$ADDR2LINE" -e "$SYMBOLS_FILE" -f -C "$OFFSET1" || echo "Symbolization failed for $OFFSET1"
echo ""

echo "For offset $OFFSET2:"
"$ADDR2LINE" -e "$SYMBOLS_FILE" -f -C "$OFFSET2" || echo "Symbolization failed for $OFFSET2"
echo ""

echo "Manual Symbolization Complete"
echo "----------------------------"
echo "If addr2line couldn't properly symbolize the addresses, you might need to:"
echo "1. Verify that your debug symbols match the exact build of your app"
echo "2. Try other symbolization tools like llvm-symbolizer"
echo "3. Check if your debug symbols contain the appropriate DWARF information"

# Dump some info about the symbols file for debugging
echo ""
echo "Symbols File Information:"
file "$SYMBOLS_FILE" || echo "Could not get file information"

# Try to extract build ID from the symbols file
echo ""
echo "Extracting build ID from symbols file..."
strings "$SYMBOLS_FILE" | grep -i "build id" || echo "No build ID found in symbols file"
