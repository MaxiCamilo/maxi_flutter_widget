import 'package:flutter/widgets.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiCenterOf implements MaxiPosicionedStack {
  final (double horizontal, double vertical) pixels;
  final (double horizontal, double vertical) percentage;

  const new() : pixels = (0.0, 0.0), percentage = (0.0, 0.0);

  const MaxiCenterOf.pixels({double horizontal = 0.0, double vertical = 0.0}) : pixels = (horizontal, vertical), percentage = (0.0, 0.0);
  // 0 = center, 1.0 = edge, -1.0 = opposite edge
  const MaxiCenterOf.percentage({double horizontal = 0.0, double vertical = 0.0}) : percentage = (horizontal, vertical), pixels = (0.0, 0.0);

  @override
  bool get requiredBuildLayout => pixels != (0.0, 0.0);

  @override
  (double, double) calculatePosition(BuildContext context, Widget child) {
    if (percentage != (0.0, 0.0)) {
      return percentage; //<-- Center with percentage offset
    }

    if (pixels != (0.0, 0.0)) {
      return (0, 0); //<-- Center with pixel offset
    }

    return (0.0, 0.0); //<-- Center
  }
}
