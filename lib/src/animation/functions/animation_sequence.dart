import 'dart:async';

import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

final class AnimationSequence extends AnimationScript {
  final List<AnimationScriptInterface> _scripts;

  const new({required this._scripts});

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    for (int i = 0; i < _scripts.length; i++) {
      if (hearth.isDisposed) return;
      final script = _scripts[i];
      if (script is AnimationScript) {
        final completer = Completer();
        hearth.attachChild(script.execute(director, onFinished: () => completer.complete()).$);
        await completer.future;
      } else {
        final completer = Completer();

        script.execute(director, onFinished: () => completer.complete()).$;
        await completer.future;
      }
    }
  });
}
