#!/bin/bash
# Script to run the Flutter web app with explicit configuration for the remote backend

# Set web port
WEB_PORT=54381

echo "=== Running Flutter Web with Remote OTel Backend ==="
echo "Web server port: $WEB_PORT"
echo "OTel backend: http://88.99.244.251:4318"
echo ""

# Run the app with specific configuration
flutter run -d chrome --web-port=$WEB_PORT \
  --dart-define=OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
