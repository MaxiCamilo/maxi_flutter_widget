import 'dart:async';

import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

final class ActionAnimationLoop extends AnimationScript {
  final AnimationScript animation;
  final int iterations;

  const new({required this.animation, this.iterations = 0});

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    if (iterations == 0) {
      while (!hearth.isDisposed) {
        final completer = Completer();
        hearth.attachChild(animation.execute(director, onFinished: () => completer.complete()).$);
        await completer.future;
      }
    } else {
      int count = iterations;
      while (!hearth.isDisposed && count > 0) {
        final completer = Completer();
        hearth.attachChild(animation.execute(director, onFinished: () => completer.complete()).$);
        await completer.future;
        count -= 1;
      }
    }
  });
}
