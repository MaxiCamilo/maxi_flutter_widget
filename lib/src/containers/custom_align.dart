import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Positions its child within the space provided by its parent.
///
/// Axis convention:
/// - [x]: 0.0 center, 1.0 far left, -1.0 far right.
/// - [y]: 0.0 center, 1.0 bottom, -1.0 top.
///
/// Pixel offset ([pixelOffset]):
/// - Applied after the alignment.
/// - Positive dx moves right, positive dy moves down (screen coordinates).
///   Example: Offset(50, -50) → 50px to the right and 50px up.
/// - Does not change the size of this widget: the child may end up
///   partially outside its bounds.
///
/// Own size:
/// - On a bounded axis, it takes all the available space.
/// - On an unbounded axis (for example, the height inside a `Column`),
///   it shrinks to fit the child.
class CustomAlign extends SingleChildRenderObjectWidget {
  const CustomAlign({
    super.key,
    this.x = 0.0,
    this.y = 0.0,
    this.pixelOffset = Offset.zero,
    super.child,
  }); //: assert(x >= -1.0 && x <= 1.0, 'x must be between -1.0 and 1.0'),
  //assert(y >= -1.0 && y <= 1.0, 'y must be between -1.0 and 1.0');

  /// 0.0 center, 1.0 left, -1.0 right.
  final double x;

  /// 0.0 center, 1.0 bottom, -1.0 top.
  final double y;

  /// Shift in pixels, applied after the alignment.
  final Offset pixelOffset;

  @override
  RenderCustomAlign createRenderObject(BuildContext context) {
    return RenderCustomAlign(x: x, y: y, pixelOffset: pixelOffset);
  }

  // Flutter reuses the RenderObject across rebuilds:
  // here we only update its properties.
  @override
  void updateRenderObject(BuildContext context, RenderCustomAlign renderObject) {
    renderObject
      ..x = x
      ..y = y
      ..pixelOffset = pixelOffset;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('x', x, defaultValue: 0.0))
      ..add(DoubleProperty('y', y, defaultValue: 0.0))
      ..add(DiagnosticsProperty<Offset>('pixelOffset', pixelOffset, defaultValue: Offset.zero));
  }
}

/// RenderObject for [CustomAlign].
///
/// Extends [RenderShiftedBox], which already handles painting, hit testing
/// and intrinsic sizes using the offset stored in the child's `parentData`.
/// We only need to implement the layout.
class RenderCustomAlign extends RenderShiftedBox {
  RenderCustomAlign({
    this._x = 0.0,
    this._y = 0.0,
    this._pixelOffset = Offset.zero,
    RenderBox? child,
  }) : super(child);

  double get x => _x;
  double _x;
  set x(double value) {
    if (_x == value) return;
    _x = value;
    // The child's position changes, and it is computed during layout.
    markNeedsLayout();
  }

  double get y => _y;
  double _y;
  set y(double value) {
    if (_y == value) return;
    _y = value;
    markNeedsLayout();
  }

  Offset get pixelOffset => _pixelOffset;
  Offset _pixelOffset;
  set pixelOffset(Offset value) {
    if (_pixelOffset == value) return;
    _pixelOffset = value;
    markNeedsLayout();
  }

  /// Computes our own size from the constraints and the child's size.
  ///
  /// Shared by [performLayout] and [computeDryLayout] so that both
  /// always return the same result.
  Size _computeSize(BoxConstraints constraints, Size childSize) {
    return constraints.constrain(
      Size(
        constraints.hasBoundedWidth ? double.infinity : childSize.width,
        constraints.hasBoundedHeight ? double.infinity : childSize.height,
      ),
    );
  }

  /// Computes the child offset for one axis.
  ///
  /// Behavior:
  /// - 0.0: centered.
  /// - ±1.0: child center on container border (half outside).
  /// - ±2.0: child fully outside (hidden) on that side.
  double _computeAxisOffset({
    required double parentExtent,
    required double childExtent,
    required double value,
    required bool positiveGoesToStart,
  }) {
    late final double childCenter;

    if (value >= -1.0 && value <= 1.0) {
      childCenter = positiveGoesToStart
          ? parentExtent * (1.0 - value) / 2.0
          : parentExtent * (1.0 + value) / 2.0;
    } else if (value > 1.0) {
      childCenter = positiveGoesToStart
          ? -(value - 1.0) * childExtent / 2.0
          : parentExtent + (value - 1.0) * childExtent / 2.0;
    } else {
      childCenter = positiveGoesToStart
          ? parentExtent + (-value - 1.0) * childExtent / 2.0
          : -(-value - 1.0) * childExtent / 2.0;
    }

    return childCenter - childExtent / 2.0;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    final child = this.child;

    if (child == null) {
      size = _computeSize(constraints, Size.zero);
      return;
    }

    // 1. Constraints go down: the child may be smaller than us.
    //    parentUsesSize: true because we are going to read child.size.
    child.layout(constraints.loosen(), parentUsesSize: true);

    // 2. Sizes go up: our size depends on the child
    //    only on unbounded axes.
    size = _computeSize(constraints, child.size);

    // 3. The parent sets the position: split the free space based on x / y...
    /*
    final freeX = size.width - child.size.width;
    final freeY = size.height - child.size.height;

    late final double dx;
    late final double dy;

    if (_x < -1.0) {
      dx = (freeX * (_x - 1));
    } else {
      dx = freeX * (1.0 - _x) / 2.0;
    }

    if (_y < -1.0) {
      dy = (freeY * (_y - 1));
    } else {
      dy = freeY * (1.0 + _y) / 2.0;
    }

    final aligned = Offset(
      dx, //  1.0 → 0 (left), -1.0 → freeX (right)
      dy, // -1.0 → 0 (top),   1.0 → freeY (bottom)
    );*/


    // 3. The parent sets the position: split the free space based on x / y...
    
    final aligned = Offset(
      _computeAxisOffset(
        parentExtent: size.width,
        childExtent: child.size.width,
        value: _x,
        positiveGoesToStart: true,
      ),
      _computeAxisOffset(
        parentExtent: size.height,
        childExtent: child.size.height,
        value: _y,
        positiveGoesToStart: false,
      ),
    );

    // ...and then add the fixed pixel shift.
    final childParentData = child.parentData! as BoxParentData;
    childParentData.offset = aligned + _pixelOffset;
  }

  /// "Dry" layout: computes the size without moving anything.
  /// Used, for example, by IntrinsicHeight and some measuring widgets.
  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final childSize = child?.getDryLayout(constraints.loosen()) ?? Size.zero;
    return _computeSize(constraints, childSize);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('x', x, defaultValue: 0.0))
      ..add(DoubleProperty('y', y, defaultValue: 0.0))
      ..add(DiagnosticsProperty<Offset>('pixelOffset', pixelOffset, defaultValue: Offset.zero));
  }
}
