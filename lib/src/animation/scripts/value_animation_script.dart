import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class ValueAnimationScript implements AnimationScript {
  final Map<Object, Object> values;
  final Duration duration;
  final Curve? curve;

  const new({required this.values, required this.duration, this.curve});

  @override
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope}) => futureScopeVoid(() async {
    for (final value in values.entries) {
      controller.set(value.key, value.value, duration: duration, curve: curve);
    }

    await scope.wait(duration);
  });
}
