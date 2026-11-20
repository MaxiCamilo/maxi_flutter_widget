import 'package:flutter/widgets.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

import 'dart:math' as math show pi;

double _gradesToRadials(double grades) => grades * math.pi / 180;

@immutable
abstract interface class MaxiActor {
  MaxiActorInstance buildInstance();
}

abstract interface class MaxiActorInstance<T extends MaxiActor> {
  Widget build(BuildContext context, BoxConstraints constraints, MaxiAnim anim);
}

class ActorWidget implements MaxiActor {
  final String tag;
  final AlignmentGeometry alignment;
  final Offset offset;
  final double scale;
  final double opacity;
  final Widget child;
  final double ratio;
  final double angle;

  const new({
    required this.tag,
    required this.child,
    this.alignment = Alignment.center,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.opacity = 1.0,

    this.ratio = 1.0,
    this.angle = 0.0,
  });

  @override
  MaxiActorInstance<MaxiActor> buildInstance() {
    return _ActorWidgetInstance(this);
  }
}

class _ActorWidgetInstance implements MaxiActorInstance<ActorWidget> {
  final ActorWidget actor;

  late final String alignmentTag = '${actor.tag}_alignment';
  late final String offsetTag = '${actor.tag}_offset';
  late final String scaleTag = '${actor.tag}_scale';
  late final String opacityTag = '${actor.tag}_opacity';
  late final String ratioTag = '${actor.tag}_ratio';
  late final String angleTag = '${actor.tag}_angle';

  _ActorWidgetInstance(this.actor);

  @override
  Widget build(BuildContext context, BoxConstraints constraints, MaxiAnim anim) {
    return Align(
      alignment: anim.listen(alignmentTag, actor.alignment),

      child: FractionalTranslation(
        translation: anim.listen(offsetTag, actor.offset),
        child: Transform.scale(
          scale: anim.listen<double>(scaleTag, actor.scale),

          child: Transform.rotate(
            angle: _gradesToRadials(anim.listen<double>(angleTag, actor.angle)),
            child: Opacity(
              opacity: anim.listen<double>(opacityTag, actor.opacity),
              child: actor.child,
            ),
          ),
        ),
      ),
    );
  }
}

class ActorWidgetBuilder implements MaxiActor {
  final String tag;
  final AlignmentGeometry alignment;
  final Offset offset;
  final double scale;
  final double opacity;

  final double ratio;
  final double angle;
  final Widget Function(BuildContext context, BoxConstraints constraints, MaxiAnim anim) builder;

  const new({
    required this.tag,
    required this.builder,
    this.alignment = Alignment.center,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.opacity = 1.0,

    this.ratio = 1.0,
    this.angle = 0.0,
  });

  @override
  MaxiActorInstance<MaxiActor> buildInstance() {
    return _ActorWidgetBuilderInstance(this);
  }
}

class _ActorWidgetBuilderInstance implements MaxiActorInstance<ActorWidgetBuilder> {
  final ActorWidgetBuilder actor;

  late final String alignmentTag = '${actor.tag}_alignment';
  late final String offsetTag = '${actor.tag}_offset';
  late final String scaleTag = '${actor.tag}_scale';
  late final String opacityTag = '${actor.tag}_opacity';
  late final String ratioTag = '${actor.tag}_ratio';
  late final String angleTag = '${actor.tag}_angle';

  _ActorWidgetBuilderInstance(this.actor);

  @override
  Widget build(BuildContext context, BoxConstraints constraints, MaxiAnim anim) {
    return Align(
      alignment: anim.listen(alignmentTag, actor.alignment),

      child: FractionalTranslation(
        translation: anim.listen(offsetTag, actor.offset),
        child: Transform.scale(
          scale: anim.listen<double>(scaleTag, actor.scale),

          child: Transform.rotate(
            angle: _gradesToRadials(anim.listen<double>(angleTag, actor.angle)),
            child: Opacity(
              opacity: anim.listen<double>(opacityTag, actor.opacity),
              child: actor.builder(context, constraints, anim),
            ),
          ),
        ),
      ),
    );
  }
}

abstract class MaxiAbstractActor implements MaxiActor {
  final String tag;
  final AlignmentGeometry alignment;
  final Offset offset;
  final double scale;
  final double opacity;

  final double ratio;
  final double angle;

  const MaxiAbstractActor({
    required this.tag,
    this.alignment = Alignment.center,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.ratio = 1.0,
    this.angle = 0.0,
  });

  @protected
  Widget build(BuildContext context, BoxConstraints constraints, MaxiAnim anim);

  @override
  MaxiActorInstance<MaxiActor> buildInstance() => _MaxiAbstractActorInstance(this);
}

class _MaxiAbstractActorInstance implements MaxiActorInstance<MaxiAbstractActor> {
  final MaxiAbstractActor actor;

  late final String alignmentTag = '${actor.tag}_alignment';
  late final String offsetTag = '${actor.tag}_offset';
  late final String scaleTag = '${actor.tag}_scale';
  late final String opacityTag = '${actor.tag}_opacity';
  late final String ratioTag = '${actor.tag}_ratio';
  late final String angleTag = '${actor.tag}_angle';

  _MaxiAbstractActorInstance(this.actor);

  @override
  Widget build(BuildContext context, BoxConstraints constraints, MaxiAnim anim) {
    return Align(
      alignment: anim.listen(alignmentTag, actor.alignment),

      child: FractionalTranslation(
        translation: anim.listen(offsetTag, actor.offset),
        child: Transform.scale(
          scale: anim.listen<double>(scaleTag, actor.scale),

          child: Transform.rotate(
            angle: _gradesToRadials(anim.listen<double>(angleTag, actor.angle)),
            child: Opacity(
              opacity: anim.listen<double>(opacityTag, actor.opacity),
              child: actor.build(context, constraints, anim),
            ),
          ),
        ),
      ),
    );
  }
}
