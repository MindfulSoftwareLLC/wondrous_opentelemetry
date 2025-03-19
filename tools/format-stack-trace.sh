#!/bin/bash
# Script to properly format a Flutter stack trace
set -e

INPUT_FILE="./tools/release-android-stack-trace.txt"
OUTPUT_FILE="./tools/formatted-stack-trace.txt"

echo "Formatting stack trace from $INPUT_FILE to $OUTPUT_FILE"

# Read the content of the file
CONTENT=$(cat "$INPUT_FILE")

# Format the content with proper line breaks
# This uses sed to insert newlines at appropriate points
echo "*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***" > "$OUTPUT_FILE"
echo "$CONTENT" | 
  sed 's/pid: /\npid: /g' | 
  sed 's/os: /\nos: /g' | 
  sed 's/arch: /\narch: /g' | 
  sed 's/comp: /\ncomp: /g' | 
  sed 's/sim: /\nsim: /g' | 
  sed 's/build_id: /\nbuild_id: /g' | 
  sed 's/isolate_dso_base: /\nisolate_dso_base: /g' | 
  sed 's/vm_dso_base: /\nvm_dso_base: /g' | 
  sed 's/isolate_instructions: /\nisolate_instructions: /g' | 
  sed 's/vm_instructions: /\nvm_instructions: /g' | 
  sed 's/#00 /\n#00 /g' | 
  sed 's/#01 /\n#01 /g' | 
  sed 's/#02 /\n#02 /g' | 
  sed 's/#03 /\n#03 /g' | 
  sed 's/#04 /\n#04 /g' | 
  sed 's/#05 /\n#05 /g' | 
  sed 's/#06 /\n#06 /g' | 
  sed 's/#07 /\n#07 /g' | 
  sed 's/#08 /\n#08 /g' | 
  sed 's/#09 /\n#09 /g' >> "$OUTPUT_FILE"

# Clean up any duplicated newlines
sed -i '' '/^$/d' "$OUTPUT_FILE"

echo "Formatted stack trace:"
cat "$OUTPUT_FILE"

echo ""
echo "Now try symbolization with:"
echo "flutter symbolize --debug-info=/Users/mbushe/dev/mf/otel/wonderous_opentelemetry/debug-symbols/wonderous_opentelemetry_android_symbols_proper.zip --input=$OUTPUT_FILE --verbose"

# Create a script to run this symbolization
SCRIPT_FILE="./tools/symbolize-formatted-trace.sh"
cat > "$SCRIPT_FILE" << EOF
#!/bin/bash
flutter symbolize \\
  --debug-info=/Users/mbushe/dev/mf/otel/wonderous_opentelemetry/debug-symbols/wonderous_opentelemetry_android_symbols_proper.zip \\
  --input=$OUTPUT_FILE \\
  --verbose
EOF

chmod +x "$SCRIPT_FILE"
echo "Created script: $SCRIPT_FILE"
echo "Run it with: $SCRIPT_FILE"
