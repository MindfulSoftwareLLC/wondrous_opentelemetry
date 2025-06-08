#!/bin/bash

# Build and serve Flutter web app with OpenTelemetry

set -e

echo "🌐 Building Flutter Web with OpenTelemetry..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build for web
echo "📦 Building Flutter web..."
flutter build web

# Check if build was successful
if [ ! -d "build/web" ]; then
    echo "❌ Web build failed - build/web directory not found"
    exit 1
fi

# Navigate to build directory and serve
echo "🚀 Starting web server..."
cd build/web

# Check if npx serve is available
if ! command -v npx &> /dev/null; then
    echo "❌ npx not found. Please install Node.js and npm"
    exit 1
fi

echo "✅ Web app building complete!"
echo ""
echo "📝 Configuration:"
echo "   Platform: Web"
echo "   OpenTelemetry Endpoint: http://localhost:4318 (HTTP)"
echo "   Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo ""
echo "🌐 Starting web server on http://localhost:3000..."
echo "   Press Ctrl+C to stop the server"
echo ""

# Serve the web app
npx serve -s . -l 5000
