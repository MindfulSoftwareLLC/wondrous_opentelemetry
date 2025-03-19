#!/bin/bash
# Use Android NDK tools directly to symbolize the stack trace
set -e

# Find the Android NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
  echo "ANDROID_NDK_HOME environment variable not set."
  echo "Please set it to the path of your Android NDK installation."
  echo "Example: export ANDROID_NDK_HOME=/Users/username/Library/Android/sdk/ndk/25.1.8937393"
  
  # Try to find it in common locations
  POSSIBLE_NDK=$(find $HOME/Library/Android/sdk -name "ndk-stack" -type f | head -1)
  if [ ! -z "$POSSIBLE_NDK" ]; then
    ANDROID_NDK_HOME=$(dirname $(dirname $POSSIBLE_NDK))
    echo "Found possible NDK at: $ANDROID_NDK_HOME"
  else
    exit 1
  fi
fi

# Find the most recent debug symbols directory
LATEST_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* 2>/dev/null | head -1)
if [ -z "$LATEST_SYMBOLS_DIR" ]; then
  echo "Error: No debug symbols directory found!"
  exit 1
fi

echo "Using debug symbols from: $LATEST_SYMBOLS_DIR"

# Create a more detailed stack trace for demo purposes
STACK_TRACE_FILE="./tools/ndk-stack-trace.txt"
cat > "$STACK_TRACE_FILE" << EOF
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 16380, tid: 487890366624, name 1.ui
os: android
arch: arm64 
comp: yes
sim: no
build_id: 'cde83d06f254073eccbd75adde5be1b9'
isolate_dso_base: 6e1906a000, vm_dso_base: 6e1906a000
isolate_instructions: 6e192b0a40, vm_instructions: 6e1929a000
#00 pc 000000000049dec3  libapp.so
#01 pc 000000000049d57b  libapp.so
EOF

echo "Created stack trace file: $STACK_TRACE_FILE"

# Check if we have ARM64 symbols
if [ ! -f "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" ]; then
  echo "Error: ARM64 symbols not found!"
  exit 1
fi

# Try to use ndk-stack to symbolize
if [ -x "$ANDROID_NDK_HOME/ndk-stack" ]; then
  echo "Using ndk-stack to symbolize..."
  $ANDROID_NDK_HOME/ndk-stack -sym "$LATEST_SYMBOLS_DIR/android" -dump "$STACK_TRACE_FILE"
else
  echo "ndk-stack not found. Trying with addr2line instead..."
  
  # Find addr2line tool
  ADDR2LINE=$(find $ANDROID_NDK_HOME -name "aarch64-linux-android-addr2line" -type f | head -1)
  
  if [ -z "$ADDR2LINE" ]; then
    echo "addr2line tool not found. Trying to find a similar tool..."
    ADDR2LINE=$(find $ANDROID_NDK_HOME -name "*-addr2line" -type f | head -1)
  fi
  
  if [ -z "$ADDR2LINE" ]; then
    echo "No addr2line tool found. Cannot symbolize."
    exit 1
  fi
  
  echo "Using addr2line tool: $ADDR2LINE"
  
  # Extract offsets from the stack trace
  OFFSETS=$(grep "^#[0-9]* pc" "$STACK_TRACE_FILE" | awk '{print $3}')
  
  echo "Symbolizing addresses..."
  for OFFSET in $OFFSETS; do
    echo "Offset: $OFFSET"
    $ADDR2LINE -e "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" -f -C $OFFSET
    echo "-----------------"
  done
fi

echo ""
echo "If the above didn't produce useful results, here are some alternatives:"

# Try to find llvm-symbolizer as an alternative
LLVM_SYMBOLIZER=$(find $ANDROID_NDK_HOME -name "llvm-symbolizer" -type f | head -1)
if [ ! -z "$LLVM_SYMBOLIZER" ]; then
  echo "You can also try using LLVM symbolizer:"
  echo "$LLVM_SYMBOLIZER -e \"$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols\" $OFFSETS"
fi

echo ""
echo "If you want to try symbolizing manually, you can use the following command:"
echo "aarch64-linux-android-addr2line -e \"$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols\" -f -C <address>"
echo ""
echo "Example addresses based on your stack trace:"
echo "0x49dec3"
echo "0x49d57b"
