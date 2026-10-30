import 'package:flutter/widgets.dart';

abstract interface class MaxiPosicionedStack {
  bool get requiredBuildLayout;

  // x and y = 0 is Center, -1 is start/top, 1 is end/bottom
  (double x, double y) calculatePosition(BuildContext context, Widget child);

  static BoxConstraints obtainParentContraints(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    return BoxConstraints.tight(renderBox.size);
  }
}
