#!/bin/bash

echo "🔍 OpenTelemetry Endpoint Diagnostic Script"
echo "==========================================="

# Test OTel HTTP endpoint (for web)
echo "Testing HTTP endpoint (port 4318)..."
if curl -s --connect-timeout 3 -X POST \
    -H "Content-Type: application/json" \
    -d '{"test": "connectivity"}' \
    http://localhost:4318/v1/metrics > /dev/null 2>&1; then
    echo "✅ HTTP endpoint (4318) is reachable"
else
    echo "❌ HTTP endpoint (4318) is NOT reachable"
fi

# Test OTel gRPC endpoint (for native)
echo "Testing gRPC endpoint (port 4317)..."
if nc -z localhost 4317 2>/dev/null; then
    echo "✅ gRPC endpoint (4317) is listening"
else
    echo "❌ gRPC endpoint (4317) is NOT listening"
fi

# Test Grafana dashboard
echo "Testing Grafana dashboard (port 3000)..."
if curl -s --connect-timeout 3 http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Grafana dashboard (3000) is accessible"
else
    echo "❌ Grafana dashboard (3000) is NOT accessible"
fi

echo ""
echo "📊 Expected services for OTel stack:"
echo "   - Port 4317: OpenTelemetry gRPC endpoint (for mobile/desktop)"
echo "   - Port 4318: OpenTelemetry HTTP endpoint (for web)"
echo "   - Port 3000: Grafana dashboard (admin/admin)"

echo ""
echo "🐳 To start the OTel stack, run:"
echo "   docker run -p 3000:3000 -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm"

echo ""
echo "🌐 To test the web app:"
echo "   1. Run: chmod +x launch_web_fixed.sh"
echo "   2. Run: ./launch_web_fixed.sh"
