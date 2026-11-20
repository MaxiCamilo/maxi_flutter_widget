import 'package:flutter/widgets.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiScenario extends StatefulWidget {
  final StackFit fit;
  final Clip clipBehavior;
  final Widget Function(BuildContext, BoxConstraints, MaxiAnim, Widget)? backgroundBuilder;
  final BoxDecoration? backgroundDecoration;
  final AnimationScript? script;
  final EdgeInsetsGeometry? padding;
  final bool expand;
  final List<MaxiActor> actors;

  const MaxiScenario._({
    super.key,
    required this.actors,
    required this.expand,
    this.fit = StackFit.expand,
    this.clipBehavior = Clip.hardEdge,
    this.backgroundDecoration,
    this.script,
    this.padding,
    this.backgroundBuilder,
  });

  const MaxiScenario.backgroundBuilder({
    Key? key,
    required List<MaxiActor> actors,
    required bool expand,
    required Widget Function(BuildContext, BoxConstraints, MaxiAnim, Widget) backgroundBuilder,
    StackFit fit = StackFit.expand,
    Clip clipBehavior = Clip.hardEdge,
    BoxDecoration? backgroundDecoration,
    AnimationScript? script,
    EdgeInsetsGeometry? padding,
    
  }) : this._(
         key: key,
         actors: actors,
         fit: fit,
         clipBehavior: clipBehavior,
         backgroundDecoration: backgroundDecoration,
         script: script,
         padding: padding,
         expand: expand,
         backgroundBuilder: backgroundBuilder,
       );

  const MaxiScenario.expand({
    Key? key,
    required List<MaxiActor> actors,
    StackFit fit = StackFit.expand,
    Clip clipBehavior = Clip.hardEdge,
    BoxDecoration? backgroundDecoration,
    AnimationScript? script,
    EdgeInsetsGeometry? padding,
  }) : this._(
         key: key,
         actors: actors,
         fit: fit,
         clipBehavior: clipBehavior,
         backgroundDecoration: backgroundDecoration,
         script: script,
         padding: padding,
         expand: true,
       );
  const MaxiScenario.single({
    Key? key,
    required List<MaxiActor> actors,
    StackFit fit = StackFit.expand,
    Clip clipBehavior = Clip.hardEdge,
    BoxDecoration? backgroundDecoration,
    AnimationScript? script,
    EdgeInsetsGeometry? padding,
    Widget Function(BuildContext, BoxConstraints, MaxiAnim, Widget)? backgroundBuilder,
  }) : this._(
         key: key,
         actors: actors,
         fit: fit,
         clipBehavior: clipBehavior,
         backgroundDecoration: backgroundDecoration,
         script: script,
         padding: padding,
         expand: false,
         backgroundBuilder: backgroundBuilder,
       );

  @override
  State<MaxiScenario> createState() => _MaxiScenarioState();
}

class _MaxiScenarioState extends State<MaxiScenario> {
  final List<MaxiActorInstance> _instances = [];

  @override
  void initState() {
    super.initState();
    _updateInstances();
  }

  void _updateInstances() {
    _instances.clear();
    for (final actor in widget.actors) {
      _instances.add(actor.buildInstance());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.backgroundBuilder != null) {
      if (widget.expand) {
        return SizedBox.expand(
          child: MaxiLayoutAnimation(
            script: widget.script,
            builder: (context, constraints, anim) {
              final childrens = Stack(fit: widget.fit, clipBehavior: widget.clipBehavior, children: _instances.map((instance) => instance.build(context, constraints, anim)).toList());
              return widget.backgroundBuilder!(context, constraints, anim, childrens);
            },
          ),
        );
      } else {
        return MaxiLayoutAnimation(
          script: widget.script,
          builder: (context, constraints, anim) {
            final childrens = Stack(fit: widget.fit, clipBehavior: widget.clipBehavior, children: _instances.map((instance) => instance.build(context, constraints, anim)).toList());
            return widget.backgroundBuilder!(context, constraints, anim, childrens);
          },
        );
      }
    } else if (widget.expand) {
      return SizedBox.expand(
        child: MaxiLayoutAnimation(
          script: widget.script,
          builder: (context, constraints, anim) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              padding: widget.padding,
              decoration: widget.backgroundDecoration,
              child: Stack(fit: widget.fit, clipBehavior: widget.clipBehavior, children: _instances.map((instance) => instance.build(context, constraints, anim)).toList()),
            );
          },
        ),
      );
    } else {
      return MaxiLayoutAnimation(
        script: widget.script,
        builder: (context, constraints, anim) {
          return Container(
            padding: widget.padding,
            decoration: widget.backgroundDecoration,
            child: Stack(fit: widget.fit, clipBehavior: widget.clipBehavior, children: _instances.map((instance) => instance.build(context, constraints, anim)).toList()),
          );
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant MaxiScenario oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actors != widget.actors) {
      _updateInstances();
      if (mounted) {
        setState(() {});
      }
    }
  }
}
