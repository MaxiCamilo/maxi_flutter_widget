import 'package:flutter/widgets.dart';

class TrackedScrollController extends ScrollController {
  TrackedScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
    this.onDispose,
  });

  final VoidCallback? onDispose;
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    if (_disposed) return; // evita doble dispose
    _disposed = true;
    super.dispose();
    onDispose?.call();
  }
}
