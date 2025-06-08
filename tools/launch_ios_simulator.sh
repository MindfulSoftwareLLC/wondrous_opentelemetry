#!/bin/bash

# Build and launch iOS app on Simulator

set -e

echo "🍎 Building and launching iOS app on Simulator..."

# First, run the bundle ID fix
echo "🔧 Fixing iOS bundle identifiers..."
if [ -f "./fix_ios_bundle_id.sh" ]; then
    chmod +x ./fix_ios_bundle_id.sh
    ./fix_ios_bundle_id.sh
else
    echo "⚠️  Bundle ID fix script not found, continuing..."
fi

# Check if iOS Simulator is available
if ! command -v xcrun &> /dev/null || ! xcrun simctl list devices | grep -q "iPhone"; then
    echo "❌ iOS Simulator not available. Please install Xcode and iOS Simulator."
    exit 1
fi

# List available simulators
echo "📱 Available iOS Simulators:"
xcrun simctl list devices | grep "iPhone"

# Try to find a booted simulator or boot one
BOOTED_SIMULATOR=$(xcrun simctl list devices | grep "Booted" | head -n 1 | sed 's/.*(\([^)]*\)).*/\1/' || true)

if [ -z "$BOOTED_SIMULATOR" ]; then
    echo "🚀 No simulator running, starting iPhone 16 Pro..."
    # Try to boot iPhone 16 Pro or fallback to first available iPhone
    SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | head -n 1 | sed 's/.*(\([^)]*\)).*/\1/' || 
                   xcrun simctl list devices | grep "iPhone" | head -n 1 | sed 's/.*(\([^)]*\)).*/\1/')
    
    if [ -n "$SIMULATOR_ID" ]; then
        xcrun simctl boot "$SIMULATOR_ID"
        open -a Simulator
        sleep 5  # Wait for simulator to fully boot
    else
        echo "❌ No iPhone simulator found"
        exit 1
    fi
fi

# Build for iOS
echo "📦 Building iOS app..."
flutter build ios --simulator

# Check if build was successful
if [ ! -d "build/ios/iphonesimulator/Runner.app" ]; then
    echo "❌ iOS build failed"
    exit 1
fi

# Launch on simulator
echo "📲 Installing and launching on iOS Simulator..."
flutter install

echo "✅ iOS build and launch complete!"
echo ""
echo "📝 Configuration:"
echo "   Platform: iOS Simulator"
echo "   OpenTelemetry Endpoint: http://localhost:4317 (gRPC)"
echo "   Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo ""
echo "📱 App should now be launching on iOS Simulator"
echo "   Bundle ID: com.gskinner.flutter.wonders"
echo ""
echo "🔍 To view telemetry data:"
echo "   1. Open Grafana at http://localhost:3000"
echo "   2. Login with admin/admin"
echo "   3. Explore traces, metrics, and logs"
echo ""
echo "⚠️  If you encounter bundle ID issues:"
echo "   1. Open ios/Runner.xcworkspace in Xcode"
echo "   2. Check that bundle identifiers are correct:"
echo "      - Runner: com.gskinner.flutter.wonders"
echo "      - WonderousWidgetExtension: com.gskinner.flutter.wonders.WonderousWidgetExtension"
