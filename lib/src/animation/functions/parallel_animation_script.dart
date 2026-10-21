import 'package:flutter/foundation.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

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

  @override
  operator ==(Object other) => identical(this, other) || (other is ParallelAnimationScript && listEquals(other._scripts, _scripts));
  @override
  int get hashCode => _scripts.map((e) => e.hashCode).fold(0, (prev, element) => prev ^ element);
}
