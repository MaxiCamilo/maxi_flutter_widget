import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/src/animation.dart';

class WaitingAnimationScript implements AnimationScript {
  final Duration duration;

  const WaitingAnimationScript({required this.duration});

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => futureScopeVoid(() async {
    await scope.wait(duration);
  });
}
