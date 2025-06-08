#!/bin/bash

# Wondrous OpenTelemetry Web Launch Script - Updated for Modern Flutter
# This script properly configures and launches the Flutter web app with OTel support

set -e

echo "🚀 Starting Wondrous OpenTelemetry Web App (with WASM support)..."

# Check if Docker is running and OTel collector is available
echo "📡 Checking OpenTelemetry Collector availability..."

# Test if OTel HTTP endpoint is accessible
if curl -s --connect-timeout 3 http://localhost:4318/v1/metrics > /dev/null 2>&1; then
    echo "✅ OTel HTTP endpoint (4318) is accessible"
else
    echo "❌ OTel HTTP endpoint (4318) is NOT accessible"
    echo "🐳 Make sure Docker is running with: docker run -p 3000:3000 -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm"
    exit 1
fi

# Test if OTel gRPC endpoint is accessible (for comparison)
if curl -s --connect-timeout 3 http://localhost:4317 > /dev/null 2>&1; then
    echo "✅ OTel gRPC endpoint (4317) is accessible"
else
    echo "⚠️  OTel gRPC endpoint (4317) is not accessible (normal for web)"
fi

# Set environment variables for OTel
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
export WEATHER_API_KEY="3f4d6e7bf868e5d14487ff4c06466e36"

echo "🔧 Environment Configuration:"
echo "   OTEL_EXPORTER_OTLP_ENDPOINT: $OTEL_EXPORTER_OTLP_ENDPOINT"
echo "   OTEL_EXPORTER_OTLP_PROTOCOL: $OTEL_EXPORTER_OTLP_PROTOCOL"
echo "   WEATHER_API_KEY: [SET]"

# Clean previous build artifacts that might cause issues
echo "🧹 Cleaning previous build artifacts..."
flutter clean
flutter pub get

echo "🌐 Launching Flutter Web app with modern configuration..."

# Modern Flutter web launch with WASM support
flutter run -d chrome \
    --web-port 8080 \
    --web-hostname localhost \
    --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318" \
    --dart-define=OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
    --dart-define=WEATHER_API_KEY="3f4d6e7bf868e5d14487ff4c06466e36" \
    --wasm \
    lib/main.dart

echo "🎉 Web app should now be running on http://localhost:8080"
echo "📊 Grafana dashboard available at http://localhost:3000 (admin/admin)"
echo "🔍 WASM compilation enabled for better performance"
