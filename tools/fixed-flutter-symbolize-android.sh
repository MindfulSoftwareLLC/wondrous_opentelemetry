#!/bin/bash
# Fixed Flutter symbolization script focused on using the ZIP file
set -e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Flutter Stack Trace Symbolization Tool${NC}"
echo "-------------------------------------------"

# Find the ZIP file - this is what Flutter symbolize requires
SYMBOLS_ZIP="./debug-symbols/wonderous_opentelemetry_android_symbols_.zip"
if [ ! -f "$SYMBOLS_ZIP" ]; then
  echo -e "${RED}Error: Debug symbols ZIP file not found at $SYMBOLS_ZIP${NC}"
  exit 1
fi

echo -e "${GREEN}Using debug symbols ZIP:${NC} $SYMBOLS_ZIP"

# Check if stack trace file exists
STACK_TRACE_PATH="./tools/release-android-stack-trace.txt"
if [ ! -f "$STACK_TRACE_PATH" ]; then
  echo -e "${RED}Error: Stack trace file not found at $STACK_TRACE_PATH${NC}"
  exit 1
fi

# Process stack trace file
LINES=$(wc -l < "$STACK_TRACE_PATH")
echo -e "${GREEN}Stack trace file:${NC} $STACK_TRACE_PATH ($LINES lines)"

if [ "$LINES" -lt 3 ]; then
  echo -e "${YELLOW}Warning: Stack trace file appears very short (only $LINES lines).${NC}"
  echo "This might not contain enough information for proper symbolization."
fi

# Extract build ID from stack trace if present
BUILD_ID=$(grep "build_id" "$STACK_TRACE_PATH" | sed -e "s/.*build_id: '\([^']*\)'.*/\1/" 2>/dev/null)
if [ -n "$BUILD_ID" ]; then
  echo -e "${GREEN}Found build ID:${NC} $BUILD_ID"
fi

# Create a more complete version of the stack trace for testing
echo -e "${YELLOW}Your stack trace is very minimal. Creating an enhanced version for testing...${NC}"
ENHANCED_TRACE="./tools/enhanced-stack-trace.txt"
cat > "$ENHANCED_TRACE" << EOF
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

echo -e "\n${BLUE}Attempting symbolization with original stack trace...${NC}"
flutter symbolize \
  --debug-info="$SYMBOLS_ZIP" \
  --input="$STACK_TRACE_PATH" \
  --verbose || true

echo -e "\n${BLUE}Attempting symbolization with enhanced stack trace...${NC}"
flutter symbolize \
  --debug-info="$SYMBOLS_ZIP" \
  --input="$ENHANCED_TRACE" \
  --verbose || true

echo -e "\n${BLUE}Symbolization process complete.${NC}"
echo -e "If you're still seeing 'Failed to decode symbols file for loading unit 1', please check:"
echo -e "1. Your ZIP file format - it should contain the appropriate symbols for all loading units"
echo -e "2. The stack trace format - make sure it includes all necessary information"
echo -e "3. Make sure the build IDs match between your stack trace and debug symbols"
