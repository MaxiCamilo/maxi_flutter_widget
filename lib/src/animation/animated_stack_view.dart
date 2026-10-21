import 'package:flutter/widgets.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class AnimatedStackView extends StatefulWidget {
  final AnimationScript appearanceAnimation;
  final AnimationScript disappearanceAnimation;
  final Widget child;
  const new({
    Key? key,
    required this.appearanceAnimation,
    required this.disappearanceAnimation,
    required this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AnimatedStackViewState();
}

class _AnimatedStackViewState extends ReactiveState<AnimatedStackView> {
  


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
