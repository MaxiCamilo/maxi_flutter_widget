import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiAnimatedContainer extends StatefulWidget {
  final Function(AnimationDirector)? onDirectorReady;
  final Widget Function(BuildContext builder, AnimationDirector director) childBuilder;
  final AnimationScriptInterface? animation;
  final bool loop;

  const MaxiAnimatedContainer({
    required this.childBuilder,
    super.key,
    this.onDirectorReady,
    this.animation,
    this.loop = false,
  });

  @override
  State<MaxiAnimatedContainer> createState() => _MaxiAnimatedContainerState();
}

class _MaxiAnimatedContainerState extends ReactiveSingleTickerState<MaxiAnimatedContainer> {
  late final AnimationDirector animationDirector;

  AnimationScriptInterface? _currentAnimation;

  bool _firstBuild = false;

  @override
  Result<void> performInitiation() => resultScopeVoid(() {
    super.performInitiation().$;
    animationDirector = heart.attachChild(AnimationDirector.onState(state: this, defaultCurve: Curves.linear, defaultDuration: const Duration(milliseconds: 300)));
    if (widget.onDirectorReady != null) {
      widget.onDirectorReady!(animationDirector);
    }
  });

  @override
  Widget build(BuildContext context) {
    if (!_firstBuild) {
      _firstBuild = true;
      if (widget.animation != null) {
        _currentAnimation = widget.animation;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.loop) {
            widget.animation!.executeLoop(animationDirector);
          } else {
            widget.animation!.execute(animationDirector);
          }
        });
      }
    }
    return widget.childBuilder(context, animationDirector);
  }

  @override
  void didUpdateWidget(MaxiAnimatedContainer old) {
    super.didUpdateWidget(old);
    if (_currentAnimation != widget.animation) {
      _currentAnimation = widget.animation;
      if (_currentAnimation == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentAnimation!.execute(animationDirector);
      });
    }
  }
}
