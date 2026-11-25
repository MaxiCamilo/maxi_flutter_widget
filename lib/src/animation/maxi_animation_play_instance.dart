import 'package:flutter/material.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiAnimationPlayInstance extends StatefulWidget {
  final MaxiAnim controller;
  final AnimationScript? script;
  final Object? keyScript;
  final List<Object> keyWatchRefresh;
  final bool autoPlay;
  final Widget Function(BuildContext context, MaxiAnim anim) builder;

  const new({
    super.key,
    required this.controller,
    required this.builder,
    this.script,
    this.keyScript,
    this.keyWatchRefresh = const [],
    this.autoPlay = true,
  });

  @override
  State<MaxiAnimationPlayInstance> createState() => _MaxiAnimationPlayInstanceState();
}

class _MaxiAnimationPlayInstanceState extends ReactiveState<MaxiAnimationPlayInstance> {
  int _currentKeyIndex = 0;
  late AnimationScript _currentScript;
  late AnimationScript? _currentAnimation;

  MaxiAnim? _currentAnim;

  @override
  Result<void> performInitiation() => resultScopeVoid(() {
    super.performInitiation().$;

    _currentAnimation = widget.autoPlay ? widget.script : null;

    _currentScript = KeyBuilderAnimationScript(
      key: _currentKeyIndex,
      script: _currentAnimation,
    );

    if (widget.keyScript != null) {
      widget.controller.controller.onChange.where((x) => x.$1 == widget.keyScript).map((x) => x.$2).listen((value) {
        if (value is AnimationScript) {
          _currentAnimation = value;
        }

        _updateAnimation();
      });
    }

    if (widget.keyWatchRefresh.isNotEmpty) {
      widget.controller.controller.onChange.where((x) => widget.keyWatchRefresh.contains(x.$1)).listen((_) => _updateAnimation());
    }
  });

  void _updateAnimation() {
    if (!mounted || heart.isDisposed) return;

    if (_currentKeyIndex == 0 && !widget.autoPlay && _currentAnimation == null) {
      _currentAnimation = widget.script;
    }

    _currentKeyIndex += 1;
    _currentScript = KeyBuilderAnimationScript(
      key: _currentKeyIndex,
      script: _currentAnimation,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaxiDesignatedAnimation(
      script: _currentScript,
      builder: (context, anim) {
        if (_currentAnim != anim) {
          if (widget.keyWatchRefresh.isNotEmpty) {
            anim.controller.onChange.where((x) => widget.keyWatchRefresh.contains(x.$1)).listen((_) {
              _updateAnimation();
            });
          }

          _currentAnim = anim;
        }
        return widget.builder(context, anim);
      },
    );
  }
}
