#!/bin/bash

# Wondrous OpenTelemetry Web Launch Script - Standard JS compilation
# This script uses standard JavaScript compilation for maximum compatibility

set -e

echo "🚀 Starting Wondrous OpenTelemetry Web App (JavaScript compilation)..."

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

# Set environment variables for OTel
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
export WEATHER_API_KEY="3f4d6e7bf868e5d14487ff4c06466e36"

echo "🔧 Environment Configuration:"
echo "   OTEL_EXPORTER_OTLP_ENDPOINT: $OTEL_EXPORTER_OTLP_ENDPOINT"
echo "   OTEL_EXPORTER_OTLP_PROTOCOL: $OTEL_EXPORTER_OTLP_PROTOCOL"
echo "   WEATHER_API_KEY: [SET]"

# Clean previous build artifacts
echo "🧹 Cleaning previous build artifacts..."
flutter clean
flutter pub get

echo "🌐 Launching Flutter Web app (JavaScript compilation)..."

# Standard Flutter web launch
flutter run -d chrome \
    --web-port 8080 \
    --web-hostname localhost \
    --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318" \
    --dart-define=OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
    --dart-define=WEATHER_API_KEY="3f4d6e7bf868e5d14487ff4c06466e36" \
    lib/main.dart

echo "🎉 Web app should now be running on http://localhost:8080"
echo "📊 Grafana dashboard available at http://localhost:3000 (admin/admin)"
