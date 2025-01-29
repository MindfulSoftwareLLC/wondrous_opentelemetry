import 'package:wonders/common_libs.dart';
import 'package:wonders/ui/wonder_illustrations/common/wonder_illustration_config.dart';
import 'package:wonders/metrics/performance_overlay_widget.dart';

/// Utility class that wraps a normal [Hero] widget, but respects WonderIllustrationConfig.enableHero setting
class WonderHero extends StatelessWidget {
  const WonderHero(this.config, this.tag, {super.key, required this.child});
  final WonderIllustrationConfig config;
  final Widget child;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return PerformanceOverlayWidget(
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