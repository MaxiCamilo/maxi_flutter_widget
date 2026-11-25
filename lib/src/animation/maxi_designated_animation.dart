import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiDesignatedAnimation extends StatefulWidget {
  final AnimationScript? script;
  final MaxiAnimationController? controller;
  final Widget Function(BuildContext context, MaxiAnim anim) builder;
  final Duration duration;
  final Curve curve;
  final Object? keyAnimation;

  final List<Object> keyWatchRefresh;

  const MaxiDesignatedAnimation({super.key, this.script, this.controller, required this.builder, this.duration = const Duration(milliseconds: 250), this.curve = Curves.easeInOut, this.keyAnimation, this.keyWatchRefresh = const []});

  @override
  State<MaxiDesignatedAnimation> createState() => _MaxiDesignatedAnimationState();
}

class _MaxiDesignatedAnimationState extends ReactiveSingleTickerState<MaxiDesignatedAnimation> {
  late MaxiAnimationController controller;
  AnimationScript? script;
  Disposable? currentAnimation;
  bool isInternalController = false;

  @override
  Result<void> performInitiation() => resultScopeVoid(() {
    super.performInitiation().$;
    controller = widget.controller ?? heart.attachChild(MaxiAnimationController());
    isInternalController = widget.controller == null;
    script = widget.script;

    if (script != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playAnimation(script);
      });
    }

    if (widget.keyWatchRefresh.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || heart.isDisposed) return;
        controller.onChange.where((event) => widget.keyWatchRefresh.contains(event.$1)).listen((event) {
          if (!mounted || heart.isDisposed) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _playAnimation(script);
          });
        });
      });
    }
  });

  void _playAnimation(AnimationScript? script) {
    /*
    if (currentAnimation != null) {
      currentAnimation!.dispose();
      currentAnimation = null;
    }

    if (script == null) return;

    currentAnimation = script.play(controller);*/
    currentAnimation?.dispose();
    currentAnimation = null;

    if (script == null || isDisposed) return; // el postFrameCallback puede llegar tarde

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
      if (isInternalController && widget.controller != null) {
        controller.dispose();
        isInternalController = false;
        controller = widget.controller!;
        _playAnimation(script);
        return;
      } else if (!isInternalController && widget.controller != controller) {
        controller = widget.controller!;
        _playAnimation(script);
        return;
      }
    }

    if (widget.script != oldWidget.script) {
      script = widget.script;
      if (script != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playAnimation(script);
        });
      }
    }
    if (widget.keyAnimation != oldWidget.keyAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playAnimation(script);
      });
    }
  }

  @override
  void performDisposal() {
    currentAnimation?.dispose();
    currentAnimation = null;
    super.performDisposal();
  }
}
