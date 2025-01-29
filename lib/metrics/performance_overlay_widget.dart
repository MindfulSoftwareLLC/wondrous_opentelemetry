import 'package:flutter/material.dart';
import 'flutter_metric_reporter.dart';

class PerformanceOverlayWidget extends StatefulWidget {
  final Widget child;
  final String componentName;
  
  const PerformanceOverlayWidget({
    Key? key,
    required this.child,
    required this.componentName,
  }) : super(key: key);

  @override
  State<PerformanceOverlayWidget> createState() => _PerformanceOverlayWidgetState();
}

class _PerformanceOverlayWidgetState extends State<PerformanceOverlayWidget> {
  late DateTime _buildStartTime;

  @override
  void initState() {
    super.initState();
    _buildStartTime = DateTime.now();
  }

  @override
  void didUpdateWidget(PerformanceOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildStartTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final buildDuration = DateTime.now().difference(_buildStartTime);
      FlutterMetricReporter().reportPerformanceMetric(
        'component_build_time',
        buildDuration,
        attributes: {'component_name': widget.componentName},
      );
    });

    return widget.child;
  }
}