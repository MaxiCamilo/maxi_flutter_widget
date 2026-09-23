import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

abstract interface class DynamicViewController {
  Result<void> changeWidget(Widget newWidget);
  Result<void> change({Widget? widget, Duration? duration, Curve? curve});
}

class DynamicView extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Function(DynamicViewController)? onControllerCreated;
  final Stream<Widget> Function()? widgetStream;

  const DynamicView({
    super.key,
    required this.child,
    this.onControllerCreated,
    this.widgetStream,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<DynamicView> createState() => _DynamicViewState();
}

class _DynamicViewState extends ReactiveState<DynamicView> implements DynamicViewController {
  late Widget currentWidget;
  late Duration duration;
  late Curve curve;

  int _id = 0;

  @override
  Result<void> performInitiation() {
    currentWidget = widget.child;
    duration = widget.duration;
    curve = widget.curve;

    if (widget.widgetStream != null) {
      final stream = widget.widgetStream!();
      heart.attachStream(
        stream: stream,
        onData: (x) {
          _id += 1;
          currentWidget = SizedBox(key: ValueKey(_id), child: x);
          setState(() {});
        },
      );
    }

    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(this);
    }

    return super.performInitiation();
  }

  @override
  Widget build(BuildContext context) {
    return OneStackView(duration: duration, curve: curve, child: currentWidget);
  }

  @override
  Result<void> changeWidget(Widget newWidget) => resultScopeVoid(() {
    checkDisposed().$;
    _id += 1;
    currentWidget = SizedBox(key: ValueKey(_id), child: newWidget);
    setState(() {});
  });

  @override
  Result<void> change({Widget? widget, Duration? duration, Curve? curve}) => resultScopeVoid(() {
    checkDisposed().$;

    bool changed = false;
    if (widget != null) {
      _id += 1;
      currentWidget = SizedBox(key: ValueKey(_id), child: widget);
      changed = true;
    }
    if (duration != null) {
      this.duration = duration;
      changed = true;
    }
    if (curve != null) {
      this.curve = curve;
      changed = true;
    }
    if (changed) {
      setState(() {});
    }
  });
}
