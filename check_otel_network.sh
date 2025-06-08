#!/bin/bash

# Network Configuration Helper for OpenTelemetry

set -e

echo "🌐 OpenTelemetry Network Configuration Helper"
echo "=============================================="
echo ""

# Check if OTEL backend is running
echo "🔍 Checking OpenTelemetry backend status..."
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Grafana LGTM stack is running on localhost:3000"
else
    echo "❌ Grafana LGTM stack not detected on localhost:3000"
    echo "   Please run: docker run -p 3000:3000 -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm"
    echo ""
fi

# Check OpenTelemetry endpoints
echo ""
echo "🔌 Checking OpenTelemetry endpoints..."

# gRPC endpoint (4317)
if nc -z localhost 4317 2>/dev/null; then
    echo "✅ gRPC endpoint available on localhost:4317"
else
    echo "❌ gRPC endpoint not available on localhost:4317"
fi

# HTTP endpoint (4318)  
if nc -z localhost 4318 2>/dev/null; then
    echo "✅ HTTP endpoint available on localhost:4318"
else
    echo "❌ HTTP endpoint not available on localhost:4318"
fi

echo ""
echo "🌐 Network Interface Information:"
echo "================================="

# Get network interfaces and IPs
if command -v ifconfig &> /dev/null; then
    # macOS/Linux with ifconfig
    echo "Available network interfaces:"
    ifconfig | grep -A 1 "flags=.*UP.*" | grep -E "inet |inet6 " | head -10
    
    # Try to find the most likely WiFi IP
    WIFI_IP=$(ifconfig | grep -A 1 'en0:' | grep 'inet ' | awk '{print $2}' | head -n 1)
    if [ -n "$WIFI_IP" ]; then
        echo ""
        echo "🏠 Likely WiFi IP address: $WIFI_IP"
    fi
    
elif command -v ip &> /dev/null; then
    # Linux with ip command
    echo "Available network interfaces:"
    ip addr show | grep -E "inet " | head -10
    
    # Try to find a WiFi IP
    WIFI_IP=$(ip route get 8.8.8.8 | grep -oP 'src \K\S+' 2>/dev/null || echo "")
    if [ -n "$WIFI_IP" ]; then
        echo ""
        echo "🏠 Likely WiFi IP address: $WIFI_IP"
    fi
else
    echo "⚠️  Unable to detect network interfaces"
fi

echo ""
echo "📱 Platform-Specific Configurations:"
echo "===================================="
echo ""
echo "🌐 Web Browser:"
echo "   Endpoint: http://localhost:4318 (HTTP)"
echo "   Status: Always works (same machine)"
echo ""
echo "🤖 Android Emulator:"
echo "   Endpoint: http://10.0.2.2:4317 (gRPC)"
echo "   Status: Emulator maps localhost to 10.0.2.2"
echo ""
echo "📱 Android Physical Device:"
if [ -n "$WIFI_IP" ] && [ "$WIFI_IP" != "127.0.0.1" ]; then
    echo "   Recommended: http://$WIFI_IP:4317 (gRPC)"
    echo "   Status: Device needs WiFi IP to reach your machine"
    
    # Test if we can reach the OTEL endpoint from this IP
    if nc -z "$WIFI_IP" 4317 2>/dev/null; then
        echo "   ✅ gRPC endpoint reachable on $WIFI_IP:4317"
    else
        echo "   ⚠️  Check firewall - gRPC endpoint may not be accessible from $WIFI_IP"
    fi
else
    echo "   Endpoint: http://[YOUR_WIFI_IP]:4317 (gRPC)"
    echo "   Status: Update config with your WiFi IP address"
fi
echo ""
echo "🍎 iOS Simulator:"
echo "   Endpoint: http://localhost:4317 (gRPC)"
echo "   Status: Simulator can access localhost"
echo ""
echo "📱 iOS Physical Device:"
if [ -n "$WIFI_IP" ] && [ "$WIFI_IP" != "127.0.0.1" ]; then
    echo "   Recommended: http://$WIFI_IP:4317 (gRPC)"
    echo "   Status: Device needs WiFi IP to reach your machine"
else
    echo "   Endpoint: http://[YOUR_WIFI_IP]:4317 (gRPC)"
    echo "   Status: Update config with your WiFi IP address"
fi

echo ""
echo "🔧 Configuration Update:"
echo "========================"
echo ""
if [ -n "$WIFI_IP" ] && [ "$WIFI_IP" != "127.0.0.1" ]; then
    echo "To update for physical devices, edit lib/config/otel_config.dart:"
    echo ""
    echo "Replace this line:"
    echo "  return 'http://192.168.1.100:4317';"
    echo ""
    echo "With:"
    echo "  return 'http://$WIFI_IP:4317';"
    echo ""
fi

echo "🚀 Quick Launch Commands:"
echo "========================="
echo ""
echo "Web:              ./launch_web.sh"
echo "Android Emulator: ./launch_android_emulator.sh"
echo "Android Device:   ./launch_android_device.sh"
echo "iOS Simulator:    ./launch_ios_simulator.sh"
echo ""
