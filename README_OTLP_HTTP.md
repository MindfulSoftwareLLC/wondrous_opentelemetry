## Technical Overview

1. **Protocol Support**:
   - OTLP/gRPC (port 4317) for native platforms
   - OTLP/HTTP/protobuf (port 4318) for web platforms
   - Both traces and metrics are supported over both protocols

# Full OTLP/HTTP Support for Flutter Web

This implementation adds complete OTLP/HTTP protocol support for Flutter Web applications, covering both traces and metrics. It enables your Flutter application to work seamlessly across all platforms.

## Background

Flutter Web doesn't support gRPC (the default protocol used by OpenTelemetry) due to browser limitations around HTTP/2. Instead, for Flutter Web, we need to use **OTLP over HTTP/protobuf**, also known as OTLP/HTTP.

This implementation adds support for OTLP/HTTP in the OpenTelemetry SDKs to make them work seamlessly on Flutter Web.

## How it Works

The implementation automatically detects when the application is running in Flutter Web and uses OTLP/HTTP instead of OTLP/gRPC. This detection happens in two ways:

1. During initialization, if `kIsWeb` is true, the exporter will use HTTP
2. You can explicitly specify the protocol with the `OTEL_EXPORTER_OTLP_PROTOCOL` environment variable

## Ports and Endpoints

- OTLP/gRPC uses port 4317 (used for native platforms)
- OTLP/HTTP uses port 4318 (used for web platforms)

The implementation automatically adjusts endpoints and ports based on the platform:

- For web, http://localhost:4317 is converted to http://localhost:4318
- For web, domain.com:4317 is converted to http://domain.com:4318

## Usage

To use OpenTelemetry in a Flutter Web application, you don't need to do anything special; it will work automatically. The SDK will detect that it's running in a web environment and use OTLP/HTTP.

### Environment Variables

You can configure OpenTelemetry using these environment variables:

- `OTEL_EXPORTER_OTLP_ENDPOINT`: Specifies the endpoint URL
  - Example: `--dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=my-otel-collector.com`

- `OTEL_EXPORTER_OTLP_PROTOCOL`: Specifies the protocol to use 
  - Example for web: `--dart-define=OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`
  - Example for native: `--dart-define=OTEL_EXPORTER_OTLP_PROTOCOL=grpc`

### Setting Up a Local Collector for Development

For local development, you can use Docker to run a local OpenTelemetry collector:

```bash
docker run -p 3000:3000 -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm
```

This runs a Grafana OTel collector that can be accessed at:
- For native apps: `http://localhost:4317` (gRPC)
- For web apps: `http://localhost:4318` (HTTP)

### Implementation Details

The implementation consists of:

1. `OtlpHttpSpanExporter` - An implementation of the SpanExporter interface that uses HTTP/protobuf
2. `OtlpHttpSpanExporterConfig` - Configuration for the HTTP exporter
3. `PlatformDetection` - Utility class in the FlutterOTel package to detect platform and select the appropriate exporter

The platform detection logic is implemented in the Flutterrific OTel package, as it depends on Flutter's `kIsWeb` constant.

1. **Protocol Support**:
    - OTLP/gRPC (port 4317) for native platforms
    - OTLP/HTTP/protobuf (port 4318) for web platforms
    - Both traces and metrics are supported over both protocols

# Full OTLP/HTTP Support for Flutter Web

This implementation adds complete OTLP/HTTP protocol support for Flutter Web applications, covering both traces and metrics. It enables your Flutter application to work seamlessly across all platforms.

## Background

Flutter Web doesn't support gRPC (the default protocol used by OpenTelemetry) due to browser limitations around HTTP/2. Instead, for Flutter Web, we need to use **OTLP over HTTP/protobuf**, also known as OTLP/HTTP.

This implementation adds support for OTLP/HTTP in the OpenTelemetry SDKs to make them work seamlessly on Flutter Web.

## How it Works

The implementation automatically detects when the application is running in Flutter Web and uses OTLP/HTTP instead of OTLP/gRPC. This detection happens in two ways:

1. During initialization, if `kIsWeb` is true, the exporter will use HTTP
2. You can explicitly specify the protocol with the `OTEL_EXPORTER_OTLP_PROTOCOL` environment variable

## Ports and Endpoints

- OTLP/gRPC uses port 4317 (used for native platforms)
- OTLP/HTTP uses port 4318 (used for web platforms)

The implementation automatically adjusts endpoints and ports based on the platform:

- For web, http://localhost:4317 is converted to http://localhost:4318
- For web, domain.com:4317 is converted to http://domain.com:4318

## Usage

To use OpenTelemetry in a Flutter Web application, you don't need to do anything special; it will work automatically. The SDK will detect that it's running in a web environment and use OTLP/HTTP.

### Environment Variables

You can configure OpenTelemetry using these environment variables:

- `OTEL_EXPORTER_OTLP_ENDPOINT`: Specifies the endpoint URL
    - Example: `--dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=my-otel-collector.com`

- `OTEL_EXPORTER_OTLP_PROTOCOL`: Specifies the protocol to use
    - Example for web: `--dart-define=OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`
    - Example for native: `--dart-define=OTEL_EXPORTER_OTLP_PROTOCOL=grpc`

### Setting Up a Local Collector for Development

For local development, you can use Docker to run a local OpenTelemetry collector:

```bash
docker run -p 3000:3000 -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm
```

This runs a Grafana OTel collector that can be accessed at:
- For native apps: `http://localhost:4317` (gRPC)
- For web apps: `http://localhost:4318` (HTTP)


### Troubleshooting

If you encounter issues, you can:

1. Enable verbose logging by setting `OTelLog.currentLevel = LogLevel.trace`
2. Check for errors in the browser console related to HTTP requests to port 4318
3. Verify your collector is configured to receive OTLP over HTTP/protobuf

Common issues:
- CORS errors: Ensure your collector has proper CORS configuration for web browsers
- Connectivity issues: Check that port 4318 is open and accessible
- Protocol mismatch: Verify your collector supports OTLP/HTTP on port 4318

## Technical Limitations

1. **Compression**: Compression is disabled for web platforms due to browser limitations.
2. **Authentication**: For web platforms, authentication must be done via headers rather than gRPC credentials.
3. **Browser Constraints**: Web browsers have limitations on cross-origin requests and HTTP/2 that may affect the reliability of telemetry data collection.

## Future Improvements

Planned improvements include:
- HTTP/JSON exporter support for even broader web compatibility
- Better metrics support for web applications
- Automatic retries and connection pooling specific to browser environments
