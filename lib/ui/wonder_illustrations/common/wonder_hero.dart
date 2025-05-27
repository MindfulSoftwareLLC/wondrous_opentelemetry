import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';
import 'package:wonders_opentelemetry/common_libs.dart';
import 'package:wonders_opentelemetry/ui/wonder_illustrations/common/wonder_illustration_config.dart';

/// Utility class that wraps a normal [Hero] widget, but respects WonderIllustrationConfig.enableHero setting
class WonderHero extends StatelessWidget {
  const WonderHero(this.config, this.tag, {super.key, required this.child});
  final WonderIllustrationConfig config;
  final Widget child;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return MetricCollector(
      componentName: 'WonderHero-$tag',
      child: config.enableHero
          ? Hero(
        createRectTween: (begin, end) => RectTween(begin: begin!, end: end!),
        tag: tag,
        child: child,
      )
          : child,
    );
  }
}
