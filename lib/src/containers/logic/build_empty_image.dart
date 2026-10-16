import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Image, PixelFormat, decodeImageFromPixels;

import 'package:maxi_dart_framework/maxi_dart_framework.dart';

final class BuildEmptyImage extends Functionality<ui.Image> {
  final int width;
  final int height;

  BuildEmptyImage({
    required this.width,
    required this.height,
  });

  @override
  FutureResult<ui.Image> performExecution(ILifecycleScope scope) => futureScopeValue(() async {
    final pixels = Uint8List(width * height * 4); // RGBA8888

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        final on = (x + y).isEven; // patrón ajedrez
        pixels[i + 0] = on ? 255 : 0; // R
        pixels[i + 1] = 0; // G
        pixels[i + 2] = on ? 0 : 255; // B
        pixels[i + 3] = 255; // A
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  });
}
