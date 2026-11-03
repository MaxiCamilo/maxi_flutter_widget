import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class ConditionalAnimationScript implements AnimationScript {
  final AnimationScript script;
  final bool Function(MaxiAnimationController controller) condition;

  const ConditionalAnimationScript({required this.script, required this.condition});

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => futureScopeVoid(() async {
    if (!scope.isDisposed && condition(controller)) {
      await script.playAndWait(controller: controller, mainScope: scope);
    }
  });
}
