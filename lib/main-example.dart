import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';

const String endpoint = 'https://otel-dev.dartastic.io:443';
const secure = true;
// var endpoint = 'http://ec2-3-139-70-11.us-east-2.compute.amazonaws.com:4317';
// var secure = false;

Future<void> copyOfOTLPgRPCExample() async {
  // Get the default tracer
  final tracer = OTel.tracer();

  //Add attributes
  // Always consult the OTel Semantic Conventions to find an existing
  // convention name for an attribute:
  // https://opentelemetry.io/docs/specs/semconv/general/attributes/
  tracer.attributes = OTel.attributesFromMap({
    SourceCodeResource.codeFunctionName.key: 'main'
  });

  // Create a new root span
  final rootSpan = tracer.startSpan(
    'root-operation-wonderous-dartastic',
    attributes: OTel.attributesFromMap({
      'example-dartastic.key': 'example-value-dartastic',
    }),
  );

  try {
    // Add an event to match Python example
    rootSpan.addEventNow('Event within span-dartastic');

    print('Dartastic Trace with a span sent to OpenTelemetry via dart-bushe-0211-grpc-batch!');

    // Simulate some work
    await Future.delayed(Duration(milliseconds: 100));

    // Create a child span
    final childSpan = tracer.startSpan(
      'child-operation-dartastic',
      parentSpan: rootSpan,
    );

    try {
      print('Doing some more work...');
      await Future.delayed(Duration(milliseconds: 50));
    } catch (e) {
      childSpan.recordException(e);
      childSpan.setStatus(SpanStatusCode.Error);
    } finally {
      childSpan.end();
    }
  } catch (e) {
    rootSpan.recordException(e);
    rootSpan.setStatus(SpanStatusCode.Error);
  } finally {
    rootSpan.end();
  }

  // Force flush before shutdown
  await OTel.tracerProvider().forceFlush();

  // Wait for any pending exports
  await Future.delayed(Duration(seconds: 1));

  // Shutdown - TODO - forceFlush inside?
  await OTel.tracerProvider().shutdown();
}

void main() async {
  copyOfOTLPgRPCExample();
}
