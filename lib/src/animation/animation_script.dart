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
import 'scripts/key_builder_animation_script.dart';

abstract interface class AnimationScript {
  @protected
  FutureResult<void> performancePlay({required MaxiAnimationController controller, required ILifecycleScope scope});

  const factory AnimationScript.waiting({required Duration duration}) = WaitingAnimationScript;
  const factory AnimationScript.selected({required Object key}) = SelectedValueAnimationScript;
  const factory AnimationScript.conditional({
    required bool Function(MaxiAnimationController controller) condition,
    required AnimationScript script,
  }) = ConditionalAnimationScript;
  const factory AnimationScript.parallel(List<AnimationScript> scripts) = ParallelAnimationScript;
  const factory AnimationScript.serial(List<AnimationScript> scripts) = SerialAnimationScript;
  const factory AnimationScript.value({required Map<Object, Object> values, required Duration duration, Curve? curve}) = ValueAnimationScript;
  const factory AnimationScript.teleport(Map<Object, Object> values) = ValueAnimationScript.teleport;
  const factory AnimationScript.loop({required AnimationScript script, int? count}) = LoopAnimationScript;
  const factory AnimationScript.keyBuilder({required Object key, required AnimationScript script}) = KeyBuilderAnimationScript;
}

extension AnimationScriptExtensions on AnimationScript {
  Future<void> playAndWait({required MaxiAnimationController controller, ILifecycleScope? mainScope}) async {
    /*
    final scope = LifecycleScopeFactory();
    if (mainScope == null) {
      controller.heart.attachHeart(scope);
    }

    final result = await $$(Oration('Failed to play animation script'), () => performancePlay(controller: controller, scope: scope));
    scope.dispose();
    final error = result.extractError();
    if (error != null) {
      log('Animation script failed with error: $error');
    }*/
    final scope = LifecycleScopeFactory();
    final parent = mainScope ?? controller.heart;

    if (parent.attachHeart(scope) is NegativeResult) {
      scope.dispose(); // el padre ya estaba descartado: no arrancar
      return;
    }

    final result = await $$(Oration('Failed to play animation script'), () => performancePlay(controller: controller, scope: scope));
    scope.dispose();
    final error = result.extractError();
    if (error != null && !parent.isDisposed) {
      log('Animation script failed with error: $error');
    }
  }

  Disposable play(MaxiAnimationController controller) {
    /*
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

    return scope;*/
    final scope = LifecycleScope();

    scheduleMicrotask(() async {
      if (scope.isDisposed) return; // cancelada antes de arrancar
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
