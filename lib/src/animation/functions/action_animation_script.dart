import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

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

  @override
  operator ==(Object other) => identical(this, other) || (other is ActionAnimationScript && mapEquals(other.values, values) && other.curve == curve && other.duration == duration);
  @override
  int get hashCode => Object.hash(values, curve, duration);
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

  @override
  operator ==(Object other) => identical(this, other) || (other is _ActionScriptExpress && other.valuesBuilder == valuesBuilder && other.curve == curve && other.duration == duration);
  @override
  int get hashCode => Object.hash(valuesBuilder, curve, duration);
}
