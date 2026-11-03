import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class ParallelAnimationScript implements AnimationScript {
  final List<AnimationScript> scripts;

  const new(this.scripts);

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => futureScopeVoid(() async {
    final initScope = LifecycleScopeFactory();
    scope.attachHeart(initScope);
    try {
      await Future.wait(scripts.map((script) => script.playAndWait(controller: controller, mainScope: initScope)));
    } finally {
      initScope.dispose();
    }
  });
}
