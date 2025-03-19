#!/bin/bash
# Improved Flutter symbolization script with error handling and diagnostics
set -e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Flutter Stack Trace Symbolization Tool${NC}"
echo "-------------------------------------------"

# Find the most recent debug symbols directory
LATEST_SYMBOLS_DIR=$(ls -td ./debug-symbols/wonderous_opentelemetry__* 2>/dev/null | head -1)
if [ -z "$LATEST_SYMBOLS_DIR" ]; then
  echo -e "${RED}Error: No debug symbols directory found!${NC}"
  echo "Please ensure you've built the app with debug symbols first."
  exit 1
fi

echo -e "${GREEN}Using debug symbols from:${NC} $LATEST_SYMBOLS_DIR"

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

# Extract build ID from stack trace
BUILD_ID=$(grep "build_id" "$STACK_TRACE_PATH" | sed -e "s/.*build_id: '\([^']*\)'.*/\1/")
if [ -z "$BUILD_ID" ]; then
  echo -e "${YELLOW}Warning: Could not find build_id in stack trace.${NC}"
  echo "This might cause symbolization to fail if the build ID doesn't match."
else
  echo -e "${GREEN}Found build ID:${NC} $BUILD_ID"
fi

# Try using direct path to symbols
echo -e "\n${BLUE}Attempting symbolization using direct path to symbols...${NC}"
flutter symbolize \
  --debug-info="$LATEST_SYMBOLS_DIR/android" \
  --input="$STACK_TRACE_PATH" \
  --verbose

# If that fails, try with the ZIP file
if [ $? -ne 0 ]; then
  echo -e "\n${YELLOW}Direct path symbolization failed. Trying with ZIP file...${NC}"
  
  # Find the latest ZIP file
  LATEST_ZIP=$(ls -t ./debug-symbols/*.zip 2>/dev/null | head -1)
  
  if [ -z "$LATEST_ZIP" ]; then
    echo -e "${RED}Error: No debug symbols ZIP file found!${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Using ZIP file:${NC} $LATEST_ZIP"
  
  flutter symbolize \
    --debug-info="$LATEST_ZIP" \
    --input="$STACK_TRACE_PATH" \
    --verbose
fi

echo -e "\n${BLUE}Symbolization process complete.${NC}"
echo -e "If symbolization failed, please check README-symbolization.md for troubleshooting steps."
