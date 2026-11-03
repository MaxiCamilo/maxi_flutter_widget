import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class SelectedAnimationScript implements AnimationScript {
  final AnimationScript? Function(MaxiAnimationController controller) selector;

  const SelectedAnimationScript({required this.selector});

  //factory SelectedAnimationScript.value(Object key) => SelectedAnimationScript(selector: (controller) => controller.get<AnimationScript>(key));

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => futureScopeVoid(() async {
    if (scope.isDisposed) return;
    final script = selector(controller);
    if (script != null) {
      await script.playAndWait(controller: controller, mainScope: scope);
    }
  });
}

class SelectedValueAnimationScript implements AnimationScript {
  final Object key;

  const SelectedValueAnimationScript({required this.key});

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => futureScopeVoid(() async {
    if (scope.isDisposed) return;
    final script = controller.get<AnimationScript>(key);
    if (script != null) {
      await script.playAndWait(controller: controller, mainScope: scope);
    }
  });
}
