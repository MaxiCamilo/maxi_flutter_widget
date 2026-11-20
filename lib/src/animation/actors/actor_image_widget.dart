import 'package:flutter/widgets.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ActorImageWidget extends MaxiAbstractActor {
  final ImageProvider source;
  final double? width;
  final double? height;
  final AlignmentGeometry imageAlignment;
  final ImageRepeat repeat;

  const new({
    required super.tag,
    required this.source,
    this.imageAlignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,

    this.width,
    this.height,
    super.alignment,
    super.offset,
    super.scale,
    super.opacity,
    super.ratio,
    super.angle,
  });

  @override
  Widget build(BuildContext context, BoxConstraints constraints, MaxiAnim anim) {
    return Image(
      image: source,
      width: width,
      height: height,
      alignment: imageAlignment,
      repeat: repeat,
    );
  }
}

class ActorSVGWidget extends MaxiAbstractActor {
  final String imageAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry imageAlignment;
  final Clip clipBehavior;

  const ActorSVGWidget({
    required super.tag,
    required this.imageAsset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.imageAlignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
    super.alignment,
    super.offset,
    super.scale,
    super.opacity,
    super.ratio,
    super.angle,
  });

  @override
  Widget build(BuildContext context, BoxConstraints constraints, MaxiAnim anim) {
    return SvgPicture.asset(
      imageAsset,
      width: width,
      height: height,
      fit: fit,
      alignment: imageAlignment,
      clipBehavior: clipBehavior,
    );
  }
}
