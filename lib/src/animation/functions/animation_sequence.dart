import 'dart:async';

import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

final class AnimationSequence extends AnimationScript {
  final Map<Object, dynamic> initValues;
  final Map<Object, dynamic> Function(AnimationDirector director)? initValuesBuilder;
  final List<AnimationScriptInterface> _scripts;
  final bool reverseAfter;

  const new({required this._scripts, this.initValues = const {}, this.initValuesBuilder, this.reverseAfter = false});

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    for (final entry in initValues.entries) {
      director.set(entry.key, entry.value);
    }
    if (initValuesBuilder != null) {
      final builtValues = initValuesBuilder!(director);
      for (final entry in builtValues.entries) {
        director.set(entry.key, entry.value);
      }
    }

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

    if (reverseAfter) {
      for (int i = _scripts.length - 1; i >= 0; i--) {
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
    }
  });
}
