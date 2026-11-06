import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class KeyBuilderAnimationScript implements AnimationScript {
  final Object key;
  final AnimationScript script;

  const KeyBuilderAnimationScript({
    required this.key,
    required this.script,
  });

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => script.performancePlay(controller: controller, scope: scope);

  @override
  operator ==(Object other) => identical(this, other) || other is KeyBuilderAnimationScript && key == other.key;

  @override
  int get hashCode => key.hashCode;
}
