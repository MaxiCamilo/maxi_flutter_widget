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

final class AnimationSequence extends AnimationScript {
  final List<AnimationScriptInterface> _scripts;

  const new({required this._scripts});

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    for (int i = 0; i < _scripts.length; i++) {
      final script = _scripts[i];
      if (script is AnimationScript) {
        await script.performAnimation(director: director, hearth: hearth);
      } else {
        final completer = Completer();

        script.execute(director, onFinished: () => completer.complete()).$;
        await completer.future;
      }
    }
  });
}

final class AnimationStateSequence extends AnimationScript {
  final List<AnimationScriptInterface> _scripts;
  int _currentIndex = 0;

  new({required this._scripts});

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    while (_currentIndex < _scripts.length) {
      final script = _scripts[_currentIndex];
      if (script is AnimationScript) {
        await script.performAnimation(director: director, hearth: hearth);
      } else {
        await script.executeAndWait(director);
      }
      _currentIndex += 1;
    }

    _currentIndex = 0;
  });

  void reset() {
    _currentIndex = 0;
  }
}

final class ParallelAnimationScript extends AnimationScript {
  final List<AnimationScriptInterface> _scripts;

  const new({required this._scripts});

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    await Future.wait(
      _scripts.map((script) {
        if (script is AnimationScript) {
          return script.performAnimation(director: director, hearth: hearth);
        } else {
          return script.executeAndWait(director);
        }
      }),
    );
  });
}

final class ActionAnimationScript extends AnimationScript {
  final Map<Object, dynamic> values;
  final Curve? curve;
  final Duration? duration;

  const new({required this.values, this.curve, this.duration});

  static AnimationScript express({required Map<Object, dynamic> Function() valuesBuilder, Curve? curve, Duration? duration}) => _ActionScriptExpress(valuesBuilder: valuesBuilder, curve: curve, duration: duration);

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    for (final entry in values.entries) {
      director.set(entry.key, entry.value, curve: curve, duration: duration);
    }

    await hearth.wait(duration ?? director.defaultDuration);
  });
}

final class _ActionScriptExpress extends AnimationScript {
  final Map<Object, dynamic> Function() valuesBuilder;
  final Curve? curve;
  final Duration? duration;

  const new({required this.valuesBuilder, required this.curve, required this.duration});

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) {
    final values = valuesBuilder();
    for (final entry in values.entries) {
      director.set(entry.key, entry.value, curve: curve, duration: duration);
    }

    return hearth.wait(duration ?? director.defaultDuration);
  }
}

final class _AniScriptExpress extends AnimationScript {
  final FutureResult<void> Function({required AnimationDirector director, required ILifecycleScope hearth}) animation;

  const _AniScriptExpress({required this.animation});
  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => animation(
    director: director,
    hearth: hearth,
  );
}
