#!/bin/bash

# Build and launch Android APK on physical device (Pixel 8 Pro)

set -e

echo "📱 Building and launching Android APK on physical device..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Check if physical device is connected
echo "🔌 Checking for connected Android device..."
DEVICE_COUNT=$(adb devices | grep -c "device$" || true)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ No Android device detected. Please connect your Pixel 8 Pro and enable USB debugging."
    echo ""
    echo "To enable USB debugging:"
    echo "1. Go to Settings > About phone"
    echo "2. Tap Build number 7 times to enable Developer options"
    echo "3. Go to Settings > System > Developer options"
    echo "4. Enable USB debugging"
    echo "5. Connect your device via USB"
    echo "6. Allow USB debugging when prompted"
    exit 1
fi

# Show connected devices
echo "📱 Connected devices:"
adb devices

# Get your local IP address for the device to connect to your development machine
LOCAL_IP=$(ifconfig | grep -A 1 'en0:' | grep 'inet ' | awk '{print $2}' | head -n 1)

if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "192.168.1.100")
fi

echo "🌐 Your development machine IP: $LOCAL_IP"
echo "📝 Note: Launch with --dart-define OTEL_EXPORTER_OTLP_ENDPOINT=$LOCAL_IP"

# Build APK for release (or debug)
echo "📦 Building Android APK..."
flutter build apk --debug

# Check if build was successful
if [ ! -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "❌ Android APK build failed"
    exit 1
fi

# Install and launch on device
echo "📲 Installing APK on device..."
flutter install --debug

echo "✅ Android APK build and launch complete!"
echo ""
echo "📝 Configuration:"
echo "   Platform: Android Physical Device"
echo "   OpenTelemetry Endpoint: http://$LOCAL_IP:4317 (gRPC)"
echo "   Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo ""
echo "📱 App should now be launching on your Pixel 8 Pro"
echo "   Package: com.gskinner.flutter.wonders"
echo ""
echo "⚠️  Important for physical device:"
echo "   1. Ensure your phone and computer are on the same WiFi network"
echo "   2. Update OTelConfig in lib/config/otel_config.dart if IP $LOCAL_IP is incorrect"
echo "   3. Your Grafana LGTM stack should be accessible at http://$LOCAL_IP:3000"
echo ""
echo "🔍 To view telemetry data:"
echo "   1. Open Grafana at http://localhost:3000 (on your development machine)"
echo "   2. Login with admin/admin"
echo "   3. Explore traces, metrics, and logs"
