import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

abstract interface class DoppelgangerController {
  Result<void> showOriginal();
  Result<void> showFake();
}

class Doppelganger extends StatefulWidget {
  final bool showFake;
  final Widget Function() childBuilder;
  final void Function(DoppelgangerController)? onControllerCreated;

  const new({super.key, this.showFake = false, required this.childBuilder, this.onControllerCreated});

  @override
  State<Doppelganger> createState() => _DoppelgangerState();
}

class _DoppelgangerState extends ReactiveState<Doppelganger> implements DoppelgangerController {
  final GlobalKey _captureKey = GlobalKey();

  late Widget _child;

  bool _init = false;

  ui.Image? _capturedImage;

  bool get isShowingFake => _capturedImage != null;

  @override
  Widget build(BuildContext context) {
    if (!_init) {
      _child = widget.childBuilder();
      _init = true;
      if (widget.showFake) {
        WidgetsBinding.instance.endOfFrame.then((_) => showFake());
      }

      if (widget.onControllerCreated != null) {
        WidgetsBinding.instance.endOfFrame.then((_) => widget.onControllerCreated!(this));
      }
    }

    return _capturedImage == null ? RepaintBoundary(key: _captureKey, child: _child) : RawImage(image: _capturedImage);
  }

  @override
  Result<void> showOriginal() => resultScopeVoid(() {
    checkDisposed().$;

    _child = widget.childBuilder();

    _capturedImage?.dispose();
    _capturedImage = null;

    setState(() {});
  });

  @override
  Result<void> showFake() => resultScopeVoid(() {
    checkDisposed().$;
    if (_capturedImage != null) return;

    _capturedImage = WidgetUtils.screenshotGpu(key: _captureKey).$;
    setState(() {});
  });

  @override
  void performDisposal() {
    super.performDisposal();
    _capturedImage?.dispose();
  }
}
