import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiAnimatedContainer extends StatefulWidget {
  final Function(AnimationDirector)? onDirectorReady;
  final Widget Function(BuildContext builder, AnimationDirector director) childBuilder;
  final AnimationScriptInterface? animation;
  final Symbol? animationKey;
  final Symbol? loopKey;
  final bool loop;

  const MaxiAnimatedContainer({
    required this.childBuilder,
    super.key,
    this.onDirectorReady,
    this.animation,
    this.animationKey,
    this.loop = false,
    this.loopKey,
  });

  @override
  State<MaxiAnimatedContainer> createState() => _MaxiAnimatedContainerState();
}

class _MaxiAnimatedContainerState extends ReactiveSingleTickerState<MaxiAnimatedContainer> {
  late final AnimationDirector animationDirector;

  AnimationScriptInterface? _currentAnimation;
  Disposable? _currentScript;

  bool _activeAnimation = false;
  bool _firstBuild = false;
  bool _animationFinished = false;
  bool _isLooping = false;

  Symbol? _currentLoopKey;
  Symbol? _currentAnimationKey;

  StreamSubscription? _loopKeySubscription;
  StreamSubscription? _animationSubscription;

  bool _usingLoopKeyWidget = true;
  bool _usingAnimationKeyWidget = true;

  @override
  Result<void> performInitiation() => resultScopeVoid(() {
    super.performInitiation().$;

    _isLooping = widget.loop;

    _currentLoopKey = widget.loopKey;
    _currentAnimationKey = widget.animationKey;

    animationDirector = heart.attachChild(AnimationDirector.onState(state: this, defaultCurve: Curves.linear, defaultDuration: const Duration(milliseconds: 300)));
    if (widget.onDirectorReady != null) {
      widget.onDirectorReady!(animationDirector);
    }

    _connectEventKeys();
  });

  void _connectEventKeys() {
    _loopKeySubscription?.cancel();
    _animationSubscription?.cancel();

    if (_currentLoopKey != null) {
      _loopKeySubscription = animationDirector.buildValueListener<bool>(_currentLoopKey!).$.listen((value) {
        if (_isLooping == value) return;
        _isLooping = value;
        _usingLoopKeyWidget = false;
        _startAnimation();
      });
    }

    if (_currentAnimationKey != null) {
      _animationSubscription = animationDirector.buildValueListener<AnimationScriptInterface?>(_currentAnimationKey!).$.listen((value) {
        //if (_currentAnimation == value && _activeAnimation) return;
        _usingAnimationKeyWidget = false;
        _changeAnimation(value);
      });
    }
  }

  void _changeAnimation(AnimationScriptInterface? newAnimation) {
    _currentScript?.dispose();
    _currentScript = null;
    _currentAnimation = newAnimation;
    _animationFinished = false;
    if (_currentAnimation == null) return;
    _startAnimation();
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstBuild) {
      _firstBuild = true;
      if (widget.animation != null) {
        _currentAnimation = widget.animation;
        _startAnimation();
      } else if (widget.animationKey != null && animationDirector.contains(widget.animationKey!)) {
        _currentAnimation = animationDirector.$(widget.animationKey!);
        _startAnimation();
      }
    }
    return widget.childBuilder(context, animationDirector);
  }

  Future<void> _startAnimation() async {
    if (_activeAnimation) {
      return;
    }

    _activeAnimation = true;

    while (!isDisposed && _currentAnimation != null && (_isLooping || !_animationFinished)) {
      final waiter = Completer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final newScriptInstance = _currentAnimation!.execute(
          animationDirector,
          onFinished: () => waiter.complete(),
        );

        if (newScriptInstance is NegativeResult) {
          log('Failed to execute animation: $newScriptInstance');
          waiter.complete();
          return;
        }

        _currentScript = (heart.attachChild(newScriptInstance.$));
      });
      _animationFinished = true;
      await waiter.future;
    }

    _currentScript = null;
    _activeAnimation = false;
  }

  @override
  void didUpdateWidget(MaxiAnimatedContainer old) {
    super.didUpdateWidget(old);

    if (_currentLoopKey != widget.loopKey || _currentAnimationKey != widget.animationKey) {
      _currentLoopKey = widget.loopKey;
      _currentAnimationKey = widget.animationKey;
      _connectEventKeys();
    }

    bool change = false;

    if (_usingAnimationKeyWidget && _currentAnimation != widget.animation) {
      change = true;
      _currentAnimation = widget.animation;
    }

    if (_usingLoopKeyWidget && _isLooping != widget.loop) {
      change = true;
      _isLooping = widget.loop;
    }

    if (change) {
      _changeAnimation(_currentAnimation);
    }
  }
}
