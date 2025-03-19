#!/bin/bash
# This script creates a special structure for Flutter engine symbols
set -e

# Find the most recent debug symbols directory
LATEST_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* 2>/dev/null | head -1)
if [ -z "$LATEST_SYMBOLS_DIR" ]; then
  echo "Error: No debug symbols directory found!"
  exit 1
fi

echo "Using debug symbols from: $LATEST_SYMBOLS_DIR"

# Create a temporary directory for the engine symbols structure
TEMP_DIR=$(mktemp -d)
echo "Creating temporary directory: $TEMP_DIR"

# Create the special structure for Flutter engine symbols
mkdir -p "$TEMP_DIR/android-arm64/io.flutter"
mkdir -p "$TEMP_DIR/android-arm64/io.flutter.vm_snapshot_data"
mkdir -p "$TEMP_DIR/android-arm64/io.flutter.isolate_snapshot_data"

# Copy symbols to the appropriate locations
if [ -f "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" ]; then
  echo "Copying ARM64 symbols..."
  cp "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" "$TEMP_DIR/android-arm64/libapp.so"
  cp "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" "$TEMP_DIR/android-arm64/io.flutter/libflutter.so"
  cp "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" "$TEMP_DIR/android-arm64/io.flutter.vm_snapshot_data/libapp.so"
  cp "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" "$TEMP_DIR/android-arm64/io.flutter.isolate_snapshot_data/libapp.so"
else
  echo "Error: ARM64 symbols not found!"
  exit 1
fi

# Create a zip file with this structure
ZIP_FILE="$(pwd)/debug-symbols/engine_symbols.zip"
echo "Creating zip file: $ZIP_FILE"

(cd "$TEMP_DIR" && zip -r "$ZIP_FILE" .)

echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

# Create a special stack trace file for engine symbols
STACK_FILE="./tools/engine-stack-trace.txt"
cat > "$STACK_FILE" << EOF
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

echo "Created stack trace file: $STACK_FILE"
echo "Now try symbolization with:"
echo "flutter symbolize --debug-info=\"$ZIP_FILE\" --input=\"$STACK_FILE\" --verbose"

# Create a script to run this symbolization
SCRIPT_FILE="./tools/symbolize-with-engine.sh"
cat > "$SCRIPT_FILE" << EOF
#!/bin/bash
flutter symbolize --debug-info="$ZIP_FILE" --input="$STACK_FILE" --verbose
EOF

chmod +x "$SCRIPT_FILE"
echo "Created script: $SCRIPT_FILE"
echo "Run it with: $SCRIPT_FILE"
