import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Hace un crossfade entre el hijo anterior y el nuevo.
///
/// El tamaño lo define siempre el hijo actual (animado con [AnimatedSize]).
/// El hijo anterior se muestra como una captura centrada que puede
/// sobresalir sin agrandar el widget.
///
/// Igual que [AnimatedSwitcher], la animación se dispara cuando cambia el
/// tipo o la key del hijo. Para widgets del mismo tipo usá keys distintas:
/// `Text(texto, key: ValueKey(texto))`.
class OneStackView extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const OneStackView({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<OneStackView> createState() => _OneStackViewState();
}

class _OneStackViewState extends State<OneStackView> with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  )..addStatusListener(_onStatus);

  late CurvedAnimation _anim = CurvedAnimation(parent: _ctrl, curve: widget.curve);

  /// Lo que realmente se pinta. Puede ir un frame atrasado respecto de
  /// widget.child mientras se espera para capturar.
  late Widget _child = widget.child;
  bool _swapScheduled = false;

  ui.Image? _snapshot;
  double _dpr = 1;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _snapshot != null) {
      setState(_clearSnapshot); // Terminó: se libera la captura.
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

    if (old.curve != widget.curve) {
      _anim.dispose();
      _anim = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    }

    if (Widget.canUpdate(_child, widget.child)) {
      _child = widget.child;
      return;
    }

    // Cambio de widget: este frame se sigue pintando el viejo.
    // La captura se hace después del paint, cuando la capa está limpia.
    if (_swapScheduled) return;
    _swapScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndSwap());
  }

  void _captureAndSwap() {
    _swapScheduled = false;
    if (!mounted) return;

    // Por si mientras tanto volvió al mismo widget.
    if (Widget.canUpdate(_child, widget.child)) {
      setState(() => _child = widget.child);
      return;
    }

    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    _clearSnapshot();
    if (boundary != null && boundary.hasSize) {
      // Después del paint: la capa contiene el widget viejo, totalmente opaco
      // (el FadeTransition está afuera del boundary).
      _snapshot = boundary.toImageSync(pixelRatio: _dpr);
    }

    setState(() => _child = widget.child);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _clearSnapshot();
    _anim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _dpr = MediaQuery.devicePixelRatioOf(context);

    return AnimatedSize(
      duration: widget.duration,
      curve: widget.curve,
      clipBehavior: Clip.none, // Si no, recorta lo que sobresale.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hijo nuevo: aparece. El fade va AFUERA del boundary para que
          // una captura a mitad de animación no salga semitransparente.
          FadeTransition(
            opacity: _anim,
            child: RepaintBoundary(
              key: _boundaryKey,
              child: _child,
            ),
          ),
          // Hijo viejo (captura): desaparece, centrado, sin afectar el tamaño.
          Positioned.fill(
            child: IgnorePointer(
              // RawImage acepta toques; sin esto bloquea al hijo nuevo
              // mientras dura la animación.
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: Alignment.center,
                child: _snapshot == null
                    ? const SizedBox()
                    : FadeTransition(
                        opacity: ReverseAnimation(_anim),
                        child: RawImage(image: _snapshot, scale: _dpr),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
