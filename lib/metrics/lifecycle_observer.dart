import 'package:flutter/material.dart';
import 'flutter_metric_reporter.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  final FlutterMetricReporter _reporter;
  DateTime? _pausedTime;
  DateTime? _appStartTime;

  AppLifecycleObserver(this._reporter) {
    _appStartTime = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _reportAppStartMetric();
  }

  void _reportAppStartMetric() {
    final startupDuration = DateTime.now().difference(_appStartTime!);
    _reporter.reportPerformanceMetric(
      'app_start_time',
      startupDuration,
      attributes: {'cold_start': true},
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pausedTime = DateTime.now();
        _reporter.reportUserInteraction(
          'app',
          'background',
          attributes: {'timestamp': _pausedTime!.toIso8601String()},
        );
        break;
      case AppLifecycleState.resumed:
        if (_pausedTime != null) {
          final backgroundDuration = DateTime.now().difference(_pausedTime!);
          _reporter.reportPerformanceMetric(
            'background_time',
            backgroundDuration,
          );
        }
        _reporter.reportUserInteraction(
          'app',
          'foreground',
          attributes: {'timestamp': DateTime.now().toIso8601String()},
        );
        break;
      case AppLifecycleState.inactive:
        _reporter.reportUserInteraction('app', 'inactive');
        break;
      case AppLifecycleState.detached:
        _reporter.reportUserInteraction('app', 'detached');
        break;
      default:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}