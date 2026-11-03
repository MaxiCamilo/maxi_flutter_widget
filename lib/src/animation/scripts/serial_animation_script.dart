import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class SerialAnimationScript implements AnimationScript {
  final List<AnimationScript> scripts;

  const new(this.scripts);

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => futureScopeVoid(() async {
    final initScope = LifecycleScopeFactory();
    scope.attachHeart(initScope);
    try {
      for (int i = 0; i < scripts.length; i++) {
        await scripts[i].playAndWait(controller: controller, mainScope: initScope);
      }
    } finally {
      initScope.dispose();
    }
  });
}
