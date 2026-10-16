import 'package:flutter/material.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';

class MaxiButton extends StatelessWidget {
  final IconData? icon;
  final Oration? text;
  final bool enabled;
  final void Function()? onTouch;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? textColor;
  final double padding;
  final double circularRadius;
  final FocusNode? focusNode;
  final double borderWidth;
  final double alphaOverlayColor;

  const MaxiButton({
    super.key,
    this.text,
    this.color,
    this.icon,
    this.enabled = true,
    this.onTouch,
    this.backgroundColor,
    this.padding = 2.0,
    this.circularRadius = 5.0,
    this.borderWidth = 1.0,
    this.alphaOverlayColor = 0.1,
    this.focusNode,
    this.borderColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: OutlinedButton(
        onPressed: enabled ? onTouch : null,
        focusNode: focusNode,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          overlayColor: (borderColor ?? color)?.withValues(alpha: alphaOverlayColor),
          side: BorderSide(width: borderWidth, color: (borderColor ?? color) ?? Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(circularRadius),
          ),
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (icon == null && text == null) {
      return SizedBox();
    } else if (icon == null) {
      return Text(text.toString(), style: TextStyle(color: textColor ?? color));
    } else {
      return Flex(
        direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? (borderColor ?? color)),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              text.toString(),
              style: TextStyle(color: textColor ?? color),
            ),
          ),
        ],
      );
    }
  }
}
