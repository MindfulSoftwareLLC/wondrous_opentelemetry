#!/bin/bash
set -e

# Define app name and version
APP_NAME="wonderous_opentelemetry"
VERSION=$(grep 'version:' ../pubspec.yaml | sed 's/version: //' | tr -d ' ')
BUILD_DATE=$(date +"%Y%m%d_%H%M%S")

# Create output directories if they don't exist
SYMBOLS_DIR="debug-symbols/${APP_NAME}_${VERSION}_${BUILD_DATE}"
mkdir -p "$SYMBOLS_DIR"
mkdir -p "$SYMBOLS_DIR/android"

echo "Building Android release with debug symbols..."
echo "App version: $VERSION"
echo "Symbols will be saved to: $SYMBOLS_DIR"

# Build Android app with debug symbols
flutter build apk --release --split-debug-info="$SYMBOLS_DIR/android"

# Copy APK to the symbols directory for reference
cp build/app/outputs/flutter-apk/app-release.apk "$SYMBOLS_DIR/android/$APP_NAME-$VERSION.apk"

# Create a metadata file with build information
cat > "$SYMBOLS_DIR/metadata.json" << EOF
{
  "appName": "$APP_NAME",
  "version": "$VERSION",
  "buildDate": "$BUILD_DATE",
  "platform": "android"
}
EOF

# Create a zip file containing the debug symbols
ZIP_NAME="${APP_NAME}_android_symbols_${VERSION}.zip"
(cd debug-symbols && zip -r "$ZIP_NAME" "${APP_NAME}_${VERSION}_${BUILD_DATE}")

echo "Debug symbols have been generated and saved to:"
echo "- Directory: $SYMBOLS_DIR"
echo "- Zip file: debug-symbols/$ZIP_NAME"
echo ""
echo "You can now upload these symbols using the Dartastic CLI or web UI."
