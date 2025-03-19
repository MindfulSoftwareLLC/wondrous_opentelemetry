#!/bin/bash
# Script to help format OTel stack traces for Flutter symbolization
set -e

INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ]; then
  echo "Error: No input file specified."
  echo "Usage: $0 <path-to-otel-stack-trace>"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file '$INPUT_FILE' not found."
  exit 1
fi

OUTPUT_FILE="./tools/formatted-stack-trace.txt"

echo "Formatting OTel stack trace for Flutter symbolization..."
echo "Input file: $INPUT_FILE"
echo "Output file: $OUTPUT_FILE"

# Extract information and format it for Flutter symbolizer
# This is a basic implementation - you might need to adapt it based on your actual OTel format
cat "$INPUT_FILE" | grep -E 'pid:|tid:|build_id:|#[0-9]+ abs ' > "$OUTPUT_FILE"

# Add missing headers if needed
if ! grep -q "os: android" "$OUTPUT_FILE"; then
  sed -i.bak '1s/^/os: android\n/' "$OUTPUT_FILE"
fi

if ! grep -q "arch: arm64" "$OUTPUT_FILE"; then
  sed -i.bak '1s/^/arch: arm64\n/' "$OUTPUT_FILE"
fi

# Add the *** header if missing
if ! grep -q "\\*\\*\\* \\*\\*\\* \\*\\*\\*" "$OUTPUT_FILE"; then
  sed -i.bak '1s/^/*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***\n/' "$OUTPUT_FILE"
fi

# Remove backup file
rm -f "$OUTPUT_FILE.bak"

echo "Formatting complete. Attempting symbolization with formatted stack trace..."

# Run the symbolization
flutter symbolize \
  --debug-info="./debug-symbols/wonderous_opentelemetry_android_symbols_.zip" \
  --input="$OUTPUT_FILE" \
  --verbose

echo "Process complete."
