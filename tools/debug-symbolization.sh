#!/bin/bash
set -e

echo "Debugging symbolization issues..."

# 1. Check the most recent debug symbols directory
DEBUG_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* | head -1)
echo "Most recent debug symbols directory: $DEBUG_SYMBOLS_DIR"

# 2. Check the contents of the directory
echo "Contents of the debug symbols directory:"
ls -la "$DEBUG_SYMBOLS_DIR/android"

# 3. Check the stack trace file
echo "Stack trace file contents:"
cat ./tools/release-android-stack-trace.txt

# 4. Try symbolization with direct path to symbol files instead of zip
echo "Attempting symbolization with direct path to symbol files..."
flutter symbolize \
  --debug-info="$DEBUG_SYMBOLS_DIR/android" \
  --input=./tools/release-android-stack-trace.txt \
  --verbose

# 5. Create a more complete version of the stack trace for testing
echo "Creating a more detailed test stack trace..."
cat > ./tools/test-stack-trace.txt << EOF
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 16380, tid: 487890366624, name 1.ui
os: android
arch: arm64 
comp: yes
sim: no
build_id: 'cde83d06f254073eccbd75adde5be1b9'
isolate_dso_base: 6e1906a000, vm_dso_base: 6e1906a000
isolate_instructions: 6e192b0a40, vm_instructions: 6e1929a000
#00 abs 0000006e1974e903 virt 00000000006e4903 _kDartIsolateSnapshotInstructions+0x49dec3 <asynchronous suspension>
#01 abs 0000006e1974dfbb virt 00000000006e3fbb _kDartIsolateSnapshotInstructions+0x49d57b <asynchronous suspension>
EOF

echo "Attempting symbolization with the more detailed test stack trace..."
flutter symbolize \
  --debug-info="$DEBUG_SYMBOLS_DIR/android" \
  --input=./tools/test-stack-trace.txt \
  --verbose

echo "Debug information complete."
