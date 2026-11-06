import 'package:flutter/widgets.dart';

extension BoxConstraintsExtension on BoxConstraints {
  double widthFactor(double f) {
    assert(hasBoundedWidth, 'El padre no tiene ancho acotado');
    return maxWidth * f;
  }

  double heightFactor(double f) {
    assert(hasBoundedHeight, 'El padre no tiene alto acotado');
    return maxHeight * f;
  }

  double widthFactorOnMax({double min = 0, double max = double.infinity, required double factor}) {
    assert(hasBoundedWidth, 'El padre no tiene ancho acotado');
    if (maxWidth < min) {
      return maxWidth;
    }

    if (maxWidth > max) {
      return max;
    }
    final dio = maxWidth * factor;
    if (dio < min) {
      return min;
    }
    if (dio > max) {
      return max;
    }
    return dio;
  }

  double heightFactorOnMax({double min = 0, double max = double.infinity, required double factor}) {
    assert(hasBoundedHeight, 'El padre no tiene alto acotado');
    if (maxHeight < min) {
      return maxHeight;
    }
    if (maxHeight > max) {
      return max;
    }
    final dio = maxHeight * factor;
    if (dio < min) {
      return min;
    }
    if (dio > max) {
      return max;
    }
    return dio;
  }
}
