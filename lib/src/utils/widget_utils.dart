import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';

mixin WidgetUtils {
  static Result<ui.Image> screenshotGpu({required GlobalKey key}) {
    if (key.currentContext == null) return Result.error("The current context has not been defined for the current key");

    final boundary = key.currentContext?.findRenderObject();
    if (boundary == null) return Result.error("The render object for the current key is not a RenderRepaintBoundary");

    if (boundary is! RenderRepaintBoundary) return Result.error("The render object for the current key is not a RenderRepaintBoundary");

    final ui.Image image = boundary.toImageSync(pixelRatio: MediaQuery.devicePixelRatioOf(key.currentContext!));

    return ResultValue(image);
  }

  static FutureResult<Uint8List> screenshotByte({required GlobalKey key}) => futureScope(() async {
    final image = screenshotGpu(key: key).$;
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) return Result.error("Failed to capture screenshot");

    return ResultValue(byteData.buffer.asUint8List());
  });
}
