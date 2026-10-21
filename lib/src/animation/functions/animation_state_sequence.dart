import 'package:flutter/foundation.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

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

  @override
  operator ==(Object other) => identical(this, other) || (other is AnimationStateSequence && listEquals(other._scripts, _scripts) && other._currentIndex == _currentIndex);

  @override
  int get hashCode => Object.hash(_scripts, _currentIndex);
}
