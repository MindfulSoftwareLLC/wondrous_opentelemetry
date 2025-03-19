#!/bin/bash
# Script to try direct symbolization using addr2line
set -e

echo "Attempting direct symbolization using addr2line..."

# Find the Android NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
  # Try to find it in the standard location
  if [ -d "$HOME/Library/Android/sdk/ndk-bundle" ]; then
    ANDROID_NDK_HOME="$HOME/Library/Android/sdk/ndk-bundle"
  elif [ -d "$HOME/Library/Android/sdk/ndk" ]; then
    # Take the latest version
    ANDROID_NDK_HOME=$(find "$HOME/Library/Android/sdk/ndk" -maxdepth 1 -type d | sort -r | head -1)
  else
    echo "Error: ANDROID_NDK_HOME is not set, and NDK not found in standard locations."
    echo "Please set ANDROID_NDK_HOME to the location of your Android NDK."
    exit 1
  fi
fi

echo "Using Android NDK at: $ANDROID_NDK_HOME"

# Find the most recent debug symbols directory
LATEST_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* 2>/dev/null | head -1)
if [ -z "$LATEST_SYMBOLS_DIR" ]; then
  echo "Error: No debug symbols directory found!"
  exit 1
fi

echo "Using debug symbols from: $LATEST_SYMBOLS_DIR"

# Check if arm64 symbols exist
if [ ! -f "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" ]; then
  echo "Error: ARM64 symbols not found!"
  exit 1
fi

# Extract addresses from stack trace
echo "Extracting addresses from stack trace..."
ADDRESSES=$(grep "^#[0-9]* abs" ./tools/enhanced-stack-trace.txt | awk '{print $3}')

# Process each address
echo "Processing addresses with addr2line..."
echo "Results:"
echo "--------"

for ADDR in $ADDRESSES; do
  # Convert address to a format addr2line understands
  # Remove the `00000` prefix and trailing zeroes
  CLEAN_ADDR=$(echo $ADDR | sed 's/^0*//g')
  
  echo "Address: $ADDR"
  
  # Try to symbolize using addr2line
  "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android-addr2line" \
    -e "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" \
    -f -C $CLEAN_ADDR
  
  echo "--------"
done

echo "Direct symbolization attempt complete."
echo "If this didn't work, try using ndk-stack:"
echo "$ANDROID_NDK_HOME/ndk-stack -sym $LATEST_SYMBOLS_DIR/android -dump ./tools/enhanced-stack-trace.txt"
