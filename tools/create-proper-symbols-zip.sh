#!/bin/bash
# Script to create a properly formatted symbols ZIP for Flutter
set -e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Creating properly formatted symbols ZIP for Flutter${NC}"
echo "-------------------------------------------------------"

# Find the most recent debug symbols directory
LATEST_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* 2>/dev/null | head -1)
if [ -z "$LATEST_SYMBOLS_DIR" ]; then
  echo -e "${RED}Error: No debug symbols directory found!${NC}"
  exit 1
fi

echo -e "${GREEN}Using debug symbols from:${NC} $LATEST_SYMBOLS_DIR"

# Create a temporary directory with the proper structure
TEMP_DIR=$(mktemp -d)
echo -e "${GREEN}Creating temporary directory:${NC} $TEMP_DIR"

# Create the expected structure for Flutter symbolizer
mkdir -p "$TEMP_DIR/android-arm"
mkdir -p "$TEMP_DIR/android-arm64"
mkdir -p "$TEMP_DIR/android-x64"

# Check if the source files exist
if [ -f "$LATEST_SYMBOLS_DIR/android/app.android-arm.symbols" ]; then
  echo "Copying ARM symbols..."
  cp "$LATEST_SYMBOLS_DIR/android/app.android-arm.symbols" "$TEMP_DIR/android-arm/app.so"
else
  echo -e "${YELLOW}Warning: ARM symbols not found${NC}"
fi

if [ -f "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" ]; then
  echo "Copying ARM64 symbols..."
  cp "$LATEST_SYMBOLS_DIR/android/app.android-arm64.symbols" "$TEMP_DIR/android-arm64/app.so"
else
  echo -e "${YELLOW}Warning: ARM64 symbols not found${NC}"
fi

if [ -f "$LATEST_SYMBOLS_DIR/android/app.android-x64.symbols" ]; then
  echo "Copying x64 symbols..."
  cp "$LATEST_SYMBOLS_DIR/android/app.android-x64.symbols" "$TEMP_DIR/android-x64/app.so"
else
  echo -e "${YELLOW}Warning: x64 symbols not found${NC}"
fi

# Copy the APK for completeness
if [ -f "$LATEST_SYMBOLS_DIR/android/wonderous_opentelemetry-.apk" ]; then
  echo "Copying APK..."
  cp "$LATEST_SYMBOLS_DIR/android/wonderous_opentelemetry-.apk" "$TEMP_DIR/"
fi

# Create a proper symbols ZIP file
NEW_ZIP="wonderous_opentelemetry_android_symbols_proper.zip"
FULL_PATH="$(pwd)/debug-symbols/$NEW_ZIP"
echo -e "${GREEN}Creating new symbols ZIP:${NC} $FULL_PATH"

# Navigate to temp dir and zip contents
(cd "$TEMP_DIR" && zip -r "$FULL_PATH" .)

# Clean up
echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}New symbols ZIP created successfully: $FULL_PATH${NC}"
echo "Now try symbolization with this new ZIP:"
echo -e "${YELLOW}flutter symbolize --debug-info=$FULL_PATH --input=./tools/enhanced-stack-trace.txt${NC}"

# Create a symbolization script for the new ZIP
NEW_SCRIPT="./tools/symbolize-with-proper-zip.sh"
cat > "$NEW_SCRIPT" << EOF
#!/bin/bash
flutter symbolize \\
  --debug-info=$FULL_PATH \\
  --input=./tools/enhanced-stack-trace.txt \\
  --verbose
EOF

chmod +x "$NEW_SCRIPT"
echo -e "\nCreated script: $NEW_SCRIPT"
echo "Run it with: ./tools/symbolize-with-proper-zip.sh"
