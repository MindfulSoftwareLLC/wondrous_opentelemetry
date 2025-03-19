import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';

/// Weather service implementation that uses the Dartastic.io weather service
/// This demonstrates end-to-end tracing between client and server
class DartasticWeatherService {
  static const String serviceUrl = 'https://weather.dartastic.io';

  // Instrument with OpenTelemetry
  final UITracer _tracer = FlutterOTel.tracer;
  final FlutterMetricReporter _metrics = FlutterMetricReporter();

  /// Get weather data for a location via the Dartastic.io service
  ///
  /// This showcases end-to-end tracing between client and server components,
  /// with the server also instrumented using Dartastic OpenTelemetry
  Future<Map<String, dynamic>> getWeatherForLocation(
      double lat, double lon) async {
    // Create a span for this operation
    final span = _tracer.startSpan('get_weather_from_dartastic');

    final stopwatch = Stopwatch()..start();

    try {
      // Call the weather endpoint of our Dart service
      final url = '$serviceUrl/weather?lat=$lat&lon=$lon';

      // Create an HTTP client
      final client = http.Client();

      try {
        // Make the request
        final response = await client.get(Uri.parse(url));

        span.addAttributes(<String, Object>{
          'latitude': lat.toString(),
          'longitude': lon.toString(),
          'url': url,
          'http.status_code': response.statusCode,
          'http.response_size': response.body.length
        }.toAttributes());

        // Record the metric
        _metrics.reportPerformanceMetric(
          'dartastic_weather_api_call',
          stopwatch.elapsed,
          attributes: {
            'status_code': response.statusCode,
            'latitude': lat,
            'longitude': lon,
          },
        );

        if (response.statusCode == 200) {
          // Parse the response
          final data = json.decode(response.body);

          // Add additional context to the span
          if (data['weather'] != null && data['weather'].isNotEmpty) {
            span.addAttributes(<String, Object>{
              'weather.main': data['weather'][0]['main'],
              'weather.description': data['weather'][0]['description']
            }.toAttributes());
          }

          span.setStatus(SpanStatusCode.Ok);
          return data;
        } else {
          // Handle error response
          final errorMsg =
              'Weather API responded with status: ${response.statusCode}';
          span.setStatus(SpanStatusCode.Error, errorMsg);
          throw Exception(errorMsg);
        }
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      // Record the error
      span.recordException(e, stackTrace: stackTrace);
      span.setStatus(SpanStatusCode.Error, e.toString());

      // Report as a metric too
      _metrics.reportError(
        'Dartastic Weather API Error',
        stackTrace: stackTrace,
        attributes: {
          'latitude': lat,
          'longitude': lon,
          'error_message': e.toString(),
        },
      );

      rethrow;
    } finally {
      stopwatch.stop();
      span.end();
    }
  }
}
