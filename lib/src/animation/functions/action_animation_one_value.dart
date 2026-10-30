import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

final class ActionAnimationOneValue extends AnimationScript {
  final Object key;
  final dynamic value;
  final Curve? curve;
  final Duration? duration;

  const new({required this.key, required this.value, this.curve, this.duration});

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    director.set(key, value, curve: curve, duration: duration);
    if (duration != null) {
      await hearth.wait(duration ?? director.defaultDuration);
    }
  });
}
