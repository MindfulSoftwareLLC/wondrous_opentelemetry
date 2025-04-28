# Flutter Web OpenTelemetry Setup Guide

This document provides instructions for setting up and troubleshooting the OpenTelemetry integration for Flutter Web in the Wonderous OpenTelemetry example app.

## Table of Contents

1. [Overview](#overview)
2. [Backend Configuration](#backend-configuration)
3. [Flutter Web Configuration](#flutter-web-configuration)
4. [Troubleshooting](#troubleshooting)
5. [Testing](#testing)

## Overview

Flutter Web has specific requirements for OpenTelemetry:

- It can only use OTLP over HTTP/protobuf (port 4318), not gRPC (port 4317)
- The backend must have proper CORS configuration enabled
- Special handling for endpoints and protocol selection is needed

## Backend Configuration

### CORS Configuration

The backend collector must have CORS enabled to accept requests from browser origins. Our `config-cors-fixed.yaml` configures:

```yaml
otlp:
  protocols:
    http:
      endpoint: 0.0.0.0:4318
      cors:
        allowed_origins:
          - "*"
        allowed_headers:
          - "*"
        max_age: 7200
```

### Updating the Backend

To update the backend configuration:

1. Make the fix-cors.sh script executable:
   ```bash
   ./make-fix-cors-executable.sh
   ```

2. Run the script to update the configuration and restart the container:
   ```bash
   ./fix-cors.sh
   ```

This script:
- Uploads the enhanced CORS configuration
- Restarts the container with the new settings

## Flutter Web Configuration

### Code Changes

The following changes have been made to support Flutter Web:

1. Added remote endpoint configuration in `main.dart`:
   ```dart
   const otelRemoteEndpoint = 'http://88.99.244.251:4318'; // For Web
   ```

2. Added platform-specific endpoint selection:
   ```dart
   String endpoint = kIsWeb ? otelRemoteEndpoint : otelLocalHostDefault;
   ```

3. Passing the correct endpoint to the FlutterOTel initialization:
   ```dart
   await FlutterOTel.initialize(
     // other params...
     endpoint: endpoint,
     // other params...
   );
   ```

### Running the Web App

Use the provided script to run the web app with the correct configuration:

```bash
./make_run_web_executable.sh  # Make script executable
./run_web_with_remote_backend.sh  # Run the app
```

This sets:
- The web port to 54381
- OTLP protocol to HTTP/protobuf

## Troubleshooting

### Common Issues

1. **CORS Errors**

   Error message:
   ```
   Access to XMLHttpRequest at 'http://88.99.244.251:4318/v1/traces' from origin 'http://localhost:54381' has been blocked by CORS policy
   ```

   Solution:
   - Ensure your backend has the correct CORS configuration
   - Restart the container after updating the configuration
   - Use the `fix-cors.sh` script to update CORS settings

2. **Endpoint Mismatches**

   Solution:
   - For Web: Always use port 4318 (HTTP), not 4317 (gRPC)
   - For Native: Use port 4317 (gRPC)

3. **Protocol Mismatches**

   Solution:
   - For Web: Use `http/protobuf` protocol
   - For Native: Use `grpc` protocol

### Testing CORS Configuration

Use the provided `cors-test.html` to test your CORS configuration:

1. Run a local web server to serve the page:
   ```bash
   cd web
   python -m http.server 8000
   ```

2. Open `http://localhost:8000/cors-test.html` in your browser
3. Click "Test CORS Configuration" to check if CORS is working

## Testing

To verify everything is working:

1. Start the backend with CORS enabled using `fix-cors.sh`
2. Run the Flutter Web app using `run_web_with_remote_backend.sh`
3. Check the browser console for any errors
4. Verify in Grafana that traces and metrics are being received

Access Grafana at: http://88.99.244.251:3000
