import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';

class ScrollTrigger with DisposableMixin, WithLifecycleScopeMixin {
  ScrollController? _controller;
  StreamController<double>? _scrollStreamController;
  StreamController<ScrollTrigger>? _onAttachStreamController;

  bool get isAttached => _controller != null;

  double get offset => _controller?.offset ?? 0;
  double get viewportDimension => _controller?.hasClients == true ? _controller!.position.viewportDimension : 0;
  double get remainingScrollExtent => _controller?.hasClients == true ? _controller!.position.maxScrollExtent - offset : 0;
  double get maxScrollExtent => _controller?.hasClients == true ? _controller!.position.maxScrollExtent : 0;
  double get minScrollExtent => _controller?.hasClients == true ? _controller!.position.minScrollExtent : 0;

  bool get isAtTop => _controller?.hasClients == true && _controller!.offset <= 0;
  bool get isAtBottom => _controller?.hasClients == true && _controller!.offset >= _controller!.position.maxScrollExtent;
  bool get isBetweenTopAndBottom => _controller?.hasClients == true && !isAtTop && !isAtBottom;

  Stream<double> get notificationChange async* {
    if (isDisposed) {
      log('Warning: Attempted to access notificationChange stream after disposal');
      return;
    }

    _scrollStreamController ??= heart.attachStreamController(StreamController<double>.broadcast());

    yield* _scrollStreamController!.stream;
  }

  ScrollTrigger({
    ScrollController? controller,
  }) {
    if (controller != null) {
      attach(controller);
    }
  }

  void onAttach(void Function(ScrollTrigger) callback) {
    _onAttachStreamController ??= heart.attachStreamController(StreamController<ScrollTrigger>.broadcast());
    _onAttachStreamController!.stream.listen((x) {
      callback(x);
      _onAttachStreamController?.close();
    });
  }

  void attach(ScrollController controller) {
    if (isDisposed) {
      log('Warning: Attempted to attach after disposal');
      return;
    }

    if (_controller != null) {
      log('Warning: Detaching from previous ScrollController');
      _controller!.removeListener(_onScroll);
    }

    _controller = controller;
    _controller!.addListener(_onScroll);

    _scrollStreamController ??= heart.attachStreamController(StreamController<double>.broadcast());

    if (_onAttachStreamController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_onAttachStreamController != null) {
          _onAttachStreamController!.add(this);
        }
      });
    }

    heart.onDispose(() {
      _controller?.removeListener(_onScroll);
      _controller = null;
    });
  }

  void jumpTo(double offset) {
    if (isDisposed) {
      log('Warning: Attempted to jumpTo after disposal');
      return;
    }
    _controller?.jumpTo(offset);
  }

  void animateTo(double offset, {required Duration duration, required Curve curve}) {
    if (isDisposed) {
      log('Warning: Attempted to animateTo after disposal');
      return;
    }
    _controller?.animateTo(offset, duration: duration, curve: curve);
  }

  void _onScroll() {
    _scrollStreamController?.add(offset);
  }
}
