import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class LoopAnimationScript implements AnimationScript {
  final AnimationScript script;
  final int? count;

  const new({required this.script, this.count});

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => futureScopeVoid(() async {
    /*if (count == null) {
      while (!scope.isDisposed) {
        await script.playAndWait(controller: controller, mainScope: scope);
      }
    } else {
      for (var i = 0; i < count!; i++) {
        if (scope.isDisposed) break;
        await script.playAndWait(controller: controller, mainScope: scope);
      }
    }*/
    if (count == null) {
      while (!scope.isDisposed && !controller.isDisposed) {
        await script.playAndWait(controller: controller, mainScope: scope);
      }
    } else {
      for (var i = 0; i < count!; i++) {
        if (scope.isDisposed || controller.isDisposed) break;
        await script.playAndWait(controller: controller, mainScope: scope);
      }
    }
  });
}
