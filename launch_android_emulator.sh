#!/bin/bash

# Build and launch Android APK on emulator

set -e

echo "🤖 Building and launching Android APK on emulator..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Check if Android emulator is running
echo "📱 Checking for running Android emulator..."
adb devices | grep -q "emulator" || {
    echo "❌ No Android emulator detected. Please start an emulator first."
    echo ""
    echo "To start an emulator:"
    echo "1. Open Android Studio"
    echo "2. Go to Tools > AVD Manager"
    echo "3. Start an existing emulator or create a new one"
    echo "4. Or use command line: flutter emulators --launch <emulator_id>"
    exit 1
}

# Build APK
echo "📦 Building Android APK..."
flutter build apk --debug

# Check if build was successful
if [ ! -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "❌ Android APK build failed"
    exit 1
fi

# Install and launch on emulator
echo "📲 Installing APK on emulator..."
flutter install --debug

echo "✅ Android APK build and launch complete!"
echo ""
echo "📝 Configuration:"
echo "   Platform: Android Emulator"
echo "   OpenTelemetry Endpoint: http://10.0.2.2:4317 (gRPC)"
echo "   Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo ""
echo "📱 App should now be launching on your Android emulator"
echo "   Package: com.gskinner.flutter.wonders"
echo ""
echo "🔍 To view telemetry data:"
echo "   1. Open Grafana at http://localhost:3000"
echo "   2. Login with admin/admin"
echo "   3. Explore traces, metrics, and logs"
