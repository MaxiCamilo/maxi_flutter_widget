import 'package:flutter/widgets.dart';

extension BuildContextExtensions on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  double calculateReducedSize({
    required double size,
    required double width,
    double minimum = 0,
  }) {
    final screenWidth = this.screenWidth;
    if (screenWidth >= width || width <= 0) return size;

    final percentageDifference = (width - screenWidth) / width;
    final reducedSize = size * percentageDifference;
    final finalSize = size - reducedSize;
    return finalSize < minimum ? minimum : finalSize;
  }

  double calculateExtendedSize({
    required double size,
    required double width,
  }) {
    final screenWidth = this.screenWidth;
    if (screenWidth >= width || width <= 0) return size;

    final percentageDifference = (width - screenWidth) / width;
    final extendedSize = size * (1 + percentageDifference);
    return extendedSize;
  }
}
