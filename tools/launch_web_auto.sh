#!/bin/bash

# Wondrous OpenTelemetry Web Launch Script - Auto-detecting Flutter capabilities
# This script detects Flutter version and uses appropriate compilation options

set -e

echo "🚀 Starting Wondrous OpenTelemetry Web App..."

# Check Flutter version and capabilities
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "📱 Detected: $FLUTTER_VERSION"

# Check if Docker is running and OTel collector is available
echo "📡 Checking OpenTelemetry Collector availability..."

if curl -s --connect-timeout 3 http://localhost:4318/v1/metrics > /dev/null 2>&1; then
    echo "✅ OTel HTTP endpoint (4318) is accessible"
else
    echo "❌ OTel HTTP endpoint (4318) is NOT accessible"
    echo "🐳 Make sure Docker is running with: docker run -p 3000:3000 -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm"
    exit 1
fi

# Set environment variables
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
export WEATHER_API_KEY="3f4d6e7bf868e5d14487ff4c06466e36"

echo "🔧 Environment Configuration:"
echo "   OTEL_EXPORTER_OTLP_ENDPOINT: $OTEL_EXPORTER_OTLP_ENDPOINT"
echo "   OTEL_EXPORTER_OTLP_PROTOCOL: $OTEL_EXPORTER_OTLP_PROTOCOL"

# Clean and prepare
echo "🧹 Preparing project..."
flutter clean
flutter pub get

# Check if WASM is supported
echo "🌐 Launching Flutter Web app..."

# Try WASM first, fallback to JS if not supported
if flutter run --help | grep -q -- "--wasm"; then
    echo "🔥 Using WASM compilation for better performance"
    flutter run -d chrome \
        --web-port 8080 \
        --web-hostname localhost \
        --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318" \
        --dart-define=OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
        --dart-define=WEATHER_API_KEY="3f4d6e7bf868e5d14487ff4c06466e36" \
        --wasm \
        lib/main.dart
else
    echo "📜 Using JavaScript compilation (WASM not available)"
    flutter run -d chrome \
        --web-port 8080 \
        --web-hostname localhost \
        --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318" \
        --dart-define=OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
        --dart-define=WEATHER_API_KEY="3f4d6e7bf868e5d14487ff4c06466e36" \
        lib/main.dart
fi

echo "🎉 Web app should now be running on http://localhost:8080"
echo "📊 Grafana dashboard available at http://localhost:3000 (admin/admin)"
