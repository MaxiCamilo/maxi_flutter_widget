import 'package:flutter/widgets.dart';

class ParentConstraints extends InheritedWidget {
  const ParentConstraints({
    super.key,
    required this.constraints,
    required super.child,
  });

  final BoxConstraints constraints;

  static BoxConstraints of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<ParentConstraints>();
    assert(w != null, 'No ConstraintsScope found above in the tree');
    return w!.constraints;
  }

  static BoxConstraints? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ParentConstraints>()?.constraints;

  @override
  bool updateShouldNotify(ParentConstraints old) => constraints != old.constraints;
}

class ConstraintsScope extends StatelessWidget {
  const ConstraintsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ParentConstraints(
        constraints: constraints,
        child: child,
      ),
    );
  }
}
