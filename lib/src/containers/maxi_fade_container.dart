import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

class MaxiFadeContainer extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final Curve curve;

  const MaxiFadeContainer({
    super.key,
    required this.child,
    this.show = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
  });

  @override
  State<MaxiFadeContainer> createState() => _MaxiFadeContainerState();
}

class _MaxiFadeContainerState extends ReactiveState<MaxiFadeContainer> {
  late DynamicViewController controller;
  late Widget currentChild;
  late bool isShown;

  @override
  Result<void> performInitiation() => resultScopeVoid(() {
    super.performInitiation().$;
    currentChild = widget.show ? widget.child : const SizedBox.shrink();
    isShown = widget.show;
  });

  @override
  Widget build(BuildContext context) {
    return DynamicView(
      onControllerCreated: (ctrl) => controller = ctrl,
      curve: widget.curve,
      duration: widget.duration,
      child: currentChild,
    );
  }

  @override
  void didUpdateWidget(MaxiFadeContainer old) {
    super.didUpdateWidget(old);
    if (isShown != widget.show) {
      isShown = widget.show;
      currentChild = isShown ? widget.child : const SizedBox.shrink();
      controller.change(widget: currentChild, curve: widget.curve, duration: widget.duration);
      return;
    }

    if (!isShown) {
      return;
    }

    if (widget.child.runtimeType != currentChild.runtimeType || widget.child.key != currentChild.key) {
      currentChild = widget.child;
      controller.change(widget: currentChild, curve: widget.curve, duration: widget.duration);
      return;
    }
  }
}
