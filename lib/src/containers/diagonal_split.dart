import 'package:flutter/widgets.dart';

/// Hacia dónde apunta la punta del primer widget dentro de la franja.
///
/// - [Axis.horizontal] (first a la izquierda): [topRight] o [bottomRight].
/// - [Axis.vertical] (first arriba): [bottomLeft] o [bottomRight].
enum DiagonalDirection { topRight, bottomRight, bottomLeft }

/// Cuál de los dos widgets queda arriba (y es el que se recorta en diagonal).
enum DiagonalOverlap { first, second }

/// Dos widgets contiguos (lado a lado o uno sobre otro) separados por una
/// diagonal. No pinta ningún color: en la franja de [space] píxeles ambos
/// widgets se superponen y el de arriba se recorta con un triángulo rectángulo.
///
/// Necesita ancho y alto acotados (SizedBox, Expanded, etc.).
class DiagonalSplit extends StatelessWidget {
  const DiagonalSplit({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.space = 60,
    this.ratio = 0.5,
    this.firstExtent,
    this.secondExtent,
    this.direction = DiagonalDirection.bottomRight,
    this.overlap = DiagonalOverlap.second,
  }) : assert(
          axis == Axis.horizontal
              ? direction != DiagonalDirection.bottomLeft
              : direction != DiagonalDirection.topRight,
          'horizontal admite topRight/bottomRight; '
          'vertical admite bottomLeft/bottomRight',
        );

  final Widget first;
  final Widget second;

  /// horizontal: first a la izquierda, second a la derecha.
  /// vertical: first arriba, second abajo.
  final Axis axis;

  /// Tamaño de la franja diagonal sobre el eje principal
  /// (ancho en horizontal, alto en vertical).
  final double space;

  /// Reparto del espacio restante: 0.5 = mitad y mitad, 0.3 = first más chico.
  final double ratio;

  /// Tamaño fijo de first sobre el eje principal (franja incluida).
  /// Si se define, reemplaza a [ratio] y second ocupa el resto. Si no entra,
  /// se limita al espacio disponible (funciona como máximo).
  final double? firstExtent;

  /// Igual que [firstExtent] pero para second: tamaño fijo (máximo) de
  /// second, franja incluida, y first ocupa el resto. Si se definen los dos,
  /// gana [firstExtent].
  final double? secondExtent;

  final DiagonalDirection direction;
  final DiagonalOverlap overlap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = axis == Axis.horizontal;
        final extent =
            horizontal ? constraints.maxWidth : constraints.maxHeight;
        final band = space.clamp(0.0, extent).toDouble();
        final fixedFirst = firstExtent;
        final fixedSecond = secondExtent;
        final double bandStart;
        if (fixedFirst != null) {
          bandStart = fixedFirst.clamp(band, extent).toDouble() - band;
        } else if (fixedSecond != null) {
          bandStart = extent - fixedSecond.clamp(band, extent).toDouble();
        } else {
          bandStart = (extent - band) * ratio.clamp(0.0, 1.0);
        }
        final bandEnd = bandStart + band;
        final firstOnTop = overlap == DiagonalOverlap.first;

        Widget clip(Widget child, {required bool isFirst}) => ClipPath(
              clipper: _DiagonalClipper(
                axis: axis,
                space: band,
                direction: direction,
                isFirst: isFirst,
              ),
              child: child,
            );

        final firstChild = firstOnTop ? clip(first, isFirst: true) : first;
        final secondChild = firstOnTop ? second : clip(second, isFirst: false);

        // first ocupa [0, bandEnd], second ocupa [bandStart, extent]:
        // se pisan exactamente en la franja.
        final a = horizontal
            ? Positioned(
                left: 0, top: 0, bottom: 0, width: bandEnd, child: firstChild)
            : Positioned(
                left: 0, top: 0, right: 0, height: bandEnd, child: firstChild);
        final b = horizontal
            ? Positioned(
                left: bandStart, top: 0, bottom: 0, right: 0, child: secondChild)
            : Positioned(
                left: 0, top: bandStart, right: 0, bottom: 0, child: secondChild);

        return Stack(children: firstOnTop ? [b, a] : [a, b]);
      },
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  const _DiagonalClipper({
    required this.axis,
    required this.space,
    required this.direction,
    required this.isFirst,
  });

  final Axis axis;
  final double space;
  final DiagonalDirection direction;
  final bool isFirst;

  @override
  Path getClip(Size size) {
    final horizontal = axis == Axis.horizontal;
    // m = extensión sobre el eje principal, c = sobre el eje cruzado.
    final m = horizontal ? size.width : size.height;
    final c = horizontal ? size.height : size.width;
    // (principal, cruzado) -> coordenadas reales; en vertical se transpone.
    Offset p(double main, double cross) =>
        horizontal ? Offset(main, cross) : Offset(cross, main);

    // true = la punta de first está en el extremo lejano del eje cruzado
    // (abajo en horizontal, derecha en vertical).
    final far = direction == DiagonalDirection.bottomRight;

    final points = isFirst
        // La franja son los últimos `space` px del widget.
        ? [
            p(0, 0),
            p(far ? m - space : m, 0),
            p(far ? m : m - space, c),
            p(0, c),
          ]
        // La franja son los primeros `space` px del widget.
        : [
            p(far ? 0 : space, 0),
            p(m, 0),
            p(m, c),
            p(far ? space : 0, c),
          ];

    return Path()..addPolygon(points, true);
  }

  @override
  bool shouldReclip(_DiagonalClipper old) =>
      old.axis != axis ||
      old.space != space ||
      old.direction != direction ||
      old.isFirst != isFirst;
}
