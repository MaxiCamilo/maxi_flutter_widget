import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiLayoutAnimation extends StatefulWidget {
  final AnimationScript? script;
  final MaxiAnimationController? controller;
  final Widget Function(BuildContext context, BoxConstraints constraints, MaxiAnim anim) builder;
  final Duration duration;
  final Curve curve;
  final Object? keyAnimation;
  final List<Object> keyWatchRefresh;

  const new({
    super.key,
    this.script,
    this.controller,
    required this.builder,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOut,
    this.keyAnimation,
    this.keyWatchRefresh = const [],
  });

  @override
  State<MaxiLayoutAnimation> createState() => _MaxiLayoutAnimationState();
}

class _MaxiLayoutAnimationState extends ReactiveState<MaxiLayoutAnimation> {
  late MaxiAnimationController controller;
  AnimationScript? script;

  @override
  Result<void> performInitiation() => resultScopeVoid(() {
    super.performInitiation().$;
    controller = widget.controller ?? heart.attachChild(MaxiAnimationController());
    script = widget.script;
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MaxiDesignatedAnimation(
        script: script,
        controller: controller,
        duration: widget.duration,
        curve: widget.curve,
        keyAnimation: widget.keyAnimation,
        keyWatchRefresh: widget.keyWatchRefresh,
        builder: (context, anim) => widget.builder(context, constraints, anim),
      ),
    );
  }
}
