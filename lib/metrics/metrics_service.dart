import 'package:get_it/get_it.dart';
import 'flutter_metric_reporter.dart';
import 'trackers/page_tracker.dart';
import 'trackers/paint_tracker.dart';
import 'trackers/shift_tracker.dart';
import 'trackers/apdex_tracker.dart';
import 'trackers/user_input_tracker.dart';
import 'trackers/error_tracker.dart';
import 'listeners/console_metrics_listener.dart';

class MetricsService {
  static void initialize() {
    final getIt = GetIt.instance;

    // Register core components
    getIt.registerSingleton<FlutterMetricReporter>(FlutterMetricReporter());

    // Register all trackers as singletons (not lazy)
    getIt.registerSingleton<PageTracker>(PageTracker());
    getIt.registerSingleton<PaintTracker>(PaintTracker());
    getIt.registerSingleton<ShiftTracker>(ShiftTracker());
    getIt.registerSingleton<ApdexTracker>(ApdexTracker());
    getIt.registerSingleton<UserInputTracker>(UserInputTracker());
    getIt.registerSingleton<ErrorTracker>(ErrorTracker());

    // Initialize and register the console listener
    getIt.registerSingleton<ConsoleMetricsListener>(ConsoleMetricsListener());

    // Force instantiation to ensure listeners are connected
    getIt<ConsoleMetricsListener>();
  }

  static void dispose() {
    final getIt = GetIt.instance;

    // Dispose in reverse order of initialization
    getIt.get<ConsoleMetricsListener>().dispose();

    // Dispose of all trackers
    getIt.get<PageTracker>().dispose();
    getIt.get<PaintTracker>().dispose();
    getIt.get<ShiftTracker>().dispose();
    getIt.get<ApdexTracker>().dispose();
    getIt.get<UserInputTracker>().dispose();
    getIt.get<ErrorTracker>().dispose();

    // Dispose of the metric reporter last
    getIt.get<FlutterMetricReporter>().dispose();
  }

  // Utility method to check if metrics are flowing
  static void debugPrintMetricsStatus() {
    final getIt = GetIt.instance;
    final reporter = getIt.get<FlutterMetricReporter>();
    final console = getIt.get<ConsoleMetricsListener>();

    print('Metrics System Status:');
    print('Reporter initialized: ${reporter != null}');
    print('Console listener initialized: ${console != null}');

    // Force a test metric to verify the pipeline
    reporter.reportPerformanceMetric(
      'metrics_test',
      Duration(milliseconds: 100),
      attributes: {'test': true},
    );
  }
}
