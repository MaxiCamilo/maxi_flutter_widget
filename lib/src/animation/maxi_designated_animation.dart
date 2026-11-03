import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiDesignatedAnimation extends StatefulWidget {
  final AnimationScript? script;
  final MaxiAnimationController? controller;
  final Widget Function(BuildContext context, MaxiAnim anim) builder;
  final Duration duration;
  final Curve curve;

  const MaxiDesignatedAnimation({super.key, this.script, this.controller, required this.builder, this.duration = const Duration(milliseconds: 250), this.curve = Curves.easeInOut});

  @override
  State<MaxiDesignatedAnimation> createState() => _MaxiDesignatedAnimationState();
}

class _MaxiDesignatedAnimationState extends ReactiveSingleTickerState<MaxiDesignatedAnimation> {
  late MaxiAnimationController controller;
  AnimationScript? script;
  Disposable? currentAnimation;

  @override
  Result<void> performInitiation() {
    super.performInitiation();
    controller = widget.controller ?? MaxiAnimationController();
    script = widget.script;

    if (script != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playAnimation(script);
      });
    }

    return Result.ok;
  }

  void _playAnimation(AnimationScript? script) {
    if (currentAnimation != null) {
      currentAnimation!.dispose();
      currentAnimation = null;
    }

    if (script == null) return;

    currentAnimation = script.play(controller);
  }

  @override
  Widget build(BuildContext context) {
    return MaxiAnimationContainer(
      controller: controller,
      builder: widget.builder,
      duration: widget.duration,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(covariant MaxiDesignatedAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (controller != oldWidget.controller) {
      log('Warning: Controller changed, test it');
      controller = widget.controller ?? controller;
      _playAnimation(script);
    } else if (widget.script != oldWidget.script) {
      script = widget.script;
      if (script != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playAnimation(script);
        });
      }
    }
  }
}
