import 'package:flutter/widgets.dart';

abstract interface class MaxiSizeStack {
  bool get requiredBuildLayout;
  (double? width, double? height) calculateSize(BuildContext context, Widget child);
}
