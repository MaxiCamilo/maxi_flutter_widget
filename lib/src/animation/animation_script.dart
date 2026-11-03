import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';
import 'package:maxi_flutter_widget/src/animation/scripts/loop_animation_script.dart';

import 'scripts/waiting_animation_script.dart';
import 'scripts/selected_animation_script.dart';
import 'scripts/conditional_animation_script.dart';
import 'scripts/parallel_animation_script.dart';
import 'scripts/serial_animation_script.dart';
import 'scripts/value_animation_script.dart';

abstract interface class AnimationScript {
  @protected
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope});

  const factory AnimationScript.waiting({required Duration duration}) = WaitingAnimationScript;
  const factory AnimationScript.selected({required Object key}) = SelectedValueAnimationScript;
  const factory AnimationScript.conditional({required AnimationScript script, required bool Function(MaxiAnimationController controller) condition}) = ConditionalAnimationScript;
  const factory AnimationScript.parallel(List<AnimationScript> scripts) = ParallelAnimationScript;
  const factory AnimationScript.serial(List<AnimationScript> scripts) = SerialAnimationScript;
  const factory AnimationScript.value({required Map<Object, Object> values, required Duration duration, Curve? curve}) = ValueAnimationScript;
  const factory AnimationScript.loop({required AnimationScript script, int? count}) = LoopAnimationScript;
  
}

extension AnimationScriptExtensions on AnimationScript {
  Future<void> playAndWait({required MaxiAnimationController controller, ILifecycleScope? mainScope}) async {
    late final ILifecycleScope scope;
    if (mainScope == null) {
      scope = LifecycleScopeFactory();
      controller.heart.attachHeart(scope);
    } else {
      scope = mainScope;
    }
    try {
      await performancePlay(controller: controller, scope: scope).logIfFailure('Failed to play animation script');
    } finally {
      scope.dispose();
    }
  }

  Disposable play(MaxiAnimationController controller) {
    final scope = LifecycleScope();

    scheduleMicrotask(() async {
      if (controller.isDisposed) {
        log('Controller is disposed, aborting animation script');
        scope.dispose();
        return;
      }
      await performancePlay(controller: controller, scope: scope).logIfFailure('Failed to play animation script');
      scope.dispose();
    });

    return scope;
  }
}
