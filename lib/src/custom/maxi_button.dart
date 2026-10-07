import 'package:flutter/material.dart';

class MaxiButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final void Function()? onTouch;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final double padding;
  final double circularRadius;
  final FocusNode? focusNode;
  final double borderWidth;

  const MaxiButton({super.key, this.child, this.icon, this.onTouch, this.backgroundColor, this.padding = 2.0, this.circularRadius = 5.0, this.borderWidth = 1.0, this.focusNode, this.borderColor, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: OutlinedButton(
        onPressed: onTouch,
        focusNode: focusNode,

        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          overlayColor: borderColor?.withValues(alpha: 0.1),
          side: BorderSide(width: borderWidth, color: borderColor ?? Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(circularRadius),
          ),
        ),
        child: _generarContenido(context),
      ),
    );
  }

  Widget _generarContenido(BuildContext context) {
    if (icon == null && child == null) {
      return SizedBox();
    } else if (icon == null) {
      return child!;
    } else {
      return Flex(
        direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? borderColor),
          SizedBox(width: 5),
          Flexible(child: child!),
        ],
      );
    }
  }
}
