import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class OneStackView extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const OneStackView({super.key, required this.child, this.duration = const Duration(milliseconds: 300), this.curve = Curves.easeInOut});

  @override
  State<OneStackView> createState() => _OneStackViewState();
}

class _OneStackViewState extends State<OneStackView> with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();

  late final _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1, // arranca "terminada": el primer child se ve sin animar
  )..addStatusListener(_onStatus);

  late final Animation<double> _anim = CurvedAnimation(parent: _ctrl, curve: widget.curve);

  ui.Image? _snapshot;
  Size _snapshotSize = Size.zero;
  double _dpr = 1;

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && _snapshot != null) {
      setState(_clearSnapshot); // terminó: se libera la captura
    }
  }

  void _clearSnapshot() {
    _snapshot?.dispose();
    _snapshot = null;
  }

  @override
  void didUpdateWidget(OneStackView old) {
    super.didUpdateWidget(old);
    _ctrl.duration = widget.duration;

    if (Widget.canUpdate(old.child, widget.child)) return;

    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return;

    _clearSnapshot();
    _snapshot = boundary.toImageSync(pixelRatio: _dpr);
    _snapshotSize = boundary.size;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _clearSnapshot();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _dpr = MediaQuery.devicePixelRatioOf(context);
    final snap = _snapshot;

    return Stack(
      clipBehavior: Clip.none, 
      children: [
        FadeTransition(
          opacity: _anim,
          child: RepaintBoundary(key: _boundaryKey, child: widget.child),
        ),
        if (snap != null)
          Positioned(
            left: 0,
            top: 0,
            width: _snapshotSize.width,
            height: _snapshotSize.height,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: ReverseAnimation(_anim),
                child: RawImage(image: snap, fit: BoxFit.fill),
              ),
            ),
          ),
      ],
    );
  }
}
