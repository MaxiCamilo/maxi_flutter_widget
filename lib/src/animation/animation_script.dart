import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

abstract interface class AnimationScriptInterface {
  Result<Disposable> execute(AnimationDirector director, {Function()? onFinished});
  Result<Disposable> executeLoop(AnimationDirector director, {Function()? onFinished});
}

abstract base class AnimationScript implements AnimationScriptInterface {
  const AnimationScript();

  static AnimationScript express({required FutureResult<void> Function({required AnimationDirector director, required ILifecycleScope hearth}) animation}) => _AniScriptExpress(animation: animation);

  @protected
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth});

  @override
  Result<Disposable> execute(AnimationDirector director, {Function()? onFinished}) => resultScopeValue(() {
    director.heart.checkDisposed().$;
    final hearth = director.heart.attachChild(LifecycleScopeFactory());

    scheduleMicrotask(() async {
      try {
        await $$_(performAnimation(director: director, hearth: hearth));
      } catch (_) {
      } finally {
        hearth.dispose();
      }
      if (onFinished != null) {
        onFinished();
      }
    });

    return hearth;
  });
  @override
  Result<Disposable> executeLoop(AnimationDirector director, {Function()? onFinished}) => resultScopeValue(() {
    director.heart.checkDisposed().$;
    final hearth = director.heart.attachChild(LifecycleScopeFactory());

    scheduleMicrotask(() async {
      try {
        while (!hearth.isDisposed) {
          await $$_(performAnimation(director: director, hearth: hearth));
        }
      } catch (_) {
      } finally {
        hearth.dispose();
      }
      if (onFinished != null) {
        onFinished();
      }
    });

    return hearth;
  });
}

final class _AniScriptExpress extends AnimationScript {
  final FutureResult<void> Function({required AnimationDirector director, required ILifecycleScope hearth}) animation;

  const _AniScriptExpress({required this.animation});
  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => animation(
    director: director,
    hearth: hearth,
  );

  @override
  operator ==(Object other) => identical(this, other) || (other is _AniScriptExpress && other.animation == animation);
  @override
  int get hashCode => animation.hashCode;
}
